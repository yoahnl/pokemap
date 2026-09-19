# Avelune Studio — Intégration M1 : une carte réellement utilisable

Date : 19 septembre 2026. Périmètre : mission M1 fournie par l’utilisateur, après AS-ARC-002-bis.

## Résultat et portée des preuves

Le Studio dispose d’un espace de travail éditable : catalogue de cartes, rendu partagé et atlas réels, palette de décors avec recherche et miniatures, placement répété, sélection des objets masqués, déplacement avec aperçu, suppression, ordre visuel persistant, historique, peinture/gomme simples, sauvegarde atomique et lancement du vrai runtime.

Les preuves sont complémentaires : parcours de widgets, fichiers réellement écrits puis relus, pixels produits par le renderer partagé, et déplacement dans un vrai `PlayableMapGame`. Elles ne constituent pas une recette native complète. La compilation et le lancement macOS ont réussi ; le pilote UI s’est attaché à une ancienne instance, empêchant de prouver le parcours M1 natif de bout en bout. Aucune capture de l’ancien écran n’est présentée comme preuve M1.

Aucune écriture Git, aucun changement Notion, aucun projet personnel modifié. Les essais utilisent des dossiers temporaires et un exemple original généré pour M1. Aucun chantier suivant n’est commencé.

## Audit initial et décisions de réemploi

État initial : branche `main`, HEAD `881e3cbe5bae8c54cca14c3c0d9df44db2196961`, arbre propre. Voir [initial-state.txt](evidence/initial-state.txt). AS-ARC-001 fournit l’inventaire, AS-ARC-002 le cycle de session et AS-ARC-002-bis les protections de chemins ; leurs rapports restent inchangés.

L’audit a identifié trois risques principaux : dupliquer le moteur de rendu, reconstruire une seconde persistance, et confondre ordre visuel avec ordre métier. Les fondations existantes ont été extraites ou enveloppées :

| Besoin | Fondation reprise | Adaptation M1 |
| --- | --- | --- |
| Modèles et commandes | `MapData`, opérations de décors de map_core | `visualOrder`, tri et pas local compatibles, sans réordonner la liste |
| Historique et traits | `MapHistoryCoordinator`, deltas/checkpoints, `MapCellStrokeBuffer` de map_editor | Déplacement vers le barrel pur `map_authoring_editing.dart` ; anciens chemins réexportés |
| Persistance | `AtomicMapDocumentPersistence`, verrou, codec et révision | Extraction publique `map_authoring_documents.dart`, contrôles spécifiques Studio |
| Rendu | `MapLayersComponent`, chargeurs et résolution runtime | Wrapper public `RuntimeAuthoringMapRenderer` et ressources décodées hors paint/build |
| Test en jeu | `RuntimeMapBundle`, `PlayableMapGame` | Vue dédiée, révision contrôlée, sauvegardes de jeu en mémoire |
| Parité authoring | Registre d’actions canonique map_authoring | Actions `placed_element.bring_forward` / `send_backward`, JSONL et transport MCP |

Le barrel `map_core_domain.dart` reprend les exports purs ; `map_core.dart` conserve son API complète et réexporte séparément les importeurs Tiled utilisant dart:io. Cela évite de faire transiter l’IO dans l’application Studio. Les gardes vérifient les graphes application/presentation, les imports privés interpackages et l’absence de dépendance à map_editor. L’adaptateur runtime autorisé est contrôlé à sa frontière publique.

Les fichiers historiques d’historique, de traits et de persistance sont déplacés avec leurs responsabilités, sans découpage artificiel. Leurs anciens chemins sont des réexports, pas une deuxième implémentation. Les nouveaux fichiers manuels du Studio restent sous 300 lignes. La suppression de l’ancien fichier Freezed d’historique correspond à son déplacement dans map_authoring.

La dépendance map_runtime ajoute ses dépendances transitives nécessaires ; Flame devient explicite, map_core devient une dépendance de production, image sert au générateur d’exemple. map_authoring déclare freezed_annotation pour les modèles déplacés. Aucun changement moteur battle/gameplay ; map_gameplay reçoit seulement une preuve de non-régression.

Le sandbox macOS reste actif. Seul l’accès au dossier sélectionné passe de lecture seule à lecture/écriture. Swift Package Manager est conservé ; l’enregistrement natif ajoute les plugins requis par le runtime.

## Comportements et garanties

