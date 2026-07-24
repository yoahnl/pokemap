# Parcours d’acceptation Phase 0

## AJ-001 — Première ouverture

Étant donné une bibliothèque vide, le Hub affiche une vue guidée, l’espace
disque et **Importer un jeu**. Aucun vocabulaire workspace/map/seed n’apparaît.

## AJ-002 — Installation locale valide

Étant donné un package v1 non signé valide, l’inspection montre identité,
éditeur déclaré, taille, compatibilité et avertissement. Après consentement,
la progression suit les étapes ; la promotion crée receipt/library et ouvre le
détail. Une annulation avant promotion ne laisse aucune version visible.

## AJ-003 — Package hostile

Étant donné traversal, doublon ou secret probable, l’import est rejeté avant
écriture hors staging. La version courante et les saves sont inchangées ; un
code diagnostic sûr est exportable.

## AJ-004 — Continuer

Étant donné une save valide, le joueur choisit le jeu, voit sa dernière partie,
ouvre le titre puis Continuer. Le Hub lance exactement la version et le slot
compatibles. Le monde reçoit le focus après `running`.

## AJ-005 — Nouvelle partie

Étant donné plusieurs profils/slots, Nouvelle partie demande profil et slot.
Un slot occupé exige confirmation ; son contenu devient backup avant création.
Annuler revient au titre sans mutation.

## AJ-006 — Pause et services

Menu/Start ouvre pause au clavier, manette et tactile. Reprendre, équipe, sac,
Pokédex, carte, save et options suivent la matrice. Boutique, soin et PC
n’apparaissent que via l’interaction/capability autorisée.

## AJ-007 — Background et reprise

Quand l’application passe en arrière-plan, gameplay/audio/input sont suspendus
et un checkpoint sûr est tenté. Au retour, la session reprend sans double input.
Si l’OS interrompt le processus, la dernière save validée reste lisible.

## AJ-008 — Update et rollback

Une update est validée côte à côte. Un échec ne change pas `current.json`.
Après activation, une save pré-update est conservée. Rollback restaure version
et snapshot compatibles avec confirmation.

## AJ-009 — Repair et uninstall

Repair détecte un fichier altéré et rétablit la version contre son receipt sans
toucher aux saves. Uninstall retire le jeu mais conserve ses saves ; une
suppression de saves est une action séparée, explicitement destructive.

## AJ-010 — Crash desktop

Le child player quitte avec code non nul. Le Hub reste interactif, détecte
l’échec en moins de 12 s, garde save/library, propose logs, Repair et retry, puis
peut lancer une autre session.

## AJ-011 — Fin de jeu

La commande no-code Terminer le jeu produit une fois `GameCompleted`. Le
gameplay se verrouille, la save completed est committée, puis résultat et
crédits apparaissent. Le joueur revient au titre ou au Hub après teardown.

## AJ-012 — Save historique

Le Hub détecte éventuellement la save globale mais ne l’associe pas. L’assistant
demande jeu/profil/slot, valide, montre un aperçu, copie dans une enveloppe et
laisse le fichier original intact. Une identité incertaine bloque l’import.

## AJ-013 — Accessibilité et responsive

Les parcours critiques sont réalisables sans pointeur, avec focus visible,
semantics, text scaling et reduced motion. Aucun overflow en desktop, mobile
portrait ou paysage ; l’état sélectionné ne dépend pas de la couleur seule.

## Gate

Ces parcours deviennent des tests unitaires/widget/intégration par phase.
L’E2E final utilise un second mini-jeu neutre et fonctionne offline ; Selbrume
seul ne satisfait pas cette acceptation générique.
