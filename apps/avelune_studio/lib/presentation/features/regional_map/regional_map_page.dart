import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:map_core/map_core.dart';

import '../../../features/regional_map/application/regional_map_controller.dart';
import '../../../platform/rendering/regional_map_image_decoder.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/dialogs/studio_review_dialog.dart';
import '../../shared/widgets/feedback/studio_empty_state.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/layout/studio_asset_preview.dart';
import '../../shared/widgets/layout/studio_page_header.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'regional_map_flight_destination.dart';
import 'regional_map_link_dialog.dart';
import 'regional_map_linked_maps.dart';
import 'regional_map_place_summary.dart';
import '../narrative/narrative_name_dialog.dart';

class RegionalMapPage extends StatefulWidget {
  const RegionalMapPage({super.key, required this.controller});
  final RegionalMapController controller;
  @override
  State<RegionalMapPage> createState() => _RegionalMapPageState();
}

class _RegionalMapPageState extends State<RegionalMapPage> {
  RegionalMapController get owner => widget.controller;
  Object? _imageKey;
  Future<({Uint8List bytes, int width, int height})?>? _image;

  Future<({Uint8List bytes, int width, int height})?> _loadImage(String path) =>
      decodeRegionalMapImage(owner.port, path);

  Future<void> _createRegion() async {
    final name = await askNarrativeName(context, 'Créer une région');
    if (mounted && name != null) owner.createRegion(name);
  }

  Future<void> _createPoint() async {
    final project = owner.source?.project;
    if (project == null || project.maps.isEmpty) return;
    final link = await askRegionalMapLink(
      context,
      title: 'Créer un lieu',
      mapLabel: 'Carte liée à la visite',
      confirmLabel: 'Créer',
      project: project,
      asksName: true,
    );
    if (mounted && link != null) owner.createPoint(link.name, link.mapId);
  }

  Future<void> _enableFlight(ProjectRegionPointOfInterest point) async {
    final project = owner.source?.project;
    if (project == null) return;
    final link = await askRegionalMapLink(
      context,
      title: 'Autoriser Vol vers ce lieu',
      mapLabel: 'Carte d’arrivée',
      confirmLabel: 'Autoriser Vol',
      project: project,
      suggestedMapId: point.mapIds.firstOrNull,
    );
    if (mounted && link != null) {
      owner.editPoint(destination: ProjectRegionDestination(mapId: link.mapId));
    }
  }

