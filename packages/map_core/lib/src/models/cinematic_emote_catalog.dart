import 'package:meta/meta.dart' show immutable;

const cinematicEmoteDefaultReactionsAtlasId = 'defaultReactions';
const cinematicEmoteNeutralBubblesAtlasId = 'neutralBubbles';
const cinematicEmoteDefaultReactionsAssetKey =
    'assets/cinematics/emotes/emotions.png';
const cinematicEmoteNeutralBubblesAssetKey =
    'assets/cinematics/emotes/emotions2.png';
const cinematicDefaultActorEmoteId = 'exclamation';

@immutable
final class CinematicEmoteAtlas {
  const CinematicEmoteAtlas({
    required this.id,
    required this.label,
    required this.assetKey,
    required this.width,
    required this.height,
    required this.frameWidth,
    required this.frameHeight,
  });

  final String id;
  final String label;
  final String assetKey;
  final int width;
  final int height;
  final int frameWidth;
  final int frameHeight;
}

@immutable
final class CinematicEmoteFrameRect {
  const CinematicEmoteFrameRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int x;
  final int y;
  final int width;
  final int height;

  bool fitsInside(CinematicEmoteAtlas atlas) {
    return x >= 0 &&
        y >= 0 &&
        width > 0 &&
        height > 0 &&
        x + width <= atlas.width &&
        y + height <= atlas.height;
  }
}

@immutable
final class CinematicEmoteCatalogEntry {
  const CinematicEmoteCatalogEntry({
    required this.id,
    required this.label,
    required this.description,
    required this.atlasId,
    required this.frame,
    this.secondFrame,
  });

  final String id;
  final String label;
  final String description;
  final String atlasId;
  final CinematicEmoteFrameRect frame;

  /// Seconde image de l'emote, quand l'atlas en fournit une.
  ///
  /// Les atlas livrés dessinent chaque concept sur deux cases voisines qui ne
  /// diffèrent que de quelques dizaines de pixels : ce sont les deux images
  /// d'une animation, pas deux emotes distinctes. Le catalogue ne modélisait
  /// qu'une case, si bien que la moitié du dessin était inatteignable et que
  /// plusieurs identifiants pointaient sur l'image 2 du concept voisin.
  final CinematicEmoteFrameRect? secondFrame;

  /// Images à jouer dans l'ordre, la première toujours présente.
  List<CinematicEmoteFrameRect> get frames => <CinematicEmoteFrameRect>[
        frame,
        ?secondFrame,
      ];

  bool get isAnimated => secondFrame != null;
}

const cinematicEmoteAtlases = <CinematicEmoteAtlas>[
  CinematicEmoteAtlas(
    id: cinematicEmoteDefaultReactionsAtlasId,
    label: 'Réactions',
    assetKey: cinematicEmoteDefaultReactionsAssetKey,
    width: 128,
    height: 48,
    frameWidth: 16,
    frameHeight: 16,
  ),
  CinematicEmoteAtlas(
    id: cinematicEmoteNeutralBubblesAtlasId,
    label: 'Bulles neutres',
    assetKey: cinematicEmoteNeutralBubblesAssetKey,
    width: 128,
    height: 48,
    frameWidth: 16,
    frameHeight: 16,
  ),
];

