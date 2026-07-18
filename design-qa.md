# Narrative Studio — UI Convergence Design QA

Date : 2026-07-18

Lot : `NS-UI-CVG-11 — convergence globale vers la coque produit Event Builder`

Verdict : **PASS** pour le périmètre Narrative Studio. Toutes les destinations
réelles partagent désormais la même coque produit, sans ancien shell imbriqué,
et les actions visibles restent reliées à des capacités réelles.

## Cible et preuves comparées

- Référence utilisateur :
  `reports/narrativeStudio/ui_consistency_audit/evidence/00-user-target-event-builder-1672x941.png`
  — 1672 × 941 — SHA-256
  `2072679b3b861a63c068628450705d39e70ad59dc5067e0a0bf91c0bcbe8c885` ;
- planche finale combinée référence + routes :
  `reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/00-target-and-final-routes-contact-sheet.png`
  — 1671 × 1256 — SHA-256
  `d0b9e73ec03fa91d30c9ccce18ad294929e3ef2db10be6eddb82cc3074c2858f` ;
- comparaisons côte à côte individuelles :
  `reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/`.

La référence et chaque implémentation ont été placées dans une même image de
comparaison avant acceptation des goldens. Les vérifications ont porté sur la
coque, le rythme, les espacements, les bordures, la typographie, les icônes,
les états vides et la densité à viewport identique.

## Routes couvertes

| Destination | État produit capturé | Verdict |
|---|---|---|
| Aperçu | structure narrative réelle | PASS |
| Storylines | graphe et structure existants | PASS |
| Scènes | arborescence, canvas et inspecteur | PASS |
| Événements | V2, legacy et politique dual-read | PASS |
| Cinématiques | bibliothèque, builder et legacy | PASS |
| Dialogues | explorer, zone de montage et inspecteur | PASS |
| Facts | liste, édition et usages | PASS |
| Règles du monde | composition no-code et état vide | PASS |
| Étape | sous-route Storylines et authoring existant | PASS |

Les trois modes Événements et les trois modes Cinématiques portent le total
des comparaisons finales à treize états produit, plus la référence utilisateur.
La planche de synthèse conserve onze états représentatifs pour rester lisible ;
les treize comparaisons individuelles demeurent l'oracle exhaustif.

## Contrat visuel commun validé

- une seule `NarrativeStudioProductShell` par route ;
- une seule `NarrativeStudioWorkspacePage` et un seul contexte/breadcrumb ;
- rail gauche stable, navigation réelle et destination sélectionnée annoncée ;
- vocabulaire canonique français : `Scènes` et `Règles du monde` ;
- aucune réapparition du Project Explorer dans Narrative Studio ;
- surfaces, boutons, cartes, badges et couleurs issus du design system ;
- aucune action active sans capacité réelle : Dialogues masque les opérations
  disque sans `projectRootPath`, Event désactive la validation sans racine ;
- états sans projet explicites sur les neuf destinations ;
- `Project Health` masqué tant qu’aucun calcul n’existe ;
- diagnostics Event avec ton info/warning/danger cohérent ;
- fonte de capture versionnée et icônes préchargées de façon déterministe.

## Responsive et accessibilité

- matrice spécialisée complète : 4 routes × 5 viewports
  (1280, 1366, 1440, 1672, 1920) × 3 échelles texte
  (100 %, 125 %, 150 %) = 60 cas ;
- matrices Storylines, Scènes, Étape et Cinématiques rejouées ;
- DPR 2 couvert ;
- navigation Tab et Shift+Tab couverte ;
- sémantiques de sélection, actions icône, actions désactivées, statuts et
  diagnostics couvertes ;
- fermeture Escape et retour Navigator de la side sheet Scènes couverts ;
- restauration du focus après modal Storylines couverte.

## Goldens normatifs principaux

| Capture | SHA-256 |
|---|---|
| Aperçu | `f5e8b1b76ee3338bb2707cced012cd73c8379fbf5dbd7ca311220fe592f28ef5` |
| Storylines | `e5d594801a35537859af59231aad45906b5139844f8dcf562c6f6358ba463f29` |
| Scènes | `b5502bd011aa318a532d09791e2bf4b494caaeac08d6bd534601f3277628c0f7` |
| Event V2 | `f9bf76815dcc511210d9fd9a9af1a0993fc0ee165aa0503b3fd977e6c357eb76` |
| Cinématiques — bibliothèque | `0f50f0789432bed10c7d1623daa4268d77f76922b55f7887277d111d6176d7f7` |
| Dialogues | `f2c9d4fd44e663211a8d921539517929b25761b16fe7159f162276fb7c682dd2` |
| Facts | `2a7fcf943567847ef3c64dee680de875d123062012f8c4d8574edb512671f40b` |
| Règles du monde | `3c180fa7a46e850010bd14582b99d2dcea16becf87bbdfb4ab467d736fdd96c9` |
| Étape | `73e664ac65a3410fa508e4ae564df221209c8083a0766ac83b4278bd47c21aa1` |

## Validation fraîche

- gate Narrative Studio final : 9 fichiers, **191 tests réussis**,
  `All tests passed!` ;
- revue spécialisée : **107 tests réussis**, exit 0 ;
- anciens goldens impactés, inspectés puis régénérés : 5 fichiers de test,
  **28 tests réussis**, `All tests passed!` ;
- analyse package : `flutter analyze --no-pub` → `No issues found!` ;
- format du scope modifié : 51 fichiers Dart, `0 changed` ;
- build produit : `flutter build macos --debug --no-pub` →
  `✓ Built build/macos/Build/Products/Debug/map_editor.app` ;
- garde historique : zéro référence à l’ancien shell/sidebar ;
- `git diff --check` : aucune erreur.

La suite package complète a été lancée une fois : **3338 réussites et 9
échecs**. Cinq échecs étaient des goldens volontairement affectés par la
nouvelle coque et ont été inspectés/régénérés ; les quatre autres étaient des
tests de performance ou de génération Selbrume sensibles à la concurrence.
Ces quatre tests ont tous été rejoués isolément avec succès. La commande
globale n’a pas été relancée pendant sept minutes après ces corrections : ce
document ne la présente donc pas comme intégralement verte en une seule passe.

## Limites et auto-critique

- La convergence porte sur la coque et la cohérence produit ; elle ne remplace
  pas chaque workspace par un clone de la composition interne Event.
- Les données affichées restent celles des vrais modèles. Les compteurs,
  notifications ou actions absents du moteur ne sont pas simulés.
- Au moment du lot `NS-UI-CVG-11`, avant l'ajout du harness `SEL-FIN-09`,
  l’instrumentation Marionette n’était pas présente dans `map_editor`; cette
  passe de QA reposait donc sur les routes réelles en widget tests, les goldens
  déterministes et le build macOS, sans parcours UI automatisé du binaire.
- Le worktree contient des assets Selbrume non suivis préexistants qui n’ont
  pas été modifiés ni nettoyés par ce lot.

Les deux revues indépendantes finales valident l’architecture, le responsive,
les états honnêtes, la fonte portable et l’absence de couleurs locales.

final result: passed
