# Comment c'est fait

Un fichier HTML, un manifeste, un service worker, deux polices, cinq images. Pas de cadre, pas
d'étape de construction, pas de dépendance à installer. Ce n'est pas de l'ascétisme : une
association sans équipe technique doit pouvoir ouvrir le fichier dans cinq ans et comprendre.

## Les écrans

Une seule page, des sections `.vue` dont une seule porte la classe `on`. `montrer(id)` bascule.
Aucune bibliothèque de routage, aucune URL à gérer.

| Vue | Rôle |
|---|---|
| `#accueil` | commencer, reprendre, le format, les joueurs, les parties du jour, le menu |
| `#partie` | les deux camps, le score, la dernière mène, *Corriger* |
| `#combien` | de un à six selon le format, chaque bouton portant son résultat |
| `#fin` | le verdict, la feuille de mènes avec les boules |
| `#qui` | composer un camp depuis la liste des prénoms connus |
| `#menu`, `#installer`, `#apropos` | le menu à trois traits et ses pages |

**Le menu à trois traits n'existe que sur l'accueil.** Sur l'écran de jeu il n'y a ni menu, ni
onglets, ni réglages : on y est debout, à une main, souvent avec un verre dans l'autre.

## Les données

Tout passe par deux fonctions, `lire()` et `ecrire()`, qui enveloppent `localStorage` sous une
seule clé. **C'est la seule couture avec le stockage** — et donc le seul endroit à toucher le
jour où une base distante s'ajoute.

```js
{
  courante:  partie | null,     // la partie en cours, reprise au rechargement
  parties:   [partie],          // les quarante dernières, filtrées sur le jour
  roster:    [{ id, nom }],     // les prénoms connus de ce téléphone
  equipes:   { nous: [joueur], eux: [joueur] },
  formatIdx: 0 | 1 | 2
}
```

Une **partie** : `{ debut, jour, max, fini, equipes, menes }`. Elle enregistre une **copie** de
ses deux camps — effacer un prénom de la liste ne réécrit jamais une feuille déjà jouée.

Une **mène** : `{ no, camp, boules, pts, nulle? }`. `boules` est ce qui a été placé, `pts` ce qui
a compté : au-delà de 13, les boules en trop restent inscrites mais ne rapportent rien. Une mène
corrigée n'est pas effacée, elle est marquée `nulle` et reste sur la feuille, barrée.

Un **joueur** est `{ id, nom }` et non un prénom seul. L'identité stable est ce qui permettra
d'attribuer les points d'une mène à un joueur (`mene.par = [id]`) et de lui attacher ses boules
(`{ genre, diametre, poids, modele }` — le genre distingue la boule agréée FIPJP de la boule de
loisir et de la boule d'enfant, qui ne tiennent pas dans les bornes du règlement et n'ont pas à
y tenir).

## Le hors-connexion

`sw.js` met en cache la coquille entière à l'installation, puis sépare deux cas :

- **la page elle-même — le réseau d'abord**, le cache si le réseau manque. Sans quoi un téléphone
  garde l'ancienne version tant que le service worker n'a pas repris la main, et une correction
  poussée le matin n'arrive pas sur le terrain l'après-midi ;
- **le reste — polices, icônes — le cache d'abord.** Sur un terrain sans réseau, une ressource qui
  attend le réseau est une ressource qui manque.

> **À chaque mise en ligne, changer `VERSION` dans `sw.js`.** Sans quoi les téléphones déjà
> installés gardent l'ancienne version indéfiniment. C'est l'erreur la plus facile à commettre
> et la plus difficile à voir.

Tout fichier ajouté à la coquille doit être ajouté à `COQUILLE`, sinon il manquera hors connexion.
`addAll` est atomique : une seule entrée qui répond 404 et aucun téléphone ne change de version,
sans un mot. `tools/verif_publication.py` relit la liste avant chaque recopie.

## Les langues

Une seule application, une seule adresse, un dictionnaire par langue. Le français est la source ;
l'anglais et le thaï en sont des traductions, jamais l'inverse.

- **Le dictionnaire** (`app/i18n/<langue>.json`, 140 clés) est embarqué dans `index.html` entre
  `/*i18n:debut*/` et `/*i18n:fin*/` par `tools/build_i18n.py`, qui n'embarque que les langues
  ouvertes. Le balisage français porte le même texte que `fr.json`, marqué `data-i18n`, et le
  build refuse toute divergence : en français la passe de traduction ne s'exécute pas, et ce que
  le joueur voit est prouvé égal au dictionnaire. Les pluriels sont des phrases entières choisies
  par `Intl.PluralRules` ; les phrases dont le sujet est une équipe sont des gabarits (« Points
  to Us »), pour ne rien conjuguer.
