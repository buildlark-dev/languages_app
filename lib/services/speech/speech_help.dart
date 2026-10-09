/// Qué se le dice a la persona cuando la voz o el micrófono no responden.
///
/// ## La regla, que es de producto y no técnica
///
/// **Nunca se exige configurar el aparato.** El mensaje anterior decía «En
/// Android se añade en Ajustes → Sistema → Idiomas → Salida de texto a voz», y
/// eso tiene dos problemas: en Android es una exigencia, y en cualquier otra
/// plataforma no dice nada que se pueda hacer. Quien abre una app para aprender
/// inglés y lo primero que recibe es una tarea de configuración, la cierra.
///
/// Lo que FR-014 y FR-018 piden es **informar** y dejar seguir. Así que el
/// mensaje dice qué pasa y qué queda disponible —leer, la transcripción,
/// escribir la respuesta—, y los pasos de configuración quedan detrás de una
/// pregunta opcional, redactados para la plataforma en la que de verdad se está
/// ejecutando.
///
/// Que estos textos vivan juntos y no repartidos por los widgets es a propósito:
/// son la parte de la app que se lee en el peor momento, y conviene poder leerla
/// entera de una vez para comprobar que no suena a reproche.
library;

import 'package:flutter/foundation.dart';

import 'stt_service.dart';

/// Lo que se dice cuando no hay forma de reproducir el audio.
///
/// Ni una palabra de instalar nada: lo primero es que se puede seguir.
const String audioUnavailableMessage =
    'No se pudo reproducir el audio en este dispositivo. Puedes seguir con el '
    'texto escrito: la lección se aprueba igual.';

/// Lo que se dice cuando el motor está pero falló la reproducción.
const String audioFailedMessage =
    'No se pudo reproducir el audio. Inténtalo otra vez.';

/// Cómo se añade una voz, en la plataforma donde se está ejecutando.
///
/// Devuelve `null` cuando no se puede dar un paso concreto y fiable, y eso es
/// mejor que un párrafo vago: una indicación que no corresponde al aparato que
/// se tiene delante hace perder más tiempo que no dar ninguna.
String? get voiceInstallSteps {
  // En web **también** se mira la plataforma, no se da un párrafo genérico.
  // Flutter deduce `defaultTargetPlatform` del navegador, así que en un
  // iPhone sale la ruta de iOS. La versión anterior listaba Windows y Android
  // pase lo que pase, y eso fue lo que vio una persona en un iPhone: una
  // instrucción para un sistema que no es el suyo.
  final String? steps = switch (defaultTargetPlatform) {
    TargetPlatform.android =>
      'En Ajustes → Sistema → Idiomas → Salida de texto a voz puedes instalar '
          'la voz en inglés del motor que uses.',
    TargetPlatform.iOS =>
      'En Ajustes → Accesibilidad → Contenido leído → Voces → English puedes '
          'descargar una voz en inglés.',
    TargetPlatform.windows =>
      'En Configuración → Hora e idioma → Voz puedes añadir una voz en inglés.',
    TargetPlatform.macOS =>
      'En Ajustes del sistema → Accesibilidad → Contenido leído puedes '
          'descargar una voz en inglés.',
    TargetPlatform.linux || TargetPlatform.fuchsia => null,
  };

  if (steps == null) return null;
  // En el navegador las voces las publica el sistema al cargar la página.
  return kIsWeb ? '$steps Después, recarga la página.' : steps;
}

/// Qué pasó con el micrófono, dicho de forma que se pueda seguir.
///
/// Cada caso termina en lo que sí se puede hacer. Un diagnóstico sin salida es
/// un callejón, y en un ejercicio de pronunciación la salida existe siempre:
/// escribirlo (FR-019, SC-008).
String microphoneFailureMessage(SttFailure failure) => switch (failure) {
  SttFailure.permissionDenied =>
    'No hay permiso de micrófono. Puedes concederlo y volver a intentarlo, o '
        'escribir la respuesta.',
  SttFailure.needsNetwork =>
    'El reconocimiento de voz de este dispositivo necesita conexión. Sin red '
        'puedes escribir la respuesta y seguir igual.',
  SttFailure.languageUnsupported =>
    'El reconocedor de este dispositivo no tiene inglés. Puedes escribir la '
        'respuesta.',
  SttFailure.noRecognizer =>
    'Este dispositivo no tiene reconocimiento de voz disponible. Puedes '
        'escribir la respuesta.',
  SttFailure.noMicrophone =>
    'No se pudo usar el micrófono. Puedes escribir la respuesta.',
  SttFailure.unknown =>
    'No se pudo escuchar. Puedes intentarlo otra vez o escribir la respuesta.',
};

/// Dónde se concede el permiso del micrófono, en esta plataforma.
///
/// Solo se ofrece cuando el permiso es el problema: en los demás casos no hay
/// nada que conceder y mostrar unos pasos sería mandar a alguien a buscar un
/// ajuste que no existe.
String? get microphonePermissionSteps {
  // Aquí el navegador sí manda sobre el sistema: el permiso lo concede la
  // página, no el aparato. En una PWA instalada en iOS se gestiona desde
  // Ajustes de Safari, por eso se distingue.
  if (kIsWeb) {
    return defaultTargetPlatform == TargetPlatform.iOS
        ? 'En iPhone, el permiso del micrófono para esta app se concede al '
              'tocar el botón, y se cambia en Ajustes → Safari → Micrófono.'
        : 'En el navegador, el permiso se gestiona en el candado de la barra '
              'de direcciones, en «Permisos del sitio».';
  }

  return switch (defaultTargetPlatform) {
    TargetPlatform.android =>
      'En Ajustes → Aplicaciones → Idiomas → Permisos → Micrófono.',
    TargetPlatform.iOS => 'En Ajustes → Privacidad → Micrófono.',
    TargetPlatform.windows ||
    TargetPlatform.macOS ||
    TargetPlatform.linux ||
    TargetPlatform.fuchsia => null,
  };
}
