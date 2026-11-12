import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/faber_app_state.dart';
import '../core/tokens.dart';
import '../models/faber_models.dart';
import '../widgets/glass_card.dart';

class ProjectsStudioScreen extends StatefulWidget {
  const ProjectsStudioScreen({super.key});

  @override
  State<ProjectsStudioScreen> createState() => _ProjectsStudioScreenState();
}

class _ProjectsStudioScreenState extends State<ProjectsStudioScreen> {
  int _segmentIndex = 0; // 0: Preview, 1: Code, 2: Terminal
  bool _isEditingCode = false;
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _terminalController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _terminalController.dispose();
    super.dispose();
  }

  String _inferLanguage(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.dart')) return 'dart';
    if (lower.endsWith('.ts') || lower.endsWith('.tsx')) return 'typescript';
    if (lower.endsWith('.js') || lower.endsWith('.jsx')) return 'javascript';
    if (lower.endsWith('.py')) return 'python';
    if (lower.endsWith('.json')) return 'json';
    if (lower.endsWith('.yaml') || lower.endsWith('.yml')) return 'yaml';
    if (lower.endsWith('.html')) return 'xml';
    if (lower.endsWith('.css')) return 'css';
    if (lower.endsWith('.sh')) return 'bash';
    if (lower.endsWith('.sql')) return 'sql';
    return 'dart';
  }

  Future<void> _openExternalUrl(String rawUrl, String baseUrl) async {
    final resolved = rawUrl.startsWith('http')
        ? rawUrl
        : '$baseUrl${rawUrl.startsWith('/') ? '' : '/'}$rawUrl';
    final uri = Uri.tryParse(resolved);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak dapat membuka $resolved')),
      );
    }
  }

  void _openFilePicker(BuildContext context, FaberAppState state) {
    final files = state.flatFiles.isNotEmpty
        ? state.flatFiles
        : const [
            'lib/main.dart',
            'lib/core/tokens.dart',
            'pubspec.yaml',
          ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: FaberTokens.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih File Proyek',
                  style: TextStyle(
                    color: FaberTokens.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: files.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, idx) {
                      final path = files[idx];
                      final active = path == state.activeFilePath;
                      return FaberGlassCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        borderColor: active
                            ? FaberTokens.accentCyan
                            : FaberTokens.borderGlass,
                        onTap: () async {
                          Navigator.pop(ctx);
                          await state.openFile(path);
                          if (mounted) {
                            setState(() {
                              _codeController.text = state.activeFileContent;
                              _isEditingCode = false;
                            });
                          }
                        },
                        child: Row(
                          children: [
                            const Icon(
                              CupertinoIcons.doc_text,
                              size: 16,
                              color: FaberTokens.accentCyan,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                path,
                                style: const TextStyle(
                                  color: FaberTokens.textPrimary,
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FaberAppState>();

    return Column(
      children: [
        // Top Segmented Pill: Preview / Code / Terminal
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: FaberGlassCard(
            padding: const EdgeInsets.all(6),
            radius: FaberTokens.radiusPill,
            elevated: true,
            child: Row(
              children: [
                _SegmentTab(
                  label: 'Preview',
                  icon: CupertinoIcons.globe,
                  selected: _segmentIndex == 0,
                  onTap: () => setState(() => _segmentIndex = 0),
                ),
                _SegmentTab(
                  label: 'Code',
                  icon: CupertinoIcons.chevron_left_slash_chevron_right,
                  selected: _segmentIndex == 1,
                  onTap: () {
                    setState(() => _segmentIndex = 1);
                    if (state.activeFilePath.isEmpty &&
                        state.flatFiles.isNotEmpty) {
                      state.openFile(state.flatFiles.first).then((_) {
                        if (mounted) {
                          _codeController.text = state.activeFileContent;
                        }
                      });
                    }
                  },
                ),
                _SegmentTab(
                  label: 'Terminal',
                  icon: CupertinoIcons.command,
                  selected: _segmentIndex == 2,
                  onTap: () => setState(() => _segmentIndex = 2),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: IndexedStack(
            index: _segmentIndex,
            children: [
              _buildPreviewTab(context, state),
              _buildCodeTab(context, state),
              _buildTerminalTab(context, state),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewTab(BuildContext context, FaberAppState state) {
    return RefreshIndicator(
      color: FaberTokens.accentIndigo,
      backgroundColor: FaberTokens.bgElevated,
      onRefresh: state.refreshAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Staging Sites',
                style: TextStyle(
                  color: FaberTokens.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              FaberPill(
                label: '${state.sites.length} Sites',
                color: FaberTokens.accentCyan,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (state.sites.isEmpty)
            const FaberGlassCard(
              child: Text(
                'Belum ada staging site ditemukan.',
                style: TextStyle(color: FaberTokens.textSecondary),
              ),
            )
          else
            ...state.sites.map((site) => _buildSiteCard(context, state, site)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cloud Apps (PM2 / Docker)',
                style: TextStyle(
                  color: FaberTokens.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              FaberPill(
                label: '${state.cloudApps.length} Apps',
                color: FaberTokens.accentEmerald,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (state.cloudApps.isEmpty)
            const FaberGlassCard(
              child: Text(
                'Tidak ada Cloud App aktif saat ini.',
                style: TextStyle(color: FaberTokens.textSecondary),
              ),
            )
          else
            ...state.cloudApps
                .map((app) => _buildCloudAppCard(context, state, app)),
        ],
      ),
    );
  }

  Widget _buildSiteCard(
    BuildContext context,
    FaberAppState state,
    FaberSite site,
  ) {
    final isSelected = site.slug == state.selectedSiteSlug;
    return FaberGlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      borderColor:
          isSelected ? FaberTokens.accentIndigo : FaberTokens.borderGlass,
      onTap: () => state.selectSite(site.slug),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  site.name,
                  style: const TextStyle(
                    color: FaberTokens.textPrimary,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              FaberPill(
                label: site.status.toUpperCase(),
                color: FaberTokens.accentEmerald,
                showDot: true,
              ),
            ],
          ),
          if (site.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              site.description,
              style: const TextStyle(
                color: FaberTokens.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 6,
                children: [
                  FaberPill(
                    label: site.framework,
                    color: FaberTokens.accentIndigo,
                  ),
                  FaberPill(
                    label: site.branch,
                    icon: CupertinoIcons.arrow_branch,
                    color: FaberTokens.accentCyan,
                  ),
                ],
              ),
              FaberGlassButton(
                label: 'Buka Staging',
                icon: CupertinoIcons.arrow_up_right_square,
                compact: true,
                isPrimary: true,
                onPressed: () {
                  final target = site.stagingUrl.isNotEmpty
                      ? site.stagingUrl
                      : '/staging/${site.slug}/';
                  _openExternalUrl(target, state.baseUrl);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCloudAppCard(
    BuildContext context,
    FaberAppState state,
    FaberCloudApp app,
  ) {
    return FaberGlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  app.name,
                  style: const TextStyle(
                    color: FaberTokens.textPrimary,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              FaberPill(
                label: app.status,
                color: app.isRunning
                    ? FaberTokens.accentEmerald
                    : FaberTokens.accentRose,
                showDot: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CPU ${app.cpuPercent.toStringAsFixed(1)}% • RAM ${app.memoryMb.toStringAsFixed(0)} MB${app.port != null ? ' • :${app.port}' : ''}',
                style: const TextStyle(
                  color: FaberTokens.textSecondary,
                  fontSize: 12.5,
                ),
              ),
              if (app.url.isNotEmpty)
                FaberGlassButton(
                  label: 'Buka',
                  icon: CupertinoIcons.link,
                  compact: true,
                  onPressed: () => _openExternalUrl(app.url, state.baseUrl),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCodeTab(BuildContext context, FaberAppState state) {
    final codeText = state.activeFileContent.isNotEmpty
        ? state.activeFileContent
        : '// Pilih file untuk melihat & mengedit kode sumber proyek.';

    if (!_isEditingCode && _codeController.text != state.activeFileContent) {
      _codeController.text = state.activeFileContent;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: [
          FaberGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _openFilePicker(context, state),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.folder_open,
                          color: FaberTokens.accentCyan,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.activeFilePath.isEmpty
                                ? 'Pilih File...'
                                : state.activeFilePath,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: FaberTokens.textPrimary,
                              fontFamily: 'monospace',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(
                          CupertinoIcons.chevron_down,
                          color: FaberTokens.textSecondary,
                          size: 15,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FaberGlassButton(
                  label: _isEditingCode ? 'Highlight' : 'Edit',
                  icon: _isEditingCode
                      ? CupertinoIcons.eye
                      : CupertinoIcons.pencil,
                  compact: true,
                  onPressed: state.activeFilePath.isEmpty
                      ? null
                      : () {
                          setState(() {
                            if (!_isEditingCode) {
                              _codeController.text = state.activeFileContent;
                            }
                            _isEditingCode = !_isEditingCode;
                          });
                        },
                ),
                if (_isEditingCode) ...[
                  const SizedBox(width: 6),
                  FaberGlassButton(
                    label: 'Simpan',
                    icon: CupertinoIcons.floppy_disk,
                    compact: true,
                    isPrimary: true,
                    isLoading: state.isFileSaving,
                    onPressed: () async {
                      final ok = await state.saveFile(_codeController.text);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'File berhasil disimpan.'
                                : 'Gagal menyimpan file.',
                          ),
                        ),
                      );
                      if (ok) {
                        setState(() => _isEditingCode = false);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: FaberGlassCard(
              padding: EdgeInsets.zero,
              backgroundColor: FaberTokens.surfaceTerminal,
              child: state.isFileLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _isEditingCode
                      ? TextField(
                          controller: _codeController,
                          maxLines: null,
                          expands: true,
                          style: const TextStyle(
                            color: FaberTokens.textCode,
                            fontFamily: 'monospace',
                            fontSize: 12.5,
                            height: 1.45,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.all(14),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(8),
                          child: HighlightView(
                            codeText,
                            language: _inferLanguage(state.activeFilePath),
                            theme: atomOneDarkTheme,
                            padding: const EdgeInsets.all(12),
                            textStyle: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12.5,
                              height: 1.45,
                            ),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalTab(BuildContext context, FaberAppState state) {
    const quickCommands = ['pm2 status', 'git status', 'df -h', 'free -m'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: quickCommands.map((cmd) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FaberPill(
                    label: '\$ $cmd',
                    color: FaberTokens.accentCyan,
                    onTap: state.isTerminalRunning
                        ? null
                        : () => state.runTerminalCommand(cmd),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: FaberGlassCard(
              padding: const EdgeInsets.all(14),
              backgroundColor: FaberTokens.surfaceTerminal,
              child: SingleChildScrollView(
                reverse: true,
                child: SelectableText(
                  state.terminalOutput.isEmpty
                      ? 'Faber VPS Terminal siap.\nKetik perintah di bawah atau pilih quick command.'
                      : state.terminalOutput,
                  style: const TextStyle(
                    color: FaberTokens.accentEmerald,
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          FaberGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                const Text(
                  '\$',
                  style: TextStyle(
                    color: FaberTokens.accentCyan,
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _terminalController,
                    style: const TextStyle(
                      color: FaberTokens.textPrimary,
                      fontFamily: 'monospace',
                      fontSize: 13.5,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Jalankan perintah VPS...',
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    onSubmitted: (val) {
                      _terminalController.clear();
                      state.runTerminalCommand(val);
                    },
                  ),
                ),
                FaberGlassButton(
                  label: 'Run',
                  icon: CupertinoIcons.play_fill,
                  compact: true,
                  isPrimary: true,
                  isLoading: state.isTerminalRunning,
                  onPressed: () {
                    final cmd = _terminalController.text;
                    _terminalController.clear();
                    state.runTerminalCommand(cmd);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            gradient: selected ? FaberTokens.accentGradient : null,
            borderRadius: FaberTokens.brPill,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : FaberTokens.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : FaberTokens.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
