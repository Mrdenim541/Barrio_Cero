/// Read-only view of committed work. It never assigns jobs to named people.
class SiteWork {
  final String siteId, building;
  final int laborMillis;
  const SiteWork(this.siteId, this.building, this.laborMillis);
}

class WorkProgress {
  final String id, kind, target;
  final int remaining, total, workers;
  final bool paused;
  const WorkProgress(
    this.id,
    this.kind,
    this.target,
    this.remaining,
    this.total,
    this.workers,
    this.paused,
  );
  double get fraction => total == 0 ? 0 : (total - remaining) / total;
}

class SettlementActivity {
  final int? productionDay;
  final int laborMillis;
  final List<SiteWork> sites;
  final Map<String, int> otherLabor, produced;
  final List<WorkProgress> projects;
  final int outgoingRoutes;
  const SettlementActivity._(
    this.productionDay,
    this.laborMillis,
    this.sites,
    this.otherLabor,
    this.produced,
    this.projects,
    this.outgoingRoutes,
  );

  factory SettlementActivity.fromWorld(
    Map<String, dynamic> world,
    Map<String, dynamic> town,
  ) {
    int n(dynamic v) => v is num ? v.toInt() : 0;
    final day = n(world['day']), raw = town['lastProduction'];
    // Old balances remain historical facts; an extinct/stale town is not working.
    final current =
        raw is Map &&
        raw['day'] == day &&
        town['extinct'] != true &&
        n(town['population']) > 0;
    final flows = current && raw['flows'] is Map
        ? raw['flows'] as Map
        : const {};
    final allocations = flows['allocations'] as Map? ?? const {};
    final result = <SiteWork>[], other = <String, int>{};
    var totalLabor = 0;
    final siteList = (town['sites'] as List? ?? []).cast<Map>().toList()
      ..sort((a, b) => '${a['id']}'.compareTo('${b['id']}'));
    for (final entry in allocations.entries) {
      var remaining = n(entry.value);
      if (remaining <= 0) continue;
      totalLabor += remaining;
      final matches = siteList
          .where((s) => s['building'] == entry.key)
          .toList();
      // The ledger accounts by building type. Only a unique site is locatable;
      // with multiple sites, keep the labor aggregated rather than invent jobs.
      if (matches.length == 1 && remaining <= 2000) {
        result.add(
          SiteWork('${matches.single['id']}', '${entry.key}', remaining),
        );
        remaining = 0;
      }
      if (remaining > 0) other['${entry.key}'] = remaining;
    }
    final progress = <WorkProgress>[];
    for (final project in town['projects'] as List? ?? []) {
      final work = project['work'];
      if (work is! Map) continue;
      progress.add(
        WorkProgress(
          '${work['id']}',
          'construction',
          '${project['building']}',
          n(work['remaining']),
          n(work['totalWork']),
          n(work['workers']),
          work['paused'] == true,
        ),
      );
    }
    for (final lesson in town['lessons'] as List? ?? []) {
      final work = lesson['work'];
      if (work is! Map) continue;
      progress.add(
        WorkProgress(
          '${work['id']}',
          'learning',
          '${lesson['course']}',
          n(work['remaining']),
          n(work['totalWork']),
          n(work['workers']),
          work['paused'] == true,
        ),
      );
    }
    return SettlementActivity._(
      current ? day : null,
      totalLabor,
      List.unmodifiable(result),
      Map.unmodifiable(other),
      Map.unmodifiable({
        for (final e in (flows['produced'] as Map? ?? const {}).entries)
          if (n(e.value) > 0) '${e.key}': n(e.value),
      }),
      List.unmodifiable(progress),
      (world['routes'] as List? ?? [])
          .where((r) => r['from'] == town['id'])
          .length,
    );
  }

  bool get hasWork =>
      sites.isNotEmpty || otherLabor.isNotEmpty || projects.isNotEmpty;
  String get summary {
    final works = projects.where((p) => p.kind == 'construction').length;
    if (works > 0) {
      return '$works ${works == 1 ? 'obra en marcha' : 'obras en marcha'}';
    }
    if (laborMillis > 0) return '${labor(laborMillis)} jornadas productivas';
    if (projects.isNotEmpty) return 'Aprendices en formación';
    return 'Observar la vida del asentamiento';
  }

  static String labor(int millis) =>
      (millis / 1000).toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
}
