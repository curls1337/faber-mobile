import 'package:flutter/material.dart';

/// Helper parsers for resilient JSON decoding across Faber Studio API payloads.
class _JsonParse {
  static String str(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;
    return value.toString();
  }

  static int integer(dynamic value, [int fallback = 0]) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  static double dbl(dynamic value, [double fallback = 0.0]) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  static bool boolean(dynamic value, [bool fallback = false]) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final s = value.toString().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
    return fallback;
  }

  static DateTime? dateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) {
      // Handle seconds vs milliseconds epoch
      final ms = value < 100000000000 ? value * 1000 : value;
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    return DateTime.tryParse(value.toString());
  }
}

// -----------------------------------------------------------------------------
// 1. FaberSite
// -----------------------------------------------------------------------------
class FaberSite {
  final String slug;
  final String name;
  final String description;
  final String url;
  final String stagingUrl;
  final String branch;
  final String commit;
  final String status;
  final String framework;
  final int? port;
  final DateTime? updatedAt;

  const FaberSite({
    required this.slug,
    required this.name,
    this.description = '',
    this.url = '',
    this.stagingUrl = '',
    this.branch = 'main',
    this.commit = '',
    this.status = 'active',
    this.framework = 'web',
    this.port,
    this.updatedAt,
  });

  factory FaberSite.fromJson(Map<String, dynamic> json) {
    final slug = _JsonParse.str(json['slug'], _JsonParse.str(json['id']));
    return FaberSite(
      slug: slug,
      name: _JsonParse.str(json['name'], slug),
      description: _JsonParse.str(json['description']),
      url: _JsonParse.str(json['url']),
      stagingUrl: _JsonParse.str(
        json['stagingUrl'],
        slug.isNotEmpty ? '/staging/$slug/' : '',
      ),
      branch: _JsonParse.str(json['branch'], 'main'),
      commit: _JsonParse.str(json['commit']),
      status: _JsonParse.str(json['status'], 'active'),
      framework: _JsonParse.str(json['framework'], 'web'),
      port: json['port'] != null ? _JsonParse.integer(json['port']) : null,
      updatedAt: _JsonParse.dateTime(json['updatedAt'] ?? json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'name': name,
        'description': description,
        'url': url,
        'stagingUrl': stagingUrl,
        'branch': branch,
        'commit': commit,
        'status': status,
        'framework': framework,
        'port': port,
        'updatedAt': updatedAt?.toIso8601String(),
      };
}

// -----------------------------------------------------------------------------
// 2. FaberAgent
// -----------------------------------------------------------------------------
class FaberAgent {
  final String id;
  final String name;
  final String role;
  final String description;
  final String avatar;
  final String status; // idle, working, active, offline, error
  final String model;
  final String currentTask;
  final String colorHex;

  const FaberAgent({
    required this.id,
    required this.name,
    this.role = 'Specialist',
    this.description = '',
    this.avatar = '🤖',
    this.status = 'idle',
    this.model = '',
    this.currentTask = '',
    this.colorHex = '#6366F1',
  });

  bool get isWorking =>
      status.toLowerCase() == 'working' ||
      status.toLowerCase() == 'active' ||
      status.toLowerCase() == 'running';

  Color get accentColor {
    final hex = colorHex.replaceAll('#', '');
    if (hex.length == 6) {
      final parsed = int.tryParse('FF$hex', radix: 16);
      if (parsed != null) return Color(parsed);
    }
    return const Color(0xFF6366F1);
  }

  factory FaberAgent.fromJson(Map<String, dynamic> json) {
    final id = _JsonParse.str(json['id'], _JsonParse.str(json['agentId']));
    return FaberAgent(
      id: id,
      name: _JsonParse.str(json['name'], id),
      role: _JsonParse.str(json['role'], _JsonParse.str(json['title'], 'Agent')),
      description: _JsonParse.str(json['description']),
      avatar: _JsonParse.str(json['avatar'], _JsonParse.str(json['emoji'], '🤖')),
      status: _JsonParse.str(json['status'], 'idle'),
      model: _JsonParse.str(json['model']),
      currentTask: _JsonParse.str(json['currentTask'] ?? json['task']),
      colorHex: _JsonParse.str(json['color'], '#6366F1'),
    );
  }

  FaberAgent copyWith({
    String? status,
    String? currentTask,
    String? model,
  }) {
    return FaberAgent(
      id: id,
      name: name,
      role: role,
      description: description,
      avatar: avatar,
      status: status ?? this.status,
      model: model ?? this.model,
      currentTask: currentTask ?? this.currentTask,
      colorHex: colorHex,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'description': description,
        'avatar': avatar,
        'status': status,
        'model': model,
        'currentTask': currentTask,
        'color': colorHex,
      };
}

// -----------------------------------------------------------------------------
// 3. FaberSession
// -----------------------------------------------------------------------------
class FaberSession {
  final String id;
  final String title;
  final String agentId;
  final String projectSlug;
  final String mode; // swarm | direct
  final DateTime? updatedAt;
  final int messageCount;
  final String lastMessage;

  const FaberSession({
    required this.id,
    required this.title,
    this.agentId = '',
    this.projectSlug = '',
    this.mode = 'swarm',
    this.updatedAt,
    this.messageCount = 0,
    this.lastMessage = '',
  });

  factory FaberSession.fromJson(Map<String, dynamic> json) {
    final id = _JsonParse.str(
      json['id'],
      _JsonParse.str(json['sessionId'], 'default'),
    );
    return FaberSession(
      id: id,
      title: _JsonParse.str(json['title'], _JsonParse.str(json['name'], id)),
      agentId: _JsonParse.str(json['agentId']),
      projectSlug: _JsonParse.str(json['projectSlug'] ?? json['slug']),
      mode: _JsonParse.str(json['mode'], 'swarm'),
      updatedAt: _JsonParse.dateTime(json['updatedAt'] ?? json['ts']),
      messageCount: _JsonParse.integer(json['messageCount'] ?? json['count']),
      lastMessage: _JsonParse.str(json['lastMessage'] ?? json['preview']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'agentId': agentId,
        'projectSlug': projectSlug,
        'mode': mode,
        'updatedAt': updatedAt?.toIso8601String(),
        'messageCount': messageCount,
        'lastMessage': lastMessage,
      };
}

// -----------------------------------------------------------------------------
// 4. FaberMessage
// -----------------------------------------------------------------------------
class FaberMessage {
  final String id;
  final String role; // user | assistant | system | tool
  final String content;
  final String agentId;
  final String agentName;
  final DateTime timestamp;
  final bool isStreaming;
  final List<String> artifacts;

  const FaberMessage({
    required this.id,
    required this.role,
    required this.content,
    this.agentId = '',
    this.agentName = '',
    required this.timestamp,
    this.isStreaming = false,
    this.artifacts = const [],
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  factory FaberMessage.fromJson(Map<String, dynamic> json) {
    final rawArtifacts = json['artifacts'];
    final artifacts = <String>[];
    if (rawArtifacts is List) {
      for (final item in rawArtifacts) {
        if (item != null) artifacts.add(item.toString());
      }
    }

    return FaberMessage(
      id: _JsonParse.str(
        json['id'],
        'msg_${DateTime.now().microsecondsSinceEpoch}',
      ),
      role: _JsonParse.str(json['role'], 'assistant'),
      content: _JsonParse.str(
        json['content'],
        _JsonParse.str(json['text'], _JsonParse.str(json['message'])),
      ),
      agentId: _JsonParse.str(json['agentId']),
      agentName: _JsonParse.str(json['agentName'] ?? json['sender']),
      timestamp:
          _JsonParse.dateTime(json['timestamp'] ?? json['ts'] ?? json['createdAt']) ??
              DateTime.now(),
      isStreaming: _JsonParse.boolean(json['isStreaming']),
      artifacts: artifacts,
    );
  }

  FaberMessage copyWith({
    String? content,
    bool? isStreaming,
    String? agentName,
    List<String>? artifacts,
  }) {
    return FaberMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      agentId: agentId,
      agentName: agentName ?? this.agentName,
      timestamp: timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      artifacts: artifacts ?? this.artifacts,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'content': content,
        'agentId': agentId,
        'agentName': agentName,
        'timestamp': timestamp.toIso8601String(),
        'isStreaming': isStreaming,
        'artifacts': artifacts,
      };
}

// -----------------------------------------------------------------------------
// 5. FaberMediaItem
// -----------------------------------------------------------------------------
class FaberMediaItem {
  final String id;
  final String name;
  final String path;
  final String type; // image | video | audio | document
  final String mimeType;
  final int sizeBytes;
  final DateTime? createdAt;

  const FaberMediaItem({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
    this.mimeType = '',
    this.sizeBytes = 0,
    this.createdAt,
  });

  String rawUrl(String baseUrl, {String? token}) {
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final base = '$cleanBase/api/library/raw?path=${Uri.encodeComponent(path)}';
    if (token != null && token.isNotEmpty) {
      return '$base&token=${Uri.encodeComponent(token)}';
    }
    return base;
  }

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String _inferType(String name, String rawType, String mime) {
    final lower = '$rawType $mime $name'.toLowerCase();
    if (lower.contains('image') ||
        lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif')) {
      return 'image';
    }
    if (lower.contains('video') ||
        lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm')) {
      return 'video';
    }
    if (lower.contains('audio') ||
        lower.endsWith('.mp3') ||
        lower.endsWith('.wav') ||
        lower.endsWith('.m4a') ||
        lower.endsWith('.ogg')) {
      return 'audio';
    }
    return 'document';
  }

  factory FaberMediaItem.fromJson(Map<String, dynamic> json) {
    final path = _JsonParse.str(json['path'], _JsonParse.str(json['url']));
    final name = _JsonParse.str(
      json['name'],
      path.split('/').where((s) => s.isNotEmpty).lastOrNull ?? 'media',
    );
    final mime = _JsonParse.str(json['mimeType'] ?? json['mime']);
    final type = _inferType(name, _JsonParse.str(json['type']), mime);
    return FaberMediaItem(
      id: _JsonParse.str(json['id'], path),
      name: name,
      path: path,
      type: type,
      mimeType: mime,
      sizeBytes: _JsonParse.integer(json['size'] ?? json['sizeBytes']),
      createdAt: _JsonParse.dateTime(json['createdAt'] ?? json['mtime']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'path': path,
        'type': type,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
        'createdAt': createdAt?.toIso8601String(),
      };
}

// -----------------------------------------------------------------------------
// 6. FaberAutomation
// -----------------------------------------------------------------------------
class FaberAutomation {
  final String id;
  final String name;
  final String schedule;
  final bool enabled;
  final String lastStatus;
  final DateTime? lastRun;
  final DateTime? nextRun;
  final String description;

  const FaberAutomation({
    required this.id,
    required this.name,
    this.schedule = '',
    this.enabled = true,
    this.lastStatus = 'idle',
    this.lastRun,
    this.nextRun,
    this.description = '',
  });

  factory FaberAutomation.fromJson(Map<String, dynamic> json) {
    final id = _JsonParse.str(json['id'], _JsonParse.str(json['jobId']));
    return FaberAutomation(
      id: id,
      name: _JsonParse.str(json['name'], id),
      schedule: _JsonParse.str(json['schedule'] ?? json['cron']),
      enabled: _JsonParse.boolean(json['enabled'], true),
      lastStatus: _JsonParse.str(json['lastStatus'] ?? json['status'], 'idle'),
      lastRun: _JsonParse.dateTime(json['lastRun'] ?? json['lastRunAt']),
      nextRun: _JsonParse.dateTime(json['nextRun'] ?? json['nextRunAt']),
      description: _JsonParse.str(json['description'] ?? json['prompt']),
    );
  }

  FaberAutomation copyWith({bool? enabled, String? lastStatus, DateTime? lastRun}) {
    return FaberAutomation(
      id: id,
      name: name,
      schedule: schedule,
      enabled: enabled ?? this.enabled,
      lastStatus: lastStatus ?? this.lastStatus,
      lastRun: lastRun ?? this.lastRun,
      nextRun: nextRun,
      description: description,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'schedule': schedule,
        'enabled': enabled,
        'lastStatus': lastStatus,
        'lastRun': lastRun?.toIso8601String(),
        'nextRun': nextRun?.toIso8601String(),
        'description': description,
      };
}

// -----------------------------------------------------------------------------
// 7. FaberCloudApp
// -----------------------------------------------------------------------------
class FaberCloudApp {
  final String id;
  final String name;
  final String slug;
  final String url;
  final String status; // running | stopped | error
  final int? port;
  final double cpuPercent;
  final double memoryMb;
  final String uptime;
  final String description;

  const FaberCloudApp({
    required this.id,
    required this.name,
    this.slug = '',
    this.url = '',
    this.status = 'running',
    this.port,
    this.cpuPercent = 0.0,
    this.memoryMb = 0.0,
    this.uptime = '',
    this.description = '',
  });

  bool get isRunning =>
      status.toLowerCase() == 'running' ||
      status.toLowerCase() == 'online' ||
      status.toLowerCase() == 'active';

  factory FaberCloudApp.fromJson(Map<String, dynamic> json) {
    final id = _JsonParse.str(json['id'], _JsonParse.str(json['slug']));
    final sub = _JsonParse.str(json['subdomain']);
    final rawUrl = _JsonParse.str(json['url']);
    final resolvedUrl = rawUrl.isNotEmpty
        ? rawUrl
        : (sub.isNotEmpty ? 'https://$sub.5nod.com' : '');
    return FaberCloudApp(
      id: id,
      name: _JsonParse.str(json['name'], id),
      slug: _JsonParse.str(json['slug'], sub.isNotEmpty ? sub : id),
      url: resolvedUrl,
      status: _JsonParse.str(json['status'], 'running'),
      port: json['port'] != null ? _JsonParse.integer(json['port']) : null,
      cpuPercent: _JsonParse.dbl(json['cpu'] ?? json['cpuPercent']),
      memoryMb: _JsonParse.dbl(json['memoryMb'] ?? json['memory']),
      uptime: _JsonParse.str(json['uptime']),
      description: _JsonParse.str(json['description']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'url': url,
        'status': status,
        'port': port,
        'cpuPercent': cpuPercent,
        'memoryMb': memoryMb,
        'uptime': uptime,
        'description': description,
      };
}

// -----------------------------------------------------------------------------
// 8. FaberSystemStats
// -----------------------------------------------------------------------------
class FaberSystemStats {
  final int totalMemBytes;
  final int freeMemBytes;
  final double uptimeSeconds;
  final String hostname;

  const FaberSystemStats({
    this.totalMemBytes = 0,
    this.freeMemBytes = 0,
    this.uptimeSeconds = 0,
    this.hostname = 'webui.5nod.com',
  });

  int get usedMemBytes =>
      (totalMemBytes - freeMemBytes).clamp(0, totalMemBytes);

  double get memUsagePercent =>
      totalMemBytes > 0 ? (usedMemBytes / totalMemBytes) * 100.0 : 0.0;

  String get formattedRam {
    if (totalMemBytes <= 0) return '-- / --';
    final usedGb = usedMemBytes / (1024 * 1024 * 1024);
    final totalGb = totalMemBytes / (1024 * 1024 * 1024);
    return '${usedGb.toStringAsFixed(1)} / ${totalGb.toStringAsFixed(1)} GB';
  }

  String get formattedUptime {
    final totalSec = uptimeSeconds.floor();
    final days = totalSec ~/ 86400;
    final hours = (totalSec % 86400) ~/ 3600;
    final mins = (totalSec % 3600) ~/ 60;
    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }

  factory FaberSystemStats.fromJson(Map<String, dynamic> json) {
    const int bytesPerGb = 1024 * 1024 * 1024;
    int totalMem = _JsonParse.integer(json['totalMem']);
    int freeMem = _JsonParse.integer(json['freeMem']);

    if (totalMem == 0 && json['memTotalGb'] != null) {
      final totalGb = _JsonParse.dbl(json['memTotalGb']);
      final usedGb = _JsonParse.dbl(json['memUsedGb']);
      totalMem = (totalGb * bytesPerGb).round();
      freeMem = ((totalGb - usedGb).clamp(0.0, totalGb) * bytesPerGb).round();
    }

    double uptimeSec = _JsonParse.dbl(json['uptime']);
    if (uptimeSec == 0 && json['uptimeHours'] != null) {
      uptimeSec = _JsonParse.dbl(json['uptimeHours']) * 3600.0;
    }

    return FaberSystemStats(
      totalMemBytes: totalMem,
      freeMemBytes: freeMem,
      uptimeSeconds: uptimeSec,
      hostname: _JsonParse.str(json['hostname'], 'webui.5nod.com'),
    );
  }

  Map<String, dynamic> toJson() => {
        'totalMem': totalMemBytes,
        'freeMem': freeMemBytes,
        'uptime': uptimeSeconds,
        'hostname': hostname,
      };
}

// -----------------------------------------------------------------------------
// Supporting Models: War Office Desk, File Node & Bootstrap Bundle
// -----------------------------------------------------------------------------
class FaberWarOfficeDesk {
  final String agentId;
  final String agentName;
  final String role;
  final String status;
  final String currentTask;
  final String avatar;

  const FaberWarOfficeDesk({
    required this.agentId,
    required this.agentName,
    this.role = '',
    this.status = 'idle',
    this.currentTask = '',
    this.avatar = '🤖',
  });

  bool get isActive =>
      status.toLowerCase() == 'working' ||
      status.toLowerCase() == 'active' ||
      status.toLowerCase() == 'busy';

  factory FaberWarOfficeDesk.fromJson(Map<String, dynamic> json) {
    final agentId = _JsonParse.str(json['agentId'], _JsonParse.str(json['id']));
    return FaberWarOfficeDesk(
      agentId: agentId,
      agentName: _JsonParse.str(json['name'] ?? json['agentName'], agentId),
      role: _JsonParse.str(json['role']),
      status: _JsonParse.str(json['status'], 'idle'),
      currentTask: _JsonParse.str(json['currentTask'] ?? json['task']),
      avatar: _JsonParse.str(json['avatar'] ?? json['emoji'], '🤖'),
    );
  }
}

class FaberFileNode {
  final String name;
  final String path;
  final bool isDir;
  final List<FaberFileNode> children;

  const FaberFileNode({
    required this.name,
    required this.path,
    this.isDir = false,
    this.children = const [],
  });

  factory FaberFileNode.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['children'];
    final children = <FaberFileNode>[];
    if (rawChildren is List) {
      for (final c in rawChildren) {
        if (c is Map<String, dynamic>) {
          children.add(FaberFileNode.fromJson(c));
        }
      }
    }
    return FaberFileNode(
      name: _JsonParse.str(json['name']),
      path: _JsonParse.str(json['path']),
      isDir: _JsonParse.boolean(
        json['isDir'],
        _JsonParse.str(json['type']) == 'directory' || children.isNotEmpty,
      ),
      children: children,
    );
  }
}

class FaberBootstrapData {
  final List<FaberAgent> agents;
  final List<FaberSite> sites;
  final List<FaberSession> sessions;
  final List<FaberMediaItem> library;
  final List<String> skills;
  final List<FaberAutomation> automations;
  final List<FaberCloudApp> cloudApps;
  final FaberSystemStats system;

  const FaberBootstrapData({
    this.agents = const [],
    this.sites = const [],
    this.sessions = const [],
    this.library = const [],
    this.skills = const [],
    this.automations = const [],
    this.cloudApps = const [],
    this.system = const FaberSystemStats(),
  });

  factory FaberBootstrapData.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(
      dynamic raw,
      T Function(Map<String, dynamic>) mapper,
    ) {
      if (raw is! List) return <T>[];
      return raw
          .whereType<Map>()
          .map((e) => mapper(Map<String, dynamic>.from(e)))
          .toList();
    }

    final rawSkills = json['skills'];
    final skills = <String>[];
    if (rawSkills is List) {
      for (final s in rawSkills) {
        if (s is String) {
          skills.add(s);
        } else if (s is Map && s['name'] != null) {
          skills.add(s['name'].toString());
        }
      }
    }

    final sysRaw = json['system'];
    final sys = sysRaw is Map
        ? FaberSystemStats.fromJson(Map<String, dynamic>.from(sysRaw))
        : const FaberSystemStats();

    final cloudEngineRaw = json['cloudEngine'];
    final rawCloudApps = json['cloudApps'] ??
        (cloudEngineRaw is Map ? cloudEngineRaw['apps'] : null);

    return FaberBootstrapData(
      agents: parseList(json['agents'], FaberAgent.fromJson),
      sites: parseList(json['sites'], FaberSite.fromJson),
      sessions: parseList(json['sessions'], FaberSession.fromJson),
      library: parseList(json['library'], FaberMediaItem.fromJson),
      skills: skills,
      automations: parseList(json['automations'], FaberAutomation.fromJson),
      cloudApps: parseList(rawCloudApps, FaberCloudApp.fromJson),
      system: sys,
    );
  }
}
