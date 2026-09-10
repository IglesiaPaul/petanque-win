# La base

Le projet Supabase **petanque-win** (`wcivitpxrzggasxauckp`, région eu-west-3, Paris) porte
l'étage 1 du compteur : joueurs durables, parties partagées, classements. L'étage 0 — compter
une partie — n'en dépend jamais et continue de fonctionner sans réseau et sans compte.

## Les migrations

`supabase/migrations/` contient les fichiers SQL, nommés `AAAAMMJJHHMMSS_ce_que_ca_fait.sql`.
L'intégration GitHub les applique dans l'ordre à chaque poussée sur `main` : seules celles qui
n'ont pas encore tourné sont exécutées.

**Il n'y a pas d'environnement de préversion sur le palier gratuit** — les branches de
préversion demandent Pro. Une migration fusionnée dans `main` part donc **directement en
production**, sans filet. D'où trois règles :

1. **Additif d'abord.** Ajouter une colonne, une table, une politique. Ne jamais supprimer ni
   renommer dans la même migration que le code qui en dépend : on ajoute, on déploie, on migre
   les données, on retire — dans des migrations séparées.
2. **Rejouable sans dégât.** `create table if not exists`, `drop policy if exists` avant
   `create policy`. Une migration qui échoue à mi-chemin doit pouvoir être relancée.
3. **Lue avant d'être fusionnée.** C'est le seul contrôle qui reste quand il n'y a pas de
   préversion.

## Ce qui n'est pas ici

Aucune clé. La clé publiable part dans le code du navigateur — c'est son rôle, et les politiques
RLS sont ce qui protège les données, pas le secret de cette clé. La clé `service_role` ne touche
jamais le navigateur ni ce dépôt : elle ne vit que dans les variables d'environnement Netlify,
pour les fonctions serveur.
