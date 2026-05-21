# Shadow Lot 8 — Editor Shadow Read Model V0

## 1. Résumé

Shadow-8 ajoute un read model éditeur pour exposer l'état Shadow d'un `ProjectElementEntry`.
Il prépare la future section UI Edit Element, sans créer de widget ni modifier l'état éditeur.

Le lot lit :

- `ProjectManifest.shadowCatalog`
- `ProjectElementEntry.shadow`
- `resolveShadowConfig(...)`

Il expose :

- le statut Shadow élément ;
- les options de profils disponibles ;
- les valeurs résolues quand une ombre est active ;
- les diagnostics lisibles quand un profil manque.

## 2. Fichiers créés

- `packages/map_editor/lib/src/application/shadow/element_shadow_read_model.dart`
- `packages/map_editor/test/application/shadow/element_shadow_read_model_test.dart`
- `reports/shadows/shadow_lot_8_editor_read_model.md`

## 3. Fichiers modifiés

Aucun fichier existant n'a été modifié.

Le lot n'a pas modifié `map_core`, `EditorState`, `EditorNotifier`, le canvas, `map_runtime`, `map_gameplay`, ni `map_battle`.

## 4. API ajoutée

Types ajoutés :

- `ElementShadowReadStatus`
- `ElementShadowDiagnosticSeverity`
- `ShadowProfileOptionReadModel`
- `ElementShadowDiagnosticReadModel`
- `ElementShadowReadModel`

Fonctions ajoutées :

```dart
List<ShadowProfileOptionReadModel> buildShadowProfileOptions(
  ProjectShadowCatalog catalog,
);

List<ShadowProfileOptionReadModel> buildShadowProfileOptionsForManifest(
  ProjectManifest manifest,
);

ElementShadowReadModel buildElementShadowReadModel({
  required ProjectManifest manifest,
  required ProjectElementEntry element,
});

List<ElementShadowReadModel> buildElementShadowReadModels(
  ProjectManifest manifest,
);
```

Code généré dans `packages/map_editor/lib/src/application/shadow/element_shadow_read_model.dart` :

