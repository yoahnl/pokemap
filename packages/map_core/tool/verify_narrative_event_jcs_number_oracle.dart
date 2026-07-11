import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:map_core/map_core.dart';

const _expectedLineCount = 200000;
const _expectedChecksum =
    'b4294dfb5683285868d038434aaf0d0dfd0fd0cdb7570d79107757f9fd500b57';

Future<void> main() async {
  final oracle = Platform.script.resolve(
    'verify_narrative_event_jcs_number_oracle.mjs',
  );
  final process = await Process.start(
    'node',
    [oracle.toFilePath(), '$_expectedLineCount'],
  );
  var count = 0;
  String? checksum;
  await for (final line in process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())) {
    if (line.startsWith('#sha256,')) {
      checksum = line.substring('#sha256,'.length);
      continue;
    }
    final separator = line.indexOf(',');
    if (separator <= 0) {
      throw FormatException('Malformed oracle line $count.');
    }
    final hex = line.substring(0, separator);
    final expected = line.substring(separator + 1);
    final actual = canonicalizeNarrativeEventJson(_doubleFromHex(hex));
    if (actual != expected) {
      throw StateError(
        'Number mismatch at line $count: $hex expected $expected got $actual',
      );
    }
    count++;
  }
  final stderr = await process.stderr.transform(utf8.decoder).join();
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    throw ProcessException('node', const [], stderr, exitCode);
  }
  if (count != _expectedLineCount || checksum != _expectedChecksum) {
    throw StateError(
      'Oracle summary mismatch: lines=$count checksum=$checksum stderr=$stderr',
    );
  }
  stdout.writeln(
    'Verified $count deterministic IEEE-754 values against Node; '
    'checksum $checksum.',
  );
}

double _doubleFromHex(String hex) {
  final bits = BigInt.parse(hex, radix: 16);
  final data = ByteData(8)
    ..setUint32(0, (bits & BigInt.from(0xffffffff)).toInt(), Endian.little)
    ..setUint32(4, (bits >> 32).toInt(), Endian.little);
  return data.getFloat64(0, Endian.little);
}
