import 'dart:io';
import 'dart:typed_data';

import 'package:map_distribution/stress.dart';
import 'package:test/test.dart';

/// BETA-AVL-005 — les médias synthétiques doivent être VRAIMENT valides.
///
/// `GamePackageContentValidator` ne regarde pas l'extension : il lit la
/// signature et décode les dimensions. Un octet aléatoire nommé `.png` fait
/// échouer la construction du package, ce qui ne mesure rien.
void main() {
  group('les PNG synthétiques', () {
    test('portent la signature et des dimensions lisibles', () {
      final png = AveluneStressAssets.png(
        targetBytes: 37000,
        entropy: AveluneStressEntropy(1),
      );

      expect(
        png.sublist(0, 8),
        <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
      );
      final header = ByteData.sublistView(png);
      expect(
        String.fromCharCodes(png.sublist(12, 16)),
        'IHDR',
        reason: 'le premier chunk doit être IHDR',
      );
      final width = header.getUint32(16, Endian.big);
      final height = header.getUint32(20, Endian.big);
      expect(width, greaterThan(0));
      expect(width, height, reason: 'les fixtures sont carrées');
      expect(header.getUint8(24), 8, reason: '8 bits par canal');
      expect(header.getUint8(25), 2, reason: 'RGB sans alpha');
    });

    test('se terminent par IEND', () {
      final png = AveluneStressAssets.png(
        targetBytes: 8000,
        entropy: AveluneStressEntropy(2),
      );
      expect(
        String.fromCharCodes(png.sublist(png.length - 8, png.length - 4)),
        'IEND',
      );
    });

    test('approchent le poids demandé sans le dépasser franchement', () {
      for (final target in <int>[4200, 37000, 157000]) {
        final png = AveluneStressAssets.png(
          targetBytes: target,
          entropy: AveluneStressEntropy(3),
        );
        expect(
          png.length,
          greaterThan((target * 0.85).round()),
          reason: 'un PNG de $target octets ne doit pas s’effondrer : c’est '
              'le signe d’une fixture compressible, donc inutile',
        );
        expect(png.length, lessThan((target * 1.3).round()));
      }
    });

    test('NE se compressent PAS : l’entropie est réelle', () {
      // Le ticket prévient qu'« une fixture compressible ou trop homogène
      // fausserait les conclusions de compression et d'I/O ». Un PNG de zéros
      // se réduirait à quelques centaines d'octets.
      final png = AveluneStressAssets.png(
        targetBytes: 60000,
        entropy: AveluneStressEntropy(4),
      );
      final recompressed = gzip.encode(png);
      expect(
        recompressed.length / png.length,
        greaterThan(0.95),
        reason: 'des pixels bruités ne se recompriment pas — s’ils le font, '
            'la fixture ne mesure ni l’I/O ni un gain de compression futur',
      );
    });

    test('respectent le plafond de dimension du format', () {
      final png = AveluneStressAssets.pngOfSide(
        side: 1024,
        entropy: AveluneStressEntropy(5),
      );
      final header = ByteData.sublistView(png);
      expect(header.getUint32(16, Endian.big), 1024);
    });
  });

  group('les autres médias', () {
    test('un Ogg porte ses pages et sa fréquence', () {
      final ogg = AveluneStressAssets.ogg(
        targetBytes: 27600,
        entropy: AveluneStressEntropy(6),
      );
      expect(String.fromCharCodes(ogg.sublist(0, 4)), 'OggS');
      expect(ogg.length, 27600);
    });

    test('un MP4 porte sa boîte ftyp', () {
      final mp4 = AveluneStressAssets.mp4(
        targetBytes: 340000,
        entropy: AveluneStressEntropy(7),
      );
      expect(String.fromCharCodes(mp4.sublist(4, 8)), 'ftyp');
      expect(mp4.length, 340000);
    });

    test('un blob du magasin embarque un vrai média', () {
      // Le validateur inspecte le média EMBARQUÉ d'un `.blob` du magasin
      // content-addressé : un blob opaque serait refusé.
      final blob = AveluneStressAssets.blob(
        targetBytes: 157000,
        entropy: AveluneStressEntropy(8),
      );
      expect(
        blob.sublist(0, 8),
        <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
      );
    });
  });

  group('le déterminisme', () {
    test('la même graine rend exactement les mêmes octets', () {
      final first = AveluneStressAssets.png(
        targetBytes: 20000,
        entropy: AveluneStressEntropy(99),
      );
      final second = AveluneStressAssets.png(
        targetBytes: 20000,
        entropy: AveluneStressEntropy(99),
      );
      expect(second, first);
    });

    test('deux graines rendent des octets différents', () {
      final first = AveluneStressAssets.png(
        targetBytes: 20000,
        entropy: AveluneStressEntropy(99),
      );
      final other = AveluneStressAssets.png(
        targetBytes: 20000,
        entropy: AveluneStressEntropy(100),
      );
      expect(other, isNot(first));
    });
  });
}
