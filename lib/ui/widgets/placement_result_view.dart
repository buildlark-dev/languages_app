/// Lo que se dice al terminar la nivelación.
///
/// Aquí vive FR-035 y FR-036, que son la parte delicada: hay que informar el
/// nivel estimado **real** y a la vez decir por dónde se empieza, sin que lo
/// segundo parezca una corrección de lo primero.
///
/// La redacción es deliberada. No dice «no puedes entrar en B1»: dice que B1
/// está en preparación y que mientras tanto A1 queda abierto para repaso. La
/// diferencia entre «no puedes» y «todavía no existe» es la diferencia entre
/// culpar a la persona y explicar el estado de la app.
library;

import 'package:flutter/material.dart';

import '../../core/placement_result.dart';

class PlacementResultView extends StatelessWidget {
  const PlacementResultView({
    required this.result,
    required this.assignedLevelId,
    required this.assignedLevelName,
    required this.assignedIsMastered,
    required this.onContinue,
    super.key,
  });

  final PlacementResult result;

  /// Dónde va a estudiar. Se **deriva** del catálogo, no se almacena.
  final String assignedLevelId;
  final String assignedLevelName;

  /// El nivel asignado quedó marcado como dominado, así que lo que hay allí es
  /// repaso y no contenido nuevo (FR-038).
  final bool assignedIsMastered;

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool estimateIsAbove = result.estimatedLevelId != assignedLevelId;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Icon(
          Icons.insights_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Tu nivel estimado es ${result.estimatedLevelId}',
          style: text.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Es lo que indica la prueba sobre lo que ya sabes.',
          style: text.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (result.masteredLevelIds.isNotEmpty)
          _Panel(
            icon: Icons.verified_outlined,
            title: _masteredTitle(result.masteredLevelIds),
            body:
                'Quedan abiertos para repasar cuando quieras. No tienes que '
                'volver a aprobarlos.',
          ),
        if (result.masteredLevelIds.isNotEmpty) const SizedBox(height: 12),
        // La explicación de la diferencia solo aparece cuando hay diferencia:
        // dársela a quien empieza justo donde la prueba dice sería ruido.
        if (estimateIsAbove)
          _Panel(
            icon: Icons.construction_outlined,
            title: 'Empiezas en $assignedLevelId',
            body:
                'El contenido de ${result.estimatedLevelId} está en '
                'preparación. $assignedLevelName es el nivel más alto '
                'disponible hoy, y te avisaremos cuando publiquemos el '
                'siguiente.',
          )
        else
          _Panel(
            icon: Icons.flag_outlined,
            title: 'Empiezas en $assignedLevelId',
            body: assignedLevelName,
          ),
        if (assignedIsMastered) ...<Widget>[
          const SizedBox(height: 12),
          const _Panel(
            icon: Icons.replay_outlined,
            title: 'Lo que encontrarás es repaso',
            body:
                'Ya demostraste este nivel, así que sus módulos están '
                'abiertos para repasar. Es la forma de no perder lo que ya '
                'sabes mientras preparamos lo siguiente.',
          ),
        ],
        const SizedBox(height: 32),
        FilledButton(onPressed: onContinue, child: const Text('Empezar')),
      ],
    );
  }

  String _masteredTitle(List<String> ids) => ids.length == 1
      ? '${ids.single} queda marcado como dominado'
      : '${ids.join(', ')} quedan marcados como dominados';
}

/// Un bloque de explicación con su icono.
class _Panel extends StatelessWidget {
  const _Panel({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
