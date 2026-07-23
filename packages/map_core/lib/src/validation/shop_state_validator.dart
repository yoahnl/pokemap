import 'dart:convert';

import '../models/project_manifest.dart';
import '../models/script_conditions.dart';
import '../models/shop_definition.dart';

enum ShopStateDiagnosticSeverity { info, warning, error }

final class ShopStateDiagnostic {
  const ShopStateDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    required this.shopId,
    required this.path,
    this.stateId,
    this.contextId,
  });

  final String code;
  final ShopStateDiagnosticSeverity severity;
  final String message;
  final String shopId;
  final String? stateId;
  final String path;
  final String? contextId;
}

/// Pure structural and project-reference validation for authored shop states.
///
/// Item IDs are supplied by the caller after it loads the configured catalog.
/// This validator deliberately performs no filesystem I/O and never evaluates
/// conditions against a runtime [GameState].
final class ShopStateValidator {
  const ShopStateValidator({
    required this.project,
    required this.knownItemIds,
  });

  final ProjectManifest project;
  final Set<String> knownItemIds;

  List<ShopStateDiagnostic> validate() {
    final diagnostics = <ShopStateDiagnostic>[];
    for (final shop in project.shops) {
      _validateShop(shop, diagnostics);
    }
    return List<ShopStateDiagnostic>.unmodifiable(diagnostics);
  }

  void _validateShop(
    ShopDefinition shop,
    List<ShopStateDiagnostic> diagnostics,
  ) {
    _validateEntries(
      shop: shop,
      stateId: null,
      entries: shop.entries,
      path: 'shops.${shop.id}.entries',
      diagnostics: diagnostics,
    );
    if (shop.entries.isEmpty) {
      diagnostics.add(
        ShopStateDiagnostic(
          code: 'SHOP_STATE_OPEN_EMPTY_CATALOGUE',
          severity: ShopStateDiagnosticSeverity.warning,
          message: 'Le catalogue par défaut ouvert est vide.',
          shopId: shop.id,
          path: 'shops.${shop.id}.entries',
        ),
      );
    }

    final seenStateIds = <String>{};
    for (final state in shop.states) {
      final stateId = state.id.trim();
      final statePath = 'shops.${shop.id}.states.$stateId';
      if (stateId.isEmpty || !seenStateIds.add(stateId)) {
        diagnostics.add(
          ShopStateDiagnostic(
            code: 'SHOP_STATE_DUPLICATE_ID',
            severity: ShopStateDiagnosticSeverity.error,
            message: stateId.isEmpty
                ? 'L’identifiant de l’état est vide.'
                : 'Plusieurs états utilisent l’identifiant « $stateId ».',
            shopId: shop.id,
            stateId: stateId.isEmpty ? null : stateId,
            path: '$statePath.id',
          ),
        );
      }
      _validateEntries(
        shop: shop,
        stateId: stateId,
        entries: state.entries,
        path: '$statePath.entries',
        diagnostics: diagnostics,
      );
      _validateConditionReferences(
        shop: shop,
        stateId: stateId,
        condition: state.activation,
        path: '$statePath.activation',
        diagnostics: diagnostics,
      );
      if (!state.isOpen && state.closedMessage.trim().isEmpty) {
        diagnostics.add(
          ShopStateDiagnostic(
            code: 'SHOP_STATE_CLOSED_WITHOUT_MESSAGE',
            severity: ShopStateDiagnosticSeverity.warning,
            message: 'Cet état ferme la boutique sans expliquer pourquoi.',
            shopId: shop.id,
            stateId: stateId,
            path: '$statePath.closedMessage',
          ),
        );
      }
      if (state.isOpen && state.entries.isEmpty) {
        diagnostics.add(
          ShopStateDiagnostic(
            code: 'SHOP_STATE_OPEN_EMPTY_CATALOGUE',
            severity: ShopStateDiagnosticSeverity.warning,
            message: 'Cet état ouvre la boutique avec un catalogue vide.',
            shopId: shop.id,
            stateId: stateId,
            path: '$statePath.entries',
          ),
        );
      }
    }

    for (var leftIndex = 0; leftIndex < shop.states.length; leftIndex += 1) {
      final left = shop.states[leftIndex];
      final leftExpression = _canonicalCondition(left.activation);
      for (var rightIndex = leftIndex + 1;
          rightIndex < shop.states.length;
          rightIndex += 1) {
        final right = shop.states[rightIndex];
        if (left.priority != right.priority ||
            leftExpression != _canonicalCondition(right.activation)) {
          continue;
        }
        diagnostics.add(
          ShopStateDiagnostic(
            code: 'SHOP_STATE_EQUAL_PRIORITY_IDENTICAL_CONDITION',
            severity: ShopStateDiagnosticSeverity.error,
            message: '« ${left.label} » et « ${right.label} » ont la même '
                'condition et la même priorité.',
            shopId: shop.id,
            stateId: right.id,
            path: 'shops.${shop.id}.states.${right.id}.activation',
          ),
        );
      }
    }
  }

