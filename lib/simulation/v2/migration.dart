import 'dart:math' as math;
import 'materials.dart';

/// A real, separately counted population residence during a journey. Completed
/// journeys retain their material/population balances instead of being erased.
class MigrationJourney {
  final String id, from, to;
  final String? cause;
  final int departedDay, departed, plannedDistance;
  final Map<String, int> initial;
  final Map<String, int> carried, consumed, delivered, lost;
  List<int> path;
  int progress, lastDay, deaths, arrived, deprivedDays;
  String status;
  bool blocked;
  int? resolvedDay;
  String? resolvedSettlement;

  MigrationJourney({
    required this.id,
    required this.from,
    required this.to,
    required this.departedDay,
    required this.departed,
    required List<int> path,
    required Map<String, int> supplies,
    int? plannedDistance,
    this.cause,
  }) : plannedDistance = plannedDistance ?? math.max(1,path.length-1),
       path = List.from(path),
       initial = Map.unmodifiable(supplies),
       carried = Map.from(supplies),
       consumed = {'food': 0, 'water': 0},
       delivered = {'food': 0, 'water': 0},
       lost = {'food': 0, 'water': 0},
       progress = 0,
       lastDay = departedDay,
       deaths = 0,
       arrived = 0,
       deprivedDays = 0,
       status = 'outbound',
       blocked = false;

  String get residence => 'transit:$id';
  bool get active => status == 'outbound' || status == 'returning';
  String get goal => status == 'returning' ? from : to;
  int get cell => path[progress];
  int get survivors => departed - deaths;

  /// A daily walking step plus fourteen days of contingency. There is no
  /// resupply by wall clock, screen animation or implicit population creation.
  static Map<String, int> provisions(int people, int distance) => {
    'food': people * (distance + 14) * 45,
    'water': people * (distance + 14) * 35,
  };

  /// Returns actual deprivation deaths for the ledger to apply exactly once.
  int consumeDay(int day, int residents) {
    if (!active || day != lastDay + 1 || residents != survivors) {
      throw const FormatException('Día o población de viaje incompatible');
    }
    lastDay = day;
    var deprived = false;
    for (final r in ['food', 'water']) {
      final need = residents * (r == 'food' ? 45 : 35);
      final used = math.min(need, carried[r]!);
      carried[r] = carried[r]! - used;
      consumed[r] = consumed[r]! + used;
      deprived |= used < need;
    }
    deprivedDays = deprived ? deprivedDays + 1 : 0;
    if (deprivedDays < 30) return 0;
    deprivedDays = 0;
    final count = math.min(residents, math.max(1, residents ~/ 10));
    deaths += count;
    return count;
  }

  void finish(int day, {String? settlement, Map<String,int>? acceptedSupplies}) {
    if (!active || day != lastDay) {
      throw const FormatException('Resolución de viaje duplicada o sin fecha');
    }
    if (settlement == null && survivors != 0) {
      throw const FormatException('Supervivientes sin destino');
    }
    if (settlement != null && settlement != goal) {
      throw const FormatException('Entrega fuera del destino confirmado');
    }
    arrived = settlement == null ? 0 : survivors;
    status = settlement == null ? 'lost' : settlement == from ? 'returned' : 'arrived';
    resolvedSettlement = settlement;
    resolvedDay = day;
    blocked = false;
    for (final r in carried.keys) {
      final accepted = settlement == null ? 0 : acceptedSupplies?[r] ?? carried[r]!;
      if(accepted < 0 || accepted > carried[r]!)throw const FormatException('Entrega de provisiones imposible');
      delivered[r] = accepted;
      lost[r] = carried[r]! - accepted;
      carried[r] = 0;
    }
  }

