import 'package:flutter/widgets.dart';
import 'package:map_editor/l10n/l10n.dart';

final class CinematicStudioCopy {
  const CinematicStudioCopy._(this.isEnglish);

  factory CinematicStudioCopy.of(BuildContext context) =>
      CinematicStudioCopy._(context.pokeMapL10n.localeName.startsWith('en'));

  final bool isEnglish;

  String get inGameFamily =>
      isEnglish ? 'In-game cinematics' : 'Cinématiques in-game';
  String get presentationFamily =>
      isEnglish ? 'Presentation cinematics' : 'Cinématiques de présentation';
  String get inGameShort => 'In-game';
  String get presentationShort => isEnglish ? 'Presentation' : 'Présentation';
  String get libraryBreadcrumb => isEnglish
      ? 'Cinematics library path'
      : 'Chemin de la bibliothèque de cinématiques';
  String get unavailableFolder =>
      isEnglish ? 'Folder unavailable' : 'Dossier indisponible';
  String get unavailableFolderMessage => isEnglish
      ? 'The folder was moved or deleted. The library returned to its root without changing its content.'
      : 'Le dossier a été déplacé ou supprimé. La bibliothèque est revenue à sa racine sans modifier son contenu.';
  String get loadingCinematics =>
      isEnglish ? 'Loading cinematics…' : 'Chargement des cinématiques…';
  String get loadingCatalog => isEnglish
      ? 'Reading the catalog and its folders.'
      : 'Lecture du catalogue et de ses dossiers.';
  String get libraryUnavailable =>
      isEnglish ? 'Library unavailable' : 'Bibliothèque indisponible';
  String get libraryUnavailableMessage => isEnglish
      ? 'The catalog could not be loaded. The project remains unchanged.'
      : 'Le catalogue n’a pas pu être chargé. Le projet reste intact.';
  String get noResults => isEnglish ? 'No results' : 'Aucun résultat';
  String get emptyLibrary => isEnglish ? 'Empty library' : 'Bibliothèque vide';
  String get noResultsMessage => isEnglish
      ? 'No cinematic or folder matches the search.'
      : 'Aucune cinématique ni aucun dossier ne correspond à la recherche.';
  String get emptyLibraryMessage => isEnglish
      ? 'This family does not contain a cinematic in this folder yet.'
      : 'Cette famille ne contient encore aucune cinématique dans ce dossier.';
  String get folder => isEnglish ? 'Folder' : 'Dossier';
  String get genericCinematic => isEnglish ? 'Cinematic' : 'Cinématique';
  String get duplicationFailed =>
      isEnglish ? 'Duplication failed' : 'Duplication impossible';
  String get restoreFailed =>
      isEnglish ? 'Restore failed' : 'Restauration impossible';
  String get archiveFailed =>
      isEnglish ? 'Archive failed' : 'Archivage impossible';
  String get deletionBlocked =>
      isEnglish ? 'Deletion blocked' : 'Suppression bloquée';
  String deletionBlockedMessage(String title, int count) => isEnglish
      ? '“$title” is still used ${count == 1 ? 'once' : '$count times'}. Remove or replace these uses before deleting it.'
      : '« $title » est encore utilisée $count fois. Retirez ou remplacez ces usages avant de la supprimer.';
  String get deleteCinematicTitle =>
      isEnglish ? 'Delete the cinematic?' : 'Supprimer la cinématique ?';
  String deleteCinematicMessage(String title) => isEnglish
      ? '“$title” will be removed from the library and the project. This action cannot be undone.'
      : '« $title » sera retirée de la bibliothèque et du projet. Cette action est définitive.';
  String get deletionFailed =>
      isEnglish ? 'Deletion failed' : 'Suppression impossible';
  String get inGameLibrary =>
      isEnglish ? 'In-game library' : 'Bibliothèque in-game';
  String get presentationLibrary =>
      isEnglish ? 'Presentation library' : 'Bibliothèque de présentation';
  String cinematicCount(int count) => isEnglish
      ? '$count ${count == 1 ? 'cinematic' : 'cinematics'}'
      : '$count cinématique${count > 1 ? 's' : ''}';
  String get selectToOpen => isEnglish
      ? 'Select a cinematic to open.'
      : 'Sélectionnez une cinématique à ouvrir.';
  String get selectToManage => isEnglish
      ? 'Select a cinematic to manage.'
      : 'Sélectionnez une cinématique à gérer.';
  String get projectRequiredToCreate => isEnglish
      ? 'Load a writable project to create a cinematic.'
      : 'Chargez un projet enregistrable pour créer une cinématique.';
  String get open => isEnglish ? 'Open' : 'Ouvrir';
  String get actions => isEnglish ? 'Actions' : 'Actions';
  String get newCinematic => isEnglish ? 'New' : 'Nouvelle';
  String get searchHint => isEnglish
      ? 'Search for a cinematic or folder…'
      : 'Rechercher une cinématique ou un dossier…';
  String get searchSemantics => isEnglish
      ? 'Search in the active family'
      : 'Rechercher dans la famille active';
  String get sort => isEnglish ? 'Sort' : 'Trier';
  String get manualOrder => isEnglish ? 'Manual order' : 'Ordre manuel';
  String get nameAscending => isEnglish ? 'Name A–Z' : 'Nom A–Z';
  String get nameDescending => isEnglish ? 'Name Z–A' : 'Nom Z–A';
  String get recentlyModified =>
      isEnglish ? 'Recently modified' : 'Modifiées récemment';
  String get show => isEnglish ? 'Show' : 'Afficher';
  String get active => isEnglish ? 'Active' : 'Actives';
  String get archived => isEnglish ? 'Archived' : 'Archivées';
  String get all => isEnglish ? 'All' : 'Toutes';
  String get listView => isEnglish ? 'List view' : 'Vue en liste';
  String get showAsList => isEnglish ? 'Show as list' : 'Afficher en liste';
  String get gridView => isEnglish ? 'Grid view' : 'Vue en grille';
  String get showAsGrid => isEnglish ? 'Show as grid' : 'Afficher en grille';

