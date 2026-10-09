/// Que se intente hablar aunque el aparato diga que no tiene voces.
///
/// Esta prueba existe por un fallo reportado en un iPhone, y la secuencia lo
/// cuenta entero: se abría la app y no había voz; se tocaba una palabra y
/// salía el aviso de instalar una voz; se iba a Ajustes, se tocaba «Probar la
/// voz» y **entonces sí funcionaba**; al volver a los módulos las palabras ya
/// sonaban; y al cerrar y abrir la PWA, otra vez igual.
///
/// La causa: en iOS `speechSynthesis.getVoices()` devuelve lista **vacía**
/// hasta que el motor se despierta, y lo que lo despierta es hablar. Preguntar
/// antes de hablar no puede responder nunca que sí.
///
/// Se maneja el canal del plugin a mano en lugar de un doble de `FlutterTts`:
/// `FlutterTts` es una clase concreta y lo que hay que comprobar es justamente
/// **en qué orden** habla con el lado nativo.
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:languages_app/services/speech/flutter_tts_service.dart';
import 'package:languages_app/services/speech/tts_service.dart';

const MethodChannel _channel = MethodChannel('flutter_tts');
const StandardMethodCodec _codec = StandardMethodCodec();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> calls;
  late List<Object?> voices;
  late bool engineAnswersStart;

  /// Simula el aviso que el motor manda cuando el sonido empieza de verdad.
  Future<void> reportStart() => TestDefaultBinaryMessengerBinding
      .instance
      .defaultBinaryMessenger
      .handlePlatformMessage(
        'flutter_tts',
        _codec.encodeMethodCall(const MethodCall('speak.onStart')),
        (_) {},
      );

  setUp(() {
    calls = <String>[];
    voices = <Object?>[];
    engineAnswersStart = true;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (MethodCall call) async {
          calls.add(call.method);
          switch (call.method) {
            case 'getLanguages':
              return voices;
            case 'getVoices':
              // El lado nativo devuelve mapas con nombre y etiqueta, no
              // etiquetas sueltas.
              return voices
                  .map(
                    (Object? tag) => <String, String>{
                      'name': 'Voz $tag',
                      'locale': '$tag',
                    },
                  )
                  .toList();
            case 'speak':
              // El motor avisa por su cuenta, después de que `speak` vuelva.
              if (engineAnswersStart) {
                Future<void>.delayed(
                  const Duration(milliseconds: 10),
                  reportStart,
                );
              }
              return 1;
            default:
              return 1;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  test('habla aunque no haya ninguna voz en la lista', () async {
    // El caso del iPhone: lista vacía y motor perfectamente capaz.
    final FlutterTtsService tts = FlutterTtsService(FlutterTts());

    final SpeakOutcome outcome = await tts.speak('good morning');

    expect(
      outcome,
      SpeakOutcome.spoken,
      reason:
          'Una lista de voces vacía no es una respuesta sobre si el aparato '
          'puede hablar: en iOS es lo que contesta hasta que algo habla',
    );
    expect(calls, contains('speak'));
  });

  test('no consulta nada antes de dar la orden de hablar', () async {
    // En iOS el permiso para hablar viene del gesto de la persona y se agota.
    // Cada consulta previa gasta ese margen, así que la primera llamada al
    // lado nativo tiene que ser `speak`.
    final FlutterTtsService tts = FlutterTtsService(FlutterTts());

    await tts.speak('good morning');

    expect(
      calls.first,
      'speak',
      reason: 'Antes de hablar se consultó «${calls.first}»',
    );
  });

  test('prepararse antes no cambia que se intente igual', () async {
    // `initialize` falla —no hay voces— y aun así hablar funciona. Antes esto
    // devolvía `noVoice` sin intentarlo.
    final FlutterTtsService tts = FlutterTtsService(FlutterTts());

    expect(await tts.initialize('en-US'), TtsAvailability.engineMissing);
    expect(await tts.speak('good morning'), SpeakOutcome.spoken);
  });

  test('si el motor no arranca y no hay voces, se dice que no hay voz', () async {
    engineAnswersStart = false;
    final FlutterTtsService tts = FlutterTtsService(FlutterTts());

    expect(await tts.speak('good morning'), SpeakOutcome.noVoice);
  });

  test('si el motor no arranca pero sí hay voces, no se culpa a la voz', () async {
    // Mandar a instalar una voz a quien ya tiene cinco es peor que no decir
    // nada: la persona se va a buscar un ajuste que no le falta.
    engineAnswersStart = false;
    voices = <Object?>['en-US', 'es-ES'];
    final FlutterTtsService tts = FlutterTtsService(FlutterTts());

    expect(await tts.speak('good morning'), SpeakOutcome.failed);
  });

  test('tras hablar se prepara la voz para la siguiente vez', () async {
    // El primer sonido de iOS sale con la voz que el sistema tenga puesta, que
    // aquí es española. En cuanto ha hablado, la lista existe: hay que
    // aprovecharla para que la segunda palabra ya suene en inglés.
    final FlutterTtsService tts = FlutterTtsService(FlutterTts());

    // Como en la app real: el curso prepara la voz al abrirse y, en iOS, esa
    // preparación no encuentra nada.
    expect(await tts.initialize('en-US'), TtsAvailability.engineMissing);

    // Y ahora sí: el motor ya habló, así que la lista existe.
    voices = <Object?>['en-US'];
    calls.clear();

    await tts.speak('good morning');
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(
      calls,
      contains('setVoice'),
      reason: 'Tras hablar hay lista de voces: hay que elegir la inglesa',
    );
  });
}
