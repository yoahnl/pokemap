import 'package:flutter/services.dart';

import '../../features/resources/domain/resource_pack_port.dart';
import '../../features/resources/domain/resource_port.dart';

final class NativeResourcePackExportSink implements ResourcePackExportSink {
  NativeResourcePackExportSink({
    this.channel = const MethodChannel('map_editor/file_access'),
  });
  final MethodChannel channel;
  final _pending = <String>{};
  final _cleanupOutcomes = <String, ResourcePackPublication>{};
  final _requeries = <String, Future<ResourcePackPublication>>{};
  Future<Map<String, Object?>> _call(
    String method,
    String token, [
    Map<String, Object?> arguments = const {},
  ]) async {
    final result = await channel.invokeMapMethod<String, Object?>(method, {
      'token': token,
      ...arguments,
    });
    if (result == null) {
      throw const ResourceFailure('Réponse native d’export absente.');
    }
    return result;
  }

  @override
  Future<ResourcePackPublication> publish({
    required String suggestedName,
    required int byteLength,
    required String rawSha256,
    required Future<List<int>> Function(int offset, int length) readChunk,
    required bool Function() isCancelled,
    required void Function() enterFinalization,
  }) async {
    String? token;
    ResourcePackPublication? outcome;
    Object? failure;
    StackTrace? stack;
    try {
      final chosen = await channel.invokeMapMethod<String, Object?>(
        'resourcePackExportChoose',
        {
          'suggestedName': suggestedName,
          'byteLength': byteLength,
          'rawSha256': rawSha256,
        },
      );
      if (chosen == null) return const ResourcePackPublication.cancelled();
      token = chosen['token'] as String?;
      if (token == null || token.isEmpty || token.length > 128) {
        throw const ResourceFailure('La session native d’export est invalide.');
      }
      var offset = 0;
      while (offset < byteLength && !isCancelled()) {
        final length = (byteLength - offset).clamp(1, 128 * 1024);
        final bytes = await readChunk(offset, length);
        if (bytes.length != length) {
          throw const ResourceFailure(
            'Le bloc lu ne correspond pas au pack préparé.',
          );
        }
        if (isCancelled()) break;
        await _call('resourcePackExportAppend', token, {
          'offset': offset,
          'bytes': Uint8List.fromList(bytes),
        });
        offset += bytes.length;
      }
      if (isCancelled()) {
        outcome = const ResourcePackPublication.cancelled();
      } else {
        await _call('resourcePackExportSeal', token);
        if (isCancelled()) {
          outcome = const ResourcePackPublication.cancelled();
        } else {
          enterFinalization();
          try {
            outcome = _outcome(await _call('resourcePackExportFinish', token));
          } on Object catch (finishFailure) {
            outcome = await _status(token, finishFailure);
          }
        }
      }
    } on Object catch (error, trace) {
      failure = error;
      stack = trace;
    }
    if (token != null && outcome?.pendingToken == null) {
      try {
        await _call('resourcePackExportRelease', token);
      } on Object catch (cleanup) {
        if (outcome?.published == true) {
          outcome = ResourcePackPublication.published(
            outcome!.path!,
            warning: _warning(
              outcome.warning,
              'Nettoyage à reprendre : $cleanup',
            ),
          );
        } else {
          final interrupted =
              '${failure ?? outcome?.warning ?? 'Export interrompu'}';
          _cleanupOutcomes[token] = ResourcePackPublication.cancelled(
            warning: interrupted,
          );
          outcome = ResourcePackPublication.pending(
            token,
            warning: '$interrupted ; nettoyage à reprendre : $cleanup',
          );
          failure = null;
        }
      }
    }
    if (failure != null) {
      Error.throwWithStackTrace(failure, stack ?? StackTrace.current);
    }
    if (outcome!.pendingToken case final String pending) _pending.add(pending);
    return outcome;
  }

  ResourcePackPublication _outcome(Map<String, Object?> value) {
    if (value['state'] == 'published') {
      final path = value['path'];
      if (path is! String || path.isEmpty) {
        throw const ResourceFailure(
          'Le chemin du fichier publié est indisponible.',
        );
      }
      return ResourcePackPublication.published(
        path,
        warning: value['warning'] as String?,
      );
    }
    if (value['state'] == 'failed') {
      return ResourcePackPublication.cancelled(
        warning:
            'La publication n’a pas eu lieu. ${value['warning'] ?? 'Le fichier préparé a été interrompu avant son renommage.'}',
      );
    }
    throw const ResourceFailure('Le statut de publication n’est pas confirmé.');
  }

  Future<ResourcePackPublication> _status(String token, Object failure) async {
    try {
      return _outcome(await _call('resourcePackExportStatus', token));
    } on Object catch (statusFailure) {
      return ResourcePackPublication.pending(
        token,
        warning:
            'Le résultat de publication doit être relu : $failure ; $statusFailure',
      );
    }
  }

  @override
  Future<ResourcePackPublication> reconcilePublication(String token) {
    if (!_pending.contains(token)) {
      return Future.error(
        const ResourceFailure(
          'Aucune publication native en attente pour cette session.',
        ),
      );
    }
    return _requeries.putIfAbsent(token, () async {
      try {
        var outcome =
            _cleanupOutcomes[token] ??
            await _status(
              token,
              const ResourceFailure('Réponse de publication indisponible.'),
            );
        if (outcome.pendingToken != null) return outcome;
        if (!outcome.published) _cleanupOutcomes[token] = outcome;
        try {
          await _call('resourcePackExportRelease', token);
        } on Object catch (cleanup) {
          if (outcome.published) {
            outcome = ResourcePackPublication.published(
              outcome.path!,
              warning: _warning(
                outcome.warning,
                'Nettoyage à reprendre : $cleanup',
              ),
            );
          } else {
            return ResourcePackPublication.pending(
              token,
              warning: 'Nettoyage à reprendre avant de fermer : $cleanup',
            );
          }
        }
        _cleanupOutcomes.remove(token);
        _pending.remove(token);
        return outcome;
      } finally {
        _requeries.remove(token);
      }
    });
  }

  String _warning(String? previous, String next) =>
      previous == null ? next : '$previous · $next';
}
