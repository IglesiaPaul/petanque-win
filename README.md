# Le compteur — petanque.win

L'application de score des **Pétanquistes**. Une partie de pétanque se joue en 13 points ; la
gêne la plus fréquente d'une partie n'a rien à voir avec le jeu, c'est que personne ne sait
le score. À la troisième mène quelqu'un demande où on en est, deux joueurs répondent des
chiffres différents, et la partie s'arrête le temps de recompter.

**[petanque.win](https://petanque.win)** — s'ouvre dans un navigateur, s'installe sur l'écran
d'accueil, fonctionne sans réseau.

## Trois promesses, qui sont des contraintes de conception

- **Sans compte.** Ni adresse, ni mot de passe, ni confirmation. On appuie sur *Commencer une
  partie* et on compte. Un joueur de soixante-dix ans à qui l'on demande d'inventer un mot de
  passe debout sur du gravier ne revient pas.
- **Sans réseau.** Une fois ouvert, tout fonctionne hors connexion. Parties, prénoms et chiffres
  restent sur le téléphone.
- **Sans publicité,** et rien qui identifie l'utilisateur ni qui le suive d'une fois sur l'autre.
- **Une seule chose est envoyée**, à la fin d'une partie : qu'une partie a été finie, et dans
  quel format. Ni score, ni prénom, ni identifiant d'appareil — un compteur agrégé, pour savoir
  si l'outil sert avant d'y ajouter quoi que ce soit. Il se coupe depuis la page *Les chiffres*.

## Deux gestes par mène

Une équipe joue six boules — trois en tête-à-tête. Une mène rapporte donc **de 1 à 6 points et
jamais autre chose** : on touche l'équipe qui a marqué, puis le nombre de boules. C'est la règle
du jeu qui dessine le clavier, pas l'inverse, et un score impossible ne peut pas entrer.

Chaque bouton écrit d'avance où il mène — *« Nous à 11 »*, *« Nous gagne 13 »* — pour que
l'annonce se lise par-dessus l'épaule avant d'être validée.

## Faire tourner en local

Aucune dépendance, aucune étape de construction. Un serveur statique suffit :

```bash
python3 -m http.server 8765     # puis http://localhost:8765
```

Le service worker s'enregistre en `https:` et sur `localhost` — donc le hors-connexion se teste
en local.

## Ce dépôt

Le site publié, et rien d'autre.

| | |
|---|---|
| `index.html` | l'application entière — écrans, styles et logique |
| `manifest.webmanifest`, `sw.js` | l'installation sur l'écran d'accueil, et le hors-connexion |
| `icons/`, `type/` | le blason et les polices, découpées aux signes utilisés |
| `netlify.toml` | publication, en-têtes de cache et politique de sécurité |
| `docs/` | l'architecture, et la marche à suivre pour déployer |

Le raisonnement complet, les décisions et ce qui est volontairement absent vivent dans le dépôt
de travail, privé, avec le reste du projet d'association.

## La suite

L'ordre importe plus que la liste : **chaque étage ne s'ouvre que si le précédent sert déjà.**

| Étage | Ce qu'on a | Ce qu'il faut |
|---|---|---|
| **0 · sans compte** | compter, corriger, revoir les parties du jour, nommer les joueurs ; tout reste sur le téléphone | rien — c'est ce qui est en ligne |
| **1 · avec un compte** | historique d'un téléphone à l'autre, classements entre amis ou dans un club | une base — Supabase |
| **2 · plus tard** | calendrier régional des concours, résultats de club | — |

## Licence

Code sous [licence MIT](LICENSE). Le nom **Pétanquistes** et le blason n'en font pas partie.
