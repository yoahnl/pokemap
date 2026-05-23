# Theme-3 — PokeMap UI Component Gallery / Visual Smoke Screen V0 Report

This report outlines the implementation and verification details of **Theme-3 — PokeMap UI Component Gallery / Visual Smoke Screen V0**.

---

## 1. Résumé
In this phase, we constructed a standalone, isolated visual **Component Gallery** showcasing all V0 foundation widgets of the PokeMap design system. The gallery is decoupled from production navigation, editor state management, and `macos_ui` components. It features individual showcases for buttons, icon buttons, badges, cards, panels, toolbar surfaces, empty states, and sidebar items under both **Light** and **Dark** mode, as well as a side-by-side split screen mode for instant theme comparison.

---

## 2. Audit initial
Before starting, we validated the design system widget files created in previous phases:
- Verified that all widgets (`PokeMapButton`, `PokeMapIconButton`, `PokeMapCard`, `PokeMapPanel`, `PokeMapBadge`, `PokeMapSectionHeader`, `PokeMapEmptyState`, `PokeMapToolbarSurface`, and `PokeMapSidebarItem`) reside in `packages/map_editor/lib/src/ui/design_system/` and are correctly exported by `design_system.dart`.
- Inspected the master `main.dart` structure to ensure the custom gallery entrypoint won't conflict with main application resources.

---

## 3. Fichiers créés
- [pokemap_design_system_gallery.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/design_system/gallery/pokemap_design_system_gallery.dart)
- [design_system_gallery_main.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/design_system_gallery_main.dart)
- [pokemap_design_system_gallery_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_design_system_gallery_test.dart)

---

## 4. Fichiers modifiés
None.

---

## 5. Décision sur l’entrypoint dédié
To allow quick local execution without triggering the full map editor or initializing client project state databases (which require mock files), we created an isolated main entrypoint:
`packages/map_editor/lib/design_system_gallery_main.dart`

This runs a dedicated `PokeMapDesignSystemGalleryApp` routing directly to the Component Gallery page. It mirrors the exact production theme configuration, using the platform theme compatibility bridge.

---

## 6. Structure de la galerie
- **Manager Header Bar**: Built using `PokeMapToolbarSurface` containing the gallery title and a toggle group of custom `PokeMapButton`s (Light / Dark / Compare).
- **Comparison Pane Grid**:
  - In **Compare** mode: Splits the screen horizontally into two Expanded columns (Light Mode column on the left and Dark Mode column on the right). Both panes display matching component segments on a scrollable layout, allowing developers to inspect color contrast and alignment differences side-by-side.
  - In **Light / Dark** mode: Shows a full-screen scrollable layout configured for the selected mode.
- **Showcase Cards**:
  - **Buttons**: Variant showcase (Primary, Secondary, Ghost, Success, Danger), sizing (Small, Medium, Large), disabled, loading, and prefix/suffix configurations.
  - **Icon Buttons**: Variants (Ghost, Soft, Danger), selection markers, tooltips, and disabled states.
  - **Badges**: All semantic variants (Neutral, Info, Success, Warning, Error, Narrative, Combat, Map Accent) shown with and without prefix icons.
  - **Cards & Panels**: Cards (Normal, Selected, Clickable with hover states) and Panels (Header, Footer, Double-dividers, layout constraints).
  - **Toolbar Surfaces**: Sample row layout.
  - **Empty States**: Display containing action button triggers.
  - **Sidebar Items**: A vertical sidebar mock folder containing item states.

---

## 7. Comment lancer la galerie manuellement
Developers can launch the component gallery by running:
```bash
cd packages/map_editor
flutter run -t lib/design_system_gallery_main.dart -d macos
```

---

## 8. Tests ajoutés
Added widget tests in `packages/map_editor/test/ui/design_system/pokemap_design_system_gallery_test.dart` verifying:
- Successful rendering under both `PokeMapTheme.light()` and `PokeMapTheme.dark()`.
- Presence of all main component category section headers.
- Presence of specific variant/state widgets (e.g. Success button, Narrative Segment badge, Bounded panel layouts) without layout exceptions.

---

## 9. Commandes lancées avec résultats exacts

