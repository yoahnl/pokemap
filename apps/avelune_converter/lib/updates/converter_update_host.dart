import 'dart:async';
import 'dart:io';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../converter_build_identity.dart';
import 'converter_update_catalog.dart';

class ConverterUpdateHost extends StatefulWidget {
  const ConverterUpdateHost({
    required this.child,
    required this.onPrepareUpdate,
    required this.onRestartRequested,
    required this.onOperationEnded,
    this.catalog,
    this.installedBuild,
    this.platformSupported,
    this.automaticCheck,
    this.installEnabled = true,
    super.key,
  });

  final Widget child;
  final Future<bool> Function() onPrepareUpdate;
  final Future<bool> Function() onRestartRequested;
  final VoidCallback onOperationEnded;
  final ConverterUpdateCatalog? catalog;
  final Future<ConverterInstalledBuild> Function()? installedBuild;
  final bool? platformSupported;
  final bool? automaticCheck;
  final bool installEnabled;

  @override
  State<ConverterUpdateHost> createState() => _ConverterUpdateHostState();
}

class _ConverterUpdateHostState extends State<ConverterUpdateHost> {
  static const _channel = MethodChannel('com.avelune.converter/updates');
  late final http.Client? _client;
  late final ConverterUpdateCatalog _catalog;
  Timer? _timer;
  ConverterUpdateRelease? _release;
  String? _message;
  String? _operationId;
  var _checking = false;
  var _opening = false;
  var _nativeOpened = false;
  var _restartPending = false;
  var _error = false;
  var _nativeUnavailable = false;
  var _operationSerial = 0;

  bool get _supported =>
      widget.platformSupported ?? (!kIsWeb && Platform.isMacOS);

