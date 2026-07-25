import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../ui/design_system/design_system.dart';
import '../application/game_package_export_profile.dart';
import 'game_package_export_controller.dart';

typedef GamePackageOutputPicker = Future<File?> Function(
  String suggestedFileName,
);

class GamePackageExportDialog extends StatefulWidget {
  const GamePackageExportDialog({
    super.key,
    required this.controller,
    required this.chooseOutputFile,
  });

  final GamePackageExportController controller;
  final GamePackageOutputPicker chooseOutputFile;

  @override
  State<GamePackageExportDialog> createState() =>
      _GamePackageExportDialogState();
}

class _GamePackageExportDialogState extends State<GamePackageExportDialog> {
  late final Map<String, TextEditingController> _fields;
  bool _didSyncLoadedProfile = false;

  @override
  void initState() {
    super.initState();
    _fields = _controllers(widget.controller.snapshot.draft);
    widget.controller.addListener(_handleControllerChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(widget.controller.initialize());
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChange);
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleControllerChange() {
    final snapshot = widget.controller.snapshot;
    if (!_didSyncLoadedProfile &&
        snapshot.status == GamePackageExportStatus.ready) {
      _didSyncLoadedProfile = true;
      _writeDraft(snapshot.draft);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final snapshot = widget.controller.snapshot;
    final draft = _draft();
    final profile = _validProfile(draft);
    final isBusy = snapshot.isBusy;
    return Dialog(
      backgroundColor: colors.surfaceBase,
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.borderSubtle),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 780,
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Row(
                children: <Widget>[
                  ExcludeSemantics(
                    child: Icon(
                      Icons.rocket_launch_outlined,
                      color: colors.brandPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Publier dans PokeMap Hub',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Crée une projection joueur certifiée, sans secrets '
                          'ni fichiers de travail.',
                          style: TextStyle(color: colors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.borderSubtle),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const PokeMapDiagnosticCallout(
                      severity: PokeMapDiagnosticSeverity.info,
                      title: 'Identité stable',
                      message:
                          'Le gameId est choisi une seule fois. Il ne dépend '
                          'jamais du titre ou du nom du dossier.',
                    ),
                    const SizedBox(height: 14),
                    PokeMapCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const PokeMapSectionHeader(
                            title: 'Jeu et version',
                          ),
                          const SizedBox(height: 12),
                          _responsivePair(
                            context,
                            _field(
                              'gameId',
                              'Game ID stable',
                              key: const ValueKey<String>(
                                'game-export-game-id',
                              ),
                              hint: 'games.studio.auteur.aventure',
                              autofocus: true,
                            ),
                            _field(
                              'gameVersion',
                              'Version',
                              hint: '1.0.0',
                            ),
                          ),
                          const SizedBox(height: 12),
                          _field('title', 'Titre du jeu'),
                          const SizedBox(height: 12),
                          _field(
                            'description',
                            'Description',
                            hint: 'Présentation courte pour la bibliothèque',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    PokeMapCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const PokeMapSectionHeader(
                            title: 'Auteur et langues',
                          ),
                          const SizedBox(height: 12),
                          _responsivePair(
                            context,
                            _field(
                              'authorName',
                              'Auteur ou studio',
                              key: const ValueKey<String>(
                                'game-export-author',
                              ),
                            ),
                            _field(
                              'authorUrl',
                              'Site auteur',
                              hint: 'https://example.com',
                            ),
                          ),
                          const SizedBox(height: 12),
                          _responsivePair(
                            context,
                            _field(
                              'defaultLocale',
                              'Langue principale',
                              hint: 'fr',
                            ),
                            _field(
                              'supportedLocales',
                              'Langues disponibles',
                              hint: 'fr, en',
                            ),
                          ),
                          const SizedBox(height: 12),
                          _responsivePair(
                            context,
                            _field(
                              'publisherName',
                              'Éditeur (optionnel)',
                            ),
                            _field(
                              'publisherUrl',
                              'Site de l’éditeur',
                              hint: 'https://example.com',
                            ),
                          ),
                          const SizedBox(height: 12),
                          _field(
                            'requiredCapabilities',
                            'Capacités runtime requises',
                            hint: 'capacité-1, capacité-2',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    PokeMapCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const PokeMapSectionHeader(
                            title: 'Branding déclaratif',
                          ),
                          const SizedBox(height: 12),
                          _responsivePair(
                            context,
                            _field(
                              'iconPath',
                              'Icône',
                              key: const ValueKey<String>(
                                'game-export-icon',
                              ),
                              hint: 'assets/icon.png',
                            ),
                            _field(
                              'coverPath',
                              'Couverture',
                              hint: 'assets/cover.png',
                            ),
                          ),
                          const SizedBox(height: 12),
                          _responsivePair(
                            context,
                            _field(
                              'heroPath',
                              'Illustration titre',
                              hint: 'assets/hero.png',
                            ),
                            _field(
                              'accentColor',
                              'Couleur d’accent',
                              hint: '#5B68F6',
                            ),
                          ),
                          const SizedBox(height: 12),
                          _responsivePair(
                            context,
                            _field(
                              'titleMusicPath',
                              'Musique du titre',
                              hint: 'assets/audio/title.ogg',
                            ),
                            _field(
                              'layoutVariant',
                              'Variante de mise en page',
                              hint: 'classic',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    PokeMapCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const PokeMapSectionHeader(
                            title: 'Mentions légales',
                          ),
                          const SizedBox(height: 12),
                          _responsivePair(
                            context,
                            _field(
                              'licensePath',
                              'Licence',
                              key: const ValueKey<String>(
                                'game-export-license',
                              ),
                              hint: 'LICENSE.txt',
                            ),
                            _field(
                              'creditsPath',
                              'Crédits',
                              hint: 'CREDITS.txt',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (snapshot.safeErrorMessage != null) ...[
                      const SizedBox(height: 14),
                      PokeMapDiagnosticCallout(
                        severity: PokeMapDiagnosticSeverity.error,
                        title: 'Export impossible',
                        message: snapshot.safeErrorMessage!,
                        actionLabel: 'Corriger les informations',
                        onAction: widget.controller.clearError,
                      ),
                    ],
                    if (snapshot.status == GamePackageExportStatus.succeeded &&
                        snapshot.artifact != null) ...[
                      const SizedBox(height: 14),
                      PokeMapDiagnosticCallout(
                        severity: PokeMapDiagnosticSeverity.info,
                        title: 'Package certifié',
                        message: snapshot.installRequest == null
                            ? 'Le package a été rouvert, contrôlé et certifié.'
                            : 'Le package certifié sera installé par PokeMap '
                                'Hub à sa prochaine consommation de l’inbox.',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: colors.borderSubtle),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                alignment: WrapAlignment.end,
                runAlignment: WrapAlignment.end,
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  PokeMapButton(
                    onPressed:
                        isBusy ? null : () => Navigator.maybePop(context),
                    variant: PokeMapButtonVariant.ghost,
                    child: const Text('Fermer'),
                  ),
                  PokeMapButton(
                    onPressed: profile == null ||
                            isBusy ||
                            !widget.controller.canInstallInHub
                        ? null
                        : () => widget.controller.installInHub(profile),
                    variant: PokeMapButtonVariant.secondary,
                    isLoading:
                        snapshot.status == GamePackageExportStatus.installing,
                    leading: const Icon(Icons.install_desktop_outlined),
                    child: const Text('Installer dans le Hub'),
                  ),
                  PokeMapButton(
                    onPressed: profile == null || isBusy
                        ? null
                        : () => _export(profile),
                    isLoading:
                        snapshot.status == GamePackageExportStatus.exporting,
                    leading: const Icon(Icons.archive_outlined),
                    child: const Text('Exporter le jeu'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _export(GamePackageExportProfile profile) async {
    final suggested =
        '${_slug(profile.title)}-${profile.gameVersion}.pokemapgame';
    final file = await widget.chooseOutputFile(suggested);
    if (file == null || !mounted) return;
    await widget.controller.export(profile: profile, outputFile: file);
  }

  Widget _field(
    String name,
    String label, {
    Key? key,
    String? hint,
    bool autofocus = false,
  }) =>
      PokeMapTextField(
        label: label,
        controller: _fields[name],
        fieldKey: key,
        hintText: hint,
        autofocus: autofocus,
        enabled: !widget.controller.snapshot.isBusy,
        onChanged: (_) => setState(() {}),
      );

  Widget _responsivePair(
    BuildContext context,
    Widget first,
    Widget second,
  ) =>
      LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 560) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                first,
                const SizedBox(height: 12),
                second,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: first),
              const SizedBox(width: 12),
              Expanded(child: second),
            ],
          );
        },
      );

  GamePackageExportDraft _draft() => GamePackageExportDraft(
        gameId: _fields['gameId']!.text,
        gameVersion: _fields['gameVersion']!.text,
        title: _fields['title']!.text,
        description: _fields['description']!.text,
        authorName: _fields['authorName']!.text,
        authorUrl: _fields['authorUrl']!.text,
        publisherName: _fields['publisherName']!.text,
        publisherUrl: _fields['publisherUrl']!.text,
        defaultLocale: _fields['defaultLocale']!.text,
        supportedLocales: _fields['supportedLocales']!.text,
        requiredCapabilities: _fields['requiredCapabilities']!.text,
        iconPath: _fields['iconPath']!.text,
        coverPath: _fields['coverPath']!.text,
        heroPath: _fields['heroPath']!.text,
        titleMusicPath: _fields['titleMusicPath']!.text,
        accentColor: _fields['accentColor']!.text,
        layoutVariant: _fields['layoutVariant']!.text,
        licensePath: _fields['licensePath']!.text,
        creditsPath: _fields['creditsPath']!.text,
      );

  GamePackageExportProfile? _validProfile(GamePackageExportDraft draft) {
    try {
      return draft.toProfile();
    } on GamePackageExportException {
      return null;
    }
  }

  Map<String, TextEditingController> _controllers(
    GamePackageExportDraft draft,
  ) =>
      <String, TextEditingController>{
        'gameId': TextEditingController(text: draft.gameId),
        'gameVersion': TextEditingController(text: draft.gameVersion),
        'title': TextEditingController(text: draft.title),
        'description': TextEditingController(text: draft.description),
        'authorName': TextEditingController(text: draft.authorName),
        'authorUrl': TextEditingController(text: draft.authorUrl),
        'publisherName': TextEditingController(text: draft.publisherName),
        'publisherUrl': TextEditingController(text: draft.publisherUrl),
        'defaultLocale': TextEditingController(text: draft.defaultLocale),
        'supportedLocales': TextEditingController(text: draft.supportedLocales),
        'requiredCapabilities':
            TextEditingController(text: draft.requiredCapabilities),
        'iconPath': TextEditingController(text: draft.iconPath),
        'coverPath': TextEditingController(text: draft.coverPath),
        'heroPath': TextEditingController(text: draft.heroPath),
        'titleMusicPath': TextEditingController(text: draft.titleMusicPath),
        'accentColor': TextEditingController(text: draft.accentColor),
        'layoutVariant': TextEditingController(text: draft.layoutVariant),
        'licensePath': TextEditingController(text: draft.licensePath),
        'creditsPath': TextEditingController(text: draft.creditsPath),
      };

  void _writeDraft(GamePackageExportDraft draft) {
    final values = <String, String>{
      'gameId': draft.gameId,
      'gameVersion': draft.gameVersion,
      'title': draft.title,
      'description': draft.description,
      'authorName': draft.authorName,
      'authorUrl': draft.authorUrl,
      'publisherName': draft.publisherName,
      'publisherUrl': draft.publisherUrl,
      'defaultLocale': draft.defaultLocale,
      'supportedLocales': draft.supportedLocales,
      'requiredCapabilities': draft.requiredCapabilities,
      'iconPath': draft.iconPath,
      'coverPath': draft.coverPath,
      'heroPath': draft.heroPath,
      'titleMusicPath': draft.titleMusicPath,
      'accentColor': draft.accentColor,
      'layoutVariant': draft.layoutVariant,
      'licensePath': draft.licensePath,
      'creditsPath': draft.creditsPath,
    };
    for (final entry in values.entries) {
      _fields[entry.key]!.text = entry.value;
    }
  }

  static String _slug(String value) {
    final slug = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'pokemap-game' : slug;
  }
}
