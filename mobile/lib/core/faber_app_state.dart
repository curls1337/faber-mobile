import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/faber_models.dart';
import '../services/faber_api_client.dart';

/// Central ChangeNotifier state management for Faber Studio Mobile's 5 modules:
/// 1. Auth & Server Connection
/// 2. Swarm / Direct Agent Chat & Sessions
/// 3. Code Studio & Remote Terminal
/// 4. War Office & Agent Souls
/// 5. Media Vault, Automations, Cloud Apps & System Stats
class FaberAppState extends ChangeNotifier {
  static const String _prefBaseUrl = 'faber_base_url';
  static const String _prefToken = 'faber_auth_token';
  static const String _prefTab = 'faber_active_tab';
  static const String _prefSiteSlug = 'faber_selected_site';
  static const String _prefAgentId = 'faber_selected_agent';
  static const String _prefSessionId = 'faber_selected_session';
  static const String _prefTaskMode = 'faber_task_mode';

  late final FaberApiClient api;
  SharedPreferences? _prefs;

  // Auth & App Shell State
  bool isInitialized = false;
  bool isAuthenticated = false;
  bool passwordRequired = true;
  bool isLoading = false;
  bool isRefreshing = false;
  bool isDemoMode = false;
  String? errorMessage;
  int activeTabIndex = 0;

  // Bootstrap Data
  List<FaberAgent> agents = [];
  List<FaberSite> sites = [];
  List<FaberSession> sessions = [];
  List<FaberMediaItem> mediaItems = [];
  List<String> skills = [];
  List<FaberAutomation> automations = [];
  List<FaberCloudApp> cloudApps = [];
  FaberSystemStats systemStats = const FaberSystemStats();

  // Module 1: Swarm / Chat State
  String selectedSessionId = 'default';
  String selectedAgentId = '';
  String taskMode = 'swarm'; // swarm | direct
  List<FaberMessage> messages = [];
  bool isStreaming = false;
  StreamSubscription<FaberStreamEvent>? _streamSub;

  // Module 2: Code Studio & Terminal State
  String selectedSiteSlug = '';
  List<FaberFileNode> fileTree = [];
  List<String> flatFiles = [];
  String siteBranch = 'main';
  String siteCommit = '';
  String activeFilePath = '';
  String activeFileContent = '';
  bool isFileLoading = false;
  bool isFileSaving = false;
  String terminalOutput = '';
  bool isTerminalRunning = false;

  // Module 3: War Office & Souls State
  List<FaberWarOfficeDesk> warOfficeDesks = [];
  int warOfficeActiveCount = 0;
  String activeSoulContent = '';
  bool isSoulLoading = false;
  bool isSoulSaving = false;

  FaberAppState() {
    api = FaberApiClient(
      baseUrl: FaberApiClient.defaultBaseUrl,
      onUnauthorized: _handleUnauthorized,
    );
  }

  String get baseUrl => api.baseUrl;

