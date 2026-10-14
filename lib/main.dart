/// Raíz de composición.
///
/// Es el **único** archivo autorizado a importar contenido concreto
/// (`content/catalog.dart`), según el Principio II de la constitución v1.1.0. Su
/// trabajo es exactamente ese: unir las piezas que las demás capas solo conocen
/// como contratos.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'app/app.dart';
import 'content/catalog.dart';
import 'content/en/a1_audio_manifest.dart';
import 'core/clock.dart';
import 'firebase_options.dart';
import 'services/auth/firebase_auth_service.dart';
import 'services/db/app_database.dart';
import 'services/db/database_opener.dart';
import 'services/db/memory_database.dart';
import 'services/db/progress_dao.dart';
import 'services/db/review_dao.dart';
import 'services/backup/json_backup_service.dart';
import 'services/progress/drift_progress_store.dart';
import 'services/review/drift_review_store.dart';
import 'services/settings/prefs_settings_store.dart';
import 'services/settings/settings_store.dart';
import 'services/speech/audio_clip_player.dart';
import 'services/speech/clip_backed_tts_service.dart';
import 'services/speech/flutter_tts_service.dart';
import 'services/speech/speech_to_text_service.dart';
import 'services/sync/firestore_sync_service.dart';
import 'services/update/platform_update_checker.dart';
import 'ui/providers/auth_providers.dart';
import 'ui/providers/backup_providers.dart';
import 'ui/providers/content_providers.dart';
import 'ui/providers/progress_providers.dart';
import 'ui/providers/review_providers.dart';
import 'ui/providers/speech_providers.dart';
import 'ui/providers/update_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Se desactiva la caché local de Firestore a propósito.
  //
  // El almacén autoritativo es Drift. Dejar activa la persistencia de Firestore
  // crearía una segunda caché que resuelve conflictos por última escritura gana,
  // y entonces estudiar sin red en el teléfono y abrir después el PC borraría el
  // avance del teléfono. FR-042 lo prohíbe, y la fusión monotónica de
  // `progress_merger` existe precisamente para no depender de esa resolución.
  //
  // Desactivarla NO impide escuchar cambios en vivo: lo que se apaga es la caché
  // en disco, no la suscripción de la que vive SC-004.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );

  // El almacén local es la fuente de verdad del progreso. Si falla, la app sigue
  // siendo usable sobre una base volátil y lo dice (FR-043).
  //
  // La reserva llega por importación condicional (`memory_database.dart`) y no
  // se construye aquí: importar `drift/native.dart` desde la raíz arrastra
  // `dart:ffi`, que no existe en web, y el build web falla con un error que
  // apunta a sqlite3 en lugar de a la línea culpable.
  final DatabaseOpenResult store = await openAppDatabase(
    openPrimary: AppDatabase.new,
    openFallback: openMemoryDatabase,
  );

  // El mismo almacén para el progreso y para el respaldo: el respaldo lee y
  // escribe exactamente lo que la app usa, no una copia paralela.
  final DriftProgressStore progressStore = DriftProgressStore(
    ProgressDao(store.database),
  );

  // Las preferencias se cargan antes de la interfaz porque el tema se lee al
  // construir el primer widget. Si el almacenamiento falla, se sigue con la
  // reserva en memoria: perder el modo oscuro es un inconveniente, no una razón
  // para no arrancar.
  SettingsStore settings;
  try {
    settings = await PrefsSettingsStore.open();
  } catch (error) {
    // La reserva deja constancia en lugar de caer en silencio. Una reserva
    // callada es exactamente lo que hizo que durante cuatro revisiones nadie
    // viera que las preferencias no se guardaban: funcionaba casi bien.
    debugPrint('Preferencias no disponibles, se usará la reserva: $error');
    settings = InMemorySettingsStore();
  }

  runApp(
    ProviderScope(
      overrides: [
        courseCatalogProvider.overrideWithValue(const AppCourseCatalog()),
        settingsStoreProvider.overrideWithValue(settings),
        authServiceProvider.overrideWithValue(
          FirebaseAuthService(fb.FirebaseAuth.instance),
        ),
        syncServiceProvider.overrideWithValue(
          FirestoreSyncService(FirebaseFirestore.instance),
        ),
        storageDegradedProvider.overrideWithValue(store.degraded),
        reviewStoreProvider.overrideWithValue(
          DriftReviewStore(ReviewDao(store.database)),
        ),
        progressStoreProvider.overrideWithValue(progressStore),
        backupServiceProvider.overrideWithValue(
          JsonBackupService(progressStore, clock: systemClock),
        ),
        // La voz se inicializa de forma perezosa, al preparar el curso: consultar
        // las voces del sistema tarda, y hacerlo en el arranque retrasaría la
        // primera pantalla sin que nadie lo necesite todavía.
        // El clip manda y la síntesis cubre lo que no tiene clip. Es el único
        // sitio donde se unen: el catálogo es contenido —vive en
        // `lib/content/en/`— y esta es la raíz de composición, el único
        // archivo autorizado a conocerlo (Principio I).
        ttsServiceProvider.overrideWithValue(
          ClipBackedTtsService(
            voice: FlutterTtsService(FlutterTts()),
            clips: AudioClipPlayer(AudioPlayer()),
            catalog: a1AudioClips,
          ),
        ),
        sttServiceProvider.overrideWithValue(
          SpeechToTextService(stt.SpeechToText()),
        ),
        // En web pregunta por `build-id.json`; en las demás plataformas
        // contesta que no hay nada, porque allí la versión la cambia el
        // paquete y no la app.
        updateCheckerProvider.overrideWithValue(createUpdateChecker()),
      ],
      child: const LanguagesApp(),
    ),
  );
}
