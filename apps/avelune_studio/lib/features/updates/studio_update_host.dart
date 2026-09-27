import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/updates/studio_update_catalog.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/feedback/studio_notice.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class StudioUpdateHost extends StatefulWidget {
  const StudioUpdateHost({
    required this.child,
    required this.onRestartRequested,
    super.key,
  });

  final Widget child;
  final Future<bool> Function() onRestartRequested;

  @override
  State<StudioUpdateHost> createState() => _StudioUpdateHostState();
}

class _StudioUpdateHostState extends State<StudioUpdateHost> {
  static const _channel = MethodChannel('map_editor/editor_updates');

  late final http.Client _client;
  late final StudioUpdateCatalog _catalog;
  Timer? _checkTimer;
  StudioUpdateRelease? _release;
  String? _message;
  bool _opening = false;
  String? _operationId;

  @override
  void initState() {
    super.initState();
    _client = http.Client();
    _catalog = StudioUpdateCatalog(_client);
    if (!kIsWeb && kReleaseMode) {
      if (Platform.isMacOS) _channel.setMethodCallHandler(_handleNativeCall);
      _checkTimer = Timer(
        const Duration(seconds: 12),
        () => unawaited(_checkForUpdates()),
      );
    }
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    if (!kIsWeb && Platform.isMacOS) _channel.setMethodCallHandler(null);
    _client.close();
    super.dispose();
  }

  Future<void> _checkForUpdates() async {
    try {
      final installed = (await PackageInfo.fromPlatform()).version;
      final release = await _catalog.newerThan(installed);
      if (mounted) setState(() => _release = release);
    } catch (error) {
      debugPrint('Studio update check failed: $error');
    }
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method == 'manualCheckRequested') {
      await _checkForUpdates();
      return;
    }
    if (call.method != 'updateEvent' || call.arguments is! Map) return;
    final event = call.arguments as Map;
    if (event['operationId'] != _operationId) return;
    if (event['kind'] == 'restartRequested') {
      var canRestart = false;
      try {
        canRestart = await widget.onRestartRequested();
      } catch (error) {
        debugPrint('Studio update restart guard failed: $error');
      }
      if (!mounted) return;
      await _channel.invokeMethod<void>('respondToRestart', {
        'operationId': _operationId,
        'canRestart': canRestart,
      });
      if (!canRestart) {
        setState(() {
          _message = 'Enregistrez le projet avant la mise à jour.';
          _opening = false;
          _operationId = null;
        });
      }
    } else if (event['kind'] == 'failed' ||
        event['kind'] == 'cancelled' ||
        event['kind'] == 'noUpdate') {
      if (!mounted) return;
      setState(() {
        _opening = false;
        _operationId = null;
        if (event['kind'] == 'failed') {
          _message = 'La mise à jour a échoué. Réessayez.';
        }
      });
    }
  }

  Future<void> _openUpdate() async {
    final release = _release;
    if (release == null || _opening) return;
    setState(() {
      _opening = true;
      _message = null;
    });
    try {
      if (Platform.isMacOS) {
        _operationId = DateTime.now().microsecondsSinceEpoch.toString();
        await _channel.invokeMethod<void>('openUpdateFlow', {
          'operationId': _operationId,
        });
      } else {
        final opened = await launchUrl(
          release.notesUri,
          mode: LaunchMode.externalApplication,
        );
        if (!opened) throw StateError('Unable to open release notes.');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _message = 'Impossible d’ouvrir la mise à jour.');
      }
      debugPrint('Studio update launch failed: $error');
    } finally {
      if (mounted && (!Platform.isMacOS || _message != null)) {
        setState(() {
          _opening = false;
          _operationId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final release = _release;
    return Column(
      children: [
        if (release != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: StudioNotice(
                    _message ??
                        'Avelune Studio ${release.version} est disponible.',
                  ),
                ),
                const SizedBox(width: 8),
                StudioButton(
                  label: Platform.isMacOS ? 'Installer' : 'Télécharger',
                  onPressed: _opening ? null : () => unawaited(_openUpdate()),
                ),
                const SizedBox(width: 8),
                StudioButton(
                  label: 'Plus tard',
                  variant: StudioButtonVariant.quiet,
                  onPressed: _opening
                      ? null
                      : () => setState(() => _release = null),
                ),
              ],
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
