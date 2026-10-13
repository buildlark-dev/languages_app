/// Identidad de la versión de la app.
///
/// Se declara aquí y no se lee de `pubspec.yaml` en tiempo de ejecución porque
/// eso exigiría una dependencia más solo para una cadena. El riesgo evidente de
/// una constante copiada a mano —que se quede desfasada— lo cubre una prueba que
/// compara este valor con el de `pubspec.yaml` y falla si divergen.
library;

/// Versión de la app, sin el número de compilación.
///
/// Viaja en el archivo de respaldo para que, si algún día un respaldo no se
/// puede leer, se sepa qué versión lo escribió.
const String appVersion = '1.0.0';
