import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:localsend_app/provider/device_info_provider.dart';
import 'package:localsend_app/provider/local_ip_provider.dart';
import 'package:localsend_app/provider/network/nearby_devices_provider.dart';
import 'package:localsend_isolates/model/device.dart';
import 'package:logging/logging.dart';
import 'package:refena_flutter/refena_flutter.dart';

const int groupUdpPort = 53319;
const int maxGroupCapacity = 10;
final _logger = Logger('GroupTransfer');

final _adjectives = [
  'Swift',
  'Nova',
  'Solar',
  'Pulse',
  'Hyper',
  'Cosmic',
  'Echo',
  'Neon',
  'Quantum',
  'Falcon',
  'Crystal',
  'Apex',
  'Zenith',
  'Vortex',
  'Starlight',
  'Aura',
  'Orbit',
  'Cyber',
  'Titan',
  'Shadow',
  'Blaze',
  'Fusion',
  'Vector',
  'Atlas',
  'Comet',
  'Matrix',
  'Spectral',
  'Velocity',
  'Radiant',
  'Stellar',
];

final _nouns = [
  'Orbit',
  'Falcon',
  'Pulse',
  'Wave',
  'Beam',
  'Link',
  'Horizon',
  'Spark',
  'Circle',
  'Squad',
  'Station',
  'Beacon',
  'Stream',
  'Forge',
  'Hub',
  'Nexus',
  'Sphere',
  'Matrix',
  'Portal',
  'Rift',
  'Core',
  'Vanguard',
  'Haven',
  'Realm',
];

String generateGroupName() {
  final rand = Random();
  final adj = _adjectives[rand.nextInt(_adjectives.length)];
  final noun = _nouns[rand.nextInt(_nouns.length)];
  final num = 10 + rand.nextInt(90);
  return '$adj $noun #$num';
}

Map<String, dynamic> deviceToGroupJson(Device d) => {
  'ip': d.ip,
  'port': d.port,
  'https': d.https,
  'fingerprint': d.fingerprint,
  'alias': d.alias,
  'deviceModel': d.deviceModel,
  'deviceType': d.deviceType.name,
  'download': d.download,
  'version': d.version,
};

Device deviceFromGroupJson(Map<String, dynamic> map) => Device(
  signalingId: null,
  ip: map['ip'] as String?,
  port: (map['port'] as num?)?.toInt() ?? 53317,
  https: map['https'] as bool? ?? true,
  fingerprint: map['fingerprint'] as String? ?? '',
  alias: map['alias'] as String? ?? 'Device',
  deviceModel: map['deviceModel'] as String?,
  deviceType: DeviceType.values.firstWhereOrNull((t) => t.name == map['deviceType']) ?? DeviceType.desktop,
  download: map['download'] as bool? ?? false,
  version: map['version'] as String? ?? '2.2',
  channels: [
    if (map['ip'] != null)
      HttpChannel(
        host: map['ip'] as String,
        port: (map['port'] as num?)?.toInt() ?? 53317,
        https: map['https'] as bool? ?? true,
      ),
  ],
);

// -------------------------------------------------------------
// Group Receive State & Service
// -------------------------------------------------------------

class GroupReceiveState {
  final String groupId;
  final String groupName;
  final bool isActive;
  final Map<String, Device> members; // Keyed by fingerprint or IP (max 10)
  final String? error;

  const GroupReceiveState({
    required this.groupId,
    required this.groupName,
    this.isActive = false,
    this.members = const {},
    this.error,
  });

  int get count => members.length;
  bool get isFull => members.length >= maxGroupCapacity;

  GroupReceiveState copyWith({
    String? groupId,
    String? groupName,
    bool? isActive,
    Map<String, Device>? members,
    String? error,
  }) => GroupReceiveState(
    groupId: groupId ?? this.groupId,
    groupName: groupName ?? this.groupName,
    isActive: isActive ?? this.isActive,
    members: members ?? this.members,
    error: error ?? this.error,
  );
}

final groupReceiveProvider = NotifierProvider<GroupReceiveService, GroupReceiveState>((ref) {
  return GroupReceiveService();
});

class GroupReceiveService extends Notifier<GroupReceiveState> {
  RawDatagramSocket? _socket;
  Timer? _heartbeatTimer;
  Timer? _cleanupTimer;
  final Map<String, DateTime> _lastSeen = {};

  @override
  GroupReceiveState init() {
    final randId = 'grp_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
    return GroupReceiveState(
      groupId: randId,
      groupName: generateGroupName(),
    );
  }

