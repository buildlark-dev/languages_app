'use strict';

// Service worker de la app.
//
// Existe porque el que genera Flutter desde 3.44 ya no guarda nada: es un
// limpiador que se desregistra solo. Sin este archivo la versión web no abre
// sin conexión, y FR-039 y SC-003 piden exactamente eso.
//
// ## Estrategia, y por qué esta
//
// * **Navegación** (abrir la app): primero la red, y si no hay, lo guardado.
//   Así, con conexión, siempre se recibe el `index.html` recién publicado.
// * **Todo lo demás** (el `main.dart.js`, los iconos, el wasm de sqlite, el
//   audio): se sirve lo guardado de inmediato y se revalida por detrás. La app
//   abre rápido y sin red, y la copia nueva queda lista para el siguiente
//   arranque.
// * **`build-id.json`**: nunca se guarda. Es el único archivo que la app usa
//   para saber si hay una versión nueva, así que guardarlo haría imposible
//   detectarla, que es justo el fallo que se vino a arreglar.
//
// Servir lo guardado y revalidar detrás significa que, tras un despliegue, el
// primer arranque todavía ejecuta la versión anterior. Eso **no** se deja así:
// `build-id.json` se pide siempre por red, la app compara y ofrece actualizar.
// La alternativa —esperar la red en cada arranque— cambiaría un aviso por tres
// megabytes de espera cada vez que se abre la app.

const CACHE = 'languages-app';

self.addEventListener('install', () => {
  // No se precarga nada: la primera visita llena la caché con lo que de verdad
  // se usa. Precargar canvaskit entero serían megabytes que la mayoría de
  // navegadores no llega a necesitar.
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  // `claim` hace que esta copia controle las pestañas ya abiertas sin esperar a
  // que se cierren todas. Esperar es lo que deja una PWA instalada congelada:
  // nadie cierra todas las ventanas de una app que vive en la pantalla de
  // inicio.
  event.waitUntil(self.clients.claim());
});

self.addEventListener('message', (event) => {
  if (event.data === 'clearCache') {
    event.waitUntil(caches.delete(CACHE));
    return;
  }
  if (event.data && event.data.type === 'precache') {
    event.waitUntil(precache(event.data.urls || []));
  }
});

/// Guarda lo que la página dice que acabó de usar.
///
/// La lista la manda `index.html` leyendo `performance.getEntriesByType`, y esa
/// vuelta es necesaria: el service worker se activa **después** de que la
/// página pidiera `index.html`, `flutter_bootstrap.js` y `main.dart.js`, así
/// que esas peticiones no pasan por él y la primera visita se quedaba sin lo
/// único imprescindible. Medido: tras la primera carga la caché tenía tres
/// archivos, y ninguno era el programa.
///
/// Que la lista venga de lo realmente pedido, en lugar de estar escrita aquí,
/// evita además adivinar qué motor de dibujo usa esta versión de Flutter: si
/// hizo falta canvaskit, aparecerá en la lista.
async function precache(urls) {
  const cache = await caches.open(CACHE);

  await Promise.all(
    urls.map(async (url) => {
      try {
        // `reload` salta la caché del navegador: se guarda lo publicado, no
        // una copia que ya podía estar vieja.
        const response = await fetch(new Request(url, { cache: 'reload' }));
        if (isStorable(response)) await cache.put(url, response);
      } catch (error) {
        // Un archivo que no se puede guardar no debe impedir guardar los
        // demás. Lo que falte se pedirá por red cuando haya.
      }
    })
  );
}

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);
  // Solo lo propio: las peticiones a Firebase y a los servicios de voz deben
  // pasar intactas, y una respuesta opaca de otro origen no se puede ni
  // inspeccionar ni guardar con sentido.
  if (url.origin !== self.location.origin) return;
  if (url.pathname === '/build-id.json') return;

  if (request.mode === 'navigate') {
    event.respondWith(networkFirst(request));
    return;
  }

  event.respondWith(cacheThenRevalidate(request));
});

/// Primero la red; si falla, lo guardado, y si tampoco, el `index.html`.
async function networkFirst(request) {
  try {
    const response = await fetch(request);
    if (isStorable(response)) {
      const cache = await caches.open(CACHE);
      await cache.put(request, response.clone());
    }
    return response;
  } catch (error) {
    const cache = await caches.open(CACHE);
    const stored = (await cache.match(request)) || (await cache.match('/'));
    if (stored) return stored;
    throw error;
  }
}

/// Lo guardado ya, y la copia nueva para la próxima.
async function cacheThenRevalidate(request) {
  const cache = await caches.open(CACHE);
  const stored = await cache.match(request);

  const fromNetwork = fetch(request)
    .then(async (response) => {
      if (isStorable(response)) await cache.put(request, response.clone());
      return response;
    })
    .catch(() => undefined);

  if (stored) return stored;

  const response = await fromNetwork;
  if (response) return response;
  return new Response('', { status: 504, statusText: 'Sin conexión' });
}

/// Si merece la pena guardarla.
///
/// Guardar un 404 o un error haría que el fallo sobreviviera al arreglo, que es
/// la peor propiedad que puede tener una caché.
function isStorable(response) {
  return response && response.ok && response.type === 'basic';
}
