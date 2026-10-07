/// Umbrales de dominio y calendario de repaso, en un solo lugar.
///
/// Están centralizados porque son reglas de producto, no detalles de
/// implementación: aparecen en la constitución (Principio III) y en los
/// criterios de éxito de la especificación. Si alguna vez cambian, deben
/// cambiar una sola vez.
///
/// Los valores provienen de la ruta de inglés ya validada en
/// `Study/ruta-de-ingles.html`, donde se usaron como `LESSON_PASS = 70` y
/// `PASS = 80`.
library;

/// Proporción mínima de aciertos para aprobar una lección: 70 %.
const double lessonPassThreshold = 0.70;

/// Proporción mínima de aciertos para aprobar un examen de módulo o de nivel:
/// 80 %.
///
/// Es más alto que el de lección a propósito: una lección es práctica y admite
/// tropiezos, un examen decide si se domina el módulo o el nivel.
const double examPassThreshold = 0.80;

/// Intervalos de repetición espaciada, en días.
///
/// Una palabra recordada avanza en esta lista y vuelve a aparecer cuando pasan
/// `srsIntervals[step]` días. Una palabra fallada regresa al primer intervalo.
const List<int> srsIntervals = <int>[1, 3, 7, 16, 35, 90];

/// Último índice válido de [srsIntervals].
///
/// Derivado en lugar de escrito a mano para que añadir un intervalo no exija
/// recordar actualizar un número en otro sitio. Es un getter y no una constante
/// porque `.length` no se evalúa en tiempo de compilación.
int get maxSrsStep => srsIntervals.length - 1;

/// Identificadores de nivel del Marco Común Europeo de Referencia, en orden
/// ascendente de dominio.
const List<String> cefrLevelIds = <String>['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