  void _validateEntries({
    required ShopDefinition shop,
    required String? stateId,
    required List<ShopEntryDefinition> entries,
    required String path,
    required List<ShopStateDiagnostic> diagnostics,
  }) {
    for (var index = 0; index < entries.length; index += 1) {
      final entry = entries[index];
      final entryPath = '$path.$index';
      if (!knownItemIds.contains(entry.itemId.trim())) {
        diagnostics.add(
          ShopStateDiagnostic(
            code: 'SHOP_STATE_UNKNOWN_ITEM',
            severity: ShopStateDiagnosticSeverity.error,
            message: 'L’objet « ${entry.itemId} » est absent du catalogue.',
            shopId: shop.id,
            stateId: stateId,
            path: '$entryPath.itemId',
          ),
        );
      }
      if (entry.price <= 0) {
        diagnostics.add(
          ShopStateDiagnostic(
            code: 'SHOP_STATE_INVALID_PRICE',
            severity: ShopStateDiagnosticSeverity.error,
            message: 'Le prix doit être strictement positif.',
            shopId: shop.id,
            stateId: stateId,
            path: '$entryPath.price',
          ),
        );
      }
      if (entry.stock != null && entry.stock! < 0) {
        diagnostics.add(
          ShopStateDiagnostic(
            code: 'SHOP_STATE_INVALID_STOCK',
            severity: ShopStateDiagnosticSeverity.error,
            message: 'Le stock ne peut pas être négatif.',
            shopId: shop.id,
            stateId: stateId,
            path: '$entryPath.stock',
          ),
        );
      }
    }
  }

  void _validateConditionReferences({
    required ShopDefinition shop,
    required String stateId,
    required ScriptCondition condition,
    required String path,
    required List<ShopStateDiagnostic> diagnostics,
  }) {
    final reference = switch (condition.type) {
      ScriptConditionType.factEquals => (
          parameter: ScriptConditionParams.factId,
          knownIds: project.facts.map((fact) => fact.id).toSet(),
          kind: 'Fact',
        ),
      ScriptConditionType.stepCompleted => (
          parameter: ScriptConditionParams.stepId,
          knownIds: {
            for (final storyline in project.storylines)
              for (final chapter in storyline.chapters)
                for (final step in chapter.steps) step.id,
          },
          kind: 'Story Step',
        ),
      ScriptConditionType.badgeOwned => (
          parameter: ScriptConditionParams.badgeId,
          knownIds: project.badges.map((badge) => badge.id).toSet(),
          kind: 'badge',
        ),
      ScriptConditionType.itemQuantityAtLeast => (
          parameter: ScriptConditionParams.itemId,
          knownIds: knownItemIds,
          kind: 'objet',
        ),
      ScriptConditionType.eventIsConsumed => (
          parameter: ScriptConditionParams.eventId,
          knownIds: {
            for (final record in project.eventRegistry?.records ?? const [])
              record.id,
          },
          kind: 'Event',
        ),
      ScriptConditionType.playerOnMap => (
          parameter: ScriptConditionParams.mapId,
          knownIds: project.maps.map((map) => map.id).toSet(),
          kind: 'map',
        ),
      _ => null,
    };
    if (reference != null) {
      final id = condition.params[reference.parameter]?.trim() ?? '';
      if (id.isEmpty || !reference.knownIds.contains(id)) {
        diagnostics.add(
          ShopStateDiagnostic(
            code: 'SHOP_STATE_UNKNOWN_CONDITION_REFERENCE',
            severity: ShopStateDiagnosticSeverity.error,
            message: 'La référence ${reference.kind} « $id » est inconnue.',
            shopId: shop.id,
            stateId: stateId,
            path: '$path.${reference.parameter}',
          ),
        );
      }
    }
    for (var index = 0; index < condition.children.length; index += 1) {
      _validateConditionReferences(
        shop: shop,
        stateId: stateId,
        condition: condition.children[index],
        path: '$path.children.$index',
        diagnostics: diagnostics,
      );
    }
  }
}

String _canonicalCondition(ScriptCondition condition) {
  final sortedParameters = condition.params.entries.toList(growable: false)
    ..sort((left, right) => left.key.compareTo(right.key));
  return jsonEncode(<String, Object?>{
    'type': condition.type.name,
    'params': <String, String>{
      for (final entry in sortedParameters) entry.key: entry.value.trim(),
    },
    'children': <Object?>[
      for (final child in condition.children) _canonicalCondition(child),
    ],
  });
}
