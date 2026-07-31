import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  group('AuthoringRequest', () {
    test('round-trips revision, idempotency, dry-run, and parameters', () {
      final request = AuthoringRequest(
        requestId: 'req-001',
        actionId: 'map.create',
        actionVersion: 1,
        workspaceHandle: 'workspace:demo',
        parameters: const {
          'name': 'Bourg Palette',
          'size': {'width': 32, 'height': 24},
        },
        expectedRevision: 'rev-10',
        idempotencyKey: 'idem-001',
        dryRun: true,
        extensions: const {'traceLabel': 'golden-map'},
      );

      final decoded = AuthoringRequest.fromJson(_roundTrip(request.toJson()));

      expect(decoded.toJson(), request.toJson());
      expect(decoded.dryRun, isTrue);
      expect(decoded.expectedRevision, 'rev-10');
      expect(
        () => decoded.parameters['other'] = true,
        throwsUnsupportedError,
      );
    });

    test('rejects invalid versions and unknown top-level fields', () {
      expect(
        () => AuthoringRequest(
          requestId: 'req',
          actionId: 'map.create',
          actionVersion: 0,
          workspaceHandle: 'workspace:demo',
        ),
        throwsArgumentError,
      );
      expect(
        () => AuthoringRequest.fromJson({
          ..._request().toJson(),
          'unknown': true,
        }),
        throwsFormatException,
      );
    });
  });

  group('AuthoringError', () {
    test('round-trips structured remediation without unsafe diagnostics', () {
      final error = AuthoringError(
        code: AuthoringErrorCode.revisionConflict,
        message: 'The project revision changed',
        retryable: true,
        fieldPath: r'$.expectedRevision',
        remediation: const [
          'Reload the project snapshot',
          'Plan the action again',
        ],
        details: const {
          'expected': 'rev-10',
          'actual': 'rev-11',
        },
      );

      expect(
        AuthoringError.fromJson(_roundTrip(error.toJson())).toJson(),
        error.toJson(),
      );
    });

    test('rejects stack traces and machine-local paths', () {
      expect(
        () => AuthoringError(
          code: AuthoringErrorCode.internal,
          message: 'Failure in /Users/alice/project/file.dart',
          retryable: false,
        ),
        throwsArgumentError,
      );
      expect(
        () => AuthoringError(
          code: AuthoringErrorCode.internal,
          message: 'Internal failure',
          retryable: false,
          details: const {
            'stackTrace': '#0 privateFunction (file.dart:12)',
          },
        ),
        throwsArgumentError,
      );
      expect(
        () => AuthoringError(
          code: AuthoringErrorCode.internal,
          message: r'Failure in C:\Users\alice\project\file.dart',
          retryable: false,
        ),
        throwsArgumentError,
      );
      expect(
        () => AuthoringError(
          code: AuthoringErrorCode.internal,
          message: 'Failure in /workspace/private/file.dart',
          retryable: false,
        ),
        throwsArgumentError,
      );
      expect(
        () => AuthoringError(
          code: AuthoringErrorCode.internal,
          message: 'Internal failure',
          retryable: false,
          details: const {'trace': '#0 privateFunction (file.dart:12)'},
        ),
        throwsArgumentError,
      );
      expect(
        () => AuthoringError(
          code: AuthoringErrorCode.internal,
          message: '#0 privateFunction (file.dart:12)',
          retryable: false,
        ),
        throwsArgumentError,
      );
    });
  });

  group('AuthoringDiff and AuthoringReceipt', () {
    test('sorts changes and derives stable affected resources', () {
      final mapRef = AuthoringResourceRef(kind: 'map', id: 'map-1');
      final layerRef = AuthoringResourceRef(kind: 'layer', id: 'layer-1');
      final diff = AuthoringDiff([
        AuthoringDiffEntry(
          operation: AuthoringDiffOperation.replace,
          resource: mapRef,
          path: r'$.name',
          before: 'Old',
          after: 'New',
        ),
        AuthoringDiffEntry(
          operation: AuthoringDiffOperation.add,
          resource: layerRef,
          path: r'$.layers[0]',
          after: const {'id': 'layer-1'},
        ),
        AuthoringDiffEntry(
          operation: AuthoringDiffOperation.replace,
          resource: mapRef,
          path: r'$.size.width',
          before: 16,
          after: 32,
        ),
      ]);

      expect(
        diff.entries.map((entry) => '${entry.resource.kind}:${entry.path}'),
        [
          r'layer:$.layers[0]',
          r'map:$.name',
          r'map:$.size.width',
        ],
      );
      expect(
        diff.affectedResources.map((reference) => reference.kind),
        ['layer', 'map'],
      );
      expect(
        AuthoringDiff.fromJson(_roundTrip(diff.toJson())).toJson(),
        diff.toJson(),
      );
    });

    test('preserves explicit null values in structured changes', () {
      final resource = AuthoringResourceRef(kind: 'map', id: 'map-1');
      final diff = AuthoringDiff([
        AuthoringDiffEntry(
          operation: AuthoringDiffOperation.add,
          resource: resource,
          path: r'$.nullableValue',
          after: null,
        ),
        AuthoringDiffEntry(
          operation: AuthoringDiffOperation.remove,
          resource: resource,
          path: r'$.oldNullableValue',
          before: null,
        ),
      ]);

      expect(diff.entries.first.toJson(), containsPair('after', null));
      expect(diff.entries.last.toJson(), containsPair('before', null));
      expect(
        AuthoringDiff.fromJson(_roundTrip(diff.toJson())).toJson(),
        diff.toJson(),
      );
    });

    test('round-trips receipts and compact artifact links', () {
      final artifact = AuthoringArtifactRef(
        id: 'artifact-preview-1',
        mediaType: 'image/png',
        uri: 'artifact://preview/map-1',
        byteLength: 1200,
        sha256: 'sha256:fixture',
      );
      final receipt = AuthoringReceipt(
        receiptId: 'receipt-1',
        requestId: 'req-001',
        actionId: 'map.create',
        actionVersion: 1,
        status: AuthoringReceiptStatus.planned,
        beforeRevision: 'rev-10',
        afterRevision: 'rev-10',
        createdAtUtc: '2026-07-31T08:00:00.000Z',
        diff: AuthoringDiff([
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.add,
            resource: AuthoringResourceRef(kind: 'map', id: 'map-1'),
            path: r'$',
            after: const {'id': 'map-1'},
          ),
        ]),
        artifacts: [artifact],
      );

      expect(
        AuthoringReceipt.fromJson(_roundTrip(receipt.toJson())).toJson(),
        receipt.toJson(),
      );
      expect(artifact.toJson().keys, {
        'id',
        'mediaType',
        'uri',
        'byteLength',
        'sha256',
      });
      expect(
        () => AuthoringArtifactRef(
          id: 'unsafe',
          mediaType: 'text/plain',
          uri: 'file:///Users/alice/private.txt',
        ),
        throwsArgumentError,
      );
    });

    test(
        'decoding malformed receipt values consistently throws FormatException',
        () {
      final malformed = _receipt().toJson()
        ..['createdAtUtc'] = 'not-a-timestamp';

      expect(
        () => AuthoringReceipt.fromJson(malformed),
        throwsFormatException,
      );
    });
  });

  group('AuthoringResult', () {
    test('round-trips successful data, receipt, and artifact links', () {
      final result = AuthoringResult.success(
        requestId: 'req-001',
        data: const {'planned': true},
        receipt: _receipt(),
        artifacts: [
          AuthoringArtifactRef(
            id: 'artifact-1',
            mediaType: 'application/json',
            uri: 'artifact://diff/receipt-1',
          ),
        ],
        extensions: const {'transportHint': 'inline'},
      );

      final decoded = AuthoringResult.fromJson(_roundTrip(result.toJson()));

      expect(decoded.toJson(), result.toJson());
      expect(decoded.status, AuthoringResultStatus.success);
      expect(decoded.error, isNull);
    });

    test('round-trips a structured failure', () {
      final result = AuthoringResult.failure(
        requestId: 'req-002',
        error: AuthoringError(
          code: AuthoringErrorCode.permissionDenied,
          message: 'Project write permission is required',
          retryable: false,
          remediation: const ['Request project.write permission'],
        ),
      );

      final decoded = AuthoringResult.fromJson(_roundTrip(result.toJson()));

      expect(decoded.toJson(), result.toJson());
      expect(decoded.status, AuthoringResultStatus.failure);
      expect(decoded.error?.code, AuthoringErrorCode.permissionDenied);
    });

    test('rejects contradictory success and failure states', () {
      expect(
        () => AuthoringResult(
          requestId: 'req',
          status: AuthoringResultStatus.success,
          error: AuthoringError(
            code: AuthoringErrorCode.internal,
            message: 'Safe failure',
            retryable: false,
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => AuthoringResult(
          requestId: 'req',
          status: AuthoringResultStatus.failure,
        ),
        throwsArgumentError,
      );
      expect(
        () => AuthoringResult.fromJson({
          ...AuthoringResult.failure(
            requestId: 'req',
            error: AuthoringError(
              code: AuthoringErrorCode.internal,
              message: 'Safe failure',
              retryable: false,
            ),
          ).toJson(),
          'status': 'future_status',
        }),
        throwsFormatException,
      );
    });
  });
}

AuthoringRequest _request() {
  return AuthoringRequest(
    requestId: 'req',
    actionId: 'map.inspect',
    actionVersion: 1,
    workspaceHandle: 'workspace:demo',
  );
}

AuthoringReceipt _receipt() {
  return AuthoringReceipt(
    receiptId: 'receipt-1',
    requestId: 'req-001',
    actionId: 'map.create',
    actionVersion: 1,
    status: AuthoringReceiptStatus.planned,
    createdAtUtc: '2026-07-31T08:00:00.000Z',
    diff: AuthoringDiff(const []),
  );
}

Map<String, dynamic> _roundTrip(Map<String, Object?> value) {
  return jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
}
