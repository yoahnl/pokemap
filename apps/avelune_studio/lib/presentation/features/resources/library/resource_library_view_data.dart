import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart' show ResourceLibraryRole;

enum ResourceLibraryCategory {
  vegetation('Végétation', Icons.eco_outlined),
  ground('Sols', Icons.layers_outlined),
  paths('Chemins', Icons.route_outlined),
  water('Eau', Icons.waves),
  relief('Reliefs et parois', Icons.terrain_outlined),
  buildings('Bâtiments', Icons.apartment_outlined),
  structures('Structures', Icons.fence_outlined),
  furniture('Mobilier', Icons.chair_outlined),
  objects('Objets', Icons.category_outlined),
  characters('Personnages', Icons.person_outline),
  environments('Environnements', Icons.landscape_outlined),
  images('Images', Icons.image_outlined, media: true),
  models('Modèles 3D', Icons.view_in_ar_outlined, media: true),
  video('Vidéos', Icons.movie_outlined, media: true),
  audio('Sons et musiques', Icons.music_note_outlined, media: true),
  effects('Effets visuels', Icons.auto_awesome_outlined, media: true);

  const ResourceLibraryCategory(this.label, this.icon, {this.media = false});

  final String label;
  final IconData icon;
  final bool media;
}

enum ResourceLibraryDimension {
  twoDimensional('2D'),
  threeDimensional('3D'),
  media('Média');

  const ResourceLibraryDimension(this.label);

  final String label;
}

enum ResourceLibraryDimensionStatus { ready, loading, unavailable }

enum ResourceLibraryScope {
  project('Tout le projet'),
  used('Sur la carte'),
  exclusive('Uniquement sur cette carte');

  const ResourceLibraryScope(this.label);

  final String label;
}

enum ResourceLibrarySort {
  project('Ordre du projet'),
  alphabetical('Nom croissant'),
  reverseAlphabetical('Nom décroissant');

  const ResourceLibrarySort(this.label);

  final String label;
}

enum ResourceLibrarySection { library, workshops }

typedef ResourceLibraryWorkshopAction = ({
  String label,
  IconData icon,
  VoidCallback open,
});

typedef ResourceLibraryWorkshopsBuilder = Widget Function(
  VoidCallback back,
  Future<bool> Function(String)? openMap,
);

typedef ResourceLibraryRelationsView = ({
  List<ResourceLibraryItemView> sources,
  List<ResourceLibraryItemView>? consumers,
});

typedef ResourceLibraryNavigation = ({
  String? revision,
  Future<void>? mapUsagesReady,
  ResourceLibraryItemView? Function(String) item,
  Future<ResourceLibraryRelationsView?> Function(String)? loadRelations,
  Future<bool> Function(String)? openMap,
});

@immutable
class ResourceLibraryItemView {
  const ResourceLibraryItemView({
    required this.id,
    required this.name,
    required this.category,
    required this.type,
    required this.dimension,
    this.compatibleDimensions = const {},
    this.usedOn = const {},
    this.art,
    this.description,
    this.collision,
    this.animationCount,
    this.sourceId,
    this.role = ResourceLibraryRole.standard,
    this.familyIds = const [],
    this.familyPath,
    this.mapId,
    this.searchText,
    this.placement,
    this.canDuplicate = true,
  });

  final String id;
  final String name;
  final ResourceLibraryCategory category;
  final String type;
  final ResourceLibraryDimension? dimension;
  final Set<ResourceLibraryDimension> compatibleDimensions;
  final Set<String>? usedOn;
  final Widget? art;
  final String? description;
  final String? collision;
  final int? animationCount;
  final String? sourceId;
  final ResourceLibraryRole role;
  final List<String> familyIds;
  final String? familyPath;
  final String? mapId;
  final String? searchText;
  final String? placement;
  final bool canDuplicate;

  bool matchesDimension(ResourceLibraryDimension value) =>
      dimension == value || compatibleDimensions.contains(value);

  String? get dimensionLabel =>
      dimension?.label ?? (compatibleDimensions.length == 2 ? '2D / 3D' : null);

  String usageLabel(Map<String, String> maps) {
    final usage = usedOn;
    if (usage == null) {
      if (mapId == null) return 'Commune au projet';
      final map = maps[mapId];
      return map == null ? 'Réservée à une carte' : 'Réservée à $map';
    }
    return switch (usage.length) {
      0 => 'Pas encore utilisée',
      1 => maps[usage.single] ?? '1 carte',
      final count => '$count cartes',
    };
  }
}