  void _handleUnauthorized() {
    isAuthenticated = false;
    _prefs?.remove(_prefToken);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Lifecycle & Auth Persistence
  // ---------------------------------------------------------------------------
  Future<void> init() async {
    if (isInitialized) return;
    isLoading = true;
    notifyListeners();

    try {
      _prefs = await SharedPreferences.getInstance();
      final savedUrl = _prefs?.getString(_prefBaseUrl);
      final savedToken = _prefs?.getString(_prefToken);
      activeTabIndex = _prefs?.getInt(_prefTab) ?? 0;
      selectedSiteSlug = _prefs?.getString(_prefSiteSlug) ?? '';
      selectedAgentId = _prefs?.getString(_prefAgentId) ?? '';
      if (selectedSiteSlug.isNotEmpty) {
        selectedSessionId = selectedSiteSlug == '_server'
            ? 'faber-server'
            : 'faber-proj-$selectedSiteSlug';
      } else {
        selectedSessionId = _prefs?.getString(_prefSessionId) ?? 'default';
      }
      taskMode = _prefs?.getString(_prefTaskMode) ?? 'swarm';

      if (savedUrl != null && savedUrl.isNotEmpty) {
        api.setBaseUrl(savedUrl);
      }
      if (savedToken != null && savedToken.isNotEmpty) {
        api.setToken(savedToken);
      }

      final auth = await api.checkAuth();
      passwordRequired = auth.passwordRequired;
      isAuthenticated = auth.authenticated || !auth.passwordRequired;

      if (isAuthenticated) {
        await refreshAll();
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isInitialized = true;
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final token = await api.login(password);
      if (token.isNotEmpty) {
        await _prefs?.setString(_prefToken, token);
      }
      isAuthenticated = true;
      isDemoMode = false;
      await refreshAll();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      isAuthenticated = false;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void enterDemoMode() {
    isDemoMode = true;
    isAuthenticated = true;
    errorMessage = null;
    _loadFallbackDemoData();
    notifyListeners();
  }

  Future<void> logout() async {
    await _streamSub?.cancel();
    api.setToken(null);
    await _prefs?.remove(_prefToken);
    isAuthenticated = false;
    isDemoMode = false;
    messages = [];
    notifyListeners();
  }

  Future<void> updateBaseUrl(String newUrl) async {
    api.setBaseUrl(newUrl);
    await _prefs?.setString(_prefBaseUrl, api.baseUrl);
    errorMessage = null;
    notifyListeners();
    if (isAuthenticated && !isDemoMode) {
      await refreshAll();
    }
  }

  void setTabIndex(int index) {
    activeTabIndex = index;
    _prefs?.setInt(_prefTab, index);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Global Pull-to-Refresh across all 5 modules
  // ---------------------------------------------------------------------------
  Future<void> refreshAll() async {
    if (isDemoMode) {
      _loadFallbackDemoData();
      notifyListeners();
      return;
    }

    isRefreshing = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = await api.bootstrap();
      agents = data.agents;
      sites = data.sites;
      sessions = data.sessions;
      mediaItems = data.library;
      skills = data.skills;
      automations = data.automations;
      cloudApps = data.cloudApps;
      systemStats = data.system;

      if (selectedAgentId.isEmpty && agents.isNotEmpty) {
        selectedAgentId = agents.first.id;
      }
      if (selectedSiteSlug.isEmpty && sites.isNotEmpty) {
        selectedSiteSlug = sites.first.slug;
      }

      await Future.wait([
        loadHistory(),
        loadWarOffice(),
        if (selectedSiteSlug.isNotEmpty) loadSiteTree(),
      ]);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isRefreshing = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Module 1: Swarm & Direct Chat
  // ---------------------------------------------------------------------------
  Future<void> loadHistory() async {
    if (isDemoMode) return;
    try {
      messages = await api.getHistory(
        sessionId: selectedSessionId,
        agentId: taskMode == 'direct' ? selectedAgentId : null,
      );
      notifyListeners();
    } catch (_) {
      // Keep existing messages if history endpoint returns empty/error
    }
  }

  void setTaskMode(String mode) {
    taskMode = mode;
    _prefs?.setString(_prefTaskMode, mode);
    notifyListeners();
  }

  void selectAgent(String agentId) {
    selectedAgentId = agentId;
    _prefs?.setString(_prefAgentId, agentId);
    notifyListeners();
  }

  Future<void> selectSession(String sessionId) async {
    selectedSessionId = sessionId;
    await _prefs?.setString(_prefSessionId, sessionId);
    notifyListeners();
    await loadHistory();
  }

  Future<void> sendPrompt(String prompt) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty || isStreaming) return;

    final userMsg = FaberMessage(
      id: 'u_${DateTime.now().microsecondsSinceEpoch}',
      role: 'user',
      content: trimmed,
      timestamp: DateTime.now(),
    );
    final assistantId = 'a_${DateTime.now().microsecondsSinceEpoch}';
    final assistantPlaceholder = FaberMessage(
      id: assistantId,
      role: 'assistant',
      content: '',
      agentId: selectedAgentId,
      agentName: taskMode == 'swarm' ? 'Faber Swarm' : selectedAgentId,
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    messages = [...messages, userMsg, assistantPlaceholder];
    isStreaming = true;
    notifyListeners();

    if (isDemoMode) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      _updateAssistantMessage(
        assistantId,
        '[Demo Mode] Perintah "$trimmed" diterima pada mode $taskMode. Hubungkan ke https://webui.5nod.com untuk eksekusi live.',
        done: true,
      );
      return;
    }

    final buffer = StringBuffer();
    try {
      await _streamSub?.cancel();
      final stream = api.sendTaskStream(
        prompt: trimmed,
        mode: taskMode,
        agentId: selectedAgentId,
        sessionId: selectedSessionId,
        projectSlug: selectedSiteSlug,
      );

      _streamSub = stream.listen(
        (evt) {
          if (evt.text.isNotEmpty) {
            buffer.write(evt.text);
            _updateAssistantMessage(
              assistantId,
              buffer.toString(),
              agentName: evt.agentName,
              done: false,
            );
          }
          if (evt.event == 'done') {
            _updateAssistantMessage(
              assistantId,
              buffer.isEmpty ? 'Selesai.' : buffer.toString(),
              done: true,
            );
          }
        },
        onError: (Object err) {
          _updateAssistantMessage(
            assistantId,
            'Error: $err',
            done: true,
          );
        },
        onDone: () {
          if (isStreaming) {
            _updateAssistantMessage(
              assistantId,
              buffer.isEmpty ? 'Selesai.' : buffer.toString(),
              done: true,
            );
          }
        },
      );
    } catch (e) {
      _updateAssistantMessage(assistantId, 'Gagal mengirim task: $e', done: true);
    }
  }

  void _updateAssistantMessage(
    String id,
    String content, {
    String? agentName,
    required bool done,
  }) {
    final idx = messages.indexWhere((m) => m.id == id);
    if (idx != -1) {
      final updated = List<FaberMessage>.from(messages);
      updated[idx] = updated[idx].copyWith(
        content: content,
        agentName: agentName ?? updated[idx].agentName,
        isStreaming: !done,
      );
      messages = updated;
    }
    if (done) {
      isStreaming = false;
    }
    notifyListeners();
  }

  Future<void> abortStreaming() async {
    await _streamSub?.cancel();
    _streamSub = null;
    if (!isDemoMode) {
      try {
        await api.abortTask(selectedSessionId);
      } catch (_) {}
    }
    if (isStreaming) {
      isStreaming = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Module 2: Code Studio & Terminal
  // ---------------------------------------------------------------------------
  Future<void> selectSite(String slug) async {
    selectedSiteSlug = slug;
    activeFilePath = '';
    activeFileContent = '';
    await _prefs?.setString(_prefSiteSlug, slug);

    // Each project has its own dedicated session & chat history!
    final projSessionId = slug == '_server' ? 'faber-server' : 'faber-proj-$slug';
    selectedSessionId = projSessionId;
    await _prefs?.setString(_prefSessionId, projSessionId);
    messages = []; // Clear previous project messages to prevent leaking
    notifyListeners();

    await Future.wait([
      loadSiteTree(),
      loadHistory(),
    ]);
  }

  Future<void> loadSiteTree() async {
    if (selectedSiteSlug.isEmpty || isDemoMode) return;
    try {
      final res = await api.getSiteTree(selectedSiteSlug);
      fileTree = res.tree;
      flatFiles = res.flatFiles;
      siteBranch = res.branch;
      siteCommit = res.commit;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> openFile(String filePath) async {
    if (selectedSiteSlug.isEmpty) return;
    activeFilePath = filePath;
    isFileLoading = true;
    notifyListeners();

    try {
      if (isDemoMode) {
        activeFileContent = '// Demo preview: $filePath';
      } else {
        activeFileContent = await api.getSiteFile(selectedSiteSlug, filePath);
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isFileLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveFile(String newContent) async {
    if (selectedSiteSlug.isEmpty || activeFilePath.isEmpty) return false;
    isFileSaving = true;
    notifyListeners();

    try {
      if (!isDemoMode) {
        await api.saveSiteFile(selectedSiteSlug, activeFilePath, newContent);
      }
      activeFileContent = newContent;
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isFileSaving = false;
      notifyListeners();
    }
  }

  Future<void> runTerminalCommand(String command) async {
    final cmd = command.trim();
    if (cmd.isEmpty) return;
    isTerminalRunning = true;
    terminalOutput += '\n\$ $cmd\n';
    notifyListeners();

    try {
      if (isDemoMode) {
        terminalOutput += '[Demo] Executed: $cmd\n';
      } else {
        final res = await api.execTerminal(cmd);
        terminalOutput += res.output;
        if (!res.output.endsWith('\n')) terminalOutput += '\n';
        terminalOutput += '[exit ${res.exitCode}]\n';
      }
    } catch (e) {
      terminalOutput += '[error] $e\n';
    } finally {
      isTerminalRunning = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Module 3: War Office & Agent Souls
  // ---------------------------------------------------------------------------
  Future<void> loadWarOffice({String board = 'office-software'}) async {
    if (isDemoMode) return;
    try {
      final state = await api.getWarOfficeState(board: board);
      warOfficeDesks = state.desks;
      warOfficeActiveCount = state.activeCount;
      notifyListeners();
    } catch (_) {
      // Non-fatal background refresh
    }
  }

  Future<void> loadSoul(String agentId, {String type = 'SOUL.md'}) async {
    isSoulLoading = true;
    notifyListeners();
    try {
      if (isDemoMode) {
        activeSoulContent = '# $agentId ($type)\nDemo Soul configuration.';
      } else {
        activeSoulContent = await api.getSoul(agentId, type: type);
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isSoulLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveSoul(
    String agentId,
    String content, {
    String type = 'SOUL.md',
  }) async {
    isSoulSaving = true;
    notifyListeners();
    try {
      if (!isDemoMode) {
        await api.updateSoul(agentId, content, type: type);
      }
      activeSoulContent = content;
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isSoulSaving = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Module 4 & 5: Automations & Media
  // ---------------------------------------------------------------------------
  Future<void> runAutomation(String jobId) async {
    try {
      if (!isDemoMode) {
        await api.runCron(jobId);
      }
      final idx = automations.indexWhere((a) => a.id == jobId);
      if (idx != -1) {
        final copy = List<FaberAutomation>.from(automations);
        copy[idx] = copy[idx].copyWith(
          lastStatus: 'running',
          lastRun: DateTime.now(),
        );
        automations = copy;
        notifyListeners();
      }
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleAutomation(String jobId, bool enabled) async {
    final idx = automations.indexWhere((a) => a.id == jobId);
    if (idx != -1) {
      final copy = List<FaberAutomation>.from(automations);
      copy[idx] = copy[idx].copyWith(enabled: enabled);
      automations = copy;
      notifyListeners();
    }
    try {
      if (!isDemoMode) {
        await api.toggleCron(jobId, enabled);
      }
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Offline / Demo Seed Fallback
  // ---------------------------------------------------------------------------
  void _loadFallbackDemoData() {
    agents = const [
      FaberAgent(
        id: 'orchestrator',
        name: 'Faber Orchestrator',
        role: 'Swarm Lead',
        avatar: '🧠',
        status: 'active',
        model: 'claude-3.7-sonnet',
        currentTask: 'Coordinating mobile build',
        colorHex: '#6366F1',
      ),
      FaberAgent(
        id: 'team-engineer',
        name: 'Team Engineer',
        role: 'Full-Stack & Mobile',
        avatar: '⚡',
        status: 'working',
        model: 'gemini-2.5-pro',
        currentTask: 'Building Flutter core tokens',
        colorHex: '#22D3EE',
      ),
      FaberAgent(
        id: 'team-qa-security',
        name: 'QA & Security',
        role: 'Verification',
        avatar: '🛡️',
        status: 'idle',
        model: 'gpt-4o',
        colorHex: '#10B981',
      ),
    ];
    sites = const [
      FaberSite(
        slug: 'faber-mobile',
        name: 'Faber Studio Mobile',
        description: 'Flutter iOS & Android Control Suite',
        branch: 'main',
        status: 'active',
        framework: 'flutter',
      ),
    ];
    selectedSiteSlug = 'faber-mobile';
    selectedAgentId = 'orchestrator';
    systemStats = const FaberSystemStats(
      totalMemBytes: 16 * 1024 * 1024 * 1024,
      freeMemBytes: 9 * 1024 * 1024 * 1024,
      uptimeSeconds: 432100,
      hostname: 'webui.5nod.com',
    );
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }
}
