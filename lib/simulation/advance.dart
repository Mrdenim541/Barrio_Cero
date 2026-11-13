class AdvanceRequest {
  final int days;
  final bool stopOnCrisis, delegateDecisions;
  const AdvanceRequest({
    required this.days,
    this.stopOnCrisis = false,
    this.delegateDecisions = false,
  });
}

enum AdvanceStop { completed, crisis, extinct }

class AdvanceResult {
  final int advancedDays, reachedDay;
  final AdvanceStop stop;
  final List<String> pendingDecisions;
  AdvanceResult(
    this.advancedDays,
    this.reachedDay,
    this.stop,
    Iterable<String> pending,
  ) : pendingDecisions = List.unmodifiable(pending);
}