```bash
cd packages/map_editor
flutter test test/ui/design_system/
```
**Output:**
```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_sidebar_item_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_sidebar_item_test.dart: PokeMapSidebarItem Tests PokeMapSidebarItem pumps correctly under light & dark theme
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_badge_test.dart: PokeMapBadge Tests PokeMapBadge pumps correctly under light & dark theme for all variants
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_badge_test.dart: PokeMapBadge Tests PokeMapBadge pumps correctly under light & dark theme for all variants
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_badge_test.dart: PokeMapBadge Tests PokeMapBadge pumps correctly under light & dark theme for all variants
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_design_system_gallery_test.dart: PokeMapDesignSystemGallery Widget Tests Gallery pumps successfully under light theme
00:00 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_design_system_gallery_test.dart: PokeMapDesignSystemGallery Widget Tests Gallery pumps successfully under light theme
00:00 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_design_system_gallery_test.dart: PokeMapDesignSystemGallery Widget Tests Gallery pumps successfully under light theme
00:00 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_design_system_gallery_test.dart: PokeMapDesignSystemGallery Widget Tests Gallery pumps successfully under light theme
00:00 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_design_system_gallery_test.dart: PokeMapDesignSystemGallery Widget Tests Gallery pumps successfully under light theme
00:00 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_design_system_gallery_test.dart: PokeMapDesignSystemGallery Widget Tests Gallery pumps successfully under light theme
00:00 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_design_system_gallery_test.dart: PokeMapDesignSystemGallery Widget Tests Gallery pumps successfully under light theme
00:00 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_design_system_gallery_test.dart: PokeMapDesignSystemGallery Widget Tests Gallery pumps successfully under light theme
00:00 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_button_test.dart: PokeMapButton & PokeMapIconButton Tests PokeMapIconButton tooltip is displayed and works with variants
00:00 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_button_test.dart: PokeMapButton & PokeMapIconButton Tests PokeMapIconButton tooltip is displayed and works with variants
00:00 +14: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_design_system_gallery_test.dart: PokeMapDesignSystemGallery Widget Tests Gallery pumps successfully under dark theme
00:00 +15: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_design_system_gallery_test.dart: PokeMapDesignSystemGallery Widget Tests Gallery pumps successfully under dark theme
00:00 +16: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_design_system_gallery_test.dart: PokeMapDesignSystemGallery Widget Tests Gallery pumps successfully under dark theme
00:00 +17: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_design_system_gallery_test.dart: PokeMapDesignSystemGallery Widget Tests Gallery pumps successfully under dark theme
00:00 +18: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_design_system_gallery_test.dart: PokeMapDesignSystemGallery Widget Tests Gallery pumps successfully under dark theme
00:00 +19: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_design_system_gallery_test.dart: PokeMapDesignSystemGallery Widget Tests Gallery displays all main component category sections
00:00 +20: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_design_system_gallery_test.dart: PokeMapDesignSystemGallery Widget Tests Gallery renders widget variants and states correctly without layout exceptions
00:01 +21: All tests passed!
```

```bash
flutter analyze lib/design_system_gallery_main.dart lib/src/ui/design_system/ test/ui/design_system/
```
**Output:**
```text
Analyzing 3 items...                                            
No issues found! (ran in 1.8s)
```

```bash
flutter test test/editor_shell_page_smoke_test.dart
```
**Output:**
```text
00:02 +11: All tests passed!
```

---

## 10. Git status initial
```text
 M packages/map_editor/lib/main.dart
 M packages/map_editor/test/shell_chrome_test_harness.dart
?? packages/map_editor/lib/src/ui/design_system/
?? packages/map_editor/test/ui/design_system/
?? reports/ui/pokemap_theme_1bis_material_root_migration_hardening.md
?? reports/ui/pokemap_theme_2_ui_widgets_foundation.md
?? reports/ui/pokemap_theme_2bis_ui_widgets_foundation_hardening.md
```
*(Note: Git status files from previous turns are already committed dynamically by the system checkpoint.)*

---

## 11. Git status final
```text
?? packages/map_editor/lib/design_system_gallery_main.dart
?? packages/map_editor/lib/src/ui/design_system/gallery/pokemap_design_system_gallery.dart
?? packages/map_editor/test/ui/design_system/pokemap_design_system_gallery_test.dart
?? reports/ui/pokemap_theme_3_component_gallery.md
```

---

