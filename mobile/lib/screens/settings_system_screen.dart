import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/faber_app_state.dart';
import '../core/tokens.dart';
import '../models/faber_models.dart';
import '../widgets/glass_card.dart';

class SettingsSystemScreen extends StatefulWidget {
  final bool biometricEnabled;
  final ValueChanged<bool>? onBiometricChanged;

  const SettingsSystemScreen({
    super.key,
    this.biometricEnabled = false,
    this.onBiometricChanged,
  });

  @override
  State<SettingsSystemScreen> createState() => _SettingsSystemScreenState();
}

class _SettingsSystemScreenState extends State<SettingsSystemScreen> {
  late TextEditingController _urlController;
  int? _lastPingMs;
  bool _isPinging = false;
  String? _pingStatus;
  late bool _biometricLocal;

  @override
  void initState() {
    super.initState();
    final state = context.read<FaberAppState>();
    _urlController = TextEditingController(text: state.baseUrl);
    _biometricLocal = widget.biometricEnabled;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _runPingTest(FaberAppState state) async {
    setState(() {
      _isPinging = true;
      _pingStatus = null;
    });
    final sw = Stopwatch()..start();
    try {
      await state.api.checkAuth();
      sw.stop();
      if (!mounted) return;
      setState(() {
        _lastPingMs = sw.elapsedMilliseconds;
        _pingStatus = 'Terhubung (${_lastPingMs} ms)';
      });
    } catch (e) {
      sw.stop();
      if (!mounted) return;
      setState(() {
        _lastPingMs = null;
        _pingStatus = state.isDemoMode
            ? 'Demo Mode (${sw.elapsedMilliseconds} ms lokal)'
            : 'Gagal ping: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isPinging = false);
      }
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    setState(() => _biometricLocal = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('faber_biometric_enabled', value);
    widget.onBiometricChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FaberAppState>();
    final sys = state.systemStats;
    final memPct = (sys.memUsagePercent / 100.0).clamp(0.0, 1.0);
    final avgCpu = state.cloudApps.isNotEmpty
        ? state.cloudApps.map((c) => c.cpuPercent).reduce((a, b) => a + b) /
            state.cloudApps.length
        : 18.4;

    return RefreshIndicator(
      color: FaberTokens.accentIndigo,
      backgroundColor: FaberTokens.bgElevated,
      onRefresh: state.refreshAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        children: [
          // VPS Telemetry Bento Card
          FaberGlassCard(
            elevated: true,
            gradient: FaberTokens.heroGradient,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Telemetri VPS',
                          style: TextStyle(
                            color: FaberTokens.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${sys.hostname} • Uptime ${sys.formattedUptime}',
                          style: const TextStyle(
                            color: FaberTokens.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    FaberPill(
                      label: state.isDemoMode ? 'DEMO' : 'ONLINE',
                      color: state.isDemoMode
                          ? FaberTokens.accentAmber
                          : FaberTokens.accentEmerald,
                      showDot: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'RAM Usage',
                      style: TextStyle(
                        color: FaberTokens.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                    Text(
                      '${sys.formattedRam} (${sys.memUsagePercent.toStringAsFixed(0)}%)',
                      style: const TextStyle(
                        color: FaberTokens.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: FaberTokens.brPill,
                  child: LinearProgressIndicator(
                    value: memPct,
                    minHeight: 8,
                    backgroundColor: FaberTokens.surfaceGlassLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      FaberTokens.accentCyan,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _TelemetryMiniTile(
                        label: 'CPU Load',
                        value: '${avgCpu.toStringAsFixed(1)}%',
                        color: FaberTokens.accentIndigo,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: _TelemetryMiniTile(
                        label: 'Disk NVMe',
                        value: '42% Used',
                        color: FaberTokens.accentEmerald,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Server Endpoint & Ping Latency Test
          FaberGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Server Endpoint & Ping',
                      style: TextStyle(
                        color: FaberTokens.textPrimary,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_lastPingMs != null)
                      FaberPill(
                        label: '${_lastPingMs} ms',
                        color: _lastPingMs! < 250
                            ? FaberTokens.accentEmerald
                            : FaberTokens.accentAmber,
                        showDot: true,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  style: const TextStyle(
                    color: FaberTokens.textPrimary,
                    fontSize: 13.5,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Faber Studio Server URL',
                    hintText: 'https://webui.5nod.com',
                    prefixIcon: Icon(
                      CupertinoIcons.globe,
                      size: 18,
                      color: FaberTokens.accentCyan,
                    ),
                  ),
                ),
                if (_pingStatus != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _pingStatus!,
                    style: const TextStyle(
                      color: FaberTokens.accentCyan,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FaberGlassButton(
                        label: 'Simpan URL',
                        icon: CupertinoIcons.checkmark_alt,
                        isPrimary: true,
                        onPressed: () async {
                          await state.updateBaseUrl(_urlController.text);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Endpoint diperbarui ke ${state.baseUrl}',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FaberGlassButton(
                        label: 'Ping Latency',
                        icon: CupertinoIcons.speedometer,
                        isLoading: _isPinging,
                        onPressed: () => _runPingTest(state),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Security & Face ID Toggle
          FaberGlassCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.lock_shield_fill,
                        color: FaberTokens.accentIndigo,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kunci Biometrik / Face ID',
                              style: TextStyle(
                                color: FaberTokens.textPrimary,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Minta verifikasi saat membuka aplikasi',
                              style: TextStyle(
                                color: FaberTokens.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoSwitch(
                  value: _biometricLocal,
                  activeTrackColor: FaberTokens.accentIndigo,
                  onChanged: _toggleBiometric,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Cron Automations
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Otomasi & Cron Jobs',
                style: TextStyle(
                  color: FaberTokens.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              FaberPill(
                label: '${state.automations.length} Jobs',
                color: FaberTokens.accentViolet,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (state.automations.isEmpty)
            const FaberGlassCard(
              child: Text(
                'Belum ada cron job terjadwal.',
                style: TextStyle(color: FaberTokens.textSecondary),
              ),
            )
          else
            ...state.automations.map(
              (job) => _CronJobTile(
                job: job,
                onToggle: (val) => state.toggleAutomation(job.id, val),
                onRun: () => state.runAutomation(job.id),
              ),
            ),

          const SizedBox(height: 16),

          // Skills Chips
          const Text(
            'Active Skills',
            style: TextStyle(
              color: FaberTokens.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          FaberGlassCard(
            child: state.skills.isEmpty
                ? const Text(
                    'Skills terintegrasi otomatis melalui Faber Orchestrator.',
                    style: TextStyle(
                      color: FaberTokens.textSecondary,
                      fontSize: 13,
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: state.skills
                        .map(
                          (s) => FaberPill(
                            label: s,
                            color: FaberTokens.accentCyan,
                          ),
                        )
                        .toList(),
                  ),
          ),

          const SizedBox(height: 20),
          FaberGlassButton(
            label: 'Keluar Sesi (Logout)',
            icon: CupertinoIcons.square_arrow_left,
            isDestructive: true,
            onPressed: () => state.logout(),
          ),
        ],
      ),
    );
  }
}

class _TelemetryMiniTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TelemetryMiniTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: FaberTokens.surfaceGlassLight,
        borderRadius: FaberTokens.brMd,
        border: Border.all(color: FaberTokens.borderGlass),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: FaberTokens.textSecondary,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CronJobTile extends StatelessWidget {
  final FaberAutomation job;
  final ValueChanged<bool> onToggle;
  final VoidCallback onRun;

  const _CronJobTile({
    required this.job,
    required this.onToggle,
    required this.onRun,
  });

  @override
  Widget build(BuildContext context) {
    return FaberGlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.name,
                      style: const TextStyle(
                        color: FaberTokens.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${job.schedule} • ${job.lastStatus}',
                      style: const TextStyle(
                        color: FaberTokens.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: job.enabled,
                activeTrackColor: FaberTokens.accentEmerald,
                onChanged: onToggle,
              ),
            ],
          ),
          const SizedBox(height: 8),
          FaberGlassButton(
            label: 'Jalankan Sekarang',
            icon: CupertinoIcons.play_fill,
            compact: true,
            onPressed: onRun,
          ),
        ],
      ),
    );
  }
}
