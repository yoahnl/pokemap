import 'dart:convert';
import 'dart:typed_data';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

/// Le décodage WebVTT canonique et la sélection de segment — BETA-CIN-078.
///
/// UN décodeur pur sert le Studio et le runtime installé : mêmes octets,
/// mêmes segments, parité par construction. La règle de sélection est celle
/// du Studio : actif tant que startUs <= t < endUs, trou = caption vide.
void main() {
  Uint8List vtt(String source) => Uint8List.fromList(utf8.encode(source));

  group('BETA-CIN-078 the shared WebVTT decoder', () {
    test('decodes plain segments with joined multi-line text', () {
      final segments = decodePresentationCaptionWebVtt(vtt('''
WEBVTT

00:00.000 --> 00:02.500
Bienvenue à Hanazuki.

00:03,000 --> 01:00:04.250
Le train de 17h42
entre en gare.
'''));
      expect(segments, const [
        PresentationCaptionSegment(
          startUs: 0,
          endUs: 2500000,
          text: 'Bienvenue à Hanazuki.',
        ),
        PresentationCaptionSegment(
          startUs: 3000000,
          endUs: 3604250000,
          text: 'Le train de 17h42 entre en gare.',
        ),
      ]);
    });

    test('tolerates BOM and CRLF like the Studio always did', () {
      final segments = decodePresentationCaptionWebVtt(
        vtt('﻿WEBVTT\r\n\r\n00:00.000 --> 00:01.000\r\nBonjour.\r\n'),
      );
      expect(segments.single.text, 'Bonjour.');
    });

    test('refuses a non-WEBVTT file with the canonical message', () {
      expect(
        () => decodePresentationCaptionWebVtt(vtt('NOT A CAPTION FILE')),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Fichier captions WEBVTT invalide.',
          ),
        ),
      );
    });

    test('refuses invalid timings, zero durations and empty files', () {
      expect(
        () => decodePresentationCaptionWebVtt(
          vtt('WEBVTT\n\nabc --> def\nTexte\n'),
        ),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => decodePresentationCaptionWebVtt(
          vtt('WEBVTT\n\n00:02.000 --> 00:01.000\nTexte\n'),
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Segment WEBVTT de durée invalide.',
          ),
        ),
      );
      expect(
        () => decodePresentationCaptionWebVtt(vtt('WEBVTT\n\n')),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Aucun segment WEBVTT lisible.',
          ),
        ),
      );
    });
  });

  group('BETA-CIN-078 the active-segment rule matches the Studio', () {
    const segments = [
      PresentationCaptionSegment(startUs: 1000, endUs: 2000, text: 'Un'),
      PresentationCaptionSegment(startUs: 3000, endUs: 4000, text: 'Deux'),
    ];

    test('start inclusive, end exclusive', () {
      expect(
        activePresentationCaptionSegment(segments, elapsedUs: 1000)?.text,
        'Un',
      );
      expect(
        activePresentationCaptionSegment(segments, elapsedUs: 1999)?.text,
        'Un',
      );
      expect(
        activePresentationCaptionSegment(segments, elapsedUs: 2000),
        isNull,
        reason: 'a gap between segments renders an empty caption',
      );
      expect(
        activePresentationCaptionSegment(segments, elapsedUs: 3500)?.text,
        'Deux',
      );
    });
  });
}
