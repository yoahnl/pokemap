# Phase A Battle Coverage

## Executive Summary

- Bootstrap moves bridgeables: 13 / 21
- Golden slice moves bridgeables: 3 / 3
- Player seeds bridgeables: 2 / 2
- Trainer seeds bridgeables: 1 / 1
- Wild seeds bridgeables: 1 / 1
- Wild battles startable: 1 / 1
- Trainer battles startable: 1 / 1

## Bootstrap Move Coverage

| moveId | engineSupportLevel | bridgeable | bridgeLimit | unsupportedReasons |
| --- | --- | --- | --- | --- |
| absorb | catalogOnly | no | engine_support_level_not_bridgeable | unsupported_effect_kind:drain |
| double_slap | catalogOnly | no | engine_support_level_not_bridgeable | unsupported_effect_kind:multi_hit |
| electric_terrain | catalogOnly | no | engine_support_level_not_bridgeable | showdown_callback:condition.durationCallback, showdown_callback:condition.onBasePower, showdown_callback:condition.onFieldEnd, showdown_callback:condition.onFieldStart, showdown_callback:condition.onSetStatus, showdown_callback:condition.onTryAddVolatile, unsupported_mechanic:condition |
| feint | structuredSupported | yes |  |  |
| growl | structuredSupported | yes |  |  |
| healing_wish | catalogOnly | no | engine_support_level_not_bridgeable | showdown_callback:condition.onSwap, showdown_callback:condition.onSwitchIn, showdown_callback:onTryHit, unsupported_mechanic:condition, unsupported_mechanic:selfdestruct |
| hyper_beam | structuredSupported | yes |  |  |
| leer | structuredSupported | yes |  |  |
| rain_dance | structuredSupported | yes |  |  |
| razor_leaf | structuredSupported | yes |  |  |
| solar_beam | catalogOnly | no | engine_support_level_not_bridgeable | showdown_callback:onBasePower, showdown_callback:onTryMove, unsupported_mechanic:weather_charge_shortcuts |
| stealth_rock | catalogOnly | no | engine_support_level_not_bridgeable | showdown_callback:condition.onSideStart, showdown_callback:condition.onSwitchIn, unsupported_mechanic:condition |
| swift | structuredSupported | yes |  |  |
| swords_dance | structuredSupported | yes |  |  |
| tackle | structuredSupported | yes |  |  |
| thunder_wave | structuredSupported | yes |  |  |
| thunderbolt | structuredSupported | yes |  |  |
| trick_room | structuredPartial | yes |  | unsupported_mechanic:turn_order_inversion, showdown_callback:condition.durationCallback, showdown_callback:condition.onFieldEnd, showdown_callback:condition.onFieldRestart, showdown_callback:condition.onFieldStart, unsupported_mechanic:condition |
| u_turn | catalogOnly | no | engine_support_level_not_bridgeable | unsupported_effect_kind:self_switch |
| vine_whip | structuredSupported | yes |  |  |
| whirlwind | catalogOnly | no | engine_support_level_not_bridgeable | unsupported_effect_kind:force_switch |

## Golden Slice Move Coverage

| moveId | occurrences | sources | engineSupportLevel | bridgeable | bridgeLimit | unsupportedReasons |
| --- | --- | --- | --- | --- | --- | --- |
| growl | 4 | player_party[0], player_party[1], trainer:trainer_rookie[0], wild:golden_field:golden_grass_zone[0] | structuredSupported | yes |  |  |
| tackle | 4 | player_party[0], player_party[1], trainer:trainer_rookie[0], wild:golden_field:golden_grass_zone[0] | structuredSupported | yes |  |  |
| vine_whip | 1 | player_party[0] | structuredSupported | yes |  |  |

## Player Seed Coverage

| label | candidateMoveIds | builtMoveIds | status | failure |
| --- | --- | --- | --- | --- |
| player_party[0]:active:sproutle | tackle, growl, vine_whip | tackle, growl, vine_whip | bridgeable |  |
| player_party[1]:reserve:sparkitten | tackle, growl | tackle, growl | bridgeable |  |

## Trainer Seed Coverage

| label | candidateMoveIds | builtMoveIds | status | failure |
| --- | --- | --- | --- | --- |
| trainer:trainer_rookie[0]:sparkitten | tackle, growl | tackle, growl | bridgeable |  |

## Wild Seed Coverage

| label | candidateMoveIds | builtMoveIds | status | failure |
| --- | --- | --- | --- | --- |
| wild:golden_field:golden_grass_zone[0]:sparkitten@6-6 | tackle, growl | tackle, growl | bridgeable |  |

## Authored Battle Startability

| kind | label | startable | reason |
| --- | --- | --- | --- |
| wild | wild:golden_field:golden_grass_zone[0]:sparkitten@6-6 | yes |  |
| trainer | trainer:golden_field:npc_trainer_rookie:trainer_rookie | yes |  |

## Notes

- Wild battle opportunities are measured at the authored `zone -> table entry` level.
- Trainer battles are measured at the authored NPC trainer hook level.
- Player truth comes from the versioned launch save, not from test-only fixtures.
- This report is generated locally from the real golden slice and the real embedded bootstrap seed.
