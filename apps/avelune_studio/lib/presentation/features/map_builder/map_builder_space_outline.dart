import 'package:flutter/material.dart';

import 'package:avelune_studio/presentation/features/map_builder/map_builder_space.dart';

const mapBuilderUnavailable = 'Pas encore disponible dans le nouveau Studio';

class MapBuilderSpaceOutline {
  const MapBuilderSpaceOutline({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.rubrics,
    required this.note,
    required this.inspectorEyebrow,
    required this.inspectorTitle,
    required this.inspectorHint,
    this.addLabel,
    this.searchHint,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final List<MapBuilderRubric> rubrics;
  final String? addLabel;
  final String? searchHint;
  final (String, String) note;
  final String inspectorEyebrow;
  final String inspectorTitle;
  final String inspectorHint;
}

class MapBuilderRubric {
  const MapBuilderRubric(this.icon, this.label, this.detail);

  final IconData icon;
  final String label;
  final String detail;
}

MapBuilderSpaceOutline? mapBuilderSpaceOutline(MapBuilderSpace space) =>
    switch (space) {
      MapBuilderSpace.construction => null,
      MapBuilderSpace.gameplay => const MapBuilderSpaceOutline(
        eyebrow: 'CARTE ACTIVE',
        title: 'Rendre la carte jouable',
        subtitle: 'Parcours, accès et rencontres.',
        rubrics: [
          MapBuilderRubric(
            Icons.link,
            'Connexions et passages',
            'Cartes voisines, portes et escaliers',
          ),
          MapBuilderRubric(
            Icons.directions_walk,
            'Déplacements',
            'Obstacles, rebords et surf',
          ),
          MapBuilderRubric(
            Icons.grass,
            'Rencontres sauvages',
            'Herbes, grottes et eau',
          ),
          MapBuilderRubric(
            Icons.flag_outlined,
            'Départs et arrivées',
            'Où le joueur apparaît',
          ),
          MapBuilderRubric(
            Icons.shield_outlined,
            'Objets utilitaires',
            'Arbres à couper, rochers',
          ),
        ],
        addLabel: 'Ajouter une liaison',
        searchHint: 'Rechercher un élément…',
        note: (
          'Jeu : parcours, accès et rencontres.',
          'Les comportements narratifs restent dans Scénario.',
        ),
        inspectorEyebrow: 'RÈGLES DE JEU',
        inspectorTitle: 'Sélectionnez un élément',
        inspectorHint:
            'Sélectionnez-le sur la carte ou dans la liste. Vous pourrez '
            'aussi en ajouter un.',
      ),
      MapBuilderSpace.story => const MapBuilderSpaceOutline(
        eyebrow: 'SCÉNARIO',
        title: 'Éléments de jeu',
        subtitle: 'Ce qui se passe sur cette carte.',
        rubrics: [
          MapBuilderRubric(
            Icons.person_outline,
            'Personnages',
            'Habitants, dresseurs, rivaux',
          ),
          MapBuilderRubric(
            Icons.chat_bubble_outline,
            'Objets interactifs',
            'Panneaux, objets à ramasser',
          ),
          MapBuilderRubric(
            Icons.crop_square,
            'Zones',
            'Déclencher une scène en entrant',
          ),
          MapBuilderRubric(
            Icons.outlined_flag,
            'Carte et résultats',
            'Ce qui arrive en entrant sur la carte',
          ),
        ],
        addLabel: 'Ajouter un élément',
        searchHint: 'Un personnage, une zone…',
        note: (
          'Scénario : personnages et événements.',
          'Les passages et rencontres restent dans Jeu.',
        ),
        inspectorEyebrow: 'ÉVÉNEMENT',
        inspectorTitle: 'Aucun élément sélectionné',
        inspectorHint:
            'Sélectionnez un élément sur la carte ou dans la liste pour '
            'afficher son comportement et ses propriétés.',
      ),
      MapBuilderSpace.ambiance => const MapBuilderSpaceOutline(
        eyebrow: 'CARTE ACTIVE',
        title: 'Ambiance du lieu',
        subtitle: 'Donner une atmosphère à la carte.',
        rubrics: [
          MapBuilderRubric(
            Icons.wb_twilight,
            'Jour et nuit',
            'Hérité du projet ou propre à la carte',
          ),
          MapBuilderRubric(
            Icons.cloud_outlined,
            'Météo',
            'Ciel, pluie et précipitations',
          ),
          MapBuilderRubric(
            Icons.auto_awesome_outlined,
            'Effets visuels',
            'Lumières, brume, particules',
          ),
          MapBuilderRubric(
            Icons.music_note_outlined,
            'Musique',
            'Choix de la carte',
          ),
        ],
        note: (
          'Réglages permanents du lieu.',
          'Les changements temporaires restent gérés par les scènes.',
        ),
        inspectorEyebrow: 'AMBIANCE DE LA CARTE',
        inspectorTitle: 'Choisissez une rubrique',
        inspectorHint:
            'Jour et nuit, météo, effets visuels ou musique : le réglage '
            'choisi s’affichera ici.',
      ),
    };
