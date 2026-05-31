# PSDK Golden Fixture Index

| Fixture | Gate tags | Focus tags | PSDK source paths | Audit deltas | Purpose |
| --- | --- | --- | --- | --- | --- |
| `basic_damage_neutral.json` | `move_method` | `damage` | `10 Move/1 Mechanics/100 Basic.rb`, `10 Move/101 Damage_Calc.rb` | `strictAttacks: 1`, `portedMethods: 1`, `portedEffects: 0` | Minimal deterministic neutral damage fixture for the first strict `s_basic` lane. |
| `status_stat_non_damage.json` | `move_method`, `status` | - | `10 Move/1 Mechanics/102 Status Stat.rb` | `strictAttacks: 1`, `portedMethods: 1`, `portedEffects: 0` | Non-damage `s_stat` fixture proving major status and stat-stage JSON riders replay through the PSDK engine. |
| `weather_rain_mod1_damage.json` | `move_method`, `field` | `damage`, `weather` | `06 Effects/06 Weather Effects/100 Rain.rb`, `10 Move/101 Damage_Calc.rb` | `strictAttacks: 0`, `portedMethods: 0`, `portedEffects: 1` | Deterministic rain fixture proving PSDK Mod1 weather damage is applied before the `+2` damage floor. |
