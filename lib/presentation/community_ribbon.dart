import 'package:flutter/material.dart';
import 'world_game.dart' show earth, gold, ink, moss;
import 'atlas_chrome.dart';

/// The always-visible controls. Explanations and full quantities open on demand.
class CommunityRibbon extends StatelessWidget {
  final String name, leader, action;
  final String? activity;
  final int population, housing, food, water;
  final bool foodLow, waterLow, enabled, travellers;
  final VoidCallback onDetails, onFood, onWater, onHousing, onAction;
  final VoidCallback? onMore;
  final VoidCallback? onBuild, onExplore;
  const CommunityRibbon({
    super.key,
    required this.name,
    required this.leader,
    required this.action,
    required this.population,
    required this.housing,
    required this.food,
    required this.water,
    required this.foodLow,
    required this.waterLow,
    required this.enabled,
    required this.travellers,
    required this.onDetails,
    required this.onFood,
    required this.onWater,
    required this.onHousing,
    required this.onAction,
    this.onMore,
    this.activity,
    this.onBuild,
    this.onExplore,
  });

  static String _count(int n) => n < 1000 ? '$n' : '${n ~/ 1000}mil';

  Widget _stock(
    String name,
    String value,
    IconData icon,
    bool warning,
    Color color,
    VoidCallback onTap,
  ) => SizedBox(
    width: 54,
    child: Tooltip(
      message: name,
      child: Semantics(
        label: '$name: $value',
        button: true,
        onTap: onTap,
        excludeSemantics: true,
        child: TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: EdgeInsets.zero,
            foregroundColor: warning ? const Color(0xffffb199) : color,
          ),
          onPressed: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(warning ? Icons.warning_amber_rounded : icon, size: 18),
              Text(value, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => AtlasPanel(
    padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
    color: ink,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Tooltip(
                message: 'Comunidad',
                child: InkWell(
                  onTap: onDetails,
                  borderRadius: BorderRadius.circular(6),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'serif',
                            ),
                          ),
                          Text(
                            activity ??
                                (leader.isEmpty
                                    ? '$population habitantes'
                                    : 'Lidera $leader'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: earth, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _stock(
              'Alimento',
              _count(food),
              Icons.grass,
              foodLow,
              gold,
              onFood,
            ),
            _stock(
              'Agua',
              _count(water),
              Icons.water_drop_outlined,
              waterLow,
              const Color(0xff94bfc7),
              onWater,
            ),
            _stock(
              'Habitantes',
              _count(population),
              Icons.groups_outlined,
              population > housing,
              moss,
              onHousing,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (onBuild != null) ...[
              Expanded(
                child: FilledButton(
                  onPressed: enabled ? onBuild : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  child: const Text(
                    'Construir',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
            if (onExplore != null) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: enabled ? onExplore : null,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  child: const Text('Explorar', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                ),
                onPressed: enabled ? onAction : null,
                child: Text(
                  action,
                  style: TextStyle(fontSize: onBuild == null ? 14 : 12),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (onMore != null) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  tooltip: 'Más acciones',
                  onPressed: enabled ? onMore : null,
                  icon: Badge(
                    isLabelVisible: travellers,
                    child: const Icon(Icons.more_horiz),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  );
}