  String get chooseAction => isEnglish
      ? 'Choose an action for this cinematic.'
      : 'Choisissez une action pour cette cinématique.';
  String get rename => isEnglish ? 'Rename' : 'Renommer';
  String get move => isEnglish ? 'Move' : 'Déplacer';
  String get duplicate => isEnglish ? 'Duplicate' : 'Dupliquer';
  String get restore => isEnglish ? 'Restore' : 'Restaurer';
  String get archive => isEnglish ? 'Archive' : 'Archiver';
  String get delete => isEnglish ? 'Delete' : 'Supprimer';
  String get cancel => isEnglish ? 'Cancel' : 'Annuler';
  String get apply => isEnglish ? 'Apply' : 'Appliquer';
  String get create => isEnglish ? 'Create' : 'Créer';
  String get newInGameCinematic =>
      isEnglish ? 'New in-game cinematic' : 'Nouvelle cinématique in-game';
  String get newPresentationCinematic => isEnglish
      ? 'New presentation cinematic'
      : 'Nouvelle cinématique de présentation';
  String get title => isEnglish ? 'Title' : 'Titre';
  String get rootLibrary =>
      isEnglish ? 'Library root' : 'Racine de la bibliothèque';
  String get startingPreset =>
      isEnglish ? 'Starting preset' : 'Preset de départ';
  String get startingPoint => isEnglish ? 'Starting point' : 'Point de départ';
  String get creationFailed =>
      isEnglish ? 'Creation failed' : 'Création impossible';
  String get titleRequired =>
      isEnglish ? 'The title is required.' : 'Le titre est obligatoire.';
  String get enterTitleBeforeCreate => isEnglish
      ? 'Enter a title before creating the cinematic.'
      : 'Saisissez un titre avant de créer la cinématique.';
  String get commandReturnedNoCinematic => isEnglish
      ? 'The command did not return a cinematic.'
      : 'La commande n’a retourné aucune cinématique.';
  String get renameCinematic =>
      isEnglish ? 'Rename cinematic' : 'Renommer la cinématique';
  String get renameFailed =>
      isEnglish ? 'Rename failed' : 'Renommage impossible';
  String get moveCinematic =>
      isEnglish ? 'Move cinematic' : 'Déplacer la cinématique';
  String get destinationFolder =>
      isEnglish ? 'Destination folder' : 'Dossier de destination';
  String get moveFailed => isEnglish ? 'Move failed' : 'Déplacement impossible';

  String worldLabel(String value) => switch (value) {
    'blank' => isEnglish ? 'Blank' : 'Vide',
    'establishingShot' =>
      isEnglish ? 'Establishing shot' : 'Plan d’établissement',
    'dialogueBeat' => isEnglish ? 'Dialogue beat' : 'Temps de dialogue',
    _ => value,
  };
  String worldDescription(String value) => switch (value) {
    'blank' =>
      isEnglish
          ? 'An empty timeline to build in the current in-game Studio.'
          : 'Une timeline vide à construire dans le Studio in-game actuel.',
    'establishingShot' =>
      isEnglish
          ? 'An opening shot followed by a moment to breathe.'
          : 'Un cadrage d’ouverture puis un temps de respiration.',
    'dialogueBeat' =>
      isEnglish
          ? 'A first narrative beat ready for dialogue.'
          : 'Un premier temps narratif prêt à recevoir un dialogue.',
    _ => value,
  };
  String templateLabel(String id) => switch (id) {
    'blank' => isEnglish ? 'Blank' : 'Vide',
    'titleIdentity' => isEnglish ? 'Title & identity' : 'Titre & identité',
    'immersiveOpening' =>
      isEnglish ? 'Immersive opening' : 'Ouverture immersive',
    'stagedStory' => isEnglish ? 'Staged story' : 'Récit mis en scène',
    'interactivePath' => isEnglish ? 'Interactive path' : 'Parcours interactif',
    'adaptiveVideo' => isEnglish ? 'Adaptive video' : 'Vidéo adaptative',
    _ => id,
  };
  String templateDescription(String id) => switch (id) {
    'blank' =>
      isEnglish
          ? 'A free composition with no required media.'
          : 'Une composition libre, sans média imposé.',
    'titleIdentity' =>
      isEnglish
          ? 'Sets a title, an identity and a responsive background.'
          : 'Installe un titre, une identité et un fond responsive.',
    'immersiveOpening' =>
      isEnglish
          ? 'Builds a visual and sound-led cinematic opening.'
          : 'Construit une ouverture visuelle, sonore et immédiatement cinématique.',
    'stagedStory' =>
      isEnglish
          ? 'Combines scenes, text and transitions into a paced story.'
          : 'Enchaîne plans, textes et transitions pour raconter un moment rythmé.',
    'interactivePath' =>
      isEnglish
          ? 'Places interaction cues into a narrative composition.'
          : 'Place des repères d’interaction dans une composition narrative.',
    'adaptiveVideo' =>
      isEnglish
          ? 'Prepares landscape and portrait video alternatives.'
          : 'Prépare une vidéo avec alternatives paysage et portrait.',
    _ => id,
  };
  String get freeComposition =>
      isEnglish ? 'Free composition' : 'Composition libre';
  String mediaCount(int count) => isEnglish
      ? '$count media item${count == 1 ? '' : 's'}'
      : '$count média${count > 1 ? 's' : ''}';
  String get nativeOrientations =>
      isEnglish ? 'Native landscape + portrait' : 'Paysage + portrait natifs';