- **La barrière** : `var LANGUES` dans le script de tête, écrite par le build d'après le
  `statut` de chaque dictionnaire. Tant qu'une langue n'y est pas, ni un `?langue=xx`, ni un
  téléphone réglé dans cette langue ne l'obtiennent. Ordre de détection : le choix enregistré,
  puis `?langue=xx` (un QR scanné est un acte délibéré : enregistré, puis retiré de l'adresse
  sans toucher au `#`), puis la langue du téléphone (jamais enregistrée), puis le français.
- **Les pages de contenu** — le tutoriel et les trois pages légales — sont des fragments
  (`app/pages/<langue>/`) habillés d'un gabarit par `tools/build_pages.py` : canonical,
  `hreflang`, `og:locale`, la rangée des langues, la date dans la langue, et sur une page
  juridique traduite l'encadré *traduction de courtoisie ; seule la version française fait foi*.
  La page de confidentialité traduite doit dire ce que la fiche Sécurité des données a déclaré :
  le build le vérifie mot à mot. `/en/` et `/th/` sont des pages d'entrée générées, avec leur
  carte de partage dans la langue, qui renvoient vers `/?langue=xx` — imprimables sur un QR.
- **Le thaï** est composé en Noto Sans Thai 400 et 600, découpée au bloc thaï seul (sans
  chiffres : les scores restent en Jost), chargée après chaque police latine et sous
  `unicode-range`. Sous `:lang(th)` : pas d'interlettrage, pas de capitales, l'interligne plus
  haut pour les marques de ton. `verif_langue.mjs --langue th` audite chaque élément.
- **Ce qui ne bouge pas** : le manifeste (un seul nom, « Le compteur », dans toutes les
  langues), la clé de stockage, la charge du compteur anonyme, le format des dates stockées.

## Ce qu'un lien montre

Collé dans un groupe WhatsApp ou sur un réseau, `petanque.win` affiche une vignette plutôt qu'une
adresse nue : le blason, *Le compteur*, une phrase, l'adresse. Les balises Open Graph sont dans
l'en-tête de `index.html` et l'image est `og.png`, 1200 × 630 — le format qu'attendent les aperçus
larges.

Deux points qui font échouer ces vignettes quand on les oublie : **l'adresse de l'image doit être
absolue** (les robots d'aperçu ne résolvent pas le relatif), et **elle doit rester légère**, sinon
l'aperçu retombe sur une petite vignette carrée. `tools/build_og.py`, dans le dépôt de travail,
régénère la carte.

L'image ne fait pas partie de la coquille hors-connexion : elle ne sert qu'aux robots, et il n'y a
aucune raison de la télécharger sur le téléphone de quelqu'un qui joue.

## Les planchers de conception

Ils viennent de la note de concept et ne se négocient pas à la légère.

| | |
|---|---|
| Cibles de comptage | jamais sous **96 px** — camps 470, boutons de boules 146 |
| Commandes de service | *Corriger*, *Accueil* : 60 px ; *Terminer* : 48 px (niveau AAA de la WCAG) |
| Contraste | marine sur crème, **11,4 : 1** — la norme AAA en demande 7 |
| Écran de jeu | toujours clair : un écran sombre au soleil de trois heures ne se lit pas |
| Gestes | que des appuis — aucun glissement, aucun appui long, aucun double appui |
| Délais | aucun : rien ne disparaît seul, rien ne se valide au bout de trois secondes |
| Veille | l'écran reste allumé pendant une partie (`navigator.wakeLock`) |
| Hauteur | `100svh` et non `100dvh` — voir ci-dessous |

### Pourquoi `svh` et pas `dvh`

`dvh` vaut la hauteur de fenêtre **sans** les barres du navigateur. Dans Safari ou Chrome sur
iPhone, le bas d'une vue passait donc sous la barre d'outils, et comme aucune vue ne défilait, le
bouton d'action devenait **inatteignable**. `svh` est la hauteur quand les barres sont présentes —
la plus petite, donc la seule sûre. En application installée il n'y a pas de barres et les deux
valeurs coïncident.

Deux filets en plus : chaque vue peut défiler en dernier recours (mieux vaut une vue qui glisse
qu'un bouton qu'on ne peut pas toucher), et les rangées de bas d'écran sont en `flex:0 0 auto`,
donc jamais comprimées. Mesuré de 844 à 420 px de haut : le bouton d'action est atteignable
partout, et l'accueil ne défile à aucune de ces hauteurs.

## Ce qui ne doit jamais régresser

Compter sans compte. Fonctionner sans réseau. Ne rien envoyer nulle part sans que l'utilisateur
l'ait demandé. Aucune publicité, aucune mesure d'audience.

Le jour où une base arrive, ces quatre points restent vrais **de l'étage 0** : le compte ouvre
l'historique partagé et les classements, il ne devient pas la condition pour compter.