- Le catalogue est chargé une fois par session ; les documents sont chargés à la demande et conservés pendant cette session. Une génération invalide les retours asynchrones obsolètes. Le changement de carte conserve modifications, historique et vue.
- La sélection et `Empilement ici` utilisent l’empreinte visuelle en cellules, l’ordre des couches et les phases de rendu. Déplacer affiche un aperçu puis crée une commande à la fin du geste ; Échap annule. La palette permet plusieurs placements successifs.
- `visualOrder` est un entier sérialisé, à zéro par défaut. Le tri est stable à égalité. Un pas devant/derrière reste dans un contexte compatible ; la liste `placedElements`, les collisions, les coordonnées et les priorités d’interaction ne sont pas réordonnées. Les consommateurs runtime et ancien éditeur suivent le même tri.
- La peinture utilise les tuiles déjà référencées et l’interpolation de traits existante ; un trait produit une entrée d’historique. La gomme choisit au départ le support visible effectivement occupé. Elle ne s’arrête plus sur une couche de décors vide.
- Enregistrer capture une version du document. Une modification survenant pendant la sauvegarde reste sale. Enregistrer toutes les cartes ne ferme pas l’espace si une carte a changé entre-temps ou si le contrôleur a été détruit.
- L’adaptateur vérifie les chemins, l’identité de carte, le manifeste et la révision SHA-256 des octets. Le CAS atomique partagé protège l’écriture ; un échec préserve les derniers octets valides et le travail en mémoire. Une relecture depuis une nouvelle instance prouve la persistance.
- Les champs inconnus ou formats dont la réécriture perdrait des données sont refusés pour l’édition. Les familles connues non éditées sont conservées. Le chargement en lecture seule ne déclenche pas de récupération de journal avec écriture.
- La fermeture propose Enregistrer, Abandonner ou Annuler. Les raccourcis n’agissent pas sur la carte pendant une saisie textuelle.
- Tester sauvegarde d’abord, vérifie la carte active et la révision disque, puis démarre le vrai runtime. Une modification externe du manifeste bloque aussi une carte propre. Les interactions sont suspendues pendant cette préparation ; une navigation concurrente ne lance pas l’ancienne carte.
- Le retour du runtime conserve le document et la transformation de vue. Les sauvegardes de gameplay du test sont isolées en mémoire et ne créent pas de sauvegarde de joueur dans le projet.
- Les atlas sont décodés et réutilisés hors rendu avec un budget de 128 images / 256 Mio. Aucune mesure FPS ou certification mémoire prolongée n’est revendiquée.

## Vérifications exécutées

Chaque paire `.txt` / `.json` dans [evidence](evidence/) conserve sortie, commande exacte, répertoire, code de sortie et, pour le runner, processus possédés/nettoyage. Les essais rouges restent disponibles afin de ne pas masquer les régressions trouvées. Les contrôles finaux ci-dessous font autorité.

| Contrôle | Résultat exact / preuve |
| --- | --- |
| Studio complet : `flutter test --no-pub` | `00:07 +124: All tests passed!` — [tests-verified.txt](evidence/tests-verified.txt), exit 0, aucun descendant possédé restant |
| Studio : `flutter analyze --no-pub` | `No issues found! (ran in 5.2s)` — [analyze-delivery.txt](evidence/analyze-delivery.txt), exit 0 |
| Core : ordre, placement et rotation | `00:00 +47: All tests passed!` — [order-core-verified.txt](evidence/order-core-verified.txt) |
| Ordre final : core / JSONL / gameplay | 9 + 1 + 1 tests, trois codes 0 — [order-final-focused.txt](evidence/order-final-focused.txt) |
| Gameplay : priorité réelle d’interaction | 6 tests réussis — [order-gameplay-tests.txt](evidence/order-gameplay-tests.txt) |
| Ancien éditeur : pixels, hit test, ordre des couches | 33 tests réussis — [order-editor-verified.txt](evidence/order-editor-verified.txt) |
| Ancien éditeur : persistance et cycle révisionné | 24 tests réussis — [io-editor-atomic-final.txt](evidence/io-editor-atomic-final.txt) |
| Ancien éditeur : historique et traits extraits | 26 tests réussis — [m1-controller-history-regression.txt](evidence/m1-controller-history-regression.txt) |
| Studio : contrôleur et commandes | 22 tests réussis — [m1-controller-complete.txt](evidence/m1-controller-complete.txt) |
| IO réel et manifeste changé | 16 tests réussis — [m1-manifest-revision-green.txt](evidence/m1-manifest-revision-green.txt) |
| Renderer partagé : ordre réellement peint | 12 tests réussis — [runtime-render-order.txt](evidence/runtime-render-order.txt) |
| Runtime : occlusion personnage et rendu | 21 tests réussis — [runtime-actor-occlusion-final.txt](evidence/runtime-actor-occlusion-final.txt) |
| Ressources Studio et vrai playtest | 8 tests réussis — [studio-render-playtest-final.txt](evidence/studio-render-playtest-final.txt) |
| Navigation concurrente et parcours widgets | 6 tests réussis — [runtime-navigation-regression.txt](evidence/runtime-navigation-regression.txt), inclus ensuite dans les 124 |
| Analyses partagées ciblées | Aucune issue : `order-source-analyze-verified`, `order-editor-analyze`, `io-authoring-analyze-final`, `io-editor-extraction-analyze`, `renderer-analysis` |
| MCP : vérification TypeScript et build | Codes 0 — [order-mcp-check.txt](evidence/order-mcp-check.txt), [order-mcp-build.txt](evidence/order-mcp-build.txt) |
| MCP : suite de transport | `tests 80`, `pass 80`, `fail 0`, `skipped 0` — [order-mcp-tests.txt](evidence/order-mcp-tests.txt) |

Les tests de persistance simulent des échecs après flush temporaire, préparation du journal et avant second CAS ; ils vérifient les octets et la reprise. Le playtest charge le projet d’exemple depuis le disque, instancie le vrai GameWidget et PlayableMapGame, puis prouve le déplacement de (8, 9) à (9, 9), l’isolation des sauvegardes et la pause à la destruction.

