import 'dart:convert';

/// A camera preference, never authority over the individual or its society.
/// Legacy worlds have no UUID; seed, size and origin identify their lineage.
class FollowTarget {
  final String worldKey, individualId;
  final int bornDay;
  const FollowTarget(this.worldKey, this.individualId, this.bornDay);

  static String keyFor(Map<String, dynamic> world) =>
      '${world['seed']}:${world['size']}:${world['origin'] ?? 'reconstruction'}';

  factory FollowTarget.person(
    Map<String, dynamic> world,
    Map<String, dynamic> person,
  ) => FollowTarget(
    keyFor(world),
    person['id'] as String,
    person['bornDay'] as int,
  );

  TrackedIndividual? resolve(Map<String, dynamic> world) {
    if (worldKey != keyFor(world)) return null;
    for (final raw in world['societies'] as List? ?? []) {
      final settlement = Map<String, dynamic>.from(raw as Map);
      for (final entry in settlement['people'] as List? ?? []) {
        if (entry['id'] == individualId && entry['bornDay'] == bornDay) {
          return TrackedIndividual(
            settlement,
            Map<String, dynamic>.from(entry as Map),
          );
        }
      }
    }
    return null;
  }

  String encode({required bool active}) => jsonEncode({
    'version': 1,
    'worldKey': worldKey,
    'individualId': individualId,
    'bornDay': bornDay,
    'active': active,
  });

  static ({FollowTarget target, bool active})? decode(String? source) {
    if (source == null) return null;
    try {
      final raw = jsonDecode(source);
      if (raw is! Map ||
          raw.length != 5 ||
          raw['version'] != 1 ||
          raw['worldKey'] is! String ||
          raw['individualId'] is! String ||
          raw['bornDay'] is! int ||
          raw['active'] is! bool ||
          (raw['worldKey'] as String).length > 160 ||
          (raw['individualId'] as String).isEmpty ||
          (raw['individualId'] as String).length > 160) {
        return null;
      }
      return (
        target: FollowTarget(
          raw['worldKey'],
          raw['individualId'],
          raw['bornDay'],
        ),
        active: raw['active'],
      );
    } on FormatException {
      return null;
    }
  }
}

class TrackedIndividual {
  final Map<String, dynamic> settlement, person;
  const TrackedIndividual(this.settlement, this.person);
  String get actorId => settlement['id'] as String;
  String get name => person['name'] as String;
  bool get alive => person['diedDay'] == null;
}
