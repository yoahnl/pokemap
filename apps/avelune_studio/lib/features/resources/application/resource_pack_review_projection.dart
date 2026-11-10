String resourcePackKindLabel(Object? kind) => switch (kind) {
  'tileset' => 'Image',
  'element' => 'Décor',
  'model3d' => 'Modèle 3D',
  'character' => 'Personnage',
  'environmentPreset' => 'Environnement',
  'smartTilePreset' => 'Terrain',
  'smartTilePattern' => 'Motif de terrain',
  'borderBlueprint' => 'Bordure',
  'resourceFamily' => 'Famille de ressources',
  'elementCategory' => 'Catégorie de décors',
  'tilesetFolder' => 'Dossier d’images',
  'tilesetElementGroup' => 'Groupe de planche',
  'smartTileMaterial' => 'Matériau de terrain',
  'smartTileAtlas' => 'Planche de terrain',
  'smartTileAnimation' => 'Animation de terrain',
  'smartTileCategory' => 'Catégorie de terrain',
  'smartTileConnectionGroup' => 'Groupe de raccordement',
  'characterPortraitState' => 'État de portrait',
  'characterAnimationDefinition' => 'Animation de personnage',
  'borderSnapshot' => 'Publication de bordure',
  'file' => 'Source graphique',
  _ => 'Ressource',
};

const resourcePackContextLabels = {
  'all': 'Tous',
  'interior': 'Intérieur',
  'exterior': 'Extérieur',
  'both': 'Les deux',
  'unspecified': 'Non renseigné',
};

String resourcePackBudgetContextLabel(Object? scope) {
  final value = '$scope';
  for (final entry in const {
    'elementCategories': 'Catégories de décors',
    'tilesetFolders': 'Dossiers des atlas',
    'dialogueFolders': 'Dossiers des dialogues',
    'terrainCategories': 'Catégories des sols',
    'pathCategories': 'Catégories des chemins',
    'groups': 'Groupes',
    'resourceLibraryCatalog.families': 'Familles de ressources',
  }.entries) {
    if (value.endsWith('.${entry.key}')) return entry.value;
  }
  if (value.contains('/')) return 'Fichier ${value.split('/').last}';
  return value == 'nativeSelectionDefinitions'
      ? 'Définitions avant publication'
      : 'Sous-ensemble du catalogue';
}

String resourcePackUnknownDimensionLabel(Object? dimension) =>
    switch (dimension) {
      'publicationMetadata' => 'informations finales de publication',
      'archiveBytes' => 'taille de l’archive',
      'manifestBytes' => 'manifeste de l’archive',
      'publishedCatalogBytes' => 'taille du catalogue publié',
      'imagePixels' || 'rgba8BytesEstimate' => 'dimensions des images',
      'licenses' => 'documents de licence',
      'mediaIntegrity' => 'intégrité des médias',
      'fileInventory' || 'files' || 'fileBytes' => 'inventaire des fichiers',
      'payloadEntries' || 'payloadBytes' => 'contenu complet du package',
      'runtimeProjection' => 'données conservées dans le jeu exporté',
      'publishedFiles' => 'fichiers finaux à installer',
      _ =>
        '$dimension'.endsWith('.imageDimensions')
            ? 'dimensions d’une image du pack'
            : 'données complémentaires',
    };

String resourcePackExportRowLabel(Map<String, Object?> row) {
  final label = row['label'] ?? 'Ressource associée';
  return switch (row['kind']) {
    'promotion' => '$label · ressource privée rendue commune',
    'organization' => '$label · ${row['effectLabel']}',
    'publication' =>
      '$label · ${switch (row['draftComparison']) {
        'equivalent' => 'brouillon enregistré équivalent',
        'divergent' => 'brouillon enregistré différent',
        'notComparable' => 'brouillon non comparable',
        _ => 'publication actuelle',
      }}. ${row['notice']}',
    'source' =>
      '$label · ${row['attributionScope'] == 'globalCredits' ? 'crédits de cette édition' : 'origine conservée'} · ${row['licenseCount']} licences${row['sourceUrl'] == null ? '' : ' · ${row['sourceUrl']}'}',
    'sourceResource' => '$label · ressource couverte par une origine conservée',
    'sourceFile' =>
      'Fichier associé à une origine conservée · ${row['logicalPath']}',
    'sourceLicense' => 'Document de licence d’une origine conservée',
    'fileLicense' => 'Document de licence d’un fichier associé',
    'license' => 'Document de licence UTF-8 · ${row['byteLength']} octets',
    _ =>
      '$label · ${resourcePackKindLabel(row['resourceKind'])}${row['selected'] == true ? ' · Ressource choisie' : ' · Dépendance incluse'}',
  };
}

String resourcePackImportRowLabel(Map<String, Object?> row) =>
    row['kind'] == 'authoringDraftNotice' || row['conflict'] != null
    ? '${row['label']} : ${row['message']}'
    : '${row['label'] ?? resourcePackKindLabel(row['kind'])}${row['labelComplete'] == false ? '… (nom abrégé)' : ''} · ${resourcePackKindLabel(row['kind'])}\n${row['selected'] == true ? 'Ressource choisie' : 'Nécessaire pour « ${row['requiredByLabel']} » (exemple de ressource choisie)'}';
