/// Ajustes: tema, velocidad de voz y respaldo.
///
/// El tema y la velocidad de voz son del **dispositivo** y no se sincronizan:
/// alguien puede querer modo claro en el PC y oscuro en el teléfono, y
/// sincronizarlo sería una molestia disfrazada de ventaja. Está documentado en
/// `settings_store.dart` y aquí solo se respeta.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app.dart';
import '../../services/settings/settings_store.dart';
import '../providers/speech_providers.dart';
import '../widgets/backup_section.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final SettingsStore settings = ref.watch(settingsStoreProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text('Apariencia', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            // Los tres modos, incluido «el del sistema», que es el valor de
            // partida: respetar la preferencia del dispositivo es lo correcto
            // mientras nadie diga lo contrario (FR-048).
            //
            // El grupo va en un `RadioGroup` y no con `groupValue` en cada
            // tarjeta porque esa forma quedó obsoleta en Flutter 3.32: el valor
            // y el cambio son del grupo, no de cada opción, y repetirlos en las
            // tres era la vía para que una se quedara sin actualizar.
            RadioGroup<ThemeMode>(
              groupValue: settings.themeMode,
              onChanged: (ThemeMode? chosen) => _setTheme(settings, chosen),
              child: Column(
                children: <Widget>[
                  for (final ThemeMode mode in ThemeMode.values)
                    RadioListTile<ThemeMode>(
                      value: mode,
                      title: Text(_themeLabel(mode)),
                    ),
                ],
              ),
            ),
            const Divider(height: 32),
            Text('Voz', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Velocidad con la que se leen las palabras en voz alta.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            _SpeechRateSlider(
              value: settings.speechRate,
              onChanged: (double rate) => _setSpeechRate(settings, rate),
            ),
            const Divider(height: 32),
            const BackupSection(),
          ],
        ),
      ),
    );
  }

  String _themeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'Como el sistema',
    ThemeMode.light => 'Claro',
    ThemeMode.dark => 'Oscuro',
  };

  Future<void> _setTheme(SettingsStore settings, ThemeMode? mode) async {
    if (mode == null) return;
    await settings.setThemeMode(mode);
    // El almacén no es un `Notifier`, así que no avisa por su cuenta. Este
    // `setState` es lo que repinta la pantalla, y la invalidación lo que repinta
    // el resto de la app.
    if (mounted) setState(() {});
    ref.invalidate(themeModeProvider);
  }

  Future<void> _setSpeechRate(SettingsStore settings, double rate) async {
    await settings.setSpeechRate(rate);
    if (!mounted) return;
    setState(() {});

    // Se aplica de inmediato a la voz ya inicializada: cambiar el número y
    // seguir oyendo la velocidad anterior parecería que el ajuste no funciona.
    await ref.read(ttsServiceProvider).setRate(settings.speechRate);
  }
}

/// Deslizador de velocidad con una muestra audible.
///
/// El botón de probar no es un extra: «0,7» no significa nada hasta que se oye,
/// y sin él la única forma de ajustar la velocidad es entrar en una lección,
/// escuchar, y volver.
class _SpeechRateSlider extends ConsumerWidget {
  const _SpeechRateSlider({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    children: <Widget>[
      Row(
        children: <Widget>[
          const Icon(Icons.slow_motion_video),
          Expanded(
            child: Slider(
              // Los extremos son los del almacén: por debajo de 0,3 la voz se
              // vuelve ininteligible, y permitirlo solo daría una forma de
              // romper los ejercicios de escucha.
              min: minSpeechRate,
              max: maxSpeechRate,
              divisions: 7,
              value: value.clamp(minSpeechRate, maxSpeechRate),
              label: value.toStringAsFixed(1),
              onChanged: onChanged,
            ),
          ),
          const Icon(Icons.speed),
        ],
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () =>
              ref.read(ttsServiceProvider).speak('This is the reading speed.'),
          icon: const Icon(Icons.volume_up_outlined),
          label: const Text('Probar la voz'),
        ),
      ),
    ],
  );
}
