# Publier sur Google Play

L'application est un site web. Pour la mettre sur Play, on l'emballe dans une coque Android
officielle — une **Trusted Web Activity** — qui ouvre `petanque.win` en plein écran, sans barre de
navigateur. Le code publié reste celui de ce dépôt : il n'y a pas de seconde base de code.

## Ce qui bloque le calendrier, et qu'on ne contourne pas

**Les douze testeurs ne s'appliquent PAS.** La règle du test fermé — 12 testeurs inscrits
pendant 14 jours consécutifs — ne vise que les comptes **personnels** ouverts après le
13 novembre 2023. Le compte est un **compte professionnel** au nom de HEMPIN, donc exempt : la
production peut s'ouvrir directement, sans délai imposé. Un test fermé reste une bonne idée pour
attraper les défauts sur de vrais téléphones, mais c'est un choix, pas une obligation.

**API 36.** Depuis le 31 août 2026, une nouvelle application doit viser **Android 16 (API 36)**.
C'est un réglage de la coque, pas du site : `bubblewrap` le pose, il faut juste vérifier qu'il ne
retombe pas sur une valeur plus basse.

**Ce que Play affiche publiquement.** Pour un compte professionnel : **nom légal, adresse
légale, adresse électronique et numéro de téléphone**. C'est plus qu'un compte personnel, et ce
n'est pas négociable. Ici cela ne révèle rien de neuf — le siège social d'une SASU figure déjà au
registre du commerce et se trouve en une recherche.

**Le nom affiché sera HEMPIN**, sur une application de pétanque. Ce n'est pas un problème de
politique, mais c'est une surprise pour qui lit la fiche : une ligne de la description doit
expliquer le lien, plutôt que de le laisser deviner.

## Fabriquer la coque

```bash
npm i -g @bubblewrap/cli
bubblewrap init --manifest https://petanque.win/manifest.webmanifest
# nom du paquet : win.petanque.compteur
# viser API 36
bubblewrap build        # produit app-release-bundle.aab et la clé de signature
```

`bubblewrap` crée une **clé de signature**. Elle ne se remplace pas : perdue, on ne peut plus
mettre à jour l'application. À sauvegarder ailleurs que sur l'ordinateur qui l'a créée, et
**jamais dans ce dépôt**.

Puis il faut prouver que le domaine et l'application vont ensemble, sinon la coque affiche une
barre d'adresse. Récupérer l'empreinte :

```bash
keytool -list -v -keystore android.keystore -alias android | grep SHA256
```

et publier `/.well-known/assetlinks.json` à la racine du site :

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "win.petanque.compteur",
    "sha256_cert_fingerprints": ["L'EMPREINTE ICI"]
  }
}]
```

⚠️ Play **resigne** l'application avec sa propre clé. L'empreinte à mettre est celle affichée dans
Play Console → *Configuration* → *Intégrité de l'application* → *Certificat de signature d'application*,
**pas** celle de la clé locale. C'est l'erreur la plus fréquente, et elle se voit tout de suite :
la barre d'adresse reste affichée.

## Le formulaire « Sécurité des données »

Il doit correspondre exactement à la page Confidentialité, sinon c'est un motif de suspension.

| Question | Réponse | Pourquoi |
|---|---|---|
| L'application collecte-t-elle des données ? | **Oui** | Le compteur de parties quitte l'appareil |
| Chiffrées en transit ? | **Oui** | HTTPS partout |
| Suppression sur demande ? | **Non applicable** — expliquer : les compteurs ne contiennent aucun identifiant, il n'y a rien à retrouver ni à supprimer | Honnête et vérifiable |

**Type 1 — Activité dans l'application → Interactions**
Collectée · non partagée · **non associée à l'identité** · **facultative** (interrupteur dans
*Les chiffres*) · finalité : *Analyse*. C'est l'événement « une partie a été finie, en doublette ».

**Type 2 — Informations personnelles → Adresse e-mail**
Collectée · non partagée · associée à l'identité · **obligatoire pour cette fonction seulement** ·
finalité : *Gestion du compte*. Cela ne concerne **que la page d'administration** de l'éditeur ;
aucun compte n'est proposé aux joueurs et l'inscription est désactivée. Le déclarer quand même :
sous-déclarer est ce qui fait suspendre une application.

> À envisager plus tard : sortir la page d'administration du périmètre de l'application Play.
> La déclaration tomberait alors au seul type 1.

**Ne rien déclarer d'autre.** Pas de localisation, pas de contacts, pas de fichiers, pas
d'identifiants publicitaires — l'application ne demande aucune permission Android.

## La fiche

| Champ | Contenu |
|---|---|
| Nom | Le compteur — Pétanquistes |
| Description courte | Le score de votre partie de pétanque, en deux gestes par mène. |
| Catégorie | Sports |
| Politique de confidentialité | `https://petanque.win/confidentialite.html` |
| Développeur affiché | HEMPIN — nom, adresse, courriel et téléphone publics |
| Icône | 512 × 512 — `icons/icon-512.png` |
| Captures | au moins 2, téléphone : l'accueil, l'écran de partie, la feuille de fin |
| Bandeau | 1024 × 500 — à faire |

**Classification du contenu** : questionnaire IARC, aucun contenu sensible, aucune publicité,
aucun achat. Attendu : 3+ / PEGI 3.

**Public cible.** Question à trancher honnêtement plutôt que stratégiquement. Le club accueille
des enfants ; si des tranches d'âge enfants sont cochées, la **politique Familles** s'applique.
L'application la respecte déjà — aucune publicité, aucune permission, aucune donnée personnelle
collectée d'un enfant — donc répondre vrai ne coûte rien et éviter la question coûterait la
crédibilité du dossier.

## Ce qui doit être vrai avant d'envoyer

- [ ] `contact@petanque.win` existe et reçoit le courrier (Cloudflare Email Routing, gratuit)
- [ ] Les trois pages légales sont en ligne et atteignables sans compte
- [ ] `assetlinks.json` porte l'empreinte **de Play**, pas celle de la clé locale
- [ ] La coque vise API 36
- [ ] Le formulaire Sécurité des données dit la même chose que la page Confidentialité
- [ ] La clé de signature est sauvegardée hors de l'ordinateur et hors du dépôt
- [ ] La description de la fiche explique en une ligne le lien entre HEMPIN et Pétanquistes

## Le chanvre et la politique Play

HEMPIN est une société du chanvre, et la boutique de vêtements viendra. La politique de Play
interdit les applications qui **facilitent la vente de marijuana ou de produits contenant du
THC**, et cite nommément le panier d'achat intégré comme exemple de violation.

- **Textile et vêtement en chanvre** : autorisé. Ce n'est pas un produit de marijuana, et une
  boutique de vêtements dans l'application ne pose aucun problème.
- **Huiles CBD, comestibles, tout ce qui contient du THC** : interdit, quelle que soit la légalité
  locale. Cela devrait rester sur le web, hors de l'application Android.

La distinction porte sur ce que l'application fait, pas sur le nom de l'éditeur : publier un
compteur de pétanque sous le nom HEMPIN ne pose aucune question.
