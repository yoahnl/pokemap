part of 'scene_focus_workspace.dart';

typedef _SceneDialoguePreview = ({
  Map<String, ProjectDialogueEntry> entries,
  Map<String, Map<String, String>> labels,
  Map<String, String> options,
  Set<String> fallbackLocales,
  String language,
});

mixin _SceneFocusDialogues on State<SceneFocusWorkspace> {
  var _language = 'source';
  Future<DialogueCatalogLanguages> Function()? _readLanguages;
  Future<DialogueCatalogLanguages>? _languages;
  var _lastSources = const <String, StoryDialogueSource>{};
  DialogueCatalogLanguages? _lastLanguages;
  _SceneDialoguePreview? _lastPreview;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final read = StoryDialogueNavigation.of(context)?.loadLanguages;
    if (_readLanguages != read) {
      _readLanguages = read;
      _languages = read?.call();
    }
    _lastPreview = null;
  }

  _SceneDialoguePreview _dialoguePreview(DialogueCatalogLanguages profile) {
    final saved = {
      for (final dialogue
          in widget.focus.document.value?.dialogues ??
              const <StoryDialogueSource>[])
        dialogue.id: dialogue,
    };
    final resolve = StoryDialogueNavigation.of(context)?.currentSource;
    final ids = {
      for (final node in widget.scene.graph.nodes)
        if (node.payload case SceneYarnDialoguePayload(:final dialogueId))
          dialogueId,
    };
    final sources = <String, StoryDialogueSource>{
      for (final id in ids)
        id: ?(resolve == null ? saved[id] : resolve(id, saved[id])),
    };
    final locales = <String>{
      ...profile.locales,
      for (final source in sources.values)
        if (source.entry.localization case final localization?) ...[
          localization.sourceLocale,
          for (final unit in localization.units) ...unit.translations.keys,
        ],
    };
    final language = locales.contains(_language) ? _language : 'source';
    if (_lastPreview case final previous?
        when previous.language == language &&
            identical(profile, _lastLanguages) &&
            mapEquals(sources, _lastSources)) {
      return previous;
    }
    final resolved = {
      for (final source in sources.values)
        source.id: previewDialogueChoices(source, language, profile),
    };
    _lastSources = sources;
    _lastLanguages = profile;
    return _lastPreview = (
      entries: {for (final source in sources.values) source.id: source.entry},
      labels: {for (final row in resolved.entries) row.key: row.value.labels},
      options: {
        'source': context.l10n.dialogueCatalogSource,
        if (ids.isNotEmpty)
          for (final locale in locales) locale: locale.toUpperCase(),
      },
      fallbackLocales: {
        for (final preview in resolved.values) ...preview.fallbackLocales,
      },
      language: language,
    );
  }
}
