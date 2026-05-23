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