  String compatibleCount(int count) => isEnglish
      ? '$count compatible cinematic${count == 1 ? '' : 's'}'
      : '$count cinématique${count > 1 ? 's' : ''} compatible${count > 1 ? 's' : ''}';
  String get createAndLink => isEnglish ? 'Create and link' : 'Créer et lier';
  String get pickerSearchHint => isEnglish
      ? 'Search for a presentation cinematic…'
      : 'Rechercher une cinématique de présentation…';
  String get pickerSearchSemantics => isEnglish
      ? 'Search for a compatible cinematic'
      : 'Rechercher une cinématique compatible';
  String get useExisting => isEnglish
      ? 'Use an existing cinematic'
      : 'Utiliser une cinématique existante';
  String get useExistingMessage => isEnglish
      ? 'Selection adds a typed node to the graph. Required interaction cues must then be linked.'
      : 'La sélection ajoute un nœud typé au graph. Les repères d’interaction obligatoires devront ensuite être reliés.';
  String get noCompatible =>
      isEnglish ? 'No compatible cinematic' : 'Aucune cinématique compatible';
  String get createPresentationInLibrary => isEnglish
      ? 'Create a presentation cinematic in the library.'
      : 'Créez une cinématique de présentation dans la bibliothèque.';
  String get changeSearch => isEnglish
      ? 'Change the search to display another cinematic.'
      : 'Modifiez la recherche pour afficher une autre cinématique.';
  String useCinematic(String title) =>
      isEnglish ? 'Use $title' : 'Utiliser $title';
  String get landscapeDedicated =>
      isEnglish ? 'Landscape · dedicated media' : 'Paysage · média dédié';
  String get landscapeFallback =>
      isEnglish ? 'Landscape · fallback' : 'Paysage · fallback';
  String get portraitDedicated =>
      isEnglish ? 'Portrait · dedicated media' : 'Portrait · média dédié';
  String get portraitFallback =>
      isEnglish ? 'Portrait · fallback' : 'Portrait · fallback';
  String interactionCount(int count) => isEnglish
      ? count == 0
            ? 'No interactions'
            : '$count interaction${count == 1 ? '' : 's'}'
      : count == 0
      ? 'Aucune interaction'
      : '$count interaction${count > 1 ? 's' : ''}';
  String requiredInteractionCount(int count) => isEnglish
      ? '$count required interaction${count == 1 ? '' : 's'} to link in this Scene.'
      : '$count interaction${count > 1 ? 's' : ''} obligatoire${count > 1 ? 's' : ''} à relier dans cette scène.';

  String get saveBeforeExit =>
      isEnglish ? 'Save before leaving?' : 'Enregistrer avant de quitter ?';
  String get unsavedCinematicMessage => isEnglish
      ? 'This cinematic contains changes that have not been saved yet.'
      : 'Cette cinématique contient des modifications qui ne sont pas encore enregistrées.';
  String get leaveWithoutSaving =>
      isEnglish ? 'Leave without saving' : 'Quitter sans enregistrer';
  String get saveAndLeave =>
      isEnglish ? 'Save and leave' : 'Enregistrer et quitter';
  String get backToLibrary =>
      isEnglish ? 'Back to library' : 'Retour à la bibliothèque';
  String get presentationCinematic =>
      isEnglish ? 'Presentation cinematic' : 'Cinématique de présentation';
  String get save => isEnglish ? 'Save' : 'Enregistrer';
  String get resizeRightPanel =>
      isEnglish ? 'Resize the right panel' : 'Redimensionner le panneau droit';
  String get layers => isEnglish ? 'Layers' : 'Calques';
  String get properties => isEnglish ? 'Properties' : 'Propriétés';
  String get add => isEnglish ? 'Add' : 'Ajouter';
  String get resizeTimeline =>
      isEnglish ? 'Resize the timeline' : 'Redimensionner la timeline';
  String get closeAddPalette =>
      isEnglish ? 'Close the Add palette' : 'Fermer la palette Ajouter';

