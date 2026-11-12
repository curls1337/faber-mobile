import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/faber_app_state.dart';
import '../core/tokens.dart';
import '../models/faber_models.dart';
import '../widgets/glass_card.dart';

class ChatSwarmScreen extends StatefulWidget {
  const ChatSwarmScreen({super.key});

  @override
  State<ChatSwarmScreen> createState() => _ChatSwarmScreenState();
}

class _ChatSwarmScreenState extends State<ChatSwarmScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<String> _pendingAttachments = [];
  bool _isVoiceListening = false;

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend(FaberAppState state) async {
    final text = _promptController.text.trim();
    if (text.isEmpty && _pendingAttachments.isEmpty) return;

    final buffer = StringBuffer();
    if (_pendingAttachments.isNotEmpty) {
      buffer.writeln('[Lampiran: ${_pendingAttachments.join(', ')}]');
    }
    buffer.write(text);

    _promptController.clear();
    setState(() {
      _pendingAttachments.clear();
      _isVoiceListening = false;
    });

    _scrollToBottom();
    await state.sendPrompt(buffer.toString());
    _scrollToBottom();
  }

  void _openProjectSwitcher(BuildContext context, FaberAppState state) {
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
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: FaberTokens.borderGlassStrong,
                      borderRadius: FaberTokens.brPill,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pilih Proyek & Sesi Aktif',
                  style: TextStyle(
                    color: FaberTokens.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (state.sites.isEmpty)
                  const Text(
                    'Belum ada proyek terdaftar.',
                    style: TextStyle(color: FaberTokens.textSecondary),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: state.sites.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final site = state.sites[index];
                        final isSelected = site.slug == state.selectedSiteSlug;
                        return FaberGlassCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          borderColor: isSelected
                              ? FaberTokens.accentIndigo
                              : FaberTokens.borderGlass,
                          onTap: () {
                            state.selectSite(site.slug);
                            Navigator.pop(ctx);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      site.name,
                                      style: const TextStyle(
                                        color: FaberTokens.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '/${site.slug} • ${site.branch}',
                                      style: const TextStyle(
                                        color: FaberTokens.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  CupertinoIcons.checkmark_circle_fill,
                                  color: FaberTokens.accentIndigo,
                                  size: 20,
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

  void _openAgentPicker(BuildContext context, FaberAppState state) {
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
                  'Pilih Agen Direct Chat',
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
                    itemCount: state.agents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, idx) {
                      final agent = state.agents[idx];
                      final selected = agent.id == state.selectedAgentId;
                      return FaberGlassCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        borderColor: selected
                            ? agent.accentColor
                            : FaberTokens.borderGlass,
                        onTap: () {
                          state.selectAgent(agent.id);
                          state.setTaskMode('direct');
                          Navigator.pop(ctx);
                        },
                        child: Row(
                          children: [
                            Text(
                              agent.avatar,
                              style: const TextStyle(fontSize: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    agent.name,
                                    style: const TextStyle(
                                      color: FaberTokens.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    agent.role,
                                    style: const TextStyle(
                                      color: FaberTokens.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FaberPill(
                              label: agent.status,
                              color: agent.isWorking
                                  ? FaberTokens.accentEmerald
                                  : agent.accentColor,
                              showDot: true,
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

  void _openAttachmentSheet(BuildContext context, FaberAppState state) {
    final candidates = <String>[
      ...state.flatFiles.take(6),
      ...state.mediaItems.take(4).map((m) => m.name),
      if (state.flatFiles.isEmpty && state.mediaItems.isEmpty) ...[
        'lib/main.dart',
        'pubspec.yaml',
        'architecture_spec.md',
      ],
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lampirkan Konteks File / Media',
                  style: TextStyle(
                    color: FaberTokens.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: candidates.map((item) {
                    final added = _pendingAttachments.contains(item);
                    return FaberPill(
                      label: item,
                      icon: CupertinoIcons.paperclip,
                      color: added
                          ? FaberTokens.accentEmerald
                          : FaberTokens.accentCyan,
                      selected: added,
                      onTap: () {
                        setState(() {
                          if (added) {
                            _pendingAttachments.remove(item);
                          } else {
                            _pendingAttachments.add(item);
                          }
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleVoiceInput() {
    setState(() {
      _isVoiceListening = !_isVoiceListening;
    });
    if (_isVoiceListening) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mode dikte suara aktif — ketuk lagi untuk selesai.'),
          duration: Duration(seconds: 2),
        ),
      );
    } else if (_promptController.text.trim().isEmpty) {
      _promptController.text =
          'Periksa status seluruh service dan laporkan ringkasan performa.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FaberAppState>();
    final activeSite = state.sites.cast<FaberSite?>().firstWhere(
          (s) => s?.slug == state.selectedSiteSlug,
          orElse: () => null,
        );
    final activeAgent = state.agents.cast<FaberAgent?>().firstWhere(
          (a) => a?.id == state.selectedAgentId,
          orElse: () => null,
        );

    return Column(
      children: [
        // Top Project Switcher & Swarm/Direct Toggle Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: FaberGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            radius: FaberTokens.radiusLg,
            elevated: true,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _openProjectSwitcher(context, state),
                        borderRadius: FaberTokens.brSm,
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                gradient: FaberTokens.accentGradient,
                                borderRadius: FaberTokens.brSm,
                              ),
                              child: const Icon(
                                CupertinoIcons.layers_alt_fill,
                                color: Colors.white,
                                size: 17,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activeSite?.name ?? 'Faber Workspace',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: FaberTokens.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    state.isDemoMode
                                        ? 'Demo Mode • ${state.agents.length} Agen'
                                        : 'Live • ${activeSite?.branch ?? 'main'}',
                                    style: const TextStyle(
                                      color: FaberTokens.textSecondary,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              CupertinoIcons.chevron_down,
                              size: 16,
                              color: FaberTokens.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Swarm / Direct Segmented Toggle
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: FaberTokens.surfaceTerminal,
                        borderRadius: FaberTokens.brPill,
                        border: Border.all(color: FaberTokens.borderGlass),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ModeChip(
                            label: 'Swarm',
                            selected: state.taskMode == 'swarm',
                            onTap: () => state.setTaskMode('swarm'),
                          ),
                          _ModeChip(
                            label: 'Direct',
                            selected: state.taskMode == 'direct',
                            onTap: () {
                              state.setTaskMode('direct');
                              if (state.agents.isNotEmpty &&
                                  state.selectedAgentId.isEmpty) {
                                state.selectAgent(state.agents.first.id);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (state.taskMode == 'direct') ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FaberPill(
                        label: activeAgent != null
                            ? '${activeAgent.avatar} ${activeAgent.name}'
                            : 'Pilih Agen Target',
                        color: activeAgent?.accentColor ??
                            FaberTokens.accentCyan,
                        onTap: () => _openAgentPicker(context, state),
                      ),
                      Text(
                        'Tap untuk ganti agen',
                        style: TextStyle(
                          color: FaberTokens.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),

        // Stream Message List with Pull-to-Refresh
        Expanded(
          child: RefreshIndicator(
            color: FaberTokens.accentIndigo,
            backgroundColor: FaberTokens.bgElevated,
            onRefresh: state.refreshAll,
            child: state.messages.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 28, 16, 20),
                    children: [
                      _EmptySwarmHero(
                        onQuickPrompt: (prompt) {
                          _promptController.text = prompt;
                          _handleSend(state);
                        },
                      ),
                    ],
                  )
                : ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final msg = state.messages[index];
                      return _MessageBubble(message: msg);
                    },
                  ),
          ),
        ),

        // Pending Attachments Bar
        if (_pendingAttachments.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _pendingAttachments.map((file) {
                return FaberPill(
                  label: '$file ✕',
                  color: FaberTokens.accentCyan,
                  onTap: () {
                    setState(() => _pendingAttachments.remove(file));
                  },
                );
              }).toList(),
            ),
          ),

        // Composer with Attachment & Voice Button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: FaberGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            radius: FaberTokens.radiusXl,
            elevated: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Lampirkan file',
                  onPressed: () => _openAttachmentSheet(context, state),
                  icon: const Icon(
                    CupertinoIcons.paperclip,
                    color: FaberTokens.textSecondary,
                    size: 20,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    minLines: 1,
                    maxLines: 4,
                    style: const TextStyle(
                      color: FaberTokens.textPrimary,
                      fontSize: 14.5,
                    ),
                    decoration: InputDecoration(
                      hintText: state.taskMode == 'swarm'
                          ? 'Instruksikan Faber Swarm...'
                          : 'Kirim pesan ke ${activeAgent?.name ?? 'agen'}...',
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _handleSend(state),
                  ),
                ),
                IconButton(
                  tooltip: 'Voice command',
                  onPressed: _toggleVoiceInput,
                  icon: Icon(
                    _isVoiceListening
                        ? CupertinoIcons.mic_circle_fill
                        : CupertinoIcons.mic,
                    color: _isVoiceListening
                        ? FaberTokens.accentRose
                        : FaberTokens.textSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: state.isStreaming ? null : () => _handleSend(state),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: FaberTokens.accentGradient,
                      borderRadius: FaberTokens.brPill,
                      boxShadow: FaberTokens.glowShadow(
                        FaberTokens.accentIndigo,
                      ),
                    ),
                    child: state.isStreaming
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(
                            CupertinoIcons.arrow_up,
                            color: Colors.white,
                            size: 19,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          gradient: selected ? FaberTokens.accentGradient : null,
          borderRadius: FaberTokens.brPill,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : FaberTokens.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _EmptySwarmHero extends StatelessWidget {
  final ValueChanged<String> onQuickPrompt;

  const _EmptySwarmHero({required this.onQuickPrompt});

  @override
  Widget build(BuildContext context) {
    const quickPrompts = [
      'Audit keamanan & dependency proyek aktif',
      'Cek status PM2, RAM & disk VPS sekarang',
      'Buat ringkasan progres 16 agen hari ini',
    ];

    return FaberGlassCard(
      padding: const EdgeInsets.all(20),
      gradient: FaberTokens.heroGradient,
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FaberPill(
            label: 'FABER SWARM ORCHESTRATOR',
            color: FaberTokens.accentCyan,
            showDot: true,
          ),
          const SizedBox(height: 14),
          const Text(
            'Kendalikan 16 Agen Spesialis dari Genggaman',
            style: TextStyle(
              color: FaberTokens.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tulis perintah untuk orkestrasi multi-agen atau beralih ke mode Direct untuk diskusi 1-on-1.',
            style: TextStyle(
              color: FaberTokens.textSecondary,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          ...quickPrompts.map(
            (prompt) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FaberGlassCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                radius: FaberTokens.radiusMd,
                onTap: () => onQuickPrompt(prompt),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        prompt,
                        style: const TextStyle(
                          color: FaberTokens.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.arrow_right_circle,
                      color: FaberTokens.accentCyan,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final FaberMessage message;

  const _MessageBubble({required this.message});

  List<String> _extractToolSteps(FaberMessage msg) {
    final steps = <String>[...msg.artifacts];
    final reg = RegExp(r'\[tool:([^\]]+)\]');
    for (final m in reg.allMatches(msg.content)) {
      final name = m.group(1)?.trim();
      if (name != null && name.isNotEmpty && !steps.contains(name)) {
        steps.add(name);
      }
    }
    return steps;
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final toolSteps = _extractToolSteps(message);
    final timeStr = DateFormat('HH:mm').format(message.timestamp);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.84,
        ),
        child: FaberGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          radius: FaberTokens.radiusLg,
          gradient: isUser ? FaberTokens.accentGradient : null,
          borderColor: isUser
              ? FaberTokens.accentIndigo.withOpacity(0.7)
              : FaberTokens.borderGlass,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isUser
                        ? 'Anda'
                        : (message.agentName.isNotEmpty
                            ? message.agentName
                            : 'Faber Assistant'),
                    style: TextStyle(
                      color: isUser
                          ? Colors.white.withOpacity(0.9)
                          : FaberTokens.accentCyan,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: isUser
                          ? Colors.white.withOpacity(0.75)
                          : FaberTokens.textMuted,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
              if (toolSteps.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: toolSteps
                      .map(
                        (step) => FaberPill(
                          label: step,
                          icon: CupertinoIcons.wrench,
                          color: FaberTokens.accentEmerald,
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 6),
              if (message.content.isEmpty && message.isStreaming)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          FaberTokens.accentCyan,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Agen sedang memproses...',
                      style: TextStyle(
                        color: FaberTokens.textSecondary,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                )
              else
                SelectableText(
                  message.content,
                  style: TextStyle(
                    color: isUser ? Colors.white : FaberTokens.textPrimary,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