```dart
import 'package:map_core/map_core.dart';

enum ElementShadowReadStatus {
  notConfigured,
  disabled,
  active,
  missingProfile,
  profileNone,
}

enum ElementShadowDiagnosticSeverity {
  warning,
  error,
}

final class ShadowProfileOptionReadModel {
  const ShadowProfileOptionReadModel({
    required this.id,
    required this.name,
    required this.mode,
    required this.renderPass,
    required this.opacity,
    required this.colorHexRgb,
  });

  final String id;
  final String name;
  final ShadowCasterMode mode;
  final ShadowRenderPass renderPass;
  final double opacity;
  final String colorHexRgb;

  bool get isNoneMode => mode == ShadowCasterMode.none;

  String get label => name.trim().isEmpty ? id : name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShadowProfileOptionReadModel &&
          other.id == id &&
          other.name == name &&
          other.mode == mode &&
          other.renderPass == renderPass &&
          other.opacity == opacity &&
          other.colorHexRgb == colorHexRgb;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        mode,
        renderPass,
        opacity,
        colorHexRgb,
      );
}

final class ElementShadowDiagnosticReadModel {
  const ElementShadowDiagnosticReadModel({
    required this.severity,
    required this.code,
    required this.message,
  });

  final ElementShadowDiagnosticSeverity severity;
  final String code;
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ElementShadowDiagnosticReadModel &&
          other.severity == severity &&
          other.code == code &&
          other.message == message;

  @override
  int get hashCode => Object.hash(severity, code, message);
}

final class ElementShadowReadModel {
  ElementShadowReadModel({
    required this.elementId,
    required this.status,
    required this.hasShadowConfig,
    required this.castsShadow,
    required this.shadowProfileId,
    required this.shadowProfileName,
    required this.profileExists,
    required this.resolved,
    required List<ElementShadowDiagnosticReadModel> diagnostics,
    required List<ShadowProfileOptionReadModel> profileOptions,
    this.offsetXOverride,
    this.offsetYOverride,
    this.scaleXOverride,
    this.scaleYOverride,
    this.opacityOverride,
  })  : diagnostics =
            List<ElementShadowDiagnosticReadModel>.unmodifiable(diagnostics),
        profileOptions =
            List<ShadowProfileOptionReadModel>.unmodifiable(profileOptions);

  final String elementId;
  final ElementShadowReadStatus status;
  final bool hasShadowConfig;
  final bool castsShadow;
  final String? shadowProfileId;
  final String? shadowProfileName;
  final bool profileExists;
  final ResolvedShadowConfig? resolved;
  final List<ElementShadowDiagnosticReadModel> diagnostics;
  final List<ShadowProfileOptionReadModel> profileOptions;
  final double? offsetXOverride;
  final double? offsetYOverride;
  final double? scaleXOverride;
  final double? scaleYOverride;
  final double? opacityOverride;

  bool get hasDiagnostics => diagnostics.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ElementShadowReadModel &&
          other.elementId == elementId &&
          other.status == status &&
          other.hasShadowConfig == hasShadowConfig &&
          other.castsShadow == castsShadow &&
          other.shadowProfileId == shadowProfileId &&
          other.shadowProfileName == shadowProfileName &&
          other.profileExists == profileExists &&
          other.resolved == resolved &&
          _listEquals(other.diagnostics, diagnostics) &&
          _listEquals(other.profileOptions, profileOptions) &&
          other.offsetXOverride == offsetXOverride &&
          other.offsetYOverride == offsetYOverride &&
          other.scaleXOverride == scaleXOverride &&
          other.scaleYOverride == scaleYOverride &&
          other.opacityOverride == opacityOverride;

  @override
  int get hashCode => Object.hash(
        elementId,
        status,
        hasShadowConfig,
        castsShadow,
        shadowProfileId,
        shadowProfileName,
        profileExists,
        resolved,
        Object.hashAll(diagnostics),
        Object.hashAll(profileOptions),
        offsetXOverride,
        offsetYOverride,
        scaleXOverride,
        scaleYOverride,
        opacityOverride,
      );
}

List<ShadowProfileOptionReadModel> buildShadowProfileOptions(
  ProjectShadowCatalog catalog,
) {
  return List<ShadowProfileOptionReadModel>.unmodifiable(
    catalog.profiles.map(
      (profile) => ShadowProfileOptionReadModel(
        id: profile.id,
        name: profile.name,
        mode: profile.mode,
        renderPass: profile.renderPass,
        opacity: profile.opacity,
        colorHexRgb: profile.colorHexRgb,
      ),
    ),
  );
}

List<ShadowProfileOptionReadModel> buildShadowProfileOptionsForManifest(
  ProjectManifest manifest,
) {
  return buildShadowProfileOptions(manifest.shadowCatalog);
}

ElementShadowReadModel buildElementShadowReadModel({
  required ProjectManifest manifest,
  required ProjectElementEntry element,
}) {
  final catalog = manifest.shadowCatalog;
  final profileOptions = buildShadowProfileOptions(catalog);
  final shadow = element.shadow;

  if (shadow == null) {
    return ElementShadowReadModel(
      elementId: element.id,
      status: ElementShadowReadStatus.notConfigured,
      hasShadowConfig: false,
      castsShadow: false,
      shadowProfileId: null,
      shadowProfileName: null,
      profileExists: false,
      resolved: null,
      diagnostics: const [],
      profileOptions: profileOptions,
    );
  }

  final profileId = shadow.shadowProfileId;
  final profile = profileId == null ? null : catalog.profileById(profileId);
  final profileExists = profile != null;

  if (!shadow.castsShadow) {
    return ElementShadowReadModel(
      elementId: element.id,
      status: ElementShadowReadStatus.disabled,
      hasShadowConfig: true,
      castsShadow: false,
      shadowProfileId: profileId,
      shadowProfileName: profile?.name,
      profileExists: profileExists,
      resolved: null,
      diagnostics: const [],
      profileOptions: profileOptions,
      offsetXOverride: shadow.offsetX,
      offsetYOverride: shadow.offsetY,
      scaleXOverride: shadow.scaleX,
      scaleYOverride: shadow.scaleY,
      opacityOverride: shadow.opacity,
    );
  }

  final resolution = resolveShadowConfig(
    catalog: catalog,
    elementShadow: shadow,
  );
  final diagnostics = _readDiagnosticsFromResolution(resolution);
  final status = _statusForActiveShadow(
    resolution: resolution,
    diagnostics: diagnostics,
    profile: profile,
  );

  return ElementShadowReadModel(
    elementId: element.id,
    status: status,
    hasShadowConfig: true,
    castsShadow: true,
    shadowProfileId: profileId,
    shadowProfileName: profile?.name,
    profileExists: profileExists,
    resolved:
        status == ElementShadowReadStatus.active ? resolution.resolved : null,
    diagnostics: diagnostics,
    profileOptions: profileOptions,
    offsetXOverride: shadow.offsetX,
    offsetYOverride: shadow.offsetY,
    scaleXOverride: shadow.scaleX,
    scaleYOverride: shadow.scaleY,
    opacityOverride: shadow.opacity,
  );
}

List<ElementShadowReadModel> buildElementShadowReadModels(
  ProjectManifest manifest,
) {
  return List<ElementShadowReadModel>.unmodifiable(
    manifest.elements.map(
      (element) => buildElementShadowReadModel(
        manifest: manifest,
        element: element,
      ),
    ),
  );
}

ElementShadowReadStatus _statusForActiveShadow({
  required ShadowConfigResolution resolution,
  required List<ElementShadowDiagnosticReadModel> diagnostics,
  required ProjectShadowProfile? profile,
}) {
  if (diagnostics.any(
    (diagnostic) => diagnostic.code == 'missingShadowProfile',
  )) {
    return ElementShadowReadStatus.missingProfile;
  }
  if (resolution.resolved != null) {
    return ElementShadowReadStatus.active;
  }
  if (profile?.mode == ShadowCasterMode.none) {
    return ElementShadowReadStatus.profileNone;
  }
  return ElementShadowReadStatus.notConfigured;
}

List<ElementShadowDiagnosticReadModel> _readDiagnosticsFromResolution(
  ShadowConfigResolution resolution,
) {
  return List<ElementShadowDiagnosticReadModel>.unmodifiable(
    resolution.diagnostics.map(_readDiagnosticFromResolution),
  );
}

ElementShadowDiagnosticReadModel _readDiagnosticFromResolution(
  ShadowConfigResolutionDiagnostic diagnostic,
) {
  switch (diagnostic.kind) {
    case ShadowConfigResolutionDiagnosticKind.missingShadowProfile:
      return ElementShadowDiagnosticReadModel(
        severity: ElementShadowDiagnosticSeverity.error,
        code: 'missingShadowProfile',
        message: diagnostic.message,
      );
    case ShadowConfigResolutionDiagnosticKind.customOverrideWithoutBaseProfile:
      return ElementShadowDiagnosticReadModel(
        severity: ElementShadowDiagnosticSeverity.warning,
        code: 'customOverrideWithoutBaseProfile',
        message: diagnostic.message,
      );
  }
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}
```