  String get importFailed => isEnglish ? 'Import failed' : 'Import impossible';
  String get importDraftUnchanged => isEnglish
      ? 'The catalog and your draft remain unchanged.'
      : 'Le catalogue et votre brouillon restent inchangés.';
  String get additionFailed =>
      isEnglish ? 'Addition failed' : 'Ajout impossible';
  String get additionDraftUnchanged => isEnglish
      ? 'The media was not added; your draft is preserved.'
      : 'Le média n’a pas été ajouté ; votre brouillon est conservé.';
  String get mediaSearchHint =>
      isEnglish ? 'Search media…' : 'Rechercher dans les médias…';
  String get mediaSearchSemantics =>
      isEnglish ? 'Search for media to add' : 'Rechercher un média à ajouter';
  String categoryLabel(String name) => switch (name) {
    'visual' => isEnglish ? 'Visual' : 'Visuel',
    'text' => isEnglish ? 'Text' : 'Texte',
    'audio' => 'Audio',
    'video' => isEnglish ? 'Video' : 'Vidéo',
    'accessibility' => isEnglish ? 'Accessibility' : 'Accessibilité',
    'marker' => isEnglish ? 'Cues' : 'Repères',
    _ => name,
  };
  String insertionAt(String time) =>
      isEnglish ? 'Insert at $time' : 'Insertion à $time';
  String folderLabel(String folderId) =>
      isEnglish ? 'Folder $folderId' : 'Dossier $folderId';
  String get importMedia => isEnglish ? 'Import media' : 'Importer un média';
  String get importInProgress =>
      isEnglish ? 'Import in progress' : 'Import en cours';
  String get importProgress =>
      isEnglish ? 'Import progress' : 'Progression de l’import';
  String get cancelImport => isEnglish ? 'Cancel import' : 'Annuler l’import';
  String get durationConflict =>
      isEnglish ? 'Duration conflict' : 'Conflit de durée';
  String get durationConflictMessage => isEnglish
      ? 'This media exceeds the remaining cinematic duration.'
      : 'Ce média dépasse la durée restante de la cinématique.';
  String get fitRemainingDuration =>
      isEnglish ? 'Fit to remaining duration' : 'Ajuster à la durée restante';
  String get addedToTimeline =>
      isEnglish ? 'Added to timeline' : 'Ajouté à la timeline';
  String get addToTimeline =>
      isEnglish ? 'Add to timeline' : 'Ajouter à la timeline';
  String get loadingMediaCatalogSemantics =>
      isEnglish ? 'Loading media catalog' : 'Chargement du catalogue média';
  String get loadingCatalogShort =>
      isEnglish ? 'Loading catalog…' : 'Chargement du catalogue…';
  String get catalogUnavailable =>
      isEnglish ? 'Catalog unavailable' : 'Catalogue indisponible';
  String get retry => isEnglish ? 'Try again' : 'Réessayer';
  String get editableTextAfterInsertion => isEnglish
      ? 'Editable text block after insertion'
      : 'Bloc texte éditable après insertion';
  String get cueAtPlayhead =>
      isEnglish ? 'Cue at the playhead' : 'Repère à la tête de lecture';
  String get noMediaInCategory => isEnglish
      ? 'No media in this category'
      : 'Aucun média dans cette catégorie';
  String get importMediaToStart => isEnglish
      ? 'Import media to get started.'
      : 'Importez un média pour commencer.';
  String get tryAnotherSearch =>
      isEnglish ? 'Try another search.' : 'Essayez une autre recherche.';
  String quickLabel(String name) => switch (name) {
    'text' => isEnglish ? 'New text' : 'Nouveau texte',
    'marker' => isEnglish ? 'New cue' : 'Nouveau repère',
    _ => name,
  };
  String availabilityLabel(String name) => switch (name) {
    'ready' => isEnglish ? 'Ready' : 'Prêt',
    'missing' => isEnglish ? 'Missing' : 'Manquant',
    'corrupt' => isEnglish ? 'Corrupt' : 'Corrompu',
    'unsupported' => isEnglish ? 'Unsupported' : 'Non supporté',
    _ => name,
  };
  String availabilityRecovery(String name) => switch (name) {
    'ready' => isEnglish ? 'Media ready.' : 'Média prêt.',
    'missing' =>
      isEnglish
          ? 'Missing media. Reimport it or replace its source.'
          : 'Média manquant. Réimportez-le ou remplacez sa source.',
    'corrupt' =>
      isEnglish
          ? 'Corrupt media. Reimport a valid copy.'
          : 'Média corrompu. Réimportez une copie valide.',
    'unsupported' =>
      isEnglish
          ? 'Unsupported format. Convert or replace this media.'
          : 'Format non supporté. Convertissez ou remplacez ce média.',
    _ => name,
  };
  String get unknownError => isEnglish
      ? 'An unknown error occurred.'
      : 'Une erreur inconnue est survenue.';