## 12. Git diff --stat tracked
*(Empty since no pre-existing tracked files were changed in this phase)*

---

## 13. Liste des fichiers untracked introduits
- `packages/map_editor/lib/design_system_gallery_main.dart`
- `packages/map_editor/lib/src/ui/design_system/gallery/pokemap_design_system_gallery.dart`
- `packages/map_editor/test/ui/design_system/pokemap_design_system_gallery_test.dart`
- `reports/ui/pokemap_theme_3_component_gallery.md`

---

## 14. Contenu complet de tous les fichiers créés/modifiés

### [design_system_gallery_main.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/design_system_gallery_main.dart)
```dart
import 'package:flutter/material.dart';
import 'src/theme/theme.dart';
import 'src/ui/design_system/gallery/pokemap_design_system_gallery.dart';

void main() {
  // Ensure the binding is initialized at the absolute beginning of main()
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const PokeMapDesignSystemGalleryApp());
}

/// Root widget for the isolated PokeMap Design System Component Gallery.
class PokeMapDesignSystemGalleryApp extends StatelessWidget {
  const PokeMapDesignSystemGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PokeMap Design System Gallery',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: PokeMapTheme.light(),
      darkTheme: PokeMapTheme.dark(),
      builder: (context, child) {
        return PokeMapMacosCompatibilityBridge(
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const PokeMapDesignSystemGallery(),
    );
  }
}
```

