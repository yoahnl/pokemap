import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_converter_core/avelune_converter_core.dart';

import 'vision_support.dart';
import 'vision_runtime.dart';

final class VisionHttpResponse {
  VisionHttpResponse({required this.statusCode, required List<int> body})
      : body = List.unmodifiable(body);
  final int statusCode;
  final List<int> body;
}

abstract interface class VisionHttpTransport {
  Future<VisionHttpResponse> send(
      {required List<int> body,
      required String bearerToken,
      required VisionAssistancePolicy policy,
      required ScanCancellation cancellation});
}

final class OpenAiResponsesTransport implements VisionHttpTransport {
  OpenAiResponsesTransport({HttpClient Function()? clientFactory})
      : clientFactory = clientFactory ?? HttpClient.new;
  final HttpClient Function() clientFactory;
  static final Uri endpoint = Uri.parse('https://api.openai.com/v1/responses');
  @override
  Future<VisionHttpResponse> send(
      {required List<int> body,
      required String bearerToken,
      required VisionAssistancePolicy policy,
      required ScanCancellation cancellation}) async {
    validateVisionPolicy(policy);
    checkVisionCancellation(cancellation);
    requireVision(
        body.isNotEmpty &&
            body.length <= policy.maxRequestBytes &&
            body.every((b) => b >= 0 && b <= 255),
        'vision.requestQuota');
    requireVision(
        bearerToken.isNotEmpty &&
            bearerToken.length <= 4096 &&
            !RegExp(r'[\x00-\x20\x7f]').hasMatch(bearerToken),
        'vision.keyInvalid');
    final client = clientFactory();
    HttpClientRequest? pending;
    var expired = false;
    final cancel = Completer<VisionHttpResponse>();
    void check() {
      requireVision(!expired, 'vision.timeout');
      checkVisionCancellation(cancellation);
    }

    final timer = Timer.periodic(const Duration(milliseconds: 10), (_) {
      if (cancellation.isCancelled && !cancel.isCompleted) {
        expired = true;
        pending?.abort();
        client.close(force: true);
        cancel
            .completeError(const VisionAssistanceException('vision.cancelled'));
      }
    });
    Future<VisionHttpResponse> perform() async {
      client.connectionTimeout = policy.timeout;
      final outgoing = await client.postUrl(endpoint);
      pending = outgoing;
      check();
      outgoing.followRedirects = false;
      outgoing.contentLength = body.length;
      outgoing.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      outgoing.headers
          .set(HttpHeaders.authorizationHeader, 'Bearer $bearerToken');
      outgoing.add(body);
      final incoming = await outgoing.close();
      check();
      requireVision(incoming.contentLength <= policy.maxResponseBytes,
          'vision.responseQuota');
      final bytes = BytesBuilder(copy: true);
      await for (final chunk in incoming) {
        check();
        requireVision(chunk.length <= policy.maxResponseBytes - bytes.length,
            'vision.responseQuota');
        bytes.add(chunk);
      }
      check();
      return VisionHttpResponse(
          statusCode: incoming.statusCode, body: bytes.takeBytes());
    }

    try {
      return await Future.any([perform(), cancel.future])
          .timeout(policy.timeout, onTimeout: () {
        expired = true;
        pending?.abort();
        client.close(force: true);
        throw const VisionAssistanceException('vision.timeout');
      });
    } on VisionAssistanceException {
      rethrow;
    } catch (_) {
      throw const VisionAssistanceException('vision.transportFailed');
    } finally {
      expired = true;
      timer.cancel();
      client.close(force: true);
    }
  }
}
