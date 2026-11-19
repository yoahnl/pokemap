import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../foundation/player_menu_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_menu_theme.dart';
import '../theme/pokemap_player_theme.dart';
import 'player_control_profile.dart';
import 'player_service_layout.dart';
import 'runtime_player_actions.dart';

class PlayerCraftingOverlay extends StatelessWidget {
  const PlayerCraftingOverlay({
    super.key,
    required this.snapshot,
    required this.onCommand,
    this.controlProfile,
    this.hardwareGamepadEnabled = true,
  });
  final RuntimeWorldServiceSnapshot snapshot;
  final ValueChanged<RuntimeWorldServiceCommand> onCommand;
  final PlayerControlProfile? controlProfile;
  final bool hardwareGamepadEnabled;

  void _emit(RuntimeWorldServiceAction action, {String? target}) {
    if (!snapshot.isActionEnabled(action)) return;
    onCommand(
      RuntimeWorldServiceCommand(
        action: action,
        snapshotRevision: snapshot.revision,
        targetId: target,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.playerL10n;
    final content = snapshot.content! as RuntimeCraftingServiceContent;
    final pendingQuantity = content.pendingOutputQuantity;
    final pendingItem = content.pendingOutputLabel;
    final applying = snapshot.stage == RuntimeWorldServiceStage.applying;
    final completed = snapshot.stage == RuntimeWorldServiceStage.completed;
    final selected = content.recipes
        .where((recipe) => recipe.recipeId == content.selectedRecipeId)
        .firstOrNull;
    return RuntimePlayerActions(
      includeDefaultKeyboardShortcuts: false,
      onBack: () => _emit(
        completed
            ? RuntimeWorldServiceAction.close
            : RuntimeWorldServiceAction.cancel,
      ),
      onMenu: () {},
      onInputSourceChanged: (_) {},
      child: RuntimePlayerInputBindings(
        controlProfile: controlProfile,
        hardwareGamepadEnabled: hardwareGamepadEnabled,
        child: Focus(
          autofocus: true,
          child: PlayerMenuThemeScope(
            role: ProjectPresentationSurfaceRole.confirmation,
            child: Builder(
              builder: (context) => ColoredBox(
                color: context.playerColors.scrim,
                child: SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 540,
                          maxHeight: 760,
                        ),
                        child: PlayerMenuPanel(
                          primary: true,
                          padding: const EdgeInsets.all(12),
                          child: PlayerServiceContent(
                            contentIdentity: (
                              snapshot.revision,
                              snapshot.stage,
                            ),
                            title: Text(
                              content.title,
                              style: context.playerMenuTheme.title,
                            ),
                            actions: PlayerServiceActions(
                              children: [
                                if (snapshot.isActionEnabled(
                                  RuntimeWorldServiceAction.confirm,
                                ))
                                  PlayerActionButton(
                                    label:
                                        content.status ==
                                            RuntimeCraftingStatus.ready
                                        ? strings.craftCollect
                                        : content.reviewing
                                        ? strings.craftConfirmDeposit
                                        : strings.craftReviewOrder,
                                    icon: Icons.check,
                                    onPressed: () => _emit(
                                      RuntimeWorldServiceAction.confirm,
                                    ),
                                  ),
                                PlayerActionButton(
                                  label: completed
                                      ? strings.close
                                      : strings.cancel,
                                  icon: Icons.close,
                                  secondary: true,
                                  onPressed: applying
                                      ? null
                                      : () => _emit(
                                          completed
                                              ? RuntimeWorldServiceAction.close
                                              : RuntimeWorldServiceAction
                                                    .cancel,
                                        ),
                                ),
                              ],
                            ),
                            children: [
                              if (content.message != null)
                                Text(content.message!),
                              if (applying) const LinearProgressIndicator(),
                              if (!completed &&
                                  content.status ==
                                      RuntimeCraftingStatus.working)
                                Text(
                                  pendingQuantity == null || pendingItem == null
                                      ? strings.craftPending
                                      : strings.craftPendingOrder(
                                          quantity: pendingQuantity,
                                          item: pendingItem,
                                        ),
                                ),
                              if (!completed &&
                                  content.status == RuntimeCraftingStatus.ready)
                                Text(
                                  pendingQuantity == null || pendingItem == null
                                      ? strings.craftReady
                                      : strings.craftReadyOrder(
                                          quantity: pendingQuantity,
                                          item: pendingItem,
                                        ),
                                ),
                              if (!completed &&
                                  content.status ==
                                      RuntimeCraftingStatus.idle) ...[
                                if (!content.reviewing)
                                  for (final recipe in content.recipes)
                                    PlayerActionButton(
                                      label: strings.craftRecipe(
                                        recipe: recipe.label,
                                        exchange: strings.craftExchange(
                                          inputQuantity: recipe.inputQuantity,
                                          input: recipe.inputLabel,
                                          outputQuantity: recipe.outputQuantity,
                                          output: recipe.outputLabel,
                                        ),
                                        owned: recipe.ownedQuantity,
                                      ),
                                      icon: Icons.build,
                                      secondary:
                                          selected?.recipeId != recipe.recipeId,
                                      labelMaxLines: 4,
                                      onPressed: applying
                                          ? null
                                          : () => _emit(
                                              RuntimeWorldServiceAction.select,
                                              target: recipe.recipeId,
                                            ),
                                    ),
                                if (selected != null) ...[
                                  Text(
                                    strings.craftExchange(
                                      inputQuantity:
                                          content.quantity *
                                          selected.inputQuantity,
                                      input: selected.inputLabel,
                                      outputQuantity:
                                          content.quantity *
                                          selected.outputQuantity,
                                      output: selected.outputLabel,
                                    ),
                                  ),
                                  Text(
                                    strings.craftQuantity(
                                      quantity: content.quantity,
                                      maximum: content.maximumQuantity,
                                    ),
                                  ),
                                  if (!content.reviewing)
                                    PlayerServiceActions(
                                      children: [
                                        PlayerActionButton(
                                          label: strings.craftDecreaseQuantity,
                                          icon: Icons.remove,
                                          secondary: true,
                                          onPressed:
                                              snapshot.isActionEnabled(
                                                RuntimeWorldServiceAction
                                                    .decreaseQuantity,
                                              )
                                              ? () => _emit(
                                                  RuntimeWorldServiceAction
                                                      .decreaseQuantity,
                                                )
                                              : null,
                                        ),
                                        PlayerActionButton(
                                          label: strings.craftIncreaseQuantity,
                                          icon: Icons.add,
                                          secondary: true,
                                          onPressed:
                                              snapshot.isActionEnabled(
                                                RuntimeWorldServiceAction
                                                    .increaseQuantity,
                                              )
                                              ? () => _emit(
                                                  RuntimeWorldServiceAction
                                                      .increaseQuantity,
                                                )
                                              : null,
                                        ),
                                      ],
                                    ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