### [pokemap_design_system_gallery.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/design_system/gallery/pokemap_design_system_gallery.dart)
```dart
import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import '../design_system.dart';

/// Supported viewing modes in the Component Gallery.
enum GalleryThemeMode {
  /// Force Light Mode view.
  light,

  /// Force Dark Mode view.
  dark,

  /// Split dual-column Side-by-Side preview.
  compare,
}

/// A comprehensive visual component gallery for the PokeMap design system.
///
/// Showcases every custom widget (V0 foundation) in all states, variants,
/// and interactive configurations under both light and dark themes.
class PokeMapDesignSystemGallery extends StatefulWidget {
  const PokeMapDesignSystemGallery({super.key});

  @override
  State<PokeMapDesignSystemGallery> createState() => _PokeMapDesignSystemGalleryState();
}

class _PokeMapDesignSystemGalleryState extends State<PokeMapDesignSystemGallery> {
  GalleryThemeMode _viewMode = GalleryThemeMode.compare;

  @override
  Widget build(BuildContext context) {
    // We resolve colors using the parent theme for the gallery manager shell toolbar
    final parentColors = context.pokeMapColors;

    return Scaffold(
      backgroundColor: parentColors.backgroundApp,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gallery Topbar Surface
            PokeMapToolbarSurface(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PokeMap Design System Gallery',
                          style: TextStyle(
                            color: parentColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'V0 Widgets Foundation & hardended layout structures',
                          style: TextStyle(
                            color: parentColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PokeMapButton(
                        onPressed: () => setState(() => _viewMode = GalleryThemeMode.light),
                        variant: _viewMode == GalleryThemeMode.light
                            ? PokeMapButtonVariant.primary
                            : PokeMapButtonVariant.ghost,
                        size: PokeMapButtonSize.small,
                        child: const Text('Light'),
                      ),
                      const SizedBox(width: 8),
                      PokeMapButton(
                        onPressed: () => setState(() => _viewMode = GalleryThemeMode.dark),
                        variant: _viewMode == GalleryThemeMode.dark
                            ? PokeMapButtonVariant.primary
                            : PokeMapButtonVariant.ghost,
                        size: PokeMapButtonSize.small,
                        child: const Text('Dark'),
                      ),
                      const SizedBox(width: 8),
                      PokeMapButton(
                        onPressed: () => setState(() => _viewMode = GalleryThemeMode.compare),
                        variant: _viewMode == GalleryThemeMode.compare
                            ? PokeMapButtonVariant.primary
                            : PokeMapButtonVariant.ghost,
                        size: PokeMapButtonSize.small,
                        child: const Text('Compare'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content Panel Area
            Expanded(
              child: _buildGalleryContentByMode(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryContentByMode() {
    switch (_viewMode) {
      case GalleryThemeMode.light:
        return Theme(
          data: PokeMapTheme.light(),
          child: Builder(
            builder: (context) => Container(
              color: context.pokeMapColors.backgroundApp,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildGalleryWidgetsList(context, isSplit: false),
              ),
            ),
          ),
        );
      case GalleryThemeMode.dark:
        return Theme(
          data: PokeMapTheme.dark(),
          child: Builder(
            builder: (context) => Container(
              color: context.pokeMapColors.backgroundApp,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildGalleryWidgetsList(context, isSplit: false),
              ),
            ),
          ),
        );
      case GalleryThemeMode.compare:
        return LayoutBuilder(
          builder: (context, constraints) {
            // Renders split panes if wide enough, otherwise fall back to vertical stacking
            final useSplitPanes = constraints.maxWidth > 900;

            if (useSplitPanes) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Light Mode Column Pane
                  Expanded(
                    child: Theme(
                      data: PokeMapTheme.light(),
                      child: Builder(
                        builder: (context) => Container(
                          color: context.pokeMapColors.backgroundApp,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildThemeHeaderBanner('LIGHT MODE', Colors.blue.shade700),
                                const SizedBox(height: 20),
                                _buildGalleryWidgetsList(context, isSplit: true),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  VerticalDivider(width: 1, color: parentDividerColor(context)),
                  // Dark Mode Column Pane
                  Expanded(
                    child: Theme(
                      data: PokeMapTheme.dark(),
                      child: Builder(
                        builder: (context) => Container(
                          color: context.pokeMapColors.backgroundApp,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildThemeHeaderBanner('DARK MODE', Colors.purple.shade700),
                                const SizedBox(height: 20),
                                _buildGalleryWidgetsList(context, isSplit: true),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            } else {
              // Stacked comparison for small screens
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Theme(
                      data: PokeMapTheme.light(),
                      child: Builder(
                        builder: (context) => Container(
                          color: context.pokeMapColors.backgroundApp,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildThemeHeaderBanner('LIGHT PREVIEW', Colors.blue.shade700),
                              const SizedBox(height: 20),
                              _buildGalleryWidgetsList(context, isSplit: false),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Theme(
                      data: PokeMapTheme.dark(),
                      child: Builder(
                        builder: (context) => Container(
                          color: context.pokeMapColors.backgroundApp,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildThemeHeaderBanner('DARK PREVIEW', Colors.purple.shade700),
                              const SizedBox(height: 20),
                              _buildGalleryWidgetsList(context, isSplit: false),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        );
    }
  }

  Color parentDividerColor(BuildContext context) {
    return context.pokeMapColors.divider;
  }

  Widget _buildThemeHeaderBanner(String label, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryWidgetsList(BuildContext context, {required bool isSplit}) {
    final colors = context.pokeMapColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Buttons Showcase Section
        _buildSectionWrapper(
          context: context,
          title: 'Buttons (PokeMapButton)',
          description: 'Custom primary, secondary, ghost, success, and danger actions.',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              PokeMapButton(
                onPressed: () {},
                variant: PokeMapButtonVariant.primary,
                size: PokeMapButtonSize.small,
                child: const Text('Primary Small'),
              ),
              PokeMapButton(
                onPressed: () {},
                variant: PokeMapButtonVariant.primary,
                child: const Text('Primary Medium'),
              ),
              PokeMapButton(
                onPressed: () {},
                variant: PokeMapButtonVariant.primary,
                size: PokeMapButtonSize.large,
                child: const Text('Primary Large'),
              ),
              PokeMapButton(
                onPressed: () {},
                variant: PokeMapButtonVariant.secondary,
                child: const Text('Secondary'),
              ),
              PokeMapButton(
                onPressed: () {},
                variant: PokeMapButtonVariant.ghost,
                child: const Text('Ghost Action'),
              ),
              PokeMapButton(
                onPressed: () {},
                variant: PokeMapButtonVariant.success,
                child: const Text('Success'),
              ),
              PokeMapButton(
                onPressed: () {},
                variant: PokeMapButtonVariant.danger,
                child: const Text('Danger'),
              ),
              const PokeMapButton(
                onPressed: null,
                child: Text('Disabled State'),
              ),
              PokeMapButton(
                onPressed: () {},
                isLoading: true,
                child: const Text('Loading...'),
              ),
              PokeMapButton(
                onPressed: () {},
                variant: PokeMapButtonVariant.secondary,
                leading: const Icon(Icons.cloud_upload),
                child: const Text('Upload'),
              ),
              PokeMapButton(
                onPressed: () {},
                variant: PokeMapButtonVariant.primary,
                trailing: const Icon(Icons.arrow_forward),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 2. Icon Buttons Showcase Section
        _buildSectionWrapper(
          context: context,
          title: 'Icon Buttons (PokeMapIconButton)',
          description: 'Compact buttons for secondary tools or grid pickers.',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              PokeMapIconButton(
                onPressed: () {},
                icon: const Icon(Icons.settings),
                tooltip: 'Settings Ghost',
              ),
              PokeMapIconButton(
                onPressed: () {},
                icon: const Icon(Icons.layers),
                variant: PokeMapIconButtonVariant.soft,
                tooltip: 'Layers Soft',
              ),
              PokeMapIconButton(
                onPressed: () {},
                icon: const Icon(Icons.delete),
                variant: PokeMapIconButtonVariant.danger,
                tooltip: 'Delete Item',
              ),
              PokeMapIconButton(
                onPressed: () {},
                icon: const Icon(Icons.brush),
                variant: PokeMapIconButtonVariant.soft,
                isSelected: true,
                tooltip: 'Active Soft Brush',
              ),
              PokeMapIconButton(
                onPressed: () {},
                icon: const Icon(Icons.map),
                variant: PokeMapIconButtonVariant.ghost,
                isSelected: true,
                tooltip: 'Active Ghost Map',
              ),
              const PokeMapIconButton(
                onPressed: null,
                icon: Icon(Icons.lock),
                variant: PokeMapIconButtonVariant.soft,
                tooltip: 'Locked',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 3. Status Badges Section
        _buildSectionWrapper(
          context: context,
          title: 'Status Badges (PokeMapBadge)',
          description: 'Semantic capsule badges mapping engine tags.',
          child: const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PokeMapBadge(label: 'Neutral', variant: PokeMapBadgeVariant.neutral),
              PokeMapBadge(
                label: 'Info',
                variant: PokeMapBadgeVariant.info,
                icon: Icon(Icons.info_outline),
              ),
              PokeMapBadge(
                label: 'Success',
                variant: PokeMapBadgeVariant.success,
                icon: Icon(Icons.check_circle_outline),
              ),
              PokeMapBadge(
                label: 'Warning',
                variant: PokeMapBadgeVariant.warning,
                icon: Icon(Icons.warning_amber),
              ),
              PokeMapBadge(
                label: 'Error',
                variant: PokeMapBadgeVariant.error,
                icon: Icon(Icons.error_outline),
              ),
              PokeMapBadge(
                label: 'Narrative Segment',
                variant: PokeMapBadgeVariant.narrative,
                icon: Icon(Icons.auto_stories),
              ),
              PokeMapBadge(
                label: 'Combat Rule',
                variant: PokeMapBadgeVariant.combat,
                icon: Icon(Icons.bolt),
              ),
              PokeMapBadge(
                label: 'Grid Map Accent',
                variant: PokeMapBadgeVariant.mapAccent,
                icon: Icon(Icons.grid_on),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 4. Cards & Panels Section
        _buildSectionWrapper(
          context: context,
          title: 'Cards & Panels (PokeMapCard / PokeMapPanel)',
          description: 'Containers resolved correctly across brightness presets.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cards Layout Demo
              Row(
                children: [
                  Expanded(
                    child: PokeMapCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Card Standard',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Basic passive item wrapper', style: TextStyle(color: colors.textMuted, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PokeMapCard(
                      selected: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Card Selected',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Uses brand primary outline', style: TextStyle(color: colors.textMuted, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              PokeMapCard(
                onTap: () {},
                child: Center(
                  child: Text(
                    'Clickable Card (Hover me to trigger background highlight)',
                    style: TextStyle(
                      color: colors.brandPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Panel Double-Divider Demo
              SizedBox(
                height: 140,
                child: PokeMapPanel(
                  expandChild: true,
                  header: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Panel Header', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11)),
                        const PokeMapBadge(label: 'V0 Panel', variant: PokeMapBadgeVariant.mapAccent),
                      ],
                    ),
                  ),
                  footer: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text('Panel Footer Actions', style: TextStyle(color: colors.textMuted, fontSize: 9)),
                  ),
                  child: Center(
                    child: Text('Panel Content Area (Scrollable/Expanded)', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 5. Toolbar Surface Section
        _buildSectionWrapper(
          context: context,
          title: 'Toolbar Surfaces (PokeMapToolbarSurface)',
          description: 'A bar that provides solid backgrounds and separator boundaries.',
          child: PokeMapToolbarSurface(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PokeMapIconButton(onPressed: () {}, icon: const Icon(Icons.arrow_back)),
                    const SizedBox(width: 8),
                    Text('Active Document Name', style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                PokeMapButton(
                  onPressed: () {},
                  variant: PokeMapButtonVariant.primary,
                  size: PokeMapButtonSize.small,
                  child: const Text('Save Manifest'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // 6. Empty States Section
        _buildSectionWrapper(
          context: context,
          title: 'Empty States (PokeMapEmptyState)',
          description: 'Centered empty screen layouts containing graphics and prompt triggers.',
          child: PokeMapCard(
            padding: EdgeInsets.zero,
            child: PokeMapEmptyState(
              title: 'No Assets Imported Yet',
              description: 'Import custom grids, PNG map tilesets, or story variables to build your RPG catalog list.',
              icon: const Icon(Icons.file_copy_outlined),
              action: PokeMapButton(
                onPressed: () {},
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                child: const Text('Import Catalog File'),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // 7. Sidebar Items Section
        _buildSectionWrapper(
          context: context,
          title: 'Sidebar Items (PokeMapSidebarItem)',
          description: 'Navigation items optimized for sidebar list hierarchies.',
          child: Container(
            width: isSplit ? double.infinity : 280,
            decoration: BoxDecoration(
              color: colors.surfaceSubtle,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.borderSubtle),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                PokeMapSidebarItem(
                  label: 'General Workspace',
                  icon: const Icon(Icons.dashboard_outlined),
                  onTap: () {},
                ),
                PokeMapSidebarItem(
                  label: 'Map Editor Grid (Active)',
                  icon: const Icon(Icons.grid_view),
                  selected: true,
                  trailing: const PokeMapBadge(label: 'Live', variant: PokeMapBadgeVariant.mapAccent),
                  onTap: () {},
                ),
                PokeMapSidebarItem(
                  label: 'Narrative Studio (New Rules)',
                  icon: const Icon(Icons.movie_creation_outlined),
                  trailing: const Icon(Icons.fiber_new, color: Colors.purpleAccent, size: 16),
                  onTap: () {},
                ),
                const PokeMapSidebarItem(
                  label: 'Locked Content (Disabled)',
                  icon: Icon(Icons.lock_outline),
                  disabled: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionWrapper({
    required BuildContext context,
    required String title,
    required String description,
    required Widget child,
  }) {
    final colors = context.pokeMapColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceBase,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          PokeMapSectionHeader(
            title: title,
            description: description,
          ),
          const SizedBox(height: 12),
          // Divider Line
          Container(
            height: 1,
            color: colors.divider,
          ),
          const SizedBox(height: 16),
          // Child content
          child,
        ],
      ),
    );
  }
}
```

