/// Les profils de stress Avelune — BETA-AVL-005.
///
/// Ces quatre profils sont CALIBRÉS sur un package réel, pas inventés : le
/// paquet `le_train_de_17h42-0.1.8.avelunegame` mesuré le 2026-08-25 porte
/// 9 407 entrées pour 348,8 Mo décompressés, répartis ainsi.
///
/// | type   | entrées | part du poids | taille moyenne |
/// |--------|---------|---------------|----------------|
/// | `png`  |   5 333 |        55,3 % |        36,2 Ko |
/// | `json` |   2 944 |        15,5 % |        18,4 Ko |
/// | `ogg`  |     728 |         5,5 % |        27,0 Ko |
/// | `blob` |     393 |        16,9 % |       154,0 Ko |
/// | `mp4`  |       5 |         4,7 % |         3,3 Mo |
///
/// Le format `.avelunegame` v1 est STORE-only (`DeterministicZipEncoder`) :
/// l'archive ne compresse rien. Ce qui coûte au Player est donc le NOMBRE
/// d'entrées, le poids brut, et la forme des JSON à décoder — pas un ratio
/// de compression. Les profils font varier ces trois axes ensemble.
///
/// LES PLAFONDS DU FORMAT BORNENT LES PROFILS. `GamePackageSecurityPolicy`
/// refuse un JSON au-delà de 32 Mo, une image au-delà de 8 192 px de côté ou
/// de 67,1 M pixels. Un profil qui les dépasse ne produit pas un package
/// « pire » : il produit un package REFUSÉ, ce qui ne mesure plus rien. Le
/// profil adversarial s'arrête donc juste sous le plafond.
///
/// Au passage, ce plafond est une donnée de conception à connaître : le
/// `project.json` du Train pèse déjà 10 Mo, soit 31 % des 32 Mo autorisés.
///
/// POURQUOI L'ENTROPIE COMPTE : le ticket prévient qu'« une fixture
/// compressible ou trop homogène fausserait les conclusions de compression et
/// d'I/O ». Un PNG de 36 Ko rempli de zéros ne mesure ni le décodage, ni le
/// débit disque, ni ce qu'une compression future gagnerait. Le générateur
/// produit donc du contenu à entropie réaliste, dérivé de la graine.
library;

/// L'axe que le profil pousse à l'extrême, quand il en pousse un.
enum AveluneStressEmphasis {
  /// Les proportions du paquet réel, à l'échelle.
  representative,

  /// Beaucoup plus d'entrées à poids égal : le pire cas pour le compte de
  /// fichiers, l'ouverture de l'archive et le parcours d'inventaire.
  fileCount,

  /// Un manifeste projet monolithique : le pire cas pour le décodage JSON sur
  /// le thread UI, la forme que `project.json` prend déjà à 10 Mo sur le
  /// Train.
  monolithicJson,

  /// Quelques textures très grandes : le pire cas pour la création de
  /// `ui.Image` et l'upload GPU.
  hugeTextures,
}

/// Un profil de package de stress, déterministe et documenté.
final class AveluneStressProfile {
  const AveluneStressProfile({
    required this.id,
    required this.summary,
    required this.pngCount,
    required this.jsonCount,
    required this.oggCount,
    required this.blobCount,
    required this.mp4Count,
    required this.mapCount,
    required this.averagePngBytes,
    required this.averageJsonBytes,
    required this.averageOggBytes,
    required this.averageBlobBytes,
    required this.averageMp4Bytes,
    required this.projectManifestBytes,
    required this.emphasis,
    this.hugeTextureCount = 0,
    this.hugeTextureBytes = 0,
  });

  final String id;
  final String summary;

  final int pngCount;
  final int jsonCount;
  final int oggCount;
  final int blobCount;
  final int mp4Count;

  /// Combien de maps le manifeste déclare — chacune est un JSON à part.
  final int mapCount;

  final int averagePngBytes;
  final int averageJsonBytes;
  final int averageOggBytes;
  final int averageBlobBytes;
  final int averageMp4Bytes;

  /// Le poids visé pour le seul `project.json`.
  final int projectManifestBytes;

  final AveluneStressEmphasis emphasis;

  /// Des textures hors norme, en plus du lot ordinaire.
  final int hugeTextureCount;
  final int hugeTextureBytes;

  /// Le nombre d'entrées de charge utile, hors manifeste de package.
  int get payloadEntryCount =>
      pngCount +
      jsonCount +
      oggCount +
      blobCount +
      mp4Count +
      mapCount +
      hugeTextureCount +
      1;

  /// Le poids brut attendu, en octets. L'archive étant STORE-only, c'est
  /// aussi l'ordre de grandeur du fichier produit.
  int get approximatePayloadBytes =>
      pngCount * averagePngBytes +
      jsonCount * averageJsonBytes +
      oggCount * averageOggBytes +
      blobCount * averageBlobBytes +
      mp4Count * averageMp4Bytes +
      hugeTextureCount * hugeTextureBytes +
      projectManifestBytes;

