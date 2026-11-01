import 'dart:convert';

import 'package:crypto/crypto.dart';

bool get nativeNarrativeFingerprintSha256Available => false;

ByteConversionSink createNarrativeFingerprintSha256Sink(Sink<Digest> output) =>
    sha256.startChunkedConversion(output);
