import assert from 'node:assert/strict';
import test from 'node:test';
import { mkdtemp, mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';

import { artifactFingerprint, backupProject, instancePlayback, protectedMap, protectedModel, readCanonicalPages, splitSourceBatches, validateApplication, validateStagedSource } from './apply_bw2_city_animations.mjs';

test('targeted water cadence preserves custom playback speeds on other objects', () => {
  const instance = { id: 'door', animationIndex: 0, animationLoop: true, animationSpeed: 0.7 };
  assert.deepEqual(instancePlayback(instance, { recommendedAnimationIndex: 0 }), instance);
  assert.equal(instancePlayback(instance, { recommendedAnimationIndex: 0, recommendedAnimationSpeed: 0.5 }).animationSpeed, 0.5);
  assert.equal(instance.animationSpeed, 0.7);
});

test('staging refuses source changes between prevalidation and publication', () => {
  const source = Buffer.from('original-model-bytes');
  const expected = artifactFingerprint(source);
  assert.equal(expected, 'sha256:5865a1106a9638af7743c0f1dd5d50c0163d01e30ffd9a3ffd20f0d6074626fe');
  validateStagedSource({ digest: expected, byteLength: source.length }, expected, source.length);
  assert.throws(() => validateStagedSource({ digest: artifactFingerprint(Buffer.from('modified-model-bytes')), byteLength: source.length }, expected, source.length));
  assert.throws(() => validateStagedSource({ digest: expected, byteLength: source.length + 1 }, expected, source.length));
});

test('source replacement cohorts respect both model and byte publication limits', () => {
  const small = Array.from({ length: 51 }, (_, i) => ({ modelId: `model-${i}`, byteLength: 1024 }));
  assert.deepEqual(splitSourceBatches(small).map(batch => batch.length), [50, 1]);
  const large = Array.from({ length: 3 }, (_, i) => ({ modelId: `large-${i}`, byteLength: 32 * 1024 * 1024 }));
  assert.deepEqual(splitSourceBatches(large).map(batch => batch.length), [2, 1]);
  assert.throws(() => splitSourceBatches([{ modelId: 'oversize', byteLength: 64 * 1024 * 1024 + 1 }]));
  assert.deepEqual(splitSourceBatches([]), []);
});

test('canonical pagination rejects a revision change and a repeating cursor', async () => {
  const revision = `sha256:${'a'.repeat(64)}`;
  const pages = [{ snapshotRevision: revision, items: [{ id: 'water' }], nextCursor: 'next' },
    { snapshotRevision: `sha256:${'b'.repeat(64)}`, items: [{ id: 'fountain' }] }];
  await assert.rejects(readCanonicalPages(async () => pages.shift(), 'project', revision, 'model3d'));
  const repeat = [{ snapshotRevision: revision, items: [{ id: 'water' }], nextCursor: 'next' },
    { snapshotRevision: revision, items: [{ id: 'fountain' }], nextCursor: 'next' }];
  await assert.rejects(readCanonicalPages(async () => repeat.shift(), 'project', revision, 'model3d'));
  const valid = [{ snapshotRevision: revision, items: [{ id: 'water' }], nextCursor: 'next' },
    { snapshotRevision: revision, items: [{ id: 'fountain' }] }];
  assert.deepEqual(await readCanonicalPages(async () => valid.shift(), 'project', revision, 'model3d'),
    [{ id: 'water' }, { id: 'fountain' }]);
});

test('a source replacement backup retains matching catalog, manifest, maps and model bytes', async () => {
  const root = await mkdtemp(join(tmpdir(), 'avelune-animation-backup-'));
  try {
    const projectRoot = join(root, 'project');
    const backupRoot = join(root, 'backup');
    const manifest = { maps: [{ relativePath: 'maps/city.json' }],
      models3d: [{ id: 'fountain', relativePath: 'assets/models3d/fountain.glb' }] };
    const files = { 'project.json': JSON.stringify(manifest),
      'maps/city.json': JSON.stringify({ id: 'city', userEditedHeight: 2 }),
      'assets/.pokemap-assets.json': JSON.stringify({ fountain: { sha256: 'original-model-hash' } }),
      'assets/models3d/fountain.glb': 'original-model-bytes' };
    for (const [path, content] of Object.entries(files)) {
      await mkdir(dirname(join(projectRoot, path)), { recursive: true });
      await writeFile(join(projectRoot, path), content);
    }
    await backupProject(projectRoot, backupRoot, manifest, { entries: [{ modelId: 'fountain' }] });
    await writeFile(join(projectRoot, 'assets/.pokemap-assets.json'), 'new-catalog');
    await writeFile(join(projectRoot, 'assets/models3d/fountain.glb'), 'new-model');
    for (const [path, content] of Object.entries(files)) {
      assert.equal(await readFile(join(backupRoot, path), 'utf8'), content);
    }
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test('animation application preserves user geometry and model settings', () => {
  const map = { id: 'city', spatialScene: { navigation: { heights: [0, 1] }, instances: [
    { id: 'tree', modelId: 'tree', position: { x: 1, y: 2, z: 3 }, animationIndex: null, animationLoop: true, animationSpeed: 1 },
  ] } };
  const animated = structuredClone(map);
  animated.spatialScene.instances[0].animationIndex = 0;
  assert.deepEqual(protectedMap(animated), protectedMap(map));
  animated.spatialScene.instances[0].position.y = 4;
  assert.notDeepEqual(protectedMap(animated), protectedMap(map));
  const model = { id: 'tree', scale: 2, pivot: { x: 0, y: 1, z: 0 }, inspection: { animations: [] } };
  assert.deepEqual(protectedModel(model), protectedModel({ ...model, inspection: { animations: [{}] } }));
  assert.notDeepEqual(protectedModel(model), protectedModel({ ...model, scale: 1 }));
});

test('animation application refuses unknown models and stale source identities', () => {
  const entry = { modelId: 'tree', sourcePath: '/private/tmp/tree.glb',
    sourceSha256Before: 'a'.repeat(64), sha256After: 'b'.repeat(64), recommendedAnimationIndex: 0 };
  const index = { schemaVersion: 1, entries: [entry] };
  validateApplication(index, [{ id: 'tree' }]);
  validateApplication({ ...index, entries: [{ ...entry, recommendedAnimationSpeed: 0.5 }] }, [{ id: 'tree' }]);
  for (const speed of [0, -1, NaN, Infinity, '0.5']) {
    assert.throws(() => validateApplication({ ...index, entries: [{ ...entry, recommendedAnimationSpeed: speed }] }, [{ id: 'tree' }]));
  }
  assert.throws(() => validateApplication(index, []));
  assert.throws(() => validateApplication({ ...index, entries: [entry, entry] }, [{ id: 'tree' }]));
  assert.throws(() => validateApplication({ ...index, entries: [{ ...entry, sourceSha256Before: 'no' }] }, [{ id: 'tree' }]));
  assert.throws(() => validateApplication({ ...index, entries: [{ ...entry, recommendedAnimationIndex: -1 }] }, [{ id: 'tree' }]));
});
