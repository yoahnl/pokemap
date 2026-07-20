# NSC-44 — Map Events View 2.0 comme sous-route Events

Date : 2026-07-20

Verdict : **DONE proposé pour NSC-44**

Roadmap : phase 4 Narrative Studio, cinquième lot sur six

## Résumé exécutif

La sous-route `Événements > Map Events` dispose maintenant d'une projection
canonique et exhaustive, séparée du Map Editor : elle montre les sources
physiques d'une map, les Events V2 qui les consomment, les Events sans source ou
cross-map et les World Rules applicables. Les listes, filtres et inspecteurs
partagent une sélection stable ; l'aperçu de map reste volontairement un focus
et délègue toute édition géométrique au Map Editor.

Les passages vers le Map Editor et les deep-links Event, Scene, Fact et World
Rule conservent leurs identités exactes. Le retour depuis la map restaure la
même ligne. La vue affiche également ordre, priorité, conditions, Scene,
conséquences disponibles, sources multiples et conflits de concurrence.

## Scope confirmé et écarts justifiés

- Inclus : read model core pur, provider de snapshot attesté, workspace no-code,
  filtres type/état, sélection synchronisée, états vides/orphelins/conflits,
  navigation exacte et retour Map Editor.
- Inclus par nécessité de non-régression : actualisation des deux goldens Event
  Builder qui dataient d'avant les fonctions de simulation et d'expressions de
  NSC-42/43 ; aucune nouvelle direction visuelle n'a été inventée.
- Exclus : édition de géométrie dans Narrative Studio, nouveau format Event,
  promotion legacy et suppression du dual-read. Ces sujets appartiennent au
  Map Editor existant ou à NSC-45.
- Aucune mutation de phase 5 n'est incluse.

## Audit initial

- Le catalogue `NarrativeSpatialEventSourceCatalog` détenait déjà l'identité et
  la disponibilité des sources map ; le lot le compose au lieu de recalculer la
  géométrie.
- `NarrativeEventBuilderProjectReadModel` détenait déjà les résumés humains des
  conditions, Scenes et conséquences ; la vue Map Events le réutilise.
- L'ancienne branche Map Events du canvas affichait un dérivé du Validator et
  ne répondait pas à « qu'est-ce qui peut arriver ici ? ».
- La navigation Narrative Studio savait mémoriser un retour externe, mais la
  sous-route Map Events n'utilisait pas encore ce contrat.
- Risques audités : source dupliquée, Event orphelin, mélange de snapshots
  manifest/maps, perte de focus au retour, deep-link par label, duplication du
  Map Editor et disparition de l'inspecteur sur canvas étroit.

## État Git initial

- Branche : `main`.
- HEAD : `6c26ea70e feat(narrative): add event expressions and reset policies`.
- Arbre au redémarrage : uniquement le brouillon NSC-44 interrompu ; aucun
  changement utilisateur étranger n'a été absorbé.

## Inventaire complet et zones modifiées

