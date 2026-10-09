// Arranque de Flutter para web, escrito a mano a propósito.
//
// El archivo que genera Flutter por defecto registra su propio service worker
// desde aquí, y eso ya no sirve de nada: desde Flutter 3.44 el
// `flutter_service_worker.js` que se genera **no guarda nada**, son treinta
// líneas cuyo único trabajo es desregistrarse a sí mismo para limpiar las
// instalaciones viejas. Medido en el sitio desplegado:
// `navigator.serviceWorker.getRegistrations()` devolvía lista vacía.
//
// Es decir: la web no tenía nada guardado para abrirse sin conexión —lo que
// FR-039 y SC-003 exigen en una plataforma que el plan declara primaria— y
// tampoco tenía forma de enterarse de una versión nueva.
//
// Al llamar a `load()` sin `serviceWorkerSettings`, Flutter no registra nada, y
// `web/index.html` registra el nuestro, que sí guarda. Las dos llaves no pueden
// convivir: hay un único registro por ámbito, así que si el de Flutter se
// registrara después, su activación desregistraría el nuestro.
{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load();