const cinematicEmoteCatalog = <CinematicEmoteCatalogEntry>[
  CinematicEmoteCatalogEntry(
    id: cinematicDefaultActorEmoteId,
    label: 'Surprise',
    description: 'Réaction forte ou découverte soudaine.',
    atlasId: cinematicEmoteDefaultReactionsAtlasId,
    frame: CinematicEmoteFrameRect(x: 0, y: 0, width: 16, height: 16),
    secondFrame:
        CinematicEmoteFrameRect(x: 16, y: 0, width: 16, height: 16),
  ),
  CinematicEmoteCatalogEntry(
    id: 'idea',
    label: 'Idée',
    description: 'Compréhension ou idée soudaine.',
    atlasId: cinematicEmoteDefaultReactionsAtlasId,
    frame: CinematicEmoteFrameRect(x: 32, y: 0, width: 16, height: 16),
    secondFrame:
        CinematicEmoteFrameRect(x: 48, y: 0, width: 16, height: 16),
  ),
  CinematicEmoteCatalogEntry(
    id: 'talk',
    label: 'Parole',
    description: 'Le personnage prend la parole.',
    atlasId: cinematicEmoteDefaultReactionsAtlasId,
    frame: CinematicEmoteFrameRect(x: 64, y: 0, width: 16, height: 16),
    secondFrame:
        CinematicEmoteFrameRect(x: 80, y: 0, width: 16, height: 16),
  ),
  CinematicEmoteCatalogEntry(
    id: 'anger',
    label: 'Colère',
    description: 'Agacement ou colère courte.',
    atlasId: cinematicEmoteDefaultReactionsAtlasId,
    frame: CinematicEmoteFrameRect(x: 96, y: 0, width: 16, height: 16),
    secondFrame:
        CinematicEmoteFrameRect(x: 112, y: 0, width: 16, height: 16),
  ),
  CinematicEmoteCatalogEntry(
    id: 'alert',
    label: 'Alerte',
    description: 'Attention immédiate.',
    atlasId: cinematicEmoteDefaultReactionsAtlasId,
    frame: CinematicEmoteFrameRect(x: 0, y: 16, width: 16, height: 16),
    secondFrame:
        CinematicEmoteFrameRect(x: 16, y: 16, width: 16, height: 16),
  ),
  CinematicEmoteCatalogEntry(
    id: 'music',
    label: 'Musique',
    description: 'Chant, joie ou note musicale.',
    atlasId: cinematicEmoteDefaultReactionsAtlasId,
    frame: CinematicEmoteFrameRect(x: 32, y: 16, width: 16, height: 16),
    secondFrame:
        CinematicEmoteFrameRect(x: 48, y: 16, width: 16, height: 16),
  ),
  CinematicEmoteCatalogEntry(
    id: 'sad',
    label: 'Tristesse',
    description: 'Abattement ou déception.',
    atlasId: cinematicEmoteDefaultReactionsAtlasId,
    frame: CinematicEmoteFrameRect(x: 64, y: 16, width: 16, height: 16),
    secondFrame:
        CinematicEmoteFrameRect(x: 80, y: 16, width: 16, height: 16),
  ),
  CinematicEmoteCatalogEntry(
    id: 'sweat',
    label: 'Gêne',
    description: 'Malaise, peur légère ou embarras.',
    atlasId: cinematicEmoteDefaultReactionsAtlasId,
    frame: CinematicEmoteFrameRect(x: 96, y: 16, width: 16, height: 16),
    secondFrame:
        CinematicEmoteFrameRect(x: 112, y: 16, width: 16, height: 16),
  ),
  CinematicEmoteCatalogEntry(
    id: 'question',
    label: 'Question',
    description: 'Interrogation courte.',
    atlasId: cinematicEmoteDefaultReactionsAtlasId,
    frame: CinematicEmoteFrameRect(x: 0, y: 32, width: 16, height: 16),
    secondFrame:
        CinematicEmoteFrameRect(x: 16, y: 32, width: 16, height: 16),
  ),
  CinematicEmoteCatalogEntry(
    id: 'heart',
    label: 'Coeur',
    description: 'Affection ou joie douce.',
    atlasId: cinematicEmoteDefaultReactionsAtlasId,
    frame: CinematicEmoteFrameRect(x: 32, y: 32, width: 16, height: 16),
    secondFrame:
        CinematicEmoteFrameRect(x: 48, y: 32, width: 16, height: 16),
  ),
  CinematicEmoteCatalogEntry(
    id: 'happy',
    label: 'Joie',
    description: 'Sourire franc ou amusement.',
    atlasId: cinematicEmoteDefaultReactionsAtlasId,
    frame: CinematicEmoteFrameRect(x: 64, y: 32, width: 16, height: 16),
    secondFrame:
        CinematicEmoteFrameRect(x: 80, y: 32, width: 16, height: 16),
  ),
  CinematicEmoteCatalogEntry(
    id: 'silence',
    label: 'Silence',
    description: 'Hésitation ou silence.',
    atlasId: cinematicEmoteDefaultReactionsAtlasId,
    frame: CinematicEmoteFrameRect(x: 96, y: 32, width: 16, height: 16),
    secondFrame:
        CinematicEmoteFrameRect(x: 112, y: 32, width: 16, height: 16),
  ),
  CinematicEmoteCatalogEntry(
    id: 'neutral',
    label: 'Bulle neutre',
    description: 'Bulle neutre ou fallback.',
    atlasId: cinematicEmoteNeutralBubblesAtlasId,
    frame: CinematicEmoteFrameRect(x: 0, y: 0, width: 16, height: 16),
  ),
  CinematicEmoteCatalogEntry(
    id: 'pause',
    label: 'Pause',
    description: 'Temps mort ou attente courte.',
    atlasId: cinematicEmoteNeutralBubblesAtlasId,
    frame: CinematicEmoteFrameRect(x: 16, y: 0, width: 16, height: 16),
  ),
  CinematicEmoteCatalogEntry(
    id: 'thought',
    label: 'Pensée',
    description: 'Pensée ou réflexion.',
    atlasId: cinematicEmoteNeutralBubblesAtlasId,
    frame: CinematicEmoteFrameRect(x: 32, y: 0, width: 16, height: 16),
  ),
];

CinematicEmoteAtlas? cinematicEmoteAtlasById(String? atlasId) {
  final id = atlasId?.trim();
  if (id == null || id.isEmpty) {
    return null;
  }
  for (final atlas in cinematicEmoteAtlases) {
    if (atlas.id == id) {
      return atlas;
    }
  }
  return null;
}

CinematicEmoteCatalogEntry? cinematicEmoteCatalogEntryById(String? emoteId) {
  final id = emoteId?.trim();
  if (id == null || id.isEmpty) {
    return null;
  }
  for (final entry in cinematicEmoteCatalog) {
    if (entry.id == id) {
      return entry;
    }
  }
  return null;
}

bool isCinematicEmoteIdKnown(String? emoteId) {
  return cinematicEmoteCatalogEntryById(emoteId) != null;
}