Deux échecs de registre préexistants subsistent dans une suite authoring élargie : `regionalMap` existe déjà dans le registre mais manque dans la liste attendue, et `element` est attendu sans être enregistré. Résultat : 10 réussites, 2 échecs dans [order-authoring-verified.txt](evidence/order-authoring-verified.txt). Les fichiers et attentes étaient inchangés à HEAD, vérifié dans [order-registry-baseline-verified.txt](evidence/order-registry-baseline-verified.txt). Ces défauts ne sont pas corrigés hors périmètre et la suite authoring globale n’est pas déclarée verte.

Le catalogue MCP vivant n’a pas pu être interrogé : `worker.exited`, code 78, voir [mcp-live.txt](evidence/mcp-live.txt). La découverte déclarative et les transports construits sont testés ; l’instance MCP connectée reste une réserve distincte, sans réparation de serveur hors mission.

## Recette native et exemple

Le lancement suivi `flutter run -d macos --no-pub` a compilé et ouvert la nouvelle application, avec service VM actif. Le pilote UI renvoyait cependant l’ancienne fenêtre et son ancien texte « Lecture seule ». Il ne permettait pas de choisir le processus M1. Aucun projet n’a été ouvert dans cette ancienne instance.

Le processus utilisateur existant a été laissé intact. Seul le processus natif lancé pour cette mission a été arrêté après contrôle de son identité, heure de démarrage et chaîne parentale. Le message final `Lost connection to device` suit cet arrêt volontaire : ce n’est ni une preuve de crash spontané ni une preuve de fermeture utilisateur normale. Voir [native-ui-observation.txt](evidence/native-ui-observation.txt), [native-run.txt](evidence/native-run.txt), [native-stop.txt](evidence/native-stop.txt).

Pour reproduire avec le Dart du SDK Flutter :

```sh
cd apps/avelune_studio
flutter pub get
dart run tool/create_example_project.dart
flutter run -d macos --no-pub
```

Choisir avec Parcourir le nouveau dossier imprimé. Le générateur refuse une cible existante ; il fournit deux cartes, un atlas original, trois décors et un personnage. Il n’utilise aucun projet personnel. SDK utilisé : Flutter 3.48.0-0.4.pre, Dart embarqué 3.14.0-95.2.beta, macOS arm64.

## Passes et critique finale

| Passe / responsable | Verdict |
| --- | --- |
| Audit / architecture, root et trois agents | Réemploi faisable par extractions limitées et wrapper public ; éviter une dépendance à map_editor |
| Implémentation IO, `m1_document_io` | Sauvegarde atomique, non-perte et protection de révision prouvées ; tests rouges puis verts pour saveAll et manifeste externe |
| Implémentation ordre, `m1_visual_order` | Même ordre core/editor/runtime, sans régression de priorité métier ; réserves registre et MCP vivant explicites |
| Implémentation rendu, `m1_render` | Vrais renderer/ressources/runtime réutilisés ; pixels, occlusion et déplacement testés |
| Intégration / tests, root | Parcours complet en widgets, erreurs et retours couverts ; 124 tests Studio verts |
| Build / validation, root | Analyse finale propre ; compilation native et lancement observés ; réserve de pilotage natif |
| Critique finale, agents rendu/ordre et root | Corrections intégrées : gomme de couche visible, libellé après navigation refusée, classement nouveau décor, carte active pendant test, conservation dirty en saveAll, manifeste revérifié |

Auto-critique : cette livraison fournit un parcours implémenté et des preuves concrètes par couche, mais ne remplace pas la recette manuelle native ni une validation artistique. La projection Studio reste statique à la première frame des animations. Les BorderLayer sont conservés avec avertissement dans Studio et chargés par le runtime ; leur aperçu complet n’est pas implémenté. La sélection suit les cellules, pas l’alpha pixel. L’ordre fixe ne remplace pas la profondeur dynamique du personnage. Aux extrémités, un pas d’ordre peut être sans effet.

La peinture simple ne remplace ni Smart Tile Studio ni l’import ou l’édition de bibliothèques. Sélection multiple, édition des autres familles, Player, narration, 3D et distribution restent hors périmètre. Les contrôles ciblés de l’ancien éditeur sont verts ; une certification exhaustive du monorepo n’a pas été exécutée. Les avertissements Swift provenant d’audioplayers_darwin sont conservés dans les logs de build.

AS-ARC-002-bis continue de refuser les chemins que le nettoyage partagé altérerait, avant la lecture du manifeste. Sa réserve native historique sur les espaces finaux reste non bloquante pour M1 et n’est pas présentée comme résolue ici.

Aucun statut Notion n’a été changé. La revue manuelle native et artistique demeure à faire ; aucun lot suivant n’a été lancé.

## Inventaire des sources et zones de changement

Chemins relatifs à la racine du dépôt. Les zones ci-dessous permettent la revue sans recopier les sources. Pour les fichiers préexistants, `git diff -- <chemin>` montre le diff canonique ; les nouveaux fichiers restent non indexés. Les journaux et reçus complémentaires sont inventoriés par l’état Git final.

