# PSDK Golden Fixtures

This directory stores canonical battle scenarios used to compare the Dart PSDK
battle lane with Pokemon SDK behavior.

Each fixture is intentionally small and deterministic. A fixture should describe
one behavior, one setup, one ordered action list, the Pokemon SDK source paths
that justify the expected behavior, and the observable final state and timeline
expected from that scenario. The goal is to grow parity without mixing many move
families inside the same golden file.

Run the focused golden suite from `packages/map_battle`:

```sh
dart test test/psdk_golden_fixture_test.dart --reporter compact
```

When a future fixture is copied from a real Pokemon SDK trace, keep the source
version and notes explicit so drift can be audited.

## Vecteurs de dégâts générés (BETA-BAT-002)

Les fixtures `damage_*.json` sont générées, pas écrites à la main :

```sh
dart run tool/generate_psdk_damage_fixtures.dart          # régénère
dart run tool/generate_psdk_damage_fixtures.dart --check  # échoue si elles ont dérivé
```

Leurs dégâts attendus viennent de `psdkReferenceDamage`, transcrit de la formule
Ruby de PSDK (`10 Move/101 Damage_Calc.rb`), **jamais** du calculateur Dart. Le
moteur n'est rejoué que pour capturer la forme de la timeline, qui n'est pas ce
que ces vecteurs certifient.

Le générateur est lui-même une porte de parité : quand l'oracle et le moteur ne
tombent pas d'accord sur les dégâts, il refuse d'écrire et sort en erreur.
Régénérer les fixtures ne peut donc pas servir à faire taire un écart — c'est
nommément le risque que le ticket décrit. Il a d'ailleurs attrapé une erreur
d'authoring pendant sa propre mise au point : une capacité Normal sur un
attaquant Normal déclenchait un STAB non déclaré, et le vecteur a été refusé
avant d'être écrit.

Leurs deltas d'audit sont nuls : ces vecteurs mesurent l'arithmétique d'un
`s_basic` déjà porté, ils ne portent aucune méthode ni aucun effet nouveau.