  Future<void> start() async {
    if (state.isActive) return;

    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, groupUdpPort, reuseAddress: true);
    } catch (_) {
      try {
        _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0, reuseAddress: true);
      } catch (e) {
        _logger.warning('Failed to bind group receive socket: $e');
        state = state.copyWith(error: 'Could not open network socket: $e');
        return;
      }
    }

    _socket?.broadcastEnabled = true;

    state = state.copyWith(isActive: true, error: null);

    // Add local device as first member
    final myDevice = ref.read(deviceFullInfoProvider);
    final myKey = myDevice.fingerprint.isNotEmpty ? myDevice.fingerprint : (myDevice.ip ?? 'local');
    state = state.copyWith(
      members: {myKey: myDevice},
    );
    _lastSeen[myKey] = DateTime.now();

    // Listen to incoming group packets
    _socket?.listen((event) {
      if (event == RawSocketEvent.read) {
        final dg = _socket?.receive();
        if (dg != null) {
          _handleDatagram(dg);
        }
      }
    });

    // Send initial query to see if an active group already exists on this Wi-Fi
    _broadcastQuery();

    // Heartbeat every 1.2s
    _heartbeatTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      _broadcastHeartbeat();
    });

    // Cleanup stale members every 2.5s
    _cleanupTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      _cleanupStaleMembers();
    });
  }

  void _handleDatagram(Datagram dg) {
    try {
      final jsonStr = utf8.decode(dg.data);
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final type = map['type'] as String?;

      if (type == 'group_heartbeat') {
        final incomingGroupId = map['groupId'] as String?;
        final incomingGroupName = map['groupName'] as String?;
        final devMap = map['device'] as Map<String, dynamic>?;

        if (devMap == null || incomingGroupId == null || incomingGroupName == null) return;

        final device = deviceFromGroupJson(devMap);
        final key = device.fingerprint.isNotEmpty ? device.fingerprint : (device.ip ?? '');
        if (key.isEmpty) return;

        final myDevice = ref.read(deviceFullInfoProvider);
        final myKey = myDevice.fingerprint.isNotEmpty ? myDevice.fingerprint : (myDevice.ip ?? 'local');

        // If we don't have other members yet and an active group is broadcasting, adopt it
        if (state.members.length <= 1 && incomingGroupId != state.groupId) {
          state = state.copyWith(
            groupId: incomingGroupId,
            groupName: incomingGroupName,
          );
        }

        // If part of our group
        if (incomingGroupId == state.groupId) {
          if (key != myKey) {
            _lastSeen[key] = DateTime.now();
            if (!state.members.containsKey(key)) {
              if (state.members.length < maxGroupCapacity) {
                final newMembers = Map<String, Device>.from(state.members)..[key] = device;
                state = state.copyWith(members: newMembers);
              }
            } else {
              final newMembers = Map<String, Device>.from(state.members)..[key] = device;
              state = state.copyWith(members: newMembers);
            }
          }
        }
      } else if (type == 'group_query') {
        _broadcastHeartbeat();
      } else if (type == 'group_leave') {
        final leaveKey = map['fingerprint'] as String? ?? (map['ip'] as String? ?? '');
        if (leaveKey.isNotEmpty && state.members.containsKey(leaveKey)) {
          final newMembers = Map<String, Device>.from(state.members)..remove(leaveKey);
          _lastSeen.remove(leaveKey);
          state = state.copyWith(members: newMembers);
        }
      }
    } catch (e) {
      // Ignore malformed packets
    }
  }

  void _broadcastHeartbeat() {
    if (_socket == null || !state.isActive) return;

    final myDevice = ref.read(deviceFullInfoProvider);
    final packet = {
      'type': 'group_heartbeat',
      'groupId': state.groupId,
      'groupName': state.groupName,
      'device': deviceToGroupJson(myDevice),
      'memberCount': state.members.length,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    _sendPacket(packet);
  }

  void _broadcastQuery() {
    if (_socket == null || !state.isActive) return;
    final packet = {'type': 'group_query'};
    _sendPacket(packet);
  }

  void _cleanupStaleMembers() {
    final now = DateTime.now();
    final myDevice = ref.read(deviceFullInfoProvider);
    final myKey = myDevice.fingerprint.isNotEmpty ? myDevice.fingerprint : (myDevice.ip ?? 'local');

    final updated = Map<String, Device>.from(state.members);
    var changed = false;

    for (final entry in state.members.entries) {
      if (entry.key == myKey) continue;
      final last = _lastSeen[entry.key];
      if (last == null || now.difference(last).inSeconds > 6) {
        updated.remove(entry.key);
        _lastSeen.remove(entry.key);
        changed = true;
      }
    }

    if (changed) {
      state = state.copyWith(members: updated);
    }
  }

  void _sendPacket(Map<String, dynamic> data) {
    if (_socket == null) return;
    try {
      final bytes = utf8.encode(jsonEncode(data));
      final localIps = ref.read(localIpProvider).localIps;
      final nearbyDevices = ref.read(nearbyDevicesProvider).allDevices.values;

      // 1. Broadcast to 255.255.255.255
      try {
        _socket?.send(bytes, InternetAddress('255.255.255.255'), groupUdpPort);
      } catch (_) {}

      // 2. Broadcast to subnet broadcast
      for (final ip in localIps) {
        final parts = ip.split('.');
        if (parts.length == 4) {
          try {
            final subnetBroadcast = '${parts[0]}.${parts[1]}.${parts[2]}.255';
            _socket?.send(bytes, InternetAddress(subnetBroadcast), groupUdpPort);
          } catch (_) {}
        }
      }

      // 3. Unicast to discovered nearby devices
      for (final dev in nearbyDevices) {
        if (dev.ip != null) {
          try {
            _socket?.send(bytes, InternetAddress(dev.ip!), groupUdpPort);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  void stop() {
    if (!state.isActive) return;

    try {
      final myDevice = ref.read(deviceFullInfoProvider);
      final myKey = myDevice.fingerprint.isNotEmpty ? myDevice.fingerprint : (myDevice.ip ?? 'local');
      final leavePacket = {
        'type': 'group_leave',
        'groupId': state.groupId,
        'fingerprint': myKey,
        'ip': myDevice.ip,
      };
      _sendPacket(leavePacket);
    } catch (_) {}

    _heartbeatTimer?.cancel();
    _cleanupTimer?.cancel();
    _socket?.close();
    _socket = null;
    _lastSeen.clear();

    state = state.copyWith(isActive: false, members: {});
  }
}

// -------------------------------------------------------------
// Group Send State & Service
// -------------------------------------------------------------

class DiscoveredGroup {
  final String groupId;
  final String groupName;
  final Map<String, Device> members;
  final DateTime lastHeartbeat;

  DiscoveredGroup({
    required this.groupId,
    required this.groupName,
    required this.members,
    required this.lastHeartbeat,
  });

  DiscoveredGroup copyWith({
    String? groupId,
    String? groupName,
    Map<String, Device>? members,
    DateTime? lastHeartbeat,
  }) => DiscoveredGroup(
    groupId: groupId ?? this.groupId,
    groupName: groupName ?? this.groupName,
    members: members ?? this.members,
    lastHeartbeat: lastHeartbeat ?? this.lastHeartbeat,
  );
}

class GroupSendState {
  final Map<String, DiscoveredGroup> groups; // groupId -> DiscoveredGroup
  final String? selectedGroupId;
  final bool isScanning;
  final String? error;

  const GroupSendState({
    this.groups = const {},
    this.selectedGroupId,
    this.isScanning = false,
    this.error,
  });

  DiscoveredGroup? get activeGroup {
    if (selectedGroupId != null && groups.containsKey(selectedGroupId)) {
      return groups[selectedGroupId];
    }
    return groups.values.firstOrNull;
  }

  GroupSendState copyWith({
    Map<String, DiscoveredGroup>? groups,
    String? selectedGroupId,
    bool? isScanning,
    String? error,
  }) => GroupSendState(
    groups: groups ?? this.groups,
    selectedGroupId: selectedGroupId ?? this.selectedGroupId,
    isScanning: isScanning ?? this.isScanning,
    error: error ?? this.error,
  );
}

final groupSendProvider = NotifierProvider<GroupSendService, GroupSendState>((ref) {
  return GroupSendService();
});

class GroupSendService extends Notifier<GroupSendState> {
  RawDatagramSocket? _socket;
  Timer? _queryTimer;
  Timer? _cleanupTimer;

  @override
  GroupSendState init() {
    return const GroupSendState();
  }

  Future<void> start() async {
    if (state.isScanning) return;

    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, groupUdpPort, reuseAddress: true);
    } catch (_) {
      try {
        _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0, reuseAddress: true);
      } catch (e) {
        _logger.warning('Failed to bind group send socket: $e');
        state = state.copyWith(error: 'Could not open network socket: $e');
        return;
      }
    }

    _socket?.broadcastEnabled = true;
    state = state.copyWith(isScanning: true, error: null);

    _socket?.listen((event) {
      if (event == RawSocketEvent.read) {
        final dg = _socket?.receive();
        if (dg != null) {
          _handleDatagram(dg);
        }
      }
    });

    // Send query immediately
    _broadcastQuery();

    // Query every 1.5s
    _queryTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      _broadcastQuery();
    });

    // Cleanup stale groups every 3s
    _cleanupTimer = Timer.periodic(const Duration(milliseconds: 3000), (_) {
      _cleanupStaleGroups();
    });
  }

  void _handleDatagram(Datagram dg) {
    try {
      final jsonStr = utf8.decode(dg.data);
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final type = map['type'] as String?;

      if (type == 'group_heartbeat') {
        final groupId = map['groupId'] as String?;
        final groupName = map['groupName'] as String?;
        final devMap = map['device'] as Map<String, dynamic>?;

        if (devMap == null || groupId == null || groupName == null) return;

        final device = deviceFromGroupJson(devMap);
        final key = device.fingerprint.isNotEmpty ? device.fingerprint : (device.ip ?? '');
        if (key.isEmpty) return;

        // Skip self
        final myDevice = ref.read(deviceFullInfoProvider);
        final myKey = myDevice.fingerprint.isNotEmpty ? myDevice.fingerprint : (myDevice.ip ?? 'local');
        if (key == myKey) return;

        final currentGroup = state.groups[groupId];
        final members = Map<String, Device>.from(currentGroup?.members ?? {});

        if (members.length < maxGroupCapacity || members.containsKey(key)) {
          members[key] = device;
        }

        final updatedGroup = DiscoveredGroup(
          groupId: groupId,
          groupName: groupName,
          members: members,
          lastHeartbeat: DateTime.now(),
        );

        final updatedGroups = Map<String, DiscoveredGroup>.from(state.groups)..[groupId] = updatedGroup;
        final newSelectedId = state.selectedGroupId ?? groupId;

        state = state.copyWith(
          groups: updatedGroups,
          selectedGroupId: newSelectedId,
        );
      } else if (type == 'group_leave') {
        final groupId = map['groupId'] as String?;
        final leaveKey = map['fingerprint'] as String? ?? (map['ip'] as String? ?? '');

        if (groupId != null && state.groups.containsKey(groupId)) {
          final currentGroup = state.groups[groupId]!;
          final updatedMembers = Map<String, Device>.from(currentGroup.members)..remove(leaveKey);
          final updatedGroups = Map<String, DiscoveredGroup>.from(state.groups)..[groupId] = currentGroup.copyWith(members: updatedMembers);

          state = state.copyWith(groups: updatedGroups);
        }
      }
    } catch (_) {}
  }

  void _broadcastQuery() {
    if (_socket == null || !state.isScanning) return;
    try {
      final bytes = utf8.encode(jsonEncode({'type': 'group_query'}));
      final localIps = ref.read(localIpProvider).localIps;
      final nearbyDevices = ref.read(nearbyDevicesProvider).allDevices.values;

      try {
        _socket?.send(bytes, InternetAddress('255.255.255.255'), groupUdpPort);
      } catch (_) {}

      for (final ip in localIps) {
        final parts = ip.split('.');
        if (parts.length == 4) {
          try {
            final subnetBroadcast = '${parts[0]}.${parts[1]}.${parts[2]}.255';
            _socket?.send(bytes, InternetAddress(subnetBroadcast), groupUdpPort);
          } catch (_) {}
        }
      }

      for (final dev in nearbyDevices) {
        if (dev.ip != null) {
          try {
            _socket?.send(bytes, InternetAddress(dev.ip!), groupUdpPort);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  void _cleanupStaleGroups() {
    final now = DateTime.now();
    final updatedGroups = <String, DiscoveredGroup>{};
    var changed = false;

    for (final entry in state.groups.entries) {
      if (now.difference(entry.value.lastHeartbeat).inSeconds <= 7) {
        updatedGroups[entry.key] = entry.value;
      } else {
        changed = true;
      }
    }

    if (changed) {
      final newSelectedId = updatedGroups.containsKey(state.selectedGroupId) ? state.selectedGroupId : updatedGroups.keys.firstOrNull;
      state = state.copyWith(groups: updatedGroups, selectedGroupId: newSelectedId);
    }
  }

  void selectGroup(String groupId) {
    if (state.groups.containsKey(groupId)) {
      state = state.copyWith(selectedGroupId: groupId);
    }
  }

  void stop() {
    if (!state.isScanning) return;

    _queryTimer?.cancel();
    _cleanupTimer?.cancel();
    _socket?.close();
    _socket = null;

    state = const GroupSendState();
  }
}
