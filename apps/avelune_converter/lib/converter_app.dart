import 'dart:async';
import 'dart:convert';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_studio/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path/path.dart' as path;

import 'desktop_services.dart';
import 'map_comparison.dart';

class ConverterApp extends StatelessWidget {
  const ConverterApp({
    super.key,
    this.workflow,
    this.pathPicker = pickConverterPath,
    this.folderOpener = openConverterFolder,
    this.initialSourcePath = '',
    this.initialParentPath = '',
  });

  final ConverterWorkflow? workflow;
  final ConverterPathPicker pathPicker;
  final ConverterFolderOpener folderOpener;
  final String initialSourcePath;
  final String initialParentPath;

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
        pathPicker: pathPicker,
        folderOpener: folderOpener,
        initialSourcePath: initialSourcePath,
        initialParentPath: initialParentPath,
      ),
    );
  }
}

class ConverterWindow extends StatefulWidget {
  const ConverterWindow({
    super.key,
    required this.workflow,
    required this.pathPicker,
    required this.folderOpener,
    required this.initialSourcePath,
    required this.initialParentPath,
  });

  final ConverterWorkflow? workflow;
  final ConverterPathPicker pathPicker;
  final ConverterFolderOpener folderOpener;
  final String initialSourcePath;
  final String initialParentPath;

  @override
  State<ConverterWindow> createState() => _ConverterWindowState();
}

class _ConverterWindowState extends State<ConverterWindow> {
  late final _workflow = widget.workflow ?? ConverterWorkflow();
  late final _source = TextEditingController(text: widget.initialSourcePath);
  late final _parent = TextEditingController(text: widget.initialParentPath);
  final _name = TextEditingController(text: 'Mon projet Avelune');
  final _folder = TextEditingController(text: 'avelune-study');
  final _search = TextEditingController();
  final _selectedMaps = <int>{};
  final _decisions = <LiteralDependencyDecision>[];
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
  bool get _busy => _state.isBusy;
  PreparedStudy? get _prepared => _state.prepared;
  (String, String, String, String) get _formValues =>
      (_source.text, _parent.text, _name.text, _folder.text);
  String get _sourceRoot {
    final value = _source.text.trim();
    return path.extension(value).toLowerCase() == '.rxproj'
        ? path.dirname(value)
        : value;
  }

  bool get _formValid =>
      path.isAbsolute(_sourceRoot) &&
      path.isAbsolute(_parent.text.trim()) &&
      _name.text.trim().isNotEmpty &&
      _validFolder(_folder.text.trim());

