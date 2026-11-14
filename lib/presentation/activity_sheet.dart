import 'package:flutter/material.dart';
import 'settlement_activity.dart';
import 'world_game.dart' show gold, earth, moss;

/// Contextual detail; the main map gets a single optional activity shortcut.
List<Widget> activitySheet(
  SettlementActivity activity, {
  required String Function(String) buildingName,
  required String Function(String) resourceName,
  required String Function(int) date,
  required String Function(String) courseName,
}) => [
  Text(
    activity.productionDay == null
        ? 'Avanza un día para observar una jornada completa.'
        : 'Jornada confirmada · ${date(activity.productionDay!)}',
    style: const TextStyle(color: moss),
  ),
  if (activity.productionDay != null) ...[
    const SizedBox(height: 12),
    Text(
      '${SettlementActivity.labor(activity.laborMillis)} jornadas asignadas',
      style: const TextStyle(color: gold, fontSize: 20),
    ),
    const Text('La comunidad organiza sus oficios por su cuenta.'),
    for (final item in activity.sites)
      ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.handyman_outlined),
        title: Text(buildingName(item.building)),
        subtitle: Text(
        '${SettlementActivity.labor(item.laborMillis)} jornadas',
        ),
      ),
    for (final e in activity.otherLabor.entries)
      ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.nature_people_outlined),
        title: Text(
          e.key == 'work:gather_wood'
              ? 'Recolección de madera'
              : e.key.startsWith('work:')
              ? 'Trabajo colectivo'
              : buildingName(e.key),
        ),
        subtitle: Text('${SettlementActivity.labor(e.value)} jornadas'),
      ),
    if (activity.produced.isNotEmpty)
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            for (final e in activity.produced.entries)
              Text(
                '+${SettlementActivity.labor(e.value)} ${resourceName(e.key)}',
                style: const TextStyle(color: earth),
              ),
          ],
        ),
      ),
  ],
  for (final project in activity.projects)
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project.kind == 'construction'
                ? buildingName(project.target)
                : courseName(project.target),
            style: const TextStyle(color: gold, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: project.fraction),
          const SizedBox(height: 6),
          Text(
            '${(project.fraction * 100).floor()}% · ${project.paused ? 'En espera de trabajadores' : '${project.workers} plazas de trabajo reservadas'}',
          ),
        ],
      ),
    ),
  if (activity.outgoingRoutes > 0)
    Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        '${activity.outgoingRoutes} rutas de comercio parten de esta comunidad.',
      ),
    ),
];
