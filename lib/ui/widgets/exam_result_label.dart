/// Cómo se dice que un examen está aprobado, con la nota que se sacó.
///
/// Existe porque las dos tarjetas de examen —la del módulo y la del nivel—
/// decían «Aprobado» y nada más. Reportado al verificar SC-002: tras reiniciar
/// el dispositivo se veían las lecciones aprobadas, pero del examen solo se
/// ofrecía volver a presentarlo, **sin el resultado obtenido**.
///
/// El dato estaba guardado todo el tiempo: `ActivityScore.bestScore` sobrevive
/// al reinicio y hay una prueba que lo fija. Lo que faltaba era enseñarlo. Y
/// enseñarlo no es un adorno: sin la nota, «aprobado» y «aprobado raspando» se
/// ven igual, y la persona no sabe si le conviene repetir.
///
/// Función suelta y compartida para que las dos tarjetas digan lo mismo de la
/// misma forma; dos copias habrían divergido a la primera corrección.
library;

import '../../core/activity_score.dart';

/// «Aprobado con un 85 %.», o solo «Aprobado.» si no hay nota guardada.
///
/// Que [score] pueda ser nulo no es defensivo por costumbre: un progreso traído
/// de otro dispositivo puede tener la actividad marcada sin su puntaje si
/// alguna vez cambia el esquema, y quedarse sin tarjeta por eso sería peor que
/// quedarse sin el número.
String passedExamLabel(ActivityScore? score) {
  if (score == null) return 'Aprobado.';
  return 'Aprobado con un ${percentageOf(score)} %.';
}

/// La nota del mejor intento, redondeada a entero.
///
/// Se redondea igual que en la pantalla de resultados, para que el número que
/// se ve al terminar el examen sea el mismo que se ve después en la tarjeta.
/// Dos redondeos distintos del mismo dato parecen un error de la app.
int percentageOf(ActivityScore score) => (score.bestScore * 100).round();