  String diagnosticMessage({
    required String cause,
    required String impact,
    required String code,
  }) => isEnglish
      ? 'Cause: $cause\nImpact: $impact\nCode: $code'
      : 'Cause : $cause\nImpact : $impact\nCode : $code';
  String get previousFrame => isEnglish ? 'Previous frame' : 'Frame précédente';
  String get play => isEnglish ? 'Play' : 'Lecture';
  String get pause => isEnglish ? 'Pause' : 'Pause';
  String get stopAndRewind =>
      isEnglish ? 'Stop and rewind' : 'Stop et retour au début';
  String get nextFrame => isEnglish ? 'Next frame' : 'Frame suivante';
  String get enableLoop => isEnglish ? 'Enable loop' : 'Activer la boucle';
  String get disableLoop => isEnglish ? 'Disable loop' : 'Désactiver la boucle';
  String get compare => isEnglish ? 'Compare' : 'Comparer';
  String get fit => isEnglish ? 'Fit' : 'Ajuster';
  String get previewLoadingReason => isEnglish
      ? 'The preview is loading.'
      : 'L’aperçu est en cours de chargement.';
  String get previewFailedReason => isEnglish
      ? 'The preview renderer failed.'
      : 'Le rendu de l’aperçu a échoué.';
  String get emptyCinematicReason =>
      isEnglish ? 'The cinematic is empty.' : 'La cinématique est vide.';
  String get previewLoading =>
      isEnglish ? 'Loading preview' : 'Chargement de l’aperçu';
  String get previewUnavailable =>
      isEnglish ? 'Preview unavailable' : 'Aperçu indisponible';
  String get interactionPending =>
      isEnglish ? 'Interaction pending' : 'Interaction en attente';
  String get responsiveCompositionBlocked => isEnglish
      ? 'Responsive composition blocked'
      : 'Composition responsive bloquée';
  String duplicateMediaBinding(String clipId) => isEnglish
      ? 'Clip $clipId has multiple media bindings.'
      : 'Le clip $clipId possède plusieurs liaisons média.';
  String musicRequiresSharedSource(String clipId) => isEnglish
      ? 'Music $clipId must keep one shared source.'
      : 'La musique $clipId doit garder une source partagée unique.';
  String mediaSourceRequired(String clipId) => isEnglish
      ? 'Clip $clipId must provide at least one media source.'
      : 'Le clip $clipId doit fournir au moins une source média.';
  String mediaDurationUnknown(String resourceId) => isEnglish
      ? 'The duration of $resourceId is unknown.'
      : 'La durée de $resourceId est inconnue.';
  String mediaTooShort(String resourceId, int availableUs, int requiredUs) =>
      isEnglish
      ? '$resourceId is too short: $availableUs µs available for $requiredUs µs.'
      : '$resourceId est trop court : $availableUs µs disponibles pour $requiredUs µs.';
  String get viewportLabel => isEnglish
      ? 'Presentation cinematic canvas'
      : 'Canvas de cinématique de présentation';
  String get viewportHint => isEnglish
      ? 'F fits the frame, plus and minus change zoom, and arrow keys move the frame.'
      : 'F ajuste le cadre, plus et moins changent le zoom, les flèches déplacent le cadre.';
  String get framePreview => isEnglish
      ? 'Presentation frame preview'
      : 'Aperçu de la frame Presentation';
  String get retryRender =>
      isEnglish ? 'Try rendering again' : 'Réessayer le rendu';
  String get noContentToDisplay =>
      isEnglish ? 'No content to display' : 'Aucun contenu à afficher';
  String get addFirstFrameContent => isEnglish
      ? 'Add media or text to compose the first frame.'
      : 'Ajoutez un média ou un texte pour composer la première frame.';
  String get zoomOut => isEnglish ? 'Zoom out' : 'Réduire le zoom';
  String get zoomIn => isEnglish ? 'Zoom in' : 'Augmenter le zoom';
  String get fitFrame => isEnglish ? 'Fit frame' : 'Ajuster le cadre';
  String get layerBank => isEnglish ? 'Layer bank' : 'Banque de calques';
  String get createVisualFolder =>
      isEnglish ? 'Create visual folder' : 'Créer un dossier visuel';
  String get visuals => isEnglish ? 'Visuals' : 'Visuels';
  String get captions => isEnglish ? 'Captions' : 'Sous-titres';
  String get cues => isEnglish ? 'Cues' : 'Repères';
  String toggleGroup({required bool expanded, required String label}) =>
      isEnglish
      ? '${expanded ? 'Collapse' : 'Expand'} $label'
      : '${expanded ? 'Replier' : 'Déplier'} $label';
  String visibilityAction({required bool visible, required String label}) =>
      isEnglish
      ? '${visible ? 'Hide' : 'Show'} $label'
      : '${visible ? 'Masquer' : 'Afficher'} $label';
  String lockAction({required bool locked, required String label}) => isEnglish
      ? '${locked ? 'Unlock' : 'Lock'} $label'
      : '${locked ? 'Déverrouiller' : 'Verrouiller'} $label';
  String actionsFor(String label) =>
      isEnglish ? 'Actions for $label' : 'Actions pour $label';
  String reorder(String label) =>
      isEnglish ? 'Reorder $label' : 'Réordonner $label';
  String visibleState(String label) =>
      isEnglish ? '$label visible' : '$label visible';
  String unlockedState(String label) =>
      isEnglish ? '$label unlocked' : '$label déverrouillé';
  String deleteFolderTitle(String label) =>
      isEnglish ? 'Delete $label?' : 'Supprimer $label ?';
  String get deleteFolderMessage => isEnglish
      ? 'The layers stay in Visuals and keep their depth.'
      : 'Les calques restent dans Visuels et conservent leur profondeur.';
  String get deleteFolder =>
      isEnglish ? 'Delete folder' : 'Supprimer le dossier';
  String get newVisualFolder =>
      isEnglish ? 'New visual folder' : 'Nouveau dossier visuel';
  String get renameFolder =>
      isEnglish ? 'Rename folder' : 'Renommer le dossier';
  String get folderName => isEnglish ? 'Folder name' : 'Nom du dossier';
  String get timelineLoading =>
      isEnglish ? 'Loading timeline' : 'Chargement de la timeline';
  String get preparingVisibleTracks => isEnglish
      ? 'Preparing visible tracks…'
      : 'Préparation des pistes visibles…';
  String get timelineUnavailable =>
      isEnglish ? 'Timeline unavailable' : 'Timeline indisponible';
  String get timelineDisabled => isEnglish
      ? 'The timeline is disabled for this document.'
      : 'La timeline est désactivée pour ce document.';
  String get timelineInvalid =>
      isEnglish ? 'Invalid timeline' : 'Timeline invalide';
  String get invalidTrackStructure => isEnglish
      ? 'The track structure is invalid.'
      : 'La structure des pistes est invalide.';
  String get undoLastClipEdit => isEnglish
      ? 'Undo the last clip edit'
      : 'Annuler la dernière édition de clips';
  String get undo => isEnglish ? 'Undo' : 'Annuler';
  String get redoLastClipEdit => isEnglish
      ? 'Redo the last clip edit'
      : 'Rétablir la dernière édition de clips';
  String get redo => isEnglish ? 'Redo' : 'Rétablir';
  String get copySelectedClips =>
      isEnglish ? 'Copy selected clips' : 'Copier les clips sélectionnés';
  String get copyAction => isEnglish ? 'Copy' : 'Copier';
  String get pasteAtPlayhead => isEnglish
      ? 'Paste clips at the playhead'
      : 'Coller les clips au playhead';
  String get paste => isEnglish ? 'Paste' : 'Coller';
  String get duplicateSelectedClips => isEnglish
      ? 'Duplicate selected clips'
      : 'Dupliquer les clips sélectionnés';
  String get deleteSelectedClips =>
      isEnglish ? 'Delete selected clips' : 'Supprimer les clips sélectionnés';
  String get zoomOutTimeline =>
      isEnglish ? 'Zoom out timeline' : 'Dézoomer la timeline';
  String get zoomInTimeline =>
      isEnglish ? 'Zoom in timeline' : 'Zoomer la timeline';
  String get presentationTimeRuler =>
      isEnglish ? 'Presentation time ruler' : 'Règle temporelle Presentation';
  String get emptyTimeline => isEnglish ? 'Empty timeline' : 'Timeline vide';
  String get addTrackToStart => isEnglish
      ? 'Add a track to start the composition.'
      : 'Ajoutez une piste pour commencer la composition.';
  String trimStart(String label) =>
      isEnglish ? 'Trim the start of $label' : 'Rogner le début de $label';
  String trimEnd(String label) =>
      isEnglish ? 'Trim the end of $label' : 'Rogner la fin de $label';
  String get preparingPreview =>
      isEnglish ? 'Preparing preview…' : 'Préparation de l’aperçu…';
  String get loopState => isEnglish ? 'loop' : 'boucle';
  String get fadesState => isEnglish ? 'fades' : 'fondus';
  String get responsiveVariants => isEnglish ? 'L/P variants' : 'variantes L/P';
  String get video => isEnglish ? 'Video' : 'Vidéo';
  String segmentCount(int count) => isEnglish
      ? '$count segment${count == 1 ? '' : 's'}'
      : '$count segment${count > 1 ? 's' : ''}';
  String get localeFallback =>
      isEnglish ? 'locale fallback' : 'fallback locale';
  String get sceneCue => isEnglish ? 'Scene cue' : 'Cue Scene';
  String get marker => isEnglish ? 'Cue' : 'Repère';
  String get requiredState => isEnglish ? 'required' : 'requis';
  String get unlinked => isEnglish ? 'unlinked' : 'non relié';
  String sceneUsageCount(int count) => isEnglish
      ? '$count Scene ${count == 1 ? 'use' : 'uses'}'
      : '$count ${count == 1 ? 'usage' : 'usages'} Scene';

