/// Tema claro y oscuro de la app.
///
/// El Principio VII pide contraste WCEG AA, objetivos táctiles de 48 dp y
/// respetar el tamaño de fuente del sistema. Las dos primeras cosas se fijan
/// aquí, de una vez, para que ninguna pantalla tenga que acordarse.
///
/// La tercera no se toca a propósito: no se fuerza ningún `textScaleFactor`, de
/// modo que la escala del sistema se aplica tal cual. Eso es lo que SC-010
/// verifica con la fuente al 130 %.
library;

import 'package:flutter/material.dart';

/// Color base de la identidad. De él derivan ambos esquemas.
const Color _seedColor = Color(0xFF2E6F6B);

/// Lado mínimo de cualquier objeto táctil, en dp.
const double minTouchTarget = 48;

ThemeData _buildTheme(Brightness brightness) {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: brightness,
    // Contraste elevado para cumplir WCAG AA sin tener que revisar pantalla por
    // pantalla.
    contrastLevel: 0.3,
  );

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    visualDensity: VisualDensity.standard,

    // Un solo sitio donde se garantiza el área táctil mínima.
    materialTapTargetSize: MaterialTapTargetSize.padded,

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(minTouchTarget),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(minTouchTarget),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(minTouchTarget, minTouchTarget),
      ),
    ),

    // Los textos de contenido se leen en párrafos largos: la altura de línea
    // holgada es lo que hace legible una explicación gramatical a 360 dp.
    textTheme: const TextTheme(
      bodyLarge: TextStyle(height: 1.5),
      bodyMedium: TextStyle(height: 1.5),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),

    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      // Un campo de respuesta necesita espacio para dedos, no solo para texto.
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}

ThemeData get lightTheme => _buildTheme(Brightness.light);

ThemeData get darkTheme => _buildTheme(Brightness.dark);
