import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectSurfaceCatalog JSON codec (Lot 46)', () {
    test('1. encodes empty catalog', () {
      final c = _catalog();
      final j = encodeProjectSurfaceCatalog(c);
      expect(j.keys.toList(), ['atlases', 'animations', 'presets']);
      expect(j['atlases'], isEmpty);
      expect(j['animations'], isEmpty);
      expect(j['presets'], isEmpty);
      expect(j.containsKey('surfaceCatalog'), isFalse);
    });

    test('2. decodes empty catalog JSON', () {
      const j = <String, Object?>{
        'atlases': <Object?>[],
        'animations': <Object?>[],
        'presets': <Object?>[],
      };
      final c = decodeProjectSurfaceCatalog(j);
      expect(c.atlases, isEmpty);
      expect(c.animations, isEmpty);
      expect(c.presets, isEmpty);
    });

    test('3. round-trip empty catalog', () {
      final o = _catalog();
      final d = decodeProjectSurfaceCatalog(encodeProjectSurfaceCatalog(o));
      expect(d, o);
    });

    test('4. encodes minimal complete catalog (child codecs)', () {
      final atlas = _atlas();
      final anim = _animation();
      final preset = _preset();
      final c = _catalog(
        atlases: [atlas],
        animations: [anim],
        presets: [preset],
      );
      final j = encodeProjectSurfaceCatalog(c);
      expect((j['atlases'] as List).length, 1);
      expect((j['animations'] as List).length, 1);
      expect((j['presets'] as List).length, 1);
      expect((j['atlases'] as List).first, encodeProjectSurfaceAtlas(atlas));
      expect((j['animations'] as List).first, encodeProjectSurfaceAnimation(anim));
      expect((j['presets'] as List).first, encodeProjectSurfacePreset(preset));
    });

    test('5. decodes minimal complete catalog', () {
      final atlas = _atlas(id: 'a1');
      final anim = _animation(id: 'm1', atlasId: 'a1');
      final preset = _preset(id: 'p1', animationId: 'm1');
      final j = encodeProjectSurfaceCatalog(
        _catalog(atlases: [atlas], animations: [anim], presets: [preset]),
      );
      final c = decodeProjectSurfaceCatalog(j);
      expect(c.atlasCount, 1);
      expect(c.animationCount, 1);
      expect(c.presetCount, 1);
      expect(c.atlasById('a1')?.id, 'a1');
      expect(c.animationById('m1')?.id, 'm1');
      expect(c.presetById('p1')?.id, 'p1');
    });

    test('6. round-trip minimal complete catalog', () {
      final o = _catalog(
        atlases: [_atlas(id: 'x')],
        animations: [_animation(id: 'y', atlasId: 'x')],
        presets: [_preset(id: 'z', animationId: 'y')],
      );
      expect(decodeProjectSurfaceCatalog(encodeProjectSurfaceCatalog(o)), o);
    });

    test('7. encode preserves atlas order', () {
      final c = _catalog(
        atlases: [
          _atlas(id: 'water-atlas'),
          _atlas(id: 'lava-atlas'),
          _atlas(id: 'grass-atlas'),
        ],
      );
      final j = encodeProjectSurfaceCatalog(c);
      final ids = (j['atlases'] as List<Object?>)
          .map((e) => (e! as Map)['id'] as String)
          .toList();
      expect(ids, ['water-atlas', 'lava-atlas', 'grass-atlas']);
    });

    test('8. decode preserves atlas order', () {
      final j = encodeProjectSurfaceCatalog(
        _catalog(
          atlases: [
            _atlas(id: 'water-atlas'),
            _atlas(id: 'lava-atlas'),
            _atlas(id: 'grass-atlas'),
          ],
        ),
      );
      final c = decodeProjectSurfaceCatalog(j);
      expect(c.atlases.map((e) => e.id).toList(),
          ['water-atlas', 'lava-atlas', 'grass-atlas']);
    });

    test('9. encode preserves animation order', () {
      final c = _catalog(
        animations: [
          _animation(id: 'water-a', atlasId: 'a'),
          _animation(id: 'water-b', atlasId: 'a'),
          _animation(id: 'water-c', atlasId: 'a'),
        ],
        atlases: [_atlas(id: 'a')],
      );
      final j = encodeProjectSurfaceCatalog(c);
      final ids = (j['animations'] as List<Object?>)
          .map((e) => (e! as Map)['id'] as String)
          .toList();
      expect(ids, ['water-a', 'water-b', 'water-c']);
    });

    test('10. decode preserves animation order', () {
      final j = encodeProjectSurfaceCatalog(
        _catalog(
          atlases: [_atlas(id: 'a')],
          animations: [
            _animation(id: 'water-a', atlasId: 'a'),
            _animation(id: 'water-b', atlasId: 'a'),
            _animation(id: 'water-c', atlasId: 'a'),
          ],
        ),
      );
      final c = decodeProjectSurfaceCatalog(j);
      expect(c.animations.map((e) => e.id).toList(),
          ['water-a', 'water-b', 'water-c']);
    });

    test('11. encode preserves preset order', () {
      final atl = _atlas(id: 'a');
      final an = _animation(id: 'm', atlasId: 'a');
      final c = _catalog(
        atlases: [atl],
        animations: [an],
        presets: [
          _preset(id: 'water-surface', animationId: 'm'),
          _preset(id: 'lava-surface', animationId: 'm'),
          _preset(id: 'grass-surface', animationId: 'm'),
        ],
      );
      final j = encodeProjectSurfaceCatalog(c);
      final ids = (j['presets'] as List<Object?>)
          .map((e) => (e! as Map)['id'] as String)
          .toList();
      expect(ids, ['water-surface', 'lava-surface', 'grass-surface']);
    });

    test('12. decode preserves preset order', () {
      final atl = _atlas(id: 'a');
      final an = _animation(id: 'm', atlasId: 'a');
      final j = encodeProjectSurfaceCatalog(
        _catalog(
          atlases: [atl],
          animations: [an],
          presets: [
            _preset(id: 'water-surface', animationId: 'm'),
            _preset(id: 'lava-surface', animationId: 'm'),
            _preset(id: 'grass-surface', animationId: 'm'),
          ],
        ),
      );
      final c = decodeProjectSurfaceCatalog(j);
      expect(c.presets.map((e) => e.id).toList(),
          ['water-surface', 'lava-surface', 'grass-surface']);
    });

    test('13. decode rejects missing atlases', () {
      expect(
        () => decodeProjectSurfaceCatalog(<String, Object?>{
          'animations': <Object?>[],
          'presets': <Object?>[],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('14. decode rejects atlases non-list', () {
      expect(
        () => decodeProjectSurfaceCatalog(<String, Object?>{
          'atlases': 'nope',
          'animations': <Object?>[],
          'presets': <Object?>[],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('15. decode rejects atlas item non-map', () {
      expect(
        () => decodeProjectSurfaceCatalog(<String, Object?>{
          'atlases': <Object?>['nope'],
          'animations': <Object?>[],
          'presets': <Object?>[],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('16. decode rejects invalid atlas via child codec (whitespace id)', () {
      final good = encodeProjectSurfaceAtlas(_atlas());
      final m = Map<String, Object?>.from(good);
      m['id'] = '   ';
      expect(
        () => decodeProjectSurfaceCatalog(<String, Object?>{
          'atlases': <Object?>[m],
          'animations': <Object?>[],
          'presets': <Object?>[],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('17. decode rejects missing animations', () {
      expect(
        () => decodeProjectSurfaceCatalog(<String, Object?>{
          'atlases': <Object?>[],
          'presets': <Object?>[],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('18. decode rejects animations non-list', () {
      expect(
        () => decodeProjectSurfaceCatalog(<String, Object?>{
          'atlases': <Object?>[],
          'animations': 1,
          'presets': <Object?>[],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('19. decode rejects animation item non-map', () {
      expect(
        () => decodeProjectSurfaceCatalog(<String, Object?>{
          'atlases': <Object?>[],
          'animations': <Object?>['x'],
          'presets': <Object?>[],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('20. decode rejects invalid animation via child codec (empty frames)', () {
      final good = encodeProjectSurfaceAnimation(
        _animation(atlasId: 'a'),
      );
      final m = Map<String, Object?>.from(good);
      final tl = Map<String, Object?>.from(m['timeline']! as Map);
      tl['frames'] = <Object?>[];
      m['timeline'] = tl;
      expect(
        () => decodeProjectSurfaceCatalog(<String, Object?>{
          'atlases': <Object?>[],
          'animations': <Object?>[m],
          'presets': <Object?>[],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('21. decode rejects missing presets', () {
      expect(
        () => decodeProjectSurfaceCatalog(<String, Object?>{
          'atlases': <Object?>[],
          'animations': <Object?>[],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('22. decode rejects presets non-list', () {
      expect(
        () => decodeProjectSurfaceCatalog(<String, Object?>{
          'atlases': <Object?>[],
          'animations': <Object?>[],
          'presets': true,
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('23. decode rejects preset item non-map', () {
      expect(
        () => decodeProjectSurfaceCatalog(<String, Object?>{
          'atlases': <Object?>[],
          'animations': <Object?>[],
          'presets': <Object?>[1],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('24. decode rejects invalid preset via child codec (empty refs)', () {
      final good = encodeProjectSurfacePreset(_preset());
      final m = Map<String, Object?>.from(good);
      final va = Map<String, Object?>.from(m['variantAnimations']! as Map);
      va['refs'] = <Object?>[];
      m['variantAnimations'] = va;
      expect(
        () => decodeProjectSurfaceCatalog(<String, Object?>{
          'atlases': <Object?>[],
          'animations': <Object?>[],
          'presets': <Object?>[m],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('25. decode rejects duplicate atlas ids (model)', () {
      final one = encodeProjectSurfaceAtlas(_atlas(id: 'dup'));
      final j = <String, Object?>{
        'atlases': <Object?>[one, one],
        'animations': <Object?>[],
        'presets': <Object?>[],
      };
      expect(
        () => decodeProjectSurfaceCatalog(j),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.toString(),
            'message',
            contains('duplicate ProjectSurfaceAtlas.id'),
          ),
        ),
      );
    });

    test('26. decode rejects duplicate animation ids (model)', () {
      final atl = _atlas(id: 'a');
      final one = encodeProjectSurfaceAnimation(_animation(id: 'dup', atlasId: 'a'));
      final j = <String, Object?>{
        'atlases': <Object?>[encodeProjectSurfaceAtlas(atl)],
        'animations': <Object?>[one, one],
        'presets': <Object?>[],
      };
      expect(
        () => decodeProjectSurfaceCatalog(j),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.toString(),
            'message',
            contains('duplicate ProjectSurfaceAnimation.id'),
          ),
        ),
      );
    });

    test('27. decode rejects duplicate preset ids (model)', () {
      final atl = _atlas(id: 'a');
      final an = _animation(id: 'm', atlasId: 'a');
      final one = encodeProjectSurfacePreset(_preset(id: 'dup', animationId: 'm'));
      final j = <String, Object?>{
        'atlases': <Object?>[encodeProjectSurfaceAtlas(atl)],
        'animations': <Object?>[encodeProjectSurfaceAnimation(an)],
        'presets': <Object?>[one, one],
      };
      expect(
        () => decodeProjectSurfaceCatalog(j),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.toString(),
            'message',
            contains('duplicate ProjectSurfacePreset.id'),
          ),
        ),
      );
    });

    test('28. decode ignores unknown top-level key', () {
      final j = <String, Object?>{
        'atlases': <Object?>[],
        'animations': <Object?>[],
        'presets': <Object?>[],
        'futureField': 'ignored',
      };
      final c = decodeProjectSurfaceCatalog(j);
      expect(c.isEmpty, isTrue);
    });

    test('29. decode ignores unknown keys in child items', () {
      final atlas = encodeProjectSurfaceAtlas(_atlas());
      final m = Map<String, Object?>.from(atlas);
      m['extraAtlas'] = 1;
      final j = <String, Object?>{
        'atlases': <Object?>[m],
        'animations': <Object?>[],
        'presets': <Object?>[],
      };
      final c = decodeProjectSurfaceCatalog(j);
      expect(c.atlasCount, 1);
    });

    test('30. decode does not mutate source map', () {
      final inner = <String, Object?>{
        'id': 'a',
        'name': 'Water Atlas',
        'tilesetId': 't',
        'geometry': encodeSurfaceAtlasGeometry(_geometry()),
        'sortOrder': 0,
      };
      final m = <String, Object?>{
        'atlases': <Object?>[inner],
        'animations': <Object?>[],
        'presets': <Object?>[],
      };
      final before = _mapStr(m);
      decodeProjectSurfaceCatalog(m);
      expect(_mapStr(m), before);
    });

    test('31. encode does not mutate catalog', () {
      final atl = _atlas(id: 'a');
      final an = _animation(id: 'm', atlasId: 'a');
      final pr = _preset(id: 'p', animationId: 'm');
      final c = _catalog(atlases: [atl], animations: [an], presets: [pr]);
      final ac = c.atlasCount;
      final pc = c.presetCount;
      final la = c.atlasById('a');
      encodeProjectSurfaceCatalog(c);
      expect(c.atlasCount, ac);
      expect(c.presetCount, pc);
      expect(c.atlasById('a'), la);
    });

    test('32. codec does not resolve animationId; diagnostics catch missing', () {
      final j = <String, Object?>{
        'atlases': <Object?>[],
        'animations': <Object?>[],
        'presets': <Object?>[
          encodeProjectSurfacePreset(
            _preset(animationId: 'missing-animation'),
          ),
        ],
      };
      final c = decodeProjectSurfaceCatalog(j);
      final r = diagnoseProjectSurfaceCatalog(c);
      expect(
        r.byKind(SurfaceCatalogDiagnosticKind.missingPresetAnimation),
        isNotEmpty,
      );
    });

    test('33. codec does not resolve atlasId; diagnostics catch missing atlas', () {
      final j = <String, Object?>{
        'atlases': <Object?>[],
        'animations': <Object?>[
          encodeProjectSurfaceAnimation(
            _animation(id: 'orphan', atlasId: 'missing-atlas'),
          ),
        ],
        'presets': <Object?>[],
      };
      final c = decodeProjectSurfaceCatalog(j);
      final r = diagnoseProjectSurfaceCatalog(c);
      expect(
        r.byKind(SurfaceCatalogDiagnosticKind.missingAnimationAtlas),
        isNotEmpty,
      );
    });

    test('34. codec does not check geometry; diagnostics catch out of bounds', () {
      final geo = SurfaceAtlasGeometry(
        tileSize: SurfaceAtlasTileSize(width: 16, height: 16),
        gridSize: SurfaceAtlasGridSize(columns: 1, rows: 1),
        layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
      );
      final atl = _atlas(id: 'water-atlas', geometry: geo);
      final anim = ProjectSurfaceAnimation(
        id: 'a1',
        name: 'A',
        timeline: SurfaceAnimationTimeline(
          frames: [
            SurfaceAnimationFrame(
              tileRef: SurfaceAtlasTileRef(
                atlasId: 'water-atlas',
                column: 999,
                row: 999,
              ),
              durationMs: 120,
            ),
          ],
        ),
      );
      final c = _catalog(atlases: [atl], animations: [anim], presets: []);
      final d = decodeProjectSurfaceCatalog(encodeProjectSurfaceCatalog(c));
      final r = diagnoseProjectSurfaceCatalog(d);
      expect(
        r.byKind(SurfaceCatalogDiagnosticKind.animationFrameOutsideAtlasGeometry),
        isNotEmpty,
      );
    });

    test('35. codec does not call unused diagnostics; unused can warn after', () {
      final aUsed = _atlas(id: 'used-atlas');
      final aUnused = _atlas(id: 'unused-atlas');
      final mUsed = _animation(id: 'used-anim', atlasId: 'used-atlas');
      final mUnused = _animation(id: 'unused-anim', atlasId: 'used-atlas');
      final p = _preset(id: 'p', animationId: 'used-anim');
      final c = _catalog(
        atlases: [aUsed, aUnused],
        animations: [mUsed, mUnused],
        presets: [p],
      );
      final d = decodeProjectSurfaceCatalog(encodeProjectSurfaceCatalog(c));
      final u = diagnoseProjectSurfaceCatalogUnusedResources(d);
      expect(u.byKind(SurfaceCatalogDiagnosticKind.unusedAtlas), isNotEmpty);
      expect(u.byKind(SurfaceCatalogDiagnosticKind.unusedAnimation), isNotEmpty);
    });

    test('36. reuses Lot 39 atlas codec for atlases[0]', () {
      final atlas = _atlas();
      final c = _catalog(atlases: [atlas]);
      final json = encodeProjectSurfaceCatalog(c);
      final list = json['atlases']! as List<Object?>;
      expect(list[0], encodeProjectSurfaceAtlas(atlas));
    });

    test('37. reuses Lot 42 animation codec for animations[0]', () {
      final atl = _atlas(id: 'a');
      final anim = _animation(atlasId: 'a');
      final c = _catalog(atlases: [atl], animations: [anim]);
      final json = encodeProjectSurfaceCatalog(c);
      final list = json['animations']! as List<Object?>;
      expect(list[0], encodeProjectSurfaceAnimation(anim));
    });

    test('38. reuses Lot 45 preset codec for presets[0]', () {
      final atl = _atlas(id: 'a');
      final anim = _animation(id: 'm', atlasId: 'a');
      final preset = _preset(animationId: 'm');
      final c = _catalog(
        atlases: [atl],
        animations: [anim],
        presets: [preset],
      );
      final json = encodeProjectSurfaceCatalog(c);
      final list = json['presets']! as List<Object?>;
      expect(list[0], encodeProjectSurfacePreset(preset));
    });

    test('39. public API encode returns map', () {
      expect(encodeProjectSurfaceCatalog(_catalog()), isA<Map<String, Object?>>());
    });

    test('40. ProjectManifest has no surface persistence keys (Lot 46)', () {
      const manifest = ProjectManifest(
        name: 'L46',
        maps: [
          ProjectMapEntry(
            id: 'm1',
            name: 'M',
            relativePath: 'maps/m1.json',
          ),
        ],
        tilesets: [],
      );
      final ju = manifest.toJson();
      for (final k in const [
        'surfaceCatalog',
        'surfaceDefinitions',
        'surfaceAtlases',
        'surfaceAnimations',
        'surfacePresets',
        'surfaceCategories',
      ]) {
        expect(ju.containsKey(k), isFalse, reason: k);
      }
    });

    test(
      '41. codec external to model: no catalog.toJson or ProjectSurfaceCatalog.fromJson',
      () {
        final c = _catalog();
        final m = encodeProjectSurfaceCatalog(c);
        expect(m, isA<Map<String, Object?>>());
      },
    );

    test('42. manifest surface integration remains out of scope (no manifest codec)', () {
      final m = encodeProjectSurfaceCatalog(_catalog());
      expect(m['atlases'], isA<List>());
    });

    test('43. no Surface categories array; categoryId stays per-item string', () {
      final c = _catalog(
        atlases: [_atlas(categoryId: 'cat')],
        animations: [_animation(atlasId: 'water-atlas')],
        presets: [_preset(animationId: 'water-isolated-loop')],
      );
      final j = encodeProjectSurfaceCatalog(c);
      expect(j.containsKey('categories'), isFalse);
      expect(j.containsKey('surfaceCategories'), isFalse);
      final plist = j['presets']! as List<Object?>;
      final p0 = plist[0] as Map<String, Object?>;
      expect(p0['categoryId'], isA<String>());
    });

    test('44. no kind / surfaceKind / presetKind / type at catalog or preset JSON', () {
      final c = _catalog(
        atlases: [_atlas()],
        animations: [_animation()],
        presets: [_preset()],
      );
      final j = encodeProjectSurfaceCatalog(c);
      for (final k in const ['surfaceKind', 'presetKind', 'kind', 'type']) {
        expect(j.containsKey(k), isFalse, reason: 'top $k');
      }
      final plist = j['presets']! as List<Object?>;
      final p0 = plist[0] as Map<String, Object?>;
      for (final k in const ['surfaceKind', 'presetKind', 'kind', 'type']) {
        expect(p0.containsKey(k), isFalse, reason: 'preset $k');
      }
    });
  });
}

SurfaceAtlasGeometry _geometry({
  int columns = 23,
  int rows = 32,
}) {
  return SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: columns, rows: rows),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
}

ProjectSurfaceAtlas _atlas({
  String id = 'water-atlas',
  String name = 'Water Atlas',
  String tilesetId = 'nature-tileset',
  SurfaceAtlasGeometry? geometry,
  String? categoryId = 'animated-surfaces',
  int sortOrder = 0,
}) {
  return ProjectSurfaceAtlas(
    id: id,
    name: name,
    tilesetId: tilesetId,
    geometry: geometry ?? _geometry(),
    categoryId: categoryId,
    sortOrder: sortOrder,
  );
}

SurfaceAnimationFrame _frame({
  String atlasId = 'water-atlas',
  int column = 0,
  int row = 0,
  int durationMs = 120,
}) {
  return SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(
      atlasId: atlasId,
      column: column,
      row: row,
    ),
    durationMs: durationMs,
  );
}

ProjectSurfaceAnimation _animation({
  String id = 'water-isolated-loop',
  String name = 'Water Isolated Loop',
  String atlasId = 'water-atlas',
  int column = 0,
  int row = 0,
  int durationMs = 120,
  String? syncGroupId = 'water',
  String? categoryId = 'animated-surfaces',
  int sortOrder = 0,
}) {
  return ProjectSurfaceAnimation(
    id: id,
    name: name,
    timeline: SurfaceAnimationTimeline(
      frames: [
        _frame(
          atlasId: atlasId,
          column: column,
          row: row,
          durationMs: durationMs,
        ),
      ],
    ),
    syncGroupId: syncGroupId,
    categoryId: categoryId,
    sortOrder: sortOrder,
  );
}

SurfaceVariantAnimationRef _ref(
  SurfaceVariantRole role, {
  String animationId = 'water-isolated-loop',
}) {
  return SurfaceVariantAnimationRef(
    role: role,
    animationId: animationId,
  );
}

ProjectSurfacePreset _preset({
  String id = 'water-surface',
  String name = 'Water Surface',
  String animationId = 'water-isolated-loop',
  String? categoryId = 'animated-surfaces',
  int sortOrder = 0,
}) {
  return ProjectSurfacePreset(
    id: id,
    name: name,
    variantAnimations: SurfaceVariantAnimationRefSet(
      refs: [
        _ref(SurfaceVariantRole.isolated, animationId: animationId),
      ],
    ),
    categoryId: categoryId,
    sortOrder: sortOrder,
  );
}

ProjectSurfaceCatalog _catalog({
  List<ProjectSurfaceAtlas>? atlases,
  List<ProjectSurfaceAnimation>? animations,
  List<ProjectSurfacePreset>? presets,
}) {
  return ProjectSurfaceCatalog(
    atlases: atlases ?? const [],
    animations: animations ?? const [],
    presets: presets ?? const [],
  );
}

String _mapStr(Object? o) {
  if (o is Map) {
    final keys = o.keys.toList()..sort();
    return keys.map((k) => '$k:${_mapStr(o[k])}').join('|');
  }
  if (o is List) {
    return o.map(_mapStr).join(';');
  }
  if (o is String) {
    return o;
  }
  if (o == null) {
    return 'null';
  }
  return o.toString();
}
