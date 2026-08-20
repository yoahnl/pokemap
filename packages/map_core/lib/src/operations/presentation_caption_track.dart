import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart' show immutable;

/// Canonical WebVTT caption decoding and segment selection — BETA-CIN-078.
///
/// One pure decoder serves the Studio preview and the installed runtime, so
/// both always read the same segments from the same bytes: parity by
/// construction, never by testing two parsers against each other. The
/// selection rule is the Studio's historical one: a segment is active while
/// `startUs <= t < endUs`, and gaps render an empty caption.
@immutable
final class PresentationCaptionSegment {
  const PresentationCaptionSegment({
    required this.startUs,
    required this.endUs,
    required this.text,
  });

  final int startUs;
  final int endUs;
  final String text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationCaptionSegment &&
          other.startUs == startUs &&
          other.endUs == endUs &&
          other.text == text;

  @override
  int get hashCode => Object.hash(startUs, endUs, text);
}

PresentationCaptionSegment? activePresentationCaptionSegment(
  List<PresentationCaptionSegment> segments, {
  required int elapsedUs,
}) {
  for (final segment in segments) {
    if (segment.startUs <= elapsedUs && elapsedUs < segment.endUs) {
      return segment;
    }
  }
  return null;
}

List<PresentationCaptionSegment> decodePresentationCaptionWebVtt(
  Uint8List bytes,
) {
  final source = utf8
      .decode(bytes, allowMalformed: false)
      .replaceFirst('﻿', '')
      .replaceAll('\r\n', '\n');
  final lines = source.split('\n');
  if (lines.isEmpty || !lines.first.trimLeft().startsWith('WEBVTT')) {
    throw const FormatException('Fichier captions WEBVTT invalide.');
  }
  final segments = <PresentationCaptionSegment>[];
  var index = 1;
  while (index < lines.length) {
    while (index < lines.length && lines[index].trim().isEmpty) {
      index += 1;
    }
    if (index >= lines.length) break;
    if (!lines[index].contains('-->')) index += 1;
    if (index >= lines.length || !lines[index].contains('-->')) {
      while (index < lines.length && lines[index].trim().isNotEmpty) {
        index += 1;
      }
      continue;
    }
    final timing = lines[index].split('-->');
    if (timing.length != 2) {
      throw const FormatException('Timing WEBVTT invalide.');
    }
    final startUs = _webVttTimeUs(timing.first.trim());
    final endToken = timing.last.trim().split(RegExp(r'\s+')).first;
    final endUs = _webVttTimeUs(endToken);
    if (endUs <= startUs) {
      throw const FormatException('Segment WEBVTT de durée invalide.');
    }
    index += 1;
    final text = <String>[];
    while (index < lines.length && lines[index].trim().isNotEmpty) {
      text.add(lines[index].trim());
      index += 1;
    }
    if (text.isNotEmpty) {
      segments.add(
        PresentationCaptionSegment(
          startUs: startUs,
          endUs: endUs,
          text: text.join(' '),
        ),
      );
    }
  }
  if (segments.isEmpty) {
    throw const FormatException('Aucun segment WEBVTT lisible.');
  }
  return List<PresentationCaptionSegment>.unmodifiable(segments);
}

int _webVttTimeUs(String value) {
  final match = RegExp(
    r'^(?:(\d{2,}):)?(\d{2}):(\d{2})[.,](\d{3})$',
  ).firstMatch(value);
  if (match == null) throw const FormatException('Horodatage WEBVTT invalide.');
  final hours = int.tryParse(match.group(1) ?? '0')!;
  final minutes = int.parse(match.group(2)!);
  final seconds = int.parse(match.group(3)!);
  final milliseconds = int.parse(match.group(4)!);
  if (minutes >= 60 || seconds >= 60) {
    throw const FormatException('Horodatage WEBVTT invalide.');
  }
  return Duration(
    hours: hours,
    minutes: minutes,
    seconds: seconds,
    milliseconds: milliseconds,
  ).inMicroseconds;
}