  String get multipleSelection =>
      isEnglish ? 'Multiple selection' : 'Sélection multiple';
  String selectedClipCount(int count) =>
      isEnglish ? '$count selected clips' : '$count clips sélectionnés';
  String get multipleSelectionMessage => isEnglish
      ? 'Group moves and deletions remain available in the timeline. Select one clip to edit its properties.'
      : 'Les déplacements et suppressions groupés restent disponibles dans la timeline. Sélectionnez un seul clip pour modifier ses propriétés.';
  String get document => isEnglish ? 'Document' : 'Document';
  String get description => isEnglish ? 'Description' : 'Description';
  String get durationSeconds =>
      isEnglish ? 'Duration (seconds)' : 'Durée (secondes)';
  String get responsiveComposition =>
      isEnglish ? 'Responsive composition' : 'Composition responsive';
  String get oneDocumentBothOrientations => isEnglish
      ? 'One document · 16:9 and 9:16'
      : 'Document unique · 16:9 et 9:16';
  String get safeAreas => isEnglish ? 'Safe areas' : 'Zones sûres';
  String get activeBothOrientations => isEnglish
      ? 'Active in both orientations'
      : 'Actives dans les deux orientations';
  String get background => isEnglish ? 'Background' : 'Fond';
  String get transparentUntilVisual => isEnglish
      ? 'Transparent until the first visual layer'
      : 'Transparent jusqu’au premier calque visuel';
  String get positiveDurationRequired => isEnglish
      ? 'Enter a duration greater than zero.'
      : 'Saisissez une durée supérieure à zéro.';
  String get visualLayer => isEnglish ? 'Visual layer' : 'Calque visuel';
  String get name => isEnglish ? 'Name' : 'Nom';
  String get zOrder => isEnglish ? 'Z order' : 'Ordre Z';
  String get visible => isEnglish ? 'Visible' : 'Visible';
  String get locked => isEnglish ? 'Locked' : 'Verrouillé';
  String get nameRequired =>
      isEnglish ? 'The name is required.' : 'Le nom est obligatoire.';
  String get integerRequired =>
      isEnglish ? 'Enter an integer.' : 'Saisissez un entier.';
  String get landscapeOrientation =>
      isEnglish ? 'Landscape 16:9' : 'Paysage 16:9';
  String get portraitOrientation =>
      isEnglish ? 'Portrait 9:16' : 'Portrait 9:16';
  String get responsiveMedia =>
      isEnglish ? 'Responsive media' : 'Média responsive';
  String get mediaType => isEnglish ? 'Media type' : 'Type de média';
  String get image => isEnglish ? 'Image' : 'Image';
  String get sharedSource => isEnglish ? 'Shared source' : 'Source partagée';
  String get landscapeSource =>
      isEnglish ? 'Landscape source' : 'Source paysage';
  String get portraitSource =>
      isEnglish ? 'Portrait source' : 'Source portrait';
  String get usesSharedSource =>
      isEnglish ? 'Uses the shared source' : 'Utilise la source partagée';
  String compositionFor(String orientation) =>
      isEnglish ? 'Composition · $orientation' : 'Composition · $orientation';
  String get sharedValues => isEnglish ? 'Shared values' : 'Valeurs partagées';
  String get resetToShared =>
      isEnglish ? 'Reset to shared' : 'Revenir au partagé';
  String get text => isEnglish ? 'Text' : 'Texte';
  String get content => isEnglish ? 'Content' : 'Contenu';
  String get localizationKey =>
      isEnglish ? 'Localization key' : 'Clé de localisation';
  String get size => isEnglish ? 'Size' : 'Taille';
  String get font => isEnglish ? 'Font' : 'Police';
  String get color => isEnglish ? 'Color' : 'Couleur';
  String get textColor => isEnglish ? 'Text color' : 'Couleur du texte';
  String get hue => isEnglish ? 'Hue' : 'Teinte';
  String get saturation => isEnglish ? 'Saturation' : 'Saturation';
  String get brightness => isEnglish ? 'Brightness' : 'Luminosité';
  String get weight => isEnglish ? 'Weight' : 'Graisse';
  String get regular => isEnglish ? 'Regular' : 'Normale';
  String get medium => isEnglish ? 'Medium' : 'Moyenne';
  String get bold => isEnglish ? 'Bold' : 'Grasse';
  String get alignment => isEnglish ? 'Alignment' : 'Alignement';
  String get start => isEnglish ? 'Start' : 'Début';
  String get centered => isEnglish ? 'Centered' : 'Centré';
  String get end => isEnglish ? 'End' : 'Fin';
  String get wrapping => isEnglish ? 'Wrapping' : 'Retour à la ligne';
  String get automatic => isEnglish ? 'Automatic' : 'Automatique';
  String get oneLine => isEnglish ? 'One line' : 'Une ligne';
  String get respectSafeAreas =>
      isEnglish ? 'Respect safe areas' : 'Respecter les zones sûres';
  String get textRequired =>
      isEnglish ? 'The text is required.' : 'Le texte est obligatoire.';
  String get positiveSizeRequired => isEnglish
      ? 'Enter a size greater than zero.'
      : 'Saisissez une taille supérieure à zéro.';
  String get type => isEnglish ? 'Type' : 'Type';
  String get music => isEnglish ? 'Music' : 'Musique';
  String get voice => isEnglish ? 'Voice' : 'Voix';
  String get soundEffect => isEnglish ? 'Sound effect' : 'Effet sonore';
  String get volume => isEnglish ? 'Volume' : 'Volume';
  String get loop => isEnglish ? 'Loop' : 'Boucle';
  String get fadeInSeconds =>
      isEnglish ? 'Fade in (seconds)' : 'Fondu d’entrée (secondes)';
  String get fadeOutSeconds =>
      isEnglish ? 'Fade out (seconds)' : 'Fondu de sortie (secondes)';
  String get resource => isEnglish ? 'Resource' : 'Ressource';
  String get startSeconds => isEnglish ? 'Start (seconds)' : 'Début (secondes)';
  String get accessibleStyle =>
      isEnglish ? 'Accessible style' : 'Style accessible';
  String get highContrast => isEnglish ? 'High contrast' : 'Contraste renforcé';
  String get projectLocaleFallback =>
      isEnglish ? 'Project locale fallback' : 'Fallback locale projet';
  String get localeRequired =>
      isEnglish ? 'The locale is required.' : 'La locale est obligatoire.';
  String get timingMustFit => isEnglish
      ? 'Timing must be positive and remain inside the document.'
      : 'Le timing doit être positif et rester dans le document.';
  String get markerAndInteraction =>
      isEnglish ? 'Cue and interaction' : 'Repère et interaction';
  String get stableIdentity =>
      isEnglish ? 'Stable identity' : 'Identité stable';
  String get usages => isEnglish ? 'Uses' : 'Usages';
  String usageInScene(int count) => isEnglish
      ? '$count ${count == 1 ? 'use' : 'uses'} in Scene'
      : '$count ${count == 1 ? 'usage' : 'usages'} dans Scene';
  String get ordinaryMarker => isEnglish ? 'Ordinary cue' : 'Repère ordinaire';
  String get sceneInteractionPoint =>
      isEnglish ? 'Scene interaction point' : 'Point d’interaction Scene';
  String get required => isEnglish ? 'Required' : 'Requis';
  String get requiredCueValidation => isEnglish
      ? 'Validation blocks when this cue is not linked to any Scene.'
      : 'La validation bloque si ce cue n’est relié à aucune Scene.';
  String get transitionsAndAnimation =>
      isEnglish ? 'Transitions and animation' : 'Transitions et animation';
  String get curve => isEnglish ? 'Curve' : 'Courbe';
  String get transitionIn =>
      isEnglish ? 'Entrance transition' : 'Transition d’entrée';
  String get transitionOut =>
      isEnglish ? 'Exit transition' : 'Transition de sortie';
  String get transitionInDuration =>
      isEnglish ? 'Entrance duration (seconds)' : 'Durée d’entrée (secondes)';
  String get transitionOutDuration =>
      isEnglish ? 'Exit duration (seconds)' : 'Durée de sortie (secondes)';
  String get reducedMotionDescription => isEnglish
      ? 'Final preview without animated translation or rotation'
      : 'Aperçu final sans translation ni rotation animée';
  String get positionX => isEnglish ? 'X position' : 'Position X';
  String get positionY => isEnglish ? 'Y position' : 'Position Y';
  String get scale => isEnglish ? 'Scale' : 'Échelle';
  String get rotationTurns =>
      isEnglish ? 'Rotation (turns)' : 'Rotation (tours)';
  String get opacity => isEnglish ? 'Opacity' : 'Opacité';
  String get cropLeft => isEnglish ? 'Crop left' : 'Recadrage gauche';
  String get cropTop => isEnglish ? 'Crop top' : 'Recadrage haut';
  String get cropRight => isEnglish ? 'Crop right' : 'Recadrage droit';
  String get cropBottom => isEnglish ? 'Crop bottom' : 'Recadrage bas';
  String get invalidNumber =>
      isEnglish ? 'Invalid numeric value.' : 'Valeur numérique invalide.';
  String get resetSharedSource =>
      isEnglish ? 'Reset to shared source' : 'Revenir à la source partagée';
  String resetSharedSourceFor(String label) => isEnglish
      ? 'Reset to shared source for $label'
      : 'Revenir à la source partagée pour $label';
  String get saving => isEnglish ? 'Saving…' : 'Enregistrement…';
  String get undoProperty =>
      isEnglish ? 'Undo property edit' : 'Annuler la propriété';
  String get redoProperty =>
      isEnglish ? 'Redo property edit' : 'Rétablir la propriété';
  String audioBusLabel(String name) => switch (name) {
    'music' => music,
    'voice' => voice,
    'effects' => isEnglish ? 'Effects' : 'Effets',
    _ => name,
  };
  String transitionLabel(String name) => switch (name) {
    'none' => isEnglish ? 'None' : 'Aucune',
    'fade' => isEnglish ? 'Fade' : 'Fondu',
    'slideLeft' => isEnglish ? 'Slide left' : 'Glisse gauche',
    'slideRight' => isEnglish ? 'Slide right' : 'Glisse droite',
    'slideUp' => isEnglish ? 'Slide up' : 'Glisse haut',
    'slideDown' => isEnglish ? 'Slide down' : 'Glisse bas',
    _ => name,
  };
}
