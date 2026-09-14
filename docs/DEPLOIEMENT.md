# Mettre en ligne

Hébergé sur **Netlify**, publié depuis ce dépôt à chaque poussée sur `main`. Pas de GitHub
Pages : la suite demande une base de données et des fonctions côté serveur, que Pages ne sait
pas servir.

## Brancher Netlify sur le dépôt

Une seule fois.

1. Netlify → le projet → **Build & deploy** → **Link repository** → GitHub → `petanque-win`,
   branche `main`.
2. Rien à renseigner : `netlify.toml` déclare `publish = "."` et aucune commande de
   construction.
3. Chaque poussée sur `main` publie. La branche `staging` se publie à sa propre adresse
   (*Branch deploys → Let me add individual branches → staging*), et chaque pull request reçoit
   une preview à la sienne.

## Le domaine petanque.win

Le domaine est chez **Cloudflare** ; on garde ses serveurs de noms et on pointe simplement
vers Netlify. Dans Netlify, ajouter le domaine (*Domain management*) : l'interface affiche les
enregistrements exacts. Ils ressemblent à ceci, à confirmer sur place.

| Type | Nom | Valeur |
|---|---|---|
| CNAME | `@` | `apex-loadbalancer.netlify.com` — Cloudflare aplatit le CNAME sur l'apex |
| CNAME | `www` | `<le-projet>.netlify.app` |

Deux pièges, dans l'ordre où on les rencontre :

- **Supprimer d'abord** les enregistrements que Cloudflare a posés tout seuls à l'achat du
  domaine. Ils entrent en conflit et l'erreur est muette.
- **Nuage gris, « DNS only »**, le temps que Netlify émette son certificat. Proxy activé, la
  validation échoue. On peut rallumer le proxy une fois le certificat en place.

