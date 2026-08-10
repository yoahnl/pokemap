import 'package:flutter/material.dart';

import '../../../ui/design_system/design_system.dart';
import '../application/personalization_preview_surface_descriptor.dart';

enum PersonalizationSceneNavigationLayout { list, rail, horizontal }

class PersonalizationSceneNavigation extends StatelessWidget {
  const PersonalizationSceneNavigation({
    super.key,
    required this.selectedScene,
    required this.onSceneSelected,
    required this.layout,
  });

  final PersonalizationStudioScene selectedScene;
  final ValueChanged<PersonalizationStudioScene> onSceneSelected;
  final PersonalizationSceneNavigationLayout layout;

  @override
  Widget build(BuildContext context) => switch (layout) {
    PersonalizationSceneNavigationLayout.list => PokeMapPanel(
      key: const ValueKey<String>('personalization-studio-navigation-list'),
      expandChild: true,
      padding: const EdgeInsets.all(10),
      child: ListView(children: _items()),
    ),
    PersonalizationSceneNavigationLayout.rail => PokeMapPanel(
      key: const ValueKey<String>('personalization-studio-navigation-rail'),
      expandChild: true,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: ListView(children: _items(collapsed: true)),
    ),
    PersonalizationSceneNavigationLayout.horizontal => PokeMapPanel(
      key: const ValueKey<String>(
        'personalization-studio-navigation-horizontal',
      ),
      padding: const EdgeInsets.all(8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            for (final descriptor in personalizationPreviewSurfaceDescriptors)
              SizedBox(
                width: 190,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _item(descriptor, showSubtitle: false),
                ),
              ),
          ],
        ),
      ),
    ),
  };

  List<Widget> _items({bool collapsed = false}) => <Widget>[
    for (final descriptor in personalizationPreviewSurfaceDescriptors)
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _item(descriptor, collapsed: collapsed),
      ),
  ];

  Widget _item(
    PersonalizationStudioSceneDescriptor descriptor, {
    bool collapsed = false,
    bool showSubtitle = true,
  }) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 48),
    child: PokeMapSidebarItem(
      key: ValueKey<String>(
        'personalization-studio-scene-${descriptor.surface.name}',
      ),
      label: descriptor.label,
      subtitle: collapsed || !showSubtitle
          ? null
          : _description(descriptor.surface),
      subtitleMaxLines: 2,
      growForTextScale: true,
      collapsed: collapsed,
      selected: selectedScene == descriptor.surface,
      icon: Icon(_icon(descriptor.surface), size: 20),
      onTap: () => onSceneSelected(descriptor.surface),
    ),
  );
}

String _description(PersonalizationStudioScene scene) => switch (scene) {
  PersonalizationStudioScene.globalStyle => 'Définissez l’identité visuelle',
  PersonalizationStudioScene.title => 'Votre écran d’accueil',
  PersonalizationStudioScene.intro => 'Introduction et mise en contexte',
  PersonalizationStudioScene.pause => 'Menu de pause en jeu',
  PersonalizationStudioScene.dialogue => 'Bulle et présentation des dialogues',
  PersonalizationStudioScene.battle => 'Interface des combats',
};

IconData _icon(PersonalizationStudioScene scene) => switch (scene) {
  PersonalizationStudioScene.globalStyle => Icons.public_rounded,
  PersonalizationStudioScene.title => Icons.image_outlined,
  PersonalizationStudioScene.intro => Icons.movie_outlined,
  PersonalizationStudioScene.pause => Icons.pause_rounded,
  PersonalizationStudioScene.dialogue => Icons.chat_bubble_rounded,
  PersonalizationStudioScene.battle => Icons.sports_martial_arts_rounded,
};
