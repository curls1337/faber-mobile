import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/faber_app_state.dart';
import '../core/tokens.dart';
import '../models/faber_models.dart';
import '../widgets/glass_card.dart';

class AgentsOfficeScreen extends StatefulWidget {
  const AgentsOfficeScreen({super.key});

  @override
  State<AgentsOfficeScreen> createState() => _AgentsOfficeScreenState();
}

class _AgentsOfficeScreenState extends State<AgentsOfficeScreen> {
  String _statusFilter = 'all'; // all | active | idle

  static const List<FaberAgent> _default16Roster = [
    FaberAgent(
      id: 'orchestrator',
      name: 'Faber Orchestrator',
      role: 'Swarm Lead',
      avatar: '🧠',
      status: 'active',
      colorHex: '#6366F1',
    ),
    FaberAgent(
      id: 'team-pm',
      name: 'Product Manager',
      role: 'BRD & PRD',
      avatar: '📋',
      status: 'idle',
      colorHex: '#8B5CF6',
    ),
    FaberAgent(
      id: 'team-architect',
      name: 'System Architect',
      role: 'Architecture & DB',
      avatar: '🏛️',
      status: 'idle',
      colorHex: '#3B82F6',
    ),
    FaberAgent(
      id: 'team-uiux',
      name: 'UI/UX Designer',
      role: 'Liquid Glass & Flows',
      avatar: '🎨',
      status: 'working',
      colorHex: '#22D3EE',
    ),
    FaberAgent(
      id: 'team-engineer',
      name: 'Team Engineer',
      role: 'Full-Stack & Mobile',
      avatar: '⚡',
      status: 'working',
      colorHex: '#22D3EE',
    ),
    FaberAgent(
      id: 'team-qa-security',
      name: 'QA & Security',
      role: 'Audit & Verification',
      avatar: '🛡️',
      status: 'idle',
      colorHex: '#10B981',
    ),
    FaberAgent(
      id: 'team-devops',
      name: 'DevOps & Cloud',
      role: 'CI/CD & VPS',
      avatar: '🚀',
      status: 'idle',
      colorHex: '#F59E0B',
    ),
    FaberAgent(
      id: 'team-data',
      name: 'Data & Analytics',
      role: 'Metrics & SQL',
      avatar: '📊',
      status: 'idle',
      colorHex: '#6366F1',
    ),
    FaberAgent(
      id: 'team-ai-ml',
      name: 'AI/ML Specialist',
      role: 'Prompts & Agents',
      avatar: '🤖',
      status: 'idle',
      colorHex: '#8B5CF6',
    ),
    FaberAgent(
      id: 'team-mobile-ios',
      name: 'iOS Specialist',
      role: 'SwiftUI & IPA',
      avatar: '📱',
      status: 'working',
      colorHex: '#3B82F6',
    ),
    FaberAgent(
      id: 'team-mobile-android',
      name: 'Android Specialist',
      role: 'Kotlin & APK',
      avatar: '🤖',
      status: 'idle',
      colorHex: '#10B981',
    ),
    FaberAgent(
      id: 'team-backend',
      name: 'Backend API',
      role: 'REST & SSE',
      avatar: '🔌',
      status: 'idle',
      colorHex: '#6366F1',
    ),
    FaberAgent(
      id: 'team-frontend',
      name: 'Frontend Web',
      role: 'SPA & Staging',
      avatar: '🌐',
      status: 'idle',
      colorHex: '#22D3EE',
    ),
    FaberAgent(
      id: 'team-content',
      name: 'Tech Writer',
      role: 'Docs & Copy',
      avatar: '✍️',
      status: 'idle',
      colorHex: '#F59E0B',
    ),
    FaberAgent(
      id: 'team-growth',
      name: 'Growth & SEO',
      role: 'Launch & ASO',
      avatar: '📈',
      status: 'idle',
      colorHex: '#10B981',
    ),
    FaberAgent(
      id: 'team-support',
      name: 'Site Reliability',
      role: 'Monitoring & Cron',
      avatar: '🩺',
      status: 'idle',
      colorHex: '#EF4444',
    ),
  ];

  List<FaberAgent> _resolvedAgents(FaberAppState state) {
    final map = <String, FaberAgent>{
      for (final a in _default16Roster) a.id: a,
    };
    for (final live in state.agents) {
      map[live.id] = live;
    }
    for (final desk in state.warOfficeDesks) {
      final existing = map[desk.agentId];
      if (existing != null) {
        map[desk.agentId] = existing.copyWith(
          status: desk.status,
          currentTask: desk.currentTask,
        );
      } else {
        map[desk.agentId] = FaberAgent(
          id: desk.agentId,
          name: desk.agentName,
          role: desk.role,
          avatar: desk.avatar,
          status: desk.status,
          currentTask: desk.currentTask,
        );
      }
    }
    final all = map.values.toList();
    if (_statusFilter == 'active') {
      return all.where((a) => a.isWorking).toList();
    }
    if (_statusFilter == 'idle') {
      return all.where((a) => !a.isWorking).toList();
    }
    return all;
  }

