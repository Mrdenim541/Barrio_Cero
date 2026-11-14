import '../simulation/engine.dart';

/// One synchronous, transactional order, without taking persistent government.
/// The caller supplies a detached candidate; SessionController persists only
/// after authority has returned to the autonomous world.
class Intervention {
  static CommandResult? _reject(WorldState world, Command request) {
    if (world.controlledId != null) {
      return const CommandResult(
        false,
        'Deja actuar al mundo antes de intervenir sin tomar su dirección.',
        code: 'manual_session',
      );
    }
    if (request.action == 'control' || request.action == 'delegate') {
      return const CommandResult(
        false,
        'Una intervención no cambia quién gobierna permanentemente.',
        code: 'invalid_intervention',
      );
    }
    if (request.actorId == null || world.society(request.actorId) == null) {
      return const CommandResult(
        false,
        'La comunidad ya no está disponible.',
        code: 'invalid_actor',
      );
    }
    return null;
  }

  static CommandPreview preview(
    WorldState world,
    Map<String, dynamic> content,
    Command request,
  ) {
    final rejection = _reject(world, request);
    if (rejection != null) {
      return CommandPreview(
        allowed: false,
        reason: rejection.message,
        code: rejection.code,
        outcome: 'Revisa la intervención.',
      );
    }
    final previous = world.controlledId;
    try {
      world.controlledId = request.actorId;
      return (Simulation(world)..registerContent(content)).preview(request);
    } finally {
      world.controlledId = previous;
    }
  }

  static CommandResult submit(
    WorldState world,
    Map<String, dynamic> content,
    Command request,
  ) {
    final rejection = _reject(world, request);
    if (rejection != null) return rejection;
    final previous = world.controlledId;
    try {
      world.controlledId = request.actorId;
      return (Simulation(world)..registerContent(content)).submit(request);
    } finally {
      world.controlledId = previous;
    }
  }
}
