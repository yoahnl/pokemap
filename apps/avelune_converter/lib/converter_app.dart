import 'dart:async';
import 'dart:convert';
import 'dart:ui' show AppExitResponse;

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path/path.dart' as path;

import 'desktop_services.dart';
import 'asset_review_panel.dart';
import 'map_comparison.dart';
import 'vision_desktop_services.dart';
import 'vision_panel.dart';

class ConverterApp extends StatelessWidget {
  const ConverterApp({
    super.key,
    this.workflow,
    this.workflowFactory,
    this.pathPicker = pickConverterPath,
    this.planSavePicker = pickConverterPlanSavePath,
    this.folderOpener = openConverterFolder,
    this.initialSourcePath = '',
    this.initialParentPath = '',
    this.sessionStore,
    this.visionVault,
    this.visionClientFactory = openConverterVisionClient,
  });

  final ConverterWorkflow? workflow;
  final ConverterWorkflow Function()? workflowFactory;
  final ConverterPathPicker pathPicker;
  final ConverterPlanSavePicker planSavePicker;
  final ConverterFolderOpener folderOpener;
  final String initialSourcePath;
  final String initialParentPath;
  final LocalReviewSessionStore? sessionStore;
  final VisionSecretVault? visionVault;
  final ConverterVisionClientFactory visionClientFactory;

  @override
  Widget build(BuildContext context) {
    final base = studioTheme();
    final minimum = const WidgetStatePropertyAll(Size(0, 44));
    return MaterialApp(
      title: 'Avelune Converter',
      theme: base.copyWith(
        filledButtonTheme: FilledButtonThemeData(
          style: base.filledButtonTheme.style?.copyWith(minimumSize: minimum),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: base.outlinedButtonTheme.style?.copyWith(minimumSize: minimum),
        ),
        textButtonTheme: TextButtonThemeData(
          style: base.textButtonTheme.style?.copyWith(minimumSize: minimum),
        ),
      ),
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: ConverterWindow(
        workflow: workflow,
        workflowFactory: workflowFactory,
        pathPicker: pathPicker,
        planSavePicker: planSavePicker,
        folderOpener: folderOpener,
        initialSourcePath: initialSourcePath,
        initialParentPath: initialParentPath,
        sessionStore: sessionStore,
        visionVault: visionVault,
        visionClientFactory: visionClientFactory,
      ),
    );
  }
}

class ConverterWindow extends StatefulWidget {
  const ConverterWindow({
    super.key,
    required this.workflow,
    this.workflowFactory,
    required this.pathPicker,
    required this.planSavePicker,
    required this.folderOpener,
    required this.initialSourcePath,
    required this.initialParentPath,
    this.sessionStore,
    this.visionVault,
    this.visionClientFactory = openConverterVisionClient,
  });

  final ConverterWorkflow? workflow;
  final ConverterWorkflow Function()? workflowFactory;
  final ConverterPathPicker pathPicker;
  final ConverterPlanSavePicker planSavePicker;
  final ConverterFolderOpener folderOpener;
  final String initialSourcePath;
  final String initialParentPath;
  final LocalReviewSessionStore? sessionStore;
  final VisionSecretVault? visionVault;
  final ConverterVisionClientFactory visionClientFactory;

  @override
  State<ConverterWindow> createState() => _ConverterWindowState();
}

class _ConverterWindowState extends State<ConverterWindow> {
  late ConverterWorkflow _workflow =
      widget.workflow ?? widget.workflowFactory?.call() ?? ConverterWorkflow();
  late bool _ownsWorkflow = widget.workflow == null;
  late final _source = TextEditingController(text: widget.initialSourcePath);
  late final _parent = TextEditingController(text: widget.initialParentPath);
  final _name = TextEditingController(text: 'Mon projet Avelune');
  final _folder = TextEditingController(text: 'avelune-study');
  final _search = TextEditingController();
  final _selectedMaps = <int>{};
  final _decisions = <LiteralDependencyDecision>[];
  final _imageBindings = <SourceImageBinding>[];
  ConverterAssetReviewSet? _reviewSet;
  int? _reviewMapId;
  StoredReviewSession? _storedReview;
  LocalReviewSessionStore? _sessionStore;
  late final AppLifecycleListener _lifecycle;
  Future<bool>? _exitRequest;
  bool _savingSession = false;
  bool _savingPlan = false;
  bool _loadingSession = false;
  bool _reviewSourceVerified = false;
  bool _unappliedDrafts = false;
  String? _sessionNotice;
  int _sessionGeneration = 0;
  AssetOutputMode _assetOutputMode = AssetOutputMode.sharedAtlas;
  PreparedStudy? _reviewPreview;
  ConverterStudySettings? _importedSettings;
  StreamSubscription<ConverterWorkflowEvent>? _subscription;
  int _step = 0;
  int? _previewMap;
  bool _dirty = false;
  bool _studyAcknowledged = false;
  bool _allowFirstFrameAutotiles = false;
  String? _localError;
  ConverterWorkflowEventKind? _lastOutcome;
  late (String, String, String, String) _lastFormValues;

  ConverterWorkflowState get _state => _workflow.state;
  bool get _busy =>
      _state.isBusy || _savingSession || _savingPlan || _loadingSession;
  PreparedStudy? get _prepared => _state.prepared ?? _reviewPreview;
  AssetReviewSession? get _reviewSession => _reviewSet?.segments[_reviewMapId];
  (String, String, String, String) get _formValues =>
      (_source.text, _parent.text, _name.text, _folder.text);
  String get _sourceRoot {
    final value = _source.text.trim();
    return path.extension(value).toLowerCase() == '.rxproj'
        ? path.dirname(value)
        : value;
  }