### [pokemap_design_system_gallery_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_design_system_gallery_test.dart)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/gallery/pokemap_design_system_gallery.dart';

void main() {
  group('PokeMapDesignSystemGallery Widget Tests', () {
    Widget buildTestWidget({
      required ThemeData theme,
      required Widget child,
    }) {
      return MaterialApp(
        theme: theme,
        home: Scaffold(
          body: child,
        ),
      );
    }

    testWidgets('Gallery pumps successfully under light theme', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.light(),
          child: const PokeMapDesignSystemGallery(),
        ),
      );

      // Verify header title
      expect(find.text('PokeMap Design System Gallery'), findsOneWidget);
      expect(find.text('Buttons (PokeMapButton)'), findsWidgets);
      expect(find.text('Icon Buttons (PokeMapIconButton)'), findsWidgets);
    });

    testWidgets('Gallery pumps successfully under dark theme', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.dark(),
          child: const PokeMapDesignSystemGallery(),
        ),
      );

      expect(find.text('PokeMap Design System Gallery'), findsOneWidget);
      expect(find.text('Status Badges (PokeMapBadge)'), findsWidgets);
    });

    testWidgets('Gallery displays all main component category sections', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.light(),
          child: const PokeMapDesignSystemGallery(),
        ),
      );

      // Verify the presence of all section headers
      expect(find.text('Buttons (PokeMapButton)'), findsWidgets);
      expect(find.text('Icon Buttons (PokeMapIconButton)'), findsWidgets);
      expect(find.text('Status Badges (PokeMapBadge)'), findsWidgets);
      expect(find.text('Cards & Panels (PokeMapCard / PokeMapPanel)'), findsWidgets);
      expect(find.text('Toolbar Surfaces (PokeMapToolbarSurface)'), findsWidgets);
      expect(find.text('Empty States (PokeMapEmptyState)'), findsWidgets);
      expect(find.text('Sidebar Items (PokeMapSidebarItem)'), findsWidgets);
    });

    testWidgets('Gallery renders widget variants and states correctly without layout exceptions', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.light(),
          child: const PokeMapDesignSystemGallery(),
        ),
      );

      // Verify specific variant/state texts are visible
      expect(find.text('Primary Small'), findsWidgets);
      expect(find.text('Ghost Action'), findsWidgets);
      expect(find.text('Success'), findsWidgets);
      expect(find.text('Secondary'), findsWidgets);
      expect(find.text('Narrative Segment'), findsWidgets);
      expect(find.text('Combat Rule'), findsWidgets);
      expect(find.text('Grid Map Accent'), findsWidgets);
      expect(find.text('No Assets Imported Yet'), findsWidgets);
      expect(find.text('Map Editor Grid (Active)'), findsWidgets);
    });
  });
}
```

---

## 15. Annexe avec le contenu complet de pokemap_badge_test.dart

As requested, below is the complete contents of `packages/map_editor/test/ui/design_system/pokemap_badge_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  group('PokeMapBadge Tests', () {
    Widget buildTestWidget({
      required ThemeData theme,
      required Widget child,
    }) {
      return MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Center(child: child),
        ),
      );
    }

    testWidgets('PokeMapBadge pumps correctly under light & dark theme for all variants', (tester) async {
      for (final variant in PokeMapBadgeVariant.values) {
        // Light Mode
        await tester.pumpWidget(
          buildTestWidget(
            theme: PokeMapTheme.light(),
            child: PokeMapBadge(
              label: 'Tag $variant',
              variant: variant,
              icon: const Icon(Icons.label),
            ),
          ),
        );
        expect(find.text('Tag $variant'), findsOneWidget);
        expect(find.byType(Icon), findsOneWidget);

        // Dark Mode
        await tester.pumpWidget(
          buildTestWidget(
            theme: PokeMapTheme.dark(),
            child: PokeMapBadge(
              label: 'Tag $variant',
              variant: variant,
            ),
          ),
        );
        expect(find.text('Tag $variant'), findsOneWidget);
      }
    });

    testWidgets('PokeMapBadge.mapAccent uses colors.mapAccent correctly', (tester) async {
      late BuildContext capturedContext;
      
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                capturedContext = context;
                return const PokeMapBadge(
                  label: 'Map Item',
                  variant: PokeMapBadgeVariant.mapAccent,
                );
              },
            ),
          ),
        ),
      );

      final badgeContainerFinder = find.byType(Container);
      expect(badgeContainerFinder, findsOneWidget);

      final expectedMapColor = capturedContext.pokeMapColors.mapAccent;
      
      // The text inside should have the mapAccent color
      final textFinder = find.text('Map Item');
      expect(textFinder, findsOneWidget);
      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.style?.color, equals(expectedMapColor));
    });
  });
}
```

---

## 16. Auto-review critique
- The gallery is cleanly organized into sections, displaying real instances of each component in multiple variants/states.
- The `GalleryThemeMode.compare` layout builder makes theme auditing fast and simple, displaying light and dark panels side-by-side or stacked on narrow displays.
- Static analysis is completely clean, and new test coverage confirms proper rendering.

---

## 17. Limites restantes
- Does not test window resizing on macOS explicitly in automated checks.
- Interactive widgets inside the gallery do not bind to dynamic mockup variables (changing properties dynamically, e.g. typing text into custom inputs).

---

## 18. Prochaine étape recommandée
We recommend moving forward with **Theme-4 — Sidebar Migration V0** to begin actual layout migration in the production shell.
