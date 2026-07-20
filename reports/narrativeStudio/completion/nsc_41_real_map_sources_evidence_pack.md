# NSC-41 — Workflow Source et Trigger fondé sur les éléments réels de map

Date : 2026-07-20
Verdict : **DONE proposé pour NSC-41**
Roadmap : phase 4 Narrative Studio, deuxième lot sur six

## Résumé exécutif

L’Event Builder ne laisse plus entendre qu’il crée les PNJ, objets ou zones. Il projette désormais le catalogue canonique des sources physiques existantes, groupé par map et par nature (`Entrée de map`, `Zone`, `PNJ`, `Objet`). Les éléments placés qui ne constituent pas une source Event restent visibles comme non rattachables ; les références cassées demandent une réparation dans le Map Editor ; le legacy est signalé comme historique à migrer.

Une source compatible peut être sélectionnée sans saisir d’ID. Une modification non destructive d’un élément lié reste autorisée mais produit maintenant un message de revalidation Event après sauvegarde de la map. Une rupture d’identité, suppression ou transformation vers un type incompatible reste bloquée par le garde-fou existant. Le runtime continue à consommer exclusivement `NarrativeEventSourceRef` : aucune seconde autorité ou nouveau type runtime n’a été inventé.

## Confirmation du scope

- Lot exact : `NSC-41 — Workflow Source et Trigger fondé sur les éléments réels de map`.
- Inclus : catalogue groupé, catégories Map/Zone/PNJ/Objet, compatibilité, visibilité des références cassées/legacy/non rattachables, picker no-code Design System, explication Map Editor, revalidation après édition physique, tests navigation existants.
- Exclus : création ou édition géométrique dans Event Builder, expressions all/any/not, reset policies, simulateur, Map Events View, migration finale. Ces sujets restent NSC-42 à NSC-45.
- Aucun lot FG de `pokemap_roadmap_mecaniques_fangame.md` n’est requalifié par ce lot.
- La phase 5 n’est ni commencée ni modifiée.

## Audit initial

### Contrats et comportements trouvés

- `BuildNarrativeSpatialEventSourceCatalog` indexait déjà les maps, entités, triggers, éléments placés et provenances legacy avec des identités canoniques.
- Le snapshot du use case n’exposait que `selectableOptions`, ce qui rendait invisibles les propriétaires physiques cassés ou non rattachables.
- La source sheet utilisait un dropdown plat : elle ne matérialisait ni la map propriétaire, ni le type physique, ni l’état de réparation.
- `NarrativeEventSourceDependencyGuard` bloquait déjà les ruptures de référence mais ne distinguait pas une édition physique non destructive nécessitant une revalidation.
- La navigation Event → Map et le bandeau de création de source côté Map Editor existaient déjà et ont été conservés puis retestés.

### Risques identifiés

- laisser croire qu’Event Builder crée ou déplace les éléments de map ;
- fabriquer un type source parallèle au wire canonique ;
- rendre sélectionnable un élément placé qui n’est ni une entité interactive ni une zone Event ;
- masquer une référence cassée et empêcher l’utilisateur de comprendre sa réparation ;
- bloquer toute édition esthétique d’une source liée alors que seule l’identité doit être protégée ;
- dégrader clavier, focus ou fidélité des résultats non spatiaux.

### Décisions

- La catégorie de présentation est dérivée du propriétaire physique et reste séparée de `NarrativeEventSourceRef`.
- Seuls les éléments `ready` et les choix draft sont activables ; cassé, non rattachable et legacy restent informatifs.
- PNJ et objet partagent l’autorité runtime `entityInteract`, mais leur distinction de présentation vient de `MapEntityKind`.
- Les outcomes de Scene et le brouillon restent dans le même picker, sans être faussement rattachés à une map.
- Une modification non identitaire déclenche une demande de revalidation ; une rupture de source reste bloquée avant écriture.

## État Git initial

- Branche : `main`.
- HEAD : `cbbce7e363 feat(narrative): complete event lifecycle`.
- `git status --short --untracked-files=all` : aucune sortie ; worktree propre.
- Aucun worktree ni sous-agent n’a été utilisé. Les passes exigées par `codex_rule.md` ont été réalisées localement et nommées séparément.

## Inventaire complet et zones modifiées

