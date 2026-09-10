-- Compter les parties, et rien d'autre.
--
-- Une seule table, un seul compteur par jour, par événement et par format. Aucune colonne ne
-- peut porter un identifiant : il n'y en a pas dans le schéma, donc il ne peut pas s'en glisser
-- un plus tard par distraction. La date est posée par le serveur, en heure de Paris, pour que
-- la ligne ne dépende pas de l'horloge d'un téléphone.
--
-- Additive et rejouable : « if not exists », « or replace », « drop policy if exists ».

create table if not exists public.usage_jour (
  jour       date     not null,
  evenement  text     not null,
  format     smallint not null default 0,
  n          integer  not null default 0,
  primary key (jour, evenement, format)
);

comment on table  public.usage_jour is
  'Combien de parties ont été comptées, par jour. Aucune donnée personnelle : ni identifiant '
  'd''appareil, ni session, ni score, ni prénom. Alimentée uniquement par public.compter().';
comment on column public.usage_jour.jour      is 'Date posée par le serveur, en heure de Paris.';
comment on column public.usage_jour.evenement is 'partie_finie ou partie_arretee.';
comment on column public.usage_jour.format    is '1 tête-à-tête, 2 doublette, 3 triplette, 0 inconnu.';
comment on column public.usage_jour.n         is 'Le compte.';

-- Aucune politique n'est créée : verrouillée, la table n'est ni lisible ni écrivable par les
-- rôles anon et authenticated. Seule la fonction ci-dessous y touche, et seul le tableau de
-- bord du projet la lit.
alter table public.usage_jour enable row level security;

-- Le seul point d'entrée. « security definer » lui permet d'écrire dans une table que
-- l'appelant ne peut pas toucher ; la liste blanche l'empêche d'écrire autre chose que les
-- quatre compteurs prévus.
create or replace function public.compter(p_evenement text, p_format smallint default 0)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_evenement not in ('partie_finie', 'partie_arretee') then
    raise exception 'événement inconnu';
  end if;
  if p_format is null or p_format < 0 or p_format > 3 then
    raise exception 'format inconnu';
  end if;

  insert into public.usage_jour (jour, evenement, format, n)
  values (((now() at time zone 'Europe/Paris')::date), p_evenement, p_format, 1)
  on conflict (jour, evenement, format) do update set n = public.usage_jour.n + 1;
end;
$$;

comment on function public.compter(text, smallint) is
  'Incrémente un compteur anonyme. N''accepte que des événements et des formats connus, '
  'n''enregistre rien d''autre, et ne renvoie rien.';

revoke all on function public.compter(text, smallint) from public;
grant execute on function public.compter(text, smallint) to anon, authenticated;

-- ────────────────────────────────────────────────────────────────────────────
-- L'auditeur du projet signale trois choses sur cette migration. Les trois sont
-- voulues, et les « corriger » casserait le mécanisme :
--
--   rls_enabled_no_policy (INFO) — la table est verrouillée exprès. Aucune
--       politique, donc personne ne la lit ni ne l'écrit ; seule la fonction
--       ci-dessus y touche, et seul le tableau de bord du projet la lit.
--   anon_security_definer_function_executable (WARN)
--   authenticated_security_definer_function_executable (WARN)
--       — c'est le mécanisme lui-même : « compter » DOIT être appelable sans
--       compte, sinon il n'y a rien à compter. Le risque est borné par la liste
--       blanche : deux événements, quatre formats, aucun autre écrit possible,
--       et la fonction ne renvoie rien.
--
-- Éprouvé depuis le rôle anon : lecture de la table 0 ligne, écriture directe
-- refusée par la sécurité au niveau ligne, événement inventé refusé, format
-- hors bornes refusé.