À défaut de CNAME sur l'apex, un enregistrement A vers `75.2.60.5`
([documentation Netlify](https://docs.netlify.com/manage/domains/configure-domains/configure-external-dns/)).

## Une seule origine

`netlify.toml` renvoie `petanque-win.netlify.app` vers `petanque.win` en 301. Ce n'est pas de la
cosmétique : pour un navigateur, une application installée depuis l'une et une installée depuis
l'autre sont **deux applications**, avec deux caches et deux historiques de parties qui ne se
voient pas. Une seule adresse circule, donc.

La règle ne vise que le sous-domaine de production : les previews de branche, en
`<branche>--petanque-win.netlify.app`, répondent toujours chez elles.

## Le chemin d'une modification

Depuis le 14 septembre 2026, `main` ne reçoit plus de poussée directe : il est protégé sur
GitHub, et l'application est dans le Play Store. Une modification suit ce chemin, sans raccourci :

1. Elle se fait dans le dépôt de travail, sur une branche (`i18n` pour les langues).
2. `tools/publier_site.py ../petanque-win-staging` la recopie dans un second clone de ce
   dépôt tenu sur la branche `staging` (`git worktree add ../petanque-win-staging staging`),
   qui se publie à `https://staging--petanque-win.netlify.app`. Le premier clone reste sur
   `main` : c'est la référence que l'oracle (`tools/verif_i18n.mjs`) compare au candidat. C'est là qu'on l'essaie, sur un
   téléphone, réseau coupé compris. Une préversion est une autre origine : l'application
   installée depuis `staging` est une application distincte, avec ses propres parties — c'est
   voulu — et le compteur anonyme n'y compte pas (`compter()` ne parle qu'à `petanque.win`).
3. Une pull request `staging → main`, relue, fusionnée : c'est la mise en ligne. L'application
   du Play Store lit `petanque.win` en direct et suit sans être reconstruite.

**Gel jusqu'au 27 septembre 2026.** Le tournoi du 26 tourne sur le commit marqué par la
branche `avant-i18n`. Un correctif d'ici là est un *cherry-pick* de `avant-i18n` vers `main`,
dans une petite pull request, avec son propre `VERSION` — jamais une fusion de la branche des
langues, même derrière sa barrière. La branche se rebase ensuite sur le correctif.

## Construire, dans l'ordre

Depuis les langues (septembre 2026), `index.html` et les pages de contenu sont en partie
générés. Les commandes, dans le dépôt de travail, dans cet ordre :

```bash
python3 tools/build_app_fonts.py            # une fois, quand une police change : les sous-ensembles woff2
python3 tools/build_i18n.py                 # les dictionnaires app/i18n/*.json → le bloc I18N et la barrière de index.html
python3 tools/build_pages.py                # les fragments app/pages/<langue>/ → les pages, les entrées /en/ et /th/, sitemap.xml
node tools/verif_i18n.mjs                   # l'oracle : le français, pas à pas, contre ../petanque-win (la production)
node tools/verif_langue.mjs --langue en     # chaque langue ouverte : pas une fuite de français, rien qui déborde
node tools/verif_langue.mjs --matrice       # la détection de la langue, dix cas
node tools/verif_horsligne.mjs              # le hors-connexion joué dans un Chromium, et la mise à jour N+1
python3 tools/publier_site.py ../petanque-win-staging   # relit tout (tools/verif_publication.py), puis recopie
```

Trois règles que ces outils font respecter :

- **Un texte est une entrée de dictionnaire, jamais une retouche de `index.html`.** Le balisage
  français porte le même texte que `fr.json`, et `build_i18n.py` refuse de construire si les deux
  divergent. Changer une phrase, c'est changer le JSON, puis reconstruire.
- **La barrière n'est pas tapée à la main.** `var LANGUES` dans `index.html` est écrite par
  `build_i18n.py` d'après le `statut` de chaque dictionnaire : `publie` ouvre la langue,
  `brouillon` la ferme. Ouvrir une langue, c'est un mot dans `th.json`, un `VERSION`, et les
  suites qui repassent. `--ouvrir th` ouvre un brouillon **pour la prévisualisation seulement** :
  `publier_site.py` refuse de recopier une barrière qui porte un brouillon, sauf avec
  `--previsualisation`, qui n'a de sens que vers `staging`.
- **Le hors-connexion se prouve, il ne se suppose pas.** `verif_horsligne.mjs` installe le
  service worker, coupe le réseau, ouvre chaque adresse qu'un joueur peut avoir sous le pouce
  (`/`, `/#commencer`, `/?langue=th`, les pages, les entrées `/en/` et `/th/`), puis simule une
  mise en ligne N+1 : un rechargement en ligne suffit, l'ancien cache disparaît, en trois
  secondes sur un Chromium.

## Avant chaque mise en ligne

1. **Changer `VERSION` dans `sw.js`.** Sans ça, les téléphones déjà installés gardent l'ancienne
   version. C'est l'oubli le plus coûteux du projet — `verif_publication.py` refuse désormais une
   `VERSION` déjà en ligne, sur la cible comme en production.
2. Vérifier qu'un fichier ajouté figure bien dans `COQUILLE`, sinon il manquera hors connexion.
   Le plafond est de 400 ko ; la coquille en pèse 396 avec les pages thaïes et les deux entrées.
3. Essayer une partie complète, puis recharger **réseau coupé** : l'application doit s'ouvrir et
   la partie en cours revenir. `verif_horsligne.mjs` le fait, un téléphone le confirme.
4. Regarder `staging` sur un téléphone avant d'ouvrir la pull request.
5. **Reconstruire sans `--ouvrir` et republier `staging` avant d'ouvrir la pull request** : la
   prévisualisation d'un brouillon (le thaï, tant qu'un relecteur ne l'a pas signé) vit sur
   `staging` entre deux mises en ligne ; la pull request `staging → main` doit montrer exactement
   ce qui part, et rien d'autre.

## Quand la base arrivera

**Supabase** pour l'étage 1 — comptes, historique d'un téléphone à l'autre, classements.
**Resend** pour les campagnes.

Trois règles à tenir au moment de les brancher :

- **Les clés ne sont jamais dans le dépôt.** Variables d'environnement Netlify, et `.env` est
  déjà ignoré par git. Une clé de service Resend ou une clé `service_role` Supabase ne touche
  jamais le navigateur : elles ne vivent que dans une fonction Netlify.
- **Ouvrir `connect-src` dans `netlify.toml`,** et lui seul : la politique de sécurité y bloque
  aujourd'hui toute sortie vers un tiers, ce qui est exactement ce qu'on veut garder par défaut.
- **L'étage 0 reste entier.** Le compte ouvre le partage ; il ne devient jamais la condition
  pour compter une partie.

Côté données personnelles : des prénoms associés à des performances sont des données personnelles
au sens du RGPD. Rester interne au club, laisser choisir un prénom ou un pseudonyme, et ne
publier aucun classement public sans accord explicite.