| Fichier | Zone précise | Raison et impact |
|---|---|---|
| `packages/map_core/lib/src/catalogs/narrative_spatial_event_source_catalog.dart` | enums présentation/état, invariants option, groupe par map, filtre de compatibilité | Expose une projection immuable, déterministe et honnête des sources physiques sans changer l’autorité runtime. |
| `packages/map_core/lib/src/operations/build_narrative_spatial_event_source_catalog.dart` | construction des options entité | Distingue PNJ et objet à partir de `MapEntityKind`. |
| `packages/map_core/test/narrative_spatial_event_source_catalog_test.dart` | scénarios NSC-41 | Prouve groupes, catégories, compatibilité, identité stable après déplacement, cassé, non rattachable et legacy. |
| `packages/map_editor/lib/src/application/services/narrative_event_source_dependency_guard.dart` | décision de revalidation et collecte des Events liés | Autorise les éditions non destructives avec feedback, bloque toujours les ruptures d’identité. |
| `packages/map_editor/lib/src/application/use_cases/narrative_event_builder_v2_use_case.dart` | snapshot des sources spatiales | Expose aussi les propriétaires indisponibles afin que l’UI explique leur état. |
| `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` | inspection des candidats complets et feedback post-mutation | Ne réduit plus une édition à ID/kind et remonte la revalidation après sauvegarde. |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_authoring_sheets.dart` | modèle de choix, grouping, picker, save guard et aide Map Editor | Remplace le dropdown plat par un workflow no-code fondé sur les sources existantes. |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_inspector.dart` | champ `Édition physique` | Rend explicite la frontière Event Builder / Map Editor. |
| `packages/map_editor/lib/src/ui/design_system/design_system.dart` | barrel export | Rend le picker réutilisable par les autres surfaces éditeur. |
| `packages/map_editor/lib/src/ui/design_system/narrative/pokemap_event_source_picker.dart` | nouveau composant Design System | Fournit groupes, cartes, badges sémantiques, clavier, focus et désactivation honnête sans couleur locale. |
| `packages/map_editor/test/narrative_event_source_dependency_guard_test.dart` | cas de revalidation et non-régression | Prouve édition liée, aucun-op, sources non liées et blocages existants. |
| `packages/map_editor/test/ui/canvas/event_builder_v2_creation_flow_test.dart` | parcours source direct et clavier | Prouve groupes réels, états visibles, non-activation des choix indisponibles, persistance PNJ et outcomes. |
| `docs/superpowers/plans/2026-07-20-nsc-41-real-map-sources.md` | micro-plan TDD du lot L | Cadre audit, rouge/vert, preuves et frontières du lot. |

## Fichiers créés — contenu canonique

Leur contenu intégral est enregistré dans le même commit que ce rapport et reste consultable avec `git show <commit-nsc-41>:<chemin>`. Empreintes avant commit :

| Fichier | Lignes | SHA-256 |
|---|---:|---|
| `docs/superpowers/plans/2026-07-20-nsc-41-real-map-sources.md` | 79 | `f7db0c7cfc04bae0457b4f118e78b40b20577555f1940ae985274221ef3b514d` |
| `packages/map_editor/lib/src/ui/design_system/narrative/pokemap_event_source_picker.dart` | 271 | `64dd28e709647b413ee8dc1f38fbe8b254c90cb2be2db9ed7261099243386a92` |

Le présent Evidence Pack constitue le troisième fichier créé et contient son propre contenu intégral.

## Tests créés ou modifiés

- Positif : groupement map/catégorie, sélection PNJ, compatibilité source, persistance, déplacement physique à identité stable.
- Négatif : source absente ou ambiguë, élément placé non rattachable, transition spawn/incompatible, rupture d’identité.
- Garde-fous : option indisponible non cliquable et hors focus, sauvegarde désactivée, aucun ID manuel, aucune création physique Event.
- Non-régression : outcome Scene, draft, navigation Event ↔ Map, lease/journal Map et flux workspace continuent à passer.

## Commandes et résultats exacts

### Rouge TDD

```text
cd packages/map_core
dart test test/narrative_spatial_event_source_catalog_test.dart
FAIL attendu : catégories de présentation, mapGroups et filtre de compatibilité absents.

cd packages/map_editor
flutter test test/ui/canvas/event_builder_v2_creation_flow_test.dart
FAIL attendu : aucun groupe de map dans le dropdown plat.

flutter test test/narrative_event_source_dependency_guard_test.dart
FAIL attendu : contrat de revalidation absent.
```