| Fichier | Zones / points d’entrée |
| --- | --- |
| `apps/avelune_studio/README.md` | Fichier 87 lignes : configuration, sérialisation générée, tests, exemple ou documentation selon le chemin |
| `apps/avelune_studio/lib/main.dart` | `9: void main() {` |
| `apps/avelune_studio/lib/src/bootstrap/studio_app.dart` | `12: class StudioApp extends StatefulWidget {`; `33: class _StudioAppState extends State<StudioApp> {` |
| `apps/avelune_studio/lib/src/bootstrap/studio_workspace_host.dart` | `10: class StudioWorkspaceHost extends StatefulWidget {`; `24: class _StudioWorkspaceHostState extends State<StudioWorkspaceHost> {` |
| `apps/avelune_studio/lib/src/features/map_workspace/application/editable_map_document.dart` | `6: class EditableMapDocument {` |
| `apps/avelune_studio/lib/src/features/map_workspace/application/map_editing_commands.dart` | `5: class MapEditingCommands {` |
| `apps/avelune_studio/lib/src/features/map_workspace/application/map_workspace_controller.dart` | `7: class MapWorkspaceController {` |
| `apps/avelune_studio/lib/src/features/map_workspace/application/map_workspace_port.dart` | `5: class MapWorkspaceDocument {`; `30: enum MapWorkspaceProblem {`; `38: class MapWorkspaceFailure implements Exception {` |
| `apps/avelune_studio/lib/src/features/map_workspace/infrastructure/local_map_workspace_adapter.dart` | `13: final class LocalMapWorkspaceAdapter implements MapWorkspacePort {`; `226: class _ProjectDocument {` |
| `apps/avelune_studio/lib/src/features/map_workspace/infrastructure/map_document_retention.dart` | Fichier 25 lignes : configuration, sérialisation générée, tests, exemple ou documentation selon le chemin |
| `apps/avelune_studio/lib/src/features/map_workspace/presentation/map_canvas_overlay.dart` | `4: class MapCanvasOverlay extends CustomPainter {` |
| `apps/avelune_studio/lib/src/features/map_workspace/presentation/map_workspace_canvas.dart` | `14: class MapWorkspaceCanvas extends StatefulWidget {`; `34: class _MapWorkspaceCanvasState extends State<MapWorkspaceCanvas> {` |
| `apps/avelune_studio/lib/src/features/map_workspace/presentation/map_workspace_panels.dart` | `10: class MapWorkspacePalette extends StatefulWidget {`; `28: class _MapWorkspacePaletteState extends State<MapWorkspacePalette> {`; `100: class MapWorkspaceInspector extends StatelessWidget {` |
| `apps/avelune_studio/lib/src/features/map_workspace/presentation/map_workspace_screen.dart` | `16: typedef StudioRuntimeBuilder =`; `23: class MapWorkspaceScreen extends StatefulWidget {`; `41: class _MapWorkspaceScreenState extends State<MapWorkspaceScreen> {` |
| `apps/avelune_studio/lib/src/features/map_workspace/presentation/map_workspace_shortcuts.dart` | Fichier 62 lignes : configuration, sérialisation générée, tests, exemple ou documentation selon le chemin |
| `apps/avelune_studio/lib/src/features/map_workspace/presentation/map_workspace_toolbar.dart` | `8: class MapWorkspaceToolbar extends StatelessWidget {` |
| `apps/avelune_studio/lib/src/features/map_workspace/presentation/map_workspace_view_state.dart` | `4: enum StudioMapTool { select, place, paint, erase, pan }`; `6: class MapWorkspaceViewState {` |
| `apps/avelune_studio/lib/src/features/map_workspace/presentation/map_workspace_visuals.dart` | `13: typedef LoadWorkspaceVisuals =` |
| `apps/avelune_studio/lib/src/features/map_workspace/rendering/studio_map_resources.dart` | `18: final class StudioMapResources implements MapWorkspaceVisuals {` |
| `apps/avelune_studio/lib/src/features/map_workspace/rendering/studio_map_visual_widgets.dart` | `10: class StudioMapVisual extends StatefulWidget {`; `24: class _StudioMapVisualState extends State<StudioMapVisual> {`; `78: class _MissingResourcePainter extends CustomPainter {`; `124: class _MapPainter extends CustomPainter {`; `137: class StudioMapThumbnail extends StatelessWidget {`; `182: class _ThumbnailPainter extends CustomPainter {` |
| `apps/avelune_studio/lib/src/features/playtest/infrastructure/studio_playtest_view.dart` | `11: class StudioPlaytestView extends StatefulWidget {`; `31: class _StudioPlaytestViewState extends State<StudioPlaytestView> {`; `115: class StudioPlaytestSaveRepository implements GameSaveRepository {` |
| `apps/avelune_studio/lib/src/features/project_session/presentation/project_session_screen.dart` | `10: class ProjectSessionScreen extends StatefulWidget {`; `26: class _ProjectSessionScreenState extends State<ProjectSessionScreen> {` |
| `apps/avelune_studio/lib/src/shared/design_system/studio_surfaces.dart` | `3: class StudioShell extends StatelessWidget {`; `48: class StudioPanel extends StatelessWidget {`; `68: class StudioNotice extends StatelessWidget {` |
| `apps/avelune_studio/lib/src/shared/design_system/studio_workspace_controls.dart` | `3: class StudioTool extends StatelessWidget {`; `29: class StudioSidebar extends StatelessWidget {`; `43: class StudioChoice extends StatelessWidget {`; `70: Future<String?> confirmStudioClose(BuildContext context) => showDialog<String>(` |
| `apps/avelune_studio/macos/Flutter/GeneratedPluginRegistrant.swift` | Fichier 14 lignes : configuration, sérialisation générée, tests, exemple ou documentation selon le chemin |
| `apps/avelune_studio/macos/Runner/DebugProfile.entitlements` | Fichier 14 lignes : configuration, sérialisation générée, tests, exemple ou documentation selon le chemin |
| `apps/avelune_studio/macos/Runner/Release.entitlements` | Fichier 10 lignes : configuration, sérialisation générée, tests, exemple ou documentation selon le chemin |
| `apps/avelune_studio/pubspec.lock` | Fichier 697 lignes : configuration, sérialisation générée, tests, exemple ou documentation selon le chemin |
| `apps/avelune_studio/pubspec.yaml` | Fichier 34 lignes : configuration, sérialisation générée, tests, exemple ou documentation selon le chemin |
| `apps/avelune_studio/test/application/m1_controller_fixture.dart` | `21: class M1ControlledPort implements MapWorkspacePort {` |
| `apps/avelune_studio/test/application/m1_controller_test.dart` | `10: void main() {` |
| `apps/avelune_studio/test/application/m1_editing_test.dart` | `8: void main() {` |
| `apps/avelune_studio/test/architecture/architecture_boundaries_test.dart` | `8: void main() {` |
| `apps/avelune_studio/test/infrastructure/m1_manifest_revision_test.dart` | `14: void main() {` |
| `apps/avelune_studio/test/infrastructure/map_workspace_io_test.dart` | `11: void main() {` |
| `apps/avelune_studio/test/infrastructure/map_workspace_read_safety_test.dart` | `11: void main() {` |
| `apps/avelune_studio/test/infrastructure/studio_map_resources_test.dart` | `12: void main() {` |
| `apps/avelune_studio/test/infrastructure/studio_playtest_test.dart` | `15: void main() {`; `127: class _ChangedPort implements MapWorkspacePort {` |
| `apps/avelune_studio/test/presentation/map_workspace_journey_test.dart` | `13: void main() {` |
| `apps/avelune_studio/test/support/map_workspace_fixture.dart` | `42: MapData workspaceMap(String id) => MapData(`; `58: class WorkspaceMemoryPort implements MapWorkspacePort {`; `109: class WorkspaceTestVisuals implements MapWorkspaceVisuals {` |
| `apps/avelune_studio/tool/create_example_project.dart` | `9: Future<void> main(List<String> arguments) async {`; `38: Future<void> writeExampleProject(Directory directory) async {`; `144: MapData exampleMap(String id, String name, {bool alternate = false}) => MapData(` |
| `apps/avelune_studio/tool/example_project_assets.dart` | Fichier 40 lignes : configuration, sérialisation générée, tests, exemple ou documentation selon le chemin |
| `packages/map_authoring/lib/map_authoring_documents.dart` | `1: export 'src/documents/atomic_map_document_persistence.dart';`; `2: export 'src/documents/document_errors.dart';`; `3: export 'src/documents/map_document_codec.dart';`; `4: export 'src/documents/map_document_persistence.dart';`; `5: export 'src/documents/map_document_write_lock.dart';` |
| `packages/map_authoring/lib/map_authoring_editing.dart` | `1: export 'src/editing/map_cell_stroke_buffer.dart';`; `2: export 'src/editing/map_history_coordinator.dart';`; `3: export 'src/editing/map_history_delta.dart';`; `4: export 'src/editing/map_history_entry.dart';`; `5: export 'src/editing/map_history_snapshot.dart';` |
| `packages/map_authoring/lib/src/documents/atomic_map_document_persistence.dart` | `12: enum AtomicMapDocumentWriteCheckpoint {`; `21: final class AtomicMapDocumentWriteContext {`; `37: typedef AtomicMapDocumentFaultInjector = FutureOr<void> Function(`; `42: final class AtomicMapDocumentSimulatedCrash implements Exception {`; `46: final class AtomicMapDocumentBytes {`; `57: final class AtomicMapDocumentPersistence {`; `359: final class _MapDocumentWriteJournal {`; `442: typedef _MapDocumentArtifactPaths = ({`; `463: Future<void> _writeJournal(`; `475: Future<void> _writeFlushed(File file, List<int> bytes) async {`; `486: Future<AtomicMapDocumentBytes> _readRequired(String targetPath) async {`; `498: Future<String?> _currentRevision(String targetPath) async {` |
| `packages/map_authoring/lib/src/documents/document_errors.dart` | `1: sealed class EditorApplicationException implements Exception {`; `10: final class EditorValidationException extends EditorApplicationException {`; `14: final class EditorNotFoundException extends EditorApplicationException {`; `18: final class EditorConflictException extends EditorApplicationException {`; `22: final class EditorInvalidOperationException extends EditorApplicationException {`; `26: final class EditorMissingDependencyException`; `31: final class EditorPersistenceException extends EditorApplicationException {`; `35: final class NarrativeEventAuthoringSessionException`; `40: final class ProjectRecoveryRequiredException`; `52: final class ProjectRecoveryBlockedException extends EditorApplicationException {` |
| `packages/map_authoring/lib/src/documents/map_document_codec.dart` | `7: MapData decodeValidatedMapDocument(` |
| `packages/map_authoring/lib/src/documents/map_document_persistence.dart` | `15: sealed class MapDocumentWritePrecondition {`; `24: final class MapDocumentMustBeAbsent extends MapDocumentWritePrecondition {`; `28: final class MapDocumentMustMatchRevision extends MapDocumentWritePrecondition {`; `35: final class RevisionedMapDocument {`; `45: enum MapDocumentRecoveryStatus {`; `52: final class MapDocumentRecoveryResult {` |
| `packages/map_authoring/lib/src/documents/map_document_write_lock.dart` | `12: Future<T> withMapDocumentWriteLock<T>(`; `51: Future<String> canonicalMapDocumentPath(String mapPath) async {` |
| `packages/map_authoring/lib/src/domains/maps/placed_element_actions.dart` | `9: final class PlacedElementActions {`; `386: List<MapPlacedElement> _instances(List<Object?> raw) {`; `449: MapData _replaceFromJsonPatch(` |
| `packages/map_authoring/lib/src/editing/map_cell_stroke_buffer.dart` | `3: enum MapCellStrokeLayerKind { tile, collision, smartTile }`; `5: final class MapCellStrokeBuffer {` |
| `packages/map_authoring/lib/src/editing/map_history_coordinator.dart` | `11: class MapHistoryMutationResult {`; `26: class MapHistoryStrokeFinalizeResult extends MapHistoryMutationResult {`; `37: class MapHistoryRestoreResult extends MapHistoryMutationResult {`; `48: class MapHistoryCoordinator {` |
| `packages/map_authoring/lib/src/editing/map_history_delta.dart` | `5: enum MapHistoryDirection { backward, forward }`; `7: final class MapHistoryDivergence implements Exception {`; `13: final class MapHistoryDelta {`; `205: final class _ValueDelta<T> {`; `231: final class _SparseListDelta<T> implements _ReversibleListDelta<T> {`; `285: final class _ListSliceDelta<T> implements _ReversibleListDelta<T> {`; `344: final class _MapLayersDelta {`; `441: final class _TileLayerDelta implements _MapLayerDelta {`; `483: final class _CollisionLayerDelta implements _MapLayerDelta {`; `527: final class _SmartTileLayerDelta implements _MapLayerDelta {`; `576: final class _ReplacementLayerDelta implements _MapLayerDelta {`; `601: final class _SmartTileFieldDelta {` |
| `packages/map_authoring/lib/src/editing/map_history_entry.dart` | `17: final class MapHistorySelection {`; `38: final class MapHistoryCheckpoint {`; `69: final class MapHistoryDeltaEntry implements MapHistoryEntry {` |
| `packages/map_authoring/lib/src/editing/map_history_snapshot.dart` | `10: abstract class MapHistorySnapshot` |
| `packages/map_authoring/lib/src/editing/map_history_snapshot.freezed.dart` | `15: mixin _$MapHistorySnapshot {`; `44: abstract mixin class $MapHistorySnapshotCopyWith<$Res>  {`; `56: class _$MapHistorySnapshotCopyWithImpl<$Res>`; `226: class _MapHistorySnapshot extends MapHistorySnapshot {`; `267: abstract mixin class _$MapHistorySnapshotCopyWith<$Res> implements $MapHistorySnapshotCopyWith<$Res> {`; `279: class __$MapHistorySnapshotCopyWithImpl<$Res>` |
| `packages/map_authoring/pubspec.yaml` | Fichier 26 lignes : configuration, sérialisation générée, tests, exemple ou documentation selon le chemin |
| `packages/map_authoring/test/domains/maps/placed_element_visual_order_actions_test.dart` | `8: void main() {`; `119: Future<AuthoringResult> _call(JsonlWorker worker, String command,` |
| `packages/map_core/lib/map_core.dart` | `1: export 'map_core_domain.dart';`; `2: export 'src/operations/tiled_map_import.dart';`; `3: export 'src/operations/tiled_map_compilation.dart';` |
| `packages/map_core/lib/map_core_domain.dart` | `3: export 'src/encounters/encounter_contract.dart';`; `5: export 'src/runtime/character_custom_animation_runtime_contract.dart';`; `6: export 'src/runtime/cinematic_character_custom_animation_contract.dart';`; `8: export 'src/localization/localized_names.dart';`; `9: export 'src/localization/project_locale_resolver.dart';`; `10: export 'src/models/narrative_validation_report.dart';`; `11: export 'src/models/narrative_diagnostic_suppression.dart';`; `12: export 'src/models/narrative_runtime_smoke_receipt.dart';`; `13: export 'src/models/mvp_release_evidence_receipt.dart';`; `14: export 'src/operations/narrative_project_fingerprint.dart';`; `15: export 'src/operations/narrative_validation_report_codec.dart';`; `17: export 'src/models/enums.dart';` |
| `packages/map_core/lib/src/models/map_data.dart` | `24: abstract class MapData with _$MapData {`; `174: abstract class MapGameplayZone with _$MapGameplayZone {`; `221: abstract class MapPlacedElement with _$MapPlacedElement {`; `256: enum MapPlacedElementTriggerType {`; `269: enum MapPlacedElementTriggerScope {`; `283: abstract class MapPlacedElementBehavior with _$MapPlacedElementBehavior {`; `300: enum MapPlacedElementEffectType {`; `314: abstract class MapPlacedElementEffect with _$MapPlacedElementEffect {`; `330: abstract class MapPlacedElementAnimation with _$MapPlacedElementAnimation {`; `347: abstract class MapEntity with _$MapEntity {`; `427: abstract class MapWarp with _$MapWarp {`; `443: enum MapWarpTriggerMode {` |
| `packages/map_core/lib/src/models/map_data.freezed.dart` | `16: mixin _$MapData {`; `49: abstract mixin class $MapDataCopyWith<$Res>  {`; `61: class _$MapDataCopyWithImpl<$Res>`; `246: class _MapData implements MapData {`; `354: abstract mixin class _$MapDataCopyWith<$Res> implements $MapDataCopyWith<$Res> {`; `366: class __$MapDataCopyWithImpl<$Res>`; `420: mixin _$MapGameplayZone {`; `457: abstract mixin class $MapGameplayZoneCopyWith<$Res>  {`; `469: class _$MapGameplayZoneCopyWithImpl<$Res>`; `700: class _MapGameplayZone implements MapGameplayZone {`; `751: abstract mixin class _$MapGameplayZoneCopyWith<$Res> implements $MapGameplayZoneCopyWith<$Res> {`; `763: class __$MapGameplayZoneCopyWithImpl<$Res>` |
| `packages/map_core/lib/src/models/map_data.g.dart` | Fichier 497 lignes : configuration, sérialisation générée, tests, exemple ou documentation selon le chemin |
| `packages/map_core/lib/src/operations/map_placed_element_visual_order.dart` | `9: List<MapPlacedElement> sortMapPlacedElementsForPainting(`; `20: List<MapPlacedElement> mapPlacedElementsAt(`; `83: MapData moveMapPlacedElementVisualOrder(` |
| `packages/map_core/test/placed_element_visual_order_test.dart` | `4: void main() {`; `265: MapData _map() => MapData(` |
| `packages/map_editor/lib/src/application/errors/application_errors.dart` | `1: export 'package:map_authoring/map_authoring_documents.dart';` |
| `packages/map_editor/lib/src/application/models/map_history_delta.dart` | `1: export 'package:map_authoring/map_authoring_editing.dart';` |
| `packages/map_editor/lib/src/application/models/map_history_entry.dart` | `1: export 'package:map_authoring/map_authoring_editing.dart';` |
| `packages/map_editor/lib/src/application/models/map_history_snapshot.dart` | `1: export 'package:map_authoring/map_authoring_editing.dart';` |
| `packages/map_editor/lib/src/application/models/map_history_snapshot.freezed.dart` | Supprimé à l’ancien emplacement ; modèle généré déplacé dans map_authoring |
| `packages/map_editor/lib/src/application/models/narrative_event_authoring_session.dart` | `10: final class NarrativeEventAuthoringSession {`; `190: final class ValidatedNarrativeEventAuthoringProject {`; `235: MapData decodeValidatedNarrativeEventAuthoringMap(` |
| `packages/map_editor/lib/src/application/services/environment_generated_placement_hover_resolver.dart` | `3: final class EnvironmentGeneratedPlacementAddPreview {`; `19: final class EnvironmentGeneratedPlacementDeleteTarget {`; `319: final class _EnvironmentGeneratedPlacementAddSelection {` |
| `packages/map_editor/lib/src/application/services/map_cell_stroke_buffer.dart` | `1: export 'package:map_authoring/map_authoring_editing.dart';` |
| `packages/map_editor/lib/src/application/services/map_history_coordinator.dart` | `1: export 'package:map_authoring/map_authoring_editing.dart';` |
| `packages/map_editor/lib/src/domain/models/map_document_persistence.dart` | `1: export 'package:map_authoring/map_authoring_documents.dart';` |
| `packages/map_editor/lib/src/features/editor/application/map_canvas_object_hit_test.dart` | `6: enum MapCanvasObjectKind {`; `16: final class MapCanvasObjectTarget {`; `116: final class MapCanvasObjectHitTest {` |
| `packages/map_editor/lib/src/infrastructure/repositories/atomic_map_document_persistence.dart` | `1: export 'package:map_authoring/map_authoring_documents.dart';` |
| `packages/map_editor/lib/src/infrastructure/repositories/map_document_write_lock.dart` | `1: export 'package:map_authoring/map_authoring_documents.dart';` |
| `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart` | `3: enum _EditorMapTileRenderPass { background, foreground }`; `10: final class _EditorObjectVisualIndexCache {`; `28: final class _EditorPatternOwnerIndexCache {`; `200: final class EnvironmentMaskBrushCursorOverlay {`; `225: final class EditorMapVisibleCellBounds {`; `310: final class MapGridCullingDebugSnapshot {`; `350: typedef MapGridCullingDebugObserver =`; `353: final class _MapGridCullingDebugCounter {`; `369: typedef MapGridPaintObserver = void Function();`; `375: class MapGridPainter extends CustomPainter {` |
| `packages/map_editor/test/features/editor/application/map_canvas_object_hit_test_test.dart` | `5: void main() {` |
| `packages/map_editor/test/map_grid_painter_layer_order_test.dart` | `8: void main() {`; `190: Future<ui.Color> _paintOverlappingLayers({`; `239: Future<ui.Color> _paintMap(MapData map) async {`; `301: Future<ui.Image> _twoColorTileset() async {`; `318: Future<ui.Color> _paintLayerAgainstEntity(` |
| `packages/map_gameplay/test/placed_element_visual_order_gameplay_test.dart` | `5: void main() {` |
| `packages/map_runtime/lib/map_runtime_authoring.dart` | `3: export 'src/application/authoring_preview/runtime_authoring_map_renderer.dart';`; `4: export 'src/application/load_runtime_map_bundle.dart'`; `6: export 'src/infrastructure/runtime_tileset_image.dart';`; `7: export 'src/infrastructure/tile_image_loader.dart'` |
| `packages/map_runtime/lib/src/application/authoring_preview/runtime_authoring_map_renderer.dart` | `8: final class RuntimeAuthoringMapRenderer {` |
| `packages/map_runtime/lib/src/infrastructure/tile_image_loader.dart` | `12: typedef RuntimeTilesetImageBatchLoader`; `17: typedef RuntimeUiImageDecoder = Future<ui.Image> Function(Uint8List bytes);`; `18: typedef RuntimeTilesetImageFileLoader = Future<RuntimeTilesetImage> Function(`; `22: typedef RuntimeTilesetImageLoadProgressSink = void Function(`; `27: final class RuntimeTilesetImageSingleFlightCache {`; `205: final class _RuntimeTilesetImageLoadSlot {`; `219: final class _RuntimeTilesetImageCacheKey {`; `240: Future<ui.Image> loadImageFromFilePath(String absolutePath) async {`; `250: Future<ui.Image> decodeFirstFrameAndDispose(ui.Codec codec) async {`; `259: Future<List<ui.Image>> decodeRuntimeTilesetChunks(`; `277: Future<RuntimeTilesetImage> decodeRuntimeTilesetImage(`; `282: Future<RuntimeTilesetImage> loadTilesetImageFromFilePath(` |
| `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart` | `25: enum MapLayerRenderPass {`; `49: final class MapLayersRenderProfile {`; `95: typedef MapLayersRenderProfileObserver = void Function(`; `99: final class _MapLayersRenderCounter {`; `111: class MapLayersComponent extends PositionComponent {`; `1878: final class _RuntimeSpatialIndex<T> {`; `1969: class _RuntimeAnimationFrame {`; `1981: class _AnimatedPlacedCell {`; `2003: class _AnimatedPlacedInstanceSpec {`; `2013: class _ActiveOneShotAnimation {` |
| `packages/map_runtime/test/runtime_authoring_map_renderer_order_test.dart` | `11: void main() {`; `141: Future<ui.Image> _paint(void Function(Canvas) paint, {int height = 32}) async {` |

