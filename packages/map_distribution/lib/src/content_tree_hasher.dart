import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'game_package_manifest.dart';
import 'package_path_policy.dart';

/// Computes the versioned content-tree digest defined by package format v1.
abstract final class ContentTreeHasher {
  static const String domain = 'pokemap-content-tree-v1';

  static String canonicalPreimage(
    Iterable<GamePackageFileEntry> entries,
  ) {
    final sorted = entries.toList()
      ..sort((left, right) => PackagePathPolicy.compareUtf8(
            left.path,
            right.path,
          ));
    final output = StringBuffer('$domain\n');
    for (final entry in sorted) {
      output
        ..write(entry.path)
        ..write('\t')
        ..write(entry.size)
        ..write('\t')
        ..write(entry.sha256)
        ..write('\n');
    }
    return output.toString();
  }

  static String sha256Hex(Iterable<GamePackageFileEntry> entries) =>
      sha256.convert(utf8.encode(canonicalPreimage(entries))).toString();
}
