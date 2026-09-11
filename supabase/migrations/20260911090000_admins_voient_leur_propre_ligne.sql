-- CORRECTIF de la migration précédente, trouvé en éprouvant la politique plutôt qu'en la lisant.
--
-- LE DÉFAUT. La politique de lecture des compteurs interroge public.admins :
--
--   using (exists (select 1 from public.admins a where a.user_id = (select auth.uid())))
--
-- Or public.admins a la sécurité au niveau ligne activée SANS aucune politique. La sous-requête
-- ne rendait donc RIEN — y compris pour un administrateur. La porte était verrouillée de
-- l'intérieur : le seul administrateur du projet voyait zéro compteur, exactement comme un
-- inconnu. Lire le SQL ne le montre pas ; simuler les trois rôles le montre en trois lignes.
--
-- LE REMÈDE. Une politique minimale : chacun voit SA propre ligne d'administrateur, et rien
-- d'autre. Elle ne révèle rien qu'un administrateur ne sache déjà, et elle évite d'introduire
-- une fonction « security definer » de plus pour contourner la sécurité qu'on vient de poser.

drop policy if exists "chacun voit sa propre ligne d'administrateur" on public.admins;
create policy "chacun voit sa propre ligne d'administrateur"
  on public.admins
  for select
  to authenticated
  using (user_id = (select auth.uid()));

-- Éprouvé en simulant les trois rôles :
--
--   anon (non connecté)            0 compteur
--   connecté, pas administrateur   0 compteur, 0 ligne d'admins
--   me@pauliglesia.com             3 compteurs, 1 ligne d'admins (la sienne)
--   Paul écrit un compteur         refusé
--   Paul se nomme un complice      refusé
--
-- Aucune écriture n'est possible depuis un navigateur, administrateur compris : seule
-- compter() écrit, et seul le tableau de bord du projet nomme un administrateur.
