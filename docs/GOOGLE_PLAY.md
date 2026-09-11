# Publier sur Google Play

L'application est un site web. Pour la mettre sur Play, on l'emballe dans une coque Android
officielle — une **Trusted Web Activity** — qui ouvre `petanque.win` en plein écran, sans barre de
navigateur. Le code publié reste celui de ce dépôt : il n'y a pas de seconde base de code.

## Ce qui bloque le calendrier, et qu'on ne contourne pas

**Douze testeurs, quatorze jours.** Tout compte développeur personnel ouvert après le
13 novembre 2023 doit faire tourner un **test fermé avec au moins 12 testeurs inscrits pendant
14 jours consécutifs** avant de pouvoir demander l'accès à la production. Le compte vient d'être
créé, donc la règle s'applique : **la production ne peut pas ouvrir avant deux semaines**, quelle
que soit la qualité du dossier. Le groupe WhatsApp fournit les douze sans difficulté ; le délai,
lui, ne se négocie pas.

**API 36.** Depuis le 31 août 2026, une nouvelle application doit viser **Android 16 (API 36)**.
C'est un réglage de la coque, pas du site : `bubblewrap` le pose, il faut juste vérifier qu'il ne
retombe pas sur une valeur plus basse.

**Vérification d'identité.** Depuis septembre 2026, les nouveaux comptes personnels doivent la
faire. Sur la fiche publique, Play affiche le **nom légal, le pays et l'adresse électronique** —
pas l'adresse postale, sauf dans certaines régions qui l'exigent.

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
- [ ] Douze testeurs inscrits, et la date de début du test notée quelque part