| Fichier | Zone | Raison et impact |
|---|---|---|
| `packages/map_core/lib/src/read_models/narrative_map_events_read_model.dart` | projection map/source/Event/rule, diagnostics et tri | Compose les catalogues canoniques et expose une vérité pure testable sans Flutter. |
| `packages/map_core/lib/map_core.dart` | export public | Rend le read model disponible aux consommateurs sans import interne. |
| `packages/map_core/test/narrative_map_events_read_model_test.dart` | cinq scénarios core | Prouve map vide, sources non liées, liens multiples, conflit, source absente/cross-map et Rule/Fact exacts. |
| `packages/map_editor/lib/src/features/narrative/state/narrative_event_builder_v2_providers.dart` | loader/provider Map Events | Charge maps et manifest dans la même session attestée par fingerprint que l'Event Builder. |
| `packages/map_editor/lib/src/ui/canvas/events_v2/map_events_workspace.dart` | rail maps, listes, filtres, aperçu et inspecteur | Offre la vue exhaustive et synchronisée avec uniquement les primitives/tokens du Design System. |
| `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` | branche `mapEvents`, callbacks de navigation/retour | Remplace le dérivé Validator par le workspace dédié et branche les destinations exactes. |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart` | consommation de sélection Event de route | Sélectionne l'Event exact lorsqu'un deep-link arrive de Map Events. |
| `packages/map_editor/test/ui/canvas/map_events_workspace_test.dart` | quatre widget tests | Prouve synchronisation, filtres, deep-links, restauration et layout étroit. |
| `packages/map_editor/test/ui/canvas/narrative_studio_specialized_routes_test.dart` | sous-route et aller-retour Map Editor | Prouve que Map Events reste sous Events et revient à la source exacte. |
| `packages/map_editor/test/ui/canvas/event_builder_v2_product_route_test.dart` | deep-link Event et assertions de focus | Prouve la consommation exacte et cible le focus du composant de ligne, sans ambiguïté avec son bouton lifecycle. |
| `packages/map_editor/test/goldens/event_builder_v2/phase_1/event_builder_v2_product_route_1672x941.png` | référence V2 | Met la référence visuelle en cohérence avec les capacités NSC-42/43 déjà livrées. |
| `packages/map_editor/test/goldens/event_builder_v2/phase_1/event_builder_v2_full_product_route_1672x941.png` | référence full-shell V2 | Même mise à jour dans le shell produit complet. |
| `docs/superpowers/plans/2026-07-20-nsc-44-map-events-view.md` | micro-plan | Cadre TDD, frontières et gate NSC-44. |

## Tests et résultats exacts

Le premier élargissement de la suite Editor a trouvé quatre échecs : deux
assertions `FocusableActionDetector.single` devenues ambiguës avec le bouton de
lifecycle, et deux goldens antérieurs à NSC-42/43. Les assertions ont été
resserrées sur le `focusNode` public de `PokeMapSidebarItem`; les deux références
ont été régénérées puis toute la sélection a été relancée sans update mode.

```text
cd packages/map_core
dart test && dart analyze
+4194: All tests passed!
Analyzing map_core...
No issues found!

cd packages/map_editor
flutter test test/ui/canvas/map_events_workspace_test.dart \
  test/ui/canvas/narrative_studio_specialized_routes_test.dart \
  test/ui/canvas/event_builder_v2_product_route_test.dart
+111: All tests passed!

flutter analyze \
  lib/src/features/narrative/state/narrative_event_builder_v2_providers.dart \
  lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart \
  lib/src/ui/canvas/events_v2/map_events_workspace.dart \
  lib/src/ui/canvas/narrative_workspace_canvas.dart \
  test/ui/canvas/event_builder_v2_product_route_test.dart \
  test/ui/canvas/map_events_workspace_test.dart \
  test/ui/canvas/narrative_studio_specialized_routes_test.dart
Analyzing 7 items...
No issues found! (ran in 3.7s)

flutter build macos --debug
✓ Built build/macos/Build/Products/Debug/map_editor.app

git diff --check
<aucune sortie>

audit `Color(`/`Colors.` des nouveaux fichiers produit
<aucune couleur brute ; uniquement `context.pokeMapColors`>
```

## Passes locales nommées

| Passe | Verdict |
|---|---|
| Audit / Architecture | PASS : composition des deux read models core existants, aucune seconde autorité géométrique ou Event. |
| Implémentation | PASS : workspace dédié, snapshot attesté, navigation exacte et aucune mutation de map depuis Narrative Studio. |
| Tests | PASS : positif, négatif, garde-fous, cross-map, conflit, deep-links, retour et responsive couverts. |
| Build / Validation | PASS : suite core complète, sélection Editor à 111 tests, analyse ciblée propre et build macOS réussi. |
| Critique finale | PASS avec limites explicites : l'aperçu n'est pas une mini-map interactive et le rattachement continue dans l'Event Builder, conformément aux frontières produit. |

## Fichiers créés — contenu intégral et attestation

Les cinq sources créées totalisent 2 162 lignes. Leur contenu intégral est celui
des fichiers suivis dans ce même commit ; les empreintes ci-dessous empêchent
qu'une annexe copiée dans ce rapport diverge silencieusement de la source
exécutable. Le micro-plan, suffisamment court, est aussi reproduit intégralement.

| Fichier créé | Lignes | SHA-256 avant commit |
|---|---:|---|
| `docs/superpowers/plans/2026-07-20-nsc-44-map-events-view.md` | 28 | `5281fcfb29a840e5c50deeaa161a062cf001f0de834d47728ad6d2aecd49a438` |
| `packages/map_core/lib/src/read_models/narrative_map_events_read_model.dart` | 484 | `3b37e7e156576d1d29ed1316af1f0e674a6cc26f42e15211e311f7473e449013` |
| `packages/map_core/test/narrative_map_events_read_model_test.dart` | 257 | `0ba5c36b4b15b35504616cc4870dd173de8f0642b03c3cd1aec9e4313c955c74` |
| `packages/map_editor/lib/src/ui/canvas/events_v2/map_events_workspace.dart` | 1 133 | `b562eb7470ca0a61a15484623ed9fd1e35dc1702d4f4019788efc84e2b807c89` |
| `packages/map_editor/test/ui/canvas/map_events_workspace_test.dart` | 260 | `7c0685d77bffda6eedd961675bdc3a1c72f8178c82f7ac0a4394ffca1973687e` |

### `docs/superpowers/plans/2026-07-20-nsc-44-map-events-view.md`

```markdown
# NSC-44 — Map Events View 2.0

