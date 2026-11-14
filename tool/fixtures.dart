import 'package:barrio_cero_eras/simulation/engine.dart';

/// Verification-only: rebuild an intentionally edited fixture's cohort state.
/// Production commands must use the population ledger's transfers and deaths.
/// Trimming is explicit because lowering a count below its featured residents
/// cannot represent a valid scarcity fixture without removing those residents.
void fixturePopulation(WorldState world, {bool trimFeatures = false}) {
  if (world.populationState == null) return;
  final carry = {
    for (final e in world.populationState!.birthCredits.entries)
      e.key: Map<String, int>.from(e.value),
  };
  for (final s in world.societies) {
    final remaining = [s.children, s.adults, s.elders];
    for (final p in s.people.where((p) => p.alive)) {
      final age = (world.day - p.bornDay) ~/ 360;
      final band = age < 16
          ? 0
          : age < 65
          ? 1
          : 2;
      if (remaining[band] == 0 && trimFeatures) {
        p.diedDay = world.day;
        continue;
      }
      remaining[band]--;
    }
  }
  world.entities!.reconcile(world.identityRecords);
  world.populationState = WorldState.estimatePopulation(
    world.day,
    world.societies.map((s) => s.toJson()),
    world.entities!,
  );
  world.populationState!.birthCredits.addAll(carry);
  for (final s in world.societies) {
    if (s.people.any(
      (p) => p.alive && p.id == s.leaderId && world.day - p.bornDay >= 18 * 360,
    )) {
      continue;
    }
    final residents = s.people
        .where((p) => p.alive && world.day - p.bornDay >= 18 * 360)
        .toList();
    if (residents.isNotEmpty) {
      s.leaderId = residents.first.id;
      continue;
    }
    final group = world.populationState!.candidate(s.id, minimumAge: 18);
    if (group == null) {
      s.leaderId = '';
      continue;
    }
    final person = Person(
      'fixture:${s.id}:${s.people.length}',
      'Residente de prueba',
      'dirigente',
      group.bornDay,
      'prudent',
      birthEstimated: group.estimated,
    );
    s.people.add(person);
    s.leaderId = person.id;
    world.populationState!.register(person.id, group.id);
  }
  world.entities!.reconcile(world.identityRecords);
  world.validate();
}

/// Static test fixture: declare an accessible corridor instead of assuming a
/// random map connects the two actors. Never called by production commands.
void fixturePath(WorldState world, String from, String to) {
  final a = world.society(from)!, b = world.society(to)!;
  var x = a.x, y = a.y;
  void open() {
    final i = y * world.size + x, t = world.tiles[i];
    if (!t.passable || t.damage >= .9) {
      world.tiles[i] = Tile(x, y, 0, t.richness, ruin: t.ruin);
    }
  }

  open();
  while (x != b.x) {
    x += x < b.x ? 1 : -1;
    open();
  }
  while (y != b.y) {
    y += y < b.y ? 1 : -1;
    open();
  }
  world.validate();
}
