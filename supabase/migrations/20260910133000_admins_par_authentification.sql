-- Une vraie authentification, à la place d'un secret partagé.
--
-- POURQUOI. La version précédente comparait une phrase de passe à son empreinte. Le secret
-- n'était stocké nulle part en clair — mais il fallait le TAPER dans l'éditeur SQL du projet
-- pour le poser, où il restait dans l'historique des requêtes. Un secret qui doit traverser un
-- journal pour être installé n'est pas un secret.
--
-- CE QUI LE REMPLACE. Un compte Supabase ordinaire, créé une fois depuis Authentication →
-- Users → Add user, où le mot de passe est saisi dans un champ prévu pour et jamais journalisé.
-- La lecture des compteurs devient une politique de sécurité, plus une fonction : le navigateur
-- lit la table directement avec le jeton de la session. Un compte connecté qui n'est pas dans
-- « admins » voit zéro ligne — pas une erreur, du vide.
--
-- POUR AJOUTER UN ADMINISTRATEUR, une fois son compte créé, et sans aucun secret dans la
-- requête :
--
--   insert into public.admins (user_id)
--   select id from auth.users where email = 'adresse@exemple.fr'
--   on conflict do nothing;
--
-- Exception assumée à la règle « additif d'abord » : les deux objets supprimés avaient vingt
-- minutes, ne contenaient aucune donnée, et laisser vivre une porte ouverte par un secret
-- partagé aurait été pire que la supprimer.

drop function if exists public.chiffres(text);
drop table if exists public.admin_cle;

create table if not exists public.admins (
  user_id   uuid primary key references auth.users(id) on delete cascade,
  ajoute_le timestamptz not null default now()
);

comment on table public.admins is
  'Qui peut lire les compteurs. Verrouillée : personne ne la lit ni ne l''écrit depuis le '
  'navigateur — seul le tableau de bord du projet y touche.';

alter table public.admins enable row level security;

drop policy if exists "les administrateurs lisent les compteurs" on public.usage_jour;
create policy "les administrateurs lisent les compteurs"
  on public.usage_jour
  for select
  to authenticated
  using (exists (select 1 from public.admins a where a.user_id = (select auth.uid())));

-- L'écriture reste interdite à tout le monde, administrateurs compris : seule compter() écrit,
-- et elle n'accepte que ses deux événements.
