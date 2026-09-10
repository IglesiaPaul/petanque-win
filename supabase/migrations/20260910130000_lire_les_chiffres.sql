-- REMPLACÉE le 10 septembre par 20260910133000_admins_par_authentification.sql : la phrase de
-- passe devait être tapée dans l'éditeur SQL du projet, où elle restait dans l'historique des
-- requêtes. Une vraie authentification l'a remplacée. Ce fichier reste pour l'histoire.

-- Lire les compteurs depuis l'application, sans embarquer de secret dans le code.
--
-- La page /#admin du site appelle chiffres(phrase). Le serveur compare l'empreinte SHA-256 de
-- la phrase à celle qui est posée dans admin_cle. La phrase elle-même n'est nulle part : ni
-- dans cette base, ni dans le code du site, ni dans ce dépôt. Elle est posée une fois par le
-- propriétaire depuis l'éditeur SQL du projet, et retenue ensuite par son seul téléphone.
--
-- POUR POSER OU CHANGER LA PHRASE, exécuter ceci dans l'éditeur SQL du projet, en remplaçant
-- le texte entre guillemets par une vraie phrase — longue, la fonction refuse en dessous de
-- huit signes :
--
--   insert into public.admin_cle (id, empreinte)
--   values (1, encode(extensions.digest('votre phrase ici', 'sha256'), 'hex'))
--   on conflict (id) do update set empreinte = excluded.empreinte, posee_le = now();
--
-- Tant qu'aucune phrase n'est posée, la page refuse tout : c'est le bon défaut.

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.admin_cle (
  id         smallint primary key default 1,
  empreinte  text not null,
  posee_le   timestamptz not null default now(),
  constraint une_seule_cle check (id = 1)
);

comment on table public.admin_cle is
  'Une ligne, l''empreinte SHA-256 de la phrase de passe qui ouvre la page des chiffres. '
  'Verrouillée : ni lisible ni écrivable par anon ou authenticated.';

alter table public.admin_cle enable row level security;

create or replace function public.chiffres(p_cle text)
returns table(jour date, evenement text, format smallint, n integer)
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  if p_cle is null or length(p_cle) < 8 then
    raise exception 'clé invalide';
  end if;
  if not exists (
    select 1 from public.admin_cle
    where empreinte = encode(extensions.digest(p_cle, 'sha256'), 'hex')
  ) then
    raise exception 'clé invalide';
  end if;

  return query
    select u.jour, u.evenement, u.format, u.n
    from public.usage_jour u
    where u.jour > (((now() at time zone 'Europe/Paris')::date) - 60)
    order by u.jour desc, u.evenement, u.format;
end;
$$;

comment on function public.chiffres(text) is
  'Les compteurs des soixante derniers jours, contre la phrase de passe. Agrégats seuls.';

revoke all on function public.chiffres(text) from public;
grant execute on function public.chiffres(text) to anon, authenticated;

-- Éprouvé depuis le rôle anon : lecture de admin_cle 0 ligne, phrase vide refusée, mauvaise
-- phrase refusée, bonne phrase acceptée. Comme pour compter(), l'auditeur signalera une
-- fonction « security definer » appelable sans compte : c'est le mécanisme, et le risque est
-- borné — la fonction ne rend que des agrégats, et cette base n'a aucune colonne capable de
-- porter un identifiant de personne.
