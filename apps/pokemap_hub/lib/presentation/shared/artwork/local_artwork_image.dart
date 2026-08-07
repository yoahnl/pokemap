import 'dart:io';

import 'package:flutter/widgets.dart';

/// The single presentation-layer bridge to the filesystem.
///
/// Read models expose artwork as `String` paths; this turns one into an
/// [ImageProvider] without leaking `dart:io` into the widget tree. Every other
/// file under `presentation/` must stay filesystem-free — enforced by
/// `test/architecture/dependency_rules_test.dart`.
///
/// Returns `null` for a missing or blank path so callers can fall back without
/// a null check at every site.
ImageProvider<Object>? localArtworkImage(String? path) {
  if (path == null || path.trim().isEmpty) return null;
  return FileImage(File(path));
}

/// Non-nullable variant for the sites that have already checked the path.
ImageProvider<Object> requireLocalArtworkImage(String path) =>
    FileImage(File(path));
