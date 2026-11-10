import 'terrain_lifecycle_fixture.dart';
export 'terrain_lifecycle_fixture.dart' show seedUwU5Terrain;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'uwu4_resource_host.dart';
import 'uwu_resource_host.dart';

Future<UwUResourceHost> openUwU5TerrainHost(
  WidgetTester tester, {
  bool published = true,
  bool savedDraft = false,
  bool used = false,
  bool advanced = false,
  Size size = const Size(1536, 1024),
  double textScale = 1,
}) => openUwU4ResourceHost(
  tester,
  size: size,
  textScale: textScale,
  configure: (fixture) => seedUwU5Terrain(
    fixture,
    published: published,
    savedDraft: savedDraft,
    used: used,
    advanced: advanced,
  ),
);
