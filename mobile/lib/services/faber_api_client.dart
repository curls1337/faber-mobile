import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/faber_models.dart';

/// Exception thrown by [FaberApiClient] on HTTP or protocol failures.
class FaberApiException implements Exception {
  final int statusCode;
  final String message;

  const FaberApiException(this.statusCode, this.message);

  bool get isUnauthorized => statusCode == 401 || statusCode == 403;

  @override
  String toString() => 'FaberApiException($statusCode): $message';
}

/// Represents an incremental event emitted by `POST /api/task` (SSE or JSON).
class FaberStreamEvent {
  final String event; // delta | agent | status | done | error
  final String text;
  final String? agentId;
  final String? agentName;
  final Map<String, dynamic> raw;

  const FaberStreamEvent({
    required this.event,
    this.text = '',
    this.agentId,
    this.agentName,
    this.raw = const {},
  });
}

/// REST & SSE Streaming Client for Faber Studio VPS (`https://webui.5nod.com`).
class FaberApiClient {
  static const String defaultBaseUrl = 'https://webui.5nod.com';

  String _baseUrl;
  String? _token;
  final http.Client _http;
  final void Function()? onUnauthorized;

  FaberApiClient({
    String baseUrl = defaultBaseUrl,
    String? token,
    http.Client? httpClient,
    this.onUnauthorized,
  })  : _baseUrl = _normalizeUrl(baseUrl),
        _token = token,
        _http = httpClient ?? http.Client();

  String get baseUrl => _baseUrl;
  String? get token => _token;

  static String _normalizeUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return defaultBaseUrl;
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  void setBaseUrl(String url) {
    _baseUrl = _normalizeUrl(url);
  }

  void setToken(String? token) {
    _token = (token != null && token.trim().isNotEmpty) ? token.trim() : null;
  }