## État final

Compilation finale : `flutter build macos --debug --no-pub`, code 0, `✓ Built build/macos/Build/Products/Debug/Avelune Studio.app` — [build-delivery.txt](evidence/build-delivery.txt). Deux services Xcode `ibtoold` apparaissent dans le reçu ; ils ne sont pas des harnesses de test et n’ont pas été arrêtés arbitrairement.

Format Studio : `dart format --output=none --set-exit-if-changed lib test tool/create_example_project.dart tool/example_project_assets.dart`, code 0, `Formatted 55 files (0 changed) in 0.12 seconds.` — [format-delivery.txt](evidence/format-delivery.txt).

Hygiène Markdown : `POKEMAP_MARKDOWN_MAX_NEW=1 bash tools/scripts/check_markdown_hygiene.sh`, code 0, `Markdown hygiene: 1 new Markdown file(s), all in canonical locations.` — [markdown-delivery.txt](evidence/markdown-delivery.txt). Le budget d’un document correspond au rapport consolidé demandé.

État final : même branche `main` et même HEAD `881e3cbe5bae8c54cca14c3c0d9df44db2196961`, index vide de changements. 35 fichiers suivis modifiés, un fichier généré supprimé de son ancien emplacement, 51 nouveaux fichiers de source/configuration/tests, ce rapport et ses preuves non indexés. `git diff --check` ne signale aucune erreur. Voir [final-git.txt](evidence/final-git.txt) pour la liste complète, les statistiques et les contrôles de révision/index. Les statistiques Git des seuls fichiers suivis montrent les suppressions dues aux extractions ; les destinations nouvelles restent non suivies et figurent dans l’inventaire.

Les fichiers de preuves sont nouveaux sous ce seul dossier M1 ; les rapports des lots précédents restent inchangés. Aucun commit, push, staging, reset ou autre écriture Git n’a été exécuté.
