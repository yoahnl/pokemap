import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_event.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_policy.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_receipt.dart';
import 'package:pokemap_loader/src/evaluation/web/evaluation_web_launcher.dart';
import 'package:pokemap_loader/src/evaluation/web/evaluation_web_server.dart';

void main() {
  test(
    'cockpit runs the real Selbrume Shop probe to completion',
    () async {
      final harness = await _EvaluationWebE2eHarness.start();
      addTearDown(harness.close);

      final runId = await harness.startRun('selbrume.shop.after-lysa');
      final events = await harness.events(runId);
      final receipt = await harness.receipt(runId);

      expect(events.first.type, 'run.started');
      expect(events.last.type, 'run.finished');
      expect(receipt.isSuccessful, isTrue);
      expect(
        receipt.evidenceLevel,
        EvaluationEvidenceLevel.diagnosticOnly,
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

final class _EvaluationWebE2eHarness {
  _EvaluationWebE2eHarness._(this.application);

  final EvaluationWebApplication application;

  static Future<_EvaluationWebE2eHarness> start() async {
    final packageRoot = Directory.current.absolute;
    final repositoryRoot = packageRoot.parent.parent;
    final application = await EvaluationWebApplication.start(
      repositoryRoot: repositoryRoot,
      assetsRoot: evaluationWebAssetsForScript(
        Uri.file(p.join(packageRoot.path, 'tool', 'pokemap_eval.dart')),
      ),
      projectId: 'selbrume',
      port: 0,
    );
    return _EvaluationWebE2eHarness._(application);
  }

  Future<String> startRun(String scenarioId) async {
    final response = await _requestJson(
      application.uri.resolve('/api/runs'),
      method: 'POST',
      token: application.server.sessionToken,
      body: <String, Object?>{
        'scenarioId': scenarioId,
        'target': EvaluationTarget.headless.name,
      },
    );
    expect(response.statusCode, HttpStatus.accepted);
    return response.json['runId']! as String;
  }

  Future<List<EvaluationEvent>> events(String runId) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(
        application.uri.resolve('/api/runs/$runId/events'),
      );
      final response = await request.close();
      expect(response.statusCode, HttpStatus.ok);

      final events = <EvaluationEvent>[];
      String? eventType;
      final data = StringBuffer();
      await for (final line
          in utf8.decoder.bind(response).transform(const LineSplitter())) {
        if (line.startsWith('event: ')) {
          eventType = line.substring('event: '.length);
        } else if (line.startsWith('data: ')) {
          data.write(line.substring('data: '.length));
        } else if (line.isEmpty && eventType != null) {
          final decoded = jsonDecode(data.toString());
          final json = Map<String, Object?>.from(decoded as Map);
          final event = EvaluationEvent(
            runId: json['runId']! as String,
            sequence: json['sequence']! as int,
            type: json['type']! as String,
            payload: Map<String, Object?>.from(json['payload']! as Map),
          );
          events.add(event);
          if (event.type == 'run.finished') break;
          eventType = null;
          data.clear();
        }
      }
      return events;
    } finally {
      client.close(force: true);
    }
  }

  Future<EvaluationReceipt> receipt(String runId) async {
    final deadline = DateTime.now().add(const Duration(seconds: 20));
    while (DateTime.now().isBefore(deadline)) {
      final response = await _requestJson(
        application.uri.resolve('/api/runs/$runId'),
      );
      if (response.statusCode == HttpStatus.ok) {
        final run = Map<String, Object?>.from(response.json['run']! as Map);
        if (run['receipt'] case final Map receiptJson) {
          return EvaluationReceipt.fromJson(
            Map<String, Object?>.from(receiptJson),
          );
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    throw TimeoutException('Receipt for $runId was not exposed by the API.');
  }

  Future<void> close() => application.close();
}

final class _JsonResponse {
  const _JsonResponse(this.statusCode, this.json);

  final int statusCode;
  final Map<String, Object?> json;
}

Future<_JsonResponse> _requestJson(
  Uri uri, {
  String method = 'GET',
  String? token,
  Map<String, Object?>? body,
}) async {
  final client = HttpClient();
  try {
    final request = await client.openUrl(method, uri);
    if (token != null) {
      request.headers.set(EvaluationWebServer.tokenHeader, token);
    }
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }
    final response = await request.close();
    final decoded = jsonDecode(await utf8.decoder.bind(response).join());
    return _JsonResponse(
      response.statusCode,
      Map<String, Object?>.from(decoded as Map),
    );
  } finally {
    client.close(force: true);
  }
}
