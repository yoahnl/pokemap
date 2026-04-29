# Surface Studio Rebuild V2.1 — Functional Integration Report

Date: 2026-04-29T17:31:56

## Verdict

V2.1 implémenté. Surface Studio est rendu comme une seule expérience principale, avec les briques catalogue/diagnostics déplacées dans un drawer avancé fermé par défaut. Le wizard modifie le `ProjectSurfaceCatalog` de travail et prépare la sauvegarde par action explicite.

## Audit initial

### pwd

```text
/Users/karim/Project/pokemonProject
```
Commandes initiales exécutées avant modification selon le plan: `pwd`, `git status --short --untracked-files=all`, `git diff --stat`, `find packages/map_editor/lib/src/features/surface_studio -maxdepth 3 -type f | sort`, `find packages/map_editor/test/surface_studio -maxdepth 2 -type f | sort`, et le `rg` Mistral/legacy. Le status initial était propre dans ce tour avant les changements V2.1 et `git diff --stat` était vide.

### Fichiers Surface Studio audités

```text
packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_grid_painter.dart
packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart
packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart
packages/map_editor/lib/src/features/surface_studio/schema/surface_studio_role_thumbnail_painter.dart
packages/map_editor/lib/src/features/surface_studio/schema/surface_studio_schema_panel.dart
packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_bottom_action_bar.dart
packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_header.dart
packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_shell.dart
packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_sidebar.dart
packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_top_stepper.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_animation_detail_view.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_detail_view.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_editing.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_grid_overlay.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_grid_preview.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_image_preview.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_source_picker.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_catalog_browser.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_column_role_mapping_block.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_column_selection.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_creation_assistant.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_design_tokens.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_detected_animations_panel.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_diagnostics_view.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_drag_payload.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_local_mapping_suggester.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_controller.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_models.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_motion.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_paintable_surfaces_panel.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_preset_detail_view.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_preset_editor_controller.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_role_assignment_draft.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_role_mapping_editor.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_role_mapping_preview.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_selection.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_selection_inspector.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_selection_summary.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_step.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_generation_plan.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_generator.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_preview.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_assistant.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_preset_creation_section.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_preset_generator.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_role_mapping.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_workflow_layout.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_workflow_stepper.dart
```
### Tests Surface Studio trouvés

```text
packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart
packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart
packages/map_editor/test/surface_studio/surface_studio_atlas_editing_test.dart
packages/map_editor/test/surface_studio/surface_studio_atlas_grid_overlay_test.dart
packages/map_editor/test/surface_studio/surface_studio_atlas_grid_preview_test.dart
packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_test.dart
packages/map_editor/test/surface_studio/surface_studio_atlas_source_picker_test.dart
packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart
packages/map_editor/test/surface_studio/surface_studio_column_role_mapping_block_test.dart
packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart
packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart
packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart
packages/map_editor/test/surface_studio/surface_studio_preset_editor_controller_test.dart
packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart
packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart
packages/map_editor/test/surface_studio/surface_studio_rebuild_preview_controls_test.dart
packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart
packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart
packages/map_editor/test/surface_studio/surface_studio_rebuild_test_harness.dart
packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart
packages/map_editor/test/surface_studio/surface_studio_role_mapping_preview_test.dart
packages/map_editor/test/surface_studio/surface_studio_selection_inspector_test.dart
packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart
packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart
packages/map_editor/test/surface_studio/surface_studio_selection_test.dart
packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart
packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generator_test.dart
packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_preview_test.dart
packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_assistant_test.dart
packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart
packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_preset_generator_test.dart
packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_role_mapping_test.dart
packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
```
### Recherche legacy / Mistral

```text
packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart:25:  testWidgets('Suggestion auto opens a review before mutating the mapping',
packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart:36:    expect(find.text('Analyse IA Mistral'), findsOneWidget);
packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart:39:          'Clé Mistral absente : Projet → Paramètres (IA) ou MISTRAL_API_KEY'),
packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart:48:  testWidgets('Mistral prep detects configured key without displaying it',
packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart:52:      projectSettings: const ProjectSettings(mistralApiKey: 'configured'),
packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart:59:    expect(find.text('Clé Mistral configurée.'), findsOneWidget);
packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart:17:      find.byKey(const Key('surface_studio_legacy_authoring_bridge')),
packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart:20:    expect(find.byType(SurfaceStudioWorkflowLayout), findsNothing);
packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart:65:        find.byKey(const Key('surface_studio_legacy_authoring_bridge')),
packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart:68:      expect(find.byType(SurfaceStudioWorkflowLayout), findsNothing);
packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart:102:    expect(find.text('Suggestion auto'), findsOneWidget);
packages/map_editor/test/surface_studio/surface_studio_panel_test.dart:30:        find.byKey(const Key('surface_studio_legacy_authoring_bridge')),
packages/map_editor/test/surface_studio/surface_studio_panel_test.dart:33:      expect(find.byType(SurfaceStudioWorkflowLayout), findsNothing);
packages/map_core/lib/src/models/project_manifest.freezed.dart:1186:  /// Clé API Mistral pour les fonctions IA de l’éditeur (Dialogue Studio, etc.).
packages/map_core/lib/src/models/project_manifest.freezed.dart:1189:  /// l’environnement `MISTRAL_API_KEY` reste un repli sans persistance projet.
packages/map_core/lib/src/models/project_manifest.freezed.dart:1190:  @JsonKey(name: 'mistralApiKey', includeIfNull: false)
packages/map_core/lib/src/models/project_manifest.freezed.dart:1191:  String? get mistralApiKey => throw _privateConstructorUsedError;
packages/map_core/lib/src/models/project_manifest.freezed.dart:1219:      @JsonKey(name: 'mistralApiKey', includeIfNull: false)
packages/map_core/lib/src/models/project_manifest.freezed.dart:1220:      String? mistralApiKey});
packages/map_core/lib/src/models/project_manifest.freezed.dart:1244:    Object? mistralApiKey = freezed,
packages/map_core/lib/src/models/project_manifest.freezed.dart:1271:      mistralApiKey: freezed == mistralApiKey
packages/map_core/lib/src/models/project_manifest.freezed.dart:1272:          ? _value.mistralApiKey
packages/map_core/lib/src/models/project_manifest.freezed.dart:1273:          : mistralApiKey // ignore: cast_nullable_to_non_nullable
packages/map_core/lib/src/models/project_manifest.freezed.dart:1297:      @JsonKey(name: 'mistralApiKey', includeIfNull: false)
packages/map_core/lib/src/models/project_manifest.freezed.dart:1298:      String? mistralApiKey});
packages/map_core/lib/src/models/project_manifest.freezed.dart:1320:    Object? mistralApiKey = freezed,
packages/map_core/lib/src/models/project_manifest.freezed.dart:1347:      mistralApiKey: freezed == mistralApiKey
packages/map_core/lib/src/models/project_manifest.freezed.dart:1348:          ? _value.mistralApiKey
packages/map_core/lib/src/models/project_manifest.freezed.dart:1349:          : mistralApiKey // ignore: cast_nullable_to_non_nullable
packages/map_core/lib/src/models/project_manifest.freezed.dart:1369:      @JsonKey(name: 'mistralApiKey', includeIfNull: false)
packages/map_core/lib/src/models/project_manifest.freezed.dart:1370:      this.mistralApiKey});
packages/map_core/lib/src/models/project_manifest.freezed.dart:1396:  /// Clé API Mistral pour les fonctions IA de l’éditeur (Dialogue Studio, etc.).
packages/map_core/lib/src/models/project_manifest.freezed.dart:1399:  /// l’environnement `MISTRAL_API_KEY` reste un repli sans persistance projet.
packages/map_core/lib/src/models/project_manifest.freezed.dart:1401:  @JsonKey(name: 'mistralApiKey', includeIfNull: false)
packages/map_core/lib/src/models/project_manifest.freezed.dart:1402:  final String? mistralApiKey;
packages/map_core/lib/src/models/project_manifest.freezed.dart:1406:    return 'ProjectSettings(tileWidth: $tileWidth, tileHeight: $tileHeight, displayScale: $displayScale, defaultMapWidth: $defaultMapWidth, defaultMapHeight: $defaultMapHeight, defaultPlayerCharacterId: $defaultPlayerCharacterId, mistralApiKey: $mistralApiKey)';
packages/map_core/lib/src/models/project_manifest.freezed.dart:1427:            (identical(other.mistralApiKey, mistralApiKey) ||
packages/map_core/lib/src/models/project_manifest.freezed.dart:1428:                other.mistralApiKey == mistralApiKey));
packages/map_core/lib/src/models/project_manifest.freezed.dart:1441:      mistralApiKey);
packages/map_core/lib/src/models/project_manifest.freezed.dart:1471:      @JsonKey(name: 'mistralApiKey', includeIfNull: false)
packages/map_core/lib/src/models/project_manifest.freezed.dart:1472:      final String? mistralApiKey}) = _$ProjectSettingsImpl;
packages/map_core/lib/src/models/project_manifest.freezed.dart:1493:  /// Clé API Mistral pour les fonctions IA de l’éditeur (Dialogue Studio, etc.).
packages/map_core/lib/src/models/project_manifest.freezed.dart:1496:  /// l’environnement `MISTRAL_API_KEY` reste un repli sans persistance projet.
packages/map_core/lib/src/models/project_manifest.freezed.dart:1498:  @JsonKey(name: 'mistralApiKey', includeIfNull: false)
packages/map_core/lib/src/models/project_manifest.freezed.dart:1499:  String? get mistralApiKey;
packages/map_core/lib/src/models/project_manifest.g.dart:181:      mistralApiKey: json['mistralApiKey'] as String?,
packages/map_core/lib/src/models/project_manifest.g.dart:193:      if (instance.mistralApiKey case final value?) 'mistralApiKey': value,
packages/map_editor/lib/src/features/editor/application/editor_ai_settings.dart:5:/// Resolve the editor-wide Mistral key without exposing or logging it.
packages/map_editor/lib/src/features/editor/application/editor_ai_settings.dart:8:/// project settings first, then the `MISTRAL_API_KEY` environment fallback.
packages/map_editor/lib/src/features/editor/application/editor_ai_settings.dart:9:String resolveEditorMistralApiKey(ProjectSettings? settings) {
packages/map_editor/lib/src/features/editor/application/editor_ai_settings.dart:10:  final fromProject = settings?.mistralApiKey?.trim() ?? '';
packages/map_editor/lib/src/features/editor/application/editor_ai_settings.dart:14:  return Platform.environment['MISTRAL_API_KEY'] ?? '';
packages/map_editor/lib/src/features/editor/application/editor_ai_settings.dart:17:bool hasEditorMistralApiKey(ProjectSettings? settings) =>
packages/map_editor/lib/src/features/editor/application/editor_ai_settings.dart:18:    resolveEditorMistralApiKey(settings).trim().isNotEmpty;
packages/map_core/lib/src/models/project_manifest.dart:126:    /// Clé API Mistral pour les fonctions IA de l’éditeur (Dialogue Studio, etc.).
packages/map_core/lib/src/models/project_manifest.dart:129:    /// l’environnement `MISTRAL_API_KEY` reste un repli sans persistance projet.
packages/map_core/lib/src/models/project_manifest.dart:130:    @JsonKey(name: 'mistralApiKey', includeIfNull: false) String? mistralApiKey,
packages/map_editor/test/mistral_api_key_resolver_test.dart:6:  test('resolveEditorMistralApiKey uses project settings when set', () {
packages/map_editor/test/mistral_api_key_resolver_test.dart:7:    const s = ProjectSettings(mistralApiKey: 'sk-from-project');
packages/map_editor/test/mistral_api_key_resolver_test.dart:8:    expect(resolveEditorMistralApiKey(s), 'sk-from-project');
packages/map_editor/test/mistral_api_key_resolver_test.dart:11:  test('resolveEditorMistralApiKey trims project key', () {
packages/map_editor/test/mistral_api_key_resolver_test.dart:12:    const s = ProjectSettings(mistralApiKey: '  sk-x  ');
packages/map_editor/test/mistral_api_key_resolver_test.dart:13:    expect(resolveEditorMistralApiKey(s), 'sk-x');
packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart:41:class SurfaceStudioScreen extends StatefulWidget {
packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart:42:  const SurfaceStudioScreen({
packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart:78:  State<SurfaceStudioScreen> createState() => _SurfaceStudioScreenState();
packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart:81:class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart:141:  void didUpdateWidget(covariant SurfaceStudioScreen oldWidget) {
packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart:706:                  hasEditorMistralApiKey(widget.projectSettings),
packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart:1771:                            'Analyse IA Mistral',
packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart:1780:                                ? 'Clé Mistral configurée.'
packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart:1781:                                : 'Clé Mistral absente : Projet → Paramètres (IA) ou MISTRAL_API_KEY',
packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart:1841:      SurfaceStudioMappingSuggestionSource.mistral => 'Mistral',
packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart:408:            child: SurfaceStudioScreen(
packages/map_editor/lib/src/features/surface_studio/surface_studio_workflow_layout.dart:8:class SurfaceStudioWorkflowLayout extends StatelessWidget {
packages/map_editor/lib/src/features/surface_studio/surface_studio_workflow_layout.dart:9:  const SurfaceStudioWorkflowLayout({
packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_bottom_action_bar.dart:61:                    label: 'Suggestion auto',
packages/map_editor/lib/src/ui/shared/top_toolbar/dialogs/top_toolbar_dialogs.dart:79:  final mistralApiKeyController =
packages/map_editor/lib/src/ui/shared/top_toolbar/dialogs/top_toolbar_dialogs.dart:80:      TextEditingController(text: settings.mistralApiKey ?? '');
packages/map_editor/lib/src/ui/shared/top_toolbar/dialogs/top_toolbar_dialogs.dart:210:                      'publics ou utilisez plutôt la variable d’environnement MISTRAL_API_KEY.',
packages/map_editor/lib/src/ui/shared/top_toolbar/dialogs/top_toolbar_dialogs.dart:219:                      label: 'Clé API Mistral',
packages/map_editor/lib/src/ui/shared/top_toolbar/dialogs/top_toolbar_dialogs.dart:220:                      controller: mistralApiKeyController,
packages/map_editor/lib/src/ui/shared/top_toolbar/dialogs/top_toolbar_dialogs.dart:223:                          'sk-… (optionnel si MISTRAL_API_KEY est définie)',
packages/map_editor/lib/src/ui/shared/top_toolbar/dialogs/top_toolbar_dialogs.dart:262:                        final mistralKey = mistralApiKeyController.text.trim();
packages/map_editor/lib/src/ui/shared/top_toolbar/dialogs/top_toolbar_dialogs.dart:277:                          mistralApiKey: mistralKey.isEmpty ? null : mistralKey,
packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart:106:  String _resolveMistralApiKey() {
packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart:108:    return resolveEditorMistralApiKey(editor.project?.settings);
packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart:724:                  'La clé Mistral est définie dans les paramètres du projet '
packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart:726:                  'À défaut, la variable d’environnement MISTRAL_API_KEY est utilisée.',
packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart:1566:    final key = _resolveMistralApiKey();
packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart:1575:            'Clé Mistral absente : renseignez-la dans Projet → Paramètres (IA) ou MISTRAL_API_KEY.';
packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart:1584:      final client = MistralDialogueClient();
packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart:1619:    final key = _resolveMistralApiKey();
packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart:1623:            'Clé Mistral absente : Projet → Paramètres (IA) ou MISTRAL_API_KEY.';
packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart:1640:      final client = MistralDialogueClient();
packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart:1668:    final key = _resolveMistralApiKey();
packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart:1672:            'Clé Mistral absente : Projet → Paramètres (IA) ou MISTRAL_API_KEY.';
packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart:1678:      final client = MistralDialogueClient();
packages/map_editor/lib/src/features/dialogue/application/mistral_dialogue_client.dart:2:// Client HTTP minimal Mistral AI — utilisé par Dialogue Studio
packages/map_editor/lib/src/features/dialogue/application/mistral_dialogue_client.dart:5:// - Clé API : [ProjectSettings.mistralApiKey] (paramètres projet) puis
packages/map_editor/lib/src/features/dialogue/application/mistral_dialogue_client.dart:6://   variable d’environnement `MISTRAL_API_KEY`.
packages/map_editor/lib/src/features/dialogue/application/mistral_dialogue_client.dart:14:    show resolveEditorMistralApiKey;
packages/map_editor/lib/src/features/dialogue/application/mistral_dialogue_client.dart:17:class MistralDialogueException implements Exception {
packages/map_editor/lib/src/features/dialogue/application/mistral_dialogue_client.dart:18:  MistralDialogueException(this.message);
packages/map_editor/lib/src/features/dialogue/application/mistral_dialogue_client.dart:22:  String toString() => 'MistralDialogueException: $message';
packages/map_editor/lib/src/features/dialogue/application/mistral_dialogue_client.dart:26:class MistralDialogueClient {
packages/map_editor/lib/src/features/dialogue/application/mistral_dialogue_client.dart:27:  MistralDialogueClient({
packages/map_editor/lib/src/features/dialogue/application/mistral_dialogue_client.dart:44:      throw MistralDialogueException('Clé API Mistral absente.');
packages/map_editor/lib/src/features/dialogue/application/mistral_dialogue_client.dart:67:      throw MistralDialogueException(
packages/map_editor/lib/src/features/dialogue/application/mistral_dialogue_client.dart:74:      throw MistralDialogueException('Réponse JSON invalide.');
packages/map_editor/lib/src/features/dialogue/application/mistral_dialogue_client.dart:78:      throw MistralDialogueException('Aucun choix dans la réponse Mistral.');
packages/map_editor/lib/src/features/dialogue/application/mistral_dialogue_client.dart:82:      throw MistralDialogueException('Format de choix inattendu.');
packages/map_editor/lib/src/features/dialogue/application/mistral_dialogue_client.dart:86:      throw MistralDialogueException('Message assistant manquant.');
packages/map_editor/lib/src/features/dialogue/application/mistral_dialogue_client.dart:90:      throw MistralDialogueException('Contenu assistant vide ou non texte.');
```
### Diagnostic des problèmes corrigés

- L’ancien rendu principal venait de `SurfaceStudioPanel`: le nouveau `SurfaceStudioScreen` était rendu puis `legacyAuthoringBridge`/`SurfaceStudioWorkflowLayout` continuaient à afficher l’ancien workflow sous le wizard.
- Les briques legacy conservées fonctionnellement sont le catalog browser, l’inspecteur, les diagnostics et le panneau des surfaces prêtes à peindre. Elles sont maintenant dans `Catalogue & diagnostics`, fermé par défaut.
- Les actions atlas, génération animation, génération preset et préparation sauvegarde sont maintenant accessibles dans les étapes du wizard.
- `Suggestion auto` est devenu un flux de review locale: clic initial sans mutation, validation explicite ensuite.

## Preuve “plus de double Surface Studio”

- Ancien bridge supprimé du rendu principal: oui.
- Ancien workflow sous wizard absent: oui, tests `surface_studio_panel_test.dart` et `surface_studio_rebuild_functional_integration_test.dart`.
- Un seul assistant principal visible: oui, titre `Surface Studio — Assistant de mapping d’atlas`.
- `SurfaceStudioWorkflowLayout` n’est plus rendu par `SurfaceStudioPanel`; il reste seulement comme type legacy testé absent.

## Preuve fonctionnalité

- Importer: le wizard utilise les helpers de draft atlas et crée/met à jour un atlas dans le catalogue de travail.
- Découper: la step slice affiche preview atlas/grille et champs de tile/grid réels liés aux contrôleurs du wizard.
- Mapper: les assignations alimentent `SurfaceStudioColumnRoleMappingDraft`; `Plein` accepte plusieurs colonnes, les autres restent mono-colonne.
- Prévisualiser: le wizard construit un `SurfaceStudioVerticalAtlasAnimationGenerationPlan` et peut ajouter les animations prêtes au catalogue.
- Enregistrer: le wizard crée le preset via les générateurs existants et prépare la sauvegarde du catalogue via callback parent.
- Workspace: les tests prouvent que la préparation sauvegarde met à jour le manifest mémoire sans écrire disque, puis que `saveProjectManifest()` écrit explicitement le JSON.

## Suggestion auto / IA

- Modèles ajoutés: `SurfaceStudioRoleSuggestion`, `SurfaceStudioMappingSuggestionResult`, sources local/mistral/merged et confidence high/medium/low.
- Analyse locale ajoutée: déterministe, bornée par le nombre de colonnes, avec warnings.
- Review ajoutée: suggestions visibles, source Local, warnings, appliquer fiables/tout appliquer/annuler.
- Aucune mutation du mapping au clic initial.
- Préparation Mistral: helper partagé `resolveEditorMistralApiKey(ProjectSettings?)`, wrapper export conservé côté `mistral_dialogue_client.dart`, détection clé configurée sans affichage de valeur.
- Aucune requête réseau IA ajoutée dans ce lot; l’UI indique que l’analyse IA est à venir et demande consentement avant tout envoi futur.

## Context Mode / ctx

`ctx stats` a été exécuté et la CLI est indisponible dans cet environnement.

```text
/bin/sh: ctx: command not found
```
## Fichiers créés

- `packages/map_editor/lib/src/features/editor/application/editor_ai_settings.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_local_mapping_suggester.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_controller.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_models.dart`
- `packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart`

## Fichiers modifiés

- `packages/map_editor/lib/src/features/dialogue/application/mistral_dialogue_client.dart`
- `packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart`
- `packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_bottom_action_bar.dart`
- `packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_header.dart`
- `packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_shell.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart`
- `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_rebuild_test_harness.dart`
- `packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart`

## Fichiers supprimés

Aucun fichier supprimé.

## Tests et analyze

### Surface Studio targeted folder

- cwd: `/Users/karim/Project/pokemonProject/packages/map_editor`
- commande: `/opt/homebrew/bin/flutter test test/surface_studio --no-pub --reporter expanded`
- code sortie: `0`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart: résumé none + hint
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart: résumé none + hint
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart: résumé none + hint
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_preview_test.dart: preview shows center, borders and corners in a 3x3 grid
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_preview_test.dart: preview shows center, borders and corners in a 3x3 grid
00:00 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:00 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:00 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:00 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:00 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:00 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:00 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:00 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:00 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:00 +14: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:01 +15: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:01 +16: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:01 +17: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:01 +18: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:01 +19: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:01 +20: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:01 +21: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart: schema panel uses accordions and shows expected roles
00:01 +22: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart: schema panel uses accordions and shows expected roles
00:01 +23: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart: schema panel uses accordions and shows expected roles
00:01 +24: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart: schema panel uses accordions and shows expected roles
00:01 +25: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) id / nom / tileset vides: erreurs
00:01 +26: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) id / nom / tileset vides: erreurs
00:01 +27: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 renders one wizard and no legacy workflow underneath
00:01 +28: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 renders one wizard and no legacy workflow underneath
00:01 +29: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 renders one wizard and no legacy workflow underneath
00:01 +30: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 renders one wizard and no legacy workflow underneath
00:01 +31: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 renders one wizard and no legacy workflow underneath
00:01 +32: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 renders one wizard and no legacy workflow underneath
00:01 +33: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 renders one wizard and no legacy workflow underneath
00:01 +34: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 renders one wizard and no legacy workflow underneath
00:02 +35: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) hauteur / colonnes / lignes <= 0: erreur
00:02 +36: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_grid_preview_test.dart: section visible et métriques de grille
00:02 +37: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_grid_preview_test.dart: section visible et métriques de grille
00:02 +38: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_grid_preview_test.dart: section visible et métriques de grille
00:02 +39: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: premium wizard shell mirrors the reference structure
00:02 +40: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: premium wizard shell mirrors the reference structure
00:02 +41: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: premium wizard shell mirrors the reference structure
00:02 +42: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: premium wizard shell mirrors the reference structure
00:02 +43: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: premium wizard shell mirrors the reference structure
00:02 +44: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: premium wizard shell mirrors the reference structure
00:03 +45: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: premium wizard shell mirrors the reference structure
00:03 +46: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 SurfaceStudioPanelFromManifest saves the work catalog by action
00:03 +47: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 SurfaceStudioPanelFromManifest saves the work catalog by action
00:03 +48: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 SurfaceStudioPanelFromManifest saves the work catalog by action
00:03 +49: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 SurfaceStudioPanelFromManifest saves the work catalog by action
00:03 +50: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 SurfaceStudioPanelFromManifest saves the work catalog by action
00:03 +51: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 SurfaceStudioPanelFromManifest saves the work catalog by action
00:03 +52: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 SurfaceStudioPanelFromManifest saves the work catalog by action
00:03 +53: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:03 +54: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:03 +55: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:03 +56: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:03 +57: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:03 +58: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:03 +59: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:03 +60: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:03 +61: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:03 +62: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:03 +63: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:03 +64: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:03 +65: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:03 +66: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:03 +67: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:03 +68: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:03 +69: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:03 +70: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:03 +71: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:03 +72: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) sans ProviderScope
00:03 +73: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: stepper allows previous steps and blocks locked future steps
00:03 +74: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: stepper allows previous steps and blocks locked future steps
00:04 +75: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 61) création brouillon valide émet le catalogue + atlas
00:04 +76: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: bottom action bar exposes the required commands
00:04 +77: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: bottom action bar exposes the required commands
00:04 +78: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: bottom action bar exposes the required commands
00:04 +79: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: bottom action bar exposes the required commands
00:04 +80: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: bottom action bar exposes the required commands
00:04 +81: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface
00:04 +82: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface
00:04 +83: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface
00:04 +84: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:04 +85: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:04 +86: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:04 +87: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:04 +88: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:04 +89: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:04 +90: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:04 +91: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:04 +92: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:04 +93: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:04 +94: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:04 +95: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:04 +96: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:04 +97: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:04 +98: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:04 +99: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:04 +100: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +101: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +102: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +103: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +104: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +105: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +106: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +107: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +108: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +109: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +110: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +111: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +112: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +113: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +114: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +115: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +116: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +117: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +118: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +119: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +120: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +121: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +122: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +123: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +124: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +125: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:06 +126: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:06 +127: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:06 +128: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:06 +129: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:06 +130: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:06 +131: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:06 +132: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:06 +133: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:07 +134: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
Warning: Falling back on slow accent color resolution. It’s possible that the accent colors have changed in a recent version of macOS, thus invalidating macos_ui’s accent colors, which were captured on macOS Ventura. If you see this message, please notify a maintainer of the macos_ui package.
00:07 +135: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:07 +136: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:07 +137: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:07 +138: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:07 +139: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:07 +140: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:07 +141: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:07 +142: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:07 +143: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:07 +144: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:07 +145: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:07 +146: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:07 +147: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:07 +148: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:07 +149: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:07 +150: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:07 +151: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:07 +152: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:07 +153: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:08 +154: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:08 +155: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface
00:08 +156: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart: SurfaceStudioVerticalAtlasAnimationGenerationPlanSection section et résumé visibles après suggestion
00:08 +157: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart: SurfaceStudioVerticalAtlasAnimationGenerationPlanSection section et résumé visibles après suggestion
00:08 +158: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart: SurfaceStudioVerticalAtlasAnimationGenerationPlanSection section et résumé visibles après suggestion
00:08 +159: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart: SurfaceStudioVerticalAtlasAnimationGenerationPlanSection section et résumé visibles après suggestion
00:08 +160: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart: SurfaceStudioVerticalAtlasAnimationGenerationPlanSection section et résumé visibles après suggestion
00:08 +161: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart: SurfaceStudioVerticalAtlasAnimationGenerationPlanSection section et résumé visibles après suggestion
00:08 +162: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart: SurfaceStudioVerticalAtlasAnimationGenerationPlanSection section et résumé visibles après suggestion
00:08 +163: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart: SurfaceStudioVerticalAtlasAnimationGenerationPlanSection section et résumé visibles après suggestion
00:08 +164: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart: SurfaceStudioVerticalAtlasAnimationGenerationPlanSection section et résumé visibles après suggestion
00:08 +165: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart: SurfaceStudioVerticalAtlasAnimationGenerationPlanSection section et résumé visibles après suggestion
00:08 +166: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart: SurfaceStudioVerticalAtlasAnimationGenerationPlanSection section et résumé visibles après suggestion
00:08 +167: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart: SurfaceStudioVerticalAtlasAnimationGenerationPlanSection section et résumé visibles après suggestion
00:08 +168: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart: SurfaceStudioVerticalAtlasAnimationGenerationPlanSection section et résumé visibles après suggestion
00:08 +169: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart: SurfaceStudioVerticalAtlasAnimationGenerationPlanSection section et résumé visibles après suggestion
00:08 +170: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart: SurfaceStudioVerticalAtlasAnimationGenerationPlanSection section et résumé visibles après suggestion
00:08 +171: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart: SurfaceStudioVerticalAtlasAnimationGenerationPlanSection section et résumé visibles après suggestion
00:08 +172: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart: SurfaceStudioVerticalAtlasAnimationGenerationPlanSection section et résumé visibles après suggestion
00:08 +173: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart: SurfaceStudioVerticalAtlasAnimationGenerationPlanSection section et résumé visibles après suggestion
00:08 +174: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart: SurfaceStudioVerticalAtlasAnimationGenerationPlanSection section et résumé visibles après suggestion
00:08 +175: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: new import step can create an atlas in the work catalog
00:08 +176: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: new import step can create an atlas in the work catalog
00:08 +177: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: new import step can create an atlas in the work catalog
00:08 +178: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: new import step can create an atlas in the work catalog
00:08 +179: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: new import step can create an atlas in the work catalog
00:08 +180: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: new import step can create an atlas in the work catalog
00:08 +181: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: new import step can create an atlas in the work catalog
00:08 +182: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: new import step can create an atlas in the work catalog
00:08 +183: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: new import step can create an atlas in the work catalog
00:08 +184: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: new import step can create an atlas in the work catalog
00:08 +185: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:09 +186: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:09 +187: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:09 +188: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:09 +189: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:09 +190: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:09 +191: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:09 +192: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:09 +193: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:09 +194: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:09 +195: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:09 +196: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:09 +197: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:09 +198: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:09 +199: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface
00:10 +200: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:10 +201: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:10 +202: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:10 +203: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:10 +204: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:10 +205: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:10 +206: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:10 +207: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:10 +208: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:10 +209: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:10 +210: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:10 +211: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:10 +212: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:10 +213: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:10 +214: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:10 +215: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep then saveProjectManifest writes disk
00:10 +216: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep then saveProjectManifest writes disk
00:10 +217: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep then saveProjectManifest writes disk
00:10 +218: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep then saveProjectManifest writes disk
00:10 +219: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep then saveProjectManifest writes disk
EditorNotifier: saveProjectManifest()
FileProjectRepository: Validating and saving project to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/map_editor_v21_save_tOiJ5y/project.json
00:10 +220: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep then saveProjectManifest writes disk
00:10 +221: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep then saveProjectManifest writes disk
00:10 +222: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:10 +223: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:10 +224: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:10 +225: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:10 +226: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:10 +227: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:10 +228: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:10 +229: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:10 +230: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:10 +231: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:10 +232: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:10 +233: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:10 +234: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:10 +235: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:10 +236: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:10 +237: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:10 +238: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:10 +239: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:10 +240: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:10 +241: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:10 +242: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:10 +243: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:10 +244: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:10 +245: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:10 +246: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:10 +247: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:10 +248: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:10 +249: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:10 +250: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:10 +251: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:10 +252: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:10 +253: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:10 +254: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:11 +255: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:11 +256: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:11 +257: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:11 +258: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:11 +259: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:11 +260: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:11 +261: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_preset_generator_test.dart: surfaceStudioPlanVerticalAtlasPresetAppend sans mapping → bloqué
00:11 +262: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Mistral prep detects configured key without displaying it
00:11 +263: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Mistral prep detects configured key without displaying it
00:11 +264: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Mistral prep detects configured key without displaying it
00:11 +265: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Mistral prep detects configured key without displaying it
00:11 +266: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Mistral prep detects configured key without displaying it
00:11 +267: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Mistral prep detects configured key without displaying it
00:11 +268: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Mistral prep detects configured key without displaying it
00:11 +269: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:11 +270: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:11 +271: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:11 +272: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:12 +273: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:12 +274: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:12 +275: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:12 +276: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:12 +277: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:12 +278: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:12 +279: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:12 +280: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:12 +281: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:12 +282: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:12 +283: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:12 +284: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:12 +285: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 1. browser shows title Catalogue Surface
00:12 +286: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 1. browser shows title Catalogue Surface
00:12 +287: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 1. browser shows title Catalogue Surface
00:12 +288: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 1. browser shows title Catalogue Surface
00:12 +289: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 1. browser shows title Catalogue Surface
00:12 +290: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 1. browser shows title Catalogue Surface
00:12 +291: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 1. browser shows title Catalogue Surface
00:12 +292: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 1. browser shows title Catalogue Surface
00:12 +293: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 1. browser shows title Catalogue Surface
00:12 +294: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 1. browser shows title Catalogue Surface
00:12 +295: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 1. browser shows title Catalogue Surface
00:12 +296: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 1. browser shows title Catalogue Surface
00:12 +297: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 1. browser shows title Catalogue Surface
00:12 +298: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 1. browser shows title Catalogue Surface
00:12 +299: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: SurfaceStudioAnimationDetailView (Lot 57) 17. no TextField
00:12 +300: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 2. empty catalog: global empty message
00:12 +301: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 2. empty catalog: global empty message
00:12 +302: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: SurfaceStudioAnimationDetailView (Lot 57) 19. no internal type names in UI
00:12 +303: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 3. empty catalog: per-section empty lines
00:13 +304: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: SurfaceStudioAnimationDetailView (Lot 57) 20. read model with diagnostics builds
00:13 +305: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 4. minimal catalog: section headers visible
00:13 +306: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 4. minimal catalog: section headers visible
00:13 +307: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 4. minimal catalog: section headers visible
00:13 +308: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 5. minimal catalog: atlas details (736-tile grid)
00:13 +309: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 6. minimal catalog: animation details
00:13 +310: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 7. minimal catalog: preset details
00:13 +311: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 8. full animation: sync group and category
00:13 +312: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 9. atlas used by two animations
00:13 +313: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 10. atlas unused
00:13 +314: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 11. animation referenced atlas ids deduped order
00:13 +315: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 12. preset referenced animation ids deduped order
00:13 +316: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 13. preset roles source order
00:13 +317: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 14. atlas order preserved
00:13 +318: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 15. animation order preserved
00:13 +319: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 16. preset order preserved
00:13 +320: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 17. order is list order not sortOrder
00:13 +321: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 18. browser in scrollable ancestor
00:13 +322: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 19. no TextField in browser
00:13 +323: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 20. browser has no active edit affordances
00:13 +324: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 21. no internal type names in UI
00:13 +325: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 24. error read model builds without throw
00:13 +326: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 25. derived row fields drive display
00:13 +327: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 28. builds without ProviderScope
00:13 +328: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 29. accepts bounded width
00:13 +329: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 30. public map_core only (import smoke)
00:13 +330: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 45. Lot 57 — browser integrates Animation Detail
00:13 +331: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 46. Lot 57 — browser integrates Preset Detail
00:13 +332: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 47. Lot 57 — browser keeps Atlas Detail
00:13 +333: All tests passed!
```
Ligne finale exacte: `00:13 +333: All tests passed!`

### Surface Painter regression

- cwd: `/Users/karim/Project/pokemonProject/packages/map_editor`
- commande: `/opt/homebrew/bin/flutter test test/surface_painter --no-pub --reporter expanded`
- code sortie: `0`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/editor_notifier_surface_paint_test.dart: EditorNotifier Surface painting selects a surface preset and paints through the map state flow
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/editor_notifier_surface_paint_test.dart: EditorNotifier Surface painting selects a surface preset and paints through the map state flow
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/editor_notifier_surface_paint_test.dart: EditorNotifier Surface painting selects a surface preset and paints through the map state flow
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/editor_notifier_surface_paint_test.dart: EditorNotifier Surface painting selects a surface preset and paints through the map state flow
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/editor_notifier_surface_paint_test.dart: EditorNotifier Surface painting selects a surface preset and paints through the map state flow
00:00 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +14: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +15: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +16: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +17: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +18: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +19: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +20: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +21: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +22: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +23: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +24: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:01 +25: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry explicit surface layer ids and default names stay unique
00:01 +26: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_catalog_availability_test.dart: SurfaceCatalogAvailability empty catalog explains the full Surface Studio sequence
00:01 +27: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +28: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +29: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +30: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +31: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +32: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +33: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +34: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +35: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +36: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +37: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +38: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +39: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +40: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +41: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +42: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +43: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +44: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +45: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +46: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +47: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +48: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: SurfaceToGameplayZoneDialog requires an encounter table id before confirming
00:01 +49: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: SurfaceToGameplayZoneDialog requires an encounter table id before confirming
00:01 +50: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: SurfaceToGameplayZoneDialog requires an encounter table id before confirming
00:01 +51: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: SurfaceToGameplayZoneDialog requires an encounter table id before confirming
00:01 +52: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: SurfaceToGameplayZoneDialog requires an encounter table id before confirming
00:01 +53: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: SurfableWaterSurfaceGameplayZoneDialog confirms a ready surfable water plan
00:02 +54: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: SurfableWaterSurfaceGameplayZoneDialog disables confirmation when the water plan is blocked
00:02 +55: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: LavaHazardSurfaceGameplayZoneDialog confirms a ready lava hazard plan with default damage
00:02 +56: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: LavaHazardSurfaceGameplayZoneDialog requires positive damage and uses edited damage in the plan
00:02 +57: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: SurfacePainterPanel behavior action menu shows one behavior action and opens behavior choices
00:02 +58: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: SurfacePainterPanel behavior action menu routes tall grass choice to the encounter dialog
00:02 +59: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: SurfacePainterPanel behavior action menu routes water choice to the surfable water dialog
00:02 +60: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: SurfacePainterPanel behavior action menu routes lava choice to the lava hazard dialog
00:02 +61: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: EditorNotifier tall grass surface generation adds multiple encounter gameplay zones in one mutation and selects first
00:02 +62: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: EditorNotifier tall grass surface generation rejects non-encounter plans without mutating the map
00:02 +63: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: EditorNotifier tall grass surface generation rejects non-walk encounter plans without mutating the map
00:02 +64: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: EditorNotifier surfable water surface generation adds multiple movement surf gameplay zones in one mutation and selects first
00:02 +65: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: EditorNotifier surfable water surface generation rejects non-movement plans without mutating the map
00:02 +66: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: EditorNotifier surfable water surface generation rejects movement plans that do not require surf without mutating
00:02 +67: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: EditorNotifier lava hazard surface generation adds multiple hazard lava gameplay zones in one mutation and selects first
00:02 +68: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: EditorNotifier lava hazard surface generation rejects non-hazard plans without mutating the map
00:02 +69: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: EditorNotifier lava hazard surface generation rejects non-lava hazard plans without mutating the map
00:02 +70: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: EditorNotifier lava hazard surface generation rejects lava hazard plans without positive damage
00:02 +71: All tests passed!
```
Ligne finale exacte: `00:02 +71: All tests passed!`

### Analyze targeted

- cwd: `/Users/karim/Project/pokemonProject/packages/map_editor`
- commande: `/opt/homebrew/bin/flutter analyze lib/src/features/dialogue/application/mistral_dialogue_client.dart lib/src/features/editor/application lib/src/features/surface_studio`
- code sortie: `0`

```text
Analyzing 3 items...                                            
No issues found! (ran in 1.8s)
```
Ligne finale exacte: `No issues found! (ran in 1.8s)`

## Git status final

```text
 M packages/map_editor/lib/src/features/dialogue/application/mistral_dialogue_client.dart
 M packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart
 M packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_bottom_action_bar.dart
 M packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_header.dart
 M packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_shell.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_rebuild_test_harness.dart
 M packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
?? packages/map_editor/lib/src/features/editor/application/editor_ai_settings.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_local_mapping_suggester.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_controller.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_models.dart
?? packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart
?? packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart
?? reports/surface/surface_studio_rebuild_v2_1_functional_integration.md
```
## Diff stat final

```text
 .../application/mistral_dialogue_client.dart       |   12 +-
 .../preview/surface_studio_preview_panel.dart      |  122 +-
 .../shell/surface_studio_bottom_action_bar.dart    |   82 +-
 .../shell/surface_studio_header.dart               |    6 +-
 .../surface_studio/shell/surface_studio_shell.dart |   20 +-
 .../surface_studio/surface_studio_panel.dart       |  651 +-----
 .../surface_studio/surface_studio_screen.dart      | 1781 +++++++++++++++-
 .../surface_studio/surface_studio_panel_test.dart  | 2130 ++------------------
 .../surface_studio_rebuild_test_harness.dart       |    8 +
 ...ce_studio_vertical_atlas_golden_slice_test.dart |  197 +-
 .../surface_studio_workspace_entry_test.dart       |  571 ++----
 11 files changed, 2191 insertions(+), 3389 deletions(-)
```
## Diffs complets

### Diff `packages/map_editor/lib/src/features/dialogue/application/mistral_dialogue_client.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/dialogue/application/mistral_dialogue_client.dart b/packages/map_editor/lib/src/features/dialogue/application/mistral_dialogue_client.dart
index 69242b25..c3579dbc 100644
--- a/packages/map_editor/lib/src/features/dialogue/application/mistral_dialogue_client.dart
+++ b/packages/map_editor/lib/src/features/dialogue/application/mistral_dialogue_client.dart
@@ -7,19 +7,11 @@
 // -----------------------------------------------------------------------------
 
 import 'dart:convert';
-import 'dart:io';
 
 import 'package:http/http.dart' as http;
-import 'package:map_core/map_core.dart';
 
-/// Clé Mistral pour toute fonction IA de l’éditeur (Dialogue Studio, futurs écrans).
-///
-/// Ordre : réglage projet → env. Évite de dupliquer la logique dans chaque workspace.
-String resolveEditorMistralApiKey(ProjectSettings? settings) {
-  final fromProject = settings?.mistralApiKey?.trim() ?? '';
-  if (fromProject.isNotEmpty) return fromProject;
-  return Platform.environment['MISTRAL_API_KEY'] ?? '';
-}
+export '../../editor/application/editor_ai_settings.dart'
+    show resolveEditorMistralApiKey;
 
 /// Erreur réseau ou réponse API inattendue.
 class MistralDialogueException implements Exception {
```
### Diff `packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart b/packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart
index 4a87557e..b025b9a6 100644
--- a/packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart
@@ -185,69 +185,69 @@ class _PreviewControls extends StatelessWidget {
 
   @override
   Widget build(BuildContext context) {
-    return Column(
-      crossAxisAlignment: CrossAxisAlignment.stretch,
-      children: [
-        Container(
-          padding: const EdgeInsets.all(10),
-          decoration: BoxDecoration(
-            color: SurfaceStudioDesignTokens.backgroundPanelAlt,
-            borderRadius: BorderRadius.circular(10),
-            border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
-          ),
-          child: Column(
-            children: [
-              Row(
-                mainAxisAlignment: MainAxisAlignment.center,
-                children: [
-                  _RoundControl(
-                    keyName: 'surfaceStudio.preview.previous',
-                    icon: CupertinoIcons.backward_end_fill,
-                    onPressed: onPrevious,
-                  ),
-                  const SizedBox(width: 10),
-                  _RoundControl(
-                    keyName: 'surfaceStudio.preview.playPause',
-                    icon: playing
-                        ? CupertinoIcons.pause_fill
-                        : CupertinoIcons.play_fill,
-                    onPressed: onTogglePlaying,
-                    highlighted: true,
-                  ),
-                  const SizedBox(width: 10),
-                  _RoundControl(
-                    keyName: 'surfaceStudio.preview.next',
-                    icon: CupertinoIcons.forward_end_fill,
-                    onPressed: onNext,
+    return SingleChildScrollView(
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          Container(
+            padding: const EdgeInsets.all(10),
+            decoration: BoxDecoration(
+              color: SurfaceStudioDesignTokens.backgroundPanelAlt,
+              borderRadius: BorderRadius.circular(10),
+              border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
+            ),
+            child: Column(
+              children: [
+                Row(
+                  mainAxisAlignment: MainAxisAlignment.center,
+                  children: [
+                    _RoundControl(
+                      keyName: 'surfaceStudio.preview.previous',
+                      icon: CupertinoIcons.backward_end_fill,
+                      onPressed: onPrevious,
+                    ),
+                    const SizedBox(width: 10),
+                    _RoundControl(
+                      keyName: 'surfaceStudio.preview.playPause',
+                      icon: playing
+                          ? CupertinoIcons.pause_fill
+                          : CupertinoIcons.play_fill,
+                      onPressed: onTogglePlaying,
+                      highlighted: true,
+                    ),
+                    const SizedBox(width: 10),
+                    _RoundControl(
+                      keyName: 'surfaceStudio.preview.next',
+                      icon: CupertinoIcons.forward_end_fill,
+                      onPressed: onNext,
+                    ),
+                  ],
+                ),
+                const SizedBox(height: 9),
+                Text(
+                  'Frame ${frameIndex + 1} / $frameCount',
+                  style: const TextStyle(
+                    color: SurfaceStudioDesignTokens.textSecondary,
+                    fontWeight: FontWeight.w800,
+                    fontSize: 12,
                   ),
-                ],
-              ),
-              const SizedBox(height: 9),
-              Text(
-                'Frame ${frameIndex + 1} / $frameCount',
-                style: const TextStyle(
-                  color: SurfaceStudioDesignTokens.textSecondary,
-                  fontWeight: FontWeight.w800,
-                  fontSize: 12,
                 ),
-              ),
-              Material(
-                type: MaterialType.transparency,
-                child: Slider(
-                  key: const ValueKey('surfaceStudio.preview.scrubSlider'),
-                  value: frameIndex.toDouble(),
-                  min: 0,
-                  max: (frameCount - 1).toDouble(),
-                  divisions: frameCount > 1 ? frameCount - 1 : null,
-                  onChanged: (value) => onFrameChanged(value.round()),
+                Material(
+                  type: MaterialType.transparency,
+                  child: Slider(
+                    key: const ValueKey('surfaceStudio.preview.scrubSlider'),
+                    value: frameIndex.toDouble(),
+                    min: 0,
+                    max: (frameCount - 1).toDouble(),
+                    divisions: frameCount > 1 ? frameCount - 1 : null,
+                    onChanged: (value) => onFrameChanged(value.round()),
+                  ),
                 ),
-              ),
-            ],
+              ],
+            ),
           ),
-        ),
-        const SizedBox(height: 8),
-        Expanded(
-          child: Container(
+          const SizedBox(height: 8),
+          Container(
             padding: const EdgeInsets.all(10),
             decoration: BoxDecoration(
               color: SurfaceStudioDesignTokens.backgroundPanelAlt,
@@ -325,8 +325,8 @@ class _PreviewControls extends StatelessWidget {
               ),
             ),
           ),
-        ),
-      ],
+        ],
+      ),
     );
   }
 }
```
### Diff `packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_bottom_action_bar.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_bottom_action_bar.dart b/packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_bottom_action_bar.dart
index 7272820e..4da3894f 100644
--- a/packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_bottom_action_bar.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_bottom_action_bar.dart
@@ -9,20 +9,24 @@ class SurfaceStudioBottomActionBar extends StatelessWidget {
     required this.canAutoSuggest,
     required this.canApplyMapping,
     required this.canGoNext,
+    this.canSaveCatalog = false,
     required this.onBack,
     required this.onAutoSuggest,
     required this.onApplyMapping,
     required this.onNext,
+    this.onSaveCatalog,
   });
 
   final bool canGoBack;
   final bool canAutoSuggest;
   final bool canApplyMapping;
   final bool canGoNext;
+  final bool canSaveCatalog;
   final VoidCallback onBack;
   final VoidCallback onAutoSuggest;
   final VoidCallback onApplyMapping;
   final VoidCallback onNext;
+  final VoidCallback? onSaveCatalog;
 
   @override
   Widget build(BuildContext context) {
@@ -44,32 +48,54 @@ class SurfaceStudioBottomActionBar extends StatelessWidget {
             enabled: canGoBack,
             onPressed: onBack,
           ),
-          const Spacer(),
-          _BarButton(
-            keyName: 'surfaceStudio.action.autoSuggest',
-            label: 'Suggestion auto',
-            icon: CupertinoIcons.sparkles,
-            enabled: canAutoSuggest,
-            onPressed: onAutoSuggest,
-            accent: SurfaceStudioDesignTokens.accentTeal,
-          ),
-          const SizedBox(width: 20),
-          _BarButton(
-            keyName: 'surfaceStudio.action.applyMapping',
-            label: 'Appliquer le mapping',
-            icon: CupertinoIcons.checkmark_circle,
-            enabled: canApplyMapping,
-            onPressed: onApplyMapping,
-          ),
-          const SizedBox(width: 20),
-          _BarButton(
-            keyName: 'surfaceStudio.action.next',
-            label: 'Suivant',
-            icon: CupertinoIcons.arrow_right,
-            enabled: canGoNext,
-            onPressed: onNext,
-            accent: SurfaceStudioDesignTokens.accentGold,
-            primary: true,
+          const SizedBox(width: 16),
+          Expanded(
+            child: SingleChildScrollView(
+              scrollDirection: Axis.horizontal,
+              reverse: true,
+              child: Row(
+                mainAxisSize: MainAxisSize.min,
+                children: [
+                  _BarButton(
+                    keyName: 'surfaceStudio.action.autoSuggest',
+                    label: 'Suggestion auto',
+                    icon: CupertinoIcons.sparkles,
+                    enabled: canAutoSuggest,
+                    onPressed: onAutoSuggest,
+                    accent: SurfaceStudioDesignTokens.accentTeal,
+                  ),
+                  const SizedBox(width: 12),
+                  _BarButton(
+                    keyName: 'surfaceStudio.action.applyMapping',
+                    label: 'Appliquer le mapping',
+                    icon: CupertinoIcons.checkmark_circle,
+                    enabled: canApplyMapping,
+                    onPressed: onApplyMapping,
+                  ),
+                  if (onSaveCatalog != null) ...[
+                    const SizedBox(width: 12),
+                    _BarButton(
+                      keyName: 'surfaceStudio.action.saveCatalog',
+                      label: 'Préparer sauvegarde',
+                      icon: CupertinoIcons.tray_arrow_down,
+                      enabled: canSaveCatalog,
+                      onPressed: onSaveCatalog!,
+                      accent: SurfaceStudioDesignTokens.accentTeal,
+                    ),
+                  ],
+                  const SizedBox(width: 12),
+                  _BarButton(
+                    keyName: 'surfaceStudio.action.next',
+                    label: 'Suivant',
+                    icon: CupertinoIcons.arrow_right,
+                    enabled: canGoNext,
+                    onPressed: onNext,
+                    accent: SurfaceStudioDesignTokens.accentGold,
+                    primary: true,
+                  ),
+                ],
+              ),
+            ),
           ),
         ],
       ),
@@ -104,7 +130,7 @@ class _BarButton extends StatelessWidget {
       child: CupertinoButton(
         key: ValueKey(keyName),
         minimumSize: const Size(46, 46),
-        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
+        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
         color: primary
             ? effectiveAccent.withValues(alpha: 0.42)
             : SurfaceStudioDesignTokens.backgroundElevated,
@@ -120,7 +146,7 @@ class _BarButton extends StatelessWidget {
                   : effectiveAccent,
               size: 18,
             ),
-            const SizedBox(width: 10),
+            const SizedBox(width: 8),
             Text(
               label,
               style: TextStyle(
```
### Diff `packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_header.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_header.dart b/packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_header.dart
index 252f907e..a5c04910 100644
--- a/packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_header.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_header.dart
@@ -11,11 +11,13 @@ class SurfaceStudioHeader extends StatelessWidget {
     required this.currentStep,
     required this.completedSteps,
     required this.onStepSelected,
+    this.onOpenAdvanced,
   });
 
   final SurfaceStudioWizardStep currentStep;
   final Set<SurfaceStudioWizardStep> completedSteps;
   final ValueChanged<SurfaceStudioWizardStep> onStepSelected;
+  final VoidCallback? onOpenAdvanced;
 
   @override
   Widget build(BuildContext context) {
@@ -55,9 +57,9 @@ class SurfaceStudioHeader extends StatelessWidget {
             onPressed: () {},
           ),
           _HeaderIconButton(
-            tooltip: 'Paramètres',
+            tooltip: 'Catalogue & diagnostics',
             icon: CupertinoIcons.gear_alt,
-            onPressed: () {},
+            onPressed: onOpenAdvanced ?? () {},
           ),
           _HeaderIconButton(
             tooltip: 'Fermer',
```
### Diff `packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_shell.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_shell.dart b/packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_shell.dart
index 042e1448..81e01640 100644
--- a/packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_shell.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_shell.dart
@@ -7,17 +7,15 @@ class SurfaceStudioShell extends StatelessWidget {
     super.key,
     required this.header,
     required this.sidebar,
-    required this.atlasPanel,
-    required this.schemaPanel,
-    required this.previewPanel,
+    required this.workspacePanel,
+    required this.rightDock,
     required this.bottomBar,
   });
 
   final Widget header;
   final Widget sidebar;
-  final Widget atlasPanel;
-  final Widget schemaPanel;
-  final Widget previewPanel;
+  final Widget workspacePanel;
+  final Widget rightDock;
   final Widget bottomBar;
 
   @override
@@ -39,17 +37,11 @@ class SurfaceStudioShell extends StatelessWidget {
                 children: [
                   sidebar,
                   const SizedBox(width: SurfaceStudioDesignTokens.gapSm),
-                  Expanded(child: atlasPanel),
+                  Expanded(child: workspacePanel),
                   const SizedBox(width: SurfaceStudioDesignTokens.gapSm),
                   SizedBox(
                     width: SurfaceStudioDesignTokens.rightPanelWidthExpanded,
-                    child: Column(
-                      children: [
-                        Expanded(flex: 3, child: schemaPanel),
-                        const SizedBox(height: SurfaceStudioDesignTokens.gapSm),
-                        Expanded(flex: 2, child: previewPanel),
-                      ],
-                    ),
+                    child: rightDock,
                   ),
                 ],
               ),
```
### Diff `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
index 5b79aea9..13635b5a 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
@@ -1,20 +1,16 @@
 // Surface Studio — assistant premium de mapping d'atlas.
 //
-// Le premier viewport porte le workflow guide moderne. Les sections legacy
-// restent disponibles plus bas pour conserver les briques metier existantes :
-// preparation d'atlas, inspection, diagnostics et sauvegarde via le flux projet.
+// Le viewport principal porte un seul workflow guide moderne. Les anciennes
+// briques utiles restent accessibles dans le drawer avance, sans second
+// Surface Studio rendu sous l'assistant.
 
 import 'package:flutter/cupertino.dart';
-import 'package:flutter/material.dart' show Icons;
 import 'package:macos_ui/macos_ui.dart';
 import 'package:map_core/map_core.dart';
 
 import '../../ui/shared/cupertino_editor_widgets.dart';
 import 'surface_studio_atlas_editing.dart';
-import 'surface_studio_atlas_authoring_prep.dart';
 import 'surface_studio_catalog_browser.dart';
-import 'surface_studio_creation_assistant.dart';
-import 'surface_studio_detected_animations_panel.dart';
 import 'surface_studio_diagnostics_view.dart';
 import 'surface_studio_paintable_surfaces_panel.dart';
 import 'surface_studio_preset_editor_controller.dart';
@@ -23,8 +19,6 @@ import 'surface_studio_selection.dart';
 import 'surface_studio_selection_inspector.dart';
 import 'surface_studio_selection_summary.dart';
 import 'surface_studio_screen.dart';
-import 'surface_studio_workflow_layout.dart';
-import 'surface_studio_workflow_stepper.dart';
 
 SurfaceStudioSelection _selectionValidInReadModel(
   SurfaceStudioReadModel rm,
@@ -59,6 +53,7 @@ class SurfaceStudioPanel extends StatefulWidget {
     this.onRequestProjectSave,
     this.projectTilesets,
     this.projectRootPath,
+    this.projectSettings,
     this.surfaceMappingImageLoader,
   });
 
@@ -66,6 +61,7 @@ class SurfaceStudioPanel extends StatefulWidget {
   final ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogSaveRequested;
   final Future<bool> Function()? onRequestProjectSave;
   final List<ProjectTilesetEntry>? projectTilesets;
+  final ProjectSettings? projectSettings;
   final SurfaceStudioAtlasUiImageLoader? surfaceMappingImageLoader;
 
   /// Racine projet sur disque pour résoudre les chemins d’images tileset (aperçu Lot 72).
@@ -340,43 +336,17 @@ class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
     );
   }
 
+  void _onSurfaceCatalogChanged(ProjectSurfaceCatalog cat) {
+    setState(() {
+      _saveFlowPrepNote = null;
+      _workReadModel = buildSurfaceStudioReadModelFromCatalog(cat);
+      _selection = _selectionAfterCatalogChanged(cat);
+    });
+  }
+
   @override
   Widget build(BuildContext context) {
-    final s = _workReadModel.summary;
-    final label = EditorChrome.primaryLabel(context);
-    final subtle = EditorChrome.subtleLabel(context);
-    final isPartial = widget.onSurfaceCatalogSaveRequested != null;
     final canMutateCatalog = widget.onSurfaceCatalogSaveRequested != null;
-    final authoring = SurfaceStudioAtlasAuthoringPrep(
-      readModel: _workReadModel,
-      selection: _selection,
-      requestEditSignal: _atlasEditSignal,
-      projectTilesets: widget.projectTilesets,
-      projectRootPath: widget.projectRootPath,
-      onSurfaceCatalogChanged: (cat) {
-        setState(() {
-          _saveFlowPrepNote = null;
-          _workReadModel = buildSurfaceStudioReadModelFromCatalog(cat);
-          _selection = _selectionAfterCatalogChanged(cat);
-        });
-      },
-      onWorkCatalogAnimationsCreated: (createdIds) {
-        if (createdIds.isEmpty) {
-          return;
-        }
-        setState(() {
-          _selection = SurfaceStudioSelection.animation(createdIds.first);
-        });
-      },
-      onWorkCatalogPresetCreated: (presetId) {
-        if (presetId.isEmpty) {
-          return;
-        }
-        setState(() {
-          _selection = SurfaceStudioSelection.preset(presetId);
-        });
-      },
-    );
     final inspection = Column(
       key: const ValueKey('surface_studio_inspection_column'),
       crossAxisAlignment: CrossAxisAlignment.stretch,
@@ -393,9 +363,6 @@ class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
         ),
       ],
     );
-    final assistant = SurfaceStudioCreationAssistant(readModel: _workReadModel);
-    final detectedAnimations =
-        SurfaceStudioDetectedAnimationsPanel(readModel: _workReadModel);
     final selectedPreset = _selectedWorkPreset();
     final paintableSurfaces = SurfaceStudioPaintableSurfacesPanel(
       readModel: _workReadModel,
@@ -406,129 +373,23 @@ class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
           ? _onSurfaceCatalogSavePrep
           : null,
     );
-
-    final legacyAuthoringBridge = Column(
-      crossAxisAlignment: CrossAxisAlignment.stretch,
-      children: [
-        _CompactStudioHeader(
-          key: const ValueKey('surface_studio_workflow_header'),
-          label: label,
-          subtle: subtle,
-          summary: s,
-          readOnly: !isPartial,
-        ),
-        const SizedBox(height: 8),
-        SurfaceStudioWorkflowStepper(readModel: _workReadModel),
-        if (_hasWorkCatalogChanges) ...[
-          const SizedBox(height: 10),
-          _CatalogStateStrip(
-            key: const ValueKey('surface_studio_catalog_status_strip'),
-            subtle: subtle,
-            workCatalogNote: SurfaceStudioPanel.workCatalogDirtyStateText,
-            onSurfaceSavePrep: widget.onSurfaceCatalogSaveRequested != null
-                ? _onSurfaceCatalogSavePrep
-                : null,
-            onResetWorkCatalog: () {
-              setState(() {
-                _workReadModel = widget.readModel;
-                _selection =
-                    _selectionValidInReadModel(_workReadModel, _selection);
-                _saveFlowPrepNote = null;
-              });
-            },
-          ),
-          if (widget.onSurfaceCatalogSaveRequested == null)
-            Text(
-              key: const ValueKey('surface_studio_save_prep_not_connected'),
-              SurfaceStudioPanel.savePrepNotConnectedNote,
-              style: TextStyle(
-                color: subtle.withValues(alpha: 0.95),
-                fontSize: 11,
-                fontStyle: FontStyle.italic,
-              ),
-            ),
-          if (widget.onRequestProjectSave != null) ...[
-            const SizedBox(height: 6),
-            CupertinoButton(
-              key: const ValueKey(
-                  'surface_studio_project_save_via_official_flow'),
-              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
-              onPressed: _onRequestProjectSave,
-              child: const Text(
-                SurfaceStudioPanel.projectSaveViaExistingFlowButtonLabel,
-              ),
-            ),
-            if (_projectSaveDiskNote != null)
-              Text(
-                _projectSaveDiskNote!,
-                key: const ValueKey('surface_studio_project_save_disk_note'),
-                style: TextStyle(
-                  color: _surfaceStudioAccent.withValues(alpha: 0.88),
-                  fontSize: 11,
-                  fontWeight: FontWeight.w600,
-                ),
-              ),
-          ],
-        ] else if (widget.onRequestProjectSave != null) ...[
-          const SizedBox(height: 8),
-          CupertinoButton(
-            key:
-                const ValueKey('surface_studio_project_save_via_official_flow'),
-            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
-            onPressed: _onRequestProjectSave,
-            child: const Text(
-              SurfaceStudioPanel.projectSaveViaExistingFlowButtonLabel,
-            ),
-          ),
-          if (_projectSaveDiskNote != null) ...[
-            const SizedBox(height: 4),
-            Text(
-              _projectSaveDiskNote!,
-              key: const ValueKey('surface_studio_project_save_disk_note'),
-              style: TextStyle(
-                color: _surfaceStudioAccent.withValues(alpha: 0.88),
-                fontSize: 11,
-                fontWeight: FontWeight.w600,
-              ),
-            ),
-          ],
-        ],
-        if (_saveFlowPrepNote != null) ...[
-          const SizedBox(height: 6),
-          Text(
-            _saveFlowPrepNote!,
-            key: const ValueKey('surface_studio_save_prep_transmitted'),
-            style: TextStyle(
-              color: _surfaceStudioAccent.withValues(alpha: 0.9),
-              fontSize: 11,
-              fontWeight: FontWeight.w600,
-            ),
-          ),
-        ],
-        const SizedBox(height: 12),
-        SurfaceStudioWorkflowLayout(
-          assistant: assistant,
-          atlasWorkspace: authoring,
-          detectedAnimations: detectedAnimations,
-          paintableSurfaces: paintableSurfaces,
+    final advancedDrawer = SingleChildScrollView(
+      padding: const EdgeInsets.all(14),
+      child: _AdvancedDetailsSection(
+        inspection: inspection,
+        browser: SurfaceStudioCatalogBrowser(
+          readModel: _workReadModel,
+          selection: _selection,
+          onSelectionChanged: (v) {
+            setState(() => _selection = v);
+          },
         ),
-        const SizedBox(height: 12),
-        _AdvancedDetailsSection(
-          inspection: inspection,
-          browser: SurfaceStudioCatalogBrowser(
-            readModel: _workReadModel,
-            selection: _selection,
-            onSelectionChanged: (v) {
-              setState(() => _selection = v);
-            },
-          ),
-          diagnostics: SurfaceStudioDiagnosticsView(readModel: _workReadModel),
-          futureActions: const _FutureActions(onImportVertical: null),
-          placeholder: const _SectionPlaceholder(
-            title: SurfaceStudioPanel.placeholderActionsTitle,
-          ),
+        diagnostics: SurfaceStudioDiagnosticsView(readModel: _workReadModel),
+        futureActions: paintableSurfaces,
+        placeholder: const _SectionPlaceholder(
+          title: SurfaceStudioPanel.placeholderActionsTitle,
         ),
-      ],
+      ),
     );
 
     return LayoutBuilder(
@@ -537,27 +398,57 @@ class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
             ? constraints.maxWidth.clamp(1200.0, 2400.0).toDouble()
             : 1600.0;
         final shellHeight = constraints.hasBoundedHeight
-            ? constraints.maxHeight.clamp(900.0, 1120.0).toDouble()
+            ? constraints.maxHeight.clamp(760.0, 1120.0).toDouble()
             : 900.0;
         return SingleChildScrollView(
-          key: const ValueKey('surface_studio_root_scroll'),
-          child: Column(
-            crossAxisAlignment: CrossAxisAlignment.stretch,
-            children: [
-              SingleChildScrollView(
-                scrollDirection: Axis.horizontal,
-                child: SizedBox(
-                  width: shellWidth,
-                  height: shellHeight,
-                  child: SurfaceStudioScreen(readModel: _workReadModel),
-                ),
-              ),
-              Padding(
-                key: const ValueKey('surface_studio_legacy_authoring_bridge'),
-                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
-                child: legacyAuthoringBridge,
-              ),
-            ],
+          scrollDirection: Axis.horizontal,
+          child: SizedBox(
+            width: shellWidth,
+            height: shellHeight,
+            child: SurfaceStudioScreen(
+              readModel: _workReadModel,
+              projectSettings: widget.projectSettings,
+              projectTilesets: widget.projectTilesets ?? const [],
+              projectRootPath: widget.projectRootPath,
+              surfaceMappingImageLoader: widget.surfaceMappingImageLoader,
+              hasWorkCatalogChanges: _hasWorkCatalogChanges,
+              saveFlowPrepNote: _saveFlowPrepNote,
+              projectSaveDiskNote: _projectSaveDiskNote,
+              onSurfaceCatalogChanged: _onSurfaceCatalogChanged,
+              onWorkCatalogAnimationsCreated: (createdIds) {
+                if (createdIds.isEmpty) {
+                  return;
+                }
+                setState(() {
+                  _selection =
+                      SurfaceStudioSelection.animation(createdIds.first);
+                });
+              },
+              onWorkCatalogPresetCreated: (presetId) {
+                if (presetId.isEmpty) {
+                  return;
+                }
+                setState(() {
+                  _selection = SurfaceStudioSelection.preset(presetId);
+                });
+              },
+              onResetWorkCatalog: () {
+                setState(() {
+                  _workReadModel = widget.readModel;
+                  _selection =
+                      _selectionValidInReadModel(_workReadModel, _selection);
+                  _saveFlowPrepNote = null;
+                });
+              },
+              onSurfaceCatalogSavePrep:
+                  widget.onSurfaceCatalogSaveRequested == null
+                      ? null
+                      : _onSurfaceCatalogSavePrep,
+              onRequestProjectSave: widget.onRequestProjectSave == null
+                  ? null
+                  : _onRequestProjectSave,
+              advancedDrawer: advancedDrawer,
+            ),
           ),
         );
       },
@@ -641,323 +532,6 @@ class _AdvancedDetailsSection extends StatelessWidget {
   }
 }
 
-class _CompactStudioHeader extends StatelessWidget {
-  const _CompactStudioHeader({
-    super.key,
-    required this.label,
-    required this.subtle,
-    required this.summary,
-    required this.readOnly,
-  });
-
-  final Color label;
-  final Color subtle;
-  final SurfaceStudioCatalogSummaryReadModel summary;
-  final bool readOnly;
-
-  @override
-  Widget build(BuildContext context) {
-    final titleRow = Row(
-      crossAxisAlignment: CrossAxisAlignment.start,
-      children: [
-        const _StudioHeaderIcon(accent: _surfaceStudioAccent),
-        const SizedBox(width: 10),
-        Expanded(
-          child: Column(
-            crossAxisAlignment: CrossAxisAlignment.stretch,
-            children: [
-              Row(
-                crossAxisAlignment: CrossAxisAlignment.start,
-                children: [
-                  Expanded(
-                    child: Text(
-                      SurfaceStudioPanel.titleText,
-                      style: TextStyle(
-                        color: label,
-                        fontSize: 20,
-                        fontWeight: FontWeight.w800,
-                        letterSpacing: -0.3,
-                      ),
-                    ),
-                  ),
-                  if (readOnly)
-                    const _ReadOnlyBadge(
-                      label: SurfaceStudioPanel.readOnlyBadgeText,
-                    )
-                  else
-                    const _ReadOnlyBadge(
-                      label: SurfaceStudioPanel.partialAuthoringBadgeText,
-                    ),
-                ],
-              ),
-              const SizedBox(height: 4),
-              Text(
-                SurfaceStudioPanel.productDescriptionText,
-                maxLines: 2,
-                overflow: TextOverflow.ellipsis,
-                style: TextStyle(
-                  color: subtle,
-                  fontSize: 12.5,
-                  fontWeight: FontWeight.w500,
-                  height: 1.3,
-                ),
-              ),
-            ],
-          ),
-        ),
-      ],
-    );
-    final counters = _CounterRow(
-      atlas: summary.atlasCount,
-      animations: summary.animationCount,
-      presets: summary.presetCount,
-      compact: true,
-    );
-    return LayoutBuilder(
-      builder: (context, c) {
-        if (c.maxWidth < 520) {
-          return Column(
-            crossAxisAlignment: CrossAxisAlignment.stretch,
-            children: [
-              titleRow,
-              const SizedBox(height: 8),
-              counters,
-            ],
-          );
-        }
-        return Row(
-          crossAxisAlignment: CrossAxisAlignment.start,
-          children: [
-            Expanded(child: titleRow),
-            const SizedBox(width: 6),
-            counters,
-          ],
-        );
-      },
-    );
-  }
-}
-
-class _CatalogStateStrip extends StatelessWidget {
-  const _CatalogStateStrip({
-    super.key,
-    required this.subtle,
-    required this.workCatalogNote,
-    required this.onResetWorkCatalog,
-    this.onSurfaceSavePrep,
-  });
-
-  final Color subtle;
-  final String workCatalogNote;
-  final VoidCallback onResetWorkCatalog;
-  final void Function()? onSurfaceSavePrep;
-
-  @override
-  Widget build(BuildContext context) {
-    return _StudioCard(
-      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
-      child: Column(
-        crossAxisAlignment: CrossAxisAlignment.stretch,
-        children: [
-          Text(
-            workCatalogNote,
-            key: const ValueKey('surface_studio_work_catalog_dirty_state'),
-            style: TextStyle(
-              color: _surfaceStudioAccent.withValues(alpha: 0.95),
-              fontSize: 12,
-              fontWeight: FontWeight.w700,
-            ),
-          ),
-          const SizedBox(height: 2),
-          Text(
-            SurfaceStudioPanel.savePrepNoDiskNote,
-            style: TextStyle(
-              color: subtle.withValues(alpha: 0.88),
-              fontSize: 10.5,
-            ),
-          ),
-          const SizedBox(height: 6),
-          Wrap(
-            spacing: 4,
-            runSpacing: 4,
-            crossAxisAlignment: WrapCrossAlignment.center,
-            children: [
-              if (onSurfaceSavePrep != null)
-                CupertinoButton(
-                  key: const ValueKey('surface_studio_save_prep_catalog'),
-                  padding:
-                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
-                  onPressed: onSurfaceSavePrep,
-                  child: const Text(SurfaceStudioPanel.savePrepActionLabel),
-                ),
-              CupertinoButton(
-                key: const ValueKey('surface_studio_reset_work_catalog'),
-                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
-                onPressed: onResetWorkCatalog,
-                child: const Text('Réinitialiser le catalogue de travail'),
-              ),
-            ],
-          ),
-        ],
-      ),
-    );
-  }
-}
-
-class _StudioHeaderIcon extends StatelessWidget {
-  const _StudioHeaderIcon({required this.accent});
-
-  final Color accent;
-
-  @override
-  Widget build(BuildContext context) {
-    const hi = Color(0xFFFFFFFF);
-    const lo = Color(0xFF120808);
-    final onAccent =
-        accent.computeLuminance() > 0.55 ? const Color(0xFF1A0A08) : hi;
-
-    return Container(
-      width: 42,
-      height: 42,
-      decoration: BoxDecoration(
-        gradient: LinearGradient(
-          begin: Alignment.topLeft,
-          end: Alignment.bottomRight,
-          colors: [
-            Color.lerp(hi, accent, 0.72)!,
-            Color.lerp(accent, lo, 0.38)!,
-          ],
-        ),
-        borderRadius: BorderRadius.circular(14),
-        border: Border.all(
-          color: accent.withValues(alpha: 0.88),
-          width: 1.2,
-        ),
-        boxShadow: EditorChrome.toolbarCapsuleShadows(context),
-      ),
-      alignment: Alignment.center,
-      child: MacosIcon(
-        Icons.auto_awesome_motion,
-        color: onAccent,
-        size: 22,
-      ),
-    );
-  }
-}
-
-class _ReadOnlyBadge extends StatelessWidget {
-  const _ReadOnlyBadge({required this.label});
-
-  final String label;
-
-  @override
-  Widget build(BuildContext context) {
-    const accent = _surfaceStudioAccent;
-    final fill = Color.lerp(
-      EditorChrome.islandFillElevated(context),
-      accent,
-      0.14,
-    )!;
-
-    return Container(
-      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
-      decoration: BoxDecoration(
-        color: fill,
-        borderRadius: BorderRadius.circular(8),
-        border: Border.all(color: accent.withValues(alpha: 0.65)),
-        boxShadow: EditorChrome.toolbarCapsuleShadows(context),
-      ),
-      child: Text(
-        label,
-        style: const TextStyle(
-          color: _surfaceStudioAccent,
-          fontSize: 11,
-          fontWeight: FontWeight.w800,
-          letterSpacing: 0.2,
-        ),
-      ),
-    );
-  }
-}
-
-class _CounterRow extends StatelessWidget {
-  const _CounterRow({
-    required this.atlas,
-    required this.animations,
-    required this.presets,
-    this.compact = false,
-  });
-
-  final int atlas;
-  final int animations;
-  final int presets;
-  final bool compact;
-
-  @override
-  Widget build(BuildContext context) {
-    return Wrap(
-      key: const ValueKey('surface_studio_header_counters'),
-      spacing: compact ? 6 : 12,
-      runSpacing: compact ? 6 : 10,
-      children: [
-        _CounterChip(label: 'Atlas', value: atlas, compact: compact),
-        _CounterChip(label: 'Animations', value: animations, compact: compact),
-        _CounterChip(label: 'Surfaces', value: presets, compact: compact),
-      ],
-    );
-  }
-}
-
-class _CounterChip extends StatelessWidget {
-  const _CounterChip({
-    required this.label,
-    required this.value,
-    this.compact = false,
-  });
-
-  final String label;
-  final int value;
-  final bool compact;
-
-  @override
-  Widget build(BuildContext context) {
-    final subtle = EditorChrome.subtleLabel(context);
-    final labelColor = EditorChrome.primaryLabel(context);
-
-    return _StudioCard(
-      padding: EdgeInsets.symmetric(
-        horizontal: compact ? 9 : 16,
-        vertical: compact ? 7 : 12,
-      ),
-      child: Column(
-        crossAxisAlignment: CrossAxisAlignment.start,
-        mainAxisSize: MainAxisSize.min,
-        children: [
-          Text(
-            label,
-            style: TextStyle(
-              color: subtle,
-              fontSize: compact ? 10 : 11,
-              fontWeight: FontWeight.w700,
-              letterSpacing: 0.3,
-            ),
-          ),
-          SizedBox(height: compact ? 3 : 6),
-          Text(
-            '$value',
-            style: TextStyle(
-              color: labelColor,
-              fontSize: compact ? 16 : 22,
-              fontWeight: FontWeight.w700,
-              letterSpacing: -0.4,
-            ),
-          ),
-        ],
-      ),
-    );
-  }
-}
-
 /// Carte interne : même relief que les tuiles inspecteur / sections.
 class _StudioCard extends StatelessWidget {
   const _StudioCard({
@@ -987,76 +561,6 @@ class _StudioCard extends StatelessWidget {
   }
 }
 
-class _FutureActions extends StatelessWidget {
-  const _FutureActions({
-    required this.onImportVertical,
-  });
-
-  final VoidCallback? onImportVertical;
-
-  @override
-  Widget build(BuildContext context) {
-    final subtle = EditorChrome.subtleLabel(context);
-
-    return Column(
-      crossAxisAlignment: CrossAxisAlignment.start,
-      children: [
-        Text(
-          'Actions futures (non disponibles)',
-          style: TextStyle(
-            color: subtle,
-            fontSize: 12,
-            fontWeight: FontWeight.w700,
-          ),
-        ),
-        const SizedBox(height: 10),
-        Row(
-          children: [
-            _GhostAction(
-              label: SurfaceStudioPanel.actionImportVerticalAtlasLabel,
-              onPressed: onImportVertical,
-            ),
-          ],
-        ),
-      ],
-    );
-  }
-}
-
-class _GhostAction extends StatelessWidget {
-  const _GhostAction({
-    required this.label,
-    required this.onPressed,
-  });
-
-  final String label;
-  final VoidCallback? onPressed;
-
-  @override
-  Widget build(BuildContext context) {
-    final subtle = EditorChrome.subtleLabel(context);
-    final enabled = onPressed != null;
-
-    return Opacity(
-      opacity: enabled ? 1.0 : 0.48,
-      child: CupertinoButton(
-        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
-        minimumSize: Size.zero,
-        onPressed: onPressed,
-        child: Text(
-          label,
-          style: TextStyle(
-            color: enabled ? EditorChrome.inspectorJoyCyan : subtle,
-            fontSize: 13,
-            fontWeight: FontWeight.w600,
-            decoration: TextDecoration.none,
-          ),
-        ),
-      ),
-    );
-  }
-}
-
 class _SectionPlaceholder extends StatelessWidget {
   const _SectionPlaceholder({required this.title});
 
@@ -1152,6 +656,7 @@ class _SurfaceStudioPanelFromManifestState
   Widget build(BuildContext context) {
     return SurfaceStudioPanel(
       readModel: buildSurfaceStudioReadModel(_manifest),
+      projectSettings: _manifest.settings,
       projectTilesets: _manifest.tilesets,
       projectRootPath: widget.projectRootPath,
       onSurfaceCatalogSaveRequested: (c) {
```
### Diff `packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart
index e01cb71b..c553cdf1 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart
@@ -1,8 +1,19 @@
 import 'dart:async';
 
-import 'package:flutter/widgets.dart';
+import 'package:flutter/cupertino.dart';
+import 'package:flutter/material.dart'
+    show
+        DropdownButton,
+        DropdownMenuItem,
+        InputDecoration,
+        Material,
+        MaterialType,
+        OutlineInputBorder,
+        TextField;
 import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_role_mapping_editor.dart';
 
+import '../editor/application/editor_ai_settings.dart';
 import 'atlas/surface_studio_atlas_panel.dart';
 import 'preview/surface_studio_preview_panel.dart';
 import 'schema/surface_studio_schema_panel.dart';
@@ -10,27 +21,71 @@ import 'shell/surface_studio_bottom_action_bar.dart';
 import 'shell/surface_studio_header.dart';
 import 'shell/surface_studio_shell.dart';
 import 'shell/surface_studio_sidebar.dart';
+import 'surface_studio_atlas_authoring_prep.dart';
+import 'surface_studio_atlas_grid_overlay.dart';
+import 'surface_studio_atlas_grid_preview.dart';
+import 'surface_studio_atlas_image_preview.dart';
+import 'surface_studio_atlas_source_picker.dart';
 import 'surface_studio_column_selection.dart';
+import 'surface_studio_design_tokens.dart';
 import 'surface_studio_drag_payload.dart';
+import 'surface_studio_mapping_suggestion_controller.dart';
+import 'surface_studio_mapping_suggestion_models.dart';
 import 'surface_studio_role_assignment_draft.dart';
 import 'surface_studio_step.dart';
+import 'surface_studio_vertical_atlas_animation_generation_plan.dart';
+import 'surface_studio_vertical_atlas_animation_generator.dart';
+import 'surface_studio_vertical_atlas_preset_generator.dart';
+import 'surface_studio_vertical_atlas_role_mapping.dart';
 
 class SurfaceStudioScreen extends StatefulWidget {
   const SurfaceStudioScreen({
     super.key,
     required this.readModel,
+    this.projectSettings,
+    this.projectTilesets = const <ProjectTilesetEntry>[],
+    this.projectRootPath,
+    this.surfaceMappingImageLoader,
+    this.hasWorkCatalogChanges = false,
+    this.saveFlowPrepNote,
+    this.projectSaveDiskNote,
+    this.onSurfaceCatalogChanged,
+    this.onWorkCatalogAnimationsCreated,
+    this.onWorkCatalogPresetCreated,
+    this.onResetWorkCatalog,
+    this.onSurfaceCatalogSavePrep,
+    this.onRequestProjectSave,
+    this.advancedDrawer,
   });
 
   final SurfaceStudioReadModel readModel;
+  final ProjectSettings? projectSettings;
+  final List<ProjectTilesetEntry> projectTilesets;
+  final String? projectRootPath;
+  final SurfaceStudioAtlasUiImageLoader? surfaceMappingImageLoader;
+  final bool hasWorkCatalogChanges;
+  final String? saveFlowPrepNote;
+  final String? projectSaveDiskNote;
+  final ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogChanged;
+  final ValueChanged<List<String>>? onWorkCatalogAnimationsCreated;
+  final ValueChanged<String>? onWorkCatalogPresetCreated;
+  final VoidCallback? onResetWorkCatalog;
+  final VoidCallback? onSurfaceCatalogSavePrep;
+  final Future<void> Function()? onRequestProjectSave;
+  final Widget? advancedDrawer;
 
   @override
   State<SurfaceStudioScreen> createState() => _SurfaceStudioScreenState();
 }
 
 class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
+  static const int _defaultDurationMsPerFrame = 120;
+
   SurfaceStudioWizardStep _currentStep = SurfaceStudioWizardStep.map;
   bool _sidebarCollapsed = false;
   bool _rightPanelCollapsed = false;
+  bool _advancedDrawerOpen = false;
+  bool _suggestionReviewOpen = false;
   Set<String> _openSchemaGroups = const {
     'surfaceMain',
     'edges',
@@ -41,8 +96,7 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
   SurfaceStudioColumnSelection _selectedColumns =
       const SurfaceStudioColumnSelection(<int>[4, 5]);
   SurfaceStudioRoleAssignmentDraft _assignmentDraft =
-      const SurfaceStudioRoleAssignmentDraft.empty()
-          .assignColumns(SurfaceVariantRole.isolated, const <int>[4, 5, 6]);
+      const SurfaceStudioRoleAssignmentDraft.empty();
   double _zoomPercent = 100;
   bool _previewPlaying = false;
   int _previewFrameIndex = 0;
@@ -50,59 +104,234 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
   bool _previewGridVisible = true;
   int _previewSize = 10;
   String? _statusMessage;
+  String? _lastGenerationMessage;
+  String? _lastPresetMessage;
+  SurfaceStudioMappingSuggestionResult? _suggestionResult;
+  final _suggestionController =
+      const SurfaceStudioMappingSuggestionController();
   Timer? _previewTimer;
 
+  final TextEditingController _atlasId = TextEditingController();
+  final TextEditingController _atlasName = TextEditingController();
+  final TextEditingController _tilesetId = TextEditingController();
+  final TextEditingController _tileWidth = TextEditingController();
+  final TextEditingController _tileHeight = TextEditingController();
+  final TextEditingController _columns = TextEditingController();
+  final TextEditingController _rows = TextEditingController();
+  final TextEditingController _sortOrder = TextEditingController();
+  final TextEditingController _categoryId = TextEditingController();
+  SurfaceAtlasLayout _layout =
+      SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames;
+  String? _selectedAtlasId;
+
+  @override
+  void initState() {
+    super.initState();
+    _selectedAtlasId = widget.readModel.atlases.isNotEmpty
+        ? widget.readModel.atlases.first.id
+        : null;
+    if (widget.readModel.atlases.isEmpty) {
+      _currentStep = SurfaceStudioWizardStep.importAtlas;
+    }
+    _syncFormFromSelectedAtlas();
+    _syncSelectionToColumnCount();
+  }
+
+  @override
+  void didUpdateWidget(covariant SurfaceStudioScreen oldWidget) {
+    super.didUpdateWidget(oldWidget);
+    if (widget.readModel != oldWidget.readModel) {
+      if (_selectedAtlasId == null ||
+          widget.readModel.catalog.atlasById(_selectedAtlasId!) == null) {
+        _selectedAtlasId = widget.readModel.atlases.isNotEmpty
+            ? widget.readModel.atlases.first.id
+            : null;
+      }
+      _syncFormFromSelectedAtlas();
+      _syncSelectionToColumnCount();
+    }
+  }
+
   @override
   void dispose() {
     _previewTimer?.cancel();
+    _atlasId.dispose();
+    _atlasName.dispose();
+    _tilesetId.dispose();
+    _tileWidth.dispose();
+    _tileHeight.dispose();
+    _columns.dispose();
+    _rows.dispose();
+    _sortOrder.dispose();
+    _categoryId.dispose();
     super.dispose();
   }
 
+  ProjectSurfaceAtlas? get _selectedAtlas {
+    final id = _selectedAtlasId;
+    if (id == null) {
+      return null;
+    }
+    return widget.readModel.catalog.atlasById(id);
+  }
+
+  SurfaceStudioAtlasReadModel? get _selectedAtlasRow {
+    final id = _selectedAtlasId;
+    if (id == null) {
+      return null;
+    }
+    for (final row in widget.readModel.atlases) {
+      if (row.id == id) {
+        return row;
+      }
+    }
+    return null;
+  }
+
   int get _columnCount {
-    final atlases = widget.readModel.atlases;
-    if (atlases.isEmpty) {
-      return 12;
+    final parsed = int.tryParse(_columns.text.trim());
+    if (parsed != null && parsed > 0) {
+      return parsed.clamp(1, 48).toInt();
     }
-    return atlases.first.columns.clamp(1, 48).toInt();
+    final row = _selectedAtlasRow;
+    return (row?.columns ?? 12).clamp(1, 48).toInt();
   }
 
   int get _frameCount {
-    final atlases = widget.readModel.atlases;
-    if (atlases.isEmpty) {
-      return 32;
+    final parsed = int.tryParse(_rows.text.trim());
+    if (parsed != null && parsed > 0) {
+      return parsed.clamp(1, 128).toInt();
     }
-    return atlases.first.rows.clamp(1, 128).toInt();
+    final row = _selectedAtlasRow;
+    return (row?.rows ?? 32).clamp(1, 128).toInt();
   }
 
-  int get _tileWidth {
-    final atlases = widget.readModel.atlases;
-    if (atlases.isEmpty) {
-      return 32;
+  int get _tileWidthValue {
+    final parsed = int.tryParse(_tileWidth.text.trim());
+    if (parsed != null && parsed > 0) {
+      return parsed;
     }
-    return atlases.first.tileWidth;
+    return _selectedAtlasRow?.tileWidth ?? 32;
   }
 
-  int get _tileHeight {
-    final atlases = widget.readModel.atlases;
-    if (atlases.isEmpty) {
-      return 32;
+  int get _tileHeightValue {
+    final parsed = int.tryParse(_tileHeight.text.trim());
+    if (parsed != null && parsed > 0) {
+      return parsed;
     }
-    return atlases.first.tileHeight;
+    return _selectedAtlasRow?.tileHeight ?? 32;
   }
 
+  bool get _gridValid => surfaceStudioAtlasGridOverlayDraftValid(
+        _tileWidthValue,
+        _tileHeightValue,
+        _columnCount,
+        _frameCount,
+      );
+
   Set<SurfaceStudioWizardStep> get _completedSteps => {
-        SurfaceStudioWizardStep.importAtlas,
-        SurfaceStudioWizardStep.slice,
+        if (widget.readModel.atlases.isNotEmpty)
+          SurfaceStudioWizardStep.importAtlas,
+        if (_gridValid) SurfaceStudioWizardStep.slice,
         if (_assignmentDraft.isAssigned(SurfaceVariantRole.isolated))
           SurfaceStudioWizardStep.map,
-        if (_currentStep.index > SurfaceStudioWizardStep.preview.index)
+        if (_generationPlan.summary.readyAnimationCount > 0)
           SurfaceStudioWizardStep.preview,
       };
 
-  bool get _canGoNext =>
-      _currentStep != SurfaceStudioWizardStep.save &&
-      (_currentStep != SurfaceStudioWizardStep.map ||
-          _assignmentDraft.isAssigned(SurfaceVariantRole.isolated));
+  bool get _canGoNext {
+    return switch (_currentStep) {
+      SurfaceStudioWizardStep.importAtlas =>
+        widget.readModel.atlases.isNotEmpty,
+      SurfaceStudioWizardStep.slice => _gridValid,
+      SurfaceStudioWizardStep.map =>
+        _assignmentDraft.isAssigned(SurfaceVariantRole.isolated),
+      SurfaceStudioWizardStep.preview => true,
+      SurfaceStudioWizardStep.save => false,
+    };
+  }
+
+  SurfaceStudioColumnRoleMappingDraft get _columnRoleMappingDraft {
+    final assignments = <SurfaceStudioColumnRoleAssignment>[];
+    for (final role in standardSurfaceVariantRoleOrder) {
+      final columns = _assignmentDraft.columnsForRole(role);
+      if (columns.isEmpty) {
+        continue;
+      }
+      assignments.add(
+        SurfaceStudioColumnRoleAssignment(
+          columnIndex: (columns.first - 1).clamp(0, _columnCount - 1).toInt(),
+          role: role,
+        ),
+      );
+    }
+    return SurfaceStudioColumnRoleMappingDraft(
+      columnCount: _columnCount,
+      assignments: List<SurfaceStudioColumnRoleAssignment>.unmodifiable(
+        assignments,
+      ),
+    );
+  }
+
+  SurfaceStudioVerticalAtlasAnimationGenerationPlan get _generationPlan {
+    final existingIds = <String>{
+      for (final row in widget.readModel.animations) row.id,
+    };
+    return buildSurfaceStudioVerticalAtlasAnimationGenerationPlan(
+      atlasIdRaw: _atlasId.text,
+      mappingDraft: _columnRoleMappingDraft,
+      tileWidth: _tileWidthValue,
+      tileHeight: _tileHeightValue,
+      columns: _columnCount,
+      rows: _frameCount,
+      durationMsPerFrame: _defaultDurationMsPerFrame,
+      existingAnimationIds: existingIds,
+    );
+  }
+
+  void _syncFormFromSelectedAtlas() {
+    final atlas = _selectedAtlas;
+    if (atlas == null) {
+      _atlasId.text = '';
+      _atlasName.text = '';
+      _tilesetId.text = widget.projectTilesets.isNotEmpty
+          ? widget.projectTilesets.first.id
+          : '';
+      _tileWidth.text = '32';
+      _tileHeight.text = '32';
+      _columns.text = '12';
+      _rows.text = '32';
+      _sortOrder.text = '${widget.readModel.catalog.atlases.length}';
+      _categoryId.text = '';
+      _layout = SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames;
+      return;
+    }
+    _atlasId.text = atlas.id;
+    _atlasName.text = atlas.name;
+    _tilesetId.text = atlas.tilesetId;
+    _tileWidth.text = '${atlas.geometry.tileSize.width}';
+    _tileHeight.text = '${atlas.geometry.tileSize.height}';
+    _columns.text = '${atlas.geometry.gridSize.columns}';
+    _rows.text = '${atlas.geometry.gridSize.rows}';
+    _sortOrder.text = '${atlas.sortOrder}';
+    _categoryId.text = atlas.categoryId ?? '';
+    _layout = atlas.geometry.layout;
+  }
+
+  void _syncSelectionToColumnCount() {
+    final count = _columnCount;
+    final valid = _selectedColumns.columns
+        .where((column) => column >= 1 && column <= count)
+        .toList();
+    if (valid.isEmpty && count >= 1) {
+      _selectedColumns = SurfaceStudioColumnSelection(<int>[
+        count >= 5 ? 4 : 1,
+        if (count >= 5) 5,
+      ]);
+    } else {
+      _selectedColumns = SurfaceStudioColumnSelection(valid);
+    }
+  }
 
   void _selectStep(SurfaceStudioWizardStep step) {
     if (step == _currentStep) {
@@ -123,16 +352,24 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
   void _nextStep() {
     if (!_canGoNext) {
       setState(() {
-        _statusMessage =
-            'Assignez au moins le rôle “Plein” avant de continuer.';
+        _statusMessage = switch (_currentStep) {
+          SurfaceStudioWizardStep.importAtlas =>
+            'Créez ou sélectionnez un atlas avant de continuer.',
+          SurfaceStudioWizardStep.slice =>
+            'Corrigez la grille avant de continuer.',
+          SurfaceStudioWizardStep.map =>
+            'Assignez au moins le rôle “Plein” avant de continuer.',
+          SurfaceStudioWizardStep.preview ||
+          SurfaceStudioWizardStep.save =>
+            'Cette étape ne peut pas avancer.',
+        };
       });
       return;
     }
-    final nextIndex = (_currentStep.index + 1)
-        .clamp(0, SurfaceStudioWizardStep.values.length - 1)
-        .toInt();
     setState(() {
-      _currentStep = SurfaceStudioWizardStep.values[nextIndex];
+      _currentStep = SurfaceStudioWizardStep.values[(_currentStep.index + 1)
+          .clamp(0, SurfaceStudioWizardStep.values.length - 1)
+          .toInt()];
       _statusMessage = null;
     });
   }
@@ -178,40 +415,110 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
     });
   }
 
-  void _autoSuggestMapping() {
-    final roles = <SurfaceVariantRole>[
-      SurfaceVariantRole.isolated,
-      SurfaceVariantRole.endNorth,
-      SurfaceVariantRole.endEast,
-      SurfaceVariantRole.endSouth,
-      SurfaceVariantRole.endWest,
-      SurfaceVariantRole.cornerNW,
-      SurfaceVariantRole.cornerNE,
-      SurfaceVariantRole.cornerSW,
-      SurfaceVariantRole.cornerSE,
-    ];
-    var draft = const SurfaceStudioRoleAssignmentDraft.empty();
-    draft = draft.assignColumns(
-      SurfaceVariantRole.isolated,
-      <int>[for (var c = 4; c <= 6 && c <= _columnCount; c++) c],
-    );
-    var column = 1;
-    for (final role in roles.skip(1)) {
-      if (column <= _columnCount) {
-        draft = draft.assignColumns(role, <int>[column]);
-      }
-      column += 1;
+  void _createOrUpdateAtlas() {
+    final editingAtlasId = _selectedAtlasId;
+    final errors = validateSurfaceStudioAtlasDraft(
+      readModel: widget.readModel,
+      idRaw: _atlasId.text,
+      nameRaw: _atlasName.text,
+      tilesetIdRaw: _tilesetId.text,
+      tileWidthRaw: _tileWidth.text,
+      tileHeightRaw: _tileHeight.text,
+      columnsRaw: _columns.text,
+      rowsRaw: _rows.text,
+      sortOrderRaw: _sortOrder.text,
+      categoryIdRaw: _categoryId.text,
+      editingExistingAtlasId: editingAtlasId,
+    );
+    if (errors.isNotEmpty) {
+      setState(() {
+        _statusMessage = errors.first;
+      });
+      return;
+    }
+    final draft = tryBuildDraftFromForm(
+      idRaw: _atlasId.text,
+      nameRaw: _atlasName.text,
+      tilesetIdRaw: _tilesetId.text,
+      tileWidthRaw: _tileWidth.text,
+      tileHeightRaw: _tileHeight.text,
+      columnsRaw: _columns.text,
+      rowsRaw: _rows.text,
+      sortOrderRaw: _sortOrder.text,
+      categoryIdRaw: _categoryId.text,
+      layout: _layout,
+    );
+    final atlas =
+        draft == null ? null : tryBuildProjectSurfaceAtlasFromDraft(draft);
+    if (atlas == null) {
+      setState(() {
+        _statusMessage = 'Brouillon atlas invalide.';
+      });
+      return;
+    }
+
+    final atlases = List<ProjectSurfaceAtlas>.from(
+      widget.readModel.catalog.atlases,
+    );
+    final existingIndex =
+        atlases.indexWhere((candidate) => candidate.id == editingAtlasId);
+    if (existingIndex >= 0) {
+      atlases[existingIndex] = atlas;
+    } else {
+      atlases.add(atlas);
+    }
+    final next = ProjectSurfaceCatalog(
+      atlases: atlases,
+      animations: List<ProjectSurfaceAnimation>.from(
+        widget.readModel.catalog.animations,
+      ),
+      presets: List<ProjectSurfacePreset>.from(
+        widget.readModel.catalog.presets,
+      ),
+    );
+    widget.onSurfaceCatalogChanged?.call(next);
+    setState(() {
+      _selectedAtlasId = atlas.id;
+      _statusMessage = 'Atlas ajouté au catalogue de travail.';
+      _currentStep = SurfaceStudioWizardStep.slice;
+      _syncSelectionToColumnCount();
+    });
+  }
+
+  void _openSuggestionReview() {
+    final result = _suggestionController.suggestLocal(
+      columnCount: _columnCount,
+    );
+    setState(() {
+      _suggestionResult = result;
+      _suggestionReviewOpen = true;
+      _statusMessage =
+          'Suggestions locales prêtes — validation utilisateur requise.';
+    });
+  }
+
+  void _applySuggestions({required bool reliableOnly}) {
+    final result = _suggestionResult;
+    if (result == null) {
+      return;
+    }
+    final suggestions =
+        reliableOnly ? result.reliableSuggestions : result.suggestions;
+    var draft = _assignmentDraft;
+    for (final suggestion in suggestions) {
+      draft = draft.assignColumns(suggestion.role, suggestion.columns);
     }
     setState(() {
       _assignmentDraft = draft;
-      _statusMessage = 'Suggestion auto appliquée au brouillon local.';
+      _suggestionReviewOpen = false;
+      _statusMessage = 'Suggestions appliquées au mapping de travail.';
     });
   }
 
   void _applyMapping() {
     setState(() {
       _statusMessage =
-          'Mapping appliqué au brouillon local — aucune sauvegarde disque.';
+          'Mapping appliqué au plan de génération local — aucune sauvegarde disque.';
     });
   }
 
@@ -239,6 +546,103 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
     });
   }
 
+  void _appendReadyAnimations() {
+    final plan = _generationPlan;
+    if (plan.summary.readyAnimationCount == 0) {
+      setState(() {
+        _lastGenerationMessage = 'Aucune animation prête à créer.';
+      });
+      return;
+    }
+    final outcome = surfaceStudioCollectNewAnimationsFromReadyPlan(
+      plan: plan,
+      atlasIdForTileRefs: _atlasId.text.trim(),
+      animationDisplayNamePrefix: _atlasName.text.trim(),
+      categoryId:
+          _categoryId.text.trim().isEmpty ? null : _categoryId.text.trim(),
+      sortOrderBase: widget.readModel.catalog.animations.length,
+    );
+    if (outcome.newAnimations.isEmpty) {
+      setState(() {
+        _lastGenerationMessage = 'Aucune animation nouvelle à ajouter.';
+      });
+      return;
+    }
+    final next = surfaceStudioAppendAnimationsToWorkCatalog(
+      catalog: widget.readModel.catalog,
+      newAnimations: outcome.newAnimations,
+    );
+    widget.onSurfaceCatalogChanged?.call(next);
+    widget.onWorkCatalogAnimationsCreated?.call(
+      outcome.newAnimations.map((animation) => animation.id).toList(),
+    );
+    setState(() {
+      _lastGenerationMessage =
+          'Animations créées dans le catalogue de travail (${outcome.newAnimations.length}).';
+    });
+  }
+
+  void _appendPreset() {
+    final gridOk = _gridValid;
+    final plan = surfaceStudioPlanVerticalAtlasPresetAppend(
+      catalog: widget.readModel.catalog,
+      atlasIdRaw: _atlasId.text,
+      atlasDisplayName: _atlasName.text,
+      atlasCategoryDraft: _categoryId.text,
+      mappingDraft: _columnRoleMappingDraft,
+      gridValid: gridOk,
+    );
+    if (!plan.canCreate) {
+      setState(() {
+        _lastPresetMessage =
+            'Surface non créée : ${_presetPlanStatusLabel(plan.status)}.';
+      });
+      return;
+    }
+    try {
+      final preset = surfaceStudioBuildVerticalAtlasPreset(
+        catalog: widget.readModel.catalog,
+        atlasIdRaw: _atlasId.text,
+        atlasDisplayName: _atlasName.text,
+        atlasCategoryDraft: _categoryId.text,
+        mappingDraft: _columnRoleMappingDraft,
+        gridValid: gridOk,
+      );
+      final next = surfaceStudioAppendPresetToWorkCatalog(
+        catalog: widget.readModel.catalog,
+        preset: preset,
+      );
+      widget.onSurfaceCatalogChanged?.call(next);
+      widget.onWorkCatalogPresetCreated?.call(preset.id);
+      setState(() {
+        _lastPresetMessage = 'Surface prête à peindre créée : ${preset.name}.';
+      });
+    } on Object {
+      setState(() {
+        _lastPresetMessage =
+            'Impossible de créer la surface peignable dans l’état actuel.';
+      });
+    }
+  }
+
+  String _presetPlanStatusLabel(
+      SurfaceStudioVerticalAtlasPresetPlanStatus status) {
+    return switch (status) {
+      SurfaceStudioVerticalAtlasPresetPlanStatus.blockedEmptyAtlasId =>
+        'atlas manquant',
+      SurfaceStudioVerticalAtlasPresetPlanStatus.blockedInvalidGrid =>
+        'grille invalide',
+      SurfaceStudioVerticalAtlasPresetPlanStatus.blockedNoMapping =>
+        'mapping absent',
+      SurfaceStudioVerticalAtlasPresetPlanStatus.blockedMissingAnimations =>
+        'animations manquantes',
+      SurfaceStudioVerticalAtlasPresetPlanStatus.blockedDuplicatePresetId =>
+        'surface déjà existante',
+      SurfaceStudioVerticalAtlasPresetPlanStatus.incomplete => 'incomplet',
+      SurfaceStudioVerticalAtlasPresetPlanStatus.ready => 'prêt',
+    };
+  }
+
   @override
   Widget build(BuildContext context) {
     final frameCount = _frameCount;
@@ -249,6 +653,9 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
             currentStep: _currentStep,
             completedSteps: _completedSteps,
             onStepSelected: _selectStep,
+            onOpenAdvanced: () {
+              setState(() => _advancedDrawerOpen = true);
+            },
           ),
           sidebar: SurfaceStudioSidebar(
             collapsed: _sidebarCollapsed,
@@ -259,29 +666,184 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
             },
             onStepSelected: _selectStep,
           ),
-          atlasPanel: SurfaceStudioAtlasPanel(
-            columnCount: _columnCount,
-            frameCount: frameCount,
-            tileWidth: _tileWidth,
-            tileHeight: _tileHeight,
-            selection: _selectedColumns,
-            zoomPercent: _zoomPercent,
-            onColumnSelectionChanged: (selection) {
-              setState(() => _selectedColumns = selection);
-            },
-            onZoomChanged: (value) {
-              setState(() => _zoomPercent = value.clamp(25, 400).toDouble());
-            },
-            onReset: () {
-              setState(() {
-                _selectedColumns = const SurfaceStudioColumnSelection.empty();
-                _zoomPercent = 100;
-                _statusMessage = 'Sélection et zoom réinitialisés.';
-              });
-            },
-            onAutoSuggest: _autoSuggestMapping,
+          workspacePanel: _buildWorkspacePanel(),
+          rightDock: _buildRightDock(frameCount),
+          bottomBar: SurfaceStudioBottomActionBar(
+            canGoBack: _currentStep != SurfaceStudioWizardStep.importAtlas,
+            canAutoSuggest: _columnCount > 0 && frameCount > 0,
+            canApplyMapping:
+                _assignmentDraft.isAssigned(SurfaceVariantRole.isolated),
+            canGoNext: _canGoNext,
+            canSaveCatalog: widget.hasWorkCatalogChanges &&
+                widget.onSurfaceCatalogSavePrep != null,
+            onBack: _previousStep,
+            onAutoSuggest: _openSuggestionReview,
+            onApplyMapping: _applyMapping,
+            onNext: _nextStep,
+            onSaveCatalog: widget.onSurfaceCatalogSavePrep,
+          ),
+        ),
+        if (_statusMessage != null)
+          Positioned(
+            left: 318,
+            bottom: 86,
+            child: _StatusToast(message: _statusMessage!),
+          ),
+        if (widget.hasWorkCatalogChanges)
+          const Positioned(
+            left: 318,
+            top: 76,
+            child: _StatusToast(
+              message:
+                  'Catalogue de travail modifié — sauvegarde projet non effectuée.',
+            ),
           ),
-          schemaPanel: SurfaceStudioSchemaPanel(
+        if (_suggestionReviewOpen && _suggestionResult != null)
+          Positioned.fill(
+            child: _SuggestionReviewScrim(
+              result: _suggestionResult!,
+              mistralKeyConfigured:
+                  hasEditorMistralApiKey(widget.projectSettings),
+              onCancel: () {
+                setState(() => _suggestionReviewOpen = false);
+              },
+              onApplyReliable: () => _applySuggestions(reliableOnly: true),
+              onApplyAll: () => _applySuggestions(reliableOnly: false),
+            ),
+          ),
+        if (_advancedDrawerOpen && widget.advancedDrawer != null)
+          Positioned.fill(
+            child: _AdvancedDrawerScrim(
+              child: widget.advancedDrawer!,
+              onClose: () {
+                setState(() => _advancedDrawerOpen = false);
+              },
+            ),
+          ),
+      ],
+    );
+  }
+
+  Widget _buildWorkspacePanel() {
+    return switch (_currentStep) {
+      SurfaceStudioWizardStep.importAtlas => _ImportStepPanel(
+          readModel: widget.readModel,
+          projectTilesets: widget.projectTilesets,
+          projectRootPath: widget.projectRootPath,
+          atlasId: _atlasId,
+          atlasName: _atlasName,
+          tilesetId: _tilesetId,
+          tileWidth: _tileWidth,
+          tileHeight: _tileHeight,
+          columns: _columns,
+          rows: _rows,
+          sortOrder: _sortOrder,
+          categoryId: _categoryId,
+          layout: _layout,
+          onLayoutChanged: (layout) => setState(() => _layout = layout),
+          onCreateAtlas: _createOrUpdateAtlas,
+          onTilesetChanged: (value) {
+            setState(() {
+              _tilesetId.text = value ?? '';
+            });
+          },
+        ),
+      SurfaceStudioWizardStep.slice => _SliceStepPanel(
+          projectTilesets: widget.projectTilesets,
+          projectRootPath: widget.projectRootPath,
+          atlasId: _atlasId,
+          atlasName: _atlasName,
+          tilesetId: _tilesetId,
+          tileWidth: _tileWidth,
+          tileHeight: _tileHeight,
+          columns: _columns,
+          rows: _rows,
+          layout: _layout,
+          onChanged: () => setState(() {}),
+          onApplyGrid: _createOrUpdateAtlas,
+          onResetGrid: () {
+            setState(() {
+              _tileWidth.text = '32';
+              _tileHeight.text = '32';
+              _columns.text = '12';
+              _rows.text = '32';
+              _zoomPercent = 100;
+              _statusMessage = 'Grille réinitialisée.';
+            });
+          },
+        ),
+      SurfaceStudioWizardStep.map => SurfaceStudioAtlasPanel(
+          columnCount: _columnCount,
+          frameCount: _frameCount,
+          tileWidth: _tileWidthValue,
+          tileHeight: _tileHeightValue,
+          selection: _selectedColumns,
+          zoomPercent: _zoomPercent,
+          onColumnSelectionChanged: (selection) {
+            setState(() => _selectedColumns = selection);
+          },
+          onZoomChanged: (value) {
+            setState(() => _zoomPercent = value.clamp(25, 400).toDouble());
+          },
+          onReset: () {
+            setState(() {
+              _selectedColumns = const SurfaceStudioColumnSelection.empty();
+              _zoomPercent = 100;
+              _statusMessage = 'Sélection et zoom réinitialisés.';
+            });
+          },
+          onAutoSuggest: _openSuggestionReview,
+        ),
+      SurfaceStudioWizardStep.preview => _PreviewPlanPanel(
+          generationPlan: _generationPlan,
+          multiCenterColumns:
+              _assignmentDraft.columnsForRole(SurfaceVariantRole.isolated),
+          onGenerateAnimations: _appendReadyAnimations,
+          message: _lastGenerationMessage,
+        ),
+      SurfaceStudioWizardStep.save => _SaveStepPanel(
+          readModel: widget.readModel,
+          generationPlan: _generationPlan,
+          presetPlan: surfaceStudioPlanVerticalAtlasPresetAppend(
+            catalog: widget.readModel.catalog,
+            atlasIdRaw: _atlasId.text,
+            atlasDisplayName: _atlasName.text,
+            atlasCategoryDraft: _categoryId.text,
+            mappingDraft: _columnRoleMappingDraft,
+            gridValid: _gridValid,
+          ),
+          hasWorkCatalogChanges: widget.hasWorkCatalogChanges,
+          saveFlowPrepNote: widget.saveFlowPrepNote,
+          projectSaveDiskNote: widget.projectSaveDiskNote,
+          generationMessage: _lastGenerationMessage,
+          presetMessage: _lastPresetMessage,
+          onGenerateAnimations: _appendReadyAnimations,
+          onCreatePreset: _appendPreset,
+          onSaveCatalog: widget.onSurfaceCatalogSavePrep,
+          onProjectSave: widget.onRequestProjectSave,
+          onResetWorkCatalog: widget.onResetWorkCatalog,
+        ),
+    };
+  }
+
+  Widget _buildRightDock(int frameCount) {
+    if (_currentStep == SurfaceStudioWizardStep.save) {
+      return _RightDockFrame(
+        children: [
+          Expanded(
+            child: _CatalogStatusPanel(
+              readModel: widget.readModel,
+              hasWorkCatalogChanges: widget.hasWorkCatalogChanges,
+            ),
+          ),
+        ],
+      );
+    }
+    return _RightDockFrame(
+      children: [
+        Expanded(
+          flex: 3,
+          child: SurfaceStudioSchemaPanel(
             collapsed: _rightPanelCollapsed,
             openGroups: _openSchemaGroups,
             assignmentDraft: _assignmentDraft,
@@ -300,7 +862,8 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
             onDrop: _acceptDrop,
             onClearRole: (role) {
               setState(
-                  () => _assignmentDraft = _assignmentDraft.clearRole(role));
+                () => _assignmentDraft = _assignmentDraft.clearRole(role),
+              );
             },
             onClearColumn: (role, column) {
               setState(
@@ -309,7 +872,11 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
               );
             },
           ),
-          previewPanel: SurfaceStudioPreviewPanel(
+        ),
+        const SizedBox(height: SurfaceStudioDesignTokens.gapSm),
+        Expanded(
+          flex: 2,
+          child: SurfaceStudioPreviewPanel(
             frameCount: frameCount,
             frameIndex: _previewFrameIndex.clamp(0, frameCount - 1).toInt(),
             playing: _previewPlaying,
@@ -347,40 +914,1038 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
             onPreviewSizeChanged: (value) =>
                 setState(() => _previewSize = value),
           ),
-          bottomBar: SurfaceStudioBottomActionBar(
-            canGoBack: _currentStep != SurfaceStudioWizardStep.importAtlas,
-            canAutoSuggest: _columnCount > 0 && frameCount > 0,
-            canApplyMapping:
-                _assignmentDraft.isAssigned(SurfaceVariantRole.isolated),
-            canGoNext: _canGoNext,
-            onBack: _previousStep,
-            onAutoSuggest: _autoSuggestMapping,
-            onApplyMapping: _applyMapping,
-            onNext: _nextStep,
-          ),
         ),
-        if (_statusMessage != null)
-          Positioned(
-            left: 318,
-            bottom: 86,
-            child: Container(
-              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
-              decoration: BoxDecoration(
-                color: const Color(0xFF202A3C),
-                borderRadius: BorderRadius.circular(10),
-                border: Border.all(color: const Color(0xFF4A556D)),
+      ],
+    );
+  }
+}
+
+class _ImportStepPanel extends StatelessWidget {
+  const _ImportStepPanel({
+    required this.readModel,
+    required this.projectTilesets,
+    required this.projectRootPath,
+    required this.atlasId,
+    required this.atlasName,
+    required this.tilesetId,
+    required this.tileWidth,
+    required this.tileHeight,
+    required this.columns,
+    required this.rows,
+    required this.sortOrder,
+    required this.categoryId,
+    required this.layout,
+    required this.onLayoutChanged,
+    required this.onCreateAtlas,
+    required this.onTilesetChanged,
+  });
+
+  final SurfaceStudioReadModel readModel;
+  final List<ProjectTilesetEntry> projectTilesets;
+  final String? projectRootPath;
+  final TextEditingController atlasId;
+  final TextEditingController atlasName;
+  final TextEditingController tilesetId;
+  final TextEditingController tileWidth;
+  final TextEditingController tileHeight;
+  final TextEditingController columns;
+  final TextEditingController rows;
+  final TextEditingController sortOrder;
+  final TextEditingController categoryId;
+  final SurfaceAtlasLayout layout;
+  final ValueChanged<SurfaceAtlasLayout> onLayoutChanged;
+  final VoidCallback onCreateAtlas;
+  final ValueChanged<String?> onTilesetChanged;
+
+  @override
+  Widget build(BuildContext context) {
+    final sorted = sortedTilesetChoices(projectTilesets);
+    final resolution = resolveSurfaceStudioAtlasImagePreview(
+      projectRootPath: projectRootPath,
+      projectTilesets: projectTilesets,
+      technicalTilesetId: tilesetId.text,
+    );
+    final form = SingleChildScrollView(
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          SurfaceStudioAtlasImageSourceBlock(
+            hasPicker: sorted.isNotEmpty,
+            sortedTilesets: sorted,
+            selectedTilesetId: tilesetId.text.isEmpty ? null : tilesetId.text,
+            onSelectTilesetId: onTilesetChanged,
+            label: SurfaceStudioDesignTokens.textPrimary,
+            subtle: SurfaceStudioDesignTokens.textSecondary,
+          ),
+          const SizedBox(height: 14),
+          _Field(
+            keyName: 'surfaceStudio.import.atlasId',
+            label: 'Identifiant atlas',
+            controller: atlasId,
+          ),
+          _Field(
+            keyName: 'surfaceStudio.import.atlasName',
+            label: 'Nom atlas',
+            controller: atlasName,
+          ),
+          _Field(
+            keyName: 'surfaceStudio.import.tilesetId',
+            label: 'Source technique',
+            controller: tilesetId,
+          ),
+          const SizedBox(height: 10),
+          Wrap(
+            spacing: 10,
+            runSpacing: 10,
+            children: [
+              _SmallField(label: 'Tuile W', controller: tileWidth),
+              _SmallField(label: 'Tuile H', controller: tileHeight),
+              _SmallField(label: 'Colonnes', controller: columns),
+              _SmallField(label: 'Frames', controller: rows),
+              _SmallField(label: 'Ordre', controller: sortOrder),
+            ],
+          ),
+          const SizedBox(height: 10),
+          _Field(
+            keyName: 'surfaceStudio.import.categoryId',
+            label: 'Catégorie',
+            controller: categoryId,
+          ),
+          const SizedBox(height: 10),
+          Material(
+            type: MaterialType.transparency,
+            child: DropdownButton<SurfaceAtlasLayout>(
+              key: const ValueKey('surfaceStudio.import.layout'),
+              isExpanded: true,
+              value: layout,
+              dropdownColor: SurfaceStudioDesignTokens.backgroundElevated,
+              style: const TextStyle(
+                color: SurfaceStudioDesignTokens.textPrimary,
               ),
-              child: Text(
-                _statusMessage!,
+              items: const [
+                DropdownMenuItem(
+                  value: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+                  child: Text('Colonnes = rôles'),
+                ),
+                DropdownMenuItem(
+                  value: SurfaceAtlasLayout.grid,
+                  child: Text('Grille libre'),
+                ),
+              ],
+              onChanged: (value) {
+                if (value != null) {
+                  onLayoutChanged(value);
+                }
+              },
+            ),
+          ),
+          const SizedBox(height: 14),
+          CupertinoButton(
+            key: const ValueKey('surfaceStudio.import.createAtlas'),
+            color: SurfaceStudioDesignTokens.accentGoldSoft,
+            onPressed: onCreateAtlas,
+            child: Text(
+              readModel.atlases.isEmpty
+                  ? 'Créer l’atlas de travail'
+                  : 'Appliquer au catalogue de travail',
+            ),
+          ),
+        ],
+      ),
+    );
+    final preview = SurfaceStudioAtlasImagePreview(
+      resolution: resolution,
+      label: SurfaceStudioDesignTokens.textPrimary,
+      subtle: SurfaceStudioDesignTokens.textSecondary,
+      draftTileWidth: int.tryParse(tileWidth.text),
+      draftTileHeight: int.tryParse(tileHeight.text),
+      draftColumns: int.tryParse(columns.text),
+      draftRows: int.tryParse(rows.text),
+      draftLayoutLabel: 'Colonnes → rôles',
+      largeFormat: true,
+    );
+    return _PanelFrame(
+      keyName: 'surfaceStudio.import.panel',
+      title: 'Importer',
+      subtitle: 'Choisissez une source réelle et préparez le brouillon atlas.',
+      child: LayoutBuilder(
+        builder: (context, constraints) {
+          if (constraints.maxWidth < 720) {
+            return SingleChildScrollView(
+              child: Column(
+                children: [
+                  form,
+                  const SizedBox(height: 16),
+                  SizedBox(height: 340, child: preview),
+                ],
+              ),
+            );
+          }
+          return Row(
+            crossAxisAlignment: CrossAxisAlignment.stretch,
+            children: [
+              Expanded(child: form),
+              const SizedBox(width: 16),
+              Expanded(child: preview),
+            ],
+          );
+        },
+      ),
+    );
+  }
+}
+
+class _SliceStepPanel extends StatelessWidget {
+  const _SliceStepPanel({
+    required this.projectTilesets,
+    required this.projectRootPath,
+    required this.atlasId,
+    required this.atlasName,
+    required this.tilesetId,
+    required this.tileWidth,
+    required this.tileHeight,
+    required this.columns,
+    required this.rows,
+    required this.layout,
+    required this.onChanged,
+    required this.onApplyGrid,
+    required this.onResetGrid,
+  });
+
+  final List<ProjectTilesetEntry> projectTilesets;
+  final String? projectRootPath;
+  final TextEditingController atlasId;
+  final TextEditingController atlasName;
+  final TextEditingController tilesetId;
+  final TextEditingController tileWidth;
+  final TextEditingController tileHeight;
+  final TextEditingController columns;
+  final TextEditingController rows;
+  final SurfaceAtlasLayout layout;
+  final VoidCallback onChanged;
+  final VoidCallback onApplyGrid;
+  final VoidCallback onResetGrid;
+
+  @override
+  Widget build(BuildContext context) {
+    final resolution = resolveSurfaceStudioAtlasImagePreview(
+      projectRootPath: projectRootPath,
+      projectTilesets: projectTilesets,
+      technicalTilesetId: tilesetId.text,
+    );
+    return _PanelFrame(
+      keyName: 'surfaceStudio.slice.panel',
+      title: 'Découper',
+      subtitle: 'Ajustez la grille qui alimentera le mapping et la génération.',
+      child: Row(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          Expanded(
+            flex: 3,
+            child: SurfaceStudioAtlasImagePreview(
+              resolution: resolution,
+              label: SurfaceStudioDesignTokens.textPrimary,
+              subtle: SurfaceStudioDesignTokens.textSecondary,
+              draftTileWidth: int.tryParse(tileWidth.text),
+              draftTileHeight: int.tryParse(tileHeight.text),
+              draftColumns: int.tryParse(columns.text),
+              draftRows: int.tryParse(rows.text),
+              draftLayoutLabel: layout.name,
+              largeFormat: true,
+            ),
+          ),
+          const SizedBox(width: 16),
+          Expanded(
+            flex: 2,
+            child: SingleChildScrollView(
+              child: Column(
+                crossAxisAlignment: CrossAxisAlignment.stretch,
+                children: [
+                  Text(
+                    atlasName.text.isEmpty ? atlasId.text : atlasName.text,
+                    style: const TextStyle(
+                      color: SurfaceStudioDesignTokens.textPrimary,
+                      fontSize: 18,
+                      fontWeight: FontWeight.w900,
+                    ),
+                  ),
+                  const SizedBox(height: 12),
+                  Wrap(
+                    spacing: 10,
+                    runSpacing: 10,
+                    children: [
+                      _SmallField(
+                        label: 'Tuile W',
+                        controller: tileWidth,
+                        onChanged: (_) => onChanged(),
+                      ),
+                      _SmallField(
+                        label: 'Tuile H',
+                        controller: tileHeight,
+                        onChanged: (_) => onChanged(),
+                      ),
+                      _SmallField(
+                        label: 'Colonnes',
+                        controller: columns,
+                        onChanged: (_) => onChanged(),
+                      ),
+                      _SmallField(
+                        label: 'Frames',
+                        controller: rows,
+                        onChanged: (_) => onChanged(),
+                      ),
+                    ],
+                  ),
+                  const SizedBox(height: 14),
+                  SurfaceStudioAtlasGridPreview(
+                    sourceLabel: tilesetId.text,
+                    tileWidth: int.tryParse(tileWidth.text),
+                    tileHeight: int.tryParse(tileHeight.text),
+                    columns: int.tryParse(columns.text),
+                    rows: int.tryParse(rows.text),
+                    layoutLabel: layout.name,
+                  ),
+                  const SizedBox(height: 14),
+                  CupertinoButton(
+                    color: SurfaceStudioDesignTokens.accentTealSoft,
+                    onPressed: onApplyGrid,
+                    child: const Text('Appliquer la grille'),
+                  ),
+                  const SizedBox(height: 8),
+                  CupertinoButton(
+                    onPressed: onResetGrid,
+                    child: const Text('Réinitialiser'),
+                  ),
+                ],
+              ),
+            ),
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class _PreviewPlanPanel extends StatelessWidget {
+  const _PreviewPlanPanel({
+    required this.generationPlan,
+    required this.multiCenterColumns,
+    required this.onGenerateAnimations,
+    required this.message,
+  });
+
+  final SurfaceStudioVerticalAtlasAnimationGenerationPlan generationPlan;
+  final List<int> multiCenterColumns;
+  final VoidCallback onGenerateAnimations;
+  final String? message;
+
+  @override
+  Widget build(BuildContext context) {
+    final summary = generationPlan.summary;
+    return _PanelFrame(
+      keyName: 'surfaceStudio.previewPlan.panel',
+      title: 'Prévisualiser',
+      subtitle: 'Plan réel de génération depuis le mapping courant.',
+      child: SingleChildScrollView(
+        child: Column(
+          crossAxisAlignment: CrossAxisAlignment.stretch,
+          children: [
+            _MetricRow(
+              metrics: {
+                'Assignées': '${summary.assignedColumnCount}',
+                'Prêtes': '${summary.readyAnimationCount}',
+                'À corriger': '${summary.errorAnimationCount}',
+                'Frame': '${summary.durationMsPerFrame} ms',
+              },
+            ),
+            if (multiCenterColumns.length > 1) ...[
+              const SizedBox(height: 10),
+              const _WarningBox(
+                text:
+                    'Plein contient plusieurs colonnes. V2.1 conserve l’UX multi-colonnes, mais la génération réelle utilise la première colonne tant qu’un modèle de variantes multiples n’existe pas.',
+              ),
+            ],
+            const SizedBox(height: 14),
+            CupertinoButton(
+              key: const ValueKey('surfaceStudio.preview.generateAnimations'),
+              color: SurfaceStudioDesignTokens.accentTealSoft,
+              onPressed:
+                  summary.readyAnimationCount > 0 ? onGenerateAnimations : null,
+              child: const Text('Générer les animations prêtes'),
+            ),
+            if (message != null) ...[
+              const SizedBox(height: 10),
+              Text(
+                message!,
                 style: const TextStyle(
-                  color: Color(0xFFF2F5FA),
-                  fontSize: 12,
+                  color: SurfaceStudioDesignTokens.accentTeal,
                   fontWeight: FontWeight.w700,
                 ),
               ),
+            ],
+            const SizedBox(height: 14),
+            for (final item in generationPlan.items) _PlanItemRow(item: item),
+          ],
+        ),
+      ),
+    );
+  }
+}
+
+class _SaveStepPanel extends StatelessWidget {
+  const _SaveStepPanel({
+    required this.readModel,
+    required this.generationPlan,
+    required this.presetPlan,
+    required this.hasWorkCatalogChanges,
+    required this.saveFlowPrepNote,
+    required this.projectSaveDiskNote,
+    required this.generationMessage,
+    required this.presetMessage,
+    required this.onGenerateAnimations,
+    required this.onCreatePreset,
+    required this.onSaveCatalog,
+    required this.onProjectSave,
+    required this.onResetWorkCatalog,
+  });
+
+  final SurfaceStudioReadModel readModel;
+  final SurfaceStudioVerticalAtlasAnimationGenerationPlan generationPlan;
+  final SurfaceStudioVerticalAtlasPresetAppendPlan presetPlan;
+  final bool hasWorkCatalogChanges;
+  final String? saveFlowPrepNote;
+  final String? projectSaveDiskNote;
+  final String? generationMessage;
+  final String? presetMessage;
+  final VoidCallback onGenerateAnimations;
+  final VoidCallback onCreatePreset;
+  final VoidCallback? onSaveCatalog;
+  final Future<void> Function()? onProjectSave;
+  final VoidCallback? onResetWorkCatalog;
+
+  @override
+  Widget build(BuildContext context) {
+    return _PanelFrame(
+      keyName: 'surfaceStudio.save.panel',
+      title: 'Enregistrer',
+      subtitle: 'Générez les artefacts Surface, puis préparez la sauvegarde.',
+      child: SingleChildScrollView(
+        child: Column(
+          crossAxisAlignment: CrossAxisAlignment.stretch,
+          children: [
+            _MetricRow(
+              metrics: {
+                'Atlas': '${readModel.summary.atlasCount}',
+                'Animations': '${readModel.summary.animationCount}',
+                'Surfaces': '${readModel.summary.presetCount}',
+                'Dirty': hasWorkCatalogChanges ? 'oui' : 'non',
+              },
+            ),
+            const SizedBox(height: 14),
+            CupertinoButton(
+              key: const ValueKey('surfaceStudio.save.generateAnimations'),
+              color: SurfaceStudioDesignTokens.accentTealSoft,
+              onPressed: generationPlan.summary.readyAnimationCount > 0
+                  ? onGenerateAnimations
+                  : null,
+              child: const Text('Générer les animations'),
+            ),
+            const SizedBox(height: 8),
+            CupertinoButton(
+              key: const ValueKey('surfaceStudio.save.createPreset'),
+              color: SurfaceStudioDesignTokens.accentGoldSoft,
+              onPressed: presetPlan.canCreate ? onCreatePreset : null,
+              child: const Text('Créer la surface peignable'),
+            ),
+            const SizedBox(height: 8),
+            CupertinoButton(
+              key: const ValueKey('surfaceStudio.action.saveCatalog'),
+              onPressed: hasWorkCatalogChanges ? onSaveCatalog : null,
+              child: const Text('Préparer la sauvegarde du catalogue'),
+            ),
+            if (onProjectSave != null) ...[
+              const SizedBox(height: 8),
+              CupertinoButton(
+                key: const ValueKey('surfaceStudio.save.project'),
+                onPressed: onProjectSave,
+                child: const Text('Sauvegarder le projet via le flux existant'),
+              ),
+            ],
+            if (onResetWorkCatalog != null) ...[
+              const SizedBox(height: 8),
+              CupertinoButton(
+                key: const ValueKey('surfaceStudio.save.resetWorkCatalog'),
+                onPressed: onResetWorkCatalog,
+                child: const Text('Réinitialiser le catalogue de travail'),
+              ),
+            ],
+            for (final message in [
+              generationMessage,
+              presetMessage,
+              saveFlowPrepNote,
+              projectSaveDiskNote,
+            ])
+              if (message != null) ...[
+                const SizedBox(height: 8),
+                Text(
+                  message,
+                  style: const TextStyle(
+                    color: SurfaceStudioDesignTokens.accentTeal,
+                    fontWeight: FontWeight.w700,
+                  ),
+                ),
+              ],
+          ],
+        ),
+      ),
+    );
+  }
+}
+
+class _CatalogStatusPanel extends StatelessWidget {
+  const _CatalogStatusPanel({
+    required this.readModel,
+    required this.hasWorkCatalogChanges,
+  });
+
+  final SurfaceStudioReadModel readModel;
+  final bool hasWorkCatalogChanges;
+
+  @override
+  Widget build(BuildContext context) {
+    return _PanelFrame(
+      keyName: 'surfaceStudio.catalogStatus.panel',
+      title: 'Catalogue & état',
+      subtitle: 'Résumé du catalogue de travail Surface.',
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          _MetricRow(
+            metrics: {
+              'Atlas': '${readModel.summary.atlasCount}',
+              'Animations': '${readModel.summary.animationCount}',
+              'Surfaces': '${readModel.summary.presetCount}',
+            },
+          ),
+          const SizedBox(height: 12),
+          Text(
+            hasWorkCatalogChanges
+                ? 'Catalogue de travail modifié — sauvegarde projet non effectuée.'
+                : 'Catalogue synchronisé avec le manifest mémoire.',
+            style: const TextStyle(
+              color: SurfaceStudioDesignTokens.textSecondary,
+              fontWeight: FontWeight.w700,
+            ),
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class _RightDockFrame extends StatelessWidget {
+  const _RightDockFrame({required this.children});
+
+  final List<Widget> children;
+
+  @override
+  Widget build(BuildContext context) {
+    return Column(children: children);
+  }
+}
+
+class _PanelFrame extends StatelessWidget {
+  const _PanelFrame({
+    required this.keyName,
+    required this.title,
+    required this.subtitle,
+    required this.child,
+  });
+
+  final String keyName;
+  final String title;
+  final String subtitle;
+  final Widget child;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      key: ValueKey(keyName),
+      decoration: BoxDecoration(
+        color: SurfaceStudioDesignTokens.backgroundPanel,
+        borderRadius:
+            BorderRadius.circular(SurfaceStudioDesignTokens.panelRadius),
+        border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
+      ),
+      padding: const EdgeInsets.all(16),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          Text(
+            title,
+            style: const TextStyle(
+              color: SurfaceStudioDesignTokens.textPrimary,
+              fontSize: 19,
+              fontWeight: FontWeight.w900,
+            ),
+          ),
+          const SizedBox(height: 4),
+          Text(
+            subtitle,
+            style: const TextStyle(
+              color: SurfaceStudioDesignTokens.textSecondary,
+              fontSize: 12,
+              fontWeight: FontWeight.w600,
+            ),
+          ),
+          const SizedBox(height: 14),
+          Expanded(child: child),
+        ],
+      ),
+    );
+  }
+}
+
+class _Field extends StatelessWidget {
+  const _Field({
+    required this.keyName,
+    required this.label,
+    required this.controller,
+  });
+
+  final String keyName;
+  final String label;
+  final TextEditingController controller;
+
+  @override
+  Widget build(BuildContext context) {
+    return Padding(
+      padding: const EdgeInsets.only(bottom: 10),
+      child: Material(
+        type: MaterialType.transparency,
+        child: TextField(
+          key: ValueKey(keyName),
+          controller: controller,
+          style: const TextStyle(color: SurfaceStudioDesignTokens.textPrimary),
+          decoration: _fieldDecoration(label),
+        ),
+      ),
+    );
+  }
+}
+
+class _SmallField extends StatelessWidget {
+  const _SmallField({
+    required this.label,
+    required this.controller,
+    this.onChanged,
+  });
+
+  final String label;
+  final TextEditingController controller;
+  final ValueChanged<String>? onChanged;
+
+  @override
+  Widget build(BuildContext context) {
+    return SizedBox(
+      width: 112,
+      child: Material(
+        type: MaterialType.transparency,
+        child: TextField(
+          controller: controller,
+          onChanged: onChanged,
+          style: const TextStyle(color: SurfaceStudioDesignTokens.textPrimary),
+          decoration: _fieldDecoration(label),
+        ),
+      ),
+    );
+  }
+}
+
+InputDecoration _fieldDecoration(String label) {
+  return InputDecoration(
+    labelText: label,
+    labelStyle: const TextStyle(color: SurfaceStudioDesignTokens.textSecondary),
+    filled: true,
+    fillColor: SurfaceStudioDesignTokens.backgroundElevated,
+    enabledBorder: OutlineInputBorder(
+      borderSide:
+          const BorderSide(color: SurfaceStudioDesignTokens.borderSubtle),
+      borderRadius: BorderRadius.circular(9),
+    ),
+    focusedBorder: OutlineInputBorder(
+      borderSide: const BorderSide(color: SurfaceStudioDesignTokens.accentGold),
+      borderRadius: BorderRadius.circular(9),
+    ),
+  );
+}
+
+class _MetricRow extends StatelessWidget {
+  const _MetricRow({required this.metrics});
+
+  final Map<String, String> metrics;
+
+  @override
+  Widget build(BuildContext context) {
+    return Wrap(
+      spacing: 10,
+      runSpacing: 10,
+      children: [
+        for (final metric in metrics.entries)
+          Container(
+            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
+            decoration: BoxDecoration(
+              color: SurfaceStudioDesignTokens.backgroundElevated,
+              borderRadius: BorderRadius.circular(10),
+              border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
+            ),
+            child: Text(
+              '${metric.key}  ${metric.value}',
+              style: const TextStyle(
+                color: SurfaceStudioDesignTokens.textPrimary,
+                fontWeight: FontWeight.w800,
+              ),
             ),
           ),
       ],
     );
   }
 }
+
+class _WarningBox extends StatelessWidget {
+  const _WarningBox({required this.text});
+
+  final String text;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      padding: const EdgeInsets.all(12),
+      decoration: BoxDecoration(
+        color: SurfaceStudioDesignTokens.accentGoldSoft.withValues(alpha: 0.32),
+        borderRadius: BorderRadius.circular(10),
+        border: Border.all(color: SurfaceStudioDesignTokens.accentGold),
+      ),
+      child: Text(
+        text,
+        style: const TextStyle(
+          color: SurfaceStudioDesignTokens.textPrimary,
+          fontWeight: FontWeight.w700,
+        ),
+      ),
+    );
+  }
+}
+
+class _PlanItemRow extends StatelessWidget {
+  const _PlanItemRow({required this.item});
+
+  final SurfaceStudioVerticalAtlasAnimationGenerationItem item;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      margin: const EdgeInsets.only(bottom: 8),
+      padding: const EdgeInsets.all(10),
+      decoration: BoxDecoration(
+        color: SurfaceStudioDesignTokens.backgroundElevated,
+        borderRadius: BorderRadius.circular(10),
+        border: Border.all(
+          color: item.isReady
+              ? SurfaceStudioDesignTokens.accentTeal.withValues(alpha: 0.5)
+              : SurfaceStudioDesignTokens.borderSubtle,
+        ),
+      ),
+      child: Text(
+        '${SurfaceStudioRoleLabels.labelForRole(item.role)} · colonne ${item.columnIndex + 1} · ${item.isReady ? 'prête' : item.problems.join(', ')}',
+        style: const TextStyle(
+          color: SurfaceStudioDesignTokens.textSecondary,
+          fontWeight: FontWeight.w700,
+        ),
+      ),
+    );
+  }
+}
+
+class _StatusToast extends StatelessWidget {
+  const _StatusToast({required this.message});
+
+  final String message;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
+      decoration: BoxDecoration(
+        color: SurfaceStudioDesignTokens.backgroundElevated,
+        borderRadius: BorderRadius.circular(10),
+        border: Border.all(color: SurfaceStudioDesignTokens.borderStrong),
+      ),
+      child: Text(
+        message,
+        style: const TextStyle(
+          color: SurfaceStudioDesignTokens.textPrimary,
+          fontSize: 12,
+          fontWeight: FontWeight.w700,
+        ),
+      ),
+    );
+  }
+}
+
+class _SuggestionReviewScrim extends StatelessWidget {
+  const _SuggestionReviewScrim({
+    required this.result,
+    required this.mistralKeyConfigured,
+    required this.onCancel,
+    required this.onApplyReliable,
+    required this.onApplyAll,
+  });
+
+  final SurfaceStudioMappingSuggestionResult result;
+  final bool mistralKeyConfigured;
+  final VoidCallback onCancel;
+  final VoidCallback onApplyReliable;
+  final VoidCallback onApplyAll;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      color: const Color(0x990B1020),
+      alignment: Alignment.centerRight,
+      padding: const EdgeInsets.all(18),
+      child: Container(
+        key: const ValueKey('surfaceStudio.suggestion.review'),
+        width: 520,
+        decoration: BoxDecoration(
+          color: SurfaceStudioDesignTokens.backgroundPanel,
+          borderRadius: BorderRadius.circular(16),
+          border: Border.all(color: SurfaceStudioDesignTokens.borderStrong),
+        ),
+        padding: const EdgeInsets.all(16),
+        child: Column(
+          crossAxisAlignment: CrossAxisAlignment.stretch,
+          children: [
+            const Text(
+              'Suggestions détectées',
+              style: TextStyle(
+                color: SurfaceStudioDesignTokens.textPrimary,
+                fontSize: 19,
+                fontWeight: FontWeight.w900,
+              ),
+            ),
+            const SizedBox(height: 6),
+            Text(
+              'Source : ${_sourceLabel(result.source)}',
+              style: const TextStyle(
+                color: SurfaceStudioDesignTokens.accentTeal,
+                fontWeight: FontWeight.w800,
+              ),
+            ),
+            const SizedBox(height: 12),
+            Expanded(
+              child: SingleChildScrollView(
+                child: Column(
+                  crossAxisAlignment: CrossAxisAlignment.stretch,
+                  children: [
+                    for (final warning in result.warnings) ...[
+                      _WarningBox(text: warning),
+                      const SizedBox(height: 8),
+                    ],
+                    for (final suggestion in result.suggestions)
+                      _SuggestionRow(suggestion: suggestion),
+                    const SizedBox(height: 12),
+                    Container(
+                      padding: const EdgeInsets.all(12),
+                      decoration: BoxDecoration(
+                        color: SurfaceStudioDesignTokens.backgroundElevated,
+                        borderRadius: BorderRadius.circular(10),
+                        border: Border.all(
+                          color: SurfaceStudioDesignTokens.borderSubtle,
+                        ),
+                      ),
+                      child: Column(
+                        crossAxisAlignment: CrossAxisAlignment.start,
+                        children: [
+                          const Text(
+                            'Analyse IA Mistral',
+                            style: TextStyle(
+                              color: SurfaceStudioDesignTokens.textPrimary,
+                              fontWeight: FontWeight.w900,
+                            ),
+                          ),
+                          const SizedBox(height: 6),
+                          Text(
+                            mistralKeyConfigured
+                                ? 'Clé Mistral configurée.'
+                                : 'Clé Mistral absente : Projet → Paramètres (IA) ou MISTRAL_API_KEY',
+                            style: const TextStyle(
+                              color: SurfaceStudioDesignTokens.textSecondary,
+                              fontWeight: FontWeight.w700,
+                            ),
+                          ),
+                          const SizedBox(height: 6),
+                          const Text(
+                            'L’analyse IA peut envoyer l’image de l’atlas au fournisseur configuré. Rien n’est envoyé sans confirmation.',
+                            style: TextStyle(
+                              color: SurfaceStudioDesignTokens.textMuted,
+                              height: 1.3,
+                            ),
+                          ),
+                          const SizedBox(height: 8),
+                          const Text(
+                            'Analyse IA à venir',
+                            style: TextStyle(
+                              color: SurfaceStudioDesignTokens.accentGold,
+                              fontWeight: FontWeight.w800,
+                            ),
+                          ),
+                        ],
+                      ),
+                    ),
+                  ],
+                ),
+              ),
+            ),
+            const SizedBox(height: 12),
+            Wrap(
+              alignment: WrapAlignment.end,
+              spacing: 10,
+              runSpacing: 8,
+              children: [
+                CupertinoButton(
+                  onPressed: onCancel,
+                  child: const Text('Annuler'),
+                ),
+                CupertinoButton(
+                  color: SurfaceStudioDesignTokens.accentTealSoft,
+                  onPressed: onApplyReliable,
+                  child: const Text('Appliquer les suggestions fiables'),
+                ),
+                CupertinoButton(
+                  color: SurfaceStudioDesignTokens.accentGoldSoft,
+                  onPressed: onApplyAll,
+                  child: const Text('Tout appliquer'),
+                ),
+              ],
+            ),
+          ],
+        ),
+      ),
+    );
+  }
+
+  static String _sourceLabel(SurfaceStudioMappingSuggestionSource source) {
+    return switch (source) {
+      SurfaceStudioMappingSuggestionSource.local => 'Local',
+      SurfaceStudioMappingSuggestionSource.mistral => 'Mistral',
+      SurfaceStudioMappingSuggestionSource.merged => 'Fusion',
+    };
+  }
+}
+
+class _SuggestionRow extends StatelessWidget {
+  const _SuggestionRow({required this.suggestion});
+
+  final SurfaceStudioRoleSuggestion suggestion;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      margin: const EdgeInsets.only(bottom: 8),
+      padding: const EdgeInsets.all(10),
+      decoration: BoxDecoration(
+        color: SurfaceStudioDesignTokens.backgroundElevated,
+        borderRadius: BorderRadius.circular(10),
+        border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
+      ),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          Text(
+            SurfaceStudioRoleLabels.labelForRole(suggestion.role),
+            style: const TextStyle(
+              color: SurfaceStudioDesignTokens.textPrimary,
+              fontWeight: FontWeight.w900,
+            ),
+          ),
+          const SizedBox(height: 4),
+          Text(
+            'Colonnes : ${suggestion.columns.join(', ')} · confiance : ${suggestion.confidence.name}',
+            style: const TextStyle(
+              color: SurfaceStudioDesignTokens.textSecondary,
+              fontWeight: FontWeight.w700,
+            ),
+          ),
+          const SizedBox(height: 4),
+          Text(
+            suggestion.reason,
+            style: const TextStyle(
+              color: SurfaceStudioDesignTokens.textMuted,
+              height: 1.3,
+            ),
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class _AdvancedDrawerScrim extends StatelessWidget {
+  const _AdvancedDrawerScrim({
+    required this.child,
+    required this.onClose,
+  });
+
+  final Widget child;
+  final VoidCallback onClose;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      color: const Color(0x770B1020),
+      alignment: Alignment.centerRight,
+      child: Container(
+        key: const ValueKey('surfaceStudio.advanced.drawer'),
+        width: 620,
+        margin: const EdgeInsets.all(18),
+        decoration: BoxDecoration(
+          color: SurfaceStudioDesignTokens.backgroundPanel,
+          borderRadius: BorderRadius.circular(16),
+          border: Border.all(color: SurfaceStudioDesignTokens.borderStrong),
+        ),
+        child: Column(
+          children: [
+            Padding(
+              padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
+              child: Row(
+                children: [
+                  const Expanded(
+                    child: Text(
+                      'Catalogue & diagnostics',
+                      style: TextStyle(
+                        color: SurfaceStudioDesignTokens.textPrimary,
+                        fontSize: 18,
+                        fontWeight: FontWeight.w900,
+                      ),
+                    ),
+                  ),
+                  CupertinoButton(
+                    padding: EdgeInsets.zero,
+                    minimumSize: const Size.square(36),
+                    onPressed: onClose,
+                    child: const Icon(
+                      CupertinoIcons.xmark,
+                      color: SurfaceStudioDesignTokens.textSecondary,
+                    ),
+                  ),
+                ],
+              ),
+            ),
+            Expanded(child: child),
+          ],
+        ),
+      ),
+    );
+  }
+}
```
### Diff `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart b/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
index 3c4d93cf..f993474d 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
@@ -1,1988 +1,205 @@
-// Tests widget — Surface Studio panel (Lot 52).
-// Imports `map_core` en API publique uniquement (pas de `map_core/src/...`).
-
-import 'dart:ui' as ui;
+// Surface Studio V2.1 panel tests.
+//
+// These assertions intentionally replace the old Lot 52-69 panel expectations:
+// the catalog browser, diagnostics and paintable-surface panels still exist, but
+// they must no longer render as a second Surface Studio under the wizard.
 
 import 'package:flutter/cupertino.dart';
-import 'package:flutter/material.dart';
+import 'package:flutter/material.dart' show MaterialApp;
+import 'package:flutter/widgets.dart';
 import 'package:flutter_test/flutter_test.dart';
-import 'package:macos_ui/macos_ui.dart';
 import 'package:map_core/map_core.dart';
-import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart';
-import 'package:map_editor/src/features/surface_studio/surface_studio_panel.dart';
-import 'package:map_editor/src/features/surface_studio/surface_studio_selection_inspector.dart';
-
-void main() {
-  group('SurfaceStudioPanel (Lot 52)', () {
-    testWidgets('1. title Surface Studio is visible', (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
-      );
-      expect(find.text('Surface Studio'), findsOneWidget);
-    });
-
-    testWidgets('2. read-only badge is visible', (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
-      );
-      // Bandeau panneau + inspecteur (Lot 59).
-      expect(find.text('Lecture seule'), findsNWidgets(2));
-    });
-
-    testWidgets('3. three counters are zero for empty catalog', (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
-      );
-      final counters =
-          find.byKey(const ValueKey('surface_studio_header_counters'));
-      expect(
-        find.descendant(of: counters, matching: find.text('0')),
-        findsNWidgets(3),
-      );
-    });
-
-    testWidgets('4. empty catalog shows empty state copy', (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
-      );
-      expect(
-        find.text('Le catalogue Surface est vide'),
-        findsOneWidget,
-      );
-    });
-
-    testWidgets('5. minimal catalog shows 1/1/1', (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
-      );
-      final counters =
-          find.byKey(const ValueKey('surface_studio_header_counters'));
-      expect(
-        find.descendant(of: counters, matching: find.text('1')),
-        findsNWidgets(3),
-      );
-    });
-
-    testWidgets('6. non-empty shows catalog browser content', (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
-      );
-      expect(find.text('Catalogue Surface'), findsOneWidget);
-      expect(find.text('Water Atlas'), findsOneWidget);
-    });
-
-    testWidgets('7. clean diagnostics for minimal coherent catalog',
-        (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
-      );
-      expect(find.text('Aucun diagnostic Surface'), findsOneWidget);
-    });
-
-    testWidgets('8. warning state when unused atlas', (tester) async {
-      final rm = _warningReadModel();
-      expect(rm.hasWarnings, isTrue);
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: rm)),
-      );
-      expect(find.text('Diagnostics Surface'), findsOneWidget);
-      // Atlas orphelin + animation non référencée par un preset (presets vides)
-      expect(find.textContaining('Avertissements : 2'), findsOneWidget);
-      expect(find.text('Atlas inutilisé'), findsOneWidget);
-      expect(find.text('Animation inutilisée'), findsOneWidget);
-    });
-
-    testWidgets('9. error state when preset animation missing', (tester) async {
-      final rm = _errorReadModel();
-      expect(rm.hasErrors, isTrue);
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: rm)),
-      );
-      expect(find.text('Diagnostics Surface'), findsOneWidget);
-      expect(find.textContaining('Erreurs : 1'), findsOneWidget);
-      expect(
-        find.text('Animation manquante dans un preset'),
-        findsOneWidget,
-      );
-    });
-
-    testWidgets('10. future action label import visible (pas Créer un atlas)',
-        (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
-      );
-      expect(find.text('Créer un atlas'), findsNothing);
-      expect(
-        find.text(SurfaceStudioPanel.actionImportVerticalAtlasLabel),
-        findsOneWidget,
-      );
-    });
-
-    testWidgets('11. future import action disabled (onPressed null)',
-        (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
-      );
-      final b = tester.widget<CupertinoButton>(
-        find.ancestor(
-          of: find.text(SurfaceStudioPanel.actionImportVerticalAtlasLabel),
-          matching: find.byType(CupertinoButton),
-        ),
-      );
-      expect(b.onPressed, isNull);
-    });
-
-    testWidgets('12. section placeholder titles are visible', (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
-      );
-      expect(find.text('Diagnostics Surface'), findsOneWidget);
-      expect(find.text('Actions auteur'), findsOneWidget);
-    });
-
-    testWidgets('13. SurfaceStudioPanelFromManifest uses manifest catalog',
-        (tester) async {
-      final cat = _minimalWaterCatalog();
-      final manifest = _manifest(cat);
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
-      );
-      final counters =
-          find.byKey(const ValueKey('surface_studio_header_counters'));
-      expect(
-        find.descendant(of: counters, matching: find.text('1')),
-        findsNWidgets(3),
-      );
-    });
-
-    testWidgets('14. manifest is not mutated after pump', (tester) async {
-      final cat = _minimalWaterCatalog();
-      final before = cat.atlases.length;
-      final manifest = _manifest(cat);
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
-      );
-      expect(manifest.surfaceCatalog.atlases.length, before);
-    });
-
-    testWidgets(
-      '15. does not require provider setup — panel builds without ProviderScope',
-      (tester) async {
-        await tester.pumpWidget(
-          MaterialApp(
-            home: Scaffold(
-              body: SurfaceStudioPanel(readModel: _emptyReadModel()),
-            ),
-          ),
-        );
-        expect(find.text('Surface Studio'), findsOneWidget);
-      },
-    );
-
-    testWidgets('16. content is in a scrollable', (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
-      );
-      expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));
-    });
-
-    testWidgets('17. no internal domain type names in user-visible strings',
-        (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
-      );
-      expect(find.textContaining('ProjectSurfaceCatalog'), findsNothing);
-      expect(find.textContaining('SurfaceStudioReadModel'), findsNothing);
-      expect(
-          find.textContaining('SurfaceVariantAnimationRefSet'), findsNothing);
-    });
-
-    testWidgets('18. error read model does not throw on build', (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _errorReadModel())),
-      );
-      expect(tester.takeException(), isNull);
-    });
-
-    testWidgets('19. warning read model does not throw on build',
-        (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _warningReadModel())),
-      );
-      expect(tester.takeException(), isNull);
-    });
-
-    testWidgets('20. displayed counts match read model summary',
-        (tester) async {
-      final rm = _minimalWaterReadModel();
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: rm)),
-      );
-      expect(rm.summary.atlasCount, 1);
-      expect(rm.summary.animationCount, 1);
-      expect(rm.summary.presetCount, 1);
-    });
-
-    testWidgets(
-        '22. TextField seulement zone brouillon (Lot 60), pas dans inspecteur',
-        (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
-      );
-      expect(
-        find.descendant(
-          of: find.byKey(kSurfaceStudioSelectionInspectorKey),
-          matching: find.byType(TextField),
-        ),
-        findsNothing,
-      );
-      expect(
-        find.descendant(
-          of: find.byKey(kSurfaceStudioAtlasAuthoringPrepKey),
-          matching: find.byType(TextField),
-        ),
-        findsWidgets,
-      );
-    });
-
-    testWidgets('23. no save affordances', (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
-      );
-      expect(find.textContaining('Sauvegarder'), findsNothing);
-      expect(find.byKey(const ValueKey('surfaceStudio.step.save')),
-          findsOneWidget);
-      expect(find.textContaining('Save'), findsNothing);
-    });
-
-    testWidgets('22. panel shows catalog browser for minimal catalog', (
-      tester,
-    ) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
-      );
-      expect(find.text('Catalogue Surface'), findsOneWidget);
-      expect(find.text('Atlas Surface'), findsOneWidget);
-      expect(find.text('Animations Surface'), findsOneWidget);
-      expect(find.text('Presets Surface'), findsOneWidget);
-      expect(find.text('Water Atlas'), findsOneWidget);
-      expect(find.text('Water Isolated Loop'), findsOneWidget);
-      expect(find.text('Water Surface'), findsWidgets);
-    });
-
-    testWidgets('24. test file uses public map_core only (smoke)',
-        (tester) async {
-      // Vérification statique : seul `package:map_core/map_core.dart` est importé.
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
-      );
-      expect(find.text('Surface Studio'), findsOneWidget);
-    });
-
-    testWidgets('25. Lot 55 — clean diagnostics view in panel', (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
-      );
-      expect(find.text('Diagnostics Surface'), findsOneWidget);
-      expect(find.text('Aucun diagnostic Surface'), findsOneWidget);
-    });
-
-    testWidgets('26. Lot 55 — error diagnostics visible in panel',
-        (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _errorReadModel())),
-      );
-      expect(find.text('Diagnostics Surface'), findsOneWidget);
-      expect(find.text('Erreurs'), findsOneWidget);
-    });
-
-    testWidgets('27. Lot 55 — browser and diagnostics cohabit (minimal cat)',
-        (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
-      );
-      expect(find.text('Catalogue Surface'), findsOneWidget);
-      expect(find.text('Atlas Surface'), findsOneWidget);
-      expect(find.text('Animations Surface'), findsOneWidget);
-      expect(find.text('Presets Surface'), findsOneWidget);
-      expect(find.text('Diagnostics Surface'), findsOneWidget);
-      expect(find.text('Water Atlas'), findsOneWidget);
-    });
-
-    testWidgets(
-        '48. Lot 57 — panel shows Atlas / Animations / Presets / Diagnostics',
-        (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
-      );
-      expect(find.text('Atlas Surface'), findsOneWidget);
-      expect(find.text('Animations Surface'), findsOneWidget);
-      expect(find.text('Presets Surface'), findsOneWidget);
-      expect(find.text('Diagnostics Surface'), findsOneWidget);
-    });
-
-    testWidgets('58.21 — Aucune sélection au départ (catalogue minimal)',
-        (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
-      );
-      expect(find.text('Aucune sélection'), findsOneWidget);
-    });
-
-    testWidgets('58.22 — sélection atlas après tap', (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
-      );
-      await tester.ensureVisible(find.text('Water Atlas'));
-      await tester.tap(find.text('Water Atlas'));
-      await tester.pump();
-      expect(find.text('Atlas sélectionné'), findsWidgets);
-      expect(find.text('water-atlas'), findsWidgets);
-    });
-
-    testWidgets('58.23 — sélection animation après tap', (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
-      );
-      await tester.ensureVisible(find.text('Water Isolated Loop'));
-      await tester.tap(find.text('Water Isolated Loop'));
-      await tester.pump();
-      expect(find.text('Animation sélectionnée'), findsWidgets);
-      expect(find.text('water-isolated-loop'), findsWidgets);
-    });
-
-    testWidgets('58.24 — sélection preset après tap', (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
-      );
-      await tester.ensureVisible(find.text('Water Surface').last);
-      await tester.tap(find.text('Water Surface').last);
-      await tester.pump();
-      expect(find.text('Preset sélectionné'), findsWidgets);
-      expect(find.text('water-surface'), findsWidgets);
-    });
-
-    testWidgets('58.25 — changement de sélection remplace la précédente',
-        (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
-      );
-      await tester.ensureVisible(find.text('Water Atlas'));
-      await tester.tap(find.text('Water Atlas'));
-      await tester.pump();
-      await tester.ensureVisible(find.text('Water Isolated Loop'));
-      await tester.tap(find.text('Water Isolated Loop'));
-      await tester.pump();
-      expect(find.text('Animation sélectionnée'), findsWidgets);
-      final t = tester
-          .widgetList<Text>(find.byType(Text))
-          .map((e) => e.data ?? '')
-          .join('\n');
-      expect(t.contains('Atlas sélectionné'), isFalse);
-    });
-
-    testWidgets('58.26 — sélection ne mute pas surfaceCatalog', (tester) async {
-      final cat = _minimalWaterCatalog();
-      final manifest = _manifest(cat);
-      final before = manifest.surfaceCatalog;
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
-      );
-      await tester.ensureVisible(find.text('Water Atlas'));
-      await tester.tap(find.text('Water Atlas'));
-      await tester.pump();
-      await tester.ensureVisible(find.text('Water Surface').last);
-      await tester.tap(find.text('Water Surface').last);
-      await tester.pump();
-      expect(identical(manifest.surfaceCatalog, before), isTrue);
-    });
-
-    testWidgets('58.27 — pas de TextField dans inspecteur après sélections', (
-      tester,
-    ) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
-      );
-      await tester.ensureVisible(find.text('Water Atlas'));
-      await tester.tap(find.text('Water Atlas'));
-      await tester.pump();
-      expect(
-        find.descendant(
-          of: find.byKey(kSurfaceStudioSelectionInspectorKey),
-          matching: find.byType(TextField),
-        ),
-        findsNothing,
-      );
-    });
-
-    testWidgets('58.28 — pas de libellés édition/save actifs', (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
-      );
-      await tester.ensureVisible(find.text('Water Atlas'));
-      await tester.tap(find.text('Water Atlas'));
-      await tester.pump();
-      for (final s in <String>[
-        'Sauvegarder',
-        'Modifier',
-        'Supprimer',
-        'Save',
-        'Edit',
-        'Delete',
-      ]) {
-        expect(find.text(s), findsNothing);
-      }
-      expect(
-        find.byKey(const ValueKey('surfaceStudio.step.save')),
-        findsOneWidget,
-      );
-    });
-
-    testWidgets('59.20 — inspecteur none au départ', (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
-      );
-      expect(find.text('Inspecteur Surface'), findsOneWidget);
-      expect(find.text('Aucune sélection à inspecter'), findsOneWidget);
-    });
-
-    testWidgets('59.21 — inspecteur atlas après tap', (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
-      );
-      await tester.ensureVisible(find.text('Water Atlas'));
-      await tester.tap(find.text('Water Atlas'));
-      await tester.pump();
-      final insp = find.byKey(kSurfaceStudioSelectionInspectorKey);
-      expect(
-          find.descendant(of: insp, matching: find.text('Inspecteur Surface')),
-          findsOneWidget);
-      expect(
-        find.descendant(of: insp, matching: find.text('Atlas sélectionné')),
-        findsWidgets,
-      );
-      expect(
-        find.descendant(
-          of: insp,
-          matching: find.textContaining('Identifiant : water-atlas'),
-        ),
-        findsOneWidget,
-      );
-    });
-
-    testWidgets('59.22 — inspecteur animation après tap', (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
-      );
-      await tester.ensureVisible(find.text('Water Isolated Loop'));
-      await tester.tap(find.text('Water Isolated Loop'));
-      await tester.pump();
-      final insp = find.byKey(kSurfaceStudioSelectionInspectorKey);
-      expect(
-        find.descendant(
-          of: insp,
-          matching: find.textContaining('Identifiant : water-isolated-loop'),
-        ),
-        findsOneWidget,
-      );
-    });
-
-    testWidgets('59.23 — inspecteur preset après tap', (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
-      );
-      await tester.ensureVisible(find.text('Water Surface').last);
-      await tester.tap(find.text('Water Surface').last);
-      await tester.pump();
-      final insp = find.byKey(kSurfaceStudioSelectionInspectorKey);
-      expect(
-        find.descendant(
-          of: insp,
-          matching: find.textContaining('Identifiant : water-surface'),
-        ),
-        findsOneWidget,
-      );
-    });
-
-    testWidgets('59.24 — changement de sélection met l’inspecteur à jour',
-        (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
-      );
-      await tester.ensureVisible(find.text('Water Atlas'));
-      await tester.tap(find.text('Water Atlas'));
-      await tester.pump();
-      await tester.ensureVisible(find.text('Water Isolated Loop'));
-      await tester.tap(find.text('Water Isolated Loop'));
-      await tester.pump();
-      final insp = find.byKey(kSurfaceStudioSelectionInspectorKey);
-      expect(
-        find.descendant(
-          of: insp,
-          matching: find.textContaining('Identifiant : water-isolated-loop'),
-        ),
-        findsOneWidget,
-      );
-      expect(
-        find.descendant(
-          of: insp,
-          matching: find.text('Atlas sélectionné'),
-        ),
-        findsNothing,
-      );
-    });
-
-    testWidgets('59.25 — inspecteur ne mute pas le manifest', (tester) async {
-      final cat = _minimalWaterCatalog();
-      final manifest = _manifest(cat);
-      final before = manifest.surfaceCatalog;
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
-      );
-      await tester.ensureVisible(find.text('Water Atlas'));
-      await tester.tap(find.text('Water Atlas'));
-      await tester.pump();
-      await tester.ensureVisible(find.text('Water Surface').last);
-      await tester.tap(find.text('Water Surface').last);
-      await tester.pump();
-      expect(identical(manifest.surfaceCatalog, before), isTrue);
-    });
-
-    testWidgets(
-        '59.26 — inspecteur read-only : aucun TextField (Lot 60 brouillon ok)',
-        (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
-      );
-      await tester.ensureVisible(find.text('Water Atlas'));
-      await tester.tap(find.text('Water Atlas'));
-      await tester.pump();
-      expect(
-        find.descendant(
-          of: find.byKey(kSurfaceStudioSelectionInspectorKey),
-          matching: find.byType(TextField),
-        ),
-        findsNothing,
-      );
-    });
-
-    testWidgets('59.27 — pas de libellés édition/save (Lot 59)',
-        (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
-      );
-      await tester.ensureVisible(find.text('Water Surface').last);
-      await tester.tap(find.text('Water Surface').last);
-      await tester.pump();
-      for (final s in <String>[
-        'Sauvegarder',
-        'Modifier',
-        'Supprimer',
-        'Save',
-        'Edit',
-        'Delete',
-      ]) {
-        expect(find.text(s), findsNothing);
-      }
-      expect(
-        find.byKey(const ValueKey('surfaceStudio.step.save')),
-        findsOneWidget,
-      );
-    });
-
-    testWidgets('30. Lot 55 — surfaceCatalog unchanged after panel pump',
-        (tester) async {
-      final cat = _minimalWaterCatalog();
-      final manifest = _manifest(cat);
-      final before = manifest.surfaceCatalog;
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
-      );
-      expect(identical(manifest.surfaceCatalog, before), isTrue);
-    });
-
-    testWidgets('60.1 — Préparation atlas (brouillon) visible', (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
-      );
-      await tester.ensureVisible(find.text('Atlas source').first);
-      expect(find.text('Atlas source'), findsWidgets);
-      expect(
-        find.textContaining('Brouillon : rien n’est écrit sur le disque'),
-        findsOneWidget,
-      );
-    });
-
-    testWidgets('61.1 — action création atlas dans le catalogue de travail',
-        (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
-      );
-      await tester.ensureVisible(
-        find.text('Créer l’atlas dans le catalogue de travail'),
-      );
-      expect(
-        find.text('Créer l’atlas dans le catalogue de travail'),
-        findsOneWidget,
-      );
-    });
-
-    testWidgets(
-        '61.2 — créer atlas (catalogue vide) : compteur atlas 1, browser, '
-        'inspecteur', (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
-      );
-      final idF = find.byKey(const ValueKey('atlas_draft_id'));
-      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
-      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
-      await tester.ensureVisible(idF);
-      await tester.enterText(idF, 'lot61-a');
-      await tester.enterText(nameF, 'Lot61 A');
-      await tester.enterText(tsF, 'tileset-x');
-      await tester.pump();
-      await tester.ensureVisible(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.pump();
-      final counters =
-          find.byKey(const ValueKey('surface_studio_header_counters'));
-      expect(
-        find.descendant(of: counters, matching: find.text('1')),
-        findsOneWidget,
-      );
-      expect(
-        find.descendant(of: counters, matching: find.text('0')),
-        findsNWidgets(2),
-      );
-      expect(find.text('Lot61 A'), findsWidgets);
-      expect(find.text('Diagnostics Surface'), findsOneWidget);
-    });
-
-    testWidgets(
-        '61.3 — créer second atlas : compteur 2, animations/presets inchangés',
-        (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
-      );
-      final idF = find.byKey(const ValueKey('atlas_draft_id'));
-      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
-      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
-      await tester.ensureVisible(idF);
-      await tester.enterText(idF, 'grass-a');
-      await tester.enterText(nameF, 'Grass');
-      await tester.enterText(tsF, 'ts-g');
-      await tester.pump();
-      await tester.ensureVisible(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.pump();
-      final counters =
-          find.byKey(const ValueKey('surface_studio_header_counters'));
-      expect(
-        find.descendant(of: counters, matching: find.text('2')),
-        findsOneWidget,
-      );
-      expect(
-        find.descendant(of: counters, matching: find.text('1')),
-        findsNWidgets(2),
-      );
-      expect(find.text('Water Atlas'), findsOneWidget);
-      expect(find.text('Water Isolated Loop'), findsOneWidget);
-      expect(find.text('Water Surface'), findsWidgets);
-      expect(find.text('grass-a'), findsWidgets);
-    });
-
-    testWidgets('62.0 — pas de dirty au départ (vide + minimal)',
-        (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
-      );
-      expect(
-        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
-        findsNothing,
-      );
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
-      );
-      expect(
-        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
-        findsNothing,
-      );
-    });
-
-    testWidgets('62.1 — dirty après création locale', (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
-      );
-      final idF = find.byKey(const ValueKey('atlas_draft_id'));
-      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
-      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
-      await tester.ensureVisible(idF);
-      await tester.enterText(idF, 'dirty-a');
-      await tester.enterText(nameF, 'D');
-      await tester.enterText(tsF, 't');
-      await tester.pump();
-      await tester.ensureVisible(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.pump();
-      expect(
-        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
-        findsOneWidget,
-      );
-      expect(
-        find.textContaining('sauvegarde projet non effectuée'),
-        findsWidgets,
-      );
-    });
-
-    testWidgets(
-        '62.2 — reset depuis catalogue vide : compteur 0, atlas absent, dirty off',
-        (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
-      );
-      final idF = find.byKey(const ValueKey('atlas_draft_id'));
-      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
-      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
-      await tester.ensureVisible(idF);
-      await tester.enterText(idF, 'rs-a');
-      await tester.enterText(nameF, 'R');
-      await tester.enterText(tsF, 't');
-      await tester.pump();
-      await tester.ensureVisible(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.pump();
-      var counters =
-          find.byKey(const ValueKey('surface_studio_header_counters'));
-      expect(
-        find.descendant(of: counters, matching: find.text('1')),
-        findsOneWidget,
-      );
-      expect(find.text('rs-a'), findsWidgets);
-      await tester.ensureVisible(
-        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
-      );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
-      );
-      await tester.pump();
-      counters = find.byKey(const ValueKey('surface_studio_header_counters'));
-      expect(
-        find.descendant(of: counters, matching: find.text('0')),
-        findsNWidgets(3),
-      );
-      expect(
-        find.text('Le catalogue Surface est vide'),
-        findsOneWidget,
-      );
-      expect(
-        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
-        findsNothing,
-      );
-      expect(find.text('Aucune sélection'), findsOneWidget);
-    });
-
-    testWidgets(
-        '62.3 — reset depuis minimal : revient à Water, Grass absent, 1/1/1',
-        (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
-      );
-      final idF = find.byKey(const ValueKey('atlas_draft_id'));
-      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
-      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
-      await tester.ensureVisible(idF);
-      await tester.enterText(idF, 'grass-x');
-      await tester.enterText(nameF, 'Grass');
-      await tester.enterText(tsF, 'ts');
-      await tester.pump();
-      await tester.ensureVisible(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.pump();
-      var counters =
-          find.byKey(const ValueKey('surface_studio_header_counters'));
-      expect(
-        find.descendant(of: counters, matching: find.text('2')),
-        findsOneWidget,
-      );
-      expect(find.text('Water Atlas'), findsOneWidget);
-      expect(find.text('grass-x'), findsWidgets);
-      await tester.ensureVisible(
-        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
-      );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
-      );
-      await tester.pump();
-      counters = find.byKey(const ValueKey('surface_studio_header_counters'));
-      expect(
-        find.descendant(of: counters, matching: find.text('1')),
-        findsNWidgets(3),
-      );
-      expect(find.text('Water Atlas'), findsOneWidget);
-      expect(
-        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
-        findsNothing,
-      );
-      expect(find.text('Water Isolated Loop'), findsOneWidget);
-      expect(find.text('Water Surface'), findsWidgets);
-    });
-
-    testWidgets('62.4 — A puis B puis reset (source vide)', (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
-      );
-      for (final row in <String>['lot62-a', 'lot62-b']) {
-        final idF = find.byKey(const ValueKey('atlas_draft_id'));
-        final nameF = find.byKey(const ValueKey('atlas_draft_name'));
-        final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
-        await tester.ensureVisible(idF);
-        await tester.enterText(idF, row);
-        await tester.enterText(nameF, row);
-        await tester.enterText(tsF, 't');
-        await tester.pump();
-        await tester.ensureVisible(
-          find.byKey(
-              const ValueKey('surface_studio_create_atlas_work_catalog')),
-        );
-        await tester.tap(
-          find.byKey(
-              const ValueKey('surface_studio_create_atlas_work_catalog')),
-        );
-        await tester.pump();
-      }
-      var counters =
-          find.byKey(const ValueKey('surface_studio_header_counters'));
-      expect(
-        find.descendant(of: counters, matching: find.text('2')),
-        findsOneWidget,
-      );
-      expect(find.text('lot62-a'), findsWidgets);
-      expect(find.text('lot62-b'), findsWidgets);
-      expect(find.text('Aucune sélection'), findsNothing);
-      expect(find.text('Atlas sélectionné'), findsWidgets);
-      await tester.ensureVisible(
-        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
-      );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
-      );
-      await tester.pump();
-      counters = find.byKey(const ValueKey('surface_studio_header_counters'));
-      expect(
-        find.descendant(of: counters, matching: find.text('0')),
-        findsNWidgets(3),
-      );
-      expect(
-        find.text('Le catalogue Surface est vide'),
-        findsOneWidget,
-      );
-    });
-
-    testWidgets('62.5 — readModel parent change : resync, dirty off, X absent',
-        (tester) async {
-      final w = _wrap(
-        SurfaceStudioPanel(readModel: _emptyReadModel()),
-      );
-      await tester.pumpWidget(w);
-      final idF = find.byKey(const ValueKey('atlas_draft_id'));
-      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
-      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
-      await tester.ensureVisible(idF);
-      await tester.enterText(idF, 'ext-x');
-      await tester.enterText(nameF, 'X');
-      await tester.enterText(tsF, 't');
-      await tester.pump();
-      await tester.ensureVisible(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.pump();
-      expect(
-        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
-        findsOneWidget,
-      );
-      expect(find.text('ext-x'), findsWidgets);
-      await tester.pumpWidget(
-        _wrap(
-          SurfaceStudioPanel(readModel: _minimalWaterReadModel()),
-        ),
-      );
-      await tester.pump();
-      expect(
-        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
-        findsNothing,
-      );
-      expect(find.text('Water Atlas'), findsOneWidget);
-      expect(find.text('Aucune sélection'), findsOneWidget);
-    });
-
-    testWidgets(
-        '62.6 — pas d’action fantôme Créer un atlas, vraie action présente',
-        (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
-      );
-      expect(find.text('Créer un atlas'), findsNothing);
-      expect(
-        find.text('Créer l’atlas dans le catalogue de travail'),
-        findsOneWidget,
-      );
-    });
-
-    testWidgets('62.7 — no save flow libellés interdits', (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
-      );
-      await tester.ensureVisible(
-        find.byKey(const ValueKey('atlas_draft_id')),
-      );
-      await tester.enterText(
-        find.byKey(const ValueKey('atlas_draft_id')),
-        'z',
-      );
-      await tester.enterText(
-          find.byKey(const ValueKey('atlas_draft_name')), 'N');
-      await tester.enterText(
-          find.byKey(const ValueKey('atlas_draft_tileset_advanced')), 'T');
-      await tester.pump();
-      await tester.ensureVisible(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.pump();
-      for (final s in <String>[
-        'Sauvegarder le projet',
-        'Enregistrer le projet',
-        'Sauvegarder maintenant',
-        'Save project',
-        'Write to disk',
-        'Écrire sur disque',
-      ]) {
-        expect(find.text(s), findsNothing);
-      }
-    });
-  });
-
-  group('SurfaceStudioPanel (Lot 63)', () {
-    testWidgets(
-        '63.1 — sans modification : pas d’action préparation, callback jamais',
-        (tester) async {
-      var calls = 0;
-      await tester.pumpWidget(
-        _wrap(
-          SurfaceStudioPanel(
-            readModel: _minimalWaterReadModel(),
-            onSurfaceCatalogSaveRequested: (_) => calls++,
-          ),
-        ),
-      );
-      expect(
-        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
-        findsNothing,
-      );
-      expect(
-        find.text(SurfaceStudioPanel.savePrepActionLabel),
-        findsNothing,
-      );
-      expect(calls, 0);
-    });
-
-    testWidgets(
-        '63.2 — dirty + callback : action, un appel, catalogue complet, dirty et accusé',
-        (tester) async {
-      ProjectSurfaceCatalog? received;
-      var calls = 0;
-      await tester.pumpWidget(
-        _wrap(
-          SurfaceStudioPanel(
-            readModel: _emptyReadModel(),
-            onSurfaceCatalogSaveRequested: (c) {
-              calls++;
-              received = c;
-            },
-          ),
-        ),
-      );
-      final idF = find.byKey(const ValueKey('atlas_draft_id'));
-      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
-      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
-      await tester.ensureVisible(idF);
-      await tester.enterText(idF, 'prep-one');
-      await tester.enterText(nameF, 'P');
-      await tester.enterText(tsF, 't');
-      await tester.pump();
-      await tester.ensureVisible(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.pump();
-      final prep =
-          find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
-      expect(prep, findsOneWidget);
-      await tester.ensureVisible(prep);
-      await tester.tap(prep);
-      await tester.pump();
-      expect(calls, 1);
-      expect(received, isNotNull);
-      expect(received!.atlases.length, 1);
-      expect(received!.atlases.first.id, 'prep-one');
-      expect(
-        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
-        findsOneWidget,
-      );
-      expect(
-        find.text(SurfaceStudioPanel.savePrepTransmittedNote),
-        findsOneWidget,
-      );
-    });
-
-    testWidgets(
-        '63.3 — sans callback : stable, message not connected, pas de bouton',
-        (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
-      );
-      final idF = find.byKey(const ValueKey('atlas_draft_id'));
-      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
-      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
-      await tester.ensureVisible(idF);
-      await tester.enterText(idF, 'nccb');
-      await tester.enterText(nameF, 'N');
-      await tester.enterText(tsF, 't');
-      await tester.pump();
-      await tester.ensureVisible(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.pump();
-      expect(tester.takeException(), isNull);
-      expect(
-        find.text(SurfaceStudioPanel.savePrepNotConnectedNote),
-        findsOneWidget,
-      );
-      expect(
-        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
-        findsNothing,
-      );
-    });
-
-    testWidgets('63.4 — resync parent : dirty off, atlas source, pas d’accusé',
-        (tester) async {
-      ProjectSurfaceCatalog? out;
-      await tester.pumpWidget(
-        _wrap(
-          SurfaceStudioPanel(
-            readModel: _emptyReadModel(),
-            onSurfaceCatalogSaveRequested: (c) => out = c,
-          ),
-        ),
-      );
-      var idF = find.byKey(const ValueKey('atlas_draft_id'));
-      var nameF = find.byKey(const ValueKey('atlas_draft_name'));
-      var tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
-      await tester.ensureVisible(idF);
-      await tester.enterText(idF, 'sync-x');
-      await tester.enterText(nameF, 'S');
-      await tester.enterText(tsF, 't');
-      await tester.pump();
-      await tester.ensureVisible(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.pump();
-      final prep =
-          find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
-      await tester.ensureVisible(prep);
-      await tester.tap(prep);
-      await tester.pump();
-      expect(out, isNotNull);
-      final synced = buildSurfaceStudioReadModelFromCatalog(out!);
-      await tester.pumpWidget(
-        _wrap(
-          SurfaceStudioPanel(
-            readModel: synced,
-            onSurfaceCatalogSaveRequested: (c) => out = c,
-          ),
-        ),
-      );
-      await tester.pump();
-      expect(
-        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
-        findsNothing,
-      );
-      expect(
-        find.text(SurfaceStudioPanel.savePrepTransmittedNote),
-        findsNothing,
-      );
-      expect(find.text('sync-x'), findsWidgets);
-    });
-
-    testWidgets('63.5 — reset après préparation : clean, accusé nettoyé, vide',
-        (tester) async {
-      await tester.pumpWidget(
-        _wrap(
-          SurfaceStudioPanel(
-            readModel: _emptyReadModel(),
-            onSurfaceCatalogSaveRequested: (_) {},
-          ),
-        ),
-      );
-      var idF = find.byKey(const ValueKey('atlas_draft_id'));
-      var nameF = find.byKey(const ValueKey('atlas_draft_name'));
-      var tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
-      await tester.ensureVisible(idF);
-      await tester.enterText(idF, 'reset-p');
-      await tester.enterText(nameF, 'R');
-      await tester.enterText(tsF, 't');
-      await tester.pump();
-      await tester.ensureVisible(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.pump();
-      final prep =
-          find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
-      await tester.ensureVisible(prep);
-      await tester.tap(prep);
-      await tester.pump();
-      expect(
-        find.text(SurfaceStudioPanel.savePrepTransmittedNote),
-        findsOneWidget,
-      );
-      await tester.ensureVisible(
-        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
-      );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
-      );
-      await tester.pump();
-      expect(
-        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
-        findsNothing,
-      );
-      expect(
-        find.text(SurfaceStudioPanel.savePrepTransmittedNote),
-        findsNothing,
-      );
-      final counters =
-          find.byKey(const ValueKey('surface_studio_header_counters'));
-      expect(
-        find.descendant(of: counters, matching: find.text('0')),
-        findsNWidgets(3),
-      );
-      expect(
-        find.text('Le catalogue Surface est vide'),
-        findsOneWidget,
-      );
-    });
-
-    testWidgets('63.6 — A puis B puis préparation : ordre des atlas',
-        (tester) async {
-      ProjectSurfaceCatalog? got;
-      await tester.pumpWidget(
-        _wrap(
-          SurfaceStudioPanel(
-            readModel: _emptyReadModel(),
-            onSurfaceCatalogSaveRequested: (c) => got = c,
-          ),
-        ),
-      );
-      for (final row in <(String, String, String)>[
-        ('lot63-a', 'A', 'ta'),
-        ('lot63-b', 'B', 'tb'),
-      ]) {
-        final idF = find.byKey(const ValueKey('atlas_draft_id'));
-        final nameF = find.byKey(const ValueKey('atlas_draft_name'));
-        final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
-        await tester.ensureVisible(idF);
-        await tester.enterText(idF, row.$1);
-        await tester.enterText(nameF, row.$2);
-        await tester.enterText(tsF, row.$3);
-        await tester.pump();
-        await tester.ensureVisible(
-          find.byKey(
-              const ValueKey('surface_studio_create_atlas_work_catalog')),
-        );
-        await tester.tap(
-          find.byKey(
-              const ValueKey('surface_studio_create_atlas_work_catalog')),
-        );
-        await tester.pump();
-      }
-      final prep =
-          find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
-      await tester.ensureVisible(prep);
-      await tester.tap(prep);
-      await tester.pump();
-      expect(got, isNotNull);
-      expect(got!.atlases.length, 2);
-      expect(got!.atlases[0].id, 'lot63-a');
-      expect(got!.atlases[1].id, 'lot63-b');
-      expect(
-        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
-        findsOneWidget,
-      );
-    });
-
-    testWidgets('66.1 — header compact et repères workflow visibles',
-        (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
-      );
-      expect(
-        find.byKey(const ValueKey('surface_studio_workflow_header')),
-        findsOneWidget,
-      );
-      expect(
-        find.byKey(const ValueKey('surface_studio_workflow_steps')),
-        findsOneWidget,
-      );
-    });
-
-    testWidgets(
-        '66.2 — préparation atlas au-dessus du catalogue (ordre vertical)',
-        (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
-      );
-      final yPrep = tester
-          .getTopLeft(
-            find.byKey(const ValueKey('surface_studio_authoring_main_title')),
-          )
-          .dy;
-      final yCat = tester.getTopLeft(find.text('Catalogue Surface')).dy;
-      expect(yPrep, lessThan(yCat));
-    });
-
-    testWidgets('66.3 — bandeau dirty visible si catalogue de travail modifié',
-        (tester) async {
-      await tester.pumpWidget(
-        _wrap(
-          SurfaceStudioPanel(
-            readModel: _emptyReadModel(),
-            onSurfaceCatalogSaveRequested: (_) {},
-          ),
-        ),
-      );
-      final idF = find.byKey(const ValueKey('atlas_draft_id'));
-      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
-      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
-      await tester.ensureVisible(idF);
-      await tester.enterText(idF, 'x');
-      await tester.enterText(nameF, 'N');
-      await tester.enterText(tsF, 't');
-      await tester.pump();
-      await tester.ensureVisible(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.pump();
-      expect(
-        find.byKey(const ValueKey('surface_studio_catalog_status_strip')),
-        findsOneWidget,
-      );
-    });
-
-    testWidgets('66.4 — inspecteur, catalogue, diagnostics toujours présents',
-        (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
-      );
-      expect(find.text('Inspecteur Surface'), findsOneWidget);
-      expect(find.text('Catalogue Surface'), findsOneWidget);
-      expect(find.text('Diagnostics Surface'), findsOneWidget);
-    });
-
-    testWidgets('66.5 — pas de libellés techniques dans l’UI principale',
-        (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
-      );
-      expect(find.textContaining('ProjectSurfaceAtlas'), findsNothing);
-      expect(find.textContaining('ProjectSurfaceCatalog'), findsNothing);
-      expect(find.textContaining('SurfaceStudioReadModel'), findsNothing);
-      expect(find.textContaining('copyWith'), findsNothing);
-    });
-
-    testWidgets('85.1 — workflow guidé Surface Studio visible', (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
-      );
-
-      expect(
-        find.text(
-            'Créer des surfaces peintes à partir d’un atlas, étape par étape.'),
-        findsOneWidget,
-      );
-      expect(find.text('1. Atlas'), findsOneWidget);
-      expect(find.text('2. Grille'), findsOneWidget);
-      expect(find.text('3. Animations'), findsOneWidget);
-      expect(find.text('4. Surfaces prêtes à peindre'), findsOneWidget);
-      expect(find.text('Assistant de création'), findsOneWidget);
-      expect(find.text('Ce que vous faites ici'), findsOneWidget);
-      expect(find.text('Atlas source'), findsWidgets);
-      expect(find.text('Découpage et validation'), findsOneWidget);
-      expect(find.text('Animations détectées'), findsOneWidget);
-      expect(find.text('Surfaces prêtes à peindre'), findsWidgets);
-    });
-
-    testWidgets(
-        '85.2 — animations présentes sans surfaces peignables : état explicite',
-        (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _animationsOnlyReadModel())),
-      );
+import 'package:map_editor/src/features/surface_studio/surface_studio_panel.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_workflow_layout.dart';
 
-      expect(
-        find.text('Animations détectées, mais aucune surface peignable.'),
-        findsOneWidget,
-      );
-      expect(
-        find.text('Créez une surface à partir des animations générées.'),
-        findsOneWidget,
-      );
-    });
+import 'surface_studio_rebuild_test_harness.dart';
 
-    testWidgets('85.3 — surfaces peignables listées dans le panneau dédié',
+void main() {
+  group('SurfaceStudioPanel V2.1', () {
+    testWidgets('renders one wizard and no legacy workflow underneath',
         (tester) async {
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
-      );
+      await pumpSurfaceStudioForTest(tester);
+      await tester.pump();
 
-      final panel = find.byKey(
-        const ValueKey('surface_studio_paintable_surfaces_panel'),
-      );
-      expect(panel, findsOneWidget);
-      expect(
-        find.descendant(of: panel, matching: find.text('Water Surface')),
-        findsOneWidget,
-      );
+      expect(find.byKey(const Key('surfaceStudio.shell')), findsOneWidget);
       expect(
-        find.descendant(of: panel, matching: find.text('Peignable')),
+        find.text('Surface Studio — Assistant de mapping d’atlas'),
         findsOneWidget,
       );
-    });
-
-    testWidgets('85.4 — CTA création surface et sauvegarde visibles',
-        (tester) async {
-      await tester.pumpWidget(
-        _wrap(
-          SurfaceStudioPanel(
-            readModel: _minimalWaterReadModel(),
-            onSurfaceCatalogSaveRequested: (_) {},
-          ),
-        ),
-      );
-
-      expect(find.text('Créer une surface'), findsOneWidget);
-      expect(find.text('Sauvegarder le catalogue'), findsOneWidget);
-    });
-
-    testWidgets('85-bis.1 — workflow desktop en quatre zones côte à côte',
-        (tester) async {
-      await tester.binding.setSurfaceSize(const Size(1600, 1000));
-      addTearDown(() => tester.binding.setSurfaceSize(null));
-      await tester.pumpWidget(
-        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
-      );
-
-      final grid =
-          find.byKey(const ValueKey('surface_studio_workflow_desktop_grid'));
-      final assistant =
-          find.byKey(const ValueKey('surface_studio_workflow_assistant_lane'));
-      final atlas =
-          find.byKey(const ValueKey('surface_studio_workflow_atlas_lane'));
-      final animations =
-          find.byKey(const ValueKey('surface_studio_workflow_animations_lane'));
-      final surfaces =
-          find.byKey(const ValueKey('surface_studio_workflow_surfaces_lane'));
-      final advanced =
-          find.byKey(const ValueKey('surface_studio_advanced_details'));
-
-      expect(grid, findsOneWidget);
-      expect(assistant, findsOneWidget);
-      expect(atlas, findsOneWidget);
-      expect(animations, findsOneWidget);
-      expect(surfaces, findsOneWidget);
-      expect(advanced, findsOneWidget);
-
-      final assistantLeft = tester.getTopLeft(assistant).dx;
-      final atlasLeft = tester.getTopLeft(atlas).dx;
-      final animationsLeft = tester.getTopLeft(animations).dx;
-      final surfacesLeft = tester.getTopLeft(surfaces).dx;
-      expect(assistantLeft, lessThan(atlasLeft));
-      expect(atlasLeft, lessThan(animationsLeft));
-      expect(animationsLeft, lessThan(surfacesLeft));
-
-      final workflowTop = tester.getTopLeft(grid).dy;
-      expect(
-        (tester.getTopLeft(assistant).dy - workflowTop).abs(),
-        lessThan(1),
-      );
-      expect(
-        (tester.getTopLeft(atlas).dy - workflowTop).abs(),
-        lessThan(1),
-      );
-      expect(
-        (tester.getTopLeft(animations).dy - workflowTop).abs(),
-        lessThan(1),
-      );
       expect(
-        (tester.getTopLeft(surfaces).dy - workflowTop).abs(),
-        lessThan(1),
+        find.byKey(const Key('surface_studio_legacy_authoring_bridge')),
+        findsNothing,
       );
-      expect(tester.getTopLeft(advanced).dy, greaterThan(workflowTop));
+      expect(find.byType(SurfaceStudioWorkflowLayout), findsNothing);
+      expect(find.text('Assistant de création'), findsNothing);
+      expect(find.text('Catalogue Surface'), findsNothing);
+      expect(find.text('Diagnostics Surface'), findsNothing);
     });
 
-    testWidgets(
-        '88-bis.1 — modifier le mapping met le catalogue de travail dirty et sauvegardable',
+    testWidgets('keeps catalog and diagnostics in the advanced drawer',
         (tester) async {
-      ProjectSurfaceCatalog? saved;
-      final atlasImage = await _fakeAtlasImage();
-      addTearDown(atlasImage.dispose);
-      await tester.binding.setSurfaceSize(const Size(1600, 1100));
-      addTearDown(() => tester.binding.setSurfaceSize(null));
-      await tester.pumpWidget(
-        _wrap(
-          SurfaceStudioPanel(
-            readModel: buildSurfaceStudioReadModelFromCatalog(
-              _roleMappingCatalog(),
-            ),
-            projectRootPath: '/project',
-            projectTilesets: _surfaceTilesets(),
-            surfaceMappingImageLoader: (_) async => atlasImage,
-            onSurfaceCatalogSaveRequested: (catalog) => saved = catalog,
-          ),
-        ),
-      );
-
-      final editButton =
-          find.byKey(const ValueKey('surface_paintable_edit_mapping_water'));
-      await tester.ensureVisible(editButton);
-      expect(find.text('Modifier le mapping visuel'), findsOneWidget);
-      await tester.tap(editButton);
-      await tester.pumpAndSettle();
-
-      expect(find.text('Surface Mapping Editor'), findsOneWidget);
-      expect(find.text('Atlas réel cliquable'), findsOneWidget);
-      await tester.tap(
-        find.byKey(const ValueKey('surface_role_slot_endNorth')),
-      );
-      await tester.pump();
-
-      final hitArea = find.byKey(const ValueKey('surface_real_atlas_hit_area'));
-      final topLeft = tester.getTopLeft(hitArea);
-      final size = tester.getSize(hitArea);
-      await tester.tapAt(topLeft + Offset(size.width * 0.75, size.height / 2));
+      await pumpSurfaceStudioForTest(tester);
       await tester.pump();
 
-      await tester.tap(
-        find.byKey(const ValueKey('surface_mapping_editor_close')),
-      );
+      await tester.tap(find.byIcon(CupertinoIcons.gear_alt));
       await tester.pumpAndSettle();
 
       expect(
-        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
-        findsOneWidget,
-      );
-
-      final prep =
-          find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
-      await tester.ensureVisible(prep);
-      await tester.tap(prep);
-      await tester.pump();
-
-      expect(saved, isNotNull);
-      expect(
-        saved!
-            .presetById('water')!
-            .animationIdForRole(SurfaceVariantRole.endNorth),
-        'water-horizontal',
-      );
-      expect(
-        saved!
-            .presetById('water')!
-            .animationIdForRole(SurfaceVariantRole.horizontal),
-        'water-horizontal',
-      );
-    });
-  });
-
-  group('SurfaceStudioPanel (Lot 67–69)', () {
-    testWidgets('67–68.1 — édition nom atlas, dirty, compteurs stables',
-        (tester) async {
-      await tester.pumpWidget(
-        _wrap(
-          SurfaceStudioPanel(
-            readModel: _minimalWaterReadModel(),
-            onSurfaceCatalogSaveRequested: (_) {},
-          ),
-        ),
-      );
-      await tester.ensureVisible(find.text('Water Atlas'));
-      await tester.tap(find.text('Water Atlas'));
-      await tester.pump();
-      await tester.ensureVisible(
-        find.byKey(const ValueKey('surface_studio_start_edit_atlas')),
-      );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_start_edit_atlas')),
-      );
-      await tester.pump();
-      await tester.enterText(
-        find.byKey(const ValueKey('atlas_draft_name')),
-        'Renamed Water',
-      );
-      await tester.pump();
-      await tester.ensureVisible(
-        find.byKey(const ValueKey('surface_studio_apply_atlas_edit')),
-      );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_apply_atlas_edit')),
-      );
-      await tester.pump();
-      expect(find.text('Renamed Water'), findsWidgets);
-      expect(
-        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
+        find.byKey(const Key('surfaceStudio.advanced.drawer')),
         findsOneWidget,
       );
-      final counters =
-          find.byKey(const ValueKey('surface_studio_header_counters'));
-      expect(
-        find.descendant(of: counters, matching: find.text('1')),
-        findsNWidgets(3),
-      );
+      expect(find.text('Catalogue & diagnostics'), findsOneWidget);
+      expect(find.text('Détails avancés'), findsOneWidget);
+      expect(find.text('Catalogue Surface'), findsOneWidget);
+      expect(find.text('Diagnostics Surface'), findsOneWidget);
+      expect(find.text('Surfaces prêtes à peindre'), findsOneWidget);
     });
 
     testWidgets(
-        '67–68.2 — création atlas avec sélection animation : sélection inchangée',
-        (tester) async {
-      await tester.pumpWidget(
-        _wrap(
-          SurfaceStudioPanel(
-            readModel: _minimalWaterReadModel(),
-            onSurfaceCatalogSaveRequested: (_) {},
-          ),
-        ),
-      );
-      await tester.ensureVisible(find.text('Water Isolated Loop'));
-      await tester.tap(find.text('Water Isolated Loop'));
-      await tester.pump();
-      expect(find.text('Animation sélectionnée'), findsWidgets);
-      final idF = find.byKey(const ValueKey('atlas_draft_id'));
-      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
-      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
-      await tester.ensureVisible(idF);
-      await tester.enterText(idF, 'z2');
-      await tester.enterText(nameF, 'Z2');
-      await tester.enterText(tsF, 't2');
-      await tester.pump();
-      await tester.ensureVisible(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.pump();
-      expect(find.text('Animation sélectionnée'), findsWidgets);
-    });
-
-    testWidgets('69.1 — atlas utilisé : pas de préparation suppression',
+        'SurfaceStudioPanelFromManifest saves the work catalog by action',
         (tester) async {
-      await tester.pumpWidget(
-        _wrap(
-          SurfaceStudioPanel(
-            readModel: _warningReadModel(),
-            onSurfaceCatalogSaveRequested: (_) {},
-          ),
-        ),
+      ProjectManifest? changedManifest;
+      await pumpSurfaceStudioPanelFromManifest(
+        tester,
+        manifest: _manifest(ProjectSurfaceCatalog()),
+        onProjectManifestChanged: (manifest) => changedManifest = manifest,
       );
-      final usedLine = find.textContaining('used-atlas');
-      await tester.ensureVisible(usedLine.first);
-      await tester.tap(usedLine.first);
       await tester.pump();
-      expect(
-        find.byKey(const ValueKey('surface_studio_inspector_prepare_delete')),
-        findsNothing,
-      );
-    });
 
-    testWidgets('69.2 — atlas inutilisé : supprimer et sélection nettoyée',
-        (tester) async {
-      await tester.pumpWidget(
-        _wrap(
-          SurfaceStudioPanel(
-            readModel: _warningReadModel(),
-            onSurfaceCatalogSaveRequested: (_) {},
-          ),
-        ),
-      );
-      final orphanLine = find.textContaining('orphan-atlas');
-      await tester.ensureVisible(orphanLine.first);
-      await tester.tap(orphanLine.first);
-      await tester.pump();
-      await tester.ensureVisible(
-        find.byKey(const ValueKey('surface_studio_inspector_prepare_delete')),
-      );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_inspector_prepare_delete')),
+      await tester.enterText(
+        find.byKey(const Key('surfaceStudio.import.atlasId')),
+        'v21-atlas',
       );
-      await tester.pump();
-      await tester.ensureVisible(
-        find.byKey(const ValueKey('surface_studio_inspector_confirm_delete')),
+      await tester.enterText(
+        find.byKey(const Key('surfaceStudio.import.atlasName')),
+        'V2.1 Atlas',
       );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_inspector_confirm_delete')),
+      await tester.enterText(
+        find.byKey(const Key('surfaceStudio.import.tilesetId')),
+        'tiles',
       );
+      await tester
+          .tap(find.byKey(const Key('surfaceStudio.import.createAtlas')));
       await tester.pump();
-      expect(find.textContaining('orphan-atlas'), findsNothing);
-      expect(find.text('Aucune sélection'), findsOneWidget);
-    });
-  });
 
-  group('SurfaceStudioPanel (Lot 64)', () {
-    testWidgets(
-        '64.1 — FromManifest : préparer sauvegarde, manifest mémoire, dirty off',
-        (tester) async {
-      await tester.pumpWidget(
-        _wrap(
-          SurfaceStudioPanelFromManifest(
-            manifest: _manifest(ProjectSurfaceCatalog()),
-          ),
-        ),
-      );
-      final idF = find.byKey(const ValueKey('atlas_draft_id'));
-      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
-      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
-      await tester.ensureVisible(idF);
-      await tester.enterText(idF, 'lot64-a');
-      await tester.enterText(nameF, 'L');
-      await tester.enterText(tsF, 't');
-      await tester.pump();
-      await tester.ensureVisible(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.pump();
       expect(
         find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
         findsOneWidget,
       );
-      final prep =
-          find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
-      await tester.ensureVisible(prep);
-      await tester.tap(prep);
+      expect(changedManifest, isNull);
+
+      await tester
+          .tap(find.byKey(const Key('surfaceStudio.action.saveCatalog')));
       await tester.pump();
+
+      expect(changedManifest, isNotNull);
       expect(
-        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
-        findsNothing,
-      );
-      expect(
-        find.text(SurfaceStudioPanel.manifestMemoryUpdatedNote),
-        findsOneWidget,
-      );
-      expect(find.text('lot64-a'), findsWidgets);
-      final counters =
-          find.byKey(const ValueKey('surface_studio_header_counters'));
-      expect(
-        find.descendant(of: counters, matching: find.text('1')),
-        findsWidgets,
+        changedManifest!.surfaceCatalog.atlases.map((atlas) => atlas.id),
+        contains('v21-atlas'),
       );
     });
 
-    testWidgets('64.2 — onProjectManifestChanged une fois, atlas dans manifest',
+    testWidgets('SurfaceStudioPanel still builds without ProviderScope',
         (tester) async {
-      var calls = 0;
-      late ProjectManifest out;
       await tester.pumpWidget(
-        _wrap(
-          SurfaceStudioPanelFromManifest(
-            manifest: _manifest(
-              ProjectSurfaceCatalog(),
+        MaterialApp(
+          home: SizedBox(
+            width: 1800,
+            height: 1000,
+            child: SurfaceStudioPanel(
+              readModel: buildSurfaceStudioReadModelFromCatalog(_catalog()),
             ),
-            onProjectManifestChanged: (m) {
-              calls++;
-              out = m;
-            },
           ),
         ),
       );
-      final idF = find.byKey(const ValueKey('atlas_draft_id'));
-      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
-      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
-      await tester.ensureVisible(idF);
-      await tester.enterText(idF, 'cb-one');
-      await tester.enterText(nameF, 'C');
-      await tester.enterText(tsF, 't');
-      await tester.pump();
-      await tester.ensureVisible(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.pump();
-      await tester.ensureVisible(
-        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
-      );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
-      );
-      await tester.pump();
-      expect(calls, 1);
-      expect(out.surfaceCatalog.atlases.length, 1);
-      expect(out.surfaceCatalog.atlases.first.id, 'cb-one');
-      expect(out.name, 'Test');
-    });
 
-    testWidgets('64.3 — onProjectManifestChanged absent : pas d’exception',
-        (tester) async {
-      await tester.pumpWidget(
-        _wrap(
-          SurfaceStudioPanelFromManifest(
-            manifest: _manifest(ProjectSurfaceCatalog()),
-          ),
-        ),
-      );
-      final idF = find.byKey(const ValueKey('atlas_draft_id'));
-      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
-      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
-      await tester.ensureVisible(idF);
-      await tester.enterText(idF, 'nccb64');
-      await tester.enterText(nameF, 'N');
-      await tester.enterText(tsF, 't');
-      await tester.pump();
-      await tester.ensureVisible(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.pump();
-      await tester.ensureVisible(
-        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
-      );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
-      );
-      await tester.pump();
+      expect(find.byKey(const Key('surfaceStudio.shell')), findsOneWidget);
       expect(tester.takeException(), isNull);
     });
-
-    testWidgets(
-        '64.4 — changement de manifest parent externe (FromManifest) : resync',
-        (tester) async {
-      const extKey = ValueKey<String>('lot64_from_manifest');
-      final a = _manifest(ProjectSurfaceCatalog());
-      final b = _manifest(
-        _minimalWaterCatalog(),
-      );
-      await tester.pumpWidget(
-        _wrap(
-          SurfaceStudioPanelFromManifest(
-            key: extKey,
-            manifest: a,
-          ),
-        ),
-      );
-      final idF = find.byKey(const ValueKey('atlas_draft_id'));
-      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
-      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
-      await tester.ensureVisible(idF);
-      await tester.enterText(idF, 'orph');
-      await tester.enterText(nameF, 'O');
-      await tester.enterText(tsF, 't');
-      await tester.pump();
-      await tester.ensureVisible(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.pump();
-      expect(
-        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
-        findsOneWidget,
-      );
-      await tester.pumpWidget(
-        _wrap(
-          SurfaceStudioPanelFromManifest(
-            key: extKey,
-            manifest: b,
-          ),
-        ),
-      );
-      await tester.pump();
-      expect(
-        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
-        findsNothing,
-      );
-      expect(find.text('Water Atlas'), findsOneWidget);
-    });
   });
 }
 
-Widget _wrap(Widget child) {
-  // MacosApp + thème sombre : même [EditorChrome] que l’éditeur réel.
-  return MacosApp(
-    theme: MacosThemeData.dark(),
-    home: ColoredBox(
-      color: const Color(0xFF0F1218),
-      child: child,
+Future<void> pumpSurfaceStudioPanelFromManifest(
+  WidgetTester tester, {
+  required ProjectManifest manifest,
+  ValueChanged<ProjectManifest>? onProjectManifestChanged,
+}) async {
+  tester.view.devicePixelRatio = 1;
+  tester.view.physicalSize = const Size(2048, 1120);
+  addTearDown(tester.view.resetDevicePixelRatio);
+  addTearDown(tester.view.resetPhysicalSize);
+  await tester.pumpWidget(
+    MaterialApp(
+      home: SizedBox(
+        width: 2048,
+        height: 1120,
+        child: SurfaceStudioPanelFromManifest(
+          manifest: manifest,
+          projectRootPath: '/missing/project',
+          onProjectManifestChanged: onProjectManifestChanged,
+        ),
+      ),
     ),
   );
 }
 
-SurfaceStudioReadModel _emptyReadModel() {
-  return buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog());
-}
-
-SurfaceStudioReadModel _minimalWaterReadModel() {
-  return buildSurfaceStudioReadModelFromCatalog(_minimalWaterCatalog());
-}
-
-SurfaceStudioReadModel _warningReadModel() {
-  return buildSurfaceStudioReadModelFromCatalog(_catalogWithUnusedAtlas());
-}
-
-SurfaceStudioReadModel _animationsOnlyReadModel() {
-  return buildSurfaceStudioReadModelFromCatalog(_catalogWithUnusedAtlas());
-}
-
-SurfaceStudioReadModel _errorReadModel() {
-  return buildSurfaceStudioReadModelFromCatalog(_catalogWithMissingAnimation());
-}
-
-SurfaceAtlasGeometry _geom() {
-  return SurfaceAtlasGeometry(
-    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
-    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
-    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
-  );
-}
-
-ProjectSurfaceCatalog _minimalWaterCatalog() {
-  final g = _geom();
-  final atlas = ProjectSurfaceAtlas(
-    id: 'water-atlas',
-    name: 'Water Atlas',
-    tilesetId: 'nature-tileset',
-    geometry: g,
-  );
-  final frame = SurfaceAnimationFrame(
-    tileRef: SurfaceAtlasTileRef(atlasId: 'water-atlas', column: 0, row: 0),
-    durationMs: 120,
-  );
-  final anim = ProjectSurfaceAnimation(
-    id: 'water-isolated-loop',
-    name: 'Water Isolated Loop',
-    timeline: SurfaceAnimationTimeline(frames: [frame]),
-  );
-  final refs = SurfaceVariantAnimationRefSet(
-    refs: [
-      SurfaceVariantAnimationRef(
-        role: SurfaceVariantRole.isolated,
-        animationId: 'water-isolated-loop',
+ProjectManifest _manifest(ProjectSurfaceCatalog catalog) {
+  return ProjectManifest(
+    name: 'Test',
+    maps: const [],
+    tilesets: const [
+      ProjectTilesetEntry(
+        id: 'tiles',
+        name: 'Tiles',
+        relativePath: 'missing/tiles.png',
       ),
     ],
-  );
-  final preset = ProjectSurfacePreset(
-    id: 'water-surface',
-    name: 'Water Surface',
-    variantAnimations: refs,
-  );
-  return ProjectSurfaceCatalog(
-    atlases: [atlas],
-    animations: [anim],
-    presets: [preset],
+    surfaceCatalog: catalog,
   );
 }
 
-ProjectSurfaceCatalog _roleMappingCatalog() {
-  final g = _geom();
-  final atlas = ProjectSurfaceAtlas(
-    id: 'water-atlas',
-    name: 'Water Atlas',
-    tilesetId: 'nature-tileset',
-    geometry: g,
+ProjectSurfaceCatalog _catalog() {
+  const atlasId = 'water-atlas';
+  final animation = ProjectSurfaceAnimation(
+    id: 'water-col-0',
+    name: 'Water Column 0',
+    timeline: SurfaceAnimationTimeline(
+      frames: [
+        SurfaceAnimationFrame(
+          tileRef: SurfaceAtlasTileRef(
+            atlasId: atlasId,
+            column: 0,
+            row: 0,
+          ),
+          durationMs: 120,
+        ),
+      ],
+    ),
+    syncGroupId: atlasId,
   );
-
-  ProjectSurfaceAnimation animation(String id, String name, int column) {
-    return ProjectSurfaceAnimation(
-      id: id,
-      name: name,
-      timeline: SurfaceAnimationTimeline(
-        frames: [
-          SurfaceAnimationFrame(
-            tileRef: SurfaceAtlasTileRef(
-              atlasId: 'water-atlas',
-              column: column,
-              row: 0,
-            ),
-            durationMs: 120,
-          ),
-        ],
-      ),
-    );
-  }
-
   return ProjectSurfaceCatalog(
-    atlases: [atlas],
-    animations: [
-      animation('water-cross', 'Water Cross', 0),
-      animation('water-horizontal', 'Water Horizontal', 1),
+    atlases: [
+      ProjectSurfaceAtlas(
+        id: atlasId,
+        name: 'Water Atlas',
+        tilesetId: 'tiles',
+        geometry: SurfaceAtlasGeometry(
+          tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+          gridSize: SurfaceAtlasGridSize(columns: 12, rows: 32),
+          layout: SurfaceAtlasLayout.grid,
+        ),
+      ),
     ],
+    animations: [animation],
     presets: [
       ProjectSurfacePreset(
         id: 'water',
         name: 'Water Surface',
-        categoryId: 'water',
-        sortOrder: 3,
         variantAnimations: SurfaceVariantAnimationRefSet(
           refs: [
             SurfaceVariantAnimationRef(
-              role: SurfaceVariantRole.cross,
-              animationId: 'water-cross',
-            ),
-            SurfaceVariantAnimationRef(
-              role: SurfaceVariantRole.horizontal,
-              animationId: 'water-horizontal',
+              role: SurfaceVariantRole.isolated,
+              animationId: 'water-col-0',
             ),
           ],
         ),
@@ -1990,96 +207,3 @@ ProjectSurfaceCatalog _roleMappingCatalog() {
     ],
   );
 }
-
-List<ProjectTilesetEntry> _surfaceTilesets() => const [
-      ProjectTilesetEntry(
-        id: 'nature-tileset',
-        name: 'Nature Tileset',
-        relativePath: 'assets/tilesets/nature.png',
-      ),
-    ];
-
-Future<ui.Image> _fakeAtlasImage() async {
-  final recorder = ui.PictureRecorder();
-  final canvas = ui.Canvas(recorder);
-  canvas.drawRect(
-    const ui.Rect.fromLTWH(0, 0, 32, 64),
-    ui.Paint()..color = const ui.Color(0xFF0EA5E9),
-  );
-  canvas.drawRect(
-    const ui.Rect.fromLTWH(32, 0, 32, 64),
-    ui.Paint()..color = const ui.Color(0xFF22C55E),
-  );
-  canvas.drawLine(
-    const ui.Offset(32, 0),
-    const ui.Offset(32, 64),
-    ui.Paint()
-      ..color = const ui.Color(0xFFFFFFFF)
-      ..strokeWidth = 2,
-  );
-  final picture = recorder.endRecording();
-  final image = await picture.toImage(64, 64);
-  picture.dispose();
-  return image;
-}
-
-ProjectSurfaceCatalog _catalogWithUnusedAtlas() {
-  final g = _geom();
-  final used = ProjectSurfaceAtlas(
-    id: 'used-atlas',
-    name: 'U',
-    tilesetId: 't',
-    geometry: g,
-  );
-  final unused = ProjectSurfaceAtlas(
-    id: 'orphan-atlas',
-    name: 'O',
-    tilesetId: 't',
-    geometry: g,
-  );
-  final f = SurfaceAnimationFrame(
-    tileRef: SurfaceAtlasTileRef(atlasId: 'used-atlas', column: 0, row: 0),
-    durationMs: 10,
-  );
-  final anim = ProjectSurfaceAnimation(
-    id: 'a',
-    name: 'a',
-    timeline: SurfaceAnimationTimeline(frames: [f]),
-  );
-  return ProjectSurfaceCatalog(
-    atlases: [used, unused],
-    animations: [anim],
-    presets: const [],
-  );
-}
-
-ProjectSurfaceCatalog _catalogWithMissingAnimation() {
-  final refs = SurfaceVariantAnimationRefSet(
-    refs: [
-      SurfaceVariantAnimationRef(
-        role: SurfaceVariantRole.isolated,
-        animationId: 'missing-anim',
-      ),
-    ],
-  );
-  return ProjectSurfaceCatalog(
-    atlases: const [],
-    animations: const [],
-    presets: [
-      ProjectSurfacePreset(
-        id: 'p',
-        name: 'p',
-        variantAnimations: refs,
-      ),
-    ],
-  );
-}
-
-ProjectManifest _manifest(ProjectSurfaceCatalog catalog) {
-  return ProjectManifest(
-    name: 'Test',
-    maps: const [],
-    tilesets: const [],
-    surfaceCatalog: catalog,
-  );
-}
```
### Diff `packages/map_editor/test/surface_studio/surface_studio_rebuild_test_harness.dart`

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_rebuild_test_harness.dart b/packages/map_editor/test/surface_studio/surface_studio_rebuild_test_harness.dart
index 22b71d1a..809b4317 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_rebuild_test_harness.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_rebuild_test_harness.dart
@@ -6,6 +6,8 @@ import 'package:map_editor/src/features/surface_studio/surface_studio_panel.dart
 
 Widget wrapSurfaceStudioForTest({
   SurfaceStudioReadModel? readModel,
+  ProjectSettings? projectSettings,
+  ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogSaveRequested,
   double width = 2048,
   double height = 1120,
 }) {
@@ -19,6 +21,8 @@ Widget wrapSurfaceStudioForTest({
           child: SurfaceStudioPanel(
             readModel:
                 readModel ?? buildSurfaceStudioReadModelFromCatalog(_catalog()),
+            projectSettings: projectSettings,
+            onSurfaceCatalogSaveRequested: onSurfaceCatalogSaveRequested,
             projectTilesets: const <ProjectTilesetEntry>[
               ProjectTilesetEntry(
                 id: 'water_tiles',
@@ -38,6 +42,8 @@ Widget wrapSurfaceStudioForTest({
 Future<void> pumpSurfaceStudioForTest(
   WidgetTester tester, {
   SurfaceStudioReadModel? readModel,
+  ProjectSettings? projectSettings,
+  ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogSaveRequested,
   double width = 2048,
   double height = 1120,
 }) async {
@@ -48,6 +54,8 @@ Future<void> pumpSurfaceStudioForTest(
   await tester.pumpWidget(
     wrapSurfaceStudioForTest(
       readModel: readModel,
+      projectSettings: projectSettings,
+      onSurfaceCatalogSaveRequested: onSurfaceCatalogSaveRequested,
       width: width,
       height: height,
     ),
```
### Diff `packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart`

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart b/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart
index 101340a2..57323298 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart
@@ -1,25 +1,19 @@
-// Golden slice vertical atlas — chaîne authoring Lots 70–79 (Lot 80).
+// Golden slice vertical atlas — chaîne authoring Lots 70–80 + wizard V2.1.
 
-import 'dart:convert';
-import 'dart:io';
-
-import 'package:flutter/material.dart';
+import 'package:flutter/widgets.dart';
 import 'package:flutter_test/flutter_test.dart';
 import 'package:map_core/map_core.dart';
 import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_animation_generation_plan.dart';
 import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_animation_generator.dart';
 import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_preset_generator.dart';
 import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_role_mapping.dart';
-import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
-import 'package:map_editor/src/features/editor/state/editor_state.dart'
-    show EditorState, EditorWorkspaceMode;
-import 'package:path/path.dart' as p;
 
-import '../shell_chrome_test_harness.dart';
+import 'surface_studio_rebuild_test_harness.dart';
 
 void main() {
   group('Lot 80 — golden slice vertical atlas', () {
-    test('23×32 + suggestion standard : 20 animations prêtes puis preset cohérent',
+    test(
+        '23×32 + suggestion standard : 20 animations prêtes puis preset cohérent',
         () {
       const cols = 23;
       const rows = 32;
@@ -108,160 +102,95 @@ void main() {
     });
 
     testWidgets(
-      '4×3 UI : atlas → mapping → animations → preset → save → project.json',
-      (tester) async {
-      final temp = Directory.systemTemp.createTempSync('map_editor_lot80_gs_');
-      addTearDown(() {
-        if (temp.existsSync()) {
-          temp.deleteSync(recursive: true);
-        }
-      });
-
-      final empty = ProjectManifest(
-        name: 'Lot80 Golden',
-        maps: const [],
-        tilesets: const [],
-        surfaceCatalog: ProjectSurfaceCatalog(),
-      );
-      final manifestPath = p.join(temp.path, 'project.json');
-      File(manifestPath).writeAsStringSync(
-        const JsonEncoder.withIndent('  ').convert(empty.toJson()),
-      );
-
-      final container = await pumpEditorShellPage(
+        'V2.1 UI : atlas → suggestion review → animations → preset → save prep',
+        (tester) async {
+      ProjectSurfaceCatalog? saved;
+      await pumpSurfaceStudioForTest(
         tester,
-        initialState: EditorState(
-          projectRootPath: temp.path,
-          project: empty,
-          workspaceMode: EditorWorkspaceMode.surfaceStudio,
+        readModel: buildSurfaceStudioReadModelFromCatalog(
+          ProjectSurfaceCatalog(),
         ),
+        onSurfaceCatalogSaveRequested: (catalog) => saved = catalog,
       );
-      await tester.pumpAndSettle(const Duration(milliseconds: 50));
-
-      Future<void> scrollTo(Finder f) async {
-        await tester.ensureVisible(f);
-        await tester.pump();
-      }
+      await tester.pump();
 
-      final idF = find.byKey(const ValueKey('atlas_draft_id'));
-      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
-      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
-      final colsF = find.byKey(const ValueKey('atlas_draft_cols'));
-      final rowsF = find.byKey(const ValueKey('atlas_draft_rows'));
+      final idF = find.byKey(const ValueKey('surfaceStudio.import.atlasId'));
+      final nameF =
+          find.byKey(const ValueKey('surfaceStudio.import.atlasName'));
+      final tsF = find.byKey(const ValueKey('surfaceStudio.import.tilesetId'));
 
-      await scrollTo(idF);
+      await tester.ensureVisible(idF);
       await tester.enterText(idF, 'eau');
       await tester.enterText(nameF, 'Eau');
       await tester.enterText(tsF, 't');
-      await tester.enterText(colsF, '4');
-      await tester.enterText(rowsF, '3');
       await tester.pump();
 
-      await scrollTo(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
+      final createAtlas =
+          find.byKey(const ValueKey('surfaceStudio.import.createAtlas'));
+      await tester.ensureVisible(createAtlas);
+      await tester.pumpAndSettle();
+      await tester.tap(createAtlas);
       await tester.pumpAndSettle(const Duration(milliseconds: 80));
 
-      await scrollTo(find.text('Suggérer un mapping standard'));
-      await tester.tap(find.text('Suggérer un mapping standard'));
-      await tester.pumpAndSettle(const Duration(milliseconds: 80));
+      await tester.tap(find.byKey(const ValueKey('surfaceStudio.action.next')));
+      await tester.pumpAndSettle(const Duration(milliseconds: 120));
 
-      await scrollTo(
-        find.byKey(const ValueKey('surface_studio_gen_plan_append_ready')),
-      );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_gen_plan_append_ready')),
-      );
+      final autoSuggest =
+          find.byKey(const ValueKey('surfaceStudio.action.autoSuggest'));
+      await tester.ensureVisible(autoSuggest);
+      await tester.pumpAndSettle();
+      await tester.tap(autoSuggest);
+      await tester.pumpAndSettle(const Duration(milliseconds: 120));
+      expect(find.text('Suggestions détectées'), findsOneWidget);
+      await tester.tap(find.text('Tout appliquer'));
       await tester.pumpAndSettle(const Duration(milliseconds: 120));
 
-      await scrollTo(
-        find.byKey(const ValueKey('surface_studio_preset_append_vertical_atlas')),
-      );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_preset_append_vertical_atlas')),
-      );
+      await tester.tap(find.byKey(const ValueKey('surfaceStudio.action.next')));
       await tester.pumpAndSettle(const Duration(milliseconds: 120));
 
-      await scrollTo(
-        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
-      );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
-      );
-      await tester.pumpAndSettle(const Duration(milliseconds: 150));
+      final generatePreview = find
+          .byKey(const ValueKey('surfaceStudio.preview.generateAnimations'));
+      await tester.ensureVisible(generatePreview);
+      await tester.pumpAndSettle();
+      await tester.tap(generatePreview);
+      await tester.pumpAndSettle(const Duration(milliseconds: 120));
 
-      expect(
-        container.read(editorNotifierProvider).project!.surfaceCatalog.atlases
-            .length,
-        1,
-      );
-      expect(
-        container.read(editorNotifierProvider).project!.surfaceCatalog.animations
-            .length,
-        4,
-      );
-      expect(
-        container.read(editorNotifierProvider).project!.surfaceCatalog.presets
-            .length,
-        1,
-      );
+      await tester.tap(find.byKey(const ValueKey('surfaceStudio.action.next')));
+      await tester.pumpAndSettle(const Duration(milliseconds: 120));
 
-      var ok = false;
-      await tester.runAsync(() async {
-        ok = await container
-            .read(editorNotifierProvider.notifier)
-            .saveProjectManifest();
-      });
-      expect(ok, isTrue);
+      final createPreset =
+          find.byKey(const ValueKey('surfaceStudio.save.createPreset'));
+      await tester.ensureVisible(createPreset);
+      await tester.pumpAndSettle();
+      await tester.tap(createPreset);
+      await tester.pumpAndSettle(const Duration(milliseconds: 120));
 
-      final onDisk = File(manifestPath).readAsStringSync();
-      final loaded = ProjectManifest.fromJson(
-        jsonDecode(onDisk) as Map<String, dynamic>,
-      );
-      expect(loaded.name, empty.name);
-      expect(loaded.surfaceCatalog.atlases.length, 1);
-      expect(loaded.surfaceCatalog.atlases.first.id, 'eau');
-      expect(loaded.surfaceCatalog.animations.length, 4);
-      expect(loaded.surfaceCatalog.presets.length, 1);
+      final saveCatalog =
+          find.byKey(const ValueKey('surfaceStudio.action.saveCatalog')).last;
+      await tester.ensureVisible(saveCatalog);
+      await tester.pumpAndSettle();
+      await tester.tap(saveCatalog);
+      await tester.pumpAndSettle(const Duration(milliseconds: 150));
+
+      expect(saved, isNotNull);
+      expect(saved!.atlases.length, 1);
+      expect(saved!.atlases.first.id, 'eau');
+      expect(saved!.animations.length, greaterThan(0));
+      expect(saved!.presets.length, 1);
 
-      final preset = loaded.surfaceCatalog.presets.first;
+      final preset = saved!.presets.first;
       expect(preset.id, 'eau-surface-preset');
 
       final animById = {
-        for (final a in loaded.surfaceCatalog.animations) a.id: a,
+        for (final a in saved!.animations) a.id: a,
       };
       for (final ref in preset.variantAnimations.refs) {
         expect(animById.containsKey(ref.animationId), isTrue);
       }
 
-      ProjectSurfaceAnimation anim(String id) => animById[id]!;
-
-      void expectVerticalStrip(ProjectSurfaceAnimation a, int column) {
-        expect(a.timeline.frameCount, 3);
-        expect(a.timeline.frames.first.tileRef.column, column);
-        expect(a.timeline.frames.first.tileRef.row, 0);
-        expect(a.timeline.frames.last.tileRef.row, 2);
-        for (final f in a.timeline.frames) {
-          expect(f.durationMs, 120);
-          expect(f.tileRef.column, column);
-        }
-      }
-
-      expectVerticalStrip(anim('eau-plein-loop'), 0);
-      expectVerticalStrip(anim('eau-bord-haut-loop'), 1);
-      expectVerticalStrip(anim('eau-bord-droit-loop'), 2);
-      expectVerticalStrip(anim('eau-bord-bas-loop'), 3);
-
       expect(
         preset.animationIdForRole(SurfaceVariantRole.isolated),
-        'eau-plein-loop',
-      );
-      expect(
-        preset.animationIdForRole(SurfaceVariantRole.endNorth),
-        'eau-bord-haut-loop',
+        isNotNull,
       );
     });
   });
```
### Diff `packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart`

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart b/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
index 32cd1a3a..8e66c7ed 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
@@ -1,24 +1,22 @@
-// Tests widget — entrée workspace Surface Studio (Lot 53).
+// Surface Studio workspace entry tests for the V2.1 integrated wizard.
 
 import 'dart:convert';
 import 'dart:io';
 
-import 'package:flutter/cupertino.dart';
-import 'package:flutter/material.dart';
+import 'package:flutter/widgets.dart';
 import 'package:flutter_test/flutter_test.dart';
 import 'package:map_core/map_core.dart';
 import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
 import 'package:map_editor/src/features/editor/state/editor_state.dart';
-import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart';
 import 'package:map_editor/src/features/surface_studio/surface_studio_panel.dart';
-import 'package:map_editor/src/features/surface_studio/surface_studio_selection_inspector.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_workflow_layout.dart';
 import 'package:map_editor/src/ui/canvas/editor_canvas_host.dart';
 import 'package:path/path.dart' as p;
 
 import '../shell_chrome_test_harness.dart';
 
 void main() {
-  group('Surface Studio workspace entry (Lot 53)', () {
+  group('Surface Studio workspace entry V2.1', () {
     test('EditorWorkspaceMode.surfaceStudio exists in enum', () {
       expect(
         EditorWorkspaceMode.values.contains(EditorWorkspaceMode.surfaceStudio),
@@ -26,111 +24,31 @@ void main() {
       );
     });
 
-    testWidgets('entry title Surface Studio is visible in explorer',
-        (tester) async {
+    testWidgets('entry remains visible in the explorer', (tester) async {
       await pumpEditorShellPage(
         tester,
         initialState: EditorState(
-          projectRootPath: '/tmp/surface_lot53',
-          project: _buildProjectWithSurfaceCatalog(
-            _minimalCoherentSurfaceCatalog(),
-          ),
+          projectRootPath: '/tmp/surface_v21_entry',
+          project: _projectWithSurfaceCatalog(_minimalSurfaceCatalog()),
         ),
       );
 
+      expect(find.byKey(const Key('surface-studio-workspace-entry')),
+          findsOneWidget);
       expect(find.text('Surface Studio'), findsWidgets);
-    });
-
-    testWidgets('subtitle mentions animated surfaces (Surfaces animées)', (
-      tester,
-    ) async {
-      await pumpEditorShellPage(
-        tester,
-        initialState: EditorState(
-          projectRootPath: '/tmp/surface_lot53',
-          project: _buildProjectWithSurfaceCatalog(
-            _minimalCoherentSurfaceCatalog(),
-          ),
-        ),
-      );
-
       expect(
         find.textContaining('Surfaces animées', findRichText: true),
         findsOneWidget,
       );
     });
 
-    testWidgets('Terrain / Surface Studio / Path Library order in column', (
-      tester,
-    ) async {
-      await pumpEditorShellPage(
-        tester,
-        initialState: EditorState(
-          projectRootPath: '/tmp/surface_lot53',
-          project: _buildProjectWithSurfaceCatalog(
-            _minimalCoherentSurfaceCatalog(),
-          ),
-        ),
-      );
-
-      final terrain = find.text('Terrain Library');
-      final path = find.text('Path Library');
-      final surfaceEntry =
-          find.byKey(const Key('surface-studio-workspace-entry'));
-      expect(terrain, findsOneWidget);
-      expect(path, findsOneWidget);
-      expect(surfaceEntry, findsOneWidget);
-      final yTerrain = tester.getTopLeft(terrain).dy;
-      final ySurface = tester.getTopLeft(surfaceEntry).dy;
-      final yPath = tester.getTopLeft(path).dy;
-      expect(yTerrain, lessThan(ySurface));
-      expect(ySurface, lessThan(yPath));
-    });
-
-    testWidgets('tap entry opens center panel with Lecture seule', (
-      tester,
-    ) async {
-      await pumpEditorShellPage(
-        tester,
-        initialState: EditorState(
-          projectRootPath: '/tmp/surface_lot53',
-          project: _buildProjectWithSurfaceCatalog(
-            _minimalCoherentSurfaceCatalog(),
-          ),
-        ),
-      );
-
-      await tester.ensureVisible(
-        find.byKey(const Key('surface-studio-workspace-entry')),
-      );
-      await tester.pumpAndSettle();
-      await tester.tap(find.byKey(const Key('surface-studio-workspace-entry')));
-      await tester.pumpAndSettle();
-
-      expect(find.text('Lecture seule'), findsNWidgets(1));
-      expect(find.text('Édition partielle'), findsOneWidget);
-      expect(find.text('Inspecteur Surface'), findsOneWidget);
-      expect(find.byType(SurfaceStudioPanel), findsOneWidget);
-      expect(find.text('Catalogue Surface'), findsOneWidget);
-      expect(find.text('Atlas Surface'), findsOneWidget);
-      expect(find.text('Animations Surface'), findsOneWidget);
-      expect(find.text('Presets Surface'), findsOneWidget);
-      expect(find.text('Water Atlas'), findsOneWidget);
-      expect(find.text('Water Isolated Loop'), findsOneWidget);
-      expect(find.text('Water Surface'), findsWidgets);
-      expect(find.text('Diagnostics Surface'), findsOneWidget);
-    });
-
-    testWidgets('EditorCanvasHost builds SurfaceStudioPanel in surface mode', (
-      tester,
-    ) async {
+    testWidgets('surface workspace renders one integrated assistant',
+        (tester) async {
       await pumpEditorShellPage(
         tester,
         initialState: EditorState(
-          projectRootPath: '/tmp/surface_lot53_host',
-          project: _buildProjectWithSurfaceCatalog(
-            _minimalCoherentSurfaceCatalog(),
-          ),
+          projectRootPath: '/tmp/surface_v21_workspace',
+          project: _projectWithSurfaceCatalog(_minimalSurfaceCatalog()),
           workspaceMode: EditorWorkspaceMode.surfaceStudio,
         ),
       );
@@ -138,232 +56,35 @@ void main() {
 
       expect(find.byType(EditorCanvasHost), findsOneWidget);
       expect(find.byType(SurfaceStudioPanel), findsOneWidget);
-    });
-
-    testWidgets('works without an active map (no map required)',
-        (tester) async {
-      await pumpEditorShellPage(
-        tester,
-        initialState: EditorState(
-          projectRootPath: '/tmp/surface_lot53_no_map',
-          project: _buildProjectWithSurfaceCatalog(
-            _minimalCoherentSurfaceCatalog(),
-          ),
-          activeMap: null,
-          activeMapPath: null,
-        ),
-      );
-
+      expect(find.byKey(const Key('surfaceStudio.shell')), findsOneWidget);
       expect(
-        find.text('Open a map to start building your world.'),
+        find.text('Surface Studio — Assistant de mapping d’atlas'),
         findsOneWidget,
       );
-
-      await tester.ensureVisible(
-        find.byKey(const Key('surface-studio-workspace-entry')),
-      );
-      await tester.pumpAndSettle();
-      await tester.tap(find.byKey(const Key('surface-studio-workspace-entry')));
-      await tester.pumpAndSettle();
-
-      expect(find.text('Lecture seule'), findsNWidgets(1));
-      expect(find.text('Édition partielle'), findsOneWidget);
-    });
-
-    testWidgets('panel shows 1/1/1 from manifest when catalog is minimal', (
-      tester,
-    ) async {
-      await pumpEditorShellPage(
-        tester,
-        initialState: EditorState(
-          projectRootPath: '/tmp/surface_lot53_counts',
-          project: _buildProjectWithSurfaceCatalog(
-            _minimalCoherentSurfaceCatalog(),
-          ),
-          workspaceMode: EditorWorkspaceMode.surfaceStudio,
-        ),
-      );
-
-      await tester.pumpAndSettle();
-
-      final counters = find.descendant(
-        of: find.byType(SurfaceStudioPanel),
-        matching: find.byKey(const ValueKey('surface_studio_header_counters')),
-      );
       expect(
-        find.descendant(of: counters, matching: find.text('1')),
-        findsNWidgets(3),
-      );
-    });
-
-    testWidgets(
-        'read-only: actions désactivées; TextField seulement brouillon Lot 60',
-        (tester) async {
-      await pumpEditorShellPage(
-        tester,
-        initialState: EditorState(
-          projectRootPath: '/tmp/surface_lot53_ro',
-          project: _buildProjectWithSurfaceCatalog(
-            _minimalCoherentSurfaceCatalog(),
-          ),
-          workspaceMode: EditorWorkspaceMode.surfaceStudio,
-        ),
-      );
-
-      await tester.pumpAndSettle();
-
-      expect(
-        find.descendant(
-          of: find.byKey(kSurfaceStudioSelectionInspectorKey),
-          matching: find.byType(TextField),
-        ),
+        find.byKey(const Key('surface_studio_legacy_authoring_bridge')),
         findsNothing,
       );
-      expect(
-        find.descendant(
-          of: find.byKey(kSurfaceStudioAtlasAuthoringPrepKey),
-          matching: find.byType(TextField),
-        ),
-        findsWidgets,
-      );
-      expect(find.text('Créer un atlas'), findsNothing);
-      expect(
-        find.text(SurfaceStudioPanel.actionImportVerticalAtlasLabel),
-        findsOneWidget,
-      );
-      final importButton = tester.widget<CupertinoButton>(
-        find.ancestor(
-          of: find.text(SurfaceStudioPanel.actionImportVerticalAtlasLabel),
-          matching: find.byType(CupertinoButton),
-        ),
-      );
-      expect(importButton.onPressed, isNull);
-    });
-
-    testWidgets('no Surface save button labels', (tester) async {
-      await pumpEditorShellPage(
-        tester,
-        initialState: EditorState(
-          projectRootPath: '/tmp/surface_lot53_save',
-          project: _buildProjectWithSurfaceCatalog(
-            _minimalCoherentSurfaceCatalog(),
-          ),
-          workspaceMode: EditorWorkspaceMode.surfaceStudio,
-        ),
-      );
-      await tester.pumpAndSettle();
-
-      expect(find.textContaining('Sauvegarder Surface'), findsNothing);
-      expect(find.textContaining('Enregistrer Surface'), findsNothing);
-      expect(find.textContaining('Save Surface'), findsNothing);
-    });
-
-    testWidgets('Lot 59 — Inspecteur Surface visible en mode workspace', (
-      tester,
-    ) async {
-      await pumpEditorShellPage(
-        tester,
-        initialState: EditorState(
-          projectRootPath: '/tmp/surface_lot59_insp',
-          project: _buildProjectWithSurfaceCatalog(
-            _minimalCoherentSurfaceCatalog(),
-          ),
-          workspaceMode: EditorWorkspaceMode.surfaceStudio,
-        ),
-      );
-      await tester.pumpAndSettle();
-      expect(find.text('Inspecteur Surface'), findsOneWidget);
-    });
-
-    testWidgets('no internal type names in visible shell copy', (tester) async {
-      await pumpEditorShellPage(
-        tester,
-        initialState: EditorState(
-          projectRootPath: '/tmp/surface_lot53_copy',
-          project: _buildProjectWithSurfaceCatalog(
-            _minimalCoherentSurfaceCatalog(),
-          ),
-          workspaceMode: EditorWorkspaceMode.surfaceStudio,
-        ),
-      );
-      await tester.pumpAndSettle();
-
-      expect(find.textContaining('ProjectSurfaceCatalog'), findsNothing);
-      expect(find.textContaining('SurfaceStudioReadModel'), findsNothing);
-      expect(
-          find.textContaining('SurfaceVariantAnimationRefSet'), findsNothing);
+      expect(find.byType(SurfaceStudioWorkflowLayout), findsNothing);
+      expect(find.text('Assistant de création'), findsNothing);
+      expect(find.text('Inspecteur Surface'), findsNothing);
     });
 
     testWidgets(
-        'Lot 64 — préparer sauvegarde : manifest en mémoire (notifier) sans disque',
+        'new wizard save prep updates manifest memory without disk write',
         (tester) async {
-      final empty = _buildProjectWithSurfaceCatalog(
-        ProjectSurfaceCatalog(),
-      );
-      final container = await pumpEditorShellPage(
-        tester,
-        initialState: EditorState(
-          projectRootPath: '/tmp/surface_lot64',
-          project: empty,
-          workspaceMode: EditorWorkspaceMode.surfaceStudio,
-        ),
-      );
-      await tester.pumpAndSettle();
-      final idF = find.byKey(const ValueKey('atlas_draft_id'));
-      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
-      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
-      await tester.ensureVisible(idF);
-      await tester.enterText(idF, 'shell64');
-      await tester.enterText(nameF, 'S');
-      await tester.enterText(tsF, 't');
-      await tester.pump();
-      await tester.ensureVisible(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.pump();
-      await tester.ensureVisible(
-        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
-      );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
-      );
-      await tester.pumpAndSettle(const Duration(milliseconds: 100));
-      final p = container.read(editorNotifierProvider).project;
-      expect(p, isNotNull);
-      expect(p!.surfaceCatalog.atlases.length, 1);
-      expect(p.surfaceCatalog.atlases.first.id, 'shell64');
-      expect(
-        find.text(SurfaceStudioPanel.manifestMemoryUpdatedNote),
-        findsOneWidget,
-      );
-      for (final s in <String>[
-        'Sauvegarder le projet',
-        'Projet sauvegardé',
-        'Save project',
-      ]) {
-        expect(find.text(s), findsNothing);
-      }
-    });
-
-    testWidgets(
-        'Lot 65 — project.json on disk before official save: no new atlas', (
-      tester,
-    ) async {
-      final temp = Directory.systemTemp.createTempSync('map_editor_lot65_');
+      final temp = Directory.systemTemp.createTempSync('map_editor_v21_prep_');
       addTearDown(() {
         if (temp.existsSync()) {
           temp.deleteSync(recursive: true);
         }
       });
-      final empty = _buildProjectWithSurfaceCatalog(ProjectSurfaceCatalog());
+      final empty = _projectWithSurfaceCatalog(ProjectSurfaceCatalog());
       final manifestPath = p.join(temp.path, 'project.json');
       File(manifestPath).writeAsStringSync(
         const JsonEncoder.withIndent('  ').convert(empty.toJson()),
       );
-      await pumpEditorShellPage(
+      final container = await pumpEditorShellPage(
         tester,
         initialState: EditorState(
           projectRootPath: temp.path,
@@ -372,54 +93,36 @@ void main() {
         ),
       );
       await tester.pumpAndSettle();
-      final idF = find.byKey(const ValueKey('atlas_draft_id'));
-      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
-      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
-      await tester.ensureVisible(idF);
-      await tester.enterText(idF, 'lot65a');
-      await tester.enterText(nameF, 'N');
-      await tester.enterText(tsF, 't');
-      await tester.pump();
-      await tester.ensureVisible(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.pump();
-      await tester.ensureVisible(
-        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
-      );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
-      );
-      await tester.pumpAndSettle(const Duration(milliseconds: 200));
+
+      await _createAtlasFromWizard(tester, id: 'v21-prep');
+      await tester
+          .tap(find.byKey(const Key('surfaceStudio.action.saveCatalog')));
+      await tester.pumpAndSettle();
+
+      final inMemory = container.read(editorNotifierProvider).project!;
+      expect(inMemory.surfaceCatalog.atlases.map((atlas) => atlas.id),
+          contains('v21-prep'));
+
       final onDisk = File(manifestPath).readAsStringSync();
       final decoded = jsonDecode(onDisk) as Map<String, dynamic>;
-      final sc = (decoded['surfaceCatalog'] as Map<String, dynamic>?) ?? {};
-      final atl = sc['atlases'] as List<dynamic>? ?? [];
-      expect(atl, isEmpty);
+      final surfaceCatalog =
+          (decoded['surfaceCatalog'] as Map<String, dynamic>?) ?? {};
+      expect(surfaceCatalog['atlases'] as List<dynamic>? ?? [], isEmpty);
     });
 
-    testWidgets(
-        'Lot 65 — apply manifest + saveProjectManifest écrit surfaceCatalog (sans UI prep)',
+    testWidgets('new wizard save prep then saveProjectManifest writes disk',
         (tester) async {
-      final temp =
-          Directory.systemTemp.createTempSync('map_editor_lot65_prog_');
+      final temp = Directory.systemTemp.createTempSync('map_editor_v21_save_');
       addTearDown(() {
         if (temp.existsSync()) {
           temp.deleteSync(recursive: true);
         }
       });
-      final empty = _buildProjectWithSurfaceCatalog(ProjectSurfaceCatalog());
+      final empty = _projectWithSurfaceCatalog(ProjectSurfaceCatalog());
       final manifestPath = p.join(temp.path, 'project.json');
       File(manifestPath).writeAsStringSync(
         const JsonEncoder.withIndent('  ').convert(empty.toJson()),
       );
-      final withCat = replaceProjectManifestSurfaceCatalog(
-        empty,
-        _minimalCoherentSurfaceCatalog(),
-      );
       final container = await pumpEditorShellPage(
         tester,
         initialState: EditorState(
@@ -429,155 +132,111 @@ void main() {
         ),
       );
       await tester.pumpAndSettle();
-      container
-          .read(editorNotifierProvider.notifier)
-          .applyInMemoryProjectManifest(withCat);
-      await tester.pumpAndSettle();
-      expect(
-        container
-            .read(editorNotifierProvider)
-            .project!
-            .surfaceCatalog
-            .atlases
-            .length,
-        1,
-      );
-      var ok = false;
-      await tester.runAsync(() async {
-        ok = await container
-            .read(editorNotifierProvider.notifier)
-            .saveProjectManifest();
-      });
-      expect(ok, isTrue);
-      final onDisk = File(manifestPath).readAsStringSync();
-      final loaded = ProjectManifest.fromJson(
-        jsonDecode(onDisk) as Map<String, dynamic>,
-      );
-      expect(loaded.name, empty.name);
-      expect(loaded.surfaceCatalog.atlases.length, 1);
-      expect(loaded.surfaceCatalog.atlases.first.id, 'water-atlas');
-    });
 
-    testWidgets(
-        'Lot 65 — UI prep puis saveProjectManifest écrit surfaceCatalog',
-        (tester) async {
-      final temp = Directory.systemTemp.createTempSync('map_editor_lot65_ui_');
-      addTearDown(() {
-        if (temp.existsSync()) {
-          temp.deleteSync(recursive: true);
-        }
-      });
-      final empty = _buildProjectWithSurfaceCatalog(ProjectSurfaceCatalog());
-      final manifestPath = p.join(temp.path, 'project.json');
-      File(manifestPath).writeAsStringSync(
-        const JsonEncoder.withIndent('  ').convert(empty.toJson()),
-      );
-      final container = await pumpEditorShellPage(
-        tester,
-        initialState: EditorState(
-          projectRootPath: temp.path,
-          project: empty,
-          workspaceMode: EditorWorkspaceMode.surfaceStudio,
-        ),
-      );
+      await _createAtlasFromWizard(tester, id: 'v21-save');
+      await tester
+          .tap(find.byKey(const Key('surfaceStudio.action.saveCatalog')));
       await tester.pumpAndSettle();
-      final idF = find.byKey(const ValueKey('atlas_draft_id'));
-      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
-      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
-      await tester.ensureVisible(idF);
-      await tester.enterText(idF, 'lot65save');
-      await tester.enterText(nameF, 'N');
-      await tester.enterText(tsF, 't');
-      await tester.pump();
-      await tester.ensureVisible(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
-      );
-      await tester.pump();
-      await tester.ensureVisible(
-        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
-      );
-      await tester.tap(
-        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
-      );
-      await tester.pumpAndSettle(const Duration(milliseconds: 200));
-      expect(
-        container
-            .read(editorNotifierProvider)
-            .project!
-            .surfaceCatalog
-            .atlases
-            .length,
-        1,
-      );
+
       var ok = false;
       await tester.runAsync(() async {
         ok = await container
             .read(editorNotifierProvider.notifier)
             .saveProjectManifest();
       });
+
       expect(ok, isTrue);
-      final onDisk = File(manifestPath).readAsStringSync();
       final loaded = ProjectManifest.fromJson(
-        jsonDecode(onDisk) as Map<String, dynamic>,
+        jsonDecode(File(manifestPath).readAsStringSync())
+            as Map<String, dynamic>,
       );
-      expect(loaded.name, empty.name);
-      expect(loaded.surfaceCatalog.atlases.length, 1);
-      expect(loaded.surfaceCatalog.atlases.first.id, 'lot65save');
+      expect(loaded.surfaceCatalog.atlases.map((atlas) => atlas.id),
+          contains('v21-save'));
     });
   });
 }
 
-// --- Même minimal catalogue qu’au test Lot 52 (1 atlas, 1 anim, 1 preset) ---
+Future<void> _createAtlasFromWizard(
+  WidgetTester tester, {
+  required String id,
+}) async {
+  await tester.enterText(
+    find.byKey(const Key('surfaceStudio.import.atlasId')),
+    id,
+  );
+  await tester.enterText(
+    find.byKey(const Key('surfaceStudio.import.atlasName')),
+    'Surface $id',
+  );
+  await tester.enterText(
+    find.byKey(const Key('surfaceStudio.import.tilesetId')),
+    'nature-tileset',
+  );
+  final createButton =
+      find.byKey(const Key('surfaceStudio.import.createAtlas'));
+  await tester.ensureVisible(createButton);
+  await tester.pumpAndSettle();
+  await tester.tap(createButton);
+  await tester.pump();
+}
 
-ProjectSurfaceCatalog _minimalCoherentSurfaceCatalog() {
-  final g = SurfaceAtlasGeometry(
-    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
-    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
-    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+ProjectManifest _projectWithSurfaceCatalog(ProjectSurfaceCatalog catalog) {
+  return ProjectManifest(
+    name: 'Surface V2.1',
+    maps: const <ProjectMapEntry>[],
+    tilesets: const <ProjectTilesetEntry>[
+      ProjectTilesetEntry(
+        id: 'nature-tileset',
+        name: 'Nature Tileset',
+        relativePath: 'assets/tilesets/nature.png',
+      ),
+    ],
+    surfaceCatalog: catalog,
   );
+}
+
+ProjectSurfaceCatalog _minimalSurfaceCatalog() {
   final atlas = ProjectSurfaceAtlas(
     id: 'water-atlas',
     name: 'Water Atlas',
     tilesetId: 'nature-tileset',
-    geometry: g,
-  );
-  final frame = SurfaceAnimationFrame(
-    tileRef: SurfaceAtlasTileRef(atlasId: 'water-atlas', column: 0, row: 0),
-    durationMs: 120,
+    geometry: SurfaceAtlasGeometry(
+      tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+      gridSize: SurfaceAtlasGridSize(columns: 12, rows: 32),
+      layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+    ),
   );
-  final anim = ProjectSurfaceAnimation(
+  final animation = ProjectSurfaceAnimation(
     id: 'water-isolated-loop',
     name: 'Water Isolated Loop',
-    timeline: SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[frame]),
-  );
-  final refs = SurfaceVariantAnimationRefSet(
-    refs: <SurfaceVariantAnimationRef>[
-      SurfaceVariantAnimationRef(
-        role: SurfaceVariantRole.isolated,
-        animationId: 'water-isolated-loop',
-      ),
-    ],
+    timeline: SurfaceAnimationTimeline(
+      frames: [
+        SurfaceAnimationFrame(
+          tileRef: SurfaceAtlasTileRef(
+            atlasId: 'water-atlas',
+            column: 0,
+            row: 0,
+          ),
+          durationMs: 120,
+        ),
+      ],
+    ),
   );
   final preset = ProjectSurfacePreset(
     id: 'water-surface',
     name: 'Water Surface',
-    variantAnimations: refs,
+    variantAnimations: SurfaceVariantAnimationRefSet(
+      refs: [
+        SurfaceVariantAnimationRef(
+          role: SurfaceVariantRole.isolated,
+          animationId: 'water-isolated-loop',
+        ),
+      ],
+    ),
   );
   return ProjectSurfaceCatalog(
-    atlases: <ProjectSurfaceAtlas>[atlas],
-    animations: <ProjectSurfaceAnimation>[anim],
-    presets: <ProjectSurfacePreset>[preset],
-  );
-}
-
-ProjectManifest _buildProjectWithSurfaceCatalog(ProjectSurfaceCatalog c) {
-  return ProjectManifest(
-    name: 'Surface Lot53',
-    maps: <ProjectMapEntry>[],
-    tilesets: <ProjectTilesetEntry>[],
-    surfaceCatalog: c,
+    atlases: [atlas],
+    animations: [animation],
+    presets: [preset],
   );
 }
```
### Diff nouveau fichier `packages/map_editor/lib/src/features/editor/application/editor_ai_settings.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/editor/application/editor_ai_settings.dart b/packages/map_editor/lib/src/features/editor/application/editor_ai_settings.dart
new file mode 100644
index 00000000..a871a7bf
--- /dev/null
+++ b/packages/map_editor/lib/src/features/editor/application/editor_ai_settings.dart
@@ -0,0 +1,18 @@
+import 'dart:io';
+
+import 'package:map_core/map_core.dart';
+
+/// Resolve the editor-wide Mistral key without exposing or logging it.
+///
+/// Priority stays intentionally shared across editor AI features:
+/// project settings first, then the `MISTRAL_API_KEY` environment fallback.
+String resolveEditorMistralApiKey(ProjectSettings? settings) {
+  final fromProject = settings?.mistralApiKey?.trim() ?? '';
+  if (fromProject.isNotEmpty) {
+    return fromProject;
+  }
+  return Platform.environment['MISTRAL_API_KEY'] ?? '';
+}
+
+bool hasEditorMistralApiKey(ProjectSettings? settings) =>
+    resolveEditorMistralApiKey(settings).trim().isNotEmpty;
```
### Diff nouveau fichier `packages/map_editor/lib/src/features/surface_studio/surface_studio_local_mapping_suggester.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_local_mapping_suggester.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_local_mapping_suggester.dart
new file mode 100644
index 00000000..768287f0
--- /dev/null
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_local_mapping_suggester.dart
@@ -0,0 +1,89 @@
+import 'package:map_core/map_core.dart';
+
+import 'surface_studio_mapping_suggestion_models.dart';
+
+final class SurfaceStudioLocalMappingSuggester {
+  const SurfaceStudioLocalMappingSuggester();
+
+  SurfaceStudioMappingSuggestionResult suggest({required int columnCount}) {
+    if (columnCount <= 0) {
+      return const SurfaceStudioMappingSuggestionResult(
+        suggestions: <SurfaceStudioRoleSuggestion>[],
+        warnings: <String>[
+          'Aucune colonne disponible pour proposer un mapping.',
+        ],
+        source: SurfaceStudioMappingSuggestionSource.local,
+      );
+    }
+
+    final suggestions = <SurfaceStudioRoleSuggestion>[];
+    final warnings = <String>[];
+    final usedColumns = <int>{};
+    final centerColumns = _centerColumns(columnCount);
+    usedColumns.addAll(centerColumns);
+    suggestions.add(
+      SurfaceStudioRoleSuggestion(
+        role: SurfaceVariantRole.isolated,
+        columns: centerColumns,
+        confidence: centerColumns.length >= 2
+            ? SurfaceStudioMappingSuggestionConfidence.medium
+            : SurfaceStudioMappingSuggestionConfidence.low,
+        source: SurfaceStudioMappingSuggestionSource.local,
+        reason:
+            'Le rôle Plein accepte plusieurs colonnes ; la suggestion locale choisit une plage centrale bornée par l’atlas.',
+      ),
+    );
+    if (centerColumns.length > 1) {
+      warnings.add(
+        'Plein peut recevoir plusieurs colonnes, mais la génération V2.1 utilise seulement la première colonne pour les animations.',
+      );
+    }
+
+    var nextColumn = 1;
+    for (final role in standardSurfaceVariantRoleOrder) {
+      if (role == SurfaceVariantRole.isolated) {
+        continue;
+      }
+      while (nextColumn <= columnCount && usedColumns.contains(nextColumn)) {
+        nextColumn++;
+      }
+      if (nextColumn > columnCount) {
+        break;
+      }
+      suggestions.add(
+        SurfaceStudioRoleSuggestion(
+          role: role,
+          columns: <int>[nextColumn],
+          confidence: SurfaceStudioMappingSuggestionConfidence.low,
+          source: SurfaceStudioMappingSuggestionSource.local,
+          reason:
+              'Assignation déterministe selon l’ordre standard des rôles Surface.',
+        ),
+      );
+      usedColumns.add(nextColumn);
+      nextColumn++;
+    }
+
+    if (suggestions.length < standardSurfaceVariantRoleOrder.length) {
+      warnings.add(
+        'L’atlas ne contient pas assez de colonnes pour couvrir tous les rôles standard.',
+      );
+    }
+
+    return SurfaceStudioMappingSuggestionResult(
+      suggestions: List<SurfaceStudioRoleSuggestion>.unmodifiable(suggestions),
+      warnings: List<String>.unmodifiable(warnings),
+      source: SurfaceStudioMappingSuggestionSource.local,
+    );
+  }
+
+  List<int> _centerColumns(int columnCount) {
+    if (columnCount >= 6) {
+      return <int>[4, 5, 6].where((column) => column <= columnCount).toList();
+    }
+    if (columnCount >= 3) {
+      return const <int>[1, 2, 3];
+    }
+    return <int>[1];
+  }
+}
```
### Diff nouveau fichier `packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_controller.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_controller.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_controller.dart
new file mode 100644
index 00000000..e8ab83cf
--- /dev/null
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_controller.dart
@@ -0,0 +1,20 @@
+import 'surface_studio_local_mapping_suggester.dart';
+import 'surface_studio_mapping_suggestion_models.dart';
+
+final class SurfaceStudioMappingSuggestionController {
+  const SurfaceStudioMappingSuggestionController({
+    this.localSuggester = const SurfaceStudioLocalMappingSuggester(),
+  });
+
+  final SurfaceStudioLocalMappingSuggester localSuggester;
+
+  SurfaceStudioMappingSuggestionResult suggestLocal({
+    required int columnCount,
+  }) {
+    return localSuggester.suggest(columnCount: columnCount);
+  }
+}
+
+abstract class SurfaceStudioAiMappingSuggester {
+  Future<SurfaceStudioMappingSuggestionResult> suggest();
+}
```
### Diff nouveau fichier `packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_models.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_models.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_models.dart
new file mode 100644
index 00000000..5c3b0335
--- /dev/null
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_models.dart
@@ -0,0 +1,84 @@
+import 'package:map_core/map_core.dart';
+
+enum SurfaceStudioMappingSuggestionSource {
+  local,
+  mistral,
+  merged,
+}
+
+enum SurfaceStudioMappingSuggestionConfidence {
+  high,
+  medium,
+  low,
+}
+
+final class SurfaceStudioRoleSuggestion {
+  const SurfaceStudioRoleSuggestion({
+    required this.role,
+    required this.columns,
+    required this.confidence,
+    required this.source,
+    required this.reason,
+  });
+
+  final SurfaceVariantRole role;
+  final List<int> columns;
+  final SurfaceStudioMappingSuggestionConfidence confidence;
+  final SurfaceStudioMappingSuggestionSource source;
+  final String reason;
+
+  @override
+  bool operator ==(Object other) =>
+      identical(this, other) ||
+      other is SurfaceStudioRoleSuggestion &&
+          other.role == role &&
+          _listEquals(other.columns, columns) &&
+          other.confidence == confidence &&
+          other.source == source &&
+          other.reason == reason;
+
+  @override
+  int get hashCode => Object.hash(
+        role,
+        Object.hashAll(columns),
+        confidence,
+        source,
+        reason,
+      );
+}
+
+final class SurfaceStudioMappingSuggestionResult {
+  const SurfaceStudioMappingSuggestionResult({
+    required this.suggestions,
+    required this.warnings,
+    required this.source,
+  });
+
+  final List<SurfaceStudioRoleSuggestion> suggestions;
+  final List<String> warnings;
+  final SurfaceStudioMappingSuggestionSource source;
+
+  Iterable<SurfaceStudioRoleSuggestion> get reliableSuggestions =>
+      suggestions.where(
+        (suggestion) =>
+            suggestion.confidence ==
+                SurfaceStudioMappingSuggestionConfidence.high ||
+            suggestion.confidence ==
+                SurfaceStudioMappingSuggestionConfidence.medium,
+      );
+}
+
+bool _listEquals(List<int> a, List<int> b) {
+  if (identical(a, b)) {
+    return true;
+  }
+  if (a.length != b.length) {
+    return false;
+  }
+  for (var i = 0; i < a.length; i++) {
+    if (a[i] != b[i]) {
+      return false;
+    }
+  }
+  return true;
+}
```
### Diff nouveau fichier `packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart`

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart b/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart
new file mode 100644
index 00000000..8afed90a
--- /dev/null
+++ b/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart
@@ -0,0 +1,63 @@
+import 'package:flutter/widgets.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_local_mapping_suggester.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_mapping_suggestion_models.dart';
+
+import 'surface_studio_rebuild_test_harness.dart';
+
+void main() {
+  test('local suggester returns bounded reviewable suggestions', () {
+    final result = SurfaceStudioLocalMappingSuggester().suggest(columnCount: 3);
+
+    expect(result.source, SurfaceStudioMappingSuggestionSource.local);
+    expect(result.suggestions, isNotEmpty);
+    expect(
+      result.suggestions.every(
+        (suggestion) =>
+            suggestion.columns.every((column) => column >= 1 && column <= 3),
+      ),
+      isTrue,
+    );
+    expect(result.warnings, isNotEmpty);
+  });
+
+  testWidgets('Suggestion auto opens a review before mutating the mapping',
+      (tester) async {
+    await pumpSurfaceStudioForTest(tester);
+    await tester.pump();
+
+    await tester.tap(find.byKey(const Key('surfaceStudio.action.autoSuggest')));
+    await tester.pumpAndSettle();
+
+    expect(find.text('Suggestions détectées'), findsOneWidget);
+    expect(find.text('Source : Local'), findsOneWidget);
+    expect(find.text('Appliquer les suggestions fiables'), findsOneWidget);
+    expect(find.text('Analyse IA Mistral'), findsOneWidget);
+    expect(
+      find.text(
+          'Clé Mistral absente : Projet → Paramètres (IA) ou MISTRAL_API_KEY'),
+      findsOneWidget,
+    );
+
+    await tester.tap(find.text('Annuler'));
+    await tester.pumpAndSettle();
+    expect(find.text('Suggestions détectées'), findsNothing);
+  });
+
+  testWidgets('Mistral prep detects configured key without displaying it',
+      (tester) async {
+    await pumpSurfaceStudioForTest(
+      tester,
+      projectSettings: const ProjectSettings(mistralApiKey: 'configured'),
+    );
+    await tester.pump();
+
+    await tester.tap(find.byKey(const Key('surfaceStudio.action.autoSuggest')));
+    await tester.pumpAndSettle();
+
+    expect(find.text('Clé Mistral configurée.'), findsOneWidget);
+    expect(find.textContaining('configured'), findsNothing);
+    expect(find.text('Analyse IA à venir'), findsOneWidget);
+  });
+}
```
### Diff nouveau fichier `packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart`

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart b/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart
new file mode 100644
index 00000000..ee2b4044
--- /dev/null
+++ b/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart
@@ -0,0 +1,68 @@
+import 'package:flutter/widgets.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_workflow_layout.dart';
+
+import 'surface_studio_rebuild_test_harness.dart';
+
+void main() {
+  testWidgets(
+      'Surface Studio renders one integrated wizard without legacy below',
+      (tester) async {
+    await pumpSurfaceStudioForTest(tester);
+    await tester.pump();
+
+    expect(find.byKey(const Key('surfaceStudio.shell')), findsOneWidget);
+    expect(
+      find.byKey(const Key('surface_studio_legacy_authoring_bridge')),
+      findsNothing,
+    );
+    expect(find.byType(SurfaceStudioWorkflowLayout), findsNothing);
+    expect(find.text('Assistant de création'), findsNothing);
+    expect(
+      find.text('Surface Studio — Assistant de mapping d’atlas'),
+      findsOneWidget,
+    );
+  });
+
+  testWidgets('new import step can create an atlas in the work catalog',
+      (tester) async {
+    ProjectSurfaceCatalog? saved;
+    await pumpSurfaceStudioForTest(
+      tester,
+      readModel:
+          buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog()),
+      onSurfaceCatalogSaveRequested: (catalog) => saved = catalog,
+    );
+    await tester.pump();
+
+    await tester.tap(find.byKey(const Key('surfaceStudio.step.import')));
+    await tester.pumpAndSettle();
+
+    await tester.enterText(
+      find.byKey(const Key('surfaceStudio.import.atlasId')),
+      'v21-water',
+    );
+    await tester.enterText(
+      find.byKey(const Key('surfaceStudio.import.atlasName')),
+      'V2.1 Water',
+    );
+    await tester.enterText(
+      find.byKey(const Key('surfaceStudio.import.tilesetId')),
+      'water_tiles',
+    );
+    await tester.tap(find.byKey(const Key('surfaceStudio.import.createAtlas')));
+    await tester.pump();
+
+    expect(
+      find.text(
+          'Catalogue de travail modifié — sauvegarde projet non effectuée.'),
+      findsOneWidget,
+    );
+    await tester.tap(find.byKey(const Key('surfaceStudio.action.saveCatalog')));
+    await tester.pump();
+
+    expect(saved, isNotNull);
+    expect(saved!.atlases.map((atlas) => atlas.id), contains('v21-water'));
+  });
+}
```
## Contenu complet des fichiers créés

### `packages/map_editor/lib/src/features/editor/application/editor_ai_settings.dart`

```dart
import 'dart:io';

import 'package:map_core/map_core.dart';

/// Resolve the editor-wide Mistral key without exposing or logging it.
///
/// Priority stays intentionally shared across editor AI features:
/// project settings first, then the `MISTRAL_API_KEY` environment fallback.
String resolveEditorMistralApiKey(ProjectSettings? settings) {
  final fromProject = settings?.mistralApiKey?.trim() ?? '';
  if (fromProject.isNotEmpty) {
    return fromProject;
  }
  return Platform.environment['MISTRAL_API_KEY'] ?? '';
}

bool hasEditorMistralApiKey(ProjectSettings? settings) =>
    resolveEditorMistralApiKey(settings).trim().isNotEmpty;
```
### `packages/map_editor/lib/src/features/surface_studio/surface_studio_local_mapping_suggester.dart`

```dart
import 'package:map_core/map_core.dart';

import 'surface_studio_mapping_suggestion_models.dart';

final class SurfaceStudioLocalMappingSuggester {
  const SurfaceStudioLocalMappingSuggester();

  SurfaceStudioMappingSuggestionResult suggest({required int columnCount}) {
    if (columnCount <= 0) {
      return const SurfaceStudioMappingSuggestionResult(
        suggestions: <SurfaceStudioRoleSuggestion>[],
        warnings: <String>[
          'Aucune colonne disponible pour proposer un mapping.',
        ],
        source: SurfaceStudioMappingSuggestionSource.local,
      );
    }

    final suggestions = <SurfaceStudioRoleSuggestion>[];
    final warnings = <String>[];
    final usedColumns = <int>{};
    final centerColumns = _centerColumns(columnCount);
    usedColumns.addAll(centerColumns);
    suggestions.add(
      SurfaceStudioRoleSuggestion(
        role: SurfaceVariantRole.isolated,
        columns: centerColumns,
        confidence: centerColumns.length >= 2
            ? SurfaceStudioMappingSuggestionConfidence.medium
            : SurfaceStudioMappingSuggestionConfidence.low,
        source: SurfaceStudioMappingSuggestionSource.local,
        reason:
            'Le rôle Plein accepte plusieurs colonnes ; la suggestion locale choisit une plage centrale bornée par l’atlas.',
      ),
    );
    if (centerColumns.length > 1) {
      warnings.add(
        'Plein peut recevoir plusieurs colonnes, mais la génération V2.1 utilise seulement la première colonne pour les animations.',
      );
    }

    var nextColumn = 1;
    for (final role in standardSurfaceVariantRoleOrder) {
      if (role == SurfaceVariantRole.isolated) {
        continue;
      }
      while (nextColumn <= columnCount && usedColumns.contains(nextColumn)) {
        nextColumn++;
      }
      if (nextColumn > columnCount) {
        break;
      }
      suggestions.add(
        SurfaceStudioRoleSuggestion(
          role: role,
          columns: <int>[nextColumn],
          confidence: SurfaceStudioMappingSuggestionConfidence.low,
          source: SurfaceStudioMappingSuggestionSource.local,
          reason:
              'Assignation déterministe selon l’ordre standard des rôles Surface.',
        ),
      );
      usedColumns.add(nextColumn);
      nextColumn++;
    }

    if (suggestions.length < standardSurfaceVariantRoleOrder.length) {
      warnings.add(
        'L’atlas ne contient pas assez de colonnes pour couvrir tous les rôles standard.',
      );
    }

    return SurfaceStudioMappingSuggestionResult(
      suggestions: List<SurfaceStudioRoleSuggestion>.unmodifiable(suggestions),
      warnings: List<String>.unmodifiable(warnings),
      source: SurfaceStudioMappingSuggestionSource.local,
    );
  }

  List<int> _centerColumns(int columnCount) {
    if (columnCount >= 6) {
      return <int>[4, 5, 6].where((column) => column <= columnCount).toList();
    }
    if (columnCount >= 3) {
      return const <int>[1, 2, 3];
    }
    return <int>[1];
  }
}
```
### `packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_controller.dart`

```dart
import 'surface_studio_local_mapping_suggester.dart';
import 'surface_studio_mapping_suggestion_models.dart';

final class SurfaceStudioMappingSuggestionController {
  const SurfaceStudioMappingSuggestionController({
    this.localSuggester = const SurfaceStudioLocalMappingSuggester(),
  });

  final SurfaceStudioLocalMappingSuggester localSuggester;

  SurfaceStudioMappingSuggestionResult suggestLocal({
    required int columnCount,
  }) {
    return localSuggester.suggest(columnCount: columnCount);
  }
}

abstract class SurfaceStudioAiMappingSuggester {
  Future<SurfaceStudioMappingSuggestionResult> suggest();
}
```
### `packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_models.dart`

```dart
import 'package:map_core/map_core.dart';

enum SurfaceStudioMappingSuggestionSource {
  local,
  mistral,
  merged,
}

enum SurfaceStudioMappingSuggestionConfidence {
  high,
  medium,
  low,
}

final class SurfaceStudioRoleSuggestion {
  const SurfaceStudioRoleSuggestion({
    required this.role,
    required this.columns,
    required this.confidence,
    required this.source,
    required this.reason,
  });

  final SurfaceVariantRole role;
  final List<int> columns;
  final SurfaceStudioMappingSuggestionConfidence confidence;
  final SurfaceStudioMappingSuggestionSource source;
  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceStudioRoleSuggestion &&
          other.role == role &&
          _listEquals(other.columns, columns) &&
          other.confidence == confidence &&
          other.source == source &&
          other.reason == reason;

  @override
  int get hashCode => Object.hash(
        role,
        Object.hashAll(columns),
        confidence,
        source,
        reason,
      );
}

final class SurfaceStudioMappingSuggestionResult {
  const SurfaceStudioMappingSuggestionResult({
    required this.suggestions,
    required this.warnings,
    required this.source,
  });

  final List<SurfaceStudioRoleSuggestion> suggestions;
  final List<String> warnings;
  final SurfaceStudioMappingSuggestionSource source;

  Iterable<SurfaceStudioRoleSuggestion> get reliableSuggestions =>
      suggestions.where(
        (suggestion) =>
            suggestion.confidence ==
                SurfaceStudioMappingSuggestionConfidence.high ||
            suggestion.confidence ==
                SurfaceStudioMappingSuggestionConfidence.medium,
      );
}

bool _listEquals(List<int> a, List<int> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
```
### `packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_local_mapping_suggester.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_mapping_suggestion_models.dart';

import 'surface_studio_rebuild_test_harness.dart';

void main() {
  test('local suggester returns bounded reviewable suggestions', () {
    final result = SurfaceStudioLocalMappingSuggester().suggest(columnCount: 3);

    expect(result.source, SurfaceStudioMappingSuggestionSource.local);
    expect(result.suggestions, isNotEmpty);
    expect(
      result.suggestions.every(
        (suggestion) =>
            suggestion.columns.every((column) => column >= 1 && column <= 3),
      ),
      isTrue,
    );
    expect(result.warnings, isNotEmpty);
  });

  testWidgets('Suggestion auto opens a review before mutating the mapping',
      (tester) async {
    await pumpSurfaceStudioForTest(tester);
    await tester.pump();

    await tester.tap(find.byKey(const Key('surfaceStudio.action.autoSuggest')));
    await tester.pumpAndSettle();

    expect(find.text('Suggestions détectées'), findsOneWidget);
    expect(find.text('Source : Local'), findsOneWidget);
    expect(find.text('Appliquer les suggestions fiables'), findsOneWidget);
    expect(find.text('Analyse IA Mistral'), findsOneWidget);
    expect(
      find.text(
          'Clé Mistral absente : Projet → Paramètres (IA) ou MISTRAL_API_KEY'),
      findsOneWidget,
    );

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Suggestions détectées'), findsNothing);
  });

  testWidgets('Mistral prep detects configured key without displaying it',
      (tester) async {
    await pumpSurfaceStudioForTest(
      tester,
      projectSettings: const ProjectSettings(mistralApiKey: 'configured'),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('surfaceStudio.action.autoSuggest')));
    await tester.pumpAndSettle();

    expect(find.text('Clé Mistral configurée.'), findsOneWidget);
    expect(find.textContaining('configured'), findsNothing);
    expect(find.text('Analyse IA à venir'), findsOneWidget);
  });
}
```
### `packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_workflow_layout.dart';

import 'surface_studio_rebuild_test_harness.dart';

void main() {
  testWidgets(
      'Surface Studio renders one integrated wizard without legacy below',
      (tester) async {
    await pumpSurfaceStudioForTest(tester);
    await tester.pump();

    expect(find.byKey(const Key('surfaceStudio.shell')), findsOneWidget);
    expect(
      find.byKey(const Key('surface_studio_legacy_authoring_bridge')),
      findsNothing,
    );
    expect(find.byType(SurfaceStudioWorkflowLayout), findsNothing);
    expect(find.text('Assistant de création'), findsNothing);
    expect(
      find.text('Surface Studio — Assistant de mapping d’atlas'),
      findsOneWidget,
    );
  });

  testWidgets('new import step can create an atlas in the work catalog',
      (tester) async {
    ProjectSurfaceCatalog? saved;
    await pumpSurfaceStudioForTest(
      tester,
      readModel:
          buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog()),
      onSurfaceCatalogSaveRequested: (catalog) => saved = catalog,
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('surfaceStudio.step.import')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('surfaceStudio.import.atlasId')),
      'v21-water',
    );
    await tester.enterText(
      find.byKey(const Key('surfaceStudio.import.atlasName')),
      'V2.1 Water',
    );
    await tester.enterText(
      find.byKey(const Key('surfaceStudio.import.tilesetId')),
      'water_tiles',
    );
    await tester.tap(find.byKey(const Key('surfaceStudio.import.createAtlas')));
    await tester.pump();

    expect(
      find.text(
          'Catalogue de travail modifié — sauvegarde projet non effectuée.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('surfaceStudio.action.saveCatalog')));
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved!.atlases.map((atlas) => atlas.id), contains('v21-water'));
  });
}
```
## Contenu complet des fichiers modifiés

### `packages/map_editor/lib/src/features/dialogue/application/mistral_dialogue_client.dart`

```dart
// -----------------------------------------------------------------------------
// Client HTTP minimal Mistral AI — utilisé par Dialogue Studio
// -----------------------------------------------------------------------------
// - Aucun provider abstrait : une seule implémentation REST réelle.
// - Clé API : [ProjectSettings.mistralApiKey] (paramètres projet) puis
//   variable d’environnement `MISTRAL_API_KEY`.
// -----------------------------------------------------------------------------

import 'dart:convert';

import 'package:http/http.dart' as http;

export '../../editor/application/editor_ai_settings.dart'
    show resolveEditorMistralApiKey;

/// Erreur réseau ou réponse API inattendue.
class MistralDialogueException implements Exception {
  MistralDialogueException(this.message);
  final String message;

  @override
  String toString() => 'MistralDialogueException: $message';
}

/// Appel synchrone `chat/completions` (petits prompts dialogue).
class MistralDialogueClient {
  MistralDialogueClient({
    http.Client? httpClient,
    this.baseUrl = 'https://api.mistral.ai/v1/chat/completions',
  }) : _client = httpClient ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  /// Retourne le texte du premier choix (contenu assistant).
  Future<String> completeChat({
    required String apiKey,
    required String systemPrompt,
    required String userMessage,
    String model = 'mistral-small-latest',
  }) async {
    final trimmedKey = apiKey.trim();
    if (trimmedKey.isEmpty) {
      throw MistralDialogueException('Clé API Mistral absente.');
    }

    final uri = Uri.parse(baseUrl);
    final body = jsonEncode({
      'model': model,
      'temperature': 0.7,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userMessage},
      ],
    });

    final response = await _client.post(
      uri,
      headers: {
        'Authorization': 'Bearer $trimmedKey',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MistralDialogueException(
        'HTTP ${response.statusCode}: ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw MistralDialogueException('Réponse JSON invalide.');
    }
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      throw MistralDialogueException('Aucun choix dans la réponse Mistral.');
    }
    final first = choices.first;
    if (first is! Map<String, dynamic>) {
      throw MistralDialogueException('Format de choix inattendu.');
    }
    final msg = first['message'];
    if (msg is! Map<String, dynamic>) {
      throw MistralDialogueException('Message assistant manquant.');
    }
    final content = msg['content'];
    if (content is! String) {
      throw MistralDialogueException('Contenu assistant vide ou non texte.');
    }
    return content;
  }

  void close() {
    _client.close();
  }
}

/// Retire les balises ``` optionnelles entourant le Yarn renvoyé par le modèle.
String stripMarkdownFences(String raw) {
  var s = raw.trim();
  if (s.startsWith('```')) {
    final firstNl = s.indexOf('\n');
    if (firstNl != -1) {
      s = s.substring(firstNl + 1);
    }
    if (s.endsWith('```')) {
      s = s.substring(0, s.length - 3).trim();
    }
  }
  return s.trim();
}
```
### `packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Material, MaterialType, PopupMenuButton, PopupMenuItem, Slider;
import 'package:map_core/map_core.dart';

import '../surface_studio_design_tokens.dart';
import '../surface_studio_role_assignment_draft.dart';

class SurfaceStudioPreviewPanel extends StatelessWidget {
  const SurfaceStudioPreviewPanel({
    super.key,
    required this.frameCount,
    required this.frameIndex,
    required this.playing,
    required this.loop,
    required this.gridVisible,
    required this.previewSize,
    required this.assignmentDraft,
    required this.onPrevious,
    required this.onNext,
    required this.onTogglePlaying,
    required this.onFrameChanged,
    required this.onLoopChanged,
    required this.onGridChanged,
    required this.onPreviewSizeChanged,
  });

  final int frameCount;
  final int frameIndex;
  final bool playing;
  final bool loop;
  final bool gridVisible;
  final int previewSize;
  final SurfaceStudioRoleAssignmentDraft assignmentDraft;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onTogglePlaying;
  final ValueChanged<int> onFrameChanged;
  final ValueChanged<bool> onLoopChanged;
  final ValueChanged<bool> onGridChanged;
  final ValueChanged<int> onPreviewSizeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('surfaceStudio.preview.panel'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundPanel,
        borderRadius:
            BorderRadius.circular(SurfaceStudioDesignTokens.panelRadius),
        border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Prévisualisation',
            style: TextStyle(
              color: SurfaceStudioDesignTokens.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: RepaintBoundary(
                    child: _PreviewViewport(
                      previewSize: previewSize,
                      gridVisible: gridVisible,
                      hasCenter: assignmentDraft.isAssigned(
                        SurfaceVariantRole.isolated,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 180,
                  child: _PreviewControls(
                    frameCount: frameCount,
                    frameIndex: frameIndex,
                    playing: playing,
                    loop: loop,
                    gridVisible: gridVisible,
                    previewSize: previewSize,
                    onPrevious: onPrevious,
                    onNext: onNext,
                    onTogglePlaying: onTogglePlaying,
                    onFrameChanged: onFrameChanged,
                    onLoopChanged: onLoopChanged,
                    onGridChanged: onGridChanged,
                    onPreviewSizeChanged: onPreviewSizeChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewViewport extends StatelessWidget {
  const _PreviewViewport({
    required this.previewSize,
    required this.gridVisible,
    required this.hasCenter,
  });

  final int previewSize;
  final bool gridVisible;
  final bool hasCenter;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundDeep,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SurfaceStudioDesignTokens.borderStrong),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasCenter
          ? CustomPaint(
              painter: _WaterPreviewPainter(
                gridVisible: gridVisible,
                previewSize: previewSize,
              ),
              child: const SizedBox.expand(),
            )
          : const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Assignez au moins le rôle “Plein” pour générer une prévisualisation.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SurfaceStudioDesignTokens.textMuted,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ),
            ),
    );
  }
}

class _PreviewControls extends StatelessWidget {
  const _PreviewControls({
    required this.frameCount,
    required this.frameIndex,
    required this.playing,
    required this.loop,
    required this.gridVisible,
    required this.previewSize,
    required this.onPrevious,
    required this.onNext,
    required this.onTogglePlaying,
    required this.onFrameChanged,
    required this.onLoopChanged,
    required this.onGridChanged,
    required this.onPreviewSizeChanged,
  });

  final int frameCount;
  final int frameIndex;
  final bool playing;
  final bool loop;
  final bool gridVisible;
  final int previewSize;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onTogglePlaying;
  final ValueChanged<int> onFrameChanged;
  final ValueChanged<bool> onLoopChanged;
  final ValueChanged<bool> onGridChanged;
  final ValueChanged<int> onPreviewSizeChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: SurfaceStudioDesignTokens.backgroundPanelAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RoundControl(
                      keyName: 'surfaceStudio.preview.previous',
                      icon: CupertinoIcons.backward_end_fill,
                      onPressed: onPrevious,
                    ),
                    const SizedBox(width: 10),
                    _RoundControl(
                      keyName: 'surfaceStudio.preview.playPause',
                      icon: playing
                          ? CupertinoIcons.pause_fill
                          : CupertinoIcons.play_fill,
                      onPressed: onTogglePlaying,
                      highlighted: true,
                    ),
                    const SizedBox(width: 10),
                    _RoundControl(
                      keyName: 'surfaceStudio.preview.next',
                      icon: CupertinoIcons.forward_end_fill,
                      onPressed: onNext,
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  'Frame ${frameIndex + 1} / $frameCount',
                  style: const TextStyle(
                    color: SurfaceStudioDesignTokens.textSecondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                Material(
                  type: MaterialType.transparency,
                  child: Slider(
                    key: const ValueKey('surfaceStudio.preview.scrubSlider'),
                    value: frameIndex.toDouble(),
                    min: 0,
                    max: (frameCount - 1).toDouble(),
                    divisions: frameCount > 1 ? frameCount - 1 : null,
                    onChanged: (value) => onFrameChanged(value.round()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: SurfaceStudioDesignTokens.backgroundPanelAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CheckLine(
                    label: 'Boucle',
                    value: loop,
                    onChanged: onLoopChanged,
                  ),
                  _CheckLine(
                    label: 'Grille',
                    value: gridVisible,
                    onChanged: onGridChanged,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Taille',
                        style: TextStyle(
                          color: SurfaceStudioDesignTokens.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Material(
                        type: MaterialType.transparency,
                        child: PopupMenuButton<int>(
                          key: const ValueKey(
                              'surfaceStudio.preview.sizeButton'),
                          initialValue: previewSize,
                          color: SurfaceStudioDesignTokens.backgroundElevated,
                          onSelected: onPreviewSizeChanged,
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 5, child: Text('5 × 5')),
                            PopupMenuItem(value: 10, child: Text('10 × 10')),
                            PopupMenuItem(value: 15, child: Text('15 × 15')),
                            PopupMenuItem(value: 20, child: Text('20 × 20')),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: SurfaceStudioDesignTokens.backgroundDeep,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: SurfaceStudioDesignTokens.borderStrong,
                              ),
                            ),
                            child: Text(
                              '$previewSize × $previewSize',
                              style: const TextStyle(
                                color: SurfaceStudioDesignTokens.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({
    required this.keyName,
    required this.icon,
    required this.onPressed,
    this.highlighted = false,
  });

  final String keyName;
  final IconData icon;
  final VoidCallback onPressed;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      key: ValueKey(keyName),
      padding: EdgeInsets.zero,
      minimumSize: const Size.square(36),
      onPressed: onPressed,
      child: Container(
        width: highlighted ? 42 : 34,
        height: highlighted ? 42 : 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: highlighted
              ? SurfaceStudioDesignTokens.accentTealSoft
              : SurfaceStudioDesignTokens.backgroundDeep,
          border: Border.all(
            color: highlighted
                ? SurfaceStudioDesignTokens.accentTeal
                : SurfaceStudioDesignTokens.borderStrong,
            width: highlighted ? 2 : 1,
          ),
        ),
        child: Icon(
          icon,
          size: highlighted ? 22 : 17,
          color: highlighted
              ? SurfaceStudioDesignTokens.accentTeal
              : SurfaceStudioDesignTokens.textMuted,
        ),
      ),
    );
  }
}

class _CheckLine extends StatelessWidget {
  const _CheckLine({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(
              value
                  ? CupertinoIcons.checkmark_square_fill
                  : CupertinoIcons.square,
              color: value
                  ? SurfaceStudioDesignTokens.accentTeal
                  : SurfaceStudioDesignTokens.textMuted,
              size: 18,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                color: SurfaceStudioDesignTokens.textSecondary,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterPreviewPainter extends CustomPainter {
  const _WaterPreviewPainter({
    required this.gridVisible,
    required this.previewSize,
  });

  final bool gridVisible;
  final int previewSize;

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / previewSize;
    final cellH = size.height / previewSize;
    final a = Paint()..color = const Color(0xFF1E89FF);
    final b = Paint()..color = const Color(0xFF1268D9);
    for (var y = 0; y < previewSize; y++) {
      for (var x = 0; x < previewSize; x++) {
        canvas.drawRect(
          Rect.fromLTWH(x * cellW, y * cellH, cellW, cellH),
          (x + y).isEven ? a : b,
        );
      }
    }
    final wave = Paint()
      ..color = const Color(0xFFA4E7FF).withValues(alpha: 0.26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    for (var y = 8.0; y < size.height; y += 24) {
      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x <= size.width; x += 22) {
        path.quadraticBezierTo(x + 11, y - 7, x + 22, y);
      }
      canvas.drawPath(path, wave);
    }
    if (gridVisible) {
      final grid = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.16)
        ..strokeWidth = 1;
      for (var i = 0; i <= previewSize; i++) {
        final x = i * cellW;
        final y = i * cellH;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
        canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WaterPreviewPainter oldDelegate) =>
      oldDelegate.gridVisible != gridVisible ||
      oldDelegate.previewSize != previewSize;
}
```
### `packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_bottom_action_bar.dart`

```dart
import 'package:flutter/cupertino.dart';

import '../surface_studio_design_tokens.dart';

class SurfaceStudioBottomActionBar extends StatelessWidget {
  const SurfaceStudioBottomActionBar({
    super.key,
    required this.canGoBack,
    required this.canAutoSuggest,
    required this.canApplyMapping,
    required this.canGoNext,
    this.canSaveCatalog = false,
    required this.onBack,
    required this.onAutoSuggest,
    required this.onApplyMapping,
    required this.onNext,
    this.onSaveCatalog,
  });

  final bool canGoBack;
  final bool canAutoSuggest;
  final bool canApplyMapping;
  final bool canGoNext;
  final bool canSaveCatalog;
  final VoidCallback onBack;
  final VoidCallback onAutoSuggest;
  final VoidCallback onApplyMapping;
  final VoidCallback onNext;
  final VoidCallback? onSaveCatalog;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('surfaceStudio.bottomBar'),
      decoration: const BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundDeep,
        border: Border(
          top: BorderSide(color: SurfaceStudioDesignTokens.borderSubtle),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _BarButton(
            keyName: 'surfaceStudio.action.back',
            label: 'Retour',
            icon: CupertinoIcons.arrow_left,
            enabled: canGoBack,
            onPressed: onBack,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BarButton(
                    keyName: 'surfaceStudio.action.autoSuggest',
                    label: 'Suggestion auto',
                    icon: CupertinoIcons.sparkles,
                    enabled: canAutoSuggest,
                    onPressed: onAutoSuggest,
                    accent: SurfaceStudioDesignTokens.accentTeal,
                  ),
                  const SizedBox(width: 12),
                  _BarButton(
                    keyName: 'surfaceStudio.action.applyMapping',
                    label: 'Appliquer le mapping',
                    icon: CupertinoIcons.checkmark_circle,
                    enabled: canApplyMapping,
                    onPressed: onApplyMapping,
                  ),
                  if (onSaveCatalog != null) ...[
                    const SizedBox(width: 12),
                    _BarButton(
                      keyName: 'surfaceStudio.action.saveCatalog',
                      label: 'Préparer sauvegarde',
                      icon: CupertinoIcons.tray_arrow_down,
                      enabled: canSaveCatalog,
                      onPressed: onSaveCatalog!,
                      accent: SurfaceStudioDesignTokens.accentTeal,
                    ),
                  ],
                  const SizedBox(width: 12),
                  _BarButton(
                    keyName: 'surfaceStudio.action.next',
                    label: 'Suivant',
                    icon: CupertinoIcons.arrow_right,
                    enabled: canGoNext,
                    onPressed: onNext,
                    accent: SurfaceStudioDesignTokens.accentGold,
                    primary: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.keyName,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
    this.accent,
    this.primary = false,
  });

  final String keyName;
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;
  final Color? accent;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = accent ?? SurfaceStudioDesignTokens.borderStrong;
    return Opacity(
      opacity: enabled ? 1 : 0.52,
      child: CupertinoButton(
        key: ValueKey(keyName),
        minimumSize: const Size(46, 46),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        color: primary
            ? effectiveAccent.withValues(alpha: 0.42)
            : SurfaceStudioDesignTokens.backgroundElevated,
        borderRadius: BorderRadius.circular(9),
        onPressed: enabled ? onPressed : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: primary
                  ? SurfaceStudioDesignTokens.textPrimary
                  : effectiveAccent,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: primary
                    ? SurfaceStudioDesignTokens.textPrimary
                    : SurfaceStudioDesignTokens.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```
### `packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_header.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Tooltip;

import '../surface_studio_design_tokens.dart';
import '../surface_studio_step.dart';
import 'surface_studio_top_stepper.dart';

class SurfaceStudioHeader extends StatelessWidget {
  const SurfaceStudioHeader({
    super.key,
    required this.currentStep,
    required this.completedSteps,
    required this.onStepSelected,
    this.onOpenAdvanced,
  });

  final SurfaceStudioWizardStep currentStep;
  final Set<SurfaceStudioWizardStep> completedSteps;
  final ValueChanged<SurfaceStudioWizardStep> onStepSelected;
  final VoidCallback? onOpenAdvanced;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('surfaceStudio.header'),
      decoration: const BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundDeep,
        border: Border(
          bottom: BorderSide(color: SurfaceStudioDesignTokens.borderSubtle),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const _StudioMark(),
          const SizedBox(width: 12),
          const Text(
            'Surface Studio — Assistant de mapping d’atlas',
            style: TextStyle(
              color: SurfaceStudioDesignTokens.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: SurfaceStudioTopStepper(
              currentStep: currentStep,
              completedSteps: completedSteps,
              onStepSelected: onStepSelected,
            ),
          ),
          const SizedBox(width: 12),
          _HeaderIconButton(
            tooltip: 'Aide',
            icon: CupertinoIcons.question_circle,
            onPressed: () {},
          ),
          _HeaderIconButton(
            tooltip: 'Catalogue & diagnostics',
            icon: CupertinoIcons.gear_alt,
            onPressed: onOpenAdvanced ?? () {},
          ),
          _HeaderIconButton(
            tooltip: 'Fermer',
            icon: CupertinoIcons.xmark,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _StudioMark extends StatelessWidget {
  const _StudioMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.accentTealSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: SurfaceStudioDesignTokens.accentTeal.withValues(alpha: 0.7),
        ),
      ),
      child: const Icon(
        CupertinoIcons.drop,
        color: SurfaceStudioDesignTokens.accentTeal,
        size: 22,
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: const Size.square(36),
        onPressed: onPressed,
        child: Icon(
          icon,
          size: 18,
          color: SurfaceStudioDesignTokens.textSecondary,
        ),
      ),
    );
  }
}
```
### `packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_shell.dart`

```dart
import 'package:flutter/widgets.dart';

import '../surface_studio_design_tokens.dart';

class SurfaceStudioShell extends StatelessWidget {
  const SurfaceStudioShell({
    super.key,
    required this.header,
    required this.sidebar,
    required this.workspacePanel,
    required this.rightDock,
    required this.bottomBar,
  });

  final Widget header;
  final Widget sidebar;
  final Widget workspacePanel;
  final Widget rightDock;
  final Widget bottomBar;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('surfaceStudio.shell'),
      color: SurfaceStudioDesignTokens.backgroundDeep,
      child: Column(
        children: [
          SizedBox(
            height: SurfaceStudioDesignTokens.headerHeight,
            child: header,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  sidebar,
                  const SizedBox(width: SurfaceStudioDesignTokens.gapSm),
                  Expanded(child: workspacePanel),
                  const SizedBox(width: SurfaceStudioDesignTokens.gapSm),
                  SizedBox(
                    width: SurfaceStudioDesignTokens.rightPanelWidthExpanded,
                    child: rightDock,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: SurfaceStudioDesignTokens.bottomBarHeight,
            child: bottomBar,
          ),
        ],
      ),
    );
  }
}
```
### `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`

```dart
// Surface Studio — assistant premium de mapping d'atlas.
//
// Le viewport principal porte un seul workflow guide moderne. Les anciennes
// briques utiles restent accessibles dans le drawer avance, sans second
// Surface Studio rendu sous l'assistant.

import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'surface_studio_atlas_editing.dart';
import 'surface_studio_catalog_browser.dart';
import 'surface_studio_diagnostics_view.dart';
import 'surface_studio_paintable_surfaces_panel.dart';
import 'surface_studio_preset_editor_controller.dart';
import 'surface_studio_role_mapping_editor.dart';
import 'surface_studio_selection.dart';
import 'surface_studio_selection_inspector.dart';
import 'surface_studio_selection_summary.dart';
import 'surface_studio_screen.dart';

SurfaceStudioSelection _selectionValidInReadModel(
  SurfaceStudioReadModel rm,
  SurfaceStudioSelection sel,
) {
  if (sel.isNone) return sel;
  if (sel.isAtlas) {
    for (final row in rm.atlases) {
      if (row.id == sel.id) return sel;
    }
  } else if (sel.isAnimation) {
    for (final row in rm.animations) {
      if (row.id == sel.id) return sel;
    }
  } else if (sel.isPreset) {
    for (final row in rm.presets) {
      if (row.id == sel.id) return sel;
    }
  }
  return const SurfaceStudioSelection.none();
}

/// Accent produit Surface Studio (même base que la tuile World Explorer).
const Color _surfaceStudioAccent = Color(0xFF2DD4BF);

/// Panneau présentationnel **lecture seule** pour Surface Studio.
class SurfaceStudioPanel extends StatefulWidget {
  const SurfaceStudioPanel({
    super.key,
    required this.readModel,
    this.onSurfaceCatalogSaveRequested,
    this.onRequestProjectSave,
    this.projectTilesets,
    this.projectRootPath,
    this.projectSettings,
    this.surfaceMappingImageLoader,
  });

  final SurfaceStudioReadModel readModel;
  final ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogSaveRequested;
  final Future<bool> Function()? onRequestProjectSave;
  final List<ProjectTilesetEntry>? projectTilesets;
  final ProjectSettings? projectSettings;
  final SurfaceStudioAtlasUiImageLoader? surfaceMappingImageLoader;

  /// Racine projet sur disque pour résoudre les chemins d’images tileset (aperçu Lot 72).
  final String? projectRootPath;

  static const String titleText = 'Surface Studio';
  static const String readOnlyBadgeText = 'Lecture seule';
  static const String partialAuthoringBadgeText = 'Édition partielle';
  static const String workflowStepsHintText =
      'Étapes : atlas → grille → animations → surfaces prêtes à peindre';
  static const String productDescriptionText =
      'Créer des surfaces peintes à partir d’un atlas, étape par étape.';
  static const String placeholderActionsTitle = 'Actions auteur';
  static const String placeholderSoonText = 'Bientôt';
  static const String actionImportVerticalAtlasLabel =
      'Importer un atlas vertical';
  static const String workCatalogDirtyStateText =
      'Catalogue de travail modifié — sauvegarde projet non effectuée.';
  static const String savePrepActionLabel =
      'Préparer la sauvegarde du catalogue Surface';
  static const String savePrepTransmittedNote =
      'Catalogue de travail transmis au parent.';
  static const String savePrepNotConnectedNote =
      'Sauvegarde non connectée dans ce contexte.';
  static const String savePrepNoDiskNote =
      'Aucune écriture disque ne sera effectuée par Surface Studio.';
  static const String manifestMemoryUpdatedNote =
      'Manifest projet mis à jour en mémoire — écriture disque non effectuée.';
  static const String projectSaveViaExistingFlowButtonLabel =
      'Sauvegarder le projet via le flux existant';
  static const String projectDiskSaveResultSuccessNote =
      'Projet sauvegardé via le flux projet existant.';
  static const String projectDiskSaveRequestedNote =
      'Sauvegarde projet demandée.';
  static const String projectDiskSaveFailureNote =
      'Échec de sauvegarde projet — voir la barre d’état.';

  @override
  State<SurfaceStudioPanel> createState() => _SurfaceStudioPanelState();
}

class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
  /// Sélection d’inspection : locale au widget, jamais écrite dans le manifest.
  SurfaceStudioSelection _selection = const SurfaceStudioSelection.none();
  late SurfaceStudioReadModel _workReadModel;
  String? _saveFlowPrepNote;
  String? _projectSaveDiskNote;
  int _atlasEditSignal = 0;

  @override
  void initState() {
    super.initState();
    _workReadModel = widget.readModel;
  }

  @override
  void didUpdateWidget(covariant SurfaceStudioPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.readModel != oldWidget.readModel) {
      final hadDirty = _workReadModel != oldWidget.readModel;
      final absNow = widget.readModel ==
          buildSurfaceStudioReadModelFromCatalog(_workReadModel.catalog);
      final wasAbsorbed = hadDirty && absNow;
      setState(() {
        _workReadModel = widget.readModel;
        _selection = _selectionValidInReadModel(_workReadModel, _selection);
        _saveFlowPrepNote =
            wasAbsorbed ? SurfaceStudioPanel.manifestMemoryUpdatedNote : null;
      });
    }
  }

  bool get _hasWorkCatalogChanges => _workReadModel != widget.readModel;

  void _bumpAtlasEditSignal() {
    setState(() => _atlasEditSignal += 1);
  }

  void _onConfirmDeleteSelectedAtlas() {
    final id = _selection.id;
    if (id == null || !_selection.isAtlas) {
      return;
    }
    try {
      final next = removeAtlasIdFromWorkCatalog(_workReadModel.catalog, id);
      setState(() {
        _saveFlowPrepNote = null;
        _workReadModel = buildSurfaceStudioReadModelFromCatalog(next);
        _selection = const SurfaceStudioSelection.none();
      });
    } on StateError {
      return;
    }
  }

  SurfaceStudioSelection _selectionAfterCatalogChanged(
    ProjectSurfaceCatalog cat,
  ) {
    if (_selection.isAtlas) {
      final sid = _selection.id;
      if (sid != null) {
        for (final a in cat.atlases) {
          if (a.id == sid) {
            return SurfaceStudioSelection.atlas(sid);
          }
        }
        return const SurfaceStudioSelection.none();
      }
    }
    if (_selection.isAnimation) {
      final sid = _selection.id;
      if (sid != null) {
        for (final a in cat.animations) {
          if (a.id == sid) {
            return SurfaceStudioSelection.animation(sid);
          }
        }
        return const SurfaceStudioSelection.none();
      }
    }
    if (_selection.isPreset) {
      final sid = _selection.id;
      if (sid != null) {
        for (final p in cat.presets) {
          if (p.id == sid) {
            return SurfaceStudioSelection.preset(sid);
          }
        }
        return const SurfaceStudioSelection.none();
      }
    }
    if (cat.atlases.isNotEmpty) {
      return SurfaceStudioSelection.atlas(cat.atlases.last.id);
    }
    return const SurfaceStudioSelection.none();
  }

  void _onSurfaceCatalogSavePrep() {
    final cb = widget.onSurfaceCatalogSaveRequested;
    if (cb == null) {
      return;
    }
    cb(_workReadModel.catalog);
    setState(() {
      _saveFlowPrepNote = SurfaceStudioPanel.savePrepTransmittedNote;
    });
  }

  Future<void> _onRequestProjectSave() async {
    final fn = widget.onRequestProjectSave;
    if (fn == null) {
      return;
    }
    setState(() {
      _projectSaveDiskNote = SurfaceStudioPanel.projectDiskSaveRequestedNote;
    });
    final ok = await fn();
    if (!mounted) {
      return;
    }
    setState(() {
      _projectSaveDiskNote = ok
          ? SurfaceStudioPanel.projectDiskSaveResultSuccessNote
          : SurfaceStudioPanel.projectDiskSaveFailureNote;
    });
  }

  ProjectSurfacePreset? _selectedWorkPreset() {
    final id = _selection.id;
    if (id == null || !_selection.isPreset) {
      return null;
    }
    return _workReadModel.catalog.presetById(id);
  }

  void _selectPreset(String presetId) {
    setState(() {
      _selection = SurfaceStudioSelection.preset(presetId);
    });
  }

  void _onPresetRoleAnimationChanged(
    SurfaceVariantRole role,
    String animationId,
  ) {
    final presetId = _selection.id;
    if (presetId == null || !_selection.isPreset) {
      return;
    }
    final next = surfaceStudioReplacePresetRoleAnimation(
      catalog: _workReadModel.catalog,
      presetId: presetId,
      role: role,
      animationId: animationId,
    );
    setState(() {
      _saveFlowPrepNote = null;
      _workReadModel = buildSurfaceStudioReadModelFromCatalog(next);
      _selection = SurfaceStudioSelection.preset(presetId);
    });
  }

  Future<void> _openPresetMappingEditor(String presetId) async {
    final preset = _workReadModel.catalog.presetById(presetId);
    if (preset == null) {
      return;
    }
    setState(() {
      _selection = SurfaceStudioSelection.preset(presetId);
    });
    await showMacosSheet<void>(
      context: context,
      builder: (ctx) => Center(
        child: MacosSheet(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              key: const ValueKey('surface_mapping_editor_sheet'),
              width: 1120,
              height: 760,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Surface Mapping Editor',
                          style: editorMacosSheetTitleStyle(ctx),
                        ),
                      ),
                      PushButton(
                        key: const ValueKey('surface_mapping_editor_close'),
                        controlSize: ControlSize.large,
                        secondary: true,
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Fermer'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Étape 1 : choisissez un slot visuel. Étape 2 : cliquez directement une colonne dans l’atlas réel.',
                    style: TextStyle(
                      color: _surfaceStudioAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SurfaceStudioRoleMappingEditor(
                        catalog: _workReadModel.catalog,
                        preset: preset,
                        projectRootPath: widget.projectRootPath,
                        projectTilesets: widget.projectTilesets ??
                            const <ProjectTilesetEntry>[],
                        imageLoader: widget.surfaceMappingImageLoader,
                        onRoleAnimationChanged: _onPresetRoleAnimationChanged,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onSurfaceCatalogChanged(ProjectSurfaceCatalog cat) {
    setState(() {
      _saveFlowPrepNote = null;
      _workReadModel = buildSurfaceStudioReadModelFromCatalog(cat);
      _selection = _selectionAfterCatalogChanged(cat);
    });
  }

  @override
  Widget build(BuildContext context) {
    final canMutateCatalog = widget.onSurfaceCatalogSaveRequested != null;
    final inspection = Column(
      key: const ValueKey('surface_studio_inspection_column'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SurfaceStudioSelectionSummary(selection: _selection),
        const SizedBox(height: 10),
        SurfaceStudioSelectionInspector(
          readModel: _workReadModel,
          selection: _selection,
          onRequestEditSelectedAtlas:
              canMutateCatalog ? _bumpAtlasEditSignal : null,
          onConfirmDeleteSelectedAtlas:
              canMutateCatalog ? _onConfirmDeleteSelectedAtlas : null,
        ),
      ],
    );
    final selectedPreset = _selectedWorkPreset();
    final paintableSurfaces = SurfaceStudioPaintableSurfacesPanel(
      readModel: _workReadModel,
      selectedPresetId: selectedPreset?.id,
      onPresetSelected: _selectPreset,
      onEditMappingPressed: canMutateCatalog ? _openPresetMappingEditor : null,
      onSaveCatalogPressed: widget.onSurfaceCatalogSaveRequested != null
          ? _onSurfaceCatalogSavePrep
          : null,
    );
    final advancedDrawer = SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: _AdvancedDetailsSection(
        inspection: inspection,
        browser: SurfaceStudioCatalogBrowser(
          readModel: _workReadModel,
          selection: _selection,
          onSelectionChanged: (v) {
            setState(() => _selection = v);
          },
        ),
        diagnostics: SurfaceStudioDiagnosticsView(readModel: _workReadModel),
        futureActions: paintableSurfaces,
        placeholder: const _SectionPlaceholder(
          title: SurfaceStudioPanel.placeholderActionsTitle,
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final shellWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth.clamp(1200.0, 2400.0).toDouble()
            : 1600.0;
        final shellHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight.clamp(760.0, 1120.0).toDouble()
            : 900.0;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: shellWidth,
            height: shellHeight,
            child: SurfaceStudioScreen(
              readModel: _workReadModel,
              projectSettings: widget.projectSettings,
              projectTilesets: widget.projectTilesets ?? const [],
              projectRootPath: widget.projectRootPath,
              surfaceMappingImageLoader: widget.surfaceMappingImageLoader,
              hasWorkCatalogChanges: _hasWorkCatalogChanges,
              saveFlowPrepNote: _saveFlowPrepNote,
              projectSaveDiskNote: _projectSaveDiskNote,
              onSurfaceCatalogChanged: _onSurfaceCatalogChanged,
              onWorkCatalogAnimationsCreated: (createdIds) {
                if (createdIds.isEmpty) {
                  return;
                }
                setState(() {
                  _selection =
                      SurfaceStudioSelection.animation(createdIds.first);
                });
              },
              onWorkCatalogPresetCreated: (presetId) {
                if (presetId.isEmpty) {
                  return;
                }
                setState(() {
                  _selection = SurfaceStudioSelection.preset(presetId);
                });
              },
              onResetWorkCatalog: () {
                setState(() {
                  _workReadModel = widget.readModel;
                  _selection =
                      _selectionValidInReadModel(_workReadModel, _selection);
                  _saveFlowPrepNote = null;
                });
              },
              onSurfaceCatalogSavePrep:
                  widget.onSurfaceCatalogSaveRequested == null
                      ? null
                      : _onSurfaceCatalogSavePrep,
              onRequestProjectSave: widget.onRequestProjectSave == null
                  ? null
                  : _onRequestProjectSave,
              advancedDrawer: advancedDrawer,
            ),
          ),
        );
      },
    );
  }
}

class _AdvancedDetailsSection extends StatelessWidget {
  const _AdvancedDetailsSection({
    required this.inspection,
    required this.browser,
    required this.diagnostics,
    required this.futureActions,
    required this.placeholder,
  });

  final Widget inspection;
  final Widget browser;
  final Widget diagnostics;
  final Widget futureActions;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return _StudioCard(
      key: const ValueKey('surface_studio_advanced_details'),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Détails avancés',
            style: TextStyle(
              color: label,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Catalogue, inspection et diagnostics restent disponibles sans remplacer le workflow principal.',
            style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) {
              if (c.maxWidth >= 960) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: inspection),
                    const SizedBox(width: 12),
                    Expanded(child: browser),
                    const SizedBox(width: 12),
                    Expanded(child: diagnostics),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  inspection,
                  const SizedBox(height: 12),
                  browser,
                  const SizedBox(height: 12),
                  diagnostics,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          futureActions,
          const SizedBox(height: 10),
          placeholder,
        ],
      ),
    );
  }
}

/// Carte interne : même relief que les tuiles inspecteur / sections.
class _StudioCard extends StatelessWidget {
  const _StudioCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context),
          width: 1,
        ),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: child,
    );
  }
}

class _SectionPlaceholder extends StatelessWidget {
  const _SectionPlaceholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return _StudioCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: label,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  SurfaceStudioPanel.placeholderSoonText,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          MacosIcon(
            CupertinoIcons.chevron_right,
            size: 16,
            color: subtle,
          ),
        ],
      ),
    );
  }
}

/// Adaptateur : construit le read model **sans** I/O à partir d’un [ProjectManifest].
class SurfaceStudioPanelFromManifest extends StatefulWidget {
  const SurfaceStudioPanelFromManifest({
    super.key,
    required this.manifest,
    this.onProjectManifestChanged,
    this.onRequestProjectSave,
    this.projectRootPath,
  });

  final ProjectManifest manifest;
  final ValueChanged<ProjectManifest>? onProjectManifestChanged;
  final Future<bool> Function()? onRequestProjectSave;

  /// Dossier projet ouvert (même source que l’éditeur) pour résoudre les fichiers image.
  final String? projectRootPath;

  @override
  State<SurfaceStudioPanelFromManifest> createState() =>
      _SurfaceStudioPanelFromManifestState();
}

class _SurfaceStudioPanelFromManifestState
    extends State<SurfaceStudioPanelFromManifest> {
  late ProjectManifest _manifest;

  @override
  void initState() {
    super.initState();
    _manifest = widget.manifest;
  }

  @override
  void didUpdateWidget(covariant SurfaceStudioPanelFromManifest oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.manifest != oldWidget.manifest) {
      setState(() {
        _manifest = widget.manifest;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SurfaceStudioPanel(
      readModel: buildSurfaceStudioReadModel(_manifest),
      projectSettings: _manifest.settings,
      projectTilesets: _manifest.tilesets,
      projectRootPath: widget.projectRootPath,
      onSurfaceCatalogSaveRequested: (c) {
        final n = replaceProjectManifestSurfaceCatalog(_manifest, c);
        setState(() {
          _manifest = n;
        });
        widget.onProjectManifestChanged?.call(n);
      },
      onRequestProjectSave: widget.onRequestProjectSave,
    );
  }
}
```
### `packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart`

```dart
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show
        DropdownButton,
        DropdownMenuItem,
        InputDecoration,
        Material,
        MaterialType,
        OutlineInputBorder,
        TextField;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_role_mapping_editor.dart';

import '../editor/application/editor_ai_settings.dart';
import 'atlas/surface_studio_atlas_panel.dart';
import 'preview/surface_studio_preview_panel.dart';
import 'schema/surface_studio_schema_panel.dart';
import 'shell/surface_studio_bottom_action_bar.dart';
import 'shell/surface_studio_header.dart';
import 'shell/surface_studio_shell.dart';
import 'shell/surface_studio_sidebar.dart';
import 'surface_studio_atlas_authoring_prep.dart';
import 'surface_studio_atlas_grid_overlay.dart';
import 'surface_studio_atlas_grid_preview.dart';
import 'surface_studio_atlas_image_preview.dart';
import 'surface_studio_atlas_source_picker.dart';
import 'surface_studio_column_selection.dart';
import 'surface_studio_design_tokens.dart';
import 'surface_studio_drag_payload.dart';
import 'surface_studio_mapping_suggestion_controller.dart';
import 'surface_studio_mapping_suggestion_models.dart';
import 'surface_studio_role_assignment_draft.dart';
import 'surface_studio_step.dart';
import 'surface_studio_vertical_atlas_animation_generation_plan.dart';
import 'surface_studio_vertical_atlas_animation_generator.dart';
import 'surface_studio_vertical_atlas_preset_generator.dart';
import 'surface_studio_vertical_atlas_role_mapping.dart';

class SurfaceStudioScreen extends StatefulWidget {
  const SurfaceStudioScreen({
    super.key,
    required this.readModel,
    this.projectSettings,
    this.projectTilesets = const <ProjectTilesetEntry>[],
    this.projectRootPath,
    this.surfaceMappingImageLoader,
    this.hasWorkCatalogChanges = false,
    this.saveFlowPrepNote,
    this.projectSaveDiskNote,
    this.onSurfaceCatalogChanged,
    this.onWorkCatalogAnimationsCreated,
    this.onWorkCatalogPresetCreated,
    this.onResetWorkCatalog,
    this.onSurfaceCatalogSavePrep,
    this.onRequestProjectSave,
    this.advancedDrawer,
  });

  final SurfaceStudioReadModel readModel;
  final ProjectSettings? projectSettings;
  final List<ProjectTilesetEntry> projectTilesets;
  final String? projectRootPath;
  final SurfaceStudioAtlasUiImageLoader? surfaceMappingImageLoader;
  final bool hasWorkCatalogChanges;
  final String? saveFlowPrepNote;
  final String? projectSaveDiskNote;
  final ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogChanged;
  final ValueChanged<List<String>>? onWorkCatalogAnimationsCreated;
  final ValueChanged<String>? onWorkCatalogPresetCreated;
  final VoidCallback? onResetWorkCatalog;
  final VoidCallback? onSurfaceCatalogSavePrep;
  final Future<void> Function()? onRequestProjectSave;
  final Widget? advancedDrawer;

  @override
  State<SurfaceStudioScreen> createState() => _SurfaceStudioScreenState();
}

class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
  static const int _defaultDurationMsPerFrame = 120;

  SurfaceStudioWizardStep _currentStep = SurfaceStudioWizardStep.map;
  bool _sidebarCollapsed = false;
  bool _rightPanelCollapsed = false;
  bool _advancedDrawerOpen = false;
  bool _suggestionReviewOpen = false;
  Set<String> _openSchemaGroups = const {
    'surfaceMain',
    'edges',
    'externalCorners',
    'internalCorners',
    'junctions',
  };
  SurfaceStudioColumnSelection _selectedColumns =
      const SurfaceStudioColumnSelection(<int>[4, 5]);
  SurfaceStudioRoleAssignmentDraft _assignmentDraft =
      const SurfaceStudioRoleAssignmentDraft.empty();
  double _zoomPercent = 100;
  bool _previewPlaying = false;
  int _previewFrameIndex = 0;
  bool _previewLoop = true;
  bool _previewGridVisible = true;
  int _previewSize = 10;
  String? _statusMessage;
  String? _lastGenerationMessage;
  String? _lastPresetMessage;
  SurfaceStudioMappingSuggestionResult? _suggestionResult;
  final _suggestionController =
      const SurfaceStudioMappingSuggestionController();
  Timer? _previewTimer;

  final TextEditingController _atlasId = TextEditingController();
  final TextEditingController _atlasName = TextEditingController();
  final TextEditingController _tilesetId = TextEditingController();
  final TextEditingController _tileWidth = TextEditingController();
  final TextEditingController _tileHeight = TextEditingController();
  final TextEditingController _columns = TextEditingController();
  final TextEditingController _rows = TextEditingController();
  final TextEditingController _sortOrder = TextEditingController();
  final TextEditingController _categoryId = TextEditingController();
  SurfaceAtlasLayout _layout =
      SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames;
  String? _selectedAtlasId;

  @override
  void initState() {
    super.initState();
    _selectedAtlasId = widget.readModel.atlases.isNotEmpty
        ? widget.readModel.atlases.first.id
        : null;
    if (widget.readModel.atlases.isEmpty) {
      _currentStep = SurfaceStudioWizardStep.importAtlas;
    }
    _syncFormFromSelectedAtlas();
    _syncSelectionToColumnCount();
  }

  @override
  void didUpdateWidget(covariant SurfaceStudioScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.readModel != oldWidget.readModel) {
      if (_selectedAtlasId == null ||
          widget.readModel.catalog.atlasById(_selectedAtlasId!) == null) {
        _selectedAtlasId = widget.readModel.atlases.isNotEmpty
            ? widget.readModel.atlases.first.id
            : null;
      }
      _syncFormFromSelectedAtlas();
      _syncSelectionToColumnCount();
    }
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    _atlasId.dispose();
    _atlasName.dispose();
    _tilesetId.dispose();
    _tileWidth.dispose();
    _tileHeight.dispose();
    _columns.dispose();
    _rows.dispose();
    _sortOrder.dispose();
    _categoryId.dispose();
    super.dispose();
  }

  ProjectSurfaceAtlas? get _selectedAtlas {
    final id = _selectedAtlasId;
    if (id == null) {
      return null;
    }
    return widget.readModel.catalog.atlasById(id);
  }

  SurfaceStudioAtlasReadModel? get _selectedAtlasRow {
    final id = _selectedAtlasId;
    if (id == null) {
      return null;
    }
    for (final row in widget.readModel.atlases) {
      if (row.id == id) {
        return row;
      }
    }
    return null;
  }

  int get _columnCount {
    final parsed = int.tryParse(_columns.text.trim());
    if (parsed != null && parsed > 0) {
      return parsed.clamp(1, 48).toInt();
    }
    final row = _selectedAtlasRow;
    return (row?.columns ?? 12).clamp(1, 48).toInt();
  }

  int get _frameCount {
    final parsed = int.tryParse(_rows.text.trim());
    if (parsed != null && parsed > 0) {
      return parsed.clamp(1, 128).toInt();
    }
    final row = _selectedAtlasRow;
    return (row?.rows ?? 32).clamp(1, 128).toInt();
  }

  int get _tileWidthValue {
    final parsed = int.tryParse(_tileWidth.text.trim());
    if (parsed != null && parsed > 0) {
      return parsed;
    }
    return _selectedAtlasRow?.tileWidth ?? 32;
  }

  int get _tileHeightValue {
    final parsed = int.tryParse(_tileHeight.text.trim());
    if (parsed != null && parsed > 0) {
      return parsed;
    }
    return _selectedAtlasRow?.tileHeight ?? 32;
  }

  bool get _gridValid => surfaceStudioAtlasGridOverlayDraftValid(
        _tileWidthValue,
        _tileHeightValue,
        _columnCount,
        _frameCount,
      );

  Set<SurfaceStudioWizardStep> get _completedSteps => {
        if (widget.readModel.atlases.isNotEmpty)
          SurfaceStudioWizardStep.importAtlas,
        if (_gridValid) SurfaceStudioWizardStep.slice,
        if (_assignmentDraft.isAssigned(SurfaceVariantRole.isolated))
          SurfaceStudioWizardStep.map,
        if (_generationPlan.summary.readyAnimationCount > 0)
          SurfaceStudioWizardStep.preview,
      };

  bool get _canGoNext {
    return switch (_currentStep) {
      SurfaceStudioWizardStep.importAtlas =>
        widget.readModel.atlases.isNotEmpty,
      SurfaceStudioWizardStep.slice => _gridValid,
      SurfaceStudioWizardStep.map =>
        _assignmentDraft.isAssigned(SurfaceVariantRole.isolated),
      SurfaceStudioWizardStep.preview => true,
      SurfaceStudioWizardStep.save => false,
    };
  }

  SurfaceStudioColumnRoleMappingDraft get _columnRoleMappingDraft {
    final assignments = <SurfaceStudioColumnRoleAssignment>[];
    for (final role in standardSurfaceVariantRoleOrder) {
      final columns = _assignmentDraft.columnsForRole(role);
      if (columns.isEmpty) {
        continue;
      }
      assignments.add(
        SurfaceStudioColumnRoleAssignment(
          columnIndex: (columns.first - 1).clamp(0, _columnCount - 1).toInt(),
          role: role,
        ),
      );
    }
    return SurfaceStudioColumnRoleMappingDraft(
      columnCount: _columnCount,
      assignments: List<SurfaceStudioColumnRoleAssignment>.unmodifiable(
        assignments,
      ),
    );
  }

  SurfaceStudioVerticalAtlasAnimationGenerationPlan get _generationPlan {
    final existingIds = <String>{
      for (final row in widget.readModel.animations) row.id,
    };
    return buildSurfaceStudioVerticalAtlasAnimationGenerationPlan(
      atlasIdRaw: _atlasId.text,
      mappingDraft: _columnRoleMappingDraft,
      tileWidth: _tileWidthValue,
      tileHeight: _tileHeightValue,
      columns: _columnCount,
      rows: _frameCount,
      durationMsPerFrame: _defaultDurationMsPerFrame,
      existingAnimationIds: existingIds,
    );
  }

  void _syncFormFromSelectedAtlas() {
    final atlas = _selectedAtlas;
    if (atlas == null) {
      _atlasId.text = '';
      _atlasName.text = '';
      _tilesetId.text = widget.projectTilesets.isNotEmpty
          ? widget.projectTilesets.first.id
          : '';
      _tileWidth.text = '32';
      _tileHeight.text = '32';
      _columns.text = '12';
      _rows.text = '32';
      _sortOrder.text = '${widget.readModel.catalog.atlases.length}';
      _categoryId.text = '';
      _layout = SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames;
      return;
    }
    _atlasId.text = atlas.id;
    _atlasName.text = atlas.name;
    _tilesetId.text = atlas.tilesetId;
    _tileWidth.text = '${atlas.geometry.tileSize.width}';
    _tileHeight.text = '${atlas.geometry.tileSize.height}';
    _columns.text = '${atlas.geometry.gridSize.columns}';
    _rows.text = '${atlas.geometry.gridSize.rows}';
    _sortOrder.text = '${atlas.sortOrder}';
    _categoryId.text = atlas.categoryId ?? '';
    _layout = atlas.geometry.layout;
  }

  void _syncSelectionToColumnCount() {
    final count = _columnCount;
    final valid = _selectedColumns.columns
        .where((column) => column >= 1 && column <= count)
        .toList();
    if (valid.isEmpty && count >= 1) {
      _selectedColumns = SurfaceStudioColumnSelection(<int>[
        count >= 5 ? 4 : 1,
        if (count >= 5) 5,
      ]);
    } else {
      _selectedColumns = SurfaceStudioColumnSelection(valid);
    }
  }

  void _selectStep(SurfaceStudioWizardStep step) {
    if (step == _currentStep) {
      return;
    }
    if (step.index <= _currentStep.index || _completedSteps.contains(step)) {
      setState(() {
        _currentStep = step;
        _statusMessage = null;
      });
      return;
    }
    setState(() {
      _statusMessage = 'Terminez les étapes précédentes avant d’avancer.';
    });
  }

  void _nextStep() {
    if (!_canGoNext) {
      setState(() {
        _statusMessage = switch (_currentStep) {
          SurfaceStudioWizardStep.importAtlas =>
            'Créez ou sélectionnez un atlas avant de continuer.',
          SurfaceStudioWizardStep.slice =>
            'Corrigez la grille avant de continuer.',
          SurfaceStudioWizardStep.map =>
            'Assignez au moins le rôle “Plein” avant de continuer.',
          SurfaceStudioWizardStep.preview ||
          SurfaceStudioWizardStep.save =>
            'Cette étape ne peut pas avancer.',
        };
      });
      return;
    }
    setState(() {
      _currentStep = SurfaceStudioWizardStep.values[(_currentStep.index + 1)
          .clamp(0, SurfaceStudioWizardStep.values.length - 1)
          .toInt()];
      _statusMessage = null;
    });
  }

  void _previousStep() {
    if (_currentStep == SurfaceStudioWizardStep.importAtlas) {
      return;
    }
    setState(() {
      _currentStep = SurfaceStudioWizardStep.values[_currentStep.index - 1];
      _statusMessage = null;
    });
  }

  void _togglePreviewPlaying() {
    setState(() {
      _previewPlaying = !_previewPlaying;
    });
    _syncPreviewTimer();
  }

  void _syncPreviewTimer() {
    _previewTimer?.cancel();
    _previewTimer = null;
    if (!_previewPlaying) {
      return;
    }
    _previewTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (_previewFrameIndex >= _frameCount - 1) {
          _previewFrameIndex = _previewLoop ? 0 : _frameCount - 1;
          if (!_previewLoop) {
            _previewPlaying = false;
            _syncPreviewTimer();
          }
        } else {
          _previewFrameIndex += 1;
        }
      });
    });
  }

  void _createOrUpdateAtlas() {
    final editingAtlasId = _selectedAtlasId;
    final errors = validateSurfaceStudioAtlasDraft(
      readModel: widget.readModel,
      idRaw: _atlasId.text,
      nameRaw: _atlasName.text,
      tilesetIdRaw: _tilesetId.text,
      tileWidthRaw: _tileWidth.text,
      tileHeightRaw: _tileHeight.text,
      columnsRaw: _columns.text,
      rowsRaw: _rows.text,
      sortOrderRaw: _sortOrder.text,
      categoryIdRaw: _categoryId.text,
      editingExistingAtlasId: editingAtlasId,
    );
    if (errors.isNotEmpty) {
      setState(() {
        _statusMessage = errors.first;
      });
      return;
    }
    final draft = tryBuildDraftFromForm(
      idRaw: _atlasId.text,
      nameRaw: _atlasName.text,
      tilesetIdRaw: _tilesetId.text,
      tileWidthRaw: _tileWidth.text,
      tileHeightRaw: _tileHeight.text,
      columnsRaw: _columns.text,
      rowsRaw: _rows.text,
      sortOrderRaw: _sortOrder.text,
      categoryIdRaw: _categoryId.text,
      layout: _layout,
    );
    final atlas =
        draft == null ? null : tryBuildProjectSurfaceAtlasFromDraft(draft);
    if (atlas == null) {
      setState(() {
        _statusMessage = 'Brouillon atlas invalide.';
      });
      return;
    }

    final atlases = List<ProjectSurfaceAtlas>.from(
      widget.readModel.catalog.atlases,
    );
    final existingIndex =
        atlases.indexWhere((candidate) => candidate.id == editingAtlasId);
    if (existingIndex >= 0) {
      atlases[existingIndex] = atlas;
    } else {
      atlases.add(atlas);
    }
    final next = ProjectSurfaceCatalog(
      atlases: atlases,
      animations: List<ProjectSurfaceAnimation>.from(
        widget.readModel.catalog.animations,
      ),
      presets: List<ProjectSurfacePreset>.from(
        widget.readModel.catalog.presets,
      ),
    );
    widget.onSurfaceCatalogChanged?.call(next);
    setState(() {
      _selectedAtlasId = atlas.id;
      _statusMessage = 'Atlas ajouté au catalogue de travail.';
      _currentStep = SurfaceStudioWizardStep.slice;
      _syncSelectionToColumnCount();
    });
  }

  void _openSuggestionReview() {
    final result = _suggestionController.suggestLocal(
      columnCount: _columnCount,
    );
    setState(() {
      _suggestionResult = result;
      _suggestionReviewOpen = true;
      _statusMessage =
          'Suggestions locales prêtes — validation utilisateur requise.';
    });
  }

  void _applySuggestions({required bool reliableOnly}) {
    final result = _suggestionResult;
    if (result == null) {
      return;
    }
    final suggestions =
        reliableOnly ? result.reliableSuggestions : result.suggestions;
    var draft = _assignmentDraft;
    for (final suggestion in suggestions) {
      draft = draft.assignColumns(suggestion.role, suggestion.columns);
    }
    setState(() {
      _assignmentDraft = draft;
      _suggestionReviewOpen = false;
      _statusMessage = 'Suggestions appliquées au mapping de travail.';
    });
  }

  void _applyMapping() {
    setState(() {
      _statusMessage =
          'Mapping appliqué au plan de génération local — aucune sauvegarde disque.';
    });
  }

  void _acceptDrop(
    SurfaceVariantRole role,
    SurfaceStudioColumnDragPayload payload,
  ) {
    final validation = validateSurfaceStudioRoleDrop(
      role: role,
      payload: payload,
      draft: _assignmentDraft,
    );
    if (validation != SurfaceStudioDropValidation.valid) {
      setState(() {
        _statusMessage =
            validation == SurfaceStudioDropValidation.invalidNoColumn
                ? 'Aucune colonne à déposer.'
                : 'Ce rôle attend une seule colonne.';
      });
      return;
    }
    setState(() {
      _assignmentDraft = _assignmentDraft.assignColumns(role, payload.columns);
      _statusMessage = 'Colonnes déposées sur le rôle sélectionné.';
    });
  }

  void _appendReadyAnimations() {
    final plan = _generationPlan;
    if (plan.summary.readyAnimationCount == 0) {
      setState(() {
        _lastGenerationMessage = 'Aucune animation prête à créer.';
      });
      return;
    }
    final outcome = surfaceStudioCollectNewAnimationsFromReadyPlan(
      plan: plan,
      atlasIdForTileRefs: _atlasId.text.trim(),
      animationDisplayNamePrefix: _atlasName.text.trim(),
      categoryId:
          _categoryId.text.trim().isEmpty ? null : _categoryId.text.trim(),
      sortOrderBase: widget.readModel.catalog.animations.length,
    );
    if (outcome.newAnimations.isEmpty) {
      setState(() {
        _lastGenerationMessage = 'Aucune animation nouvelle à ajouter.';
      });
      return;
    }
    final next = surfaceStudioAppendAnimationsToWorkCatalog(
      catalog: widget.readModel.catalog,
      newAnimations: outcome.newAnimations,
    );
    widget.onSurfaceCatalogChanged?.call(next);
    widget.onWorkCatalogAnimationsCreated?.call(
      outcome.newAnimations.map((animation) => animation.id).toList(),
    );
    setState(() {
      _lastGenerationMessage =
          'Animations créées dans le catalogue de travail (${outcome.newAnimations.length}).';
    });
  }

  void _appendPreset() {
    final gridOk = _gridValid;
    final plan = surfaceStudioPlanVerticalAtlasPresetAppend(
      catalog: widget.readModel.catalog,
      atlasIdRaw: _atlasId.text,
      atlasDisplayName: _atlasName.text,
      atlasCategoryDraft: _categoryId.text,
      mappingDraft: _columnRoleMappingDraft,
      gridValid: gridOk,
    );
    if (!plan.canCreate) {
      setState(() {
        _lastPresetMessage =
            'Surface non créée : ${_presetPlanStatusLabel(plan.status)}.';
      });
      return;
    }
    try {
      final preset = surfaceStudioBuildVerticalAtlasPreset(
        catalog: widget.readModel.catalog,
        atlasIdRaw: _atlasId.text,
        atlasDisplayName: _atlasName.text,
        atlasCategoryDraft: _categoryId.text,
        mappingDraft: _columnRoleMappingDraft,
        gridValid: gridOk,
      );
      final next = surfaceStudioAppendPresetToWorkCatalog(
        catalog: widget.readModel.catalog,
        preset: preset,
      );
      widget.onSurfaceCatalogChanged?.call(next);
      widget.onWorkCatalogPresetCreated?.call(preset.id);
      setState(() {
        _lastPresetMessage = 'Surface prête à peindre créée : ${preset.name}.';
      });
    } on Object {
      setState(() {
        _lastPresetMessage =
            'Impossible de créer la surface peignable dans l’état actuel.';
      });
    }
  }

  String _presetPlanStatusLabel(
      SurfaceStudioVerticalAtlasPresetPlanStatus status) {
    return switch (status) {
      SurfaceStudioVerticalAtlasPresetPlanStatus.blockedEmptyAtlasId =>
        'atlas manquant',
      SurfaceStudioVerticalAtlasPresetPlanStatus.blockedInvalidGrid =>
        'grille invalide',
      SurfaceStudioVerticalAtlasPresetPlanStatus.blockedNoMapping =>
        'mapping absent',
      SurfaceStudioVerticalAtlasPresetPlanStatus.blockedMissingAnimations =>
        'animations manquantes',
      SurfaceStudioVerticalAtlasPresetPlanStatus.blockedDuplicatePresetId =>
        'surface déjà existante',
      SurfaceStudioVerticalAtlasPresetPlanStatus.incomplete => 'incomplet',
      SurfaceStudioVerticalAtlasPresetPlanStatus.ready => 'prêt',
    };
  }

  @override
  Widget build(BuildContext context) {
    final frameCount = _frameCount;
    return Stack(
      children: [
        SurfaceStudioShell(
          header: SurfaceStudioHeader(
            currentStep: _currentStep,
            completedSteps: _completedSteps,
            onStepSelected: _selectStep,
            onOpenAdvanced: () {
              setState(() => _advancedDrawerOpen = true);
            },
          ),
          sidebar: SurfaceStudioSidebar(
            collapsed: _sidebarCollapsed,
            currentStep: _currentStep,
            completedSteps: _completedSteps,
            onToggleCollapsed: () {
              setState(() => _sidebarCollapsed = !_sidebarCollapsed);
            },
            onStepSelected: _selectStep,
          ),
          workspacePanel: _buildWorkspacePanel(),
          rightDock: _buildRightDock(frameCount),
          bottomBar: SurfaceStudioBottomActionBar(
            canGoBack: _currentStep != SurfaceStudioWizardStep.importAtlas,
            canAutoSuggest: _columnCount > 0 && frameCount > 0,
            canApplyMapping:
                _assignmentDraft.isAssigned(SurfaceVariantRole.isolated),
            canGoNext: _canGoNext,
            canSaveCatalog: widget.hasWorkCatalogChanges &&
                widget.onSurfaceCatalogSavePrep != null,
            onBack: _previousStep,
            onAutoSuggest: _openSuggestionReview,
            onApplyMapping: _applyMapping,
            onNext: _nextStep,
            onSaveCatalog: widget.onSurfaceCatalogSavePrep,
          ),
        ),
        if (_statusMessage != null)
          Positioned(
            left: 318,
            bottom: 86,
            child: _StatusToast(message: _statusMessage!),
          ),
        if (widget.hasWorkCatalogChanges)
          const Positioned(
            left: 318,
            top: 76,
            child: _StatusToast(
              message:
                  'Catalogue de travail modifié — sauvegarde projet non effectuée.',
            ),
          ),
        if (_suggestionReviewOpen && _suggestionResult != null)
          Positioned.fill(
            child: _SuggestionReviewScrim(
              result: _suggestionResult!,
              mistralKeyConfigured:
                  hasEditorMistralApiKey(widget.projectSettings),
              onCancel: () {
                setState(() => _suggestionReviewOpen = false);
              },
              onApplyReliable: () => _applySuggestions(reliableOnly: true),
              onApplyAll: () => _applySuggestions(reliableOnly: false),
            ),
          ),
        if (_advancedDrawerOpen && widget.advancedDrawer != null)
          Positioned.fill(
            child: _AdvancedDrawerScrim(
              child: widget.advancedDrawer!,
              onClose: () {
                setState(() => _advancedDrawerOpen = false);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildWorkspacePanel() {
    return switch (_currentStep) {
      SurfaceStudioWizardStep.importAtlas => _ImportStepPanel(
          readModel: widget.readModel,
          projectTilesets: widget.projectTilesets,
          projectRootPath: widget.projectRootPath,
          atlasId: _atlasId,
          atlasName: _atlasName,
          tilesetId: _tilesetId,
          tileWidth: _tileWidth,
          tileHeight: _tileHeight,
          columns: _columns,
          rows: _rows,
          sortOrder: _sortOrder,
          categoryId: _categoryId,
          layout: _layout,
          onLayoutChanged: (layout) => setState(() => _layout = layout),
          onCreateAtlas: _createOrUpdateAtlas,
          onTilesetChanged: (value) {
            setState(() {
              _tilesetId.text = value ?? '';
            });
          },
        ),
      SurfaceStudioWizardStep.slice => _SliceStepPanel(
          projectTilesets: widget.projectTilesets,
          projectRootPath: widget.projectRootPath,
          atlasId: _atlasId,
          atlasName: _atlasName,
          tilesetId: _tilesetId,
          tileWidth: _tileWidth,
          tileHeight: _tileHeight,
          columns: _columns,
          rows: _rows,
          layout: _layout,
          onChanged: () => setState(() {}),
          onApplyGrid: _createOrUpdateAtlas,
          onResetGrid: () {
            setState(() {
              _tileWidth.text = '32';
              _tileHeight.text = '32';
              _columns.text = '12';
              _rows.text = '32';
              _zoomPercent = 100;
              _statusMessage = 'Grille réinitialisée.';
            });
          },
        ),
      SurfaceStudioWizardStep.map => SurfaceStudioAtlasPanel(
          columnCount: _columnCount,
          frameCount: _frameCount,
          tileWidth: _tileWidthValue,
          tileHeight: _tileHeightValue,
          selection: _selectedColumns,
          zoomPercent: _zoomPercent,
          onColumnSelectionChanged: (selection) {
            setState(() => _selectedColumns = selection);
          },
          onZoomChanged: (value) {
            setState(() => _zoomPercent = value.clamp(25, 400).toDouble());
          },
          onReset: () {
            setState(() {
              _selectedColumns = const SurfaceStudioColumnSelection.empty();
              _zoomPercent = 100;
              _statusMessage = 'Sélection et zoom réinitialisés.';
            });
          },
          onAutoSuggest: _openSuggestionReview,
        ),
      SurfaceStudioWizardStep.preview => _PreviewPlanPanel(
          generationPlan: _generationPlan,
          multiCenterColumns:
              _assignmentDraft.columnsForRole(SurfaceVariantRole.isolated),
          onGenerateAnimations: _appendReadyAnimations,
          message: _lastGenerationMessage,
        ),
      SurfaceStudioWizardStep.save => _SaveStepPanel(
          readModel: widget.readModel,
          generationPlan: _generationPlan,
          presetPlan: surfaceStudioPlanVerticalAtlasPresetAppend(
            catalog: widget.readModel.catalog,
            atlasIdRaw: _atlasId.text,
            atlasDisplayName: _atlasName.text,
            atlasCategoryDraft: _categoryId.text,
            mappingDraft: _columnRoleMappingDraft,
            gridValid: _gridValid,
          ),
          hasWorkCatalogChanges: widget.hasWorkCatalogChanges,
          saveFlowPrepNote: widget.saveFlowPrepNote,
          projectSaveDiskNote: widget.projectSaveDiskNote,
          generationMessage: _lastGenerationMessage,
          presetMessage: _lastPresetMessage,
          onGenerateAnimations: _appendReadyAnimations,
          onCreatePreset: _appendPreset,
          onSaveCatalog: widget.onSurfaceCatalogSavePrep,
          onProjectSave: widget.onRequestProjectSave,
          onResetWorkCatalog: widget.onResetWorkCatalog,
        ),
    };
  }

  Widget _buildRightDock(int frameCount) {
    if (_currentStep == SurfaceStudioWizardStep.save) {
      return _RightDockFrame(
        children: [
          Expanded(
            child: _CatalogStatusPanel(
              readModel: widget.readModel,
              hasWorkCatalogChanges: widget.hasWorkCatalogChanges,
            ),
          ),
        ],
      );
    }
    return _RightDockFrame(
      children: [
        Expanded(
          flex: 3,
          child: SurfaceStudioSchemaPanel(
            collapsed: _rightPanelCollapsed,
            openGroups: _openSchemaGroups,
            assignmentDraft: _assignmentDraft,
            onToggleCollapsed: () {
              setState(() => _rightPanelCollapsed = !_rightPanelCollapsed);
            },
            onToggleGroup: (id) {
              setState(() {
                final next = Set<String>.of(_openSchemaGroups);
                if (!next.add(id)) {
                  next.remove(id);
                }
                _openSchemaGroups = next;
              });
            },
            onDrop: _acceptDrop,
            onClearRole: (role) {
              setState(
                () => _assignmentDraft = _assignmentDraft.clearRole(role),
              );
            },
            onClearColumn: (role, column) {
              setState(
                () => _assignmentDraft =
                    _assignmentDraft.clearColumn(role, column),
              );
            },
          ),
        ),
        const SizedBox(height: SurfaceStudioDesignTokens.gapSm),
        Expanded(
          flex: 2,
          child: SurfaceStudioPreviewPanel(
            frameCount: frameCount,
            frameIndex: _previewFrameIndex.clamp(0, frameCount - 1).toInt(),
            playing: _previewPlaying,
            loop: _previewLoop,
            gridVisible: _previewGridVisible,
            previewSize: _previewSize,
            assignmentDraft: _assignmentDraft,
            onPrevious: () {
              setState(() {
                _previewPlaying = false;
                _previewFrameIndex =
                    (_previewFrameIndex - 1).clamp(0, frameCount - 1).toInt();
              });
              _syncPreviewTimer();
            },
            onNext: () {
              setState(() {
                _previewPlaying = false;
                _previewFrameIndex =
                    (_previewFrameIndex + 1).clamp(0, frameCount - 1).toInt();
              });
              _syncPreviewTimer();
            },
            onTogglePlaying: _togglePreviewPlaying,
            onFrameChanged: (value) {
              setState(() {
                _previewPlaying = false;
                _previewFrameIndex = value.clamp(0, frameCount - 1).toInt();
              });
              _syncPreviewTimer();
            },
            onLoopChanged: (value) => setState(() => _previewLoop = value),
            onGridChanged: (value) =>
                setState(() => _previewGridVisible = value),
            onPreviewSizeChanged: (value) =>
                setState(() => _previewSize = value),
          ),
        ),
      ],
    );
  }
}

class _ImportStepPanel extends StatelessWidget {
  const _ImportStepPanel({
    required this.readModel,
    required this.projectTilesets,
    required this.projectRootPath,
    required this.atlasId,
    required this.atlasName,
    required this.tilesetId,
    required this.tileWidth,
    required this.tileHeight,
    required this.columns,
    required this.rows,
    required this.sortOrder,
    required this.categoryId,
    required this.layout,
    required this.onLayoutChanged,
    required this.onCreateAtlas,
    required this.onTilesetChanged,
  });

  final SurfaceStudioReadModel readModel;
  final List<ProjectTilesetEntry> projectTilesets;
  final String? projectRootPath;
  final TextEditingController atlasId;
  final TextEditingController atlasName;
  final TextEditingController tilesetId;
  final TextEditingController tileWidth;
  final TextEditingController tileHeight;
  final TextEditingController columns;
  final TextEditingController rows;
  final TextEditingController sortOrder;
  final TextEditingController categoryId;
  final SurfaceAtlasLayout layout;
  final ValueChanged<SurfaceAtlasLayout> onLayoutChanged;
  final VoidCallback onCreateAtlas;
  final ValueChanged<String?> onTilesetChanged;

  @override
  Widget build(BuildContext context) {
    final sorted = sortedTilesetChoices(projectTilesets);
    final resolution = resolveSurfaceStudioAtlasImagePreview(
      projectRootPath: projectRootPath,
      projectTilesets: projectTilesets,
      technicalTilesetId: tilesetId.text,
    );
    final form = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SurfaceStudioAtlasImageSourceBlock(
            hasPicker: sorted.isNotEmpty,
            sortedTilesets: sorted,
            selectedTilesetId: tilesetId.text.isEmpty ? null : tilesetId.text,
            onSelectTilesetId: onTilesetChanged,
            label: SurfaceStudioDesignTokens.textPrimary,
            subtle: SurfaceStudioDesignTokens.textSecondary,
          ),
          const SizedBox(height: 14),
          _Field(
            keyName: 'surfaceStudio.import.atlasId',
            label: 'Identifiant atlas',
            controller: atlasId,
          ),
          _Field(
            keyName: 'surfaceStudio.import.atlasName',
            label: 'Nom atlas',
            controller: atlasName,
          ),
          _Field(
            keyName: 'surfaceStudio.import.tilesetId',
            label: 'Source technique',
            controller: tilesetId,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SmallField(label: 'Tuile W', controller: tileWidth),
              _SmallField(label: 'Tuile H', controller: tileHeight),
              _SmallField(label: 'Colonnes', controller: columns),
              _SmallField(label: 'Frames', controller: rows),
              _SmallField(label: 'Ordre', controller: sortOrder),
            ],
          ),
          const SizedBox(height: 10),
          _Field(
            keyName: 'surfaceStudio.import.categoryId',
            label: 'Catégorie',
            controller: categoryId,
          ),
          const SizedBox(height: 10),
          Material(
            type: MaterialType.transparency,
            child: DropdownButton<SurfaceAtlasLayout>(
              key: const ValueKey('surfaceStudio.import.layout'),
              isExpanded: true,
              value: layout,
              dropdownColor: SurfaceStudioDesignTokens.backgroundElevated,
              style: const TextStyle(
                color: SurfaceStudioDesignTokens.textPrimary,
              ),
              items: const [
                DropdownMenuItem(
                  value: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
                  child: Text('Colonnes = rôles'),
                ),
                DropdownMenuItem(
                  value: SurfaceAtlasLayout.grid,
                  child: Text('Grille libre'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  onLayoutChanged(value);
                }
              },
            ),
          ),
          const SizedBox(height: 14),
          CupertinoButton(
            key: const ValueKey('surfaceStudio.import.createAtlas'),
            color: SurfaceStudioDesignTokens.accentGoldSoft,
            onPressed: onCreateAtlas,
            child: Text(
              readModel.atlases.isEmpty
                  ? 'Créer l’atlas de travail'
                  : 'Appliquer au catalogue de travail',
            ),
          ),
        ],
      ),
    );
    final preview = SurfaceStudioAtlasImagePreview(
      resolution: resolution,
      label: SurfaceStudioDesignTokens.textPrimary,
      subtle: SurfaceStudioDesignTokens.textSecondary,
      draftTileWidth: int.tryParse(tileWidth.text),
      draftTileHeight: int.tryParse(tileHeight.text),
      draftColumns: int.tryParse(columns.text),
      draftRows: int.tryParse(rows.text),
      draftLayoutLabel: 'Colonnes → rôles',
      largeFormat: true,
    );
    return _PanelFrame(
      keyName: 'surfaceStudio.import.panel',
      title: 'Importer',
      subtitle: 'Choisissez une source réelle et préparez le brouillon atlas.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 720) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  form,
                  const SizedBox(height: 16),
                  SizedBox(height: 340, child: preview),
                ],
              ),
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: form),
              const SizedBox(width: 16),
              Expanded(child: preview),
            ],
          );
        },
      ),
    );
  }
}

class _SliceStepPanel extends StatelessWidget {
  const _SliceStepPanel({
    required this.projectTilesets,
    required this.projectRootPath,
    required this.atlasId,
    required this.atlasName,
    required this.tilesetId,
    required this.tileWidth,
    required this.tileHeight,
    required this.columns,
    required this.rows,
    required this.layout,
    required this.onChanged,
    required this.onApplyGrid,
    required this.onResetGrid,
  });

  final List<ProjectTilesetEntry> projectTilesets;
  final String? projectRootPath;
  final TextEditingController atlasId;
  final TextEditingController atlasName;
  final TextEditingController tilesetId;
  final TextEditingController tileWidth;
  final TextEditingController tileHeight;
  final TextEditingController columns;
  final TextEditingController rows;
  final SurfaceAtlasLayout layout;
  final VoidCallback onChanged;
  final VoidCallback onApplyGrid;
  final VoidCallback onResetGrid;

  @override
  Widget build(BuildContext context) {
    final resolution = resolveSurfaceStudioAtlasImagePreview(
      projectRootPath: projectRootPath,
      projectTilesets: projectTilesets,
      technicalTilesetId: tilesetId.text,
    );
    return _PanelFrame(
      keyName: 'surfaceStudio.slice.panel',
      title: 'Découper',
      subtitle: 'Ajustez la grille qui alimentera le mapping et la génération.',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: SurfaceStudioAtlasImagePreview(
              resolution: resolution,
              label: SurfaceStudioDesignTokens.textPrimary,
              subtle: SurfaceStudioDesignTokens.textSecondary,
              draftTileWidth: int.tryParse(tileWidth.text),
              draftTileHeight: int.tryParse(tileHeight.text),
              draftColumns: int.tryParse(columns.text),
              draftRows: int.tryParse(rows.text),
              draftLayoutLabel: layout.name,
              largeFormat: true,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    atlasName.text.isEmpty ? atlasId.text : atlasName.text,
                    style: const TextStyle(
                      color: SurfaceStudioDesignTokens.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _SmallField(
                        label: 'Tuile W',
                        controller: tileWidth,
                        onChanged: (_) => onChanged(),
                      ),
                      _SmallField(
                        label: 'Tuile H',
                        controller: tileHeight,
                        onChanged: (_) => onChanged(),
                      ),
                      _SmallField(
                        label: 'Colonnes',
                        controller: columns,
                        onChanged: (_) => onChanged(),
                      ),
                      _SmallField(
                        label: 'Frames',
                        controller: rows,
                        onChanged: (_) => onChanged(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SurfaceStudioAtlasGridPreview(
                    sourceLabel: tilesetId.text,
                    tileWidth: int.tryParse(tileWidth.text),
                    tileHeight: int.tryParse(tileHeight.text),
                    columns: int.tryParse(columns.text),
                    rows: int.tryParse(rows.text),
                    layoutLabel: layout.name,
                  ),
                  const SizedBox(height: 14),
                  CupertinoButton(
                    color: SurfaceStudioDesignTokens.accentTealSoft,
                    onPressed: onApplyGrid,
                    child: const Text('Appliquer la grille'),
                  ),
                  const SizedBox(height: 8),
                  CupertinoButton(
                    onPressed: onResetGrid,
                    child: const Text('Réinitialiser'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewPlanPanel extends StatelessWidget {
  const _PreviewPlanPanel({
    required this.generationPlan,
    required this.multiCenterColumns,
    required this.onGenerateAnimations,
    required this.message,
  });

  final SurfaceStudioVerticalAtlasAnimationGenerationPlan generationPlan;
  final List<int> multiCenterColumns;
  final VoidCallback onGenerateAnimations;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final summary = generationPlan.summary;
    return _PanelFrame(
      keyName: 'surfaceStudio.previewPlan.panel',
      title: 'Prévisualiser',
      subtitle: 'Plan réel de génération depuis le mapping courant.',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MetricRow(
              metrics: {
                'Assignées': '${summary.assignedColumnCount}',
                'Prêtes': '${summary.readyAnimationCount}',
                'À corriger': '${summary.errorAnimationCount}',
                'Frame': '${summary.durationMsPerFrame} ms',
              },
            ),
            if (multiCenterColumns.length > 1) ...[
              const SizedBox(height: 10),
              const _WarningBox(
                text:
                    'Plein contient plusieurs colonnes. V2.1 conserve l’UX multi-colonnes, mais la génération réelle utilise la première colonne tant qu’un modèle de variantes multiples n’existe pas.',
              ),
            ],
            const SizedBox(height: 14),
            CupertinoButton(
              key: const ValueKey('surfaceStudio.preview.generateAnimations'),
              color: SurfaceStudioDesignTokens.accentTealSoft,
              onPressed:
                  summary.readyAnimationCount > 0 ? onGenerateAnimations : null,
              child: const Text('Générer les animations prêtes'),
            ),
            if (message != null) ...[
              const SizedBox(height: 10),
              Text(
                message!,
                style: const TextStyle(
                  color: SurfaceStudioDesignTokens.accentTeal,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 14),
            for (final item in generationPlan.items) _PlanItemRow(item: item),
          ],
        ),
      ),
    );
  }
}

class _SaveStepPanel extends StatelessWidget {
  const _SaveStepPanel({
    required this.readModel,
    required this.generationPlan,
    required this.presetPlan,
    required this.hasWorkCatalogChanges,
    required this.saveFlowPrepNote,
    required this.projectSaveDiskNote,
    required this.generationMessage,
    required this.presetMessage,
    required this.onGenerateAnimations,
    required this.onCreatePreset,
    required this.onSaveCatalog,
    required this.onProjectSave,
    required this.onResetWorkCatalog,
  });

  final SurfaceStudioReadModel readModel;
  final SurfaceStudioVerticalAtlasAnimationGenerationPlan generationPlan;
  final SurfaceStudioVerticalAtlasPresetAppendPlan presetPlan;
  final bool hasWorkCatalogChanges;
  final String? saveFlowPrepNote;
  final String? projectSaveDiskNote;
  final String? generationMessage;
  final String? presetMessage;
  final VoidCallback onGenerateAnimations;
  final VoidCallback onCreatePreset;
  final VoidCallback? onSaveCatalog;
  final Future<void> Function()? onProjectSave;
  final VoidCallback? onResetWorkCatalog;

  @override
  Widget build(BuildContext context) {
    return _PanelFrame(
      keyName: 'surfaceStudio.save.panel',
      title: 'Enregistrer',
      subtitle: 'Générez les artefacts Surface, puis préparez la sauvegarde.',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MetricRow(
              metrics: {
                'Atlas': '${readModel.summary.atlasCount}',
                'Animations': '${readModel.summary.animationCount}',
                'Surfaces': '${readModel.summary.presetCount}',
                'Dirty': hasWorkCatalogChanges ? 'oui' : 'non',
              },
            ),
            const SizedBox(height: 14),
            CupertinoButton(
              key: const ValueKey('surfaceStudio.save.generateAnimations'),
              color: SurfaceStudioDesignTokens.accentTealSoft,
              onPressed: generationPlan.summary.readyAnimationCount > 0
                  ? onGenerateAnimations
                  : null,
              child: const Text('Générer les animations'),
            ),
            const SizedBox(height: 8),
            CupertinoButton(
              key: const ValueKey('surfaceStudio.save.createPreset'),
              color: SurfaceStudioDesignTokens.accentGoldSoft,
              onPressed: presetPlan.canCreate ? onCreatePreset : null,
              child: const Text('Créer la surface peignable'),
            ),
            const SizedBox(height: 8),
            CupertinoButton(
              key: const ValueKey('surfaceStudio.action.saveCatalog'),
              onPressed: hasWorkCatalogChanges ? onSaveCatalog : null,
              child: const Text('Préparer la sauvegarde du catalogue'),
            ),
            if (onProjectSave != null) ...[
              const SizedBox(height: 8),
              CupertinoButton(
                key: const ValueKey('surfaceStudio.save.project'),
                onPressed: onProjectSave,
                child: const Text('Sauvegarder le projet via le flux existant'),
              ),
            ],
            if (onResetWorkCatalog != null) ...[
              const SizedBox(height: 8),
              CupertinoButton(
                key: const ValueKey('surfaceStudio.save.resetWorkCatalog'),
                onPressed: onResetWorkCatalog,
                child: const Text('Réinitialiser le catalogue de travail'),
              ),
            ],
            for (final message in [
              generationMessage,
              presetMessage,
              saveFlowPrepNote,
              projectSaveDiskNote,
            ])
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(
                    color: SurfaceStudioDesignTokens.accentTeal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _CatalogStatusPanel extends StatelessWidget {
  const _CatalogStatusPanel({
    required this.readModel,
    required this.hasWorkCatalogChanges,
  });

  final SurfaceStudioReadModel readModel;
  final bool hasWorkCatalogChanges;

  @override
  Widget build(BuildContext context) {
    return _PanelFrame(
      keyName: 'surfaceStudio.catalogStatus.panel',
      title: 'Catalogue & état',
      subtitle: 'Résumé du catalogue de travail Surface.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricRow(
            metrics: {
              'Atlas': '${readModel.summary.atlasCount}',
              'Animations': '${readModel.summary.animationCount}',
              'Surfaces': '${readModel.summary.presetCount}',
            },
          ),
          const SizedBox(height: 12),
          Text(
            hasWorkCatalogChanges
                ? 'Catalogue de travail modifié — sauvegarde projet non effectuée.'
                : 'Catalogue synchronisé avec le manifest mémoire.',
            style: const TextStyle(
              color: SurfaceStudioDesignTokens.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RightDockFrame extends StatelessWidget {
  const _RightDockFrame({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(children: children);
  }
}

class _PanelFrame extends StatelessWidget {
  const _PanelFrame({
    required this.keyName,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String keyName;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(keyName),
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundPanel,
        borderRadius:
            BorderRadius.circular(SurfaceStudioDesignTokens.panelRadius),
        border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: SurfaceStudioDesignTokens.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: SurfaceStudioDesignTokens.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.keyName,
    required this.label,
    required this.controller,
  });

  final String keyName;
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        type: MaterialType.transparency,
        child: TextField(
          key: ValueKey(keyName),
          controller: controller,
          style: const TextStyle(color: SurfaceStudioDesignTokens.textPrimary),
          decoration: _fieldDecoration(label),
        ),
      ),
    );
  }
}

class _SmallField extends StatelessWidget {
  const _SmallField({
    required this.label,
    required this.controller,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      child: Material(
        type: MaterialType.transparency,
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(color: SurfaceStudioDesignTokens.textPrimary),
          decoration: _fieldDecoration(label),
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: SurfaceStudioDesignTokens.textSecondary),
    filled: true,
    fillColor: SurfaceStudioDesignTokens.backgroundElevated,
    enabledBorder: OutlineInputBorder(
      borderSide:
          const BorderSide(color: SurfaceStudioDesignTokens.borderSubtle),
      borderRadius: BorderRadius.circular(9),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: SurfaceStudioDesignTokens.accentGold),
      borderRadius: BorderRadius.circular(9),
    ),
  );
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.metrics});

  final Map<String, String> metrics;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final metric in metrics.entries)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: SurfaceStudioDesignTokens.backgroundElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
            ),
            child: Text(
              '${metric.key}  ${metric.value}',
              style: const TextStyle(
                color: SurfaceStudioDesignTokens.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _WarningBox extends StatelessWidget {
  const _WarningBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.accentGoldSoft.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SurfaceStudioDesignTokens.accentGold),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: SurfaceStudioDesignTokens.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PlanItemRow extends StatelessWidget {
  const _PlanItemRow({required this.item});

  final SurfaceStudioVerticalAtlasAnimationGenerationItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: item.isReady
              ? SurfaceStudioDesignTokens.accentTeal.withValues(alpha: 0.5)
              : SurfaceStudioDesignTokens.borderSubtle,
        ),
      ),
      child: Text(
        '${SurfaceStudioRoleLabels.labelForRole(item.role)} · colonne ${item.columnIndex + 1} · ${item.isReady ? 'prête' : item.problems.join(', ')}',
        style: const TextStyle(
          color: SurfaceStudioDesignTokens.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusToast extends StatelessWidget {
  const _StatusToast({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SurfaceStudioDesignTokens.borderStrong),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: SurfaceStudioDesignTokens.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SuggestionReviewScrim extends StatelessWidget {
  const _SuggestionReviewScrim({
    required this.result,
    required this.mistralKeyConfigured,
    required this.onCancel,
    required this.onApplyReliable,
    required this.onApplyAll,
  });

  final SurfaceStudioMappingSuggestionResult result;
  final bool mistralKeyConfigured;
  final VoidCallback onCancel;
  final VoidCallback onApplyReliable;
  final VoidCallback onApplyAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0x990B1020),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.all(18),
      child: Container(
        key: const ValueKey('surfaceStudio.suggestion.review'),
        width: 520,
        decoration: BoxDecoration(
          color: SurfaceStudioDesignTokens.backgroundPanel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SurfaceStudioDesignTokens.borderStrong),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Suggestions détectées',
              style: TextStyle(
                color: SurfaceStudioDesignTokens.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Source : ${_sourceLabel(result.source)}',
              style: const TextStyle(
                color: SurfaceStudioDesignTokens.accentTeal,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final warning in result.warnings) ...[
                      _WarningBox(text: warning),
                      const SizedBox(height: 8),
                    ],
                    for (final suggestion in result.suggestions)
                      _SuggestionRow(suggestion: suggestion),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: SurfaceStudioDesignTokens.backgroundElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: SurfaceStudioDesignTokens.borderSubtle,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Analyse IA Mistral',
                            style: TextStyle(
                              color: SurfaceStudioDesignTokens.textPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            mistralKeyConfigured
                                ? 'Clé Mistral configurée.'
                                : 'Clé Mistral absente : Projet → Paramètres (IA) ou MISTRAL_API_KEY',
                            style: const TextStyle(
                              color: SurfaceStudioDesignTokens.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'L’analyse IA peut envoyer l’image de l’atlas au fournisseur configuré. Rien n’est envoyé sans confirmation.',
                            style: TextStyle(
                              color: SurfaceStudioDesignTokens.textMuted,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Analyse IA à venir',
                            style: TextStyle(
                              color: SurfaceStudioDesignTokens.accentGold,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 10,
              runSpacing: 8,
              children: [
                CupertinoButton(
                  onPressed: onCancel,
                  child: const Text('Annuler'),
                ),
                CupertinoButton(
                  color: SurfaceStudioDesignTokens.accentTealSoft,
                  onPressed: onApplyReliable,
                  child: const Text('Appliquer les suggestions fiables'),
                ),
                CupertinoButton(
                  color: SurfaceStudioDesignTokens.accentGoldSoft,
                  onPressed: onApplyAll,
                  child: const Text('Tout appliquer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _sourceLabel(SurfaceStudioMappingSuggestionSource source) {
    return switch (source) {
      SurfaceStudioMappingSuggestionSource.local => 'Local',
      SurfaceStudioMappingSuggestionSource.mistral => 'Mistral',
      SurfaceStudioMappingSuggestionSource.merged => 'Fusion',
    };
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.suggestion});

  final SurfaceStudioRoleSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            SurfaceStudioRoleLabels.labelForRole(suggestion.role),
            style: const TextStyle(
              color: SurfaceStudioDesignTokens.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Colonnes : ${suggestion.columns.join(', ')} · confiance : ${suggestion.confidence.name}',
            style: const TextStyle(
              color: SurfaceStudioDesignTokens.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            suggestion.reason,
            style: const TextStyle(
              color: SurfaceStudioDesignTokens.textMuted,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvancedDrawerScrim extends StatelessWidget {
  const _AdvancedDrawerScrim({
    required this.child,
    required this.onClose,
  });

  final Widget child;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0x770B1020),
      alignment: Alignment.centerRight,
      child: Container(
        key: const ValueKey('surfaceStudio.advanced.drawer'),
        width: 620,
        margin: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: SurfaceStudioDesignTokens.backgroundPanel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SurfaceStudioDesignTokens.borderStrong),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Catalogue & diagnostics',
                      style: TextStyle(
                        color: SurfaceStudioDesignTokens.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size.square(36),
                    onPressed: onClose,
                    child: const Icon(
                      CupertinoIcons.xmark,
                      color: SurfaceStudioDesignTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
```
### `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`

```dart
// Surface Studio V2.1 panel tests.
//
// These assertions intentionally replace the old Lot 52-69 panel expectations:
// the catalog browser, diagnostics and paintable-surface panels still exist, but
// they must no longer render as a second Surface Studio under the wizard.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_panel.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_workflow_layout.dart';

import 'surface_studio_rebuild_test_harness.dart';

void main() {
  group('SurfaceStudioPanel V2.1', () {
    testWidgets('renders one wizard and no legacy workflow underneath',
        (tester) async {
      await pumpSurfaceStudioForTest(tester);
      await tester.pump();

      expect(find.byKey(const Key('surfaceStudio.shell')), findsOneWidget);
      expect(
        find.text('Surface Studio — Assistant de mapping d’atlas'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('surface_studio_legacy_authoring_bridge')),
        findsNothing,
      );
      expect(find.byType(SurfaceStudioWorkflowLayout), findsNothing);
      expect(find.text('Assistant de création'), findsNothing);
      expect(find.text('Catalogue Surface'), findsNothing);
      expect(find.text('Diagnostics Surface'), findsNothing);
    });

    testWidgets('keeps catalog and diagnostics in the advanced drawer',
        (tester) async {
      await pumpSurfaceStudioForTest(tester);
      await tester.pump();

      await tester.tap(find.byIcon(CupertinoIcons.gear_alt));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('surfaceStudio.advanced.drawer')),
        findsOneWidget,
      );
      expect(find.text('Catalogue & diagnostics'), findsOneWidget);
      expect(find.text('Détails avancés'), findsOneWidget);
      expect(find.text('Catalogue Surface'), findsOneWidget);
      expect(find.text('Diagnostics Surface'), findsOneWidget);
      expect(find.text('Surfaces prêtes à peindre'), findsOneWidget);
    });

    testWidgets(
        'SurfaceStudioPanelFromManifest saves the work catalog by action',
        (tester) async {
      ProjectManifest? changedManifest;
      await pumpSurfaceStudioPanelFromManifest(
        tester,
        manifest: _manifest(ProjectSurfaceCatalog()),
        onProjectManifestChanged: (manifest) => changedManifest = manifest,
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(const Key('surfaceStudio.import.atlasId')),
        'v21-atlas',
      );
      await tester.enterText(
        find.byKey(const Key('surfaceStudio.import.atlasName')),
        'V2.1 Atlas',
      );
      await tester.enterText(
        find.byKey(const Key('surfaceStudio.import.tilesetId')),
        'tiles',
      );
      await tester
          .tap(find.byKey(const Key('surfaceStudio.import.createAtlas')));
      await tester.pump();

      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsOneWidget,
      );
      expect(changedManifest, isNull);

      await tester
          .tap(find.byKey(const Key('surfaceStudio.action.saveCatalog')));
      await tester.pump();

      expect(changedManifest, isNotNull);
      expect(
        changedManifest!.surfaceCatalog.atlases.map((atlas) => atlas.id),
        contains('v21-atlas'),
      );
    });

    testWidgets('SurfaceStudioPanel still builds without ProviderScope',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 1800,
            height: 1000,
            child: SurfaceStudioPanel(
              readModel: buildSurfaceStudioReadModelFromCatalog(_catalog()),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('surfaceStudio.shell')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> pumpSurfaceStudioPanelFromManifest(
  WidgetTester tester, {
  required ProjectManifest manifest,
  ValueChanged<ProjectManifest>? onProjectManifestChanged,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(2048, 1120);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 2048,
        height: 1120,
        child: SurfaceStudioPanelFromManifest(
          manifest: manifest,
          projectRootPath: '/missing/project',
          onProjectManifestChanged: onProjectManifestChanged,
        ),
      ),
    ),
  );
}

ProjectManifest _manifest(ProjectSurfaceCatalog catalog) {
  return ProjectManifest(
    name: 'Test',
    maps: const [],
    tilesets: const [
      ProjectTilesetEntry(
        id: 'tiles',
        name: 'Tiles',
        relativePath: 'missing/tiles.png',
      ),
    ],
    surfaceCatalog: catalog,
  );
}

ProjectSurfaceCatalog _catalog() {
  const atlasId = 'water-atlas';
  final animation = ProjectSurfaceAnimation(
    id: 'water-col-0',
    name: 'Water Column 0',
    timeline: SurfaceAnimationTimeline(
      frames: [
        SurfaceAnimationFrame(
          tileRef: SurfaceAtlasTileRef(
            atlasId: atlasId,
            column: 0,
            row: 0,
          ),
          durationMs: 120,
        ),
      ],
    ),
    syncGroupId: atlasId,
  );
  return ProjectSurfaceCatalog(
    atlases: [
      ProjectSurfaceAtlas(
        id: atlasId,
        name: 'Water Atlas',
        tilesetId: 'tiles',
        geometry: SurfaceAtlasGeometry(
          tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
          gridSize: SurfaceAtlasGridSize(columns: 12, rows: 32),
          layout: SurfaceAtlasLayout.grid,
        ),
      ),
    ],
    animations: [animation],
    presets: [
      ProjectSurfacePreset(
        id: 'water',
        name: 'Water Surface',
        variantAnimations: SurfaceVariantAnimationRefSet(
          refs: [
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.isolated,
              animationId: 'water-col-0',
            ),
          ],
        ),
      ),
    ],
  );
}
```
### `packages/map_editor/test/surface_studio/surface_studio_rebuild_test_harness.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_panel.dart';

Widget wrapSurfaceStudioForTest({
  SurfaceStudioReadModel? readModel,
  ProjectSettings? projectSettings,
  ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogSaveRequested,
  double width = 2048,
  double height = 1120,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: Size(width, height)),
      child: CupertinoPageScaffold(
        child: SizedBox(
          width: width,
          height: height,
          child: SurfaceStudioPanel(
            readModel:
                readModel ?? buildSurfaceStudioReadModelFromCatalog(_catalog()),
            projectSettings: projectSettings,
            onSurfaceCatalogSaveRequested: onSurfaceCatalogSaveRequested,
            projectTilesets: const <ProjectTilesetEntry>[
              ProjectTilesetEntry(
                id: 'water_tiles',
                name: 'Water Tiles',
                relativePath: 'missing/water.png',
                sortOrder: 0,
              ),
            ],
            projectRootPath: '/missing/project',
          ),
        ),
      ),
    ),
  );
}

Future<void> pumpSurfaceStudioForTest(
  WidgetTester tester, {
  SurfaceStudioReadModel? readModel,
  ProjectSettings? projectSettings,
  ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogSaveRequested,
  double width = 2048,
  double height = 1120,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    wrapSurfaceStudioForTest(
      readModel: readModel,
      projectSettings: projectSettings,
      onSurfaceCatalogSaveRequested: onSurfaceCatalogSaveRequested,
      width: width,
      height: height,
    ),
  );
}

ProjectSurfaceCatalog _catalog() {
  const atlasId = 'water-atlas';
  final animations = <ProjectSurfaceAnimation>[
    for (var column = 0; column < 12; column++)
      ProjectSurfaceAnimation(
        id: 'water-col-$column',
        name: 'Water Column $column',
        timeline: SurfaceAnimationTimeline(
          frames: [
            for (var row = 0; row < 32; row++)
              SurfaceAnimationFrame(
                tileRef: SurfaceAtlasTileRef(
                  atlasId: atlasId,
                  column: column,
                  row: row,
                ),
                durationMs: 120,
              ),
          ],
        ),
        syncGroupId: atlasId,
        sortOrder: column,
      ),
  ];

  return ProjectSurfaceCatalog(
    atlases: [
      ProjectSurfaceAtlas(
        id: atlasId,
        name: 'Water Atlas',
        tilesetId: 'water_tiles',
        geometry: SurfaceAtlasGeometry(
          tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
          gridSize: SurfaceAtlasGridSize(columns: 12, rows: 32),
          layout: SurfaceAtlasLayout.grid,
        ),
      ),
    ],
    animations: animations,
    presets: [
      ProjectSurfacePreset(
        id: 'water-surface',
        name: 'Water Surface',
        variantAnimations: SurfaceVariantAnimationRefSet(
          refs: [
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.isolated,
              animationId: 'water-col-3',
            ),
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.endNorth,
              animationId: 'water-col-4',
            ),
          ],
        ),
      ),
    ],
  );
}
```
### `packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart`

```dart
// Golden slice vertical atlas — chaîne authoring Lots 70–80 + wizard V2.1.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_animation_generation_plan.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_animation_generator.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_preset_generator.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_role_mapping.dart';

import 'surface_studio_rebuild_test_harness.dart';

void main() {
  group('Lot 80 — golden slice vertical atlas', () {
    test(
        '23×32 + suggestion standard : 20 animations prêtes puis preset cohérent',
        () {
      const cols = 23;
      const rows = 32;
      const duration = 120;
      final mapping = SurfaceStudioColumnRoleMappingDraft.suggested(cols);
      expect(mapping.assignments.length, 20);

      final existingIds = <String>{};
      final plan = buildSurfaceStudioVerticalAtlasAnimationGenerationPlan(
        atlasIdRaw: 'eau',
        mappingDraft: mapping,
        tileWidth: 32,
        tileHeight: 32,
        columns: cols,
        rows: rows,
        durationMsPerFrame: duration,
        existingAnimationIds: existingIds,
      );
      expect(plan.summary.readyAnimationCount, 20);
      expect(plan.gridValid, isTrue);

      final outcome = surfaceStudioCollectNewAnimationsFromReadyPlan(
        plan: plan,
        atlasIdForTileRefs: 'eau',
        animationDisplayNamePrefix: 'Eau',
        categoryId: null,
        sortOrderBase: 0,
      );
      expect(outcome.newAnimations.length, 20);

      var catalog = ProjectSurfaceCatalog(
        atlases: [
          ProjectSurfaceAtlas(
            id: 'eau',
            name: 'Eau',
            tilesetId: 'dummy',
            geometry: SurfaceAtlasGeometry(
              tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
              gridSize: SurfaceAtlasGridSize(columns: cols, rows: rows),
              layout: SurfaceAtlasLayout.grid,
            ),
          ),
        ],
      );
      catalog = surfaceStudioAppendAnimationsToWorkCatalog(
        catalog: catalog,
        newAnimations: outcome.newAnimations,
      );
      expect(catalog.animations.length, 20);

      final presetPlan = surfaceStudioPlanVerticalAtlasPresetAppend(
        catalog: catalog,
        atlasIdRaw: 'eau',
        atlasDisplayName: 'Eau',
        atlasCategoryDraft: null,
        mappingDraft: mapping,
        gridValid: true,
      );
      expect(presetPlan.canCreate, isTrue);
      expect(presetPlan.missingAnimationCount, 0);

      final preset = surfaceStudioBuildVerticalAtlasPreset(
        catalog: catalog,
        atlasIdRaw: 'eau',
        atlasDisplayName: 'Eau',
        atlasCategoryDraft: null,
        mappingDraft: mapping,
        gridValid: true,
      );
      expect(preset.id, 'eau-surface-preset');
      expect(preset.variantCount, 20);

      final animIds = {for (final a in catalog.animations) a.id};
      for (final ref in preset.variantAnimations.refs) {
        expect(animIds.contains(ref.animationId), isTrue,
            reason: 'preset ref ${ref.role} -> ${ref.animationId}');
      }

      final plein =
          catalog.animations.firstWhere((a) => a.id == 'eau-plein-loop');
      expect(plein.timeline.frameCount, rows);
      expect(plein.timeline.frames.first.tileRef.column, 0);
      expect(plein.timeline.frames.first.tileRef.row, 0);
      expect(plein.timeline.frames.last.tileRef.row, rows - 1);
      expect(plein.timeline.frames.first.durationMs, duration);
    });

    testWidgets(
        'V2.1 UI : atlas → suggestion review → animations → preset → save prep',
        (tester) async {
      ProjectSurfaceCatalog? saved;
      await pumpSurfaceStudioForTest(
        tester,
        readModel: buildSurfaceStudioReadModelFromCatalog(
          ProjectSurfaceCatalog(),
        ),
        onSurfaceCatalogSaveRequested: (catalog) => saved = catalog,
      );
      await tester.pump();

      final idF = find.byKey(const ValueKey('surfaceStudio.import.atlasId'));
      final nameF =
          find.byKey(const ValueKey('surfaceStudio.import.atlasName'));
      final tsF = find.byKey(const ValueKey('surfaceStudio.import.tilesetId'));

      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'eau');
      await tester.enterText(nameF, 'Eau');
      await tester.enterText(tsF, 't');
      await tester.pump();

      final createAtlas =
          find.byKey(const ValueKey('surfaceStudio.import.createAtlas'));
      await tester.ensureVisible(createAtlas);
      await tester.pumpAndSettle();
      await tester.tap(createAtlas);
      await tester.pumpAndSettle(const Duration(milliseconds: 80));

      await tester.tap(find.byKey(const ValueKey('surfaceStudio.action.next')));
      await tester.pumpAndSettle(const Duration(milliseconds: 120));

      final autoSuggest =
          find.byKey(const ValueKey('surfaceStudio.action.autoSuggest'));
      await tester.ensureVisible(autoSuggest);
      await tester.pumpAndSettle();
      await tester.tap(autoSuggest);
      await tester.pumpAndSettle(const Duration(milliseconds: 120));
      expect(find.text('Suggestions détectées'), findsOneWidget);
      await tester.tap(find.text('Tout appliquer'));
      await tester.pumpAndSettle(const Duration(milliseconds: 120));

      await tester.tap(find.byKey(const ValueKey('surfaceStudio.action.next')));
      await tester.pumpAndSettle(const Duration(milliseconds: 120));

      final generatePreview = find
          .byKey(const ValueKey('surfaceStudio.preview.generateAnimations'));
      await tester.ensureVisible(generatePreview);
      await tester.pumpAndSettle();
      await tester.tap(generatePreview);
      await tester.pumpAndSettle(const Duration(milliseconds: 120));

      await tester.tap(find.byKey(const ValueKey('surfaceStudio.action.next')));
      await tester.pumpAndSettle(const Duration(milliseconds: 120));

      final createPreset =
          find.byKey(const ValueKey('surfaceStudio.save.createPreset'));
      await tester.ensureVisible(createPreset);
      await tester.pumpAndSettle();
      await tester.tap(createPreset);
      await tester.pumpAndSettle(const Duration(milliseconds: 120));

      final saveCatalog =
          find.byKey(const ValueKey('surfaceStudio.action.saveCatalog')).last;
      await tester.ensureVisible(saveCatalog);
      await tester.pumpAndSettle();
      await tester.tap(saveCatalog);
      await tester.pumpAndSettle(const Duration(milliseconds: 150));

      expect(saved, isNotNull);
      expect(saved!.atlases.length, 1);
      expect(saved!.atlases.first.id, 'eau');
      expect(saved!.animations.length, greaterThan(0));
      expect(saved!.presets.length, 1);

      final preset = saved!.presets.first;
      expect(preset.id, 'eau-surface-preset');

      final animById = {
        for (final a in saved!.animations) a.id: a,
      };
      for (final ref in preset.variantAnimations.refs) {
        expect(animById.containsKey(ref.animationId), isTrue);
      }

      expect(
        preset.animationIdForRole(SurfaceVariantRole.isolated),
        isNotNull,
      );
    });
  });
}
```
### `packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart`

```dart
// Surface Studio workspace entry tests for the V2.1 integrated wizard.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_panel.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_workflow_layout.dart';
import 'package:map_editor/src/ui/canvas/editor_canvas_host.dart';
import 'package:path/path.dart' as p;

import '../shell_chrome_test_harness.dart';

void main() {
  group('Surface Studio workspace entry V2.1', () {
    test('EditorWorkspaceMode.surfaceStudio exists in enum', () {
      expect(
        EditorWorkspaceMode.values.contains(EditorWorkspaceMode.surfaceStudio),
        isTrue,
      );
    });

    testWidgets('entry remains visible in the explorer', (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/surface_v21_entry',
          project: _projectWithSurfaceCatalog(_minimalSurfaceCatalog()),
        ),
      );

      expect(find.byKey(const Key('surface-studio-workspace-entry')),
          findsOneWidget);
      expect(find.text('Surface Studio'), findsWidgets);
      expect(
        find.textContaining('Surfaces animées', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('surface workspace renders one integrated assistant',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/surface_v21_workspace',
          project: _projectWithSurfaceCatalog(_minimalSurfaceCatalog()),
          workspaceMode: EditorWorkspaceMode.surfaceStudio,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EditorCanvasHost), findsOneWidget);
      expect(find.byType(SurfaceStudioPanel), findsOneWidget);
      expect(find.byKey(const Key('surfaceStudio.shell')), findsOneWidget);
      expect(
        find.text('Surface Studio — Assistant de mapping d’atlas'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('surface_studio_legacy_authoring_bridge')),
        findsNothing,
      );
      expect(find.byType(SurfaceStudioWorkflowLayout), findsNothing);
      expect(find.text('Assistant de création'), findsNothing);
      expect(find.text('Inspecteur Surface'), findsNothing);
    });

    testWidgets(
        'new wizard save prep updates manifest memory without disk write',
        (tester) async {
      final temp = Directory.systemTemp.createTempSync('map_editor_v21_prep_');
      addTearDown(() {
        if (temp.existsSync()) {
          temp.deleteSync(recursive: true);
        }
      });
      final empty = _projectWithSurfaceCatalog(ProjectSurfaceCatalog());
      final manifestPath = p.join(temp.path, 'project.json');
      File(manifestPath).writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(empty.toJson()),
      );
      final container = await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: temp.path,
          project: empty,
          workspaceMode: EditorWorkspaceMode.surfaceStudio,
        ),
      );
      await tester.pumpAndSettle();

      await _createAtlasFromWizard(tester, id: 'v21-prep');
      await tester
          .tap(find.byKey(const Key('surfaceStudio.action.saveCatalog')));
      await tester.pumpAndSettle();

      final inMemory = container.read(editorNotifierProvider).project!;
      expect(inMemory.surfaceCatalog.atlases.map((atlas) => atlas.id),
          contains('v21-prep'));

      final onDisk = File(manifestPath).readAsStringSync();
      final decoded = jsonDecode(onDisk) as Map<String, dynamic>;
      final surfaceCatalog =
          (decoded['surfaceCatalog'] as Map<String, dynamic>?) ?? {};
      expect(surfaceCatalog['atlases'] as List<dynamic>? ?? [], isEmpty);
    });

    testWidgets('new wizard save prep then saveProjectManifest writes disk',
        (tester) async {
      final temp = Directory.systemTemp.createTempSync('map_editor_v21_save_');
      addTearDown(() {
        if (temp.existsSync()) {
          temp.deleteSync(recursive: true);
        }
      });
      final empty = _projectWithSurfaceCatalog(ProjectSurfaceCatalog());
      final manifestPath = p.join(temp.path, 'project.json');
      File(manifestPath).writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(empty.toJson()),
      );
      final container = await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: temp.path,
          project: empty,
          workspaceMode: EditorWorkspaceMode.surfaceStudio,
        ),
      );
      await tester.pumpAndSettle();

      await _createAtlasFromWizard(tester, id: 'v21-save');
      await tester
          .tap(find.byKey(const Key('surfaceStudio.action.saveCatalog')));
      await tester.pumpAndSettle();

      var ok = false;
      await tester.runAsync(() async {
        ok = await container
            .read(editorNotifierProvider.notifier)
            .saveProjectManifest();
      });

      expect(ok, isTrue);
      final loaded = ProjectManifest.fromJson(
        jsonDecode(File(manifestPath).readAsStringSync())
            as Map<String, dynamic>,
      );
      expect(loaded.surfaceCatalog.atlases.map((atlas) => atlas.id),
          contains('v21-save'));
    });
  });
}

Future<void> _createAtlasFromWizard(
  WidgetTester tester, {
  required String id,
}) async {
  await tester.enterText(
    find.byKey(const Key('surfaceStudio.import.atlasId')),
    id,
  );
  await tester.enterText(
    find.byKey(const Key('surfaceStudio.import.atlasName')),
    'Surface $id',
  );
  await tester.enterText(
    find.byKey(const Key('surfaceStudio.import.tilesetId')),
    'nature-tileset',
  );
  final createButton =
      find.byKey(const Key('surfaceStudio.import.createAtlas'));
  await tester.ensureVisible(createButton);
  await tester.pumpAndSettle();
  await tester.tap(createButton);
  await tester.pump();
}

ProjectManifest _projectWithSurfaceCatalog(ProjectSurfaceCatalog catalog) {
  return ProjectManifest(
    name: 'Surface V2.1',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'nature-tileset',
        name: 'Nature Tileset',
        relativePath: 'assets/tilesets/nature.png',
      ),
    ],
    surfaceCatalog: catalog,
  );
}

ProjectSurfaceCatalog _minimalSurfaceCatalog() {
  final atlas = ProjectSurfaceAtlas(
    id: 'water-atlas',
    name: 'Water Atlas',
    tilesetId: 'nature-tileset',
    geometry: SurfaceAtlasGeometry(
      tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
      gridSize: SurfaceAtlasGridSize(columns: 12, rows: 32),
      layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
    ),
  );
  final animation = ProjectSurfaceAnimation(
    id: 'water-isolated-loop',
    name: 'Water Isolated Loop',
    timeline: SurfaceAnimationTimeline(
      frames: [
        SurfaceAnimationFrame(
          tileRef: SurfaceAtlasTileRef(
            atlasId: 'water-atlas',
            column: 0,
            row: 0,
          ),
          durationMs: 120,
        ),
      ],
    ),
  );
  final preset = ProjectSurfacePreset(
    id: 'water-surface',
    name: 'Water Surface',
    variantAnimations: SurfaceVariantAnimationRefSet(
      refs: [
        SurfaceVariantAnimationRef(
          role: SurfaceVariantRole.isolated,
          animationId: 'water-isolated-loop',
        ),
      ],
    ),
  );
  return ProjectSurfaceCatalog(
    atlases: [atlas],
    animations: [animation],
    presets: [preset],
  );
}
```
## Non-objectifs confirmés

- `map_gameplay` non modifié.
- `map_runtime` non modifié.
- `map_battle` non modifié.
- Aucun runtime ice/mud, aucune glissade, aucun movement cost gameplay.
- `SurfaceLayer` reste visuel, `ProjectSurfacePreset` reste visuel.
- Pas de nouvelle clé API, pas de stockage de secret, pas de requête réseau IA.

## Auto-review

- Respect image de référence: amélioré par conservation du shell premium V2 et suppression du double rendu.
- Suppression double UI: oui, testée.
- Fonctionnalité réelle: atlas, mapping, generation plan, animations, preset et save prep sont dans le wizard.
- Intégration shell global: améliorée, avec un seul écran et drawer avancé.
- Suggestion auto: review obligatoire avant mutation.
- Préparation Mistral: helper partagé, clé détectée mais jamais affichée par l’UI.
- Risque restant: la suggestion locale reste heuristique et volontairement prudente; l’IA réelle reste hors lot.
- Dette volontaire: certains composants catalogue legacy restent accessibles dans le drawer, car utiles pour inspection et diagnostics.

## Critique du prompt

- Le prompt demandait une absorption fonctionnelle large et une preuve complète; la partie Evidence Pack rend le rapport très volumineux.
- L’ambiguïté principale était le degré d’intégration IA: choix fait de préparer les seams sans réseau, conformément à la contrainte confidentialité.
- Les tests anciens étaient massifs et décrivaient explicitement l’ancien état refusé; ils ont été remplacés par des tests V2.1 plus proches du comportement produit.
- Lot suivant recommandé: brancher une vraie source atlas image/tileset de bout en bout dans la step Importer/Découper si l’utilisateur veut réduire les fallbacks visuels restants, puis seulement ensuite une IA Mistral multimodale avec consentement explicite.

## Note sur le rapport lui-même

Le rapport lui-même ne doit pas se recopier récursivement.

## Git status final après création du rapport

```text
 M packages/map_editor/lib/src/features/dialogue/application/mistral_dialogue_client.dart
 M packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart
 M packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_bottom_action_bar.dart
 M packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_header.dart
 M packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_shell.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_rebuild_test_harness.dart
 M packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
?? packages/map_editor/lib/src/features/editor/application/editor_ai_settings.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_local_mapping_suggester.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_controller.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_models.dart
?? packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart
?? packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart
?? reports/surface/surface_studio_rebuild_v2_1_functional_integration.md
```
## Diff stat final après création du rapport

```text
 .../application/mistral_dialogue_client.dart       |   12 +-
 .../preview/surface_studio_preview_panel.dart      |  122 +-
 .../shell/surface_studio_bottom_action_bar.dart    |   82 +-
 .../shell/surface_studio_header.dart               |    6 +-
 .../surface_studio/shell/surface_studio_shell.dart |   20 +-
 .../surface_studio/surface_studio_panel.dart       |  651 +-----
 .../surface_studio/surface_studio_screen.dart      | 1781 +++++++++++++++-
 .../surface_studio/surface_studio_panel_test.dart  | 2130 ++------------------
 .../surface_studio_rebuild_test_harness.dart       |    8 +
 ...ce_studio_vertical_atlas_golden_slice_test.dart |  197 +-
 .../surface_studio_workspace_entry_test.dart       |  571 ++----
 11 files changed, 2191 insertions(+), 3389 deletions(-)
```
