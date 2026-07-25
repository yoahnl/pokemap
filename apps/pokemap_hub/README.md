# PokeMap Hub

Composition root for the generic PokeMap player product.

The package is split into three public entry points:

- `pokemap_hub.dart`: pure-Dart library, installation, and save services for
  recovery workers;
- `pokemap_hub_player.dart`: runtime session and player-shell composition;
- `pokemap_hub_ui.dart`: Flutter Hub application and player presentation.

Platform runners inject native package selection, available-disk measurement,
install/maintenance services, and the mounted Flame game view into
`PokeMapHubApp` and `HubPlayerShellView`. This keeps platform code out of the
distribution, runtime, and reusable UI packages.

The official Hub does not import `map_editor` or
`examples/playable_runtime_host`.

Run validation from this directory:

```bash
flutter test
flutter analyze
```