  Map<String, String> get authHeaders => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$_baseUrl$path');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      ...query,
    });
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
    Duration timeout = const Duration(seconds: 25),
  }) async {
    final uri = _uri(path, query);
    late http.Response response;

    switch (method) {
      case 'GET':
        response = await _http.get(uri, headers: authHeaders).timeout(timeout);
        break;
      case 'POST':
        response = await _http
            .post(
              uri,
              headers: authHeaders,
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(timeout);
        break;
      case 'PUT':
        response = await _http
            .put(
              uri,
              headers: authHeaders,
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(timeout);
        break;
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      onUnauthorized?.call();
      throw FaberApiException(
        response.statusCode,
        'Sesi tidak valid atau membutuhkan login.',
      );
    }

    Map<String, dynamic> decoded = {};
    if (response.body.isNotEmpty) {
      try {
        final raw = jsonDecode(response.body);
        if (raw is Map<String, dynamic>) {
          decoded = raw;
        } else {
          decoded = {'ok': true, 'data': raw};
        }
      } catch (_) {
        if (response.statusCode >= 400) {
          throw FaberApiException(response.statusCode, response.body);
        }
        return {'ok': true, 'raw': response.body};
      }
    }

    if (response.statusCode >= 400 || decoded['ok'] == false) {
      final msg = decoded['error']?.toString() ??
          decoded['message']?.toString() ??
          'Request failed (${response.statusCode})';
      throw FaberApiException(response.statusCode, msg);
    }

    return decoded;
  }

  // ---------------------------------------------------------------------------
  // Auth Endpoints
  // ---------------------------------------------------------------------------
  Future<({bool authenticated, bool passwordRequired})> checkAuth() async {
    final data = await _request('GET', '/api/auth/check');
    return (
      authenticated: data['authenticated'] == true,
      passwordRequired: data['passwordRequired'] != false,
    );
  }

  Future<String> login(String password) async {
    final data = await _request(
      'POST',
      '/api/auth',
      body: {'password': password},
    );
    final token = data['token']?.toString() ?? '';
    if (token.isNotEmpty) {
      setToken(token);
    }
    return token;
  }

  // ---------------------------------------------------------------------------
  // Bootstrap & History
  // ---------------------------------------------------------------------------
  Future<FaberBootstrapData> bootstrap() async {
    final data = await _request('GET', '/api/bootstrap');
    return FaberBootstrapData.fromJson(data);
  }

  Future<List<FaberMessage>> getHistory({
    String? sessionId,
    String? agentId,
  }) async {
    final query = <String, String>{};
    if (sessionId != null && sessionId.isNotEmpty) {
      query['sessionId'] = sessionId;
    }
    if (agentId != null && agentId.isNotEmpty) {
      query['agentId'] = agentId;
    }
    final data = await _request('GET', '/api/history', query: query);
    final rawMsgs = data['messages'];
    if (rawMsgs is! List) return [];
    return rawMsgs
        .whereType<Map>()
        .map((e) => FaberMessage.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Task Execution (SSE Streaming + JSON Auto-Fallback)
  // ---------------------------------------------------------------------------
  Stream<FaberStreamEvent> sendTaskStream({
    required String prompt,
    String mode = 'swarm',
    String? agentId,
    String? sessionId,
    String? projectSlug,
  }) async* {
    Future<http.StreamedResponse> openStream(String path) {
      final uri = _uri(path);
      final request = http.Request('POST', uri)
        ..headers.addAll({
          ...authHeaders,
          'Accept': 'text/event-stream, application/json',
        })
        ..body = jsonEncode({
          'prompt': prompt,
          'mode': mode,
          if (agentId != null && agentId.isNotEmpty) 'agentId': agentId,
          if (sessionId != null && sessionId.isNotEmpty) 'sessionId': sessionId,
          if (projectSlug != null && projectSlug.isNotEmpty)
            'projectSlug': projectSlug,
        });
      return _http.send(request).timeout(const Duration(seconds: 45));
    }

    var streamed = await openStream('/api/task/stream');
    // Auto-fallback to /api/task for legacy/custom endpoints
    if (streamed.statusCode == 404) {
      await streamed.stream.drain<void>();
      streamed = await openStream('/api/task');
    }

    if (streamed.statusCode == 401 || streamed.statusCode == 403) {
      onUnauthorized?.call();
      throw FaberApiException(streamed.statusCode, 'Autentikasi diperlukan.');
    }

    if (streamed.statusCode >= 400) {
      final errBody = await streamed.stream.bytesToString();
      throw FaberApiException(
        streamed.statusCode,
        errBody.isNotEmpty ? errBody : 'Task request failed',
      );
    }

    final contentType =
        (streamed.headers['content-type'] ?? '').toLowerCase();

    // Auto-fallback: if server responds with JSON instead of SSE stream
    if (contentType.contains('application/json')) {
      final rawText = await streamed.stream.bytesToString();
      try {
        final json = jsonDecode(rawText);
        if (json is Map<String, dynamic>) {
          final reply = json['reply']?.toString() ??
              json['output']?.toString() ??
              json['message']?.toString() ??
              json['content']?.toString() ??
              rawText;
          yield FaberStreamEvent(
            event: 'delta',
            text: reply,
            agentId: json['agentId']?.toString(),
            agentName: json['agentName']?.toString(),
            raw: json,
          );
        } else {
          yield FaberStreamEvent(event: 'delta', text: rawText);
        }
      } catch (_) {
        yield FaberStreamEvent(event: 'delta', text: rawText);
      }
      yield const FaberStreamEvent(event: 'done');
      return;
    }

    // Parse SSE stream line-by-line
    String currentEvent = 'message';
    final lines =
        streamed.stream.transform(utf8.decoder).transform(const LineSplitter());

    await for (final line in lines) {
      if (line.isEmpty) {
        currentEvent = 'message';
        continue;
      }
      if (line.startsWith('event:')) {
        currentEvent = line.substring(6).trim();
        continue;
      }
      if (line.startsWith('data:')) {
        final payload = line.substring(5).trim();
        if (payload == '[DONE]') {
          yield const FaberStreamEvent(event: 'done');
          break;
        }
        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map<String, dynamic>) {
            final text = decoded['delta']?.toString() ??
                decoded['text']?.toString() ??
                decoded['content']?.toString() ??
                decoded['chunk']?.toString() ??
                decoded['message']?.toString() ??
                '';
            final evtName = decoded['type']?.toString() ?? currentEvent;
            yield FaberStreamEvent(
              event: evtName == 'done' ? 'done' : 'delta',
              text: text,
              agentId: decoded['agentId']?.toString(),
              agentName: decoded['agentName']?.toString(),
              raw: decoded,
            );
            if (evtName == 'done' || decoded['done'] == true) break;
          } else {
            yield FaberStreamEvent(event: 'delta', text: decoded.toString());
          }
        } catch (_) {
          if (payload.isNotEmpty) {
            yield FaberStreamEvent(event: 'delta', text: payload);
          }
        }
      }
    }

    yield const FaberStreamEvent(event: 'done');
  }

  // ---------------------------------------------------------------------------
  // Code Studio & Terminal
  // ---------------------------------------------------------------------------
  Future<({List<FaberFileNode> tree, List<String> flatFiles, String branch, String commit})>
      getSiteTree(String slug) async {
    final data = await _request('GET', '/api/sites/tree', query: {'slug': slug});
    final rawTree = data['tree'];
    final tree = <FaberFileNode>[];
    if (rawTree is List) {
      for (final node in rawTree) {
        if (node is Map) {
          tree.add(FaberFileNode.fromJson(Map<String, dynamic>.from(node)));
        }
      }
    }

    final rawFlat = data['flatFiles'];
    final flat = <String>[];
    if (rawFlat is List) {
      for (final f in rawFlat) {
        if (f != null) flat.add(f.toString());
      }
    }

    return (
      tree: tree,
      flatFiles: flat,
      branch: data['branch']?.toString() ?? 'main',
      commit: data['commit']?.toString() ?? '',
    );
  }

  Future<String> getSiteFile(String slug, String file) async {
    final data = await _request(
      'GET',
      '/api/sites/file',
      query: {'slug': slug, 'file': file},
    );
    return data['content']?.toString() ?? '';
  }

  Future<void> saveSiteFile(String slug, String file, String content) async {
    await _request(
      'PUT',
      '/api/sites/file',
      body: {'slug': slug, 'file': file, 'content': content},
    );
  }

  Future<({String output, int exitCode})> execTerminal(
    String command, {
    String? cwd,
  }) async {
    final data = await _request(
      'POST',
      '/api/terminal/exec',
      body: {
        'command': command,
        if (cwd != null && cwd.isNotEmpty) 'cwd': cwd,
      },
      timeout: const Duration(seconds: 60),
    );
    return (
      output: data['output']?.toString() ?? '',
      exitCode: (data['exitCode'] is num)
          ? (data['exitCode'] as num).toInt()
          : 0,
    );
  }

  Future<void> abortTask(String sessionId) async {
    await _request('POST', '/api/task/abort', body: {'sessionId': sessionId});
  }

  // ---------------------------------------------------------------------------
  // War Office & Agent Souls
  // ---------------------------------------------------------------------------
  Future<({List<FaberWarOfficeDesk> desks, int activeCount})> getWarOfficeState({
    String board = 'office-software',
  }) async {
    final data = await _request(
      'GET',
      '/api/war-office/state',
      query: {'board': board},
    );
    final desks = <FaberWarOfficeDesk>[];
    final rawDesks = data['desks'];
    if (rawDesks is List) {
      for (final d in rawDesks) {
        if (d is Map) {
          desks.add(FaberWarOfficeDesk.fromJson(Map<String, dynamic>.from(d)));
        }
      }
    } else if (data['heroes'] is Map) {
      final heroes = Map<String, dynamic>.from(data['heroes'] as Map);
      final agentsList = data['agents'] is List
          ? (data['agents'] as List).whereType<Map>().toList()
          : const <Map>[];
      final agentMeta = {
        for (final a in agentsList)
          if (a['id'] != null) a['id'].toString(): a,
      };
      heroes.forEach((id, val) {
        if (val is Map) {
          final meta = agentMeta[id];
          desks.add(FaberWarOfficeDesk(
            agentId: id,
            agentName: meta?['name']?.toString() ?? id,
            role: meta?['role']?.toString() ?? '',
            status: val['isWorking'] == true ? 'working' : 'idle',
            currentTask: val['statusText']?.toString() ?? '',
            avatar: meta?['avatar']?.toString() ?? '🤖',
          ));
        }
      });
    }
    final activeCount = (data['activeCount'] is num)
        ? (data['activeCount'] as num).toInt()
        : desks.where((d) => d.isActive).length;
    return (desks: desks, activeCount: activeCount);
  }

  Future<String> getSoul(String agentId, {String type = 'SOUL.md'}) async {
    final data = await _request(
      'GET',
      '/api/souls',
      query: {'agentId': agentId, 'type': type},
    );
    return data['content']?.toString() ?? '';
  }

  Future<void> updateSoul(
    String agentId,
    String content, {
    String type = 'SOUL.md',
  }) async {
    await _request(
      'PUT',
      '/api/souls',
      body: {'agentId': agentId, 'type': type, 'content': content},
    );
  }

  // ---------------------------------------------------------------------------
  // Automations / Cron
  // ---------------------------------------------------------------------------
  Future<void> runCron(String jobId) async {
    try {
      await _request(
        'POST',
        '/api/cron/action',
        body: {'jobId': jobId, 'action': 'run'},
      );
    } on FaberApiException catch (e) {
      if (e.statusCode == 404) {
        await _request('POST', '/api/cron/run', body: {'jobId': jobId});
      } else {
        rethrow;
      }
    }
  }

  Future<void> toggleCron(String jobId, bool enabled) async {
    try {
      await _request(
        'POST',
        '/api/cron/action',
        body: {'jobId': jobId, 'action': enabled ? 'enable' : 'disable'},
      );
    } on FaberApiException catch (e) {
      if (e.statusCode == 404) {
        await _request(
          'POST',
          '/api/cron/toggle',
          body: {'jobId': jobId, 'enabled': enabled},
        );
      } else {
        rethrow;
      }
    }
  }

  String mediaRawUrl(String path) {
    return '$_baseUrl/api/library/raw?path=${Uri.encodeComponent(path)}';
  }
}