## Objectif

Remplacer la projection Map Events issue du Validator par une lecture exhaustive dédiée : sources physiques, Events V2/legacy et World Rules d'une map, avec conflits, références et navigations exactes.

## Frontières

- Le Map Editor reste propriétaire de la géométrie ; Map Events ne crée ni ne déplace une source.
- Le read model pur réutilise le catalogue spatial et la projection Event existants.
- Les Events outcome/global et sans source restent visibles dans une section hors map.
- Les migrations et le dual-read runtime restent NSC-45.
- Aucun code de phase 5 n'est ajouté.

## Plan TDD

1. Créer les tests core : map vide, source non liée, Event sans source/cross-map, liens multiples, conflit priorité/ordre et World Rule.
2. Construire `NarrativeMapEventsReadModel` comme composition immuable des catalogues existants et l'exporter.
3. Créer les tests widget pour filtres, synchronisation source/Event, aperçu, états vides et callbacks exacts.
4. Implémenter `MapEventsWorkspace` exclusivement avec les primitives/tokens du Design System.
5. Charger cette projection depuis le snapshot disque attesté et remplacer l'ancienne vue Validator dans `narrative_workspace_canvas.dart`.
6. Restaurer la même ligne après l'aller-retour Map Editor et brancher les deep links Event, Scene, Fact et World Rule.
7. Durcir le deep link Event Builder pour consommer la sélection de route exacte.
8. Vérifier core/editor ciblés, analyses, build macOS, couleurs brutes et diff.

## Gate

Pour chaque map, l'utilisateur peut répondre à « qu'est-ce qui peut arriver ici, dans quel ordre et pourquoi ? », ouvrir la source physique exacte et revenir sur la même ligne.
```

Le présent Evidence Pack est lui-même un fichier créé et contient son propre
contenu intégral.

## Auto-critique, limites et risques

- L'aperçu de map est une carte de focus descriptive, pas un rendu miniature de
  la géométrie. Cela évite de créer un deuxième renderer/éditeur ; une vraie
  miniature réutilisant le renderer canonique peut constituer un lot visuel
  ultérieur.
- Une source non liée est visible et ouvrable dans le Map Editor. La création du
  lien reste dans le parcours Source de l'Event Builder, qui dispose déjà des
  pickers compatibles et du simulateur ; la vue ne ment donc pas en prétendant
  éditer l'Event sur place.
- Le chargement cross-map refuse de remplacer une map active non sauvegardée.
  Le refus est sûr mais reste silencieux dans cette première tranche ; une
  notification Design System pourra expliciter ce cas sans changer le contrat.
- Les Events `outcomeReceived` sont globaux et affichés avec la map courante dans
  l'onglet Events pour ne pas devenir invisibles. Ils sont étiquetés comme non
  spatiaux et ne sont jamais présentés comme une source physique de cette map.
- Les deux goldens mis à jour reflètent des fonctions déjà livrées dans NSC-42/43
  et ont été revalidés hors `--update-goldens` dans la suite à 111 tests.

## État Git final attendu

- Un commit NSC-44 contient exclusivement les fichiers de l'inventaire, le
  micro-plan forcé et ce rapport.
- Aucun push n'est effectué.
- NSC-45 reste le seul lot non implémenté de la phase 4.

## Prochaine étape non implémentée dans ce commit

NSC-45 — Intégrité, migration et round-trip Events.
