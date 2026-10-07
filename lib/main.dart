/// Raíz de composición.
///
/// Es el **único** archivo autorizado a importar contenido concreto
/// (`content/catalog.dart`), según el Principio II de la constitución v1.1.0. Su
/// trabajo es exactamente ese: unir las piezas que las demás capas solo conocen
/// como contratos.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/native.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'app/app.dart';
import 'content/catalog.dart';
import 'firebase_options.dart';
import 'services/auth/firebase_auth_service.dart';
import 'services/db/app_database.dart';
import 'services/db/database_opener.dart';
import 'services/db/review_dao.dart';
import 'services/review/drift_review_store.dart';
import 'services/speech/flutter_tts_service.dart';
import 'services/speech/speech_to_text_service.dart';
import 'services/sync/firestore_sync_service.dart';
import 'ui/providers/auth_providers.dart';
import 'ui/providers/content_providers.dart';
import 'ui/providers/progress_providers.dart';
import 'ui/providers/review_providers.dart';
import 'ui/providers/speech_providers.dart';

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
  // La reserva se elige aquí y no dentro del opener porque `NativeDatabase` es
  // específico de plataforma, y el opener debe poder compilarse y probarse en
  // cualquier destino.
  final DatabaseOpenResult store = await openAppDatabase(
    openPrimary: AppDatabase.new,
    openFallback: () => AppDatabase.withExecutor(NativeDatabase.memory()),
  );

  runApp(
    ProviderScope(
      overrides: [
        courseCatalogProvider.overrideWithValue(const AppCourseCatalog()),
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
        // La voz se inicializa de forma perezosa, al preparar el curso: consultar
        // las voces del sistema tarda, y hacerlo en el arranque retrasaría la
        // primera pantalla sin que nadie lo necesite todavía.
        ttsServiceProvider.overrideWithValue(FlutterTtsService(FlutterTts())),
        sttServiceProvider.overrideWithValue(
          SpeechToTextService(stt.SpeechToText()),
        ),
      ],
      child: const LanguagesApp(),
    ),
  );
}
