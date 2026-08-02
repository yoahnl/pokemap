# PERF-RM-08 Editor Asset Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` or `executing-plans` task by task. Every behavior change follows red → green → refactor.

**Goal:** Remove synchronous image I/O/decode from editor build paths and bound project-scoped decoded image memory with safe leases and revision-aware LRU eviction.

**Architecture:** Extend the existing `EditorImageCache`; do not create another global cache. One project-scoped service owns async metadata/read/decode, full sources and crops, single-flight futures, decoded-byte accounting, and post-frame retirement. Widgets own cloned consumer handles and render design-system loading/error states.

**Tech Stack:** Flutter `dart:ui`, Riverpod family provider, PokeMap design system, widget tests and macOS profile driver.

---

### Task 1: Characterize cache ownership and weighted eviction

**Files:**
- Modify: `packages/map_editor/test/editor_image_cache_test.dart`

- [ ] Add injected gated file probe, byte reader, decoder, and cropper; assert two concurrent callers perform each stage once.
- [ ] Add weighted A/B/touch-A/C LRU, oversize non-retention, safe acquired clone after eviction, failure retry, same-path revision replacement, crop single-flight, in-flight dispose, and project isolation cases.
- [ ] Assert `residentDecodedBytes <= maximumDecodedBytes`, peak bytes, evictions, and in-flight counts.
- [ ] Run the focused test and retain the expected red failures before production changes.

### Task 2: Extend the one canonical editor cache

**Files:**
- Modify: `packages/map_editor/lib/src/ui/assets/editor_image_cache.dart`
- Modify: `packages/map_editor/lib/src/app/providers/editor/editor_asset_cache_providers.dart`

- [ ] Add injectable async file/decode seams whose defaults use `File` and `ui.instantiateImageCodec` with codec disposal in `finally`.
- [ ] Add a 32 MiB initial decoded-byte budget, insertion-ordered LRU touch, `width * height * 4` weights, and diagnostics.
- [ ] Add `loadCrop` backed by the same source master and cache budget.
- [ ] Track pending acquisitions so eviction/invalidations never dispose a master before all waiting consumers clone it.
- [ ] Serve an entry larger than the budget once without retaining it; remove failed futures so retry remains possible.

### Task 3: Make Environment thumbnails fully async

**Files:**
- Modify: `packages/map_editor/lib/src/features/environment_studio/widgets/environment_element_thumbnail.dart`
- Modify wiring only where a project root/cache must be supplied in `packages/map_editor/lib/src/features/environment_studio/widgets/`
- Create: `packages/map_editor/test/environment_studio/environment_element_thumbnail_async_test.dart`

- [ ] Replace `existsSync`, `readAsBytesSync`, `img.decodeImage`, `copyCrop`, pixel painter, and the static crop cache with `EditorImageCache.loadCrop`.
- [ ] Hold/release one lease per displayed result and ignore/release late results after widget updates.
- [ ] Render tokenized loading, missing/decode error, and success states with accessible semantics.
- [ ] Test slow read/decode, success, error, stale A→B completion, rebuild single-flight, and disposal.

### Task 4: Make Path Studio loaders and previews async

**Files:**
- Modify: `packages/map_editor/lib/src/features/path_studio/path_pattern_tileset_image_info_loader.dart`
- Modify: `packages/map_editor/lib/src/features/path_studio/path_studio_tileset_image_picker.dart`
- Modify: `packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart`
- Modify: `packages/map_editor/test/path_pattern/path_studio_tileset_image_picker_test.dart`
- Create focused loader/panel tests beside the existing Path Studio tests.

- [ ] Stop calling the image-info loader synchronously from `build`; expose an async read model keyed by project root plus tileset revisions.
- [ ] Derive dimensions from the central decoded image, not `package:image` on the UI isolate.
- [ ] Include transparent color in the variant key and offload any required PNG transform before decode.
- [ ] Paint full/tile previews from leased `ui.Image` source rects; remove decode→crop→encode→`Image.memory` cycles from `build`.
- [ ] Cover missing root/file, invalid grid, loading, transparent variant, late result, file revision, and lease cleanup.

### Task 5: Remove the Tileset Editor static cache

**Files:**
- Modify: `packages/map_editor/lib/src/ui/canvas/tileset_editor_canvas.dart`
- Add or modify its focused widget test.

- [ ] Replace `_TilesetEditorImageCache` with `editorImageCacheProvider(projectRoot)` and a state owner for its consumer lease.
- [ ] Distinguish loading from typed error, invalidate on file revision, and release the old image after handoff.
- [ ] Delete the static path-only future map and prove the codec and images are retired.

### Task 6: Profile and regress the shared cache

- [ ] Re-run palette/world-map async-order tests because they already consume `EditorImageCache`.
- [ ] Add a profile journey for 100 assets, duplicates, failures, project switch, and ten cycles; capture frame timings, cache diagnostics, RSS, and native memory in three runs.
- [ ] Require zero synchronous I/O/decode in `build`, one decode per source/revision in flight, safe eviction, non-stale previews, and stabilized growth at most 50 MiB or 10%.

**Verification:**

```bash
cd packages/map_editor && flutter test test/editor_image_cache_test.dart test/environment_studio/environment_element_thumbnail_async_test.dart test/path_pattern/path_studio_tileset_image_picker_test.dart
cd packages/map_editor && flutter test && flutter analyze && flutter build macos --debug
```

**MCP parity:** N/A for new semantics: this lot changes presentation performance and ownership only. Project data, authoring actions, validation, import/export and persistence formats remain unchanged.

**Non-goals:** runtime cache sharing, preload-all, cache limits by entry count, raw product colors, removing previews, canvas viewport work from `RM-07B`, or unrelated synchronous file checks outside the four audited consumers.
