import 'dart:convert';

import '../api/authoring_result_projection.dart';
import '../contracts/authoring_result.dart';
import '../contracts/json_contract_support.dart';
import '../workspace/workspace_handle_store.dart';

Future<Map<String, Object?>> readJsonlProjection(
  AuthoringResultProjectionPort api,
  Map<String, dynamic> args, {
  required String requestId,
}) async {
  final operation = requireContractString(args['operation'], 'args.operation');
  final project = ProjectHandle(
    requireContractString(args['projectHandle'], 'args.projectHandle'),
  );
  Map<String, Object?> data;
  switch (operation) {
    case 'receipt':
      rejectUnknownContractKeys(
        args,
        const {'operation', 'projectHandle', 'receiptId'},
      );
      data = await api.reprojectMutationReceipt(
        project,
        receiptId: requireContractString(args['receiptId'], 'args.receiptId'),
      );
    case 'diff':
      rejectUnknownContractKeys(
        args,
        const {'operation', 'projectHandle', 'diffRef', 'cursor', 'limit'},
      );
      final diffRef = requireContractString(args['diffRef'], 'args.diffRef');
      final cursor = args.containsKey('cursor')
          ? requireContractString(args['cursor'], 'args.cursor')
          : null;
      var limit = args.containsKey('limit')
          ? _integer(args['limit'], 'limit', 1, authoringProjectionMaxRows)
          : authoringProjectionMaxRows;
      while (true) {
        data = await api.readMutationDiffPage(
          project,
          diffRef: diffRef,
          cursor: cursor,
          limit: limit,
        );
        if (_fits(data, requestId)) return data;
        final rows = (data['entries']! as List).length;
        if (rows <= 1 || rows > limit) _tooLarge();
        limit = rows ~/ 2;
      }
    case 'payload':
      rejectUnknownContractKeys(
        args,
        const {
          'operation',
          'projectHandle',
          'payloadRef',
          'offset',
          'byteLength'
        },
      );
      data = (await api.readMutationPayloadChunk(
        project,
        payloadRef:
            requireContractString(args['payloadRef'], 'args.payloadRef'),
        offset: _integer(args['offset'], 'offset', 0),
        byteLength: args.containsKey('byteLength')
            ? _integer(args['byteLength'], 'byteLength', 1,
                authoringProjectionMaxChunkBytes)
            : authoringProjectionMaxChunkBytes,
      ))
          .toJson();
    default:
      throw const FormatException('Unknown projection operation.');
  }
  if (!_fits(data, requestId)) _tooLarge();
  return data;
}

int _integer(Object? value, String field, int minimum, [int? maximum]) {
  if (value is! int ||
      value < minimum ||
      (maximum != null && value > maximum)) {
    throw FormatException('Invalid projection $field.');
  }
  return value;
}

bool _fits(Map<String, Object?> data, String requestId) {
  final envelope = AuthoringResult.success(requestId: requestId, data: data);
  return utf8.encode(jsonEncode(envelope.toJson())).length + 1 <=
      authoringProjectionMaxBytes;
}

Never _tooLarge() => throw const AuthoringProjectionException(
      'projection.resource_limit',
      'The projection envelope exceeds its bounded response budget.',
    );
