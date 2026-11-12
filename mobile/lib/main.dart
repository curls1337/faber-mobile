import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/faber_app_state.dart';
import 'core/tokens.dart';
import 'screens/agents_office_screen.dart';
import 'screens/chat_swarm_screen.dart';
import 'screens/media_library_screen.dart';
import 'screens/projects_studio_screen.dart';
import 'screens/settings_system_screen.dart';
import 'widgets/glass_card.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FaberMobileApp());
}

class FaberMobileApp extends StatelessWidget {
  const FaberMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<FaberAppState>(
      create: (_) => FaberAppState()..init(),
      child: MaterialApp(
        title: 'Faber Studio Mobile',
        debugShowCheckedModeBanner: false,
        theme: FaberTokens.darkTheme,
        home: const AppRootRouter(),
      ),
    );
  }
}

class AppRootRouter extends StatefulWidget {
  const AppRootRouter({super.key});

  @override
  State<AppRootRouter> createState() => _AppRootRouterState();
}

class _AppRootRouterState extends State<AppRootRouter> {
  bool _biometricEnabled = false;
  bool _biometricUnlocked = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricPref();
  }

  Future<void> _loadBiometricPref() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('faber_biometric_enabled') ?? false;
    setState(() {
      _biometricEnabled = enabled;
      _biometricUnlocked = !enabled;
    });
  }

  void _unlockBiometric() {
    setState(() => _biometricUnlocked = true);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FaberAppState>();

    if (!state.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(FaberTokens.accentIndigo),
          ),
        ),
      );
    }

    if (!state.isAuthenticated) {
      return const AuthLoginScreen();
    }

    if (_biometricEnabled && !_biometricUnlocked) {
      return BiometricLockScreen(onUnlock: _unlockBiometric);
    }

    return MainShellScreen(
      biometricEnabled: _biometricEnabled,
      onBiometricChanged: (val) {
        setState(() {
          _biometricEnabled = val;
          _biometricUnlocked = !val || _biometricUnlocked;
        });
      },
    );
  }
}

class AuthLoginScreen extends StatefulWidget {
  const AuthLoginScreen({super.key});

  @override
  State<AuthLoginScreen> createState() => _AuthLoginScreenState();
}

class _AuthLoginScreenState extends State<AuthLoginScreen> {
  final TextEditingController _pwdController = TextEditingController();
  bool _obscureText = true;

