import 'dart:convert';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as image;

List<int> visionPng(int width, int height, List<int> reds,
    {Map<String, String>? textData}) {
  final raster = image.Image(width: width, height: height, numChannels: 4);
  raster.textData = textData;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      raster.setPixelRgba(x, y, reds[y * width + x], 20, 30, 255);
    }
  }
  return image.encodePng(raster);
}

final class VisionTestFixture {
  VisionTestFixture({Map<String, String>? sourceTextData})
      : sourceBytes =
            visionPng(2, 3, [1, 2, 3, 4, 5, 6], textData: sourceTextData);
  final List<int> sourceBytes;
  final account = ConverterId('account-1');
  late final sourceHash = Sha256Hash(sha256.convert(sourceBytes).toString());
  final snapshotHash = Sha256Hash('a' * 64);
  final sessionHash = Sha256Hash('b' * 64);
  final candidate = ConverterId('candidate-1');
  final region = ConverterId('region-1');
  final file = ConverterId('file-1');
  VisionRequest request(
      {String model = 'test-vision-model',
      Map<String, Object?> options = const {},
      List<int>? cropBytes,
      bool reflected = false,
      int quarterTurns = 0,
      ConverterId? accountRevision,
      String requestId = 'request-1'}) {
    final context = VisionRequestContext(
        requestId: ConverterId(requestId),
        sourceSnapshotHash: snapshotHash,
        inputRevision: 1,
        candidateIds: {candidate},
        sourceRegionIds: {region});
    final material = VisionMaterial(
        context: context,
        expectedSessionHash: sessionHash,
        candidateHashes: {candidate: Sha256Hash('c' * 64)},
        model: model,
        promptVersion: '1',
        options: options,
        crops: [
          VisionCrop(
              regionId: region,
              fileId: file,
              sourceHash: sourceHash,
              sourceRect: {'x': 0, 'y': 0, 'width': 2, 'height': 3},
              pngBytes: cropBytes ?? sourceBytes,
              transmittedWidth: quarterTurns.isOdd ? 3 : 2,
              transmittedHeight: quarterTurns.isOdd ? 2 : 3,
              reflected: reflected,
              quarterTurns: quarterTurns)
        ]);
    return VisionRequest(
        context: context,
        material: material,
        consent: VisionConsent.grant(
            materialHash: material.canonicalHash,
            accountRevision: accountRevision ?? account,
            humanConfirmed: true));
  }

  VisionLiveContext live(VisionRequest request,
          {bool verified = true,
          Sha256Hash? session,
          ConverterId? accountRevision}) =>
      VisionLiveContext(
          sourceVerified: verified,
          sourceSnapshotHash: snapshotHash,
          sessionHash: session ?? sessionHash,
          selectionHash: request.material.selectionHash,
          inputRevision: 1,
          accountRevision: accountRevision ?? request.consent.accountRevision);
  Map<String, Object?> resultJson(VisionRequest request,
          {String name = 'Petit arbre'}) =>
      {
        'schemaVersion': '1.0',
        'kind': 'visionResponse',
        'exampleOnly': false,
        'requestId': request.context.requestId.value,
        'sourceSnapshotHash': snapshotHash.value,
        'inputRevision': 1,
        'suggestions': [
          {
            'suggestionId': 'suggestion-1',
            'candidateIds': [candidate.value],
            'sourceRegionIds': [region.value],
            'proposedName': name,
            'category': 'nature',
            'tags': ['arbre'],
            'evidenceSummary': 'Découpe végétale à confirmer',
            'uncertainties': ['Suggestion seulement'],
            'confidenceLabel': 'medium'
          }
        ]
      };
  VisionResponse response(VisionRequest request) =>
      VisionResponse.fromJson(resultJson(request));
  VisionHttpResponse http(VisionRequest request,
          {bool usage = true, String name = 'Petit arbre'}) =>
      VisionHttpResponse(
          statusCode: 200,
          body: utf8.encode(jsonEncode({
            'status': 'completed',
            'output': [
              {
                'type': 'message',
                'role': 'assistant',
                'content': [
                  {
                    'type': 'output_text',
                    'text': jsonEncode(resultJson(request, name: name))
                  }
                ]
              }
            ],
            if (usage) 'usage': {'input_tokens': 10, 'output_tokens': 4}
          })));
}

final class VisionTestFiles implements SourceFilePort {
  VisionTestFiles(this.bytes);
  List<int> bytes;
  int reads = 0;
  @override
  Future<List<int>> read(ConverterId id) async {
    reads++;
    return List<int>.from(bytes);
  }
}

final class VisionTestVault implements VisionSecretVault {
  VisionTestVault({this.secret = 'decoy-secret-that-must-not-persist'});
  String? secret;
  int reads = 0;
  Future<void> Function()? onRead;
  @override
  Future<String?> read() async {
    reads++;
    await onRead?.call();
    return secret;
  }

  @override
  Future<void> write(String secret) async => this.secret = secret;
  @override
  Future<void> delete() async => secret = null;
}

final class VisionTestTransport implements VisionHttpTransport {
  VisionTestTransport(this.onSend);
  Future<VisionHttpResponse> Function(int) onSend;
  final bodies = <List<int>>[];
  final tokens = <String>[];
  @override
  Future<VisionHttpResponse> send(
      {required List<int> body,
      required String bearerToken,
      required VisionAssistancePolicy policy,
      required ScanCancellation cancellation}) async {
    bodies.add(List<int>.from(body));
    tokens.add(bearerToken);
    return onSend(bodies.length);
  }
}