## 5. Statuts exposés

- `notConfigured` : `element.shadow == null`.
- `disabled` : une config Shadow existe, mais `castsShadow == false`.
- `active` : `resolveShadowConfig(...)` retourne une `ResolvedShadowConfig`.
- `missingProfile` : `castsShadow == true`, mais le profil référencé est absent du `ProjectShadowCatalog`.
- `profileNone` : le profil existe et son `mode == ShadowCasterMode.none`, donc aucune ombre visible volontairement.

## 6. Options de profils exposées

`buildShadowProfileOptions(...)` expose une option par profil du catalogue, en conservant l'ordre source :

- `id`
- `name`
- `mode`
- `renderPass`
- `opacity`
- `colorHexRgb`
- `isNoneMode`
- `label`

Les profils `ShadowCasterMode.none` ne sont pas filtrés, pour que la future UI puisse les afficher.

## 7. Règles de diagnostic

Les diagnostics du resolver core sont transformés en diagnostics éditeur lisibles :

- `missingShadowProfile` devient un diagnostic `error`.
- `customOverrideWithoutBaseProfile` est supporté comme diagnostic `warning`, même si le builder élément Shadow-8 appelle le resolver sans override instance.

Les statuts `notConfigured`, `disabled`, `active` et `profileNone` ne produisent pas de diagnostic.

## 8. Décisions d’implémentation

- Le read model vit dans `packages/map_editor/lib/src/application/shadow/` pour rester en couche application pure, hors widgets.
- Il ne modifie pas `EditorState` ni `EditorNotifier` car Shadow-8 prépare seulement les données de lecture pour Shadow-9.
- Il n'ajoute aucune UI : pas de widget, pas de formulaire, pas de canvas, pas de section Edit Element.
- Il utilise `resolveShadowConfig(...)` depuis `map_core` uniquement quand `element.shadow.castsShadow == true`.
- Il garde `resolved == null` pour `profileNone` afin de ne pas fabriquer une fausse config visible pour un profil qui exprime volontairement l'absence d'ombre.
- Il expose les overrides élément `offsetX/offsetY/scaleX/scaleY/opacity` pour la future UI, sans les modifier.
- Il copie les listes exposées en listes immuables.
- Il n'ajoute aucun export public `map_editor` parce que le package ne possède pas de barrel application comparable pour ces internals.

## 9. Tests ajoutés

Test ajouté :

- `packages/map_editor/test/application/shadow/element_shadow_read_model_test.dart`

Couverture :

- options de profils vides ;
- préservation d'ordre ;
- metadata d'option ;
- profils `none` visibles ;
- listes immuables ;
- `notConfigured` ;
- `disabled` ;
- `active` ;
- valeurs résolues ;
- overrides élément ;
- `missingProfile` ;
- `profileNone` ;
- metadata profil ;
- diagnostics ;
- non-mutation ;
- builder liste ;
- égalité de valeur.

Code généré dans `packages/map_editor/test/application/shadow/element_shadow_read_model_test.dart` :

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/shadow/element_shadow_read_model.dart';

