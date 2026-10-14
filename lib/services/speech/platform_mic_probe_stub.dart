/// Plataformas donde el plugin ya pide el permiso por su cuenta.
///
/// Android y escritorio no necesitan sonda: `speech_to_text` dispara el
/// diálogo del sistema al inicializar. Responder «no hay nada que objetar» deja
/// esa ruta exactamente como estaba.
library;

import 'mic_probe.dart';

Future<MicProbe> probeMicrophone() async => const MicProbe.ok();
