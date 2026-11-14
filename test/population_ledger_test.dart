import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/simulation/v2/population.dart';

void main() {
  int first(int maximum) => 0;
  test(
    'A featured resident belongs to the count instead of adding population',
    () {
      final ledger = PopulationLedger();
      final group = ledger.add(
        settlement: 'a',
        culture: 'culture:a',
        bornDay: -20 * 360,
        count: 2,
      );
      ledger.register('Ana', group);
      ledger.register('Leo', group);
      expect(ledger.total, 2);
      expect(ledger.totals('a').adults, 2);
      final before = jsonEncode(ledger.toJson());
      expect(() => ledger.register('Tito', group), throwsFormatException);
      expect(jsonEncode(ledger.toJson()), before);
      expect(() => ledger.register('Ana', group), throwsFormatException);
      ledger.validate();
    },
  );
  test('Age boundaries are exact and independent of batch sizes or saves', () {
    final a = PopulationLedger();
    final group = a.add(
      settlement: 'a',
      culture: 'c',
      bornDay: 1 - 16 * 360,
      count: 3,
    );
    a.register('p', group);
    final b = PopulationLedger.fromJson(jsonDecode(jsonEncode(a.toJson())));
    expect(a.totals('a').children, 3);
    a.advanceTo(1);
    expect(a.totals('a').adults, 3);
    expect(a.totals('a').children, 0);
    a.advanceTo(49 * 360 + 1);
    b.advanceTo(49 * 360 + 1);
    expect(a.totals('a').elders, 3);
    expect(a.totals('a').total, 3);
    expect(jsonEncode(a.toJson()), jsonEncode(b.toJson()));
    final expired = a.advanceTo(104 * 360 + 1);
    expect(expired, [group]);
    expect(() => a.validate(), throwsFormatException);
    final deaths = a.killCohort(group, 3, first);
    expect(deaths.people, ['p']);
    expect(a.total, 0);
    expect(a.members, isEmpty);
    a.validate();
  });
  test(
    'A migration carries people, age and culture while conserving both ends',
    () {
      final ledger = PopulationLedger();
      final source = ledger.add(
        settlement: 'a',
        culture: 'origin',
        bornDay: -30 * 360,
        count: 4,
      );
      ledger.register('p1', source);
      ledger.register('p2', source);
      ledger.add(
        settlement: 'b',
        culture: 'destination',
        bornDay: -25 * 360,
        count: 2,
      );
      final moved = ledger.transfer('a', 'b', 1, 1, first);
      expect(moved.people, ['p1']);
      expect(ledger.totals('a').adults, 3);
      expect(ledger.totals('b').adults, 3);
      expect(ledger.total, 6);
      final cohort = ledger.cohort(ledger.cohortOf('p1')!)!;
      expect(cohort.culture, 'origin');
      expect(cohort.bornDay, -30 * 360);
      expect(cohort.settlement, 'b');
      expect(ledger.cohortOf('p2'), source);
      ledger.validate();
      final restored = PopulationLedger.fromJson(
        jsonDecode(jsonEncode(ledger.toJson())),
      );
      expect(jsonEncode(restored.toJson()), jsonEncode(ledger.toJson()));
    },
  );
  test('Invalid transfers and casualties cannot partially change counts', () {
    final ledger = PopulationLedger();
    ledger.add(settlement: 'a', culture: 'c', bornDay: -25 * 360, count: 3);
    final before = jsonEncode(ledger.toJson());
    for (final action in <void Function()>[
      () => ledger.transfer('a', 'a', 1, 1, first),
      () => ledger.transfer('a', 'b', 4, 1, first),
      () => ledger.remove('a', 4, first),
      () => ledger.remove('a', 1, first, priority: [1, 1, 0]),
    ]) {
      expect(action, throwsFormatException);
      expect(jsonEncode(ledger.toJson()), before);
    }
  });
  test(
    'Casualties can affect featured residents without duplicating deaths',
    () {
      final ledger = PopulationLedger();
      final c = ledger.add(
        settlement: 'a',
        culture: 'c',
        bornDay: -70 * 360,
        count: 3,
      );
      ledger.register('elder', c);
      ledger.add(settlement: 'a', culture: 'c', bornDay: -20 * 360, count: 4);
      final casualties = ledger.remove('a', 2, first);
      expect(casualties.people, ['elder']);
      expect(ledger.total, 5);
      expect(ledger.members, isEmpty);
      final rest = ledger.remove('a', 5, first);
      expect(rest.people, isEmpty);
      expect(ledger.total, 0);
      ledger.validate();
    },
  );
  test(
    'Explicit conversion preserves known birthdays and marks common estimates',
    () {
      final ledger = PopulationLedger.fromProjections(
        day: 100,
        settlements: [
          {
            'id': 'a',
            'cultureId': 'culture:a',
            'children': 4,
            'adults': 8,
            'elders': 2,
            'people': [
              {'id': 'p', 'bornDay': 100 - 28 * 360, 'diedDay': null},
            ],
          },
        ],
      );
      expect(ledger.total, 14);
      expect(ledger.totals('a').toJson(), {
        'children': 4,
        'adults': 8,
        'elders': 2,
      });
      final known = ledger.cohort(ledger.cohortOf('p')!)!;
      expect(known.bornDay, 100 - 28 * 360);
      expect(known.estimated, isFalse);
      expect(
        ledger.cohorts
            .where((c) => c.estimated)
            .fold<int>(0, (n, c) => n + c.count),
        13,
      );
      expect(
        () => PopulationLedger.fromProjections(
          day: 0,
          settlements: [
            {
              'id': 'bad',
              'cultureId': 'c',
              'children': 1,
              'adults': 0,
              'elders': 0,
              'people': [
                {'id': 'adult', 'bornDay': -20 * 360, 'diedDay': null},
              ],
            },
          ],
        ),
        throwsFormatException,
      );
    },
  );
  test('A forged membership, reused serial or unknown species is rejected', () {
    final ledger = PopulationLedger();
    ledger.add(settlement: 'a', culture: 'c', bornDay: 0, count: 1);
    for (final edit in <void Function(Map<String, dynamic>)>[
      (m) => m['serial'] = 0,
      (m) => m['members'] = {'p': 'missing'},
      (m) => m['cohorts'][0]['species'] = 'unsupported',
      (m) => m['cohorts'][0]['count'] = -1,
    ]) {
      final raw =
          jsonDecode(jsonEncode(ledger.toJson())) as Map<String, dynamic>;
      edit(raw);
      expect(() => PopulationLedger.fromJson(raw), throwsFormatException);
    }
  });
}
