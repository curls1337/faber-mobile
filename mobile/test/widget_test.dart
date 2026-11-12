import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:faber_mobile/core/faber_app_state.dart';
import 'package:faber_mobile/core/tokens.dart';
import 'package:faber_mobile/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FaberAppState Unit Tests', () {
    test('enterDemoMode populates agents, sites, and systemStats', () {
      final state = FaberAppState();
      expect(state.isAuthenticated, isFalse);

      state.enterDemoMode();

      expect(state.isDemoMode, isTrue);
      expect(state.isAuthenticated, isTrue);
      expect(state.agents, isNotEmpty);
      expect(state.sites, isNotEmpty);
      expect(state.systemStats.hostname, equals('webui.5nod.com'));
    });

    test('setTabIndex and setTaskMode update state cleanly', () {
      final state = FaberAppState();
      state.setTabIndex(2);
      state.setTaskMode('direct');

      expect(state.activeTabIndex, equals(2));
      expect(state.taskMode, equals('direct'));
    });

    test('sendPrompt in demo mode appends user and assistant messages', () async {
      final state = FaberAppState();
      state.enterDemoMode();

      await state.sendPrompt('Cek status VPS');

      expect(state.messages.length, equals(2));
      expect(state.messages.first.isUser, isTrue);
      expect(state.messages.first.content, equals('Cek status VPS'));
      expect(state.messages.last.isAssistant, isTrue);
      expect(state.messages.last.isStreaming, isFalse);
    });
  });

  group('Widget Smoke Tests', () {
    testWidgets('AuthLoginScreen renders login and demo mode controls',
        (WidgetTester tester) async {
      final state = FaberAppState()..isInitialized = true;

      await tester.pumpWidget(
        ChangeNotifierProvider<FaberAppState>.value(
          value: state,
          child: MaterialApp(
            theme: FaberTokens.darkTheme,
            home: const AppRootRouter(),
          ),
        ),
      );

      expect(find.text('Faber Studio Mobile'), findsOneWidget);
      expect(find.text('Masuk ke Studio VPS'), findsOneWidget);
      expect(find.text('Coba Mode Demo Interaktif'), findsOneWidget);

      await tester.tap(find.text('Coba Mode Demo Interaktif'));
      await tester.pumpAndSettle();

      expect(state.isAuthenticated, isTrue);
      expect(find.text('Swarm Studio'), findsOneWidget);
      expect(find.text('War Office'), findsOneWidget);
    });

    testWidgets('MainShellScreen switches between 5 bottom dock tabs',
        (WidgetTester tester) async {
      final state = FaberAppState()
        ..isInitialized = true
        ..enterDemoMode();

      await tester.pumpWidget(
        ChangeNotifierProvider<FaberAppState>.value(
          value: state,
          child: MaterialApp(
            theme: FaberTokens.darkTheme,
            home: const MainShellScreen(),
          ),
        ),
      );

      expect(find.text('Swarm Studio'), findsOneWidget);

      await tester.tap(find.text('War Office'));
      await tester.pumpAndSettle();
      expect(state.activeTabIndex, equals(2));
      expect(find.text('War Office • 16 Agen Spesialis'), findsOneWidget);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(state.activeTabIndex, equals(4));
      expect(find.text('Telemetri VPS'), findsOneWidget);
    });
  });
}
