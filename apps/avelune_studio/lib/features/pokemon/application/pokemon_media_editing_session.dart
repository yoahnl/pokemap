import 'dart:typed_data';

import '../domain/pokemon_workspace_models.dart';
import '../domain/pokemon_workspace_port.dart';
import 'pokemon_document_editing.dart';
import 'pokemon_workspace_controller.dart';
import 'pokemon_workspace_workflow.dart';

class PokemonMediaEditingSession {
  PokemonMediaEditingSession({required this.current});

  static const roles = [
    'icon',
    'party',
    'portrait',
    'frontStatic',
    'backStatic',
    'frontShinyStatic',
    'backShinyStatic',
    'overworld',
    'overworldShiny',
    'cry',
  ];

  final PokemonWorkspaceController? Function() current;
  final _probes = <String, Future<PokemonMediaFileStatus>>{};
  PokemonWorkspaceController? _owner;
  String? _speciesId;
  String? _selectedForm;
  String _role = 'icon';
  bool _disposed = false;
  late final _workflow = PokemonWorkspaceWorkflow(
    current: current,
    isActive: () => !_disposed,
    confirmDraft: () async => PokemonDraftDecision.stay,
  );

  PokemonWorkspaceController? get _controller {
    _syncOwner();
    return _owner;
  }

  void _syncOwner() {
    final controller = _disposed ? null : current();
    final id = controller?.selectedDraft?.id;
    if (!identical(controller, _owner) || id != _speciesId) {
      _owner = controller;
      _speciesId = id;
      _selectedForm = null;
      _role = 'icon';
      _probes.clear();
    }
  }

  Map<String, dynamic>? get document =>
      _controller?.selectedDraft?.document(PokemonDocumentFamily.media);

  String? get problem => _controller?.selectedDraft?.base.media?.problem;

  bool get hasMediaReference {
    final species = _controller?.selectedDraft?.document(
      PokemonDocumentFamily.species,
    );
    final reference = (species?['refs'] as Map?)?['media'];
    return reference is String && reference.isNotEmpty;
  }

  List<String> get formIds {
    final controller = _controller;
    final variants = document?['variants'] as Map? ?? const {};
    return List.unmodifiable(
      <String>{
        ...?controller?.index?.entries
            .where((entry) => entry.id == _speciesId)
            .firstOrNull
            ?.formIds,
        ...variants.keys.cast<String>(),
      }.where((form) => form.isNotEmpty),
    );
  }

  String? get formId {
    final forms = formIds;
    if (forms.contains(_selectedForm)) return _selectedForm;
    final fallback = document?['defaultFormId'];
    return forms.contains(fallback) ? fallback as String : forms.firstOrNull;
  }

  String get role {
    _syncOwner();
    return _role;
  }

  Map<String, dynamic> get _values =>
      ((document?['variants'] as Map?)?[formId] as Map?)
          ?.cast<String, dynamic>() ??
      const {};

  String? get path => _values[role] as String?;
  bool get associated => path?.isNotEmpty == true;
  bool get busy =>
      _disposed ||
      _controller?.operationActive == true ||
      _controller?.hasPendingChanges == true ||
      _workflow.choosingMedia;
  bool get canImportPng =>
      hasMediaReference &&
      problem == null &&
      formId != null &&
      const {'icon', 'party', 'portrait'}.contains(role) &&
      !associated &&
      !busy;

  bool selectForm(String value) {
    if (!formIds.contains(value)) return false;
    _selectedForm = value;
    return true;
  }

  bool selectRole(String value) {
    _syncOwner();
    if (_disposed || !roles.contains(value)) return false;
    _role = value;
    return true;
  }

  Future<PokemonMediaFileStatus>? probeRole(String role) {
    final controller = _controller;
    final values = _values;
    final paths = {
      for (final role in roles)
        if (values[role] case final String path when path.isNotEmpty) path,
    };
    _probes.removeWhere((path, _) => !paths.contains(path));
    final path = values[role];
    if (controller == null || path is! String || path.isEmpty) return null;
    return _probes.putIfAbsent(
      path,
      () => controller.port
          .probeMedia(path)
          .catchError((Object _) => PokemonMediaFileStatus.inaccessible),
    );
  }

  void setPath(String value) {
    final controller = _controller;
    final form = formId;
    if (controller == null ||
        document == null ||
        form == null ||
        !hasMediaReference ||
        problem != null) {
      return;
    }
    controller.edit(
      PokemonDocumentFamily.media,
      (json) =>
          PokemonDocumentEditing.write(json, ['variants', form, role], value),
    );
  }

  void setDefaultForm(String value) {
    final controller = _controller;
    if (controller == null ||
        document == null ||
        !hasMediaReference ||
        problem != null) {
      return;
    }
    controller.edit(
      PokemonDocumentFamily.media,
      (json) => PokemonDocumentEditing.write(json, ['defaultFormId'], value),
    );
  }

  Future<bool> choosePng(Future<String?> Function() picker) async {
    if (!canImportPng) return false;
    final controller = _controller;
    final selection = (formId!, role);
    final imported = await _workflow.chooseMenuPng(
      formId: selection.$1,
      role: selection.$2,
      picker: picker,
      isCurrentSelection: () =>
          identical(_controller, controller) && (formId, role) == selection,
    );
    if (imported) _probes.clear();
    return imported;
  }

  void dispose() {
    _disposed = true;
    _workflow.dispose();
    _probes.clear();
  }
}

class PokemonMediaReadSlot {
  (PokemonWorkspacePort, String)? _imageKey;
  Future<Uint8List?>? _image;
  (PokemonWorkspacePort, PokemonSpeciesSummary, int)? _thumbnailKey;
  Future<Uint8List?>? _thumbnail;

  Future<Uint8List?> image(PokemonWorkspacePort port, String path) {
    final key = (port, path);
    if (_imageKey != key) {
      _imageKey = key;
      _image = port.loadImage(path);
    }
    return _image!;
  }

  Future<Uint8List?> thumbnail({
    required PokemonWorkspacePort port,
    required PokemonSpeciesSummary entry,
    int mediaRevision = 0,
  }) {
    final key = (port, entry, mediaRevision);
    if (_thumbnailKey != key) {
      _thumbnailKey = key;
      _thumbnail = port.loadThumbnail(entry);
    }
    return _thumbnail!;
  }
}