  @override
  void initState() {
    super.initState();
    _client = widget.catalog == null ? http.Client() : null;
    _catalog = widget.catalog ?? ConverterUpdateCatalog(_client!);
    if (_supported) {
      _channel.setMethodCallHandler(_handleNativeCall);
      if (widget.automaticCheck ?? kReleaseMode) {
        _timer = Timer(
          const Duration(seconds: 12),
          () => unawaited(_check(manual: false)),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_supported) _channel.setMethodCallHandler(null);
    _client?.close();
    if (_operationId != null) {
      _operationId = null;
      widget.onOperationEnded();
    }
    super.dispose();
  }

  Future<ConverterInstalledBuild> _installedBuild() async {
    final loader = widget.installedBuild;
    if (loader != null) return loader();
    if (!kReleaseMode || ConverterBuildIdentity.current.revision == null) {
      throw UnsupportedError('The local build has no release provenance.');
    }
    final info = await PackageInfo.fromPlatform();
    return ConverterInstalledBuild(
      version: info.version,
      buildNumber: int.tryParse(info.buildNumber) ?? 0,
      bundleId: info.packageName,
    );
  }

  Future<void> _check({required bool manual}) async {
    if (!_supported || _checking || _opening) return;
    setState(() {
      _checking = true;
      _release = null;
      _message = null;
      _error = false;
    });
    try {
      final installed = await _installedBuild();
      final result = await _catalog.check(installed);
      if (!mounted) return;
      setState(() {
        _release = result.release;
        _message = switch (result.status) {
          ConverterUpdateStatus.available => null,
          ConverterUpdateStatus.current =>
            manual
                ? 'Avelune Converter est à jour (${installed.version}+${installed.buildNumber}).'
                : null,
          ConverterUpdateStatus.unpublished =>
            manual
                ? 'Le canal de mises à jour n’est pas encore publié. Réessayez plus tard.'
                : null,
        };
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _message = error is UnsupportedError
            ? 'Les mises à jour ne sont pas disponibles pour cette compilation locale.'
            : 'La vérification des mises à jour est indisponible. Réessayez plus tard.';
      });
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _openUpdate() async {
    if (!_supported ||
        _release == null ||
        _opening ||
        _checking ||
        !widget.installEnabled ||
        _nativeUnavailable) {
      return;
    }
    final operation =
        'converter-${DateTime.now().microsecondsSinceEpoch}-${++_operationSerial}';
    setState(() {
      _operationId = operation;
      _opening = true;
      _message = 'Préparation de la mise à jour…';
      _error = false;
    });
    try {
      final approved = await widget.onPrepareUpdate();
      if (!mounted || _operationId != operation) return;
      if (!approved) {
        _finish(
          operation,
          message:
              'Votre session est conservée. La mise à jour n’a pas été lancée.',
        );
        return;
      }
      final ready = await widget.onRestartRequested();
      if (!mounted || _operationId != operation) return;
      if (!ready) {
        _finish(
          operation,
          message: 'Le convertisseur est occupé. Terminez le traitement avant la mise à jour.',
        );
        return;
      }
      _nativeOpened = true;
      await _channel.invokeMethod<void>('openUpdateFlow', {
        'operationId': operation,
      });
      if (mounted && _operationId == operation) {
        setState(
          () => _message =
              'La mise à jour est ouverte. Votre session reste protégée.',
        );
      }
    } on PlatformException catch (error) {
      if (error.code == 'native_update_unconfigured') _nativeUnavailable = true;
      _finish(
        operation,
        error: true,
        message: error.code == 'native_update_unconfigured'
            ? 'Cette compilation locale ne dispose pas des mises à jour signées.'
            : 'Impossible d’ouvrir la mise à jour. Votre session est conservée.',
      );
    } catch (_) {
      _finish(
        operation,
        error: true,
        message:
            'Impossible d’ouvrir la mise à jour. Votre session est conservée.',
      );
    }
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method == 'manualCheckRequested') {
      await _check(manual: true);
      return;
    }
    if (call.method != 'updateEvent' || call.arguments is! Map) return;
    final event = call.arguments as Map;
    final operation = _operationId;
    if (operation == null ||
        !_nativeOpened ||
        event['operationId'] != operation) {
      return;
    }
    switch (event['kind']) {
      case 'restartRequested':
        if (_restartPending) return;
        _restartPending = true;
        var allowed = false;
        try {
          allowed = await widget.onRestartRequested();
        } catch (_) {
          allowed = false;
        }
        if (!mounted || _operationId != operation) return;
        try {
          await _channel.invokeMethod<void>('respondToRestart', {
            'operationId': operation,
            'canRestart': allowed,
          });
          if (!allowed) {
            _finish(
              operation,
              message: 'Le convertisseur est occupé ou la session a changé. Le redémarrage est annulé.',
            );
          }
        } catch (_) {
          _finish(
            operation,
            error: true,
            message: 'Le redémarrage n’a pas été autorisé. Votre session est conservée.',
          );
        } finally {
          if (_operationId == operation) _restartPending = false;
        }
      case 'finished':
        _finish(operation, message: 'La vérification native est terminée.');
      case 'cancelled':
        _finish(
          operation,
          message: 'Mise à jour annulée. Votre session est conservée.',
        );
      case 'failed':
        _finish(
          operation,
          error: true,
          message: 'La mise à jour a échoué. Votre session est conservée ; réessayez.',
        );
    }
  }

  void _finish(String operation, {String? message, bool error = false}) {
    if (!mounted || _operationId != operation) return;
    setState(() {
      _operationId = null;
      _opening = false;
      _nativeOpened = false;
      _restartPending = false;
      _message = message;
      _error = error;
    });
    widget.onOperationEnded();
  }

  @override
  Widget build(BuildContext context) {
    if (!_supported) return widget.child;
    final release = _release;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              StudioButton(
                key: const ValueKey('converter-check-updates'),
                label: _checking
                    ? 'Vérification…'
                    : 'Vérifier les mises à jour',
                variant: StudioButtonVariant.quiet,
                onPressed: _checking || _opening
                    ? null
                    : () => unawaited(_check(manual: true)),
              ),
              if (release != null) ...[
                StudioButton(
                  key: const ValueKey('converter-install-update'),
                  label: 'Installer',
                  onPressed:
                      _opening ||
                          _checking ||
                          !widget.installEnabled ||
                          _nativeUnavailable
                      ? null
                      : () => unawaited(_openUpdate()),
                ),
                StudioButton(
                  label: 'Plus tard',
                  variant: StudioButtonVariant.quiet,
                  onPressed: _opening
                      ? null
                      : () => setState(() {
                          _release = null;
                          _message = null;
                        }),
                ),
              ],
            ],
          ),
        ),
        if (_message != null || release != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: StudioNotice(
              _message ??
                  'Avelune Converter ${release!.version}+${release.buildNumber} est disponible.',
              isError: _error,
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
