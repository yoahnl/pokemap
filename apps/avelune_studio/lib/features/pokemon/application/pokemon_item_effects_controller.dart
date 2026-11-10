import 'package:map_core/map_core_domain.dart';

import 'pokemon_commerce_controller.dart';
import 'pokemon_item_effect_editing.dart';

class PokemonItemEffectsController {
  PokemonItemEffectsController(this.commerce);

  final PokemonCommerceController commerce;

  ProjectItemUseDefinition? useFor(ProjectItemUseContext context) =>
      PokemonItemEffectEditing.use(commerce.item!, context);

  void setUse(
    ProjectItemUseContext context,
    ProjectItemUseDefinition? replacement,
  ) {
    commerce.setFieldError(
      'item-effect-${commerce.item!.id}-${context.name}',
      null,
    );
    commerce.editItem(
      (item) => PokemonItemEffectEditing.replace(item, context, replacement),
    );
  }

  ProjectItemUseDefinition defaultUse(ProjectItemUseContext context) =>
      PokemonItemEffectEditing.defaultUse(context);
  ProjectItemEffectDefinition effectForKind(String kind) =>
      PokemonItemEffectEditing.effect(kind);
  String kindOf(ProjectItemEffectDefinition effect) =>
      PokemonItemEffectEditing.kind(effect);

  void add(ProjectItemUseContext context) =>
      setUse(context, defaultUse(context));
  void remove(ProjectItemUseContext context) => setUse(context, null);

  void selectEffect(ProjectItemUseContext context, String kind) {
    final use = useFor(context);
    if (use != null) {
      setUse(context, PokemonItemEffectEditing.changeKind(use, kind));
    }
  }

  void setInteger(ProjectItemUseContext context, String field, int value) {
    final use = useFor(context);
    if (use != null) {
      setUse(context, PokemonItemEffectEditing.setInteger(use, field, value));
    }
  }

  void toggleFriendshipLoss(ProjectItemUseContext context, bool enabled) {
    final use = useFor(context);
    if (use != null) {
      setUse(
        context,
        PokemonItemEffectEditing.toggleFriendshipLoss(use, enabled),
      );
    }
  }

  void editFriendshipLoss(
    ProjectItemUseContext context,
    String tier,
    int value,
  ) {
    final use = useFor(context);
    if (use != null) {
      setUse(
        context,
        PokemonItemEffectEditing.editFriendshipLoss(use, tier, value),
      );
    }
  }
}