  void validate(int day, int size) {
    bool identifier(String value) => RegExp(r'^[A-Za-z0-9_.:-]{1,100}$').hasMatch(value);
    if (!identifier(id) || !identifier(from) || !identifier(to) || from == to ||
        departed < 1 || departed > 100000 || plannedDistance < 1 || plannedDistance > size*size || deaths < 0 || deaths > departed ||
        arrived < 0 || arrived > survivors || deprivedDays < 0 || deprivedDays >= 30 ||
        departedDay < 0 || lastDay < departedDay || lastDay > day ||
        !['outbound', 'returning', 'arrived', 'returned', 'lost'].contains(status) ||
        path.isEmpty || path.length > size * size || progress < 0 || progress >= path.length ||
        path.any((p) => p < 0 || p >= size * size) ||
        cause != null && cause!.length > 128) {
      throw const FormatException('Trayecto migratorio inválido');
    }
    for (var i = 1; i < path.length; i++) {
      final a = path[i-1], b = path[i];
      if ((a % size - b % size).abs() + (a ~/ size - b ~/ size).abs() != 1) {
        throw const FormatException('Trayecto migratorio desconectado');
      }
    }
    for (final map in [initial, carried, consumed, delivered, lost]) {
      if (map.length != 2 || !map.keys.toSet().containsAll(['food', 'water']) ||
          map.values.any((n) => n < 0 || n > Quantity.maxMillis)) {
        throw const FormatException('Provisiones migratorias inválidas');
      }
    }
    for (final r in initial.keys) {
      if(initial[r] != provisions(departed,plannedDistance)[r])throw const FormatException('Provisiones iniciales incompatibles con el viaje');
      if (initial[r] != carried[r]! + consumed[r]! + delivered[r]! + lost[r]!) {
        throw const FormatException('Balance de viaje incoherente');
      }
    }
    if (active) {
      if (lastDay != day || resolvedDay != null || resolvedSettlement != null || arrived != 0 ||
          survivors == 0 || delivered.values.any((n) => n != 0) || lost.values.any((n) => n != 0)) {
        throw const FormatException('Viaje activo ya resuelto');
      }
    } else if (resolvedDay != lastDay || resolvedDay == null ||
        carried.values.any((n) => n != 0) ||
        status == 'lost' && (survivors != 0 || arrived != 0 || resolvedSettlement != null || delivered.values.any((n) => n != 0)) ||
        status != 'lost' && (arrived != survivors || arrived == 0 ||
          resolvedSettlement != (status == 'returned' ? from : to) || progress != path.length - 1)) {
      throw const FormatException('Resolución migratoria incoherente');
    }
  }

  Map<String, dynamic> toJson() => {
    'version': 1, 'id': id, 'from': from, 'to': to, 'cause': cause,
    'departedDay': departedDay, 'departed': departed, 'plannedDistance':plannedDistance, 'lastDay': lastDay,
    'path': path, 'progress': progress, 'status': status, 'blocked': blocked,
    'initial': initial, 'carried': carried, 'consumed': consumed,
    'delivered': delivered, 'lost': lost, 'deaths': deaths, 'arrived': arrived,
    'deprivedDays': deprivedDays, 'resolvedDay': resolvedDay,
    'resolvedSettlement': resolvedSettlement,
  };

  factory MigrationJourney.fromJson(Map<String, dynamic> raw) {
    const keys = {'version','id','from','to','cause','departedDay','departed','plannedDistance','lastDay',
      'path','progress','status','blocked','initial','carried','consumed','delivered',
      'lost','deaths','arrived','deprivedDays','resolvedDay','resolvedSettlement'};
    if (raw.length != keys.length || raw.keys.any((k) => !keys.contains(k)) || raw['version'] != 1) {
      throw const FormatException('Esquema de migración incompatible');
    }
    return MigrationJourney(id: raw['id'], from: raw['from'], to: raw['to'],
      departedDay: raw['departedDay'], departed: raw['departed'],plannedDistance:raw['plannedDistance'],
      path: List<int>.from(raw['path']), supplies: Map<String,int>.from(raw['initial']), cause: raw['cause'])
      ..lastDay = raw['lastDay'] ..progress = raw['progress'] ..status = raw['status']
      ..blocked = raw['blocked'] ..deaths = raw['deaths'] ..arrived = raw['arrived']
      ..deprivedDays = raw['deprivedDays'] ..resolvedDay = raw['resolvedDay']
      ..resolvedSettlement = raw['resolvedSettlement']
      ..carried.clear() ..carried.addAll(Map<String,int>.from(raw['carried']))
      ..consumed.clear() ..consumed.addAll(Map<String,int>.from(raw['consumed']))
      ..delivered.clear() ..delivered.addAll(Map<String,int>.from(raw['delivered']))
      ..lost.clear() ..lost.addAll(Map<String,int>.from(raw['lost']));
  }
}