  bool get _formValid {
    if (!path.isAbsolute(_sourceRoot) ||
        !path.isAbsolute(_parent.text.trim()) ||
        _name.text.trim().isEmpty ||
        !_validFolder(_folder.text.trim())) {
      return false;
    }
    try {
      _resumeSettings();
      return true;
    } on LocalReviewSessionStoreFailure {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _sessionStore = widget.sessionStore;
    _lifecycle = AppLifecycleListener(
      onExitRequested: () async => await _prepareForSessionChange()
          ? AppExitResponse.exit
          : AppExitResponse.cancel,
    );
    _lastFormValues = _formValues;
    for (final controller in [_source, _parent, _name, _folder]) {
      controller.addListener(_markEdited);
    }
    _listenToWorkflow();
  }

  void _listenToWorkflow() {
    _subscription = _workflow.events.listen((event) {
      if (!mounted) return;
      setState(() {
        if (event.kind == ConverterWorkflowEventKind.completed ||
            event.kind == ConverterWorkflowEventKind.cancelled ||
            event.kind == ConverterWorkflowEventKind.failed) {
          _lastOutcome = event.kind;
        }
      });
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    unawaited(_subscription?.cancel());
    for (final controller in [_source, _parent, _name, _folder, _search]) {
      controller.dispose();
    }
    if (_ownsWorkflow) unawaited(_workflow.dispose());
    super.dispose();
  }

  void _markEdited() {
    final values = _formValues;
    if (values == _lastFormValues) return;
    _lastFormValues = values;
    if (!mounted) return;
    setState(() {
      _dirty = true;
      _localError = null;
      _sessionNotice = null;
      if (_sourceRoot != _state.source?.rootPath) _reviewSourceVerified = false;
    });
  }

  LocalReviewResumeSettings _resumeSettings() {
    final snapshot = _state.snapshot;
    final previous = _storedReview?.resumeSettings;
    final previousAcknowledgement = previous?.profileAcknowledgement;
    final keepAcknowledgement =
        snapshot != null &&
        previousAcknowledgement?.sourceSnapshotHash == snapshot.canonicalHash &&
        previousAcknowledgement?.profileEvidenceHash ==
            snapshot.profile.evidenceHash &&
        previousAcknowledgement?.humanConfirmed == _studyAcknowledged;
    return LocalReviewResumeSettings(
      sourceRootPath: _sourceRoot,
      destinationParentPath: _parent.text.trim(),
      projectName: _name.text.trim(),
      folderName: _folder.text.trim(),
      allowFirstFrameAutotiles: _allowFirstFrameAutotiles,
      sourceScanPolicy: _state.source?.policy ?? previous?.sourceScanPolicy,
      normalizationLimits:
          previous?.normalizationLimits ??
          _importedSettings?.normalizationLimits ??
          const SourceNormalizationLimits(),
      writeLimits:
          previous?.writeLimits ??
          _importedSettings?.writeLimits ??
          sourceCatalogStudyWriteLimitsFor(_selectedMaps.length),
      profileAcknowledgement: snapshot == null || keepAcknowledgement
          ? previousAcknowledgement
          : LocalReviewProfileAcknowledgement(
              sourceSnapshotHash: snapshot.canonicalHash,
              profileEvidenceHash: snapshot.profile.evidenceHash,
              humanConfirmed: _studyAcknowledged,
              reason: _studyAcknowledged
                  ? 'Limites du profil observé acceptées pour ce projet d’étude.'
                  : '',
            ),
      dependencyDecisions: !_reviewSourceVerified && previous != null
          ? previous.dependencyDecisions
          : _decisions.map(LocalReviewDependencyDecision.fromDecision).toList(),
      imageBindings: _imageBindings,
    );
  }

  bool get _sessionUnsaved {
    final reviewSet = _reviewSet;
    if (reviewSet == null) return false;
    final stored = _storedReview;
    if (stored == null ||
        stored.reviewSet.canonicalHash != reviewSet.canonicalHash ||
        !_formValid) {
      return true;
    }
    return canonicalHashOf(_resumeSettings().toJson()) !=
        canonicalHashOf(stored.resumeSettings.toJson());
  }

  Future<LocalReviewSessionStore> _getSessionStore() async =>
      _sessionStore ??= await openConverterReviewSessionStore();

  Future<bool> _saveReviewSession() async {
    final reviewSet = _reviewSet;
    if (reviewSet == null ||
        !_formValid ||
        _unappliedDrafts ||
        _busy ||
        !_reviewSourceVerified) {
      return false;
    }
    final generation = _sessionGeneration;
    final stored = _storedReview;
    setState(() {
      _savingSession = true;
      _sessionNotice = null;
      _localError = null;
    });
    try {
      final settings = _resumeSettings();
      final store = await _getSessionStore();
      final saved = stored == null
          ? await store.create(reviewSet: reviewSet, resumeSettings: settings)
          : await store.compareAndSwap(
              reviewSet: reviewSet,
              resumeSettings: settings,
              expectedStoredRevision: stored.storedRevision,
              expectedCanonicalHash: stored.canonicalHash,
            );
      if (!mounted || generation != _sessionGeneration) return false;
      setState(() {
        _storedReview = saved;
        _sessionNotice = 'Session enregistrée';
      });
      return _reviewSet?.canonicalHash == saved.reviewSet.canonicalHash &&
          canonicalHashOf(_resumeSettings().toJson()) ==
              canonicalHashOf(saved.resumeSettings.toJson());
    } catch (error) {
      if (mounted && generation == _sessionGeneration) {
        setState(() {
          _sessionNotice = 'Enregistrement impossible';
          _localError =
              error is LocalReviewSessionStoreFailure &&
                  error.code.contains('conflict')
              ? 'Une autre fenêtre a enregistré une version plus récente. Vos corrections sont conservées ; rechargez cette session avant de réessayer.'
              : 'La session n’a pas pu être enregistrée. Vos corrections restent disponibles.';
        });
      }
      return false;
    } finally {
      if (mounted && generation == _sessionGeneration) {
        setState(() => _savingSession = false);
      }
    }
  }

  Future<bool> _prepareForSessionChange() => _exitRequest ??=
      _confirmSessionChange().whenComplete(() => _exitRequest = null);

  Future<bool> _confirmSessionChange() async {
    if (_busy) return false;
    if (!_sessionUnsaved && !_unappliedDrafts) return true;
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StudioReviewDialog(
        title: 'Conserver votre session de revue ?',
        content: Text(
          _unappliedDrafts
              ? 'Certains champs ne sont pas appliqués. Restez pour les appliquer, ou abandonnez explicitement ces changements.'
              : 'Vos décisions et corrections ne sont pas enregistrées.',
        ),
        cancelLabel: 'Rester',
        onCancelled: () => Navigator.pop(dialogContext, 'stay'),
        secondaryActionLabel: 'Abandonner les changements',
        onSecondaryAction: () => Navigator.pop(dialogContext, 'discard'),
        confirmLabel: 'Enregistrer et fermer',
        onConfirmed: _unappliedDrafts || !_formValid || !_reviewSourceVerified
            ? null
            : () => Navigator.pop(dialogContext, 'save'),
      ),
    );
    if (!mounted || choice == 'stay' || choice == null) return false;
    if (choice == 'discard') return true;
    return _saveReviewSession();
  }

  void _setStep(int step) {
    if (_unappliedDrafts && step != _step) {
      setState(
        () => _localError = 'Appliquez ou abandonnez les champs de revue avant de changer d’étape.',
      );
      return;
    }
    setState(() => _step = step);
  }

  void _acceptReviewSegment(
    AssetReviewSession next,
    Sha256Hash expectedSegmentHash,
    Sha256Hash expectedSetHash,
    int sourceMapId,
  ) {
    final current = _reviewSet;
    if (current == null ||
        sourceMapId != _reviewMapId ||
        current.canonicalHash != expectedSetHash) {
      return;
    }
    try {
      _acceptReviewSet(
        current.replaceSegment(
          sourceMapId: sourceMapId,
          next: next,
          expectedSetHash: expectedSetHash,
          expectedSegmentHash: expectedSegmentHash,
        ),
        expectedSetHash,
      );
    } on ContractError {
      return;
    }
  }

  void _acceptReviewSet(
    ConverterAssetReviewSet next,
    Sha256Hash expectedPreviousHash,
  ) {
    final current = _reviewSet;
    if (_busy ||
        !_reviewSourceVerified ||
        current == null ||
        current.canonicalHash != expectedPreviousHash ||
        current.sessionId != next.sessionId ||
        next.revision <= current.revision ||
        current.sourceSnapshotHash != next.sourceSnapshotHash ||
        current.normalizedSourceHash != next.normalizedSourceHash) {
      return;
    }
    setState(() {
      _reviewPreview ??= _prepared;
      _reviewSet = next;
      _assetOutputMode = next.outputMode;
      _dirty = true;
      _sessionNotice = null;
    });
    _workflow.invalidatePrepared();
  }

  void _changeReviewMap(int sourceMapId) {
    if (_busy ||
        _unappliedDrafts ||
        !_reviewSourceVerified ||
        _sourceRoot != _state.source?.rootPath ||
        _reviewSet?.segments.containsKey(sourceMapId) != true) {
      return;
    }
    setState(() => _reviewMapId = sourceMapId);
  }

  void _reconcileReviewMap() {
    final maps = _reviewSet?.segments.keys;
    if (maps == null || maps.isEmpty) {
      _reviewMapId = null;
    } else if (!maps.contains(_reviewMapId)) {
      _reviewMapId = maps.first;
    }
  }

  Future<void> _chooseReviewSession() => _run(() async {
    if (_busy || !await _prepareForSessionChange() || !mounted) return;
    setState(() => _loadingSession = true);
    try {
      final sessions = await (await _getSessionStore()).list();
      if (!mounted) return;
      if (sessions.isEmpty) {
        setState(() => _sessionNotice = 'Aucune session enregistrée');
        return;
      }
      final selected = await showDialog<StoredReviewSession>(
        context: context,
        builder: (dialogContext) => StudioReviewDialog(
          title: 'Reprendre une session',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final stored in sessions)
                StudioChoice(
                  key: ValueKey(
                    'load-session-${stored.reviewSet.sessionId.value}',
                  ),
                  label: stored.resumeSettings.projectName,
                  subtitle:
                      '${stored.reviewSet.selectedSourceMapIds.length} carte(s) · ${stored.reviewSet.activeCandidates.length} proposition(s) · révision ${stored.storedRevision}',
                  selected: false,
                  onTap: () => Navigator.pop(dialogContext, stored),
                ),
            ],
          ),
          confirmLabel: 'Choisir une session',
          onConfirmed: null,
          onCancelled: () => Navigator.pop(dialogContext),
        ),
      );
      if (selected != null && mounted) await _restoreReviewSession(selected);
    } finally {
      if (mounted) setState(() => _loadingSession = false);
    }
  });

  Future<void> _restoreReviewSession(
    StoredReviewSession stored, {
    String? sourceRootPath,
  }) async {
    final generation = ++_sessionGeneration;
    _workflow.invalidatePrepared();
    final settings = stored.resumeSettings;
    _source.text = sourceRootPath ?? settings.sourceRootPath;
    _parent.text = settings.destinationParentPath;
    _name.text = settings.projectName;
    _folder.text = settings.folderName;
    setState(() {
      _loadingSession = true;
      _storedReview = stored;
      _importedSettings = null;
      _reviewSet = stored.reviewSet;
      _reviewMapId = null;
      _reconcileReviewMap();
      _assetOutputMode = stored.reviewSet.outputMode;
      _selectedMaps
        ..clear()
        ..addAll(stored.reviewSet.selectedSourceMapIds);
      _decisions.clear();
      _imageBindings
        ..clear()
        ..addAll(settings.imageBindings);
      _studyAcknowledged =
          settings.profileAcknowledgement?.humanConfirmed ?? false;
      _allowFirstFrameAutotiles = settings.allowFirstFrameAutotiles;
      _reviewSourceVerified = false;
      _unappliedDrafts = false;
      _reviewPreview = null;
      _dirty = true;
      _step = 2;
      _sessionNotice = 'Vérification de la source…';
    });
    try {
      final prepared = await ConverterReviewSessionResumer.resume(
        stored: stored,
        workflow: _workflow,
        sourceRootPath: sourceRootPath,
      );
      if (!mounted || generation != _sessionGeneration) return;
      setState(() {
        _decisions
          ..clear()
          ..addAll(prepared.settings.dependencyDecisions);
        _studyAcknowledged =
            prepared.settings.profileAcknowledgement.humanConfirmed;
        _importedSettings = prepared.settings;
        _reviewPreview = null;
        _reviewSourceVerified = true;
        _dirty = false;
        _sessionNotice = 'Session reprise · source vérifiée';
      });
    } catch (error) {
      if (!mounted || generation != _sessionGeneration) return;
      setState(() {
        if (error is ConverterWorkflowFailure &&
            error.code == 'native.destination.exists') {
          _sessionNotice = 'Session conservée · destination déjà utilisée';
          _localError = 'Ce dossier contient déjà une conversion. Choisissez un nouveau nom de dossier dans Source, puis préparez la sélection pour reprendre vos corrections.';
        } else {
          _sessionNotice = 'Session conservée · source à retrouver';
          _localError = 'La source n’est pas accessible ou ne correspond plus à cette session. Vos décisions sont conservées. Sélectionnez à nouveau le dossier exact pour reprendre.';
        }
      });
    } finally {
      if (mounted && generation == _sessionGeneration) {
        setState(() => _loadingSession = false);
      }
    }
  }

  Future<void> _reselectSessionSource() => _run(() async {
    final stored = _storedReview;
    if (stored == null || _busy || _unappliedDrafts) return;
    if (!await _prepareForSessionChange() || !mounted) return;
    final selected = await widget.pathPicker(ConverterPathKind.sourceFolder);
    if (selected == null || !mounted) return;
    await _restoreReviewSession(stored, sourceRootPath: selected);
  });

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _localError = null;
      _lastOutcome = null;
    });
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      if (error is ConverterWorkflowFailure && error.code.contains('cancel')) {
        setState(() => _lastOutcome = ConverterWorkflowEventKind.cancelled);
      } else {
        setState(() => _localError = _failureMessage(error));
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _pick(ConverterPathKind kind) => _run(() async {
    if (_unappliedDrafts) return;
    if (kind != ConverterPathKind.destinationParent &&
        !await _prepareForSessionChange()) {
      return;
    }
    final selected = await widget.pathPicker(kind);
    if (selected == null || !mounted) return;
    if (kind == ConverterPathKind.destinationParent) {
      _parent.text = selected;
    } else {
      _source.text = selected;
      setState(() {
        _studyAcknowledged = false;
        _allowFirstFrameAutotiles = false;
        _reviewPreview = null;
        _reviewSet = null;
        _reviewMapId = null;
        _storedReview = null;
        _reviewSourceVerified = false;
        _sessionGeneration++;
        _step = 0;
      });
    }
  });

  Future<void> _scan() => _run(() async {
    if (!await _prepareForSessionChange() || !mounted) return;
    setState(() {
      _step = 1;
      _selectedMaps.clear();
      _importedSettings = null;
      _imageBindings.clear();
      _dirty = false;
      _studyAcknowledged = false;
      _allowFirstFrameAutotiles = false;
      _decisions.clear();
      _assetOutputMode = AssetOutputMode.sharedAtlas;
      _reviewPreview = null;
      _reviewSet = null;
      _reviewMapId = null;
      _storedReview = null;
      _reviewSourceVerified = false;
      _sessionGeneration++;
    });
    await _workflow.scanSource(
      ConverterSourceSelection(
        rootPath: _sourceRoot,
        logicalProjectNamespace: ConverterId(
          'local-${canonicalHashOf(_sourceRoot).value.substring(0, 24)}',
        ),
      ),
    );
  });

  ConverterStudySettings _settings() {
    final snapshot = _state.snapshot!;
    final ids = _selectedMaps.toList()..sort();
    return ConverterStudySettings(
      imageBindings: _imageBindings,
      projectName: _name.text.trim(),
      parentPath: _parent.text.trim(),
      folderName: _folder.text.trim(),
      selectedSourceMapIds: ids,
      profileAcknowledgement: SourceStudyAcknowledgement(
        sourceSnapshotHash: snapshot.canonicalHash,
        profileEvidenceHash: snapshot.profile.evidenceHash,
        humanConfirmed: _studyAcknowledged,
        reason: _studyAcknowledged
            ? 'Limites du profil observé acceptées pour ce projet d’étude.'
            : '',
      ),
      dependencyDecisions: _decisions,
      allowFirstFrameAutotiles: _allowFirstFrameAutotiles,
      assetOutputMode: _assetOutputMode,
      reviewSet: _reviewSet,
      normalizationLimits:
          _storedReview?.resumeSettings.normalizationLimits ??
          _importedSettings?.normalizationLimits ??
          const SourceNormalizationLimits(),
      writeLimits:
          _storedReview?.resumeSettings.writeLimits ??
          _importedSettings?.writeLimits,
    );
  }

  Future<void> _prepareCurrent() async {
    if (_unappliedDrafts) {
      throw StateError(
        'Appliquez ou abandonnez les champs de revue avant la préparation.',
      );
    }
    final generation = _sessionGeneration;
    final stored = _storedReview;
    final PreparedStudy prepared;
    if (stored != null && !_reviewSourceVerified) {
      final current = StoredReviewSession(
        reviewSet: _reviewSet ?? stored.reviewSet,
        resumeSettings: _resumeSettings(),
        storedRevision: stored.storedRevision,
      );
      prepared = await ConverterReviewSessionResumer.resume(
        stored: current,
        workflow: _workflow,
        sourceRootPath: _sourceRoot,
        destinationParentPath: _parent.text.trim(),
        folderName: _folder.text.trim(),
        projectName: _name.text.trim(),
      );
    } else {
      _workflow.updateSettings(_settings());
      prepared = await _workflow.prepareStudy();
    }
    if (!mounted || generation != _sessionGeneration) return;
    if (_reviewSet != null &&
        prepared.reviewSet?.canonicalHash != _reviewSet!.canonicalHash) {
      throw const ConverterWorkflowFailure(
        'workflow.review.mismatch',
        'Le plan ne correspond pas à la revue active. Préparez à nouveau la sélection.',
      );
    }
    setState(() {
      _dirty = false;
      _reviewPreview = null;
      if (stored != null) _importedSettings = prepared.settings;
      _reviewSet ??= prepared.reviewSet;
      _reconcileReviewMap();
      _reviewSourceVerified = true;
      _decisions
        ..clear()
        ..addAll(prepared.settings.dependencyDecisions);
      _studyAcknowledged =
          prepared.settings.profileAcknowledgement.humanConfirmed;
      _allowFirstFrameAutotiles = prepared.settings.allowFirstFrameAutotiles;
      _assetOutputMode = _reviewSet?.outputMode ?? _assetOutputMode;
      final ids = prepared.normalizedSource.maps
          .map((value) => value.map.sourceMapId)
          .toList();
      if (!ids.contains(_previewMap)) {
        _previewMap = ids.isEmpty ? null : ids.first;
      }
    });
  }

  Future<void> _prepare() => _run(_prepareCurrent);

  Future<void> _savePlan() => _run(() async {
    if (_busy || _dirty || _unappliedDrafts || _state.prepared == null) return;
    final recipe = _workflow.exportStudyPlanRecipe();
    setState(() => _savingPlan = true);
    try {
      final selected = await widget.planSavePicker();
      if (selected == null || !mounted) return;
      await const LocalStudyPlanStore().writeNew(recipe, selected);
      if (mounted) {
        setState(
          () => _sessionNotice = 'Plan enregistré. Il sera vérifié à nouveau avant toute création.',
        );
      }
    } finally {
      if (mounted) setState(() => _savingPlan = false);
    }
  });

  Future<void> _loadPlan() => _run(() async {
    if (_busy || !await _prepareForSessionChange() || !mounted) return;
    final selected = await widget.pathPicker(ConverterPathKind.planFile);
    if (selected == null || !mounted) return;
    setState(() => _loadingSession = true);
    try {
      final recipe = await const LocalStudyPlanStore().read(selected);
      if (!mounted) return;
      final previous = _workflow;
      final ownedPrevious = _ownsWorkflow;
      await _subscription?.cancel();
      _workflow = widget.workflowFactory?.call() ?? ConverterWorkflow();
      _ownsWorkflow = true;
      _listenToWorkflow();
      if (ownedPrevious) await previous.dispose();
      if (!mounted) return;
      _source.text = recipe.sourceSelection.rootPath;
      _parent.text = recipe.settings.parentPath;
      _name.text = recipe.settings.projectName;
      _folder.text = recipe.settings.folderName;
      setState(() {
        _sessionGeneration++;
        _importedSettings = recipe.settings;
        _imageBindings
          ..clear()
          ..addAll(recipe.settings.imageBindings);
        _storedReview = null;
        _reviewSet = null;
        _reviewMapId = null;
        _reviewPreview = null;
        _reviewSourceVerified = false;
        _unappliedDrafts = false;
        _selectedMaps
          ..clear()
          ..addAll(recipe.settings.selectedSourceMapIds);
        _decisions
          ..clear()
          ..addAll(recipe.settings.dependencyDecisions);
        _studyAcknowledged =
            recipe.settings.profileAcknowledgement.humanConfirmed;
        _allowFirstFrameAutotiles = recipe.settings.allowFirstFrameAutotiles;
        _assetOutputMode = recipe.settings.assetOutputMode;
        _step = 1;
      });
      final prepared = await _workflow.restoreStudyPlanRecipe(recipe);
      if (!mounted) return;
      setState(() {
        _dirty = false;
        _reviewSet = prepared.reviewSet;
        _reconcileReviewMap();
        _reviewSourceVerified = true;
        _previewMap = prepared.normalizedSource.maps.first.map.sourceMapId;
        _sessionNotice = 'Plan vérifié depuis la source actuelle. Une nouvelle approbation est nécessaire pour créer le projet.';
        _step = 4;
      });
    } finally {
      if (mounted) setState(() => _loadingSession = false);
    }
  });

  void _changeAssetOutputMode(AssetOutputMode mode) => unawaited(
    _run(() async {
      if (_busy || _unappliedDrafts || !_reviewSourceVerified) return;
      final reviewSet = _reviewSet;
      if (reviewSet != null) {
        _acceptReviewSet(
          reviewSet.changeOutputMode(
            outputMode: mode,
            expectedSetHash: reviewSet.canonicalHash,
          ),
          reviewSet.canonicalHash,
        );
        await _prepareCurrent();
        return;
      }
      setState(() {
        _reviewPreview ??= _prepared;
        _assetOutputMode = mode;
        _dirty = true;
      });
      await _prepareCurrent();
    }),
  );

  void _changeSelection(int id, bool selected) => unawaited(
    _run(() async {
      final ids = _selectedMaps.toSet();
      selected ? ids.add(id) : ids.remove(id);
      await _replaceSelection(ids);
    }),
  );

  Future<void> _replaceSelection(Set<int> ids) async {
    if (!await _prepareForSessionChange() || !mounted) return;
    setState(() {
      _selectedMaps
        ..clear()
        ..addAll(ids);
      _decisions.clear();
      _reviewPreview = null;
      _reviewSet = null;
      _reviewMapId = null;
      _storedReview = null;
      _reviewSourceVerified = false;
      _sessionGeneration++;
      _dirty = true;
    });
    _workflow.invalidatePrepared();
  }

  void _changeImageBinding(String expected, String selected) => unawaited(
    _run(() async {
      final previous = _prepared;
      final snapshot = _state.snapshot;
      if (snapshot == null || !await _prepareForSessionChange() || !mounted) {
        return;
      }
      final entry = selected.isEmpty
          ? null
          : snapshot.entries.singleWhere(
              (entry) =>
                  entry.relativePath == selected &&
                  entry.kind == SourceNodeKind.file &&
                  entry.sha256 != null,
            );
      final binding = entry == null
          ? null
          : SourceImageBinding(
              expectedReferencePath: expected,
              sourceRelativePath: entry.relativePath,
              sourceSha256: entry.sha256!,
            );
      setState(() {
        _imageBindings.removeWhere(
          (value) =>
              sourcePathCollisionKey(value.expectedReferencePath) ==
              sourcePathCollisionKey(expected),
        );
        if (binding != null) _imageBindings.add(binding);
        _reviewPreview = previous;
        _reviewSet = null;
        _reviewMapId = null;
        _storedReview = null;
        _reviewSourceVerified = false;
        _unappliedDrafts = false;
        _decisions.clear();
        _sessionGeneration++;
        _dirty = true;
      });
      _workflow.invalidatePrepared();
    }),
  );

  void _changeDependency(
    LiteralMapDependency dependency,
    LiteralDependencyDisposition disposition,
  ) => unawaited(
    _run(() async {
      final prepared = _prepared!;
      if (!await _prepareForSessionChange() || !mounted) return;
      setState(() {
        _reviewPreview = prepared;
        _reviewSet = null;
        _reviewMapId = null;
        _storedReview = null;
        _reviewSourceVerified = false;
        _sessionGeneration++;
        _decisions.removeWhere(
          (value) =>
              canonicalHashOf(value.locator.toJson()) ==
              canonicalHashOf(dependency.locator.toJson()),
        );
        _decisions.add(
          LiteralDependencyDecision(
            sourceSnapshotHash: prepared.sourceSnapshotHash,
            selectionHash: prepared.composition.selectionHash,
            locator: dependency.locator,
            targetSourceMapId: dependency.targetSourceMapId!,
            decision: disposition,
          ),
        );
        _dirty = true;
      });
      _workflow.invalidatePrepared();
    }),
  );

  Future<void> _export() => _run(() async {
    final prepared = _prepared;
    if (prepared == null ||
        !prepared.canApprove ||
        _dirty ||
        _busy ||
        _unappliedDrafts) {
      return;
    }
    var confirmed = false;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => StudioReviewDialog(
          title: 'Créer ce projet d’étude ?',
          confirmLabel: 'Créer le projet',
          onCancelled: () => Navigator.pop(dialogContext, false),
          onConfirmed: confirmed
              ? () => Navigator.pop(dialogContext, true)
              : null,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${prepared.composition.nativeMaps.length} carte(s), '
                '${prepared.composition.tilesetIds.length} atlas et '
                '${prepared.assetLibrary?.candidateBindings.length ?? 0} objet(s) approuvé(s) pour la bibliothèque.',
              ),
              const SizedBox(height: 12),
              const Text('Destination prévue'),
              SelectableText(
                path.join(
                  prepared.settings.parentPath,
                  prepared.settings.folderName,
                ),
              ),
              const SizedBox(height: 12),
              const StudioNotice(
                'Le projet sera créé dans un dossier de préparation. '
                'Les événements et le gameplay ne sont pas certifiés.',
              ),
              const SizedBox(height: 12),
              StudioToggleRow(
                key: const ValueKey('approve-plan'),
                label: 'J’approuve ce plan et les limites indiquées.',
                value: confirmed,
                onChanged: (value) => update(() => confirmed = value),
              ),
            ],
          ),
        ),
      ),
    );
    if (accepted != true || !mounted || _dirty) return;
    final approval = _workflow.approvePrepared(
      sessionRevision: prepared.sessionRevision,
      preparationHash: prepared.preparationHash,
      humanConfirmed: true,
    );
    setState(() {
      _step = 4;
      _sessionNotice = null;
    });
    await _workflow.writeApproved(approval);
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    body: FocusTraversalGroup(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _navigation(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StudioPageHeader(
                  title: [
                    'Un nouveau départ pour vos projets.',
                    'Comprendre le projet',
                    'Ressources extraites',
                    'Comparer les cartes',
                    'Créer le projet Avelune',
                  ][_step],
                  description:
                      'RPG Maker XP / Pokémon Essentials → Avelune Studio',
                  prominent: _step == 0,
                ),
                _sessionActions(),
                if (_busy) _progress(),
                if (_localError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: StudioNotice(_localError!, isError: true),
                  ),
                if (_lastOutcome == ConverterWorkflowEventKind.cancelled)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: StudioNotice(
                      'Traitement annulé. Vous pouvez relancer l’analyse ; aucun succès d’export n’est annoncé.',
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    key: const ValueKey('step-content'),
                    padding: const EdgeInsets.fromLTRB(32, 16, 32, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!_busy &&
                            (_state.failure?.stagingPath != null ||
                                _state.failure?.journalPath != null)) ...[
                          _recoveryPanel(),
                          const SizedBox(height: 24),
                        ],
                        switch (_step) {
                          0 => _sourcePage(),
                          1 => _analysisPage(),
                          2 => _resourcesPage(),
                          3 => _verificationPage(),
                          _ => _exportPage(),
                        },
                      ],
                    ),
                  ),
                ),
                _actions(),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _navigation() => StudioSidebar(
    width: 208,
    child: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        key: const ValueKey('navigation-scroll'),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 8,
                  ),
                  child: Image.asset(
                    'assets/avelune_logo.png',
                    height: 48,
                    semanticLabel: 'Avelune Converter',
                    fit: BoxFit.contain,
                  ),
                ),
                const Text('CONVERTER', textAlign: TextAlign.center),
                const SizedBox(height: 24),
                for (var index = 0; index < 5; index++)
                  StudioChoice(
                    key: ValueKey('step-$index'),
                    label: [
                      'Source',
                      'Analyse',
                      'Ressources',
                      'Vérification',
                      'Export',
                    ][index],
                    subtitle: [
                      'Choisir le projet',
                      'Voir les possibilités',
                      'Examiner les atlas',
                      'Comparer et vérifier',
                      'Revoir puis créer',
                    ][index],
                    selected: _step == index,
                    leading: Text('${index + 1}'),
                    onTap: () => _setStep(index),
                  ),
                const Spacer(),
                const StudioBadge('Traitement local', icon: Icons.computer),
                const SizedBox(height: 8),
                const StudioBadge('Projet d’étude', tone: StudioTone.info),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _sessionActions() => StudioActionBar(
    message:
        (_state.result?.published == true
            ? 'Projet d’étude publié et vérifié.'
            : _sessionNotice) ??
        (_reviewSet != null && !_formValid
            ? 'Corrigez les champs du projet avant l’enregistrement.'
            : _reviewSet == null
            ? 'Reprenez une session enregistrée ou analysez votre source.'
            : _unappliedDrafts
            ? 'Champs de revue à appliquer'
            : _sessionUnsaved
            ? 'Session à enregistrer'
            : 'Session enregistrée'),
    actions: [
      StudioButton(
        key: const ValueKey('load-conversion-plan'),
        label: 'Charger un plan local',
        icon: Icons.description_outlined,
        secondary: true,
        onPressed: _busy ? null : _loadPlan,
      ),
      StudioButton(
        key: const ValueKey('save-conversion-plan'),
        label: 'Enregistrer le plan',
        icon: Icons.save_outlined,
        secondary: true,
        onPressed:
            !_busy &&
                !_dirty &&
                !_unappliedDrafts &&
                _state.prepared?.canApprove == true
            ? _savePlan
            : null,
      ),
      StudioButton(
        key: const ValueKey('load-review-session'),
        label: 'Reprendre une session',
        icon: Icons.folder_open,
        secondary: true,
        onPressed: _busy ? null : _chooseReviewSession,
      ),
      if (_reviewSet != null)
        StudioButton(
          key: const ValueKey('save-review-session'),
          label: 'Enregistrer la session',
          icon: Icons.save_outlined,
          secondary: true,
          onPressed:
              !_busy && _formValid && !_unappliedDrafts && _reviewSourceVerified
              ? () => unawaited(_saveReviewSession())
              : null,
        ),
      if (_storedReview != null && !_reviewSourceVerified && !_busy)
        StudioButton(
          key: const ValueKey('reselect-session-source'),
          label: 'Retrouver le dossier source',
          secondary: true,
          onPressed: _reselectSessionSource,
        ),
    ],
  );

  Widget _sourcePage() {
    final input = StudioPanel(
      title: 'Votre projet source',
      radius: 16,
      children: [
        const Text(
          'Choisissez un dossier non chiffré ou son fichier Game.rxproj.',
        ),
        const SizedBox(height: 16),
        StudioPathField(
          key: const ValueKey('source-path'),
          controller: _source,
          label: 'Dossier source ou Game.rxproj',
          onSubmitted: () => FocusScope.of(context).nextFocus(),
          enabled: !_busy,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            StudioButton(
              key: const ValueKey('choose-source'),
              label: 'Choisir un dossier',
              icon: Icons.folder_open,
              secondary: true,
              onPressed: _busy
                  ? null
                  : () => _pick(ConverterPathKind.sourceFolder),
            ),
            StudioButton(
              label: 'Choisir Game.rxproj',
              secondary: true,
              onPressed: _busy
                  ? null
                  : () => _pick(ConverterPathKind.sourceProject),
            ),
            StudioButton(
              label: 'Copier le chemin',
              secondary: true,
              icon: Icons.copy,
              onPressed: _source.text.trim().isEmpty
                  ? null
                  : () => Clipboard.setData(ClipboardData(text: _sourceRoot)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        StudioPathField(
          key: const ValueKey('destination-path'),
          controller: _parent,
          label: 'Dossier parent de destination',
          onSubmitted: () => FocusScope.of(context).nextFocus(),
          enabled: !_busy,
        ),
        const SizedBox(height: 12),
        StudioButton(
          key: const ValueKey('choose-destination'),
          label: 'Choisir la destination',
          secondary: true,
          onPressed: _busy
              ? null
              : () => _pick(ConverterPathKind.destinationParent),
        ),
        const SizedBox(height: 20),
        StudioDraftField(
          key: const ValueKey('project-name'),
          value: _name.text,
          label: 'Nom du projet Avelune',
          enabled: !_busy,
          onChanged: (value) => _name.text = value,
        ),
        const SizedBox(height: 16),
        StudioDraftField(
          key: const ValueKey('folder-name'),
          value: _folder.text,
          label: 'Nom du nouveau dossier',
          enabled: !_busy,
          onChanged: (value) => _folder.text = value,
        ),
        const SizedBox(height: 16),
        if (_state.snapshot != null)
          StudioBadge(
            _profileLabel(_state.snapshot!.profile),
            tone: StudioTone.warning,
          ),
      ],
    );
    const explanation = StudioPanel(
      title: 'Ce que vous obtiendrez',
      radius: 16,
      children: [
        Text(
          'Des cartes éditables dans Avelune Studio, avec leurs tuiles et atlas réutilisables.',
        ),
        SizedBox(height: 16),
        StudioBadge(
          'Projet d’étude — cartes et ressources',
          tone: StudioTone.info,
        ),
        SizedBox(height: 16),
        Text(
          'La lecture du projet ne certifie pas ses événements, ses combats ou sa progression. Les écarts restent visibles avant création.',
        ),
        SizedBox(height: 16),
        StudioNotice(
          'Les scripts source ne sont jamais exécutés. Aucun compte, service cloud ou clé IA n’est nécessaire.',
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) =>
          constraints.maxWidth >= 1100 &&
              MediaQuery.textScalerOf(context).scale(14) <= 18
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: input),
                const SizedBox(width: 24),
                const Expanded(child: explanation),
              ],
            )
          : Column(children: [input, const SizedBox(height: 24), explanation]),
    );
  }

  Widget _analysisPage() {
    final snapshot = _state.snapshot;
    if (snapshot == null) {
      return const StudioEmptyState(
        title: 'Choisissez un projet source',
        description: 'L’analyse affichera ses données réelles et les limites de conversion.',
        icon: Icons.manage_search,
      );
    }
    final prepared = _prepared;
    final normalized = prepared?.normalizedSource ?? _state.sourceCatalog;
    final search = _search.text.trim().toLowerCase();
    final ids = _state.availableSourceMapIds
        .where((id) => _mapName(id).toLowerCase().contains(search))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioPanel(
          title: 'Extraction et adaptation',
          radius: 16,
          children: [
            Text(
              'Inventaire : ${snapshot.entries.where((value) => value.kind == SourceNodeKind.file).length} fichiers lus.',
            ),
            const SizedBox(height: 8),
            Text(
              'Cartes : ${_state.availableSourceMapIds.length} disponibles ; ${prepared?.composition.nativeMaps.length ?? 0} préparées pour Avelune.',
            ),
            const SizedBox(height: 8),
            Text(
              'Atlas : ${normalized?.tilesets.length ?? 0} extraits ; ${prepared?.composition.tilesetIds.length ?? 0} préparés.',
            ),
            const SizedBox(height: 8),
            Text(
              _eventSummary ??
                  'Événements : ${normalized?.maps.fold<int>(0, (count, value) => count + value.map.events.length) ?? 0} extraits ; préparez une sélection pour vérifier leur adaptation.',
            ),
            const SizedBox(height: 16),
            StudioBadge(
              _profileLabel(snapshot.profile),
              tone: StudioTone.warning,
            ),
            const SizedBox(height: 12),
            StudioToggleRow(
              key: const ValueKey('acknowledge-study'),
              label: 'J’accepte les limites du profil observé pour un projet d’étude.',
              description: 'Cette décision ne certifie pas une version Essentials ni le gameplay.',
              value: _studyAcknowledged,
              onChanged: _busy
                  ? null
                  : (value) => setState(() {
                      _studyAcknowledged = value;
                      _dirty = true;
                    }),
            ),
            const SizedBox(height: 12),
            StudioToggleRow(
              key: const ValueKey('allow-first-frame-autotiles'),
              label: 'Autoriser une étude statique si l’animation ne peut pas être vérifiée.',
              description: 'Les frames sont conservées ; seule la première est affichée. Cette dégradation apparaîtra dans la revue.',
              value: _allowFirstFrameAutotiles,
              onChanged: _busy
                  ? null
                  : (value) => setState(() {
                      _allowFirstFrameAutotiles = value;
                      _dirty = true;
                    }),
            ),
          ],
        ),
        const SizedBox(height: 24),
        StudioPanel(
          title: 'Cartes à convertir',
          radius: 16,
          actions: [
            Text('${_selectedMaps.length} sélectionnée(s)'),
            StudioButton(
              label: 'Tout sélectionner',
              secondary: true,
              onPressed: _busy
                  ? null
                  : () => unawaited(
                      _run(
                        () => _replaceSelection(
                          _state.availableSourceMapIds.toSet(),
                        ),
                      ),
                    ),
            ),
            StudioButton(
              label: 'Tout retirer',
              secondary: true,
              onPressed: _busy
                  ? null
                  : () => unawaited(_run(() => _replaceSelection(<int>{}))),
            ),
          ],
          children: [
            StudioSearchField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              label: 'Rechercher une carte',
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: ListView.builder(
                key: const ValueKey('map-selection'),
                itemCount: ids.length,
                itemBuilder: (context, index) => StudioToggleRow(
                  key: ValueKey('select-map-${ids[index]}'),
                  label: _mapName(ids[index]),
                  value: _selectedMaps.contains(ids[index]),
                  onChanged: _busy
                      ? null
                      : (value) => _changeSelection(ids[index], value),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _imageBindingsPanel(),
        const SizedBox(height: 24),
        _issuesPanel(),
      ],
    );
  }

  Widget _imageBindingsPanel() {
    final references = <String>{
      for (final binding in _imageBindings) binding.expectedReferencePath,
      for (final tileset
          in _prepared?.normalizedSource.tilesets ?? <NormalizedTileset>[])
        for (final reference in tileset.images)
          if ((reference.state == 'missing' ||
                  reference.state == 'ambiguous' ||
                  reference.appliedImageBinding != null) &&
              (reference.role == 'tileset' || reference.role == 'autotile'))
            '${reference.role == 'tileset' ? 'Graphics/Tilesets' : 'Graphics/Autotiles'}/${reference.sourceName}',
    }.toList()..sort();
    if (references.isEmpty) return const SizedBox.shrink();
    return StudioPanel(
      title: 'Associer les images d’atlas',
      radius: 16,
      children: [
        const Text(
          'Une image référencée manque ou reste ambiguë. Choisissez un PNG déjà présent dans le projet source, puis préparez à nouveau les cartes pour vérifier leur affichage.',
        ),
        const SizedBox(height: 16),
        for (final expected in references) ...[
          StudioSelect(
            key: ValueKey('atlas-image-binding-$expected'),
            label: 'Image pour $expected',
            value:
                _imageBindings
                    .where(
                      (binding) => binding.expectedReferencePath == expected,
                    )
                    .firstOrNull
                    ?.sourceRelativePath ??
                '',
            options: {
              '': 'Aucune association',
              for (final entry
                  in _state.snapshot?.entries ?? <SourceFileEntry>[])
                if (entry.kind == SourceNodeKind.file &&
                    entry.sha256 != null &&
                    entry.format == 'raster' &&
                    entry.relativePath.toLowerCase().endsWith('.png') &&
                    sourcePathCollisionKey(
                          path.posix.dirname(entry.relativePath),
                        ) ==
                        sourcePathCollisionKey(path.posix.dirname(expected)))
                  entry.relativePath: path.posix.basename(entry.relativePath),
            },
            onChanged: _busy
                ? null
                : (selected) => _changeImageBinding(expected, selected),
          ),
          const SizedBox(height: 12),
        ],
        const Text(
          'Ce choix sera conservé dans le plan. Les fichiers source restent intacts ; l’association ne garantit pas que les deux images soient identiques.',
        ),
      ],
    );
  }

  Widget _resourcesPage() {
    final prepared = _prepared;
    final reviewSet = _reviewSet;
    final sourceMapId = _reviewMapId;
    final names = {
      for (final source in prepared?.normalizedSource.maps ?? <SourceMapIr>[])
        source.map.sourceMapId: source.map.name,
    };
    if (prepared == null && reviewSet == null) {
      return const StudioEmptyState(
        title: 'Préparez les cartes à convertir',
        description: 'Choisissez vos cartes dans Analyse, puis préparez la sélection pour examiner leurs ressources.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StudioNotice(
          'Les tuiles gardent leurs placements source. Les objets approuvés sont ajoutés à la bibliothèque après une vérification de leurs images source.',
        ),
        const SizedBox(height: 24),
        if (reviewSet != null) ...[
          StudioSelect(
            key: const ValueKey('review-map-selector'),
            label: 'Carte à revoir',
            value: sourceMapId?.toString(),
            options: {
              for (final id in reviewSet.segments.keys)
                id.toString(): names[id]?.trim().isNotEmpty == true
                    ? names[id]!
                    : 'Carte $id',
            },
            onChanged:
                !_busy &&
                    !_unappliedDrafts &&
                    _reviewSourceVerified &&
                    _sourceRoot == _state.source?.rootPath
                ? (value) => _changeReviewMap(int.parse(value))
                : null,
          ),
          const SizedBox(height: 16),
        ],
        _assetReviewPanel(prepared),
        const SizedBox(height: 24),
        if (_reviewSession case final session?) ...[
          ConverterVisionPanel(
            key: ValueKey(
              'vision-review-$sourceMapId-${session.sessionId.value}',
            ),
            session: session,
            enabled:
                !_busy &&
                _reviewSourceVerified &&
                !_unappliedDrafts &&
                _sourceRoot == _state.source?.rootPath,
            vault: widget.visionVault,
            clientFactory: widget.visionClientFactory,
            sourceFiles: _visionSourceFiles,
            verifySource: _verifyVisionSource,
            excludedRoots: () async => [
              if (_sourceRoot.isNotEmpty) _sourceRoot,
              if (_parent.text.trim().isNotEmpty &&
                  _validFolder(_folder.text.trim()))
                path.join(_parent.text.trim(), _folder.text.trim()),
            ],
            onSessionChanged: (next, expectedHash) => _acceptReviewSegment(
              next,
              expectedHash,
              reviewSet!.canonicalHash,
              sourceMapId!,
            ),
          ),
          const SizedBox(height: 24),
        ],
        for (final tileset
            in prepared?.normalizedSource.tilesets ?? <NormalizedTileset>[])
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: StudioPanel(
              title: tileset.name.trim().isEmpty
                  ? 'Atlas ${tileset.sourceTilesetId}'
                  : tileset.name,
              radius: 16,
              children: [
                Text(
                  '${prepared!.composition.crops.where((value) => value.sourceTilesetId == tileset.sourceTilesetId).length} tuiles littérales préparées.',
                ),
                for (final reference in tileset.images)
                  Text(
                    reference.sourceName.isEmpty
                        ? 'Emplacement de ressource optionnelle inutilisé'
                        : '${reference.sourceName} — ${reference.sourceFile == null ? 'image manquante' : 'image référencée'}',
                  ),
                if (prepared.composition.draft != null)
                  ConverterAtlasPreview(
                    prepared: prepared,
                    sourceTilesetId: tileset.sourceTilesetId,
                  ),
                for (final autotile in prepared.composition.autotiles.where(
                  (value) => value.sourceTilesetId == tileset.sourceTilesetId,
                ))
                  StudioPanel(
                    compact: true,
                    children: [
                      Text(
                        'Autotile ${autotile.autotileSlot + 1} · ${autotile.sourceFrameCount} frame(s) · 48 variantes conservées',
                      ),
                      StudioBadge(
                        autotile.animationVerified
                            ? 'Animation attestée · ${autotile.frameDurationMs} ms par frame'
                            : autotile.degraded
                            ? 'Étude dégradée · première frame'
                            : 'Ressource statique',
                      ),
                      ConverterAtlasPreview(
                        prepared: prepared,
                        sourceTilesetId: tileset.sourceTilesetId,
                        autotileSlot: autotile.autotileSlot,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        for (final diagnostic
            in prepared?.assetProposalDiagnostics ??
                <LocalAssetProposalDiagnostic>[])
          StudioNotice(_assetIssueMessage(diagnostic.code, diagnostic.message)),
        for (final diagnostic
            in prepared?.assetLibrary?.diagnostics ??
                <ApprovedAssetLibraryDiagnostic>[])
          StudioNotice(
            _assetIssueMessage(diagnostic.code, diagnostic.message),
            isError: diagnostic.blocksExport,
          ),
        _issuesPanel(),
      ],
    );
  }

  Widget _assetReviewPanel(PreparedStudy? prepared) {
    final reviewSet = _reviewSet;
    final sourceMapId = _reviewMapId;
    final session = _reviewSession;
    return ConverterAssetReviewPanel(
      key: ValueKey('asset-review-$sourceMapId-${session?.sessionId.value}'),
      artifacts: prepared?.composition.draft?.artifacts ?? const [],
      limits:
          prepared?.settings.writeLimits ??
          _storedReview?.resumeSettings.writeLimits ??
          _importedSettings?.writeLimits ??
          sourceCatalogStudyWriteLimitsFor(_selectedMaps.length),
      outputMode: _assetOutputMode,
      enabled:
          !_busy &&
          _reviewSourceVerified &&
          _sourceRoot == _state.source?.rootPath,
      session: session,
      onSessionChanged: reviewSet == null || sourceMapId == null
          ? null
          : (next, expectedHash) => _acceptReviewSegment(
              next,
              expectedHash,
              reviewSet.canonicalHash,
              sourceMapId,
            ),
      onUnappliedDraftsChanged: (value) {
        if (mounted &&
            _reviewMapId == sourceMapId &&
            _reviewSet?.sessionId == reviewSet?.sessionId &&
            value != _unappliedDrafts) {
          setState(() => _unappliedDrafts = value);
        }
      },
      sourceFilePaths: _reviewSourceVerified
          ? {
              for (final entry
                  in _state.snapshot?.entries ?? <SourceFileEntry>[])
                if (entry.sha256 != null) entry.fileId: entry.relativePath,
            }
          : const {},
      availableSources:
          prepared?.assetProposalsByMap?[sourceMapId]?.sourceImages ?? const [],
      onModeChanged: _changeAssetOutputMode,
    );
  }

  Future<SourceFilePort> _visionSourceFiles() async {
    final source = _state.source;
    final snapshot = _state.snapshot;
    if (_busy ||
        !_reviewSourceVerified ||
        _unappliedDrafts ||
        source == null ||
        snapshot == null ||
        _sourceRoot != source.rootPath) {
      throw const VisionAssistanceException('vision.stale');
    }
    return ConverterVisionSourceFiles(source, snapshot);
  }

  Future<bool> _verifyVisionSource() async {
    final source = _state.source;
    final snapshot = _state.snapshot;
    if (_busy ||
        !_reviewSourceVerified ||
        _unappliedDrafts ||
        source == null ||
        snapshot == null ||
        _sourceRoot != source.rootPath) {
      return false;
    }
    final verified = await verifyConverterVisionSource(source, snapshot);
    return mounted &&
        verified &&
        !_busy &&
        _reviewSourceVerified &&
        !_unappliedDrafts &&
        _sourceRoot == source.rootPath &&
        _state.source?.canonicalHash == source.canonicalHash &&
        _state.snapshot?.canonicalHash == snapshot.canonicalHash;
  }

  Widget _verificationPage() {
    final prepared = _prepared;
    if (prepared == null) {
      return const StudioEmptyState(
        title: 'Préparez une sélection de cartes',
        description: 'La comparaison utilisera les données source et les cellules natives du plan.',
      );
    }
    final maps = prepared.normalizedSource.maps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioPanel(
          title: 'Trois vérifications distinctes',
          radius: 16,
          children: [
            Text(
              'Structure : ${prepared.composition.canWrite ? 'plan natif préparé ; relecture après création' : 'préparation bloquée'}.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Visuel : comparaison des tuiles ci-dessous ; fidélité du moteur source non certifiée.',
            ),
            const SizedBox(height: 8),
            Text(
              prepared.nativeDraft?.compositionEvidence['sourceSemantics'] !=
                      null
                  ? 'Comportement : passages et profondeur des décors calculés automatiquement sans IA pour la marche prise en charge. Les sauts et les modes dynamiques restent à adapter.'
                  : 'Comportement : événements et gameplay non certifiés.',
            ),
            if (_eventSummary != null) ...[
              const SizedBox(height: 8),
              Text(_eventSummary!),
            ],
          ],
        ),
        const SizedBox(height: 24),
        StudioSelect(
          key: const ValueKey('comparison-map'),
          label: 'Carte à comparer',
          value: _previewMap?.toString(),
          options: {
            for (final value in maps)
              value.map.sourceMapId.toString(): value.map.name,
          },
          onChanged: (value) => setState(() => _previewMap = int.parse(value)),
        ),
        const SizedBox(height: 16),
        if (_previewMap != null)
          ConverterMapComparison(
            key: ValueKey('comparison-$_previewMap'),
            prepared: prepared,
            sourceMapId: _previewMap!,
          ),
        const SizedBox(height: 24),
        _dependenciesPanel(),
        const SizedBox(height: 24),
        _issuesPanel(),
      ],
    );
  }

  Widget _dependenciesPanel() {
    final prepared = _prepared!;
    final dependencies = prepared.composition.dependencies;
    return StudioPanel(
      title: 'Cartes dépendantes',
      radius: 16,
      children: [
        if (dependencies.isEmpty)
          const Text('Aucun transfert vers une carte hors sélection détecté.'),
        for (final dependency in dependencies) ...[
          Text(
            '${_mapName(dependency.sourceMapId)} → ${dependency.targetSourceMapId == null ? 'destination dynamique inconnue' : _mapName(dependency.targetSourceMapId!)}',
          ),
          if (dependency.kind == LiteralDependencyKind.staticTransfer &&
              dependency.targetSourceMapId != null)
            StudioSelect(
              label: dependency.locator.eventId == null
                  ? 'Choix pour cette carte dépendante'
                  : 'Transfert de l’événement ${dependency.locator.eventId}',
              value: _decisionFor(dependency)?.name,
              options: const {
                'include': 'Inclure cette carte',
                'excludeStudy': 'Exclure du projet d’étude',
                'block': 'Bloquer la conversion',
              },
              onChanged:
                  _busy ||
                      !_sameSelection(prepared.settings.selectedSourceMapIds)
                  ? null
                  : (value) => _changeDependency(
                      dependency,
                      LiteralDependencyDisposition.values.byName(value),
                    ),
            )
          else
            const StudioNotice(
              'Une destination inconnue ne peut pas être incluse automatiquement.',
            ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  LiteralDependencyDisposition? _decisionFor(LiteralMapDependency dependency) {
    for (final value in _decisions) {
      if (canonicalHashOf(value.locator.toJson()) ==
          canonicalHashOf(dependency.locator.toJson())) {
        return value.decision;
      }
    }
    return dependency.decision;
  }

  bool _sameSelection(List<int> ids) =>
      ids.length == _selectedMaps.length && ids.every(_selectedMaps.contains);

  Widget _exportPage() {
    final result = _state.result;
    if (result != null && !_dirty) {
      return StudioPanel(
        title: 'Projet d’étude publié et relu',
        radius: 16,
        children: [
          const StudioBadge(
            'Structure native vérifiée',
            tone: StudioTone.success,
          ),
          const SizedBox(height: 16),
          Text(
            '${result.receipt.mapHashes.length} cartes et ${result.receipt.assetHashes.length} ressources vérifiées.',
          ),
          const SizedBox(height: 16),
          const Text('Dossier du projet'),
          SelectableText(result.projectPath),
          const SizedBox(height: 16),
          StudioButton(
            key: const ValueKey('show-result-folder'),
            label: 'Afficher le dossier',
            secondary: true,
            icon: Icons.folder_open,
            onPressed: () =>
                _run(() => widget.folderOpener(result.projectPath)),
          ),
          const SizedBox(height: 16),
          const StudioNotice(
            'Dans Avelune Studio, ouvrez ce dossier pour examiner et éditer les cartes, puis choisissez « Tester la carte » pour les essayer. Le projet d’étude est publié ; les comportements source non traduits restent signalés et le gameplay complet n’est pas certifié.',
          ),
        ],
      );
    }
    final prepared = _prepared;
    if (prepared == null) {
      return const StudioEmptyState(
        title: 'Aucun plan de conversion préparé',
        description:
            'Analysez le projet et examinez les cartes avant création.',
      );
    }
    return StudioPanel(
      title: 'Revoir le plan',
      radius: 16,
      children: [
        Text(
          '${prepared.composition.nativeMaps.length} cartes, ${prepared.composition.tilesetIds.length} atlas et ${prepared.assetLibrary?.candidateBindings.length ?? 0} objet(s) approuvé(s) pour la bibliothèque.',
        ),
        if (prepared.nativeDraft case final draft?) ...[
          const SizedBox(height: 8),
          Text(
            'Plan : ${draft.artifacts.length + draft.sourceArtifacts.length} fichiers / ${prepared.settings.writeLimits.maxArtifacts}, '
            '${draft.mutations.length} opérations / ${prepared.settings.writeLimits.maxMutations}, '
            '${draft.validatedJsonByteLength} octets / ${prepared.settings.writeLimits.maxTotalDraftJsonBytes}.',
          ),
        ],
        const SizedBox(height: 16),
        const Text('Destination prévue'),
        SelectableText(
          path.join(prepared.settings.parentPath, prepared.settings.folderName),
        ),
        const SizedBox(height: 16),
        StudioBadge(
          !_dirty && prepared.canApprove ? 'Prêt à approuver' : 'À examiner',
          tone: !_dirty && prepared.canApprove
              ? StudioTone.info
              : StudioTone.warning,
        ),
        const SizedBox(height: 16),
        if (!_studyAcknowledged)
          const StudioNotice(
            'Acceptez les limites du profil observé dans Analyse, puis préparez le plan actualisé.',
          ),
        if (_dirty)
          const StudioNotice(
            'Votre sélection ou vos choix ont changé. Une nouvelle préparation est nécessaire avant création.',
          ),
        if (_semanticProjection?['qualified'] == false)
          const StudioNotice(
            'Qualification partielle : certains passages ou effets de décor restent non pris en charge. Consultez les observations avant de créer le projet.',
          ),
        if (prepared.nativeDraft == null)
          const StudioNotice(
            'Les problèmes bloquants doivent être résolus avant création.',
            isError: true,
          ),
        const SizedBox(height: 16),
        Text(
          prepared.nativeDraft?.compositionEvidence['sourceSemantics'] != null
              ? 'La création importe le personnage source, les passages pris en charge et les décors avec leur profondeur, sans IA. Les passages non qualifiés sont fermés et signalés.'
              : 'La création conserve les tuiles littérales. Aucun événement, collision ou comportement non pris en charge n’est présenté comme converti.',
        ),
        if (_eventSummary != null) ...[
          const SizedBox(height: 8),
          Text(_eventSummary!),
        ],
        if (_directedJumpSummary case final summary?) ...[
          const SizedBox(height: 8),
          Text(summary),
          if (_directedJumpProjection?['nativeAnimationQualified'] != true ||
              _directedJumpProjection?['runtimeJourneyQualified'] != true)
            const StudioNotice(
              'Le parcours animé reste à tester dans le Player.',
            ),
        ],
        const SizedBox(height: 16),
        StudioSection(
          title: 'Détails de la préparation',
          collapsible: true,
          initiallyExpanded: false,
          children: [
            SelectableText('Source : ${prepared.sourceSnapshotHash.value}'),
            SelectableText('Plan : ${prepared.preparationHash.value}'),
            Text('Révision : ${prepared.sessionRevision}'),
          ],
        ),
        const SizedBox(height: 24),
        _issuesPanel(),
      ],
    );
  }

  Map<String, Object?>? get _eventProjection {
    final events = _prepared?.nativeDraft?.compositionEvidence['sourceEvents'];
    if (events is! Map<String, Object?>) return null;
    final projection = events['projection'];
    return projection is Map<String, Object?> ? projection : null;
  }

  String? get _eventSummary {
    final projection = _eventProjection;
    if (projection == null) return null;
    return 'Événements : ${projection['qualifiedEventCount']} adapté(s) automatiquement sans IA ; ${projection['quarantinedEventCount']} en quarantaine.';
  }

  Map<String, Object?>? get _semanticProjection {
    final semantics =
        _prepared?.nativeDraft?.compositionEvidence['sourceSemantics'];
    if (semantics is! Map<String, Object?>) return null;
    final projection = semantics['projection'];
    return projection is Map<String, Object?> ? projection : null;
  }

  Map<String, Object?>? get _directedJumpProjection {
    final semantics =
        _prepared?.nativeDraft?.compositionEvidence['sourceSemantics'];
    if (semantics is! Map<String, Object?>) return null;
    final jumps = semantics['directedJumps'];
    return jumps is Map<String, Object?> ? jumps : null;
  }

  String? get _directedJumpSummary {
    final jumps = _directedJumpProjection;
    if (jumps == null) return null;
    final preserved = ((jumps['rows'] as List?) ?? const [])
        .whereType<Map<String, Object?>>()
        .where((row) => row['nativeStatus'] == 'preservedOnly')
        .length;
    return 'Rebords : ${jumps['importedJumpCount']} importé(s) automatiquement ; '
        '$preserved conservé(s) sans saut natif.';
  }

  Widget _issuesPanel() {
    final gaps = (_semanticProjection?['gaps'] as List?) ?? const [];
    final issues = <({String code, String message, String locator, bool blocking})>[
      for (final gap in gaps.whereType<Map<String, Object?>>())
        (
          code: gap['code'] as String,
          message: _semanticIssueMessage(gap),
          locator: gap['sourceMapId'] is int
              ? _mapName(gap['sourceMapId'] as int)
              : 'Sélection actuelle',
          blocking: false,
        ),
      for (final issue
          in ((_directedJumpProjection?['diagnostics'] as List?) ?? const [])
              .whereType<Map<String, Object?>>())
        (
          code: issue['code'] as String,
          message: _directedJumpIssueMessage(issue['code'] as String),
          locator:
              '${_mapName(issue['sourceMapId'] as int)} · case (${(issue['via'] as List).join(', ')}) · ${_jumpDirectionLabel(issue['direction'])}',
          blocking: false,
        ),
      for (final event
          in ((_eventProjection?['events'] as List?) ?? const [])
              .whereType<Map<String, Object?>>())
        if (event['status'] == 'quarantinedWholeEvent')
          (
            code: 'workflow.events.quarantined',
            message: 'Cet événement reste inactif et ses données source sont conservées. Son contenu doit être adapté avant de pouvoir le jouer.',
            locator: jsonEncode({
              'source': event['locator'],
              'pointsÀAdapter': event['gaps'],
            }),
            blocking: false,
          ),
      for (final value
          in _state.snapshot?.diagnostics ?? <SourceScanDiagnostic>[])
        (
          code: value.code,
          message: value.message,
          locator: value.relativePath,
          blocking: value.blocksExtraction,
        ),
      for (final value
          in (_prepared?.normalizedSource ?? _state.sourceCatalog)
                  ?.diagnostics ??
              <SourceNormalizationDiagnostic>[])
        (
          code: value.code,
          message: value.message,
          locator: jsonEncode(value.locator.toJson()),
          blocking: value.blocksPlanning,
        ),
      for (final value
          in _prepared?.composition.diagnostics ??
              <LiteralCompositionDiagnostic>[])
        (
          code: value.code,
          message: value.message,
          locator: jsonEncode(value.locator),
          blocking: value.blocksPlanning,
        ),
      for (final value
          in _prepared?.assetProposalDiagnostics ??
              <LocalAssetProposalDiagnostic>[])
        (
          code: value.code,
          message: _assetIssueMessage(value.code, value.message),
          locator: jsonEncode(value.toJson()),
          blocking: false,
        ),
      for (final value
          in _prepared?.assetLibrary?.diagnostics ??
              <ApprovedAssetLibraryDiagnostic>[])
        (
          code: value.code,
          message: _assetIssueMessage(value.code, value.message),
          locator: jsonEncode(value.locator?.toJson()),
          blocking: value.blocksExport,
        ),
    ];
    return StudioPanel(
      title: 'À examiner avant la création',
      radius: 16,
      children: [
        Text(
          '${issues.where((value) => value.blocking).length} problème(s) bloquant(s), ${issues.where((value) => !value.blocking).length} observation(s).',
        ),
        if (issues.isNotEmpty)
          SizedBox(
            height: 260,
            child: ListView.builder(
              itemCount: issues.length,
              itemBuilder: (context, index) {
                final issue = issues[index];
                return StudioSection(
                  title: _issueTitle(issue.code, issue.blocking),
                  collapsible: true,
                  initiallyExpanded: false,
                  children: [
                    Text(issue.message),
                    const SizedBox(height: 8),
                    SelectableText(issue.locator),
                    Text(
                      issue.code,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  String _mapName(int id) {
    for (final info
        in (_prepared?.normalizedSource ?? _state.sourceCatalog)
                ?.mapHierarchy ??
            <NormalizedMapInfo>[]) {
      if (info.sourceMapId == id) {
        return '${info.name} · ${id.toString().padLeft(3, '0')}';
      }
    }
    return 'Carte ${id.toString().padLeft(3, '0')}';
  }

  Widget _recoveryPanel() => StudioPanel(
    title: _state.failure!.promotionMayHaveOccurred
        ? 'Publication à vérifier'
        : 'Préparation conservée',
    radius: 16,
    children: [
      Text('Étape interrompue : ${_phaseLabel(_state.phase)}.'),
      const SizedBox(height: 12),
      StudioNotice(
        _state.failure!.promotionMayHaveOccurred
            ? 'Le dossier final peut avoir été publié avant l’interruption. Le journal permet de vérifier son état ; les fichiers sont conservés.'
            : 'La préparation est interrompue. Vous pouvez examiner les fichiers conservés. Une nouvelle approbation sera demandée pour réessayer.',
      ),
      const SizedBox(height: 16),
      SelectableText(
        (_state.failure!.promotionMayHaveOccurred
                ? _state.failure!.destinationPath
                : _state.failure!.stagingPath) ??
            _state.failure!.stagingPath ??
            path.dirname(_state.failure!.journalPath!),
      ),
      if (_state.failure!.journalPath != null) ...[
        const SizedBox(height: 12),
        const Text('Journal de publication'),
        SelectableText(_state.failure!.journalPath!),
        const SizedBox(height: 12),
        StudioButton(
          key: const ValueKey('verify-publication-journal'),
          label: 'Vérifier la publication',
          secondary: true,
          icon: Icons.fact_check_outlined,
          onPressed: () => _run(() async {
            final recovery = await const NativeProjectPublication().reconcile(
              journalPath: _state.failure!.journalPath!,
              policy: NativePublicationPolicy(
                allowedParentRoots: [_parent.text.trim()],
                sourceRoots: [_sourceRoot],
              ),
            );
            if (!mounted) return;
            setState(() {
              _sessionNotice = switch (recovery.state) {
                NativePublicationRecoveryState.published =>
                  'Publication vérifiée : ${recovery.receipt!.projectPath}. Le gameplay complet reste non certifié.',
                NativePublicationRecoveryState.prepared => 'Préparation vérifiée, non publiée. Une nouvelle approbation reste nécessaire.',
                NativePublicationRecoveryState.incomplete => 'Préparation incomplète conservée. Aucun succès de publication établi.',
                NativePublicationRecoveryState.conflict => 'Le dossier ne correspond pas au journal. Les fichiers sont conservés.',
                NativePublicationRecoveryState.corrupt =>
                  'Le journal est invalide. Les fichiers sont conservés.',
              };
            });
          }),
        ),
      ],
      const SizedBox(height: 16),
      StudioButton(
        key: const ValueKey('show-recovered-folder'),
        label: _state.failure!.promotionMayHaveOccurred
            ? 'Afficher le dossier de sortie'
            : 'Afficher les fichiers conservés',
        secondary: true,
        icon: Icons.folder_open,
        onPressed: () => _run(
          () => widget.folderOpener(
            _state.failure!.promotionMayHaveOccurred &&
                    _state.failure!.destinationPath != null
                ? path.dirname(_state.failure!.destinationPath!)
                : _state.failure!.stagingPath ??
                      path.dirname(_state.failure!.journalPath!),
          ),
        ),
      ),
    ],
  );

  Widget _progress() {
    final progress = _savingSession || _loadingSession ? null : _state.progress;
    final total = progress?.total;
    final determinate = total != null && total > 0;
    final phase = _savingSession
        ? 'Enregistrement de la session…'
        : _loadingSession
        ? 'Reprise de la session…'
        : _phaseLabel(_state.phase);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: StudioPanel(
        compact: true,
        children: [
          Text(_state.cancellationRequested ? 'Annulation en cours…' : phase),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: determinate ? progress!.done / total : null,
            semanticsLabel: phase,
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            Text(
              '${progress.done}${total == null ? '' : ' / $total'} ${_unitLabel(progress.unit)}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _actions() => StudioActionBar(
    key: const ValueKey('action-bar'),
    message: _busy
        ? 'Les fichiers source restent en lecture seule.'
        : _dirty && _prepared != null
        ? 'Choix modifiés : préparez à nouveau le plan.'
        : 'Projet d’étude — gameplay non certifié',
    actions: [
      if (_state.isBusy)
        StudioButton(
          key: const ValueKey('cancel-job'),
          label: _state.cancellationRequested
              ? 'Annulation en cours…'
              : 'Annuler',
          secondary: true,
          onPressed: _state.cancellationRequested
              ? null
              : _workflow.cancelCurrentJob,
        )
      else if (!_busy) ...[
        if (_step > 0)
          StudioButton(
            label: 'Précédent',
            secondary: true,
            onPressed: () => _setStep(_step - 1),
          ),
        if (_step == 0)
          StudioButton(
            key: const ValueKey('analyse-project'),
            label: 'Analyser le projet',
            icon: Icons.manage_search,
            onPressed: _formValid ? _scan : null,
          )
        else if (_step == 1 || _dirty)
          StudioButton(
            key: const ValueKey('prepare-study'),
            label: 'Préparer la sélection',
            onPressed:
                _state.snapshot?.state == SourceScanState.complete &&
                    _selectedMaps.isNotEmpty &&
                    _formValid &&
                    _sourceRoot == _state.source?.rootPath
                ? _prepare
                : null,
          ),
        if (_step > 0 && _step < 4 && _prepared != null)
          StudioButton(
            label: [
              '',
              '',
              'Vérifier les ressources',
              'Comparer les cartes',
              'Revoir le plan',
            ][_step + 1],
            onPressed: () => _setStep(_step + 1),
          ),
        if (_step == 4 && _state.result == null)
          StudioButton(
            key: const ValueKey('create-study-project'),
            label: 'Créer le projet Avelune',
            onPressed: _prepared?.canApprove == true && !_dirty
                ? _export
                : null,
          ),
      ],
    ],
  );
}

bool _validFolder(String value) =>
    value.isNotEmpty &&
    value != '.' &&
    value != '..' &&
    !RegExp(r'[\\/<>:"|?*\x00-\x1f]').hasMatch(value);

String _profileLabel(SourceProfile profile) => switch (profile.state) {
  SourceProfileState.confirmed => 'Profil confirmé : ${profile.version}',
  SourceProfileState.observed =>
    'Profil observé : ${profile.version} — à examiner',
  SourceProfileState.requiresConfirmation =>
    'Profil à confirmer : indices contradictoires',
  SourceProfileState.unknown => 'Profil à confirmer : version non prouvée',
};

String _unitLabel(JobUnit unit) => switch (unit) {
  JobUnit.files => 'fichiers',
  JobUnit.maps => 'cartes',
  JobUnit.assets => 'ressources',
  JobUnit.operations => 'opérations',
};

String _phaseLabel(ConverterWorkflowPhase? phase) => switch (phase) {
  ConverterWorkflowPhase.scan => 'Inventaire du projet',
  ConverterWorkflowPhase.verifySource => 'Vérification des fichiers source',
  ConverterWorkflowPhase.normalize => 'Lecture des cartes et références',
  ConverterWorkflowPhase.compose => 'Préparation des tuiles natives',
  ConverterWorkflowPhase.writeNative => 'Création du projet Avelune',
  ConverterWorkflowPhase.verifyNative => 'Relecture du projet créé',
  ConverterWorkflowPhase.publishNative => 'Publication du projet vérifié',
  null => 'Traitement',
};

String _failureMessage(Object error) {
  if (error is ConverterWorkflowFailure) {
    if (error.code.startsWith('workflow.recipe')) {
      if (error.code.endsWith('conflict')) {
        return 'Ce fichier de plan existe déjà. Choisissez un nouveau nom.';
      }
      if (error.code.endsWith('source_overlap')) {
        return 'Enregistrez le plan dans un autre dossier que le projet source.';
      }
      if (error.code.endsWith('destination_overlap')) {
        return 'Enregistrez le plan en dehors du futur projet Avelune.';
      }
      if (error.code.endsWith('stale')) {
        return 'Ce plan ne correspond plus aux données actuelles. Relancez l’analyse de la source.';
      }
      return 'Le plan local n’a pas pu être chargé ou enregistré. Choisissez un fichier valide et accessible.';
    }
    if (error.code.contains('stale') || error.code.contains('changed')) {
      return 'Le projet source a changé. Relancez son analyse avant de créer le projet Avelune.';
    }
    if (error.code.contains('destination') || error.code.contains('parent')) {
      return 'Vérifiez la destination : choisissez un dossier parent accessible et un nouveau nom de dossier.';
    }
    if (error.code.contains('source') || error.code.contains('scan')) {
      return 'Ce projet n’a pas pu être lu. Vérifiez le dossier, les droits d’accès et le format RPG Maker XP. ${error.message}';
    }
    return 'La conversion n’a pas abouti. ${error.message}';
  }
  return 'L’opération n’a pas abouti. ${error.toString()}';
}

String _issueTitle(String code, bool blocking) {
  if (code.startsWith('jumps.')) return 'Rebord à vérifier';
  if (code == 'workflow.events.quarantined') {
    return 'Événement conservé en quarantaine';
  }
  if (code.startsWith('semantics.')) return 'Comportement source à vérifier';
  if (code.startsWith('library.')) return 'Objet proposé à vérifier';
  if (code.contains('autotile')) return 'Autotiles à prendre en charge';
  if (code.contains('depend') || code.contains('transfer')) {
    return 'Carte dépendante à examiner';
  }
  if (code.contains('image') || code.contains('asset')) {
    return 'Ressource source à vérifier';
  }
  if (code.contains('profile')) return 'Profil source à examiner';
  if (code.contains('gameplay') || code.contains('event')) {
    return 'Comportement non certifié';
  }
  return blocking ? 'Donnée bloquant la conversion' : 'Limite ou observation';
}

String _assetIssueMessage(String code, String fallback) {
  if (code == 'asset.proposal.quota') {
    return 'La reconnaissance locale dépasse le budget de cette sélection. '
        'Aucune proposition partielle n’a été conservée. Les cartes à tuiles '
        'restent disponibles ; vous pouvez sélectionner moins de cartes pour revoir les objets.';
  }
  if (code == 'asset.proposal.animated_deferred' ||
      code == 'library.animation.unsupported') {
    return 'Cette ressource animée reste dans sa représentation littérale. '
        'Son extraction comme objet de bibliothèque demande une prise en charge supplémentaire.';
  }
  if (code == 'asset.proposal.ambiguous' ||
      code == 'library.candidate.uncertainty') {
    return 'Le regroupement de ces morceaux et leur fonction restent à vérifier. '
        'L’approbation conserve les incertitudes avec les métadonnées source.';
  }
  if (code == 'library.shared_atlas.geometry') {
    return 'Ces morceaux ne forment pas un rectangle utilisable dans l’atlas source. '
        'Choisissez « Une image par objet », puis examinez et approuvez la nouvelle proposition.';
  }
  return fallback;
}

String _semanticIssueMessage(Map<String, Object?> gap) => switch (gap['code']) {
  'semantics.passage.unqualified' =>
    '${gap['unqualifiedTransitionCount']} passage(s) ordinaires dépendent de règles non prises en charge. Ils restent fermés dans ce projet. Les rebords importés sont comptés séparément.',
  'semantics.render.reflections.unqualified' =>
    '${gap['sourceTileCount']} tuile(s) utilisent des reflets ou un ordre de rendu particulier. Leurs pixels sont conservés, mais cet effet reste non certifié.',
  'semantics.occlusion.geometry' => 'Ce morceau de décor ne peut pas encore recevoir une profondeur fidèle à sa position. Il reste dans sa couche source.',
  'semantics.preview_spawn.unavailable' => 'Aucun point de départ sûr n’a été trouvé pour le test. Le démarrage de cette carte reste à définir dans Studio.',
  _ => 'Ce comportement source reste à qualifier avant de pouvoir être testé fidèlement.',
};

String _directedJumpIssueMessage(String code) => switch (code) {
  'jumps.source_event_footprint' => 'Un événement occupe le départ, le rebord ou la réception. Le saut reste inactif pour conserver cette interaction.',
  'jumps.orientation_unqualified' => 'Le sens de ce rebord n’est pas encore pris en charge. Son apparence source est conservée sans activer le saut.',
  'jumps.source_glyph_unqualified' => 'L’image ou les propriétés de ce rebord ne permettent pas un import fidèle. Sa représentation source est conservée.',
  _ =>
    'Ce rebord conserve sa représentation source ; son saut reste à adapter.',
};

String _jumpDirectionLabel(Object? direction) => switch (direction) {
  'up' => 'vers le haut',
  'right' => 'vers la droite',
  'down' => 'vers le bas',
  'left' => 'vers la gauche',
  _ => 'sens à vérifier',
};