  @override
  void dispose() {
    _pwdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FaberAppState>();

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: FaberTokens.ambientTopGlow,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: FaberGlassCard(
                    padding: const EdgeInsets.all(26),
                    radius: FaberTokens.radius2xl,
                    elevated: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              gradient: FaberTokens.accentGradient,
                              borderRadius: FaberTokens.brXl,
                              boxShadow: FaberTokens.glowShadow(
                                FaberTokens.accentIndigo,
                              ),
                            ),
                            child: const Icon(
                              CupertinoIcons.cube_box_fill,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Faber Studio Mobile',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: FaberTokens.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'VisionOS Dark Graphite Liquid Suite\n${state.baseUrl}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: FaberTokens.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (state.errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: FaberTokens.roseSoft,
                              borderRadius: FaberTokens.brMd,
                              border: Border.all(
                                color: FaberTokens.accentRose.withOpacity(0.4),
                              ),
                            ),
                            child: Text(
                              state.errorMessage!,
                              style: const TextStyle(
                                color: FaberTokens.accentRose,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextField(
                          controller: _pwdController,
                          obscureText: _obscureText,
                          style: const TextStyle(
                            color: FaberTokens.textPrimary,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Master Access Password',
                            prefixIcon: const Icon(
                              CupertinoIcons.lock_fill,
                              size: 18,
                              color: FaberTokens.accentCyan,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText
                                    ? CupertinoIcons.eye_slash
                                    : CupertinoIcons.eye,
                                size: 18,
                                color: FaberTokens.textSecondary,
                              ),
                              onPressed: () => setState(
                                () => _obscureText = !_obscureText,
                              ),
                            ),
                          ),
                          onSubmitted: (pwd) => state.login(pwd),
                        ),
                        const SizedBox(height: 18),
                        FaberGlassButton(
                          label: 'Masuk ke Studio VPS',
                          icon: CupertinoIcons.arrow_right_circle_fill,
                          isPrimary: true,
                          isLoading: state.isLoading,
                          onPressed: () => state.login(_pwdController.text),
                        ),
                        const SizedBox(height: 12),
                        FaberGlassButton(
                          label: 'Coba Mode Demo Interaktif',
                          icon: CupertinoIcons.sparkles,
                          onPressed: () => state.enterDemoMode(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BiometricLockScreen extends StatelessWidget {
  final VoidCallback onUnlock;

  const BiometricLockScreen({super.key, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: FaberGlassCard(
            padding: const EdgeInsets.all(28),
            radius: FaberTokens.radius2xl,
            elevated: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: FaberTokens.accentIndigo.withOpacity(0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: FaberTokens.accentIndigo.withOpacity(0.5),
                    ),
                  ),
                  child: const Icon(
                    CupertinoIcons.lock_shield_fill,
                    size: 36,
                    color: FaberTokens.accentCyan,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Faber Mobile Terkunci',
                  style: TextStyle(
                    color: FaberTokens.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Gunakan Face ID atau sidik jari untuk melanjutkan kontrol studio.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: FaberTokens.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 22),
                FaberGlassButton(
                  label: 'Verifikasi Face ID',
                  icon: CupertinoIcons.viewfinder,
                  isPrimary: true,
                  onPressed: onUnlock,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MainShellScreen extends StatelessWidget {
  final bool biometricEnabled;
  final ValueChanged<bool>? onBiometricChanged;

  const MainShellScreen({
    super.key,
    this.biometricEnabled = false,
    this.onBiometricChanged,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FaberAppState>();

    final screens = [
      const ChatSwarmScreen(),
      const ProjectsStudioScreen(),
      const AgentsOfficeScreen(),
      const MediaLibraryScreen(),
      SettingsSystemScreen(
        biometricEnabled: biometricEnabled,
        onBiometricChanged: onBiometricChanged,
      ),
    ];

    final titles = [
      'Swarm Studio',
      'Code & Cloud',
      'War Office',
      'Media Vault',
      'VPS Settings',
    ];

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: FaberTokens.accentGradient,
                borderRadius: FaberTokens.brSm,
              ),
              child: const Icon(
                CupertinoIcons.cube_box_fill,
                color: Colors.white,
                size: 15,
              ),
            ),
            const SizedBox(width: 10),
            Text(titles[state.activeTabIndex]),
          ],
        ),
        actions: [
          if (state.isRefreshing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(FaberTokens.accentCyan),
                ),
              ),
            )
          else
            IconButton(
              tooltip: 'Segarkan',
              icon: const Icon(
                CupertinoIcons.arrow_clockwise,
                size: 20,
                color: FaberTokens.textSecondary,
              ),
              onPressed: state.refreshAll,
            ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: screens[state.activeTabIndex],
      ),
      bottomNavigationBar: _BottomGlassDock(
        currentIndex: state.activeTabIndex,
        onTap: (index) => state.setTabIndex(index),
      ),
    );
  }
}

class _BottomGlassDock extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomGlassDock({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      (CupertinoIcons.chat_bubble_2_fill, 'Swarm'),
      (CupertinoIcons.hammer_fill, 'Studio'),
      (CupertinoIcons.person_3_fill, 'War Office'),
      (CupertinoIcons.photo_on_rectangle, 'Media'),
      (CupertinoIcons.gear_alt_fill, 'Settings'),
    ];

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: BoxDecoration(
          borderRadius: FaberTokens.brPill,
          boxShadow: FaberTokens.glassShadow,
        ),
        child: ClipRRect(
          borderRadius: FaberTokens.brPill,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: FaberTokens.blurSigmaHeavy,
              sigmaY: FaberTokens.blurSigmaHeavy,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: FaberTokens.surfaceGlassElevated,
                borderRadius: FaberTokens.brPill,
                border: Border.all(
                  color: FaberTokens.borderGlassStrong,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (idx) {
                  final item = items[idx];
                  final isSelected = currentIndex == idx;
                  return InkWell(
                    onTap: () => onTap(idx),
                    borderRadius: FaberTokens.brPill,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected ? FaberTokens.accentGradient : null,
                        borderRadius: FaberTokens.brPill,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.$1,
                            size: 19,
                            color: isSelected
                                ? Colors.white
                                : FaberTokens.textSecondary,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.$2,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : FaberTokens.textSecondary,
                              fontSize: 10.5,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
