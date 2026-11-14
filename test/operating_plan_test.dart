import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/simulation/v2/operating_plan.dart';

void main() {
  Map<String, int> stock() => {
    'food': 0,
    'water': 0,
    'wood': 0,
    'stone': 0,
    'tools': 0,
    'knowledge': 0,
  };
  DailyProduction plan({
    int workers = 10,
    Map<String, int>? stocks,
    List<ProducerCapacity>? jobs,
  }) => planProduction(
    stocks: stocks ?? stock(),
    producers:
        jobs ??
        [
          ProducerCapacity('food', 2, {'food': 1500}),
          ProducerCapacity('water', 1, {'water': 1400}),
        ],
    workers: workers,
    minimumYield: {'food': 1080, 'water': 840},
    reserveStocks: {'food': 60000, 'water': 60000},
    otherTargets: {'wood': 200000, 'knowledge': 100000},
  );
  test(
    'Shared labor prioritizes both vital needs and keeps a material balance',
    () {
      final p = plan();
      expect(p.sustainsNeeds, isTrue);
      expect(p.laborUsed, lessThanOrEqualTo(10000));
      expect(p.closing['food'], greaterThanOrEqualTo(1080));
      expect(p.closing['water'], greaterThanOrEqualTo(840));
      p.validate();
    },
  );
  test('Scarce labor is shared and cannot be spent again in gathering', () {
    final p = plan(workers: 1);
    expect(p.sustainsNeeds, isFalse);
    expect(p.closing['food'], greaterThan(0));
    expect(p.closing['water'], greaterThan(0));
    expect(p.laborUsed, lessThanOrEqualTo(1000));
    p.validate();
  });
  test('No labor creates no output and a query leaves stocks untouched', () {
    final stocks = stock(), copy = Map<String, int>.from(stock());
    final p = plan(workers: 0, stocks: stocks);
    expect(p.produced, isEmpty);
    expect(p.laborUsed, 0);
    expect(stocks, copy);
  });
  test('Unavailable inputs reserve no workers and cannot become negative', () {
    final p = plan(
      jobs: [
        ProducerCapacity('smith', 10, {'tools': 150}, inputs: {'stone': 40}),
      ],
    );
    expect(p.allocations.containsKey('smith'), isFalse);
    expect(p.closing['tools'], 0);
    expect(p.closing['wood'], greaterThan(0));
    p.validate();
  });
  test('Imported production rejects forged stock or duplicated labor', () {
    final p = plan(), j = p.toJson();
    expect(DailyProduction.fromJson(j).toJson(), j);
    final forged = Map<String, dynamic>.from(j)
      ..['closing'] = {...p.closing, 'tools': 123};
    expect(() => DailyProduction.fromJson(forged), throwsFormatException);
    final doubled = Map<String, dynamic>.from(j)
      ..['allocations'] = {'food': 1000000};
    expect(() => DailyProduction.fromJson(doubled), throwsFormatException);
  });
}
