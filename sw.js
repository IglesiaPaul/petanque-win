/* Le compteur doit s'ouvrir sur un terrain sans réseau : tout tient dans ce cache.
   Changer VERSION à chaque mise en ligne — l'ancien cache est effacé à l'activation. */
const VERSION = "compteur-2026-09-11-1";
const COQUILLE = [
  ".", "index.html", "manifest.webmanifest", "legal.css",
  "confidentialite.html", "conditions.html", "mentions-legales.html",
  "type/jost-400.woff2", "type/jost-600.woff2", "type/franklin-400.woff2",
  "icons/blason.svg", "icons/icon-192.png", "icons/icon-512.png",
  "icons/icon-maskable-512.png", "icons/apple-touch-icon.png"
];

self.addEventListener("install", e => {
  e.waitUntil(caches.open(VERSION).then(c => c.addAll(COQUILLE)).then(() => self.skipWaiting()));
});

self.addEventListener("activate", e => {
  e.waitUntil(caches.keys()
    .then(ks => Promise.all(ks.filter(k => k !== VERSION).map(k => caches.delete(k))))
    .then(() => self.clients.claim()));
});

/* La page elle-même : le réseau d'abord, le cache si le réseau manque. Sans quoi un
   téléphone garde l'ancienne version tant que le service worker n'a pas repris la main —
   on l'a vérifié à ses dépens. Le reste — polices, icônes — vient du cache d'abord :
   sur le terrain, une ressource qui attend le réseau est une ressource qui manque. */
self.addEventListener("fetch", e => {
  if (e.request.method !== "GET" || new URL(e.request.url).origin !== location.origin) return;

  if (e.request.mode === "navigate") {
    e.respondWith(fetch(e.request)
      .then(r => {
        if (r && r.ok && !r.redirected) caches.open(VERSION).then(c => c.put(e.request, r.clone()));
        return r;
      })
      .catch(() => caches.match(e.request).then(hit => hit || caches.match("index.html"))));
    return;
  }

  e.respondWith(caches.match(e.request).then(hit => {
    const frais = fetch(e.request).then(r => {
      // `redirected` : depuis l'ancienne adresse Netlify, tout part désormais en 301 vers le
      // domaine, et mettre en cache une réponse redirigée lève une exception.
      if (r && r.ok && !r.redirected) caches.open(VERSION).then(c => c.put(e.request, r.clone()));
      return r;
    }).catch(() => hit);
    return hit || frais;
  }));
});
