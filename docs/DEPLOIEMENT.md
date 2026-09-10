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
3. Chaque poussée sur `main` publie. Chaque branche et chaque pull request reçoit une
   **preview** à sa propre adresse — c'est là qu'on regarde avant de fusionner.

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

## Avant chaque mise en ligne

1. **Changer `VERSION` dans `sw.js`.** Sans ça, les téléphones déjà installés gardent l'ancienne
   version. C'est l'oubli le plus coûteux du projet.
2. Vérifier qu'un fichier ajouté figure bien dans `COQUILLE`, sinon il manquera hors connexion.
3. Essayer une partie complète, puis recharger **réseau coupé** : l'application doit s'ouvrir et
   la partie en cours revenir.
4. Regarder la preview de la branche avant de fusionner.

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