  void _openAgentModal(BuildContext context, FaberAppState state, FaberAgent agent) {
    final soulController = TextEditingController();
    bool loadedOnce = false;

    state.loadSoul(agent.id).then((_) {
      soulController.text = state.activeSoulContent;
      loadedOnce = true;
    });

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: FaberTokens.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final liveState = modalCtx.watch<FaberAppState>();
            if (!loadedOnce &&
                !liveState.isSoulLoading &&
                liveState.activeSoulContent.isNotEmpty) {
              soulController.text = liveState.activeSoulContent;
              loadedOnce = true;
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              agent.avatar,
                              style: const TextStyle(fontSize: 28),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  agent.name,
                                  style: const TextStyle(
                                    color: FaberTokens.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  agent.role,
                                  style: const TextStyle(
                                    color: FaberTokens.textSecondary,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        FaberPill(
                          label: agent.status.toUpperCase(),
                          color: agent.isWorking
                              ? FaberTokens.accentEmerald
                              : agent.accentColor,
                          showDot: true,
                        ),
                      ],
                    ),
                    if (agent.currentTask.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      FaberGlassCard(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          'Tugas aktif: ${agent.currentTask}',
                          style: const TextStyle(
                            color: FaberTokens.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'SOUL.md Configuration',
                          style: TextStyle(
                            color: FaberTokens.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        FaberGlassButton(
                          label: 'Direct Chat',
                          icon: CupertinoIcons.chat_bubble_2_fill,
                          compact: true,
                          isPrimary: true,
                          onPressed: () {
                            state.selectAgent(agent.id);
                            state.setTaskMode('direct');
                            state.setTabIndex(0);
                            Navigator.pop(ctx);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: FaberTokens.surfaceTerminal,
                        borderRadius: FaberTokens.brMd,
                        border: Border.all(color: FaberTokens.borderGlass),
                      ),
                      child: liveState.isSoulLoading
                          ? const Center(child: CircularProgressIndicator())
                          : TextField(
                              controller: soulController,
                              maxLines: null,
                              expands: true,
                              style: const TextStyle(
                                color: FaberTokens.textCode,
                                fontFamily: 'monospace',
                                fontSize: 12.5,
                                height: 1.4,
                              ),
                              decoration: const InputDecoration(
                                hintText: '# SOUL.md...',
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.all(12),
                              ),
                            ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FaberGlassButton(
                          label: 'Tutup',
                          onPressed: () => Navigator.pop(ctx),
                        ),
                        const SizedBox(width: 10),
                        FaberGlassButton(
                          label: 'Simpan SOUL.md',
                          icon: CupertinoIcons.floppy_disk,
                          isPrimary: true,
                          isLoading: liveState.isSoulSaving,
                          onPressed: () async {
                            final ok = await state.saveSoul(
                              agent.id,
                              soulController.text,
                            );
                            if (!mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok
                                      ? 'SOUL.md ${agent.name} disimpan.'
                                      : 'Gagal menyimpan SOUL.md.',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FaberAppState>();
    final agents = _resolvedAgents(state);
    final activeCount = agents.where((a) => a.isWorking).length;

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
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'War Office • 16 Agen Spesialis',
                          style: TextStyle(
                            color: FaberTokens.textPrimary,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Ketuk agen untuk edit SOUL.md atau Direct Chat',
                          style: TextStyle(
                            color: FaberTokens.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    FaberPill(
                      label: '$activeCount Aktif',
                      color: FaberTokens.accentEmerald,
                      showDot: true,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FaberPill(
                      label: 'Semua (${agents.length})',
                      color: FaberTokens.accentIndigo,
                      selected: _statusFilter == 'all',
                      onTap: () => setState(() => _statusFilter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    FaberPill(
                      label: 'Bekerja',
                      color: FaberTokens.accentEmerald,
                      selected: _statusFilter == 'active',
                      onTap: () => setState(() => _statusFilter = 'active'),
                    ),
                    const SizedBox(width: 8),
                    FaberPill(
                      label: 'Idle',
                      color: FaberTokens.textSecondary,
                      selected: _statusFilter == 'idle',
                      onTap: () => setState(() => _statusFilter = 'idle'),
                    ),
                  ],
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
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.08,
              ),
              itemCount: agents.length,
              itemBuilder: (context, idx) {
                final agent = agents[idx];
                return FaberGlassCard(
                  padding: const EdgeInsets.all(14),
                  borderColor: agent.isWorking
                      ? agent.accentColor.withOpacity(0.55)
                      : FaberTokens.borderGlass,
                  onTap: () => _openAgentModal(context, state, agent),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            agent.avatar,
                            style: const TextStyle(fontSize: 26),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            agent.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: FaberTokens.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            agent.currentTask.isNotEmpty
                                ? agent.currentTask
                                : agent.role,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: FaberTokens.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
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
