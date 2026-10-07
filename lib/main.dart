/// Raíz de composición.
///
/// Es el **único** archivo autorizado a importar contenido concreto
/// (`content/catalog.dart`), según el Principio II de la constitución v1.1.0. Su
/// trabajo es exactamente ese: unir las piezas que las demás capas solo conocen
/// como contratos.
///
/// Por eso aquí está también la elección de la base de datos de reserva: el
/// opener no importa nada específico de plataforma, así que quien decide qué
/// usar cuando el almacenamiento falla es este archivo.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/native.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'content/catalog.dart';
import 'firebase_options.dart';
import 'services/db/app_database.dart';
import 'services/db/database_opener.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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

  // El almacén local es la fuente de verdad del progreso. Si falla, la app
  // sigue siendo usable sobre una base volátil y lo dice (FR-043).
  final DatabaseOpenResult store = await openAppDatabase(
    openPrimary: AppDatabase.new,
    openFallback: () => AppDatabase.withExecutor(NativeDatabase.memory()),
  );

  runApp(
    LanguagesApp(
      catalog: const AppCourseCatalog(),
      storageDegraded: store.degraded,
    ),
  );
}
