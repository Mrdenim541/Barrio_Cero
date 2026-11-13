class WorkOrder {
  final String id;
  final int totalWork, workers, createdDay, sequence;
  final Map<String, int> committed;
  int remaining;
  bool paused;
  WorkOrder({
    required this.id,
    required this.totalWork,
    required this.remaining,
    this.workers = 4,
    this.createdDay = 0,
    this.sequence = 0,
    Map<String, int> committed = const {},
    this.paused = false,
  }) : committed = Map.unmodifiable({
         for (final e in committed.entries)
           if (e.value != 0) e.key: e.value,
       }) {
    if (id.isEmpty ||
        id.length > 128 ||
        workers < 1 ||
        workers > 1000 ||
        totalWork < 1 ||
        totalWork > 1000000000 ||
        remaining < 0 ||
        remaining > totalWork ||
        createdDay < 0 ||
        sequence < 0 ||
        committed.entries.any((e) => e.value < 0 || e.value > 1000000000000)) {
      throw const FormatException('Compromiso de trabajo inválido');
    }
  }
  int advance(int available) {
    if (available < 0) throw const FormatException('Personal negativo');
    final used = [
      available,
      workers,
      remaining,
    ].reduce((a, b) => a < b ? a : b);
    remaining -= used;
    paused = remaining > 0 && used == 0;
    return used;
  }

  Map<String, int> get refund => {
    for (final e in committed.entries)
      e.key:
          ((BigInt.from(e.value) * BigInt.from(remaining)) ~/
                  BigInt.from(totalWork))
              .toInt(),
  };
  Map<String, dynamic> toJson() => {
    'id': id,
    'totalWork': totalWork,
    'remaining': remaining,
    'workers': workers,
    'createdDay': createdDay,
    'sequence': sequence,
    'committed': committed,
    'paused': paused,
  };
  factory WorkOrder.fromJson(Map<String, dynamic> raw) {
    const keys = {
      'id',
      'totalWork',
      'remaining',
      'workers',
      'createdDay',
      'sequence',
      'committed',
      'paused',
    };
    if (raw.length != keys.length ||
        raw.keys.any((k) => !keys.contains(k)) ||
        raw['id'] is! String ||
        raw['paused'] is! bool ||
        raw['committed'] is! Map ||
        [
          'totalWork',
          'remaining',
          'workers',
          'createdDay',
          'sequence',
        ].any((k) => raw[k] is! int)) {
      throw const FormatException('Orden de trabajo incompatible');
    }
    final committed = <String, int>{};
    for (final e in (raw['committed'] as Map).entries) {
      if (e.key is! String || e.value is! int) {
        throw const FormatException('Material reservado inválido');
      }
      committed[e.key] = e.value;
    }
    return WorkOrder(
      id: raw['id'],
      totalWork: raw['totalWork'],
      remaining: raw['remaining'],
      workers: raw['workers'],
      createdDay: raw['createdDay'],
      sequence: raw['sequence'],
      committed: committed,
      paused: raw['paused'],
    );
  }
}