Une première commande core référençait par erreur `test/narrative_event_project_catalog_test.dart`, fichier inexistant. Elle a été corrigée vers le test réel ci-dessus ; ce n’était pas un échec produit.

### Core final

```text
cd packages/map_core
dart test test/narrative_spatial_event_source_catalog_test.dart && dart analyze
+12: All tests passed!
No issues found!
```

### Editor final

```text
cd packages/map_editor
flutter test test/narrative_event_builder_v2_use_case_test.dart test/narrative_event_source_dependency_guard_test.dart test/ui/canvas/event_builder_v2_creation_flow_test.dart test/ui/canvas/event_builder_v2_flow_fidelity_test.dart test/ui/canvas/event_builder_v2_workspace_test.dart test/event_map_navigation_controller_test.dart test/ui/canvas/narrative_event_map_banner_test.dart
+85: All tests passed!
```

### Analyse

```text
cd packages/map_editor
flutter analyze <9 fichiers NSC-41>
No issues found! (ran in 3.7s)
```

L’analyse complète editor conserve exactement sa baseline hors lot :

```text
flutter analyze
11 issues found. (ran in 4.9s)
```

Les 11 warnings visent uniquement `lib/src/ui/canvas/dialogue_studio/dialogs/dialogue_studio_dialogs.dart` (un `unused_element`, dix usages protected/visibleForTesting). Ce fichier n’est pas modifié par NSC-41 ; ils ne sont pas maquillés ni corrigés dans ce lot Event.

### Build

```text
cd packages/map_editor
flutter build macos --debug
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

### Audit statique

```text
git diff --check
<aucune sortie>

rg <raw UI colors> <fichiers UI NSC-41>
<aucune couleur brute ; les seules correspondances larges étaient des variables `toneColors` issues du Design System>
```

## Passes locales nommées exigées

| Passe | Verdict |
|---|---|
| Audit / Architecture | PASS : catalogue spatial, refs canoniques et navigation existante réutilisés comme autorités uniques. |
| Implémentation | PASS : projection groupée et picker DS ajoutés sans modèle physique concurrent. |
| Tests | PASS ciblé : 12 tests core et 85 tests editor couvrent positif, négatif, garde-fous et navigation. |
| Build / Validation | PASS avec baseline : analyses core/ciblée vertes et build macOS réussi ; 11 warnings Dialogue globaux documentés. |
| Critique finale | PASS : les éléments placés non-sources ont été séparés de l’état “à réparer”, le legacy reste distinct et aucune option indisponible n’est activable. |

## Auto-critique finale

- La première projection aurait pu présenter tout élément placé comme une référence cassée. La passe critique a introduit `notAttachable` pour ne pas promettre qu’une simple réparation suffira.
- Les tests clavier comptaient initialement un nombre fixe de tabulations, fragile après ajout du picker. Ils cherchent maintenant l’action draft réellement focalisée avant activation.
- Le catalogue distingue PNJ/objet uniquement pour la présentation ; cette distinction ne doit jamais être interprétée comme deux kinds runtime.
- Le picker conserve l’ordre déterministe fourni par le catalogue. Il n’offre pas encore recherche/filtre : le volume de source important sera traité avec la Map Events View de NSC-44 plutôt que par une extension hors lot.

## Limites et risques conservés

- Event Builder référence les sources ; il ne crée, déplace ou redimensionne aucun élément physique.
- Les modifications physiques non destructives demandent une revalidation après sauvegarde mais ne déclenchent pas une migration automatique.
- Les expressions conditionnelles, policies de reset et simulateur restent absents jusqu’à NSC-42/43.
- Les sources legacy restent visibles pour compatibilité mais ne deviennent pas sélectionnables implicitement.
- La suite editor complète de plusieurs milliers de tests n’a pas été relancée ; les 85 tests Event/navigation/persistence pertinents l’ont été.

## État Git final attendu

- Un commit NSC-41 contient exclusivement l’inventaire ci-dessus, le micro-plan forcé et cet Evidence Pack.
- Aucun push n’est effectué.
- Le prochain commit commencera NSC-42 seulement après fermeture de ce lot.

## Prochaine étape proposée, non implémentée ici

`NSC-42 — Conditions, comportement, Scene liée et simulation Event` : exposer la vérité V1 AND-only, les politiques de comportement et un simulateur qui appelle l’autorité de dispatch canonique.
