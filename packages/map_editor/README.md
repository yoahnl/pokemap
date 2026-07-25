# map_editor

Flutter desktop authoring application for PokeMap projects.

## Exporting a player game

Open a project and choose **Export Game** in the File toolbar group. The
guided form persists a stable `gameId`, version, author, locales, branding,
legal metadata and required runtime capabilities under:

```text
.pokemap/export-profile-v1.json
```

The exporter never packages the author workspace directly. It builds a
player-only projection, compiles supported Yarn dialogue into strict runtime
JSON, rewrites copied references, removes editor/debug/save/cache files,
scrubs secret fields, creates a deterministic `.pokemapgame`, then reopens
and inspects it before reporting success.

**Exporter le jeu** writes a certified package chosen by the author.
**Installer dans le Hub** publishes the same certified bytes through the
hash-bound Hub inbox protocol. No editor or Hub code dependency crosses that
boundary; both applications share only pure Dart distribution contracts.

## Headless generic release gate

After saving the export profile once, the same pipeline can run without the
editor UI:

```bash
dart run tool/export_pokemap_game.dart \
  --project /path/to/project \
  --output /path/to/game-1.0.0.pokemapgame
```

Use `--profile <file>` to supply a separate version-1 profile and
`--hub-inbox <directory>` to queue the certified artifact for direct Hub
installation. The command has no built-in project, Selbrume, or developer-host
assumption.