  @override
  String toString() => 'AveluneStressProfile($id, '
      '$payloadEntryCount entrées, '
      '${(approximatePayloadBytes / 1048576).toStringAsFixed(1)} Mo)';
}

/// Un package de démo : ce qu'un auteur produit à ses premiers essais.
///
/// Environ un cinquantième du Train. Assez petit pour être matérialisé dans
/// un test unitaire sans le ralentir.
const AveluneStressProfile aveluneStressSmall = AveluneStressProfile(
  id: 'small',
  summary: 'Démo d’auteur : ~190 entrées, ~7 Mo, proportions du paquet réel.',
  pngCount: 107,
  jsonCount: 59,
  oggCount: 15,
  blobCount: 8,
  mp4Count: 0,
  mapCount: 3,
  averagePngBytes: 37000,
  averageJsonBytes: 18800,
  averageOggBytes: 27600,
  averageBlobBytes: 157000,
  averageMp4Bytes: 0,
  projectManifestBytes: 210000,
  emphasis: AveluneStressEmphasis.representative,
);

/// Un jeu de taille moyenne : une région jouable, pas encore une campagne.
///
/// Environ un huitième du Train.
const AveluneStressProfile aveluneStressMedium = AveluneStressProfile(
  id: 'medium',
  summary: 'Région jouable : ~1 180 entrées, ~44 Mo, proportions réelles.',
  pngCount: 667,
  jsonCount: 368,
  oggCount: 91,
  blobCount: 49,
  mp4Count: 1,
  mapCount: 4,
  averagePngBytes: 37000,
  averageJsonBytes: 18800,
  averageOggBytes: 27600,
  averageBlobBytes: 157000,
  averageMp4Bytes: 3400000,
  projectManifestBytes: 1300000,
  emphasis: AveluneStressEmphasis.representative,
);

/// Le Train, à l'échelle réelle.
///
/// Les compteurs reprennent la mesure du 2026-08-25 : c'est la borne haute
/// que le Player doit tenir aujourd'hui, pas une projection.
const AveluneStressProfile aveluneStressLarge = AveluneStressProfile(
  id: 'large',
  summary: 'Campagne réelle : ~9 400 entrées, ~349 Mo, mesuré sur le Train.',
  pngCount: 5333,
  jsonCount: 2913,
  oggCount: 728,
  blobCount: 393,
  mp4Count: 5,
  mapCount: 31,
  averagePngBytes: 37000,
  averageJsonBytes: 18800,
  averageOggBytes: 27600,
  averageBlobBytes: 157000,
  averageMp4Bytes: 3400000,
  projectManifestBytes: 10500000,
  emphasis: AveluneStressEmphasis.representative,
);

/// Les formes que le Player encaisse le plus mal, à budget de poids voisin.
///
/// Trois axes poussés ENSEMBLE, parce qu'ils se cumulent dans la vraie vie :
/// deux fois plus d'entrées qu'à l'échelle réelle mais bien plus petites (le
/// compte de fichiers domine l'I/O), un `project.json` de 31 Mo — juste sous
/// le plafond de 32 Mo, trois fois le Train d'aujourd'hui — et deux textures
/// de 4 096 px de côté (la création de `ui.Image` et l'upload GPU).
///
/// Les textures sont DEUX et non huit : le stress GPU vient de la dimension
/// d'une texture, pas de leur nombre, et huit textures de 4 096 px
/// pèseraient 400 Mo de bruit à matérialiser pour rien.
const AveluneStressProfile aveluneStressAdversarial = AveluneStressProfile(
  id: 'adversarial',
  summary: 'Formes coûteuses cumulées : ~18 500 entrées, un manifeste de '
      '31 Mo au bord du plafond, deux textures de 4 096 px.',
  pngCount: 12000,
  jsonCount: 6000,
  oggCount: 400,
  blobCount: 600,
  mp4Count: 2,
  mapCount: 64,
  averagePngBytes: 4200,
  averageJsonBytes: 1800,
  averageOggBytes: 12000,
  averageBlobBytes: 9000,
  averageMp4Bytes: 3400000,
  projectManifestBytes: 31000000,
  emphasis: AveluneStressEmphasis.monolithicJson,
  hugeTextureCount: 2,
  hugeTextureBytes: 50331648,
);

/// Les quatre profils, dans l'ordre de coût croissant.
const List<AveluneStressProfile> aveluneStressProfiles = <AveluneStressProfile>[
  aveluneStressSmall,
  aveluneStressMedium,
  aveluneStressLarge,
  aveluneStressAdversarial,
];

/// Le profil portant cet identifiant, ou un refus explicite.
AveluneStressProfile aveluneStressProfileById(String id) {
  for (final profile in aveluneStressProfiles) {
    if (profile.id == id) return profile;
  }
  throw ArgumentError.value(
    id,
    'id',
    'Profil de stress inconnu. Attendus : '
        '${aveluneStressProfiles.map((profile) => profile.id).join(', ')}.',
  );
}