void main() {
  group('buildShadowProfileOptions', () {
    test('returns an empty list for an empty catalog', () {
      expect(buildShadowProfileOptions(ProjectShadowCatalog()), isEmpty);
    });

    test('preserves catalog order', () {
      final options = buildShadowProfileOptions(
        ProjectShadowCatalog(
          profiles: [
            _profile('tree_large', name: 'Large tree'),
            _profile('rock_small', name: 'Small rock'),
          ],
        ),
      );

      expect(options.map((option) => option.id), [
        'tree_large',
        'rock_small',
      ]);
    });

    test('exposes profile metadata for a future dropdown', () {
      final options = buildShadowProfileOptions(
        ProjectShadowCatalog(
          profiles: [
            _profile(
              'actor_contact',
              name: 'Actor contact',
              mode: ShadowCasterMode.contactBlob,
              renderPass: ShadowRenderPass.actorContact,
              opacity: 0.2,
              colorHexRgb: '123ABC',
            ),
          ],
        ),
      );

      final option = options.single;
      expect(option.id, 'actor_contact');
      expect(option.name, 'Actor contact');
      expect(option.label, 'Actor contact');
      expect(option.mode, ShadowCasterMode.contactBlob);
      expect(option.renderPass, ShadowRenderPass.actorContact);
      expect(option.opacity, 0.2);
      expect(option.colorHexRgb, '123ABC');
      expect(option.isNoneMode, isFalse);
    });

    test('keeps none-mode profiles visible', () {
      final options = buildShadowProfileOptions(
        ProjectShadowCatalog(
          profiles: [
            _profile('shadow_none', mode: ShadowCasterMode.none),
          ],
        ),
      );

      expect(options.single.id, 'shadow_none');
      expect(options.single.isNoneMode, isTrue);
    });

    test('returns an immutable list', () {
      final options = buildShadowProfileOptions(
        ProjectShadowCatalog(profiles: [_profile('tree_large')]),
      );

      expect(
        () => options.add(
          const ShadowProfileOptionReadModel(
            id: 'other',
            name: 'Other',
            mode: ShadowCasterMode.ellipse,
            renderPass: ShadowRenderPass.groundStatic,
            opacity: 0.35,
            colorHexRgb: '000000',
          ),
        ),
        throwsUnsupportedError,
      );
    });
  });

  group('buildElementShadowReadModel status', () {
    test('element shadow null returns notConfigured', () {
      final element = _element(id: 'tree_large');
      final model = buildElementShadowReadModel(
        manifest: _manifest(elements: [element]),
        element: element,
      );

      expect(model.elementId, 'tree_large');
      expect(model.status, ElementShadowReadStatus.notConfigured);
      expect(model.hasShadowConfig, isFalse);
      expect(model.castsShadow, isFalse);
      expect(model.shadowProfileId, isNull);
      expect(model.shadowProfileName, isNull);
      expect(model.profileExists, isFalse);
      expect(model.resolved, isNull);
      expect(model.diagnostics, isEmpty);
    });

    test('castsShadow false returns disabled without diagnostics', () {
      final element = _element(
        id: 'flat_decor',
        shadow: ProjectElementShadowConfig(),
      );
      final model = buildElementShadowReadModel(
        manifest: _manifest(elements: [element]),
        element: element,
      );

      expect(model.status, ElementShadowReadStatus.disabled);
      expect(model.hasShadowConfig, isTrue);
      expect(model.castsShadow, isFalse);
      expect(model.resolved, isNull);
      expect(model.diagnostics, isEmpty);
    });

    test('castsShadow false with a profile id does not emit diagnostics', () {
      final element = _element(
        id: 'decor',
        shadow: ProjectElementShadowConfig(shadowProfileId: 'missing'),
      );
      final model = buildElementShadowReadModel(
        manifest: _manifest(elements: [element]),
        element: element,
      );

      expect(model.status, ElementShadowReadStatus.disabled);
      expect(model.shadowProfileId, 'missing');
      expect(model.profileExists, isFalse);
      expect(model.diagnostics, isEmpty);
    });

    test('castsShadow true with an existing profile returns active', () {
      final element = _element(
        id: 'tree',
        shadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'tree_large',
        ),
      );
      final manifest = _manifest(
        shadowCatalog: ProjectShadowCatalog(
          profiles: [
            _profile(
              'tree_large',
              mode: ShadowCasterMode.ellipse,
              renderPass: ShadowRenderPass.groundStatic,
              offsetX: 4,
              offsetY: 12,
              scaleX: 1.2,
              scaleY: 0.45,
              opacity: 0.35,
              colorHexRgb: '102030',
            ),
          ],
        ),
        elements: [element],
      );

      final model = buildElementShadowReadModel(
        manifest: manifest,
        element: element,
      );

      expect(model.status, ElementShadowReadStatus.active);
      expect(model.resolved, isNotNull);
      expect(
        model.resolved,
        const ResolvedShadowConfig(
          shadowProfileId: 'tree_large',
          mode: ShadowCasterMode.ellipse,
          renderPass: ShadowRenderPass.groundStatic,
          offsetX: 4,
          offsetY: 12,
          scaleX: 1.2,
          scaleY: 0.45,
          opacity: 0.35,
          colorHexRgb: '102030',
          softnessMode: ShadowSoftnessMode.hardEdge,
        ),
      );
      expect(model.diagnostics, isEmpty);
    });

    test('active status applies element numeric overrides', () {
      final element = _element(
        id: 'tree',
        shadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'tree_large',
          offsetX: 8,
          offsetY: 16,
          scaleX: 0.9,
          scaleY: 0.4,
          opacity: 0.25,
        ),
      );
      final model = buildElementShadowReadModel(
        manifest: _manifest(
          shadowCatalog: ProjectShadowCatalog(
            profiles: [
              _profile(
                'tree_large',
                offsetX: 4,
                offsetY: 12,
                scaleX: 1.2,
                scaleY: 0.45,
                opacity: 0.35,
              ),
            ],
          ),
          elements: [element],
        ),
        element: element,
      );

      expect(model.status, ElementShadowReadStatus.active);
      expect(model.offsetXOverride, 8);
      expect(model.offsetYOverride, 16);
      expect(model.scaleXOverride, 0.9);
      expect(model.scaleYOverride, 0.4);
      expect(model.opacityOverride, 0.25);
      expect(model.resolved!.offsetX, 8);
      expect(model.resolved!.offsetY, 16);
      expect(model.resolved!.scaleX, 0.9);
      expect(model.resolved!.scaleY, 0.4);
      expect(model.resolved!.opacity, 0.25);
    });

    test('missing profile returns missingProfile with a diagnostic', () {
      final element = _element(
        id: 'tree',
        shadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'missing_profile',
        ),
      );
      final model = buildElementShadowReadModel(
        manifest: _manifest(elements: [element]),
        element: element,
      );

      expect(model.status, ElementShadowReadStatus.missingProfile);
      expect(model.resolved, isNull);
      expect(model.shadowProfileId, 'missing_profile');
      expect(model.shadowProfileName, isNull);
      expect(model.profileExists, isFalse);
      expect(model.diagnostics, hasLength(1));
      expect(model.diagnostics.single.severity,
          ElementShadowDiagnosticSeverity.error);
      expect(model.diagnostics.single.code, 'missingShadowProfile');
      expect(model.diagnostics.single.message, contains('missing_profile'));
    });

    test('none-mode profile returns profileNone without diagnostics', () {
      final element = _element(
        id: 'flat_shadow',
        shadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'shadow_none',
        ),
      );
      final model = buildElementShadowReadModel(
        manifest: _manifest(
          shadowCatalog: ProjectShadowCatalog(
            profiles: [
              _profile('shadow_none', mode: ShadowCasterMode.none),
            ],
          ),
          elements: [element],
        ),
        element: element,
      );

      expect(model.status, ElementShadowReadStatus.profileNone);
      expect(model.resolved, isNull);
      expect(model.profileExists, isTrue);
      expect(model.shadowProfileName, 'shadow_none shadow');
      expect(model.diagnostics, isEmpty);
    });
  });

  group('buildElementShadowReadModel profile metadata', () {
    test('fills profile name when the selected profile exists', () {
      final element = _element(
        shadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'tree_large',
        ),
      );
      final model = buildElementShadowReadModel(
        manifest: _manifest(
          shadowCatalog: ProjectShadowCatalog(
            profiles: [_profile('tree_large', name: 'Large tree shadow')],
          ),
          elements: [element],
        ),
        element: element,
      );

      expect(model.shadowProfileId, 'tree_large');
      expect(model.shadowProfileName, 'Large tree shadow');
      expect(model.profileExists, isTrue);
    });

    test('keeps profile name null when the selected profile is missing', () {
      final element = _element(
        shadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'missing',
        ),
      );
      final model = buildElementShadowReadModel(
        manifest: _manifest(elements: [element]),
        element: element,
      );

      expect(model.shadowProfileId, 'missing');
      expect(model.shadowProfileName, isNull);
      expect(model.profileExists, isFalse);
    });

    test('includes profile options on each element read model', () {
      final element = _element();
      final model = buildElementShadowReadModel(
        manifest: _manifest(
          shadowCatalog: ProjectShadowCatalog(
            profiles: [
              _profile('tree_large'),
              _profile('rock_small'),
            ],
          ),
          elements: [element],
        ),
        element: element,
      );

      expect(model.profileOptions.map((option) => option.id), [
        'tree_large',
        'rock_small',
      ]);
    });
  });

  group('diagnostics and immutability', () {
    test('diagnostics are empty for notConfigured, disabled, and active', () {
      final notConfigured = _element(id: 'not_configured');
      final disabled = _element(
        id: 'disabled',
        shadow: ProjectElementShadowConfig(),
      );
      final active = _element(
        id: 'active',
        shadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'tree_large',
        ),
      );
      final manifest = _manifest(
        shadowCatalog: ProjectShadowCatalog(
          profiles: [_profile('tree_large')],
        ),
        elements: [notConfigured, disabled, active],
      );

      expect(
        buildElementShadowReadModel(
          manifest: manifest,
          element: notConfigured,
        ).diagnostics,
        isEmpty,
      );
      expect(
        buildElementShadowReadModel(
          manifest: manifest,
          element: disabled,
        ).diagnostics,
        isEmpty,
      );
      expect(
        buildElementShadowReadModel(
          manifest: manifest,
          element: active,
        ).diagnostics,
        isEmpty,
      );
    });

    test('diagnostics list is immutable', () {
      final element = _element(
        shadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'missing',
        ),
      );
      final model = buildElementShadowReadModel(
        manifest: _manifest(elements: [element]),
        element: element,
      );

      expect(
        () => model.diagnostics.add(
          const ElementShadowDiagnosticReadModel(
            severity: ElementShadowDiagnosticSeverity.warning,
            code: 'other',
            message: 'Other',
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('profile options list on the element read model is immutable', () {
      final element = _element();
      final model = buildElementShadowReadModel(
        manifest: _manifest(
          shadowCatalog: ProjectShadowCatalog(
            profiles: [_profile('tree_large')],
          ),
          elements: [element],
        ),
        element: element,
      );

      expect(
        () => model.profileOptions.clear(),
        throwsUnsupportedError,
      );
    });
  });

  group('non-mutation', () {
    test('does not mutate manifest, element shadow, or shadow catalog', () {
      final shadow = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'tree_large',
        opacity: 0.2,
      );
      final element = _element(shadow: shadow);
      final catalog = ProjectShadowCatalog(
        profiles: [_profile('tree_large')],
      );
      final manifest = _manifest(
        shadowCatalog: catalog,
        elements: [element],
      );

      final beforeManifest = manifest;
      final beforeElement = element;
      final beforeShadow = element.shadow;
      final beforeCatalog = manifest.shadowCatalog;

      buildElementShadowReadModel(manifest: manifest, element: element);

      expect(manifest, beforeManifest);
      expect(element, beforeElement);
      expect(element.shadow, beforeShadow);
      expect(manifest.shadowCatalog, beforeCatalog);
      expect(manifest.shadowCatalog.profileById('tree_large'), isNotNull);
    });
  });

  group('bulk builder', () {
    test('buildElementShadowReadModels builds models in manifest element order',
        () {
      final first = _element(id: 'first');
      final second = _element(
        id: 'second',
        shadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'tree_large',
        ),
      );
      final models = buildElementShadowReadModels(
        _manifest(
          shadowCatalog: ProjectShadowCatalog(
            profiles: [_profile('tree_large')],
          ),
          elements: [first, second],
        ),
      );

      expect(models.map((model) => model.elementId), ['first', 'second']);
      expect(models.map((model) => model.status), [
        ElementShadowReadStatus.notConfigured,
        ElementShadowReadStatus.active,
      ]);
      expect(() => models.clear(), throwsUnsupportedError);
    });
  });

  group('value equality', () {
    test('ShadowProfileOptionReadModel supports value equality', () {
      const a = ShadowProfileOptionReadModel(
        id: 'tree_large',
        name: 'Large tree',
        mode: ShadowCasterMode.ellipse,
        renderPass: ShadowRenderPass.groundStatic,
        opacity: 0.35,
        colorHexRgb: '000000',
      );
      const b = ShadowProfileOptionReadModel(
        id: 'tree_large',
        name: 'Large tree',
        mode: ShadowCasterMode.ellipse,
        renderPass: ShadowRenderPass.groundStatic,
        opacity: 0.35,
        colorHexRgb: '000000',
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('ElementShadowDiagnosticReadModel supports value equality', () {
      const a = ElementShadowDiagnosticReadModel(
        severity: ElementShadowDiagnosticSeverity.error,
        code: 'missingShadowProfile',
        message: 'Missing shadow profile "tree".',
      );
      const b = ElementShadowDiagnosticReadModel(
        severity: ElementShadowDiagnosticSeverity.error,
        code: 'missingShadowProfile',
        message: 'Missing shadow profile "tree".',
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('ElementShadowReadModel supports value equality', () {
      final profileOptions = [
        const ShadowProfileOptionReadModel(
          id: 'tree_large',
          name: 'Large tree',
          mode: ShadowCasterMode.ellipse,
          renderPass: ShadowRenderPass.groundStatic,
          opacity: 0.35,
          colorHexRgb: '000000',
        ),
      ];
      final a = ElementShadowReadModel(
        elementId: 'tree',
        status: ElementShadowReadStatus.active,
        hasShadowConfig: true,
        castsShadow: true,
        shadowProfileId: 'tree_large',
        shadowProfileName: 'Large tree',
        profileExists: true,
        resolved: const ResolvedShadowConfig(
          shadowProfileId: 'tree_large',
          mode: ShadowCasterMode.ellipse,
          renderPass: ShadowRenderPass.groundStatic,
          offsetX: 0,
          offsetY: 0,
          scaleX: 1,
          scaleY: 1,
          opacity: 0.35,
          colorHexRgb: '000000',
          softnessMode: ShadowSoftnessMode.hardEdge,
        ),
        diagnostics: const [],
        profileOptions: profileOptions,
      );
      final b = ElementShadowReadModel(
        elementId: 'tree',
        status: ElementShadowReadStatus.active,
        hasShadowConfig: true,
        castsShadow: true,
        shadowProfileId: 'tree_large',
        shadowProfileName: 'Large tree',
        profileExists: true,
        resolved: const ResolvedShadowConfig(
          shadowProfileId: 'tree_large',
          mode: ShadowCasterMode.ellipse,
          renderPass: ShadowRenderPass.groundStatic,
          offsetX: 0,
          offsetY: 0,
          scaleX: 1,
          scaleY: 1,
          opacity: 0.35,
          colorHexRgb: '000000',
          softnessMode: ShadowSoftnessMode.hardEdge,
        ),
        diagnostics: const [],
        profileOptions: profileOptions,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}

ProjectManifest _manifest({
  ProjectShadowCatalog? shadowCatalog,
  List<ProjectElementEntry> elements = const [],
}) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    elements: elements,
    surfaceCatalog: ProjectSurfaceCatalog(),
    shadowCatalog: shadowCatalog ?? ProjectShadowCatalog(),
  );
}

ProjectElementEntry _element({
  String id = 'tree',
  ProjectElementShadowConfig? shadow,
}) {
  return ProjectElementEntry(
    id: id,
    name: id,
    tilesetId: 'tileset',
    categoryId: 'nature',
    frames: const [
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 0),
      ),
    ],
    shadow: shadow,
  );
}

ProjectShadowProfile _profile(
  String id, {
  String? name,
  ShadowCasterMode mode = ShadowCasterMode.ellipse,
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
  double offsetX = 0,
  double offsetY = 0,
  double scaleX = 1,
  double scaleY = 1,
  double opacity = 0.35,
  String colorHexRgb = '000000',
}) {
  return ProjectShadowProfile(
    id: id,
    name: name ?? '$id shadow',
    mode: mode,
    renderPass: renderPass,
    offsetX: offsetX,
    offsetY: offsetY,
    scaleX: scaleX,
    scaleY: scaleY,
    opacity: opacity,
    colorHexRgb: colorHexRgb,
  );
}
```

## 10. Commandes lancées

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
sed -n '1,220p' packages/map_editor/pubspec.yaml
rg -n "ReadModel|read model|ViewModel|view model|Presenter|summary|diagnostic" packages/map_editor/lib packages/map_editor/test
sed -n '1,260p' packages/map_core/lib/src/models/project_manifest.dart
sed -n '1,260p' packages/map_core/lib/src/models/shadow.dart
sed -n '1,260p' packages/map_core/lib/src/models/shadow_catalog.dart
sed -n '1,300p' packages/map_core/lib/src/operations/shadow_config_resolver.dart
sed -n '1,240p' packages/map_editor/lib/src/application/models/tile_layer_environment_attachment_read_model.dart
rg -n "class ProjectElementEntry|ProjectElementEntry\\(" packages/map_core/lib/src/models/project_manifest.dart packages/map_core/lib/src/models/project_manifest.freezed.dart
sed -n '240,520p' packages/map_core/lib/src/models/project_manifest.dart
find packages/map_editor/test -maxdepth 4 -type f | sort
rg -n "ProjectManifest\\(|ProjectElementEntry\\(|ProjectShadowCatalog|ProjectElementShadowConfig" packages/map_editor/test packages/map_editor/lib packages/map_core/test/shadow
sed -n '1,260p' packages/map_core/test/shadow/shadow_config_resolver_test.dart
sed -n '190,255p' packages/map_core/test/shadow/shadow_authoring_diagnostics_test.dart
sed -n '1,140p' packages/map_editor/test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
sed -n '1,120p' reports/shadows/shadow_lot_7_config_resolver.md
flutter test test/application/shadow/element_shadow_read_model_test.dart
dart format lib/src/application/shadow/element_shadow_read_model.dart test/application/shadow/element_shadow_read_model_test.dart
flutter test test/application/shadow/element_shadow_read_model_test.dart
flutter analyze lib/src/application/shadow test/application/shadow
flutter test test/application/shadow
cd packages/map_core && dart test test/shadow
flutter test
rg -n "Widget|StatefulWidget|StatelessWidget|BuildContext|TextField|Slider|Dropdown|Button|InkWell|GestureDetector" packages/map_editor/lib/src/application/shadow
rg -n "map_runtime|map_gameplay|Flame|Canvas|drawOval|drawPath|drawImage|ImageFilter|saveLayer" packages/map_editor/lib/src/application/shadow
rg -n "runtimeBlur|blurRadius|zOrder|zIndex|modeOverride|colorOverride|renderPassOverride|softnessOverride|shadowTilesetId|shadowSource|sourceMaskId|timeMode|affectedByTimeOfDay" packages/map_editor/lib/src/application/shadow
git diff --name-only
git diff --check
git diff --stat
git status --short --untracked-files=all
```

## 11. Résultats des tests ciblés

Commande rouge initiale :

```bash
cd packages/map_editor && flutter test test/application/shadow/element_shadow_read_model_test.dart
```

Résultat attendu avant implémentation :

```text
Error when reading 'lib/src/application/shadow/element_shadow_read_model.dart': No such file or directory
00:00 +0 -1: Some tests failed.
```

Commande après implémentation :

```bash
cd packages/map_editor && flutter test test/application/shadow/element_shadow_read_model_test.dart
```

Résultat :

```text
00:00 +23: All tests passed!
```

## 12. Résultat des tests Shadow map_editor

Commande :

```bash
cd packages/map_editor && flutter test test/application/shadow
```

Résultat :

```text
00:00 +23: All tests passed!
```

Le dossier `test/application/shadow` contient uniquement le test Shadow-8 ajouté dans ce lot.

## 13. Résultat de l’analyse

Commande :

```bash
cd packages/map_editor && flutter analyze lib/src/application/shadow test/application/shadow
```

Résultat :

```text
Analyzing 2 items...
No issues found! (ran in 1.7s)
```

## 14. Résultat des tests Shadow map_core

Commande :

```bash
cd packages/map_core && dart test test/shadow
```

Résultat :

```text
00:00 +152: All tests passed!
```

## 15. Résultat du test complet map_editor

Commande :

```bash
cd packages/map_editor && flutter test
```

Résultat :

```text
01:22 +1395 -45: Some tests failed.
```

Échecs observés hors lot Shadow-8 :

- plusieurs tests existants utilisent `const ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog(), ...)` alors que `ProjectSurfaceCatalog()` n'est pas un constructeur `const` ;
- `pokemon_sdk_move_catalog_converter.dart` référence des types ou paramètres absents côté `map_core` (`PokemonMoveAimedTarget`, `PokemonMoveFlags`, `PokemonMoveBattleStageMod`, `PokemonMoveStatus`, `psdkStudioMoveId`, `dbSymbol`) ;
- `project_element_collision_file_repository_roundtrip_test.dart` échoue sur une attente de cellules de collision existante ;
- `update_pokedex_species_learnset_use_case_test.dart` échoue sur une référence de move `protect` absente du catalogue local.

Ces échecs ne proviennent pas du nouveau dossier `application/shadow`, qui passe isolément.

## 16. Vérifications anti-dérive

Commandes :

```bash
rg -n "Widget|StatefulWidget|StatelessWidget|BuildContext|TextField|Slider|Dropdown|Button|InkWell|GestureDetector" packages/map_editor/lib/src/application/shadow
rg -n "map_runtime|map_gameplay|Flame|Canvas|drawOval|drawPath|drawImage|ImageFilter|saveLayer" packages/map_editor/lib/src/application/shadow
rg -n "runtimeBlur|blurRadius|zOrder|zIndex|modeOverride|colorOverride|renderPassOverride|softnessOverride|shadowTilesetId|shadowSource|sourceMaskId|timeMode|affectedByTimeOfDay" packages/map_editor/lib/src/application/shadow
```

Résultat :

```text
aucune sortie
```

Confirmations :

- aucune UI ajoutée ;
- aucun widget ajouté ;
- aucun `EditorState` modifié ;
- aucun `EditorNotifier` modifié ;
- aucun canvas modifié ;
- aucun `map_runtime` modifié ;
- aucun `map_gameplay` modifié ;
- aucun `map_core` modifié ;
- aucun JSON ajouté ;
- aucun `toJson/fromJson` ajouté ;
- aucun `build_runner` lancé ;
- aucun generated file créé ;
- aucune collision modifiée ;
- aucune occlusion modifiée ;
- aucun `collisionMask` modifié ;
- aucun `occlusionMask` modifié ;
- aucun `visualMask` modifié ;
- aucun `cells` modifié ;
- aucun `runtimeBlur` ;
- aucun `blurRadius` ;
- aucun `zOrder/zIndex` ;
- aucun renderer.

`git diff --name-only` :

```text
aucune sortie
```

Note : les fichiers Shadow-8 sont nouveaux et non suivis, donc visibles dans `git status`, pas dans `git diff --name-only`.

`git diff --check` :

```text
aucune sortie
```

## 17. Git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Résultat initial :

```text
aucune sortie
```

## 18. Git status final

Résultat final attendu après création du rapport :

```text
?? packages/map_editor/lib/src/application/shadow/element_shadow_read_model.dart
?? packages/map_editor/test/application/shadow/element_shadow_read_model_test.dart
?? reports/shadows/shadow_lot_8_editor_read_model.md
```

## 19. Git diff stat final

Commande :

```bash
git diff --stat
```

Résultat :

```text
aucune sortie
```

Note : le lot ajoute uniquement des fichiers non suivis ; `git diff --stat` ne les liste pas tant qu'ils ne sont pas indexés.

## 20. Non-objectifs respectés

- aucune UI créée ;
- aucune fenêtre Edit Element modifiée ;
- aucune section Ombre visuelle créée ;
- aucun bouton ajouté ;
- aucun slider ajouté ;
- aucun `EditorState` modifié ;
- aucun `EditorNotifier` modifié ;
- aucun canvas modifié ;
- aucun `MapCanvas` modifié ;
- aucun runtime Flame touché ;
- aucune ombre dessinée ;
- aucun `ShadowRuntimeRenderInstruction` ajouté ;
- aucun `WorldLightState` ajouté ;
- aucun `ShadowLightProfile` ajouté ;
- aucun `ProjectManifest` modifié ;
- aucun `ProjectElementEntry` modifié ;
- aucun `MapPlacedElement` modifié ;
- aucun `ProjectShadowCatalog` modifié ;
- aucun `ProjectShadowProfile` modifié ;
- aucun JSON ajouté ;
- aucun `build_runner` lancé ;
- aucune dépendance externe ajoutée.

## 21. Risques / réserves

- Le test complet `map_editor` ne passe pas à cause de dettes hors lot déjà présentes dans des zones Pokémon/collision et dans des tests utilisant `const ProjectManifest`.
- Le read model expose `customOverrideWithoutBaseProfile` par cohérence avec le resolver, mais le builder élément Shadow-8 ne fournit pas d'override instance ; ce diagnostic sera surtout utile quand un read model instance ou un écran plus riche apparaîtra.
- Aucun barrel public `map_editor` n'a été modifié ; l'UI Shadow-9 importera directement ce fichier interne, comme les autres couches internes du package.

## 22. Prochain lot recommandé

Shadow-9 — Edit Element Shadow Section V0

Ne pas l'implémenter dans Shadow-8.
