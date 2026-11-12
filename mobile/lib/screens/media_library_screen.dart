import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../core/faber_app_state.dart';
import '../core/tokens.dart';
import '../models/faber_models.dart';
import '../widgets/glass_card.dart';

class MediaLibraryScreen extends StatefulWidget {
  const MediaLibraryScreen({super.key});

  @override
  State<MediaLibraryScreen> createState() => _MediaLibraryScreenState();
}

class _MediaLibraryScreenState extends State<MediaLibraryScreen> {
  String _activeFilter = 'all'; // all | image | video | audio | pdf
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingAudioId;
  bool _isAudioPlaying = false;
  Duration _audioPos = Duration.zero;
  Duration _audioDur = Duration.zero;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;

  @override
  void initState() {
    super.initState();
    _stateSub = _audioPlayer.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      setState(() {
        _isAudioPlaying = s == PlayerState.playing;
        if (s == PlayerState.completed || s == PlayerState.stopped) {
          _audioPos = Duration.zero;
        }
      });
    });
    _posSub = _audioPlayer.onPositionChanged.listen((d) {
      if (!mounted) return;
      setState(() => _audioPos = d);
    });
    _durSub = _audioPlayer.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _audioDur = d);
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  List<FaberMediaItem> _filteredItems(FaberAppState state) {
    final source = state.mediaItems.isNotEmpty
        ? state.mediaItems
        : (state.isDemoMode ? _demoMediaItems : <FaberMediaItem>[]);

    if (_activeFilter == 'all') return source;
    if (_activeFilter == 'pdf') {
      return source
          .where((m) =>
              m.type == 'document' || m.name.toLowerCase().endsWith('.pdf'))
          .toList();
    }
    return source.where((m) => m.type == _activeFilter).toList();
  }

  static const List<FaberMediaItem> _demoMediaItems = [
    FaberMediaItem(
      id: 'demo_1',
      name: 'architecture-diagram.png',
      path: '/staging/faber-mobile/architecture-diagram.png',
      type: 'image',
      mimeType: 'image/png',
      sizeBytes: 428100,
    ),
    FaberMediaItem(
      id: 'demo_2',
      name: 'faber-swarm-demo.mp4',
      path: '/staging/faber-mobile/faber-swarm-demo.mp4',
      type: 'video',
      mimeType: 'video/mp4',
      sizeBytes: 3420000,
    ),
    FaberMediaItem(
      id: 'demo_3',
      name: 'agent-briefing.mp3',
      path: '/staging/faber-mobile/agent-briefing.mp3',
      type: 'audio',
      mimeType: 'audio/mpeg',
      sizeBytes: 812000,
    ),
    FaberMediaItem(
      id: 'demo_4',
      name: 'BRD_PRD_FaberMobile.pdf',
      path: '/staging/faber-mobile/BRD_PRD_FaberMobile.pdf',
      type: 'document',
      mimeType: 'application/pdf',
      sizeBytes: 194500,
    ),
  ];

  Future<void> _downloadItem(FaberMediaItem item, String baseUrl) async {
    final url = item.rawUrl(baseUrl);
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengunduh ${item.name}')),
      );
    }
  }

  Future<void> _toggleAudio(FaberMediaItem item, String baseUrl) async {
    final url = item.rawUrl(baseUrl);
    try {
      if (_playingAudioId == item.id && _isAudioPlaying) {
        await _audioPlayer.pause();
      } else if (_playingAudioId == item.id && !_isAudioPlaying) {
        await _audioPlayer.resume();
      } else {
        await _audioPlayer.stop();
        setState(() {
          _playingAudioId = item.id;
          _audioPos = Duration.zero;
          _audioDur = Duration.zero;
        });
        await _audioPlayer.play(UrlSource(url));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Audio player: $e')),
      );
    }
  }

  void _openVideoPlayerModal(
    BuildContext context,
    FaberMediaItem item,
    String baseUrl,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: FaberTokens.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _VideoPlayerModal(
        item: item,
        mediaUrl: item.rawUrl(baseUrl),
        onDownload: () => _downloadItem(item, baseUrl),
      ),
    );
  }

  void _openImagePreviewModal(
    BuildContext context,
    FaberMediaItem item,
    String baseUrl,
  ) {
    final url = item.rawUrl(baseUrl);
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: FaberTokens.bgElevated,
        shape: RoundedRectangleBorder(borderRadius: FaberTokens.brXl),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FaberTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark_circle_fill),
                    color: FaberTokens.textSecondary,
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: FaberTokens.brMd,
                child: Image.network(
                  url,
                  height: 260,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 180,
                    child: Center(
                      child: Icon(
                        CupertinoIcons.photo,
                        size: 48,
                        color: FaberTokens.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FaberGlassButton(
                label: 'Unduh Gambar',
                icon: CupertinoIcons.cloud_download,
                isPrimary: true,
                onPressed: () => _downloadItem(item, baseUrl),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'image':
        return CupertinoIcons.photo_fill;
      case 'video':
        return CupertinoIcons.play_rectangle_fill;
      case 'audio':
        return CupertinoIcons.waveform;
      default:
        return CupertinoIcons.doc_richtext_fill;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'image':
        return FaberTokens.accentCyan;
      case 'video':
        return FaberTokens.accentViolet;
      case 'audio':
        return FaberTokens.accentEmerald;
      default:
        return FaberTokens.accentAmber;
    }
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FaberAppState>();
    final items = _filteredItems(state);

    const filters = [
      ('all', 'Semua'),
      ('image', 'Gambar'),
      ('video', 'Video'),
      ('audio', 'Audio'),
      ('pdf', 'PDF'),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: FaberGlassCard(
            padding: const EdgeInsets.all(14),
            elevated: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Media Vault & Library',
                      style: TextStyle(
                        color: FaberTokens.textPrimary,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    FaberPill(
                      label: '${items.length} Item',
                      color: FaberTokens.accentCyan,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filters.map((f) {
                      final selected = _activeFilter == f.$1;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FaberPill(
                          label: f.$2,
                          color: selected
                              ? FaberTokens.accentIndigo
                              : FaberTokens.textSecondary,
                          selected: selected,
                          onTap: () => setState(() => _activeFilter = f.$1),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: FaberTokens.accentIndigo,
            backgroundColor: FaberTokens.bgElevated,
            onRefresh: state.refreshAll,
            child: items.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: const [
                      FaberGlassCard(
                        child: Column(
                          children: [
                            Icon(
                              CupertinoIcons.folder_badge_minus,
                              size: 40,
                              color: FaberTokens.textMuted,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Belum ada media pada kategori ini.',
                              style:
                                  TextStyle(color: FaberTokens.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: items.length,
                    itemBuilder: (context, idx) {
                      final item = items[idx];
                      final color = _colorForType(item.type);
                      final isThisAudio = _playingAudioId == item.id;

                      return FaberGlassCard(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.16),
                                    borderRadius: FaberTokens.brMd,
                                    border: Border.all(
                                      color: color.withOpacity(0.4),
                                    ),
                                  ),
                                  child: Icon(
                                    _iconForType(item.type),
                                    color: color,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: FaberTokens.textPrimary,
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${item.type.toUpperCase()} • ${item.formattedSize}',
                                        style: const TextStyle(
                                          color: FaberTokens.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Unduh',
                                  icon: const Icon(
                                    CupertinoIcons.cloud_download,
                                    color: FaberTokens.accentCyan,
                                  ),
                                  onPressed: () =>
                                      _downloadItem(item, state.baseUrl),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (item.type == 'audio')
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  FaberGlassButton(
                                    label: isThisAudio && _isAudioPlaying
                                        ? 'Jeda Audio'
                                        : 'Putar Audio',
                                    icon: isThisAudio && _isAudioPlaying
                                        ? CupertinoIcons.pause_fill
                                        : CupertinoIcons.play_fill,
                                    compact: true,
                                    isPrimary: true,
                                    onPressed: () =>
                                        _toggleAudio(item, state.baseUrl),
                                  ),
                                  if (isThisAudio)
                                    Text(
                                      '${_formatDuration(_audioPos)} / ${_formatDuration(_audioDur)}',
                                      style: const TextStyle(
                                        color: FaberTokens.textSecondary,
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              )
                            else if (item.type == 'video')
                              FaberGlassButton(
                                label: 'Putar Video Player',
                                icon: CupertinoIcons.play_circle_fill,
                                compact: true,
                                isPrimary: true,
                                onPressed: () => _openVideoPlayerModal(
                                  context,
                                  item,
                                  state.baseUrl,
                                ),
                              )
                            else if (item.type == 'image')
                              FaberGlassButton(
                                label: 'Pratinjau Gambar',
                                icon: CupertinoIcons.eye_fill,
                                compact: true,
                                onPressed: () => _openImagePreviewModal(
                                  context,
                                  item,
                                  state.baseUrl,
                                ),
                              )
                            else
                              FaberGlassButton(
                                label: 'Buka Dokumen / PDF',
                                icon: CupertinoIcons.doc_text_search,
                                compact: true,
                                onPressed: () =>
                                    _downloadItem(item, state.baseUrl),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _VideoPlayerModal extends StatefulWidget {
  final FaberMediaItem item;
  final String mediaUrl;
  final VoidCallback onDownload;

  const _VideoPlayerModal({
    required this.item,
    required this.mediaUrl,
    required this.onDownload,
  });

  @override
  State<_VideoPlayerModal> createState() => _VideoPlayerModalState();
}

class _VideoPlayerModalState extends State<_VideoPlayerModal> {
  VideoPlayerController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.mediaUrl));
      _controller = ctrl;
      await ctrl.initialize();
      ctrl.addListener(() {
        if (mounted) setState(() {});
      });
      await ctrl.play();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _controller;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FaberTokens.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.xmark_circle_fill),
                  color: FaberTokens.textSecondary,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: FaberTokens.brLg,
                border: Border.all(color: FaberTokens.borderGlass),
              ),
              child: _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Gagal memuat video:\n$_error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: FaberTokens.accentRose,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    )
                  : (ctrl != null && ctrl.value.isInitialized)
                      ? ClipRRect(
                          borderRadius: FaberTokens.brLg,
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: ctrl.value.aspectRatio,
                              child: VideoPlayer(ctrl),
                            ),
                          ),
                        )
                      : const Center(child: CircularProgressIndicator()),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FaberGlassButton(
                  label: (ctrl != null && ctrl.value.isPlaying)
                      ? 'Pause'
                      : 'Play',
                  icon: (ctrl != null && ctrl.value.isPlaying)
                      ? CupertinoIcons.pause_fill
                      : CupertinoIcons.play_fill,
                  isPrimary: true,
                  onPressed: (ctrl != null && ctrl.value.isInitialized)
                      ? () {
                          if (ctrl.value.isPlaying) {
                            ctrl.pause();
                          } else {
                            ctrl.play();
                          }
                        }
                      : null,
                ),
                FaberGlassButton(
                  label: 'Unduh MP4',
                  icon: CupertinoIcons.cloud_download,
                  onPressed: widget.onDownload,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