  @override
  void initState() {
    super.initState();
    _lastFormValues = _formValues;
    for (final controller in [_source, _parent, _name, _folder]) {
      controller.addListener(_markEdited);
    }
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
    unawaited(_subscription?.cancel());
    for (final controller in [_source, _parent, _name, _folder, _search]) {
      controller.dispose();
    }
    if (widget.workflow == null) unawaited(_workflow.dispose());
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
    });
  }

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
    final selected = await widget.pathPicker(kind);
    if (selected == null || !mounted) return;
    if (kind == ConverterPathKind.destinationParent) {
      _parent.text = selected;
    } else {
      _source.text = selected;
      setState(() {
        _studyAcknowledged = false;
        _allowFirstFrameAutotiles = false;
        _step = 0;
      });
    }
  });

  Future<void> _scan() => _run(() async {
    setState(() {
      _step = 1;
      _studyAcknowledged = false;
      _allowFirstFrameAutotiles = false;
      _decisions.clear();
    });
    final snapshot = await _workflow.scanSource(
      ConverterSourceSelection(
        rootPath: _sourceRoot,
        logicalProjectNamespace: ConverterId(
          'local-${canonicalHashOf(_sourceRoot).value.substring(0, 24)}',
        ),
      ),
    );
    if (!mounted || snapshot.state != SourceScanState.complete) return;
    _selectedMaps
      ..clear()
      ..addAll(_state.availableSourceMapIds);
    if (_selectedMaps.isNotEmpty) await _prepareCurrent();
  });

  ConverterStudySettings _settings() {
    final snapshot = _state.snapshot!;
    final ids = _selectedMaps.toList()..sort();
    return ConverterStudySettings(
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
    );
  }

  Future<void> _prepareCurrent() async {
    _workflow.updateSettings(_settings());
    final prepared = await _workflow.prepareStudy();
    if (!mounted) return;
    setState(() {
      _dirty = false;
      final ids = prepared.normalizedSource.maps
          .map((value) => value.map.sourceMapId)
          .toList();
      if (!ids.contains(_previewMap)) {
        _previewMap = ids.isEmpty ? null : ids.first;
      }
    });
  }

  Future<void> _prepare() => _run(_prepareCurrent);

  void _changeSelection(int id, bool selected) {
    setState(() {
      selected ? _selectedMaps.add(id) : _selectedMaps.remove(id);
      _decisions.clear();
      _dirty = true;
    });
  }

  void _changeDependency(
    LiteralMapDependency dependency,
    LiteralDependencyDisposition disposition,
  ) {
    final prepared = _prepared!;
    setState(() {
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
  }

  Future<void> _export() => _run(() async {
    final prepared = _prepared;
    if (prepared == null || !prepared.canApprove || _dirty || _busy) return;
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
                '${prepared.composition.tilesetIds.length} atlas.',
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
                label: 'J’approuve les cartes, les dépendances et les limites de ce plan.',
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
    setState(() => _step = 4);
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
                        if (!_busy && _state.failure?.stagingPath != null) ...[
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
                    'assets/home/avelune_logo.png',
                    package: 'avelune_studio',
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
                    onTap: () => setState(() => _step = index),
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
    final normalized = prepared?.normalizedSource;
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
              'Cartes : ${normalized?.maps.length ?? 0} extraites ; ${prepared?.composition.nativeMaps.length ?? 0} préparées pour Avelune.',
            ),
            const SizedBox(height: 8),
            Text(
              'Atlas : ${normalized?.tilesets.length ?? 0} extraits ; ${prepared?.composition.tilesetIds.length ?? 0} préparés.',
            ),
            const SizedBox(height: 8),
            Text(
              'Événements : ${normalized?.maps.fold<int>(0, (count, value) => count + value.map.events.length) ?? 0} extraits ; adaptation non disponible.',
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
                  : () => setState(() {
                      _selectedMaps.addAll(_state.availableSourceMapIds);
                      _decisions.clear();
                      _dirty = true;
                    }),
            ),
            StudioButton(
              label: 'Tout retirer',
              secondary: true,
              onPressed: _busy
                  ? null
                  : () => setState(() {
                      _selectedMaps.clear();
                      _decisions.clear();
                      _dirty = true;
                    }),
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
        _issuesPanel(),
      ],
    );
  }

  Widget _resourcesPage() {
    final prepared = _prepared;
    if (prepared == null) {
      return const StudioEmptyState(
        title: 'Les ressources apparaîtront après l’analyse',
        description: 'Les atlas affichés proviennent des fichiers du projet sélectionné.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StudioNotice(
          'Les tuiles gardent leurs placements source. La reconnaissance en objets et les propositions IA ne sont pas disponibles dans cette version.',
        ),
        const SizedBox(height: 24),
        for (final tileset in prepared.normalizedSource.tilesets)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: StudioPanel(
              title: tileset.name.trim().isEmpty
                  ? 'Atlas ${tileset.sourceTilesetId}'
                  : tileset.name,
              radius: 16,
              children: [
                Text(
                  '${prepared.composition.crops.where((value) => value.sourceTilesetId == tileset.sourceTilesetId).length} tuiles littérales préparées.',
                ),
                for (final reference in tileset.images)
                  Text(
                    '${reference.sourceName} — ${reference.sourceFile == null ? 'image manquante' : 'image référencée'}',
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
        _issuesPanel(),
      ],
    );
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
            const Text('Comportement : événements et gameplay non certifiés.'),
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
        title: 'Projet d’étude créé et relu',
        radius: 16,
        children: [
          const StudioBadge(
            'Structure native vérifiée',
            tone: StudioTone.success,
          ),
          const SizedBox(height: 16),
          Text(
            '${result.receipt.mapHashes.length} cartes et ${result.receipt.assetHashes.length} images vérifiées.',
          ),
          const SizedBox(height: 16),
          const Text('Dossier du projet'),
          SelectableText(result.receipt.projectPath),
          const SizedBox(height: 16),
          StudioButton(
            key: const ValueKey('show-result-folder'),
            label: 'Afficher le dossier',
            secondary: true,
            icon: Icons.folder_open,
            onPressed: () =>
                _run(() => widget.folderOpener(result.receipt.projectPath)),
          ),
          const SizedBox(height: 16),
          const StudioNotice(
            'Dans Avelune Studio, ouvrez ce dossier pour examiner et éditer les cartes. Le projet reste en préparation ; publication et gameplay ne sont pas certifiés.',
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
          '${prepared.composition.nativeMaps.length} cartes et ${prepared.composition.tilesetIds.length} atlas dans cette préparation.',
        ),
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
        if (!prepared.composition.canWrite)
          const StudioNotice(
            'Les problèmes bloquants doivent être résolus avant création.',
            isError: true,
          ),
        const SizedBox(height: 16),
        const Text(
          'La création conserve les tuiles littérales. Aucun événement, collision ou comportement non pris en charge n’est présenté comme converti.',
        ),
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
      ],
    );
  }

  Widget _issuesPanel() {
    final issues =
        <({String code, String message, String locator, bool blocking})>[
          for (final value
              in _state.snapshot?.diagnostics ?? <SourceScanDiagnostic>[])
            (
              code: value.code,
              message: value.message,
              locator: value.relativePath,
              blocking: value.blocksExtraction,
            ),
          for (final value
              in _prepared?.normalizedSource.diagnostics ??
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
        in _prepared?.normalizedSource.mapHierarchy ?? <NormalizedMapInfo>[]) {
      if (info.sourceMapId == id) {
        return '${info.name} · ${id.toString().padLeft(3, '0')}';
      }
    }
    return 'Carte ${id.toString().padLeft(3, '0')}';
  }

  Widget _recoveryPanel() => StudioPanel(
    title: 'Préparation conservée',
    radius: 16,
    children: [
      Text('Étape interrompue : ${_phaseLabel(_state.phase)}.'),
      const SizedBox(height: 12),
      const StudioNotice(
        'Aucun projet final publié. Vous pouvez examiner les fichiers conservés. Une nouvelle approbation sera demandée pour réessayer.',
      ),
      const SizedBox(height: 16),
      SelectableText(_state.failure!.stagingPath!),
      const SizedBox(height: 16),
      StudioButton(
        key: const ValueKey('show-recovered-folder'),
        label: 'Afficher la préparation',
        secondary: true,
        icon: Icons.folder_open,
        onPressed: () =>
            _run(() => widget.folderOpener(_state.failure!.stagingPath!)),
      ),
    ],
  );

  Widget _progress() {
    final progress = _state.progress;
    final total = progress?.total;
    final determinate = total != null && total > 0;
    final phase = _phaseLabel(_state.phase);
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
      if (_busy)
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
      else ...[
        if (_step > 0)
          StudioButton(
            label: 'Précédent',
            secondary: true,
            onPressed: () => setState(() => _step--),
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
            onPressed: () => setState(() => _step++),
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
  null => 'Traitement',
};

String _failureMessage(Object error) {
  if (error is ConverterWorkflowFailure) {
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
