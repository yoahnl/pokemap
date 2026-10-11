import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

void main() {
  final sourcePath = Platform.environment['AVELUNE_CONVERTER_TEST_SOURCE'];
  test(
    'qualifies an explicitly selected local Marshal corpus without source execution',
    () async {
      final source = await MacOsSourceTree.open(sourcePath!);
      final classes = <String, int>{};
      final kinds = <String, int>{};
      final encodingDiagnostics = <String, int>{};
      final observedVersions = <Map<String, Object>>[];
      final quotaRefusals = <Map<String, Object>>[];
      var marshalFiles = 0;
      var maps = 0;
      var nodes = 0;
      var tables = 0;
      var cells = 0;
      var compressedScripts = 0;
      var scriptBytes = 0;
      final cancellation = ScanCancellation();
      try {
        await for (final node in source.walk(
          policy: SourceScanPolicy(),
          cancellation: cancellation,
        )) {
          if (node.kind != SourceNodeKind.file ||
              !RegExp(r'\.(?:rxdata|dat)$', caseSensitive: false)
                  .hasMatch(node.relativePath)) {
            continue;
          }
          expect(node.byteLength, lessThanOrEqualTo(67108864));
          final builder = BytesBuilder(copy: false);
          await for (final chunk in source.read(
            node,
            maxBytes: 67108864,
            cancellation: cancellation,
          )) {
            builder.add(chunk);
          }
          final bytes = builder.takeBytes();
          if (bytes.length < 2 || bytes[0] != 4 || bytes[1] != 8) continue;
          final MarshalDocument document;
          try {
            document = const MarshalDecoder().decode(
              bytes,
              sourcePath: node.relativePath,
            );
          } on BinaryDecodeError catch (failure) {
            if (!failure.code.startsWith('marshal.quota.')) rethrow;
            quotaRefusals.add({
              'sourcePath': node.relativePath,
              'bytes': bytes.length,
              'code': failure.code,
              'byteOffset': failure.location.byteOffset,
              'graphPath': failure.location.graphPath,
            });
            continue;
          }
          marshalFiles++;
          nodes += document.nodes.length;
          final root = document.node(document.rootId);
          if (root.className == 'RPG::Map') maps++;
          for (final value in document.nodes) {
            kinds.update(value.kind.name, (count) => count + 1,
                ifAbsent: () => 1);
            final className = value.className;
            if (className != null) {
              classes.update(className, (count) => count + 1,
                  ifAbsent: () => 1);
            }
            if (value.kind == MarshalKind.userDefined &&
                value.className == 'Table') {
              final table = const TableDecoder().decode(value);
              tables++;
              cells += table.cellCount;
            } else if (value.kind == MarshalKind.userDefined &&
                value.className == 'Color') {
              const RgssColorDecoder().decode(value);
            } else if (value.kind == MarshalKind.userDefined &&
                value.className == 'Tone') {
              const RgssToneDecoder().decode(value);
            }
            if (value.kind == MarshalKind.string ||
                value.kind == MarshalKind.symbol) {
              final diagnostic = value.text().diagnosticCode;
              if (diagnostic != null) {
                encodingDiagnostics.update(diagnostic, (count) => count + 1,
                    ifAbsent: () => 1);
              }
            }
          }
          if (node.relativePath != 'Data/Scripts.rxdata') continue;
          expect(root.kind, MarshalKind.array);
          for (var index = 0; index < root.elements.length; index++) {
            final tuple = document.node(root.elements[index]);
            expect(tuple.kind, MarshalKind.array);
            expect(tuple.elements.length, 3);
            final title = document.node(tuple.elements[1]).text();
            final payload = document.node(tuple.elements[2]);
            expect(payload.kind, MarshalKind.string);
            const maximumTotal = 67108864;
            final remaining = maximumTotal - scriptBytes;
            expect(remaining, greaterThan(0));
            final decoded = const BoundedZlibDecoder().decode(
              payload.bytes!,
              sourcePath: node.relativePath,
              baseOffset: payload.dataOffset!,
              limits: ZlibDecodeLimits(
                maxOutputBytes: remaining < 33554432 ? remaining : 33554432,
              ),
            );
            compressedScripts++;
            scriptBytes += decoded.length;
            String? text;
            try {
              text = utf8.decode(decoded, allowMalformed: false);
            } on FormatException {
              encodingDiagnostics.update(
                  'scripts.invalid_utf8', (count) => count + 1,
                  ifAbsent: () => 1);
            }
            if (text == null) continue;
            final lines = const LineSplitter().convert(text);
            for (var line = 0; line < lines.length; line++) {
              final match = RegExp(
                r'''^\s*ESSENTIALS_VERSION\s*=\s*["']([0-9]+\.[0-9]+(?:\.[0-9]+)?)["']''',
              ).firstMatch(lines[line]);
              if (match == null) continue;
              observedVersions.add({
                'scriptIndex': index,
                'scriptTitle': title.text ?? '<undecodable>',
                'line': line + 1,
                'version': match.group(1)!,
              });
            }
          }
        }
      } finally {
        await source.close();
      }
      expect(marshalFiles, greaterThan(0));
      expect(nodes, greaterThan(0));
      print(jsonEncode({
        'marshalFiles': marshalFiles,
        'maps': maps,
        'nodes': nodes,
        'tables': tables,
        'tableCells': cells,
        'compressedScripts': compressedScripts,
        'decompressedScriptBytes': scriptBytes,
        'classes': Map.fromEntries(classes.entries.toList()
          ..sort((left, right) => left.key.compareTo(right.key))),
        'kinds': kinds,
        'encodingDiagnostics': encodingDiagnostics,
        'staticVersionDeclarations': observedVersions,
        'quotaRefusals': quotaRefusals,
      }));
    },
    skip: !Platform.isMacOS || sourcePath == null
        ? 'Explicit macOS source is required for local corpus qualification.'
        : false,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