  Future<void> _delete(String label, VoidCallback remove) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StudioReviewDialog(
        title: 'Supprimer $label ?',
        content: const Text(
          'La suppression restera un brouillon jusqu’à son enregistrement.',
        ),
        confirmLabel: 'Supprimer',
        onConfirmed: () => Navigator.pop(context, true),
        onCancelled: () => Navigator.pop(context, false),
      ),
    );
    if (mounted && accepted == true) remove();
  }

  @override
  Widget build(BuildContext context) {
    final region = owner.region, point = owner.point, source = owner.source;
    final imageKey = (region?.imagePath, source?.revision);
    if (_imageKey != imageKey) {
      _imageKey = imageKey;
      _image = region?.imagePath == null
          ? null
          : _loadImage(region!.imagePath!);
    }
    return Column(
      children: [
        StudioPageHeader(
          title: 'Carte régionale',
          description: 'Illustrez vos régions, placez leurs lieux et choisissez les arrivées de Vol.',
          actions: [
            StudioButton(
              label: 'Créer une région',
              icon: Icons.add,
              onPressed: owner.busy || source == null ? null : _createRegion,
            ),
            StudioTool(
              label: 'Annuler la dernière modification',
              icon: Icons.undo,
              onPressed: owner.canUndo ? owner.undo : null,
            ),
            StudioButton(
              label: 'Abandonner',
              secondary: true,
              onPressed: owner.busy || !owner.dirty ? null : owner.discard,
            ),
            StudioButton(
              label: 'Enregistrer',
              icon: Icons.save_outlined,
              onPressed: owner.busy || !owner.dirty
                  ? null
                  : () => owner.saveAll(),
            ),
          ],
        ),
        if (owner.error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: StudioNotice(owner.error!, isError: true),
          ),
        Expanded(
          child: source == null
              ? const StudioEmptyState(
                  title: 'Chargement de la carte régionale',
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      StudioPanel(
                        title: 'Région',
                        children: [
                          StudioSelect(
                            label: 'Région',
                            value: region?.id,
                            options: {
                              for (final region in owner.catalog.regions)
                                region.id: region.label,
                            },
                            onChanged: owner.busy ? null : owner.selectRegion,
                          ),
                          if (region != null) ...[
                            StudioDraftField(
                              label: 'Nom de la région',
                              value: owner.regionLabel,
                              enabled: !owner.busy,
                              onChanged: (value) =>
                                  owner.editRegion(label: value),
                            ),
                            StudioSelect(
                              label: 'Image de la région',
                              value: region.imagePath,
                              options: source.images,
                              onChanged: owner.busy
                                  ? null
                                  : (path) => owner.editRegion(imagePath: path),
                            ),
                            if (source.images.isEmpty)
                              const StudioNotice(
                                'Ajoutez une image dans la bibliothèque Ressources avant de placer les lieux.',
                              ),
                            StudioButton(
                              label: 'Supprimer la région',
                              secondary: true,
                              onPressed: owner.busy
                                  ? null
                                  : () => _delete(
                                      region.label,
                                      owner.deleteRegion,
                                    ),
                            ),
                          ] else
                            const StudioEmptyState(
                              title: 'Créez votre première région',
                              icon: Icons.public,
                            ),
                        ],
                      ),
                      if (region != null) ...[
                        const SizedBox(height: 16),
                        StudioPanel(
                          title: 'Lieux',
                          actions: [
                            StudioButton(
                              label: 'Créer un lieu',
                              icon: Icons.add,
                              onPressed:
                                  owner.busy ||
                                      region.imagePath == null ||
                                      source.project.maps.isEmpty
                                  ? null
                                  : _createPoint,
                            ),
                          ],
                          children: [
                            StudioSelect(
                              label: 'Lieu',
                              value: point?.id,
                              options: {
                                for (final point in owner.points)
                                  point.id: point.label,
                              },
                              onChanged: owner.busy ? null : owner.selectPoint,
                            ),
                            if (owner.points.length > 1)
                              RegionalPlaceFinder(
                                points: owner.points,
                                project: source.project,
                                selectedId: point?.id,
                                onSelected: owner.busy
                                    ? null
                                    : owner.selectPoint,
                              ),
                            const SizedBox(height: 12),
                            StudioAssetPreview(
                              height: 340,
                              child: _image == null
                                  ? const StudioEmptyState(
                                      title: 'Choisissez une image de région',
                                      icon: Icons.image_outlined,
                                    )
                                  : FutureBuilder(
                                      future: _image,
                                      builder: (context, snapshot) {
                                        final image = snapshot.data;
                                        if (snapshot.connectionState !=
                                            ConnectionState.done) {
                                          return const StudioEmptyState(
                                            key: ValueKey(
                                              'regional-image-loading',
                                            ),
                                            title: 'Chargement de l’image…',
                                            icon: Icons.hourglass_empty,
                                          );
                                        }
                                        if (snapshot.hasError) {
                                          return StudioEmptyState(
                                            key: const ValueKey(
                                              'regional-image-error',
                                            ),
                                            title: 'Image illisible',
                                            description:
                                                'Lecture ou décodage impossible (${snapshot.error}). Choisissez une autre image.',
                                          );
                                        }
                                        if (image == null) {
                                          return const StudioEmptyState(
                                            key: ValueKey(
                                              'regional-image-missing',
                                            ),
                                            title: 'Image absente',
                                            description: 'Le fichier référencé est introuvable. Choisissez une image de la bibliothèque.',
                                          );
                                        }
                                        return LayoutBuilder(
                                          builder: (context, bounds) {
                                            final fit = applyBoxFit(
                                              BoxFit.contain,
                                              Size(
                                                image.width.toDouble(),
                                                image.height.toDouble(),
                                              ),
                                              bounds.biggest,
                                            ).destination;
                                            return SizedBox(
                                              width: fit.width,
                                              height: fit.height,
                                              child: GestureDetector(
                                                key: const ValueKey(
                                                  'regional-map-image',
                                                ),
                                                onTapDown:
                                                    owner.busy || point == null
                                                    ? null
                                                    : (
                                                        event,
                                                      ) => owner.placePoint(
                                                        dx: event
                                                            .localPosition
                                                            .dx,
                                                        dy: event
                                                            .localPosition
                                                            .dy,
                                                        width: fit.width,
                                                        height: fit.height,
                                                      ),
                                                child: Stack(
                                                  clipBehavior: Clip.none,
                                                  children: [
                                                    Positioned.fill(
                                                      child: Image.memory(
                                                        image.bytes,
                                                        fit: BoxFit.fill,
                                                        filterQuality:
                                                            region.sampling ==
                                                                ProjectMenuImageSampling
                                                                    .pixelArt
                                                            ? FilterQuality.none
                                                            : FilterQuality
                                                                  .medium,
                                                      ),
                                                    ),
                                                    for (final marker
                                                        in owner.points)
                                                      Positioned(
                                                        left:
                                                            marker.u *
                                                                fit.width -
                                                            16,
                                                        top:
                                                            marker.v *
                                                                fit.height -
                                                            16,
                                                        child: RawGestureDetector(
                                                          gestures: owner.busy
                                                              ? const {}
                                                              : {
                                                                  EagerGestureRecognizer:
                                                                      GestureRecognizerFactoryWithHandlers<
                                                                        EagerGestureRecognizer
                                                                      >(
                                                                        EagerGestureRecognizer
                                                                            .new,
                                                                        (_) {},
                                                                      ),
                                                                },
                                                          child: Listener(
                                                            onPointerDown:
                                                                owner.busy
                                                                ? null
                                                                : (_) => owner
                                                                      .selectPoint(
                                                                        marker
                                                                            .id,
                                                                      ),
                                                            onPointerMove:
                                                                owner.busy
                                                                ? null
                                                                : (event) {
                                                                    final selected =
                                                                        owner
                                                                            .point;
                                                                    if (selected
                                                                            ?.id !=
                                                                        marker
                                                                            .id) {
                                                                      return;
                                                                    }
                                                                    owner.dragPoint(
                                                                      dx: event
                                                                          .delta
                                                                          .dx,
                                                                      dy: event
                                                                          .delta
                                                                          .dy,
                                                                      width: fit
                                                                          .width,
                                                                      height: fit
                                                                          .height,
                                                                    );
                                                                  },
                                                            child: StudioTool(
                                                              label:
                                                                  marker.label,
                                                              icon: Icons
                                                                  .location_on,
                                                              selected:
                                                                  marker.id ==
                                                                  point?.id,
                                                              onPressed:
                                                                  owner.busy
                                                                  ? null
                                                                  : () => owner
                                                                        .selectPoint(
                                                                          marker
                                                                              .id,
                                                                        ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                            ),
                            if (point != null) ...[
                              Text(
                                '${regionalPlacePosition(point)}. Cliquez sur l’image ou faites glisser le repère pour le déplacer.',
                                key: const ValueKey('regional-place-position'),
                              ),
                              StudioDraftField(
                                label: 'Nom du lieu',
                                value: owner.pointLabel,
                                enabled: !owner.busy,
                                onChanged: (value) =>
                                    owner.editPoint(label: value),
                              ),
                              Text(
                                '${regionalPlaceVisibility(point)} · ${regionalPlaceFlight(point, source.project)}',
                                key: const ValueKey('regional-place-summary'),
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              StudioSelect(
                                label: 'Visibilité du lieu',
                                value: point.visibility.name,
                                options: const {
                                  'always': 'Toujours visible',
                                  'discoveredOnly': 'Après découverte',
                                  'hidden': 'Masqué',
                                },
                                onChanged: owner.busy
                                    ? null
                                    : (value) => owner.editPoint(
                                        visibility: ProjectRegionPointVisibility
                                            .values
                                            .byName(value),
                                      ),
                              ),
                              StudioSelect(
                                label: 'Découverte',
                                value: point.discovery.name,
                                options: const {
                                  'onMapVisit': 'Après visite d’une carte liée',
                                  'always': 'Connu dès le départ',
                                },
                                onChanged: owner.busy
                                    ? null
                                    : (value) => owner.editPoint(
                                        discovery: ProjectRegionPointDiscovery
                                            .values
                                            .byName(value),
                                      ),
                              ),
                              RegionalMapLinkedMaps(
                                key: ValueKey('regional-linked-${point.id}'),
                                project: source.project,
                                mapIds: point.mapIds,
                                discovery: point.discovery,
                                busy: owner.busy,
                                onChanged: (ids) =>
                                    owner.editPoint(mapIds: ids),
                              ),
                              RegionalMapFlightDestination(
                                owner: owner,
                                point: point,
                                onEnable: () => _enableFlight(point),
                              ),
                              StudioButton(
                                label: 'Supprimer le lieu',
                                secondary: true,
                                onPressed: owner.busy
                                    ? null
                                    : () => _delete(
                                        point.label,
                                        owner.deletePoint,
                                      ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
