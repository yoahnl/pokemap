import assert from 'node:assert/strict';
import { createHash, randomUUID } from 'node:crypto';
import { appendFile, copyFile, mkdir, readFile, realpath, writeFile } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { dirname, isAbsolute, relative, resolve, sep } from 'node:path';
import { setTimeout as delay } from 'node:timers/promises';
import { fileURLToPath } from 'node:url';

const repository = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const hash = bytes => createHash('sha256').update(bytes).digest('hex');

export function artifactFingerprint(bytes) {
  const name = Buffer.from('artifact-content');
  const nameLength = Buffer.alloc(8);
  const contentLength = Buffer.alloc(8);
  nameLength.writeBigUInt64BE(BigInt(name.length));
  contentLength.writeBigUInt64BE(BigInt(bytes.length));
  return `sha256:${createHash('sha256').update(nameLength).update(name).update(contentLength).update(bytes).digest('hex')}`;
}

export function validateStagedSource(staged, digest, byteLength) {
  assert.equal(staged.digest, digest, 'Staged source bytes changed');
  assert.equal(staged.byteLength, byteLength, 'Staged source size changed');
}

export async function readCanonicalPages(call, projectHandle, revision, kind, ids, options = {}) {
  if (ids?.length === 0) return [];
  const items = [];
  const seenIds = new Set();
  const seenCursors = new Set();
  let cursor;
  do {
    const page = await call('pokemap_query', {
      projectHandle, resourceKind: kind, operation: ids ? ids.length === 1 ? 'get' : 'batch_get' : 'list',
      ...(ids ? { ids } : {}), view: 'detail', pageSize: options.pageSize ?? 200,
      ...(cursor ? { cursor } : {}),
    });
    assert.match(page.snapshotRevision, /^sha256:[a-f0-9]{64}$/);
    assert.equal(page.snapshotRevision, revision, 'Project changed outside the current canonical mutation cohort');
    for (const item of page.items) {
      assert.ok(item.id && !seenIds.has(item.id), `Duplicate canonical resource ${kind}:${item.id}`);
      seenIds.add(item.id);
      items.push(item);
    }
    cursor = page.nextCursor;
    if (cursor) {
      assert.ok(!seenCursors.has(cursor), `Repeated canonical cursor ${kind}`);
      seenCursors.add(cursor);
    }
  } while (cursor);
  return items;
}

export function protectedModel(model) {
  const { inspection, resourceKind, ...identity } = model;
  return identity;
}

export function protectedMap(map) {
  const copy = structuredClone(map);
  for (const instance of copy.spatialScene?.instances ?? []) {
    delete instance.animationIndex;
    delete instance.animationLoop;
    delete instance.animationSpeed;
  }
  return copy;
}

export function instancePlayback(instance, entry) {
  return { ...instance, animationIndex: entry.recommendedAnimationIndex,
    animationLoop: true, animationSpeed: entry.recommendedAnimationSpeed ?? instance.animationSpeed };
}

export function validateApplication(index, models) {
  assert.equal(index.schemaVersion, 1);
  assert.ok(Array.isArray(index.entries), 'Missing animation entries');
  const known = new Map(models.map(model => [model.id, model]));
  const seen = new Set();
  for (const entry of index.entries) {
    assert.ok(!seen.has(entry.modelId), `Duplicate animation model ${entry.modelId}`);
    seen.add(entry.modelId);
    assert.ok(known.has(entry.modelId), `Unknown animation model ${entry.modelId}`);
    assert.ok(isAbsolute(entry.sourcePath), 'A canonical source path is required');
    assert.match(entry.sourceSha256Before, /^[a-f0-9]{64}$/);
    assert.match(entry.sha256After, /^[a-f0-9]{64}$/);
    assert.ok(entry.recommendedAnimationIndex == null ||
      Number.isSafeInteger(entry.recommendedAnimationIndex) && entry.recommendedAnimationIndex >= 0);
    assert.ok(entry.recommendedAnimationSpeed == null ||
      Number.isFinite(entry.recommendedAnimationSpeed) && entry.recommendedAnimationSpeed > 0);
  }
}

export function splitSourceBatches(entries, maximumCount = 50, maximumBytes = 64 * 1024 * 1024) {
  const batches = [];
  let batch = [], totalBytes = 0;
  for (const entry of entries) {
    assert.ok(Number.isSafeInteger(entry.byteLength) && entry.byteLength > 0 &&
      entry.byteLength <= maximumBytes, `Invalid model source size ${entry.modelId}`);
    if (batch.length === maximumCount || totalBytes + entry.byteLength > maximumBytes) {
      batches.push(batch);
      batch = [];
      totalBytes = 0;
    }
    batch.push(entry);
    totalBytes += entry.byteLength;
  }
  if (batch.length) batches.push(batch);
  return batches;
}

export async function backupProject(projectRoot, backupRoot, manifest, index) {
  projectRoot = await realpath(projectRoot);
  const models = new Map(manifest.models3d.map(model => [model.id, model]));
  const paths = new Set(['project.json', 'assets/.pokemap-assets.json',
    ...manifest.maps.map(map => map.relativePath),
    ...index.entries.map(entry => models.get(entry.modelId).relativePath)]);
  for (const path of paths) {
    const source = await inside(projectRoot, resolve(projectRoot, path));
    const target = resolve(backupRoot, path);
    await mkdir(dirname(target), { recursive: true });
    await copyFile(source, target);
    assert.equal(hash(await readFile(source)), hash(await readFile(target)));
  }
}

function argumentsFrom(argv) {
  const options = {};
  for (let i = 0; i < argv.length; i++) {
    const key = argv[i];
    assert.ok(['--project-root', '--index', '--evidence-root', '--apply', '--export-path'].includes(key), `Unknown argument ${key}`);
    assert.ok(!(key in options), `Repeated argument ${key}`);
    if (key === '--apply') options[key] = true;
    else {
      assert.ok(argv[i + 1] && !argv[i + 1].startsWith('--'), `Missing value ${key}`);
      options[key] = argv[++i];
    }
  }
  for (const key of ['--project-root', '--index', '--evidence-root']) assert.ok(options[key], `Required ${key}`);
  return options;
}

async function inside(root, path) {
  const result = await realpath(path);
  const local = relative(root, result);
  assert.ok(local && local !== '..' && !local.startsWith(`..${sep}`) && !isAbsolute(local), `Path outside root ${path}`);
  return result;
}

export async function applyCityAnimations(options) {
  const projectRoot = await realpath(options['--project-root']);
  const indexPath = await realpath(options['--index']);
  const artifactRoot = dirname(indexPath);
  const evidenceRoot = resolve(options['--evidence-root']);
  await mkdir(evidenceRoot, { recursive: true });
  const index = JSON.parse(await readFile(indexPath, 'utf8'));
  const manifest = JSON.parse(await readFile(resolve(projectRoot, 'project.json'), 'utf8'));
  validateApplication(index, manifest.models3d);
  const models = new Map(manifest.models3d.map(model => [model.id, model]));
  const entries = new Map(index.entries.map(entry => [entry.modelId, entry]));
  const sourceByteLengths = new Map();
  const sourceArtifactDigests = new Map();
  const beforeMaps = new Map();
  for (const map of manifest.maps) {
    const path = await inside(projectRoot, resolve(projectRoot, map.relativePath));
    beforeMaps.set(map.id, JSON.parse(await readFile(path, 'utf8')));
  }
  for (const entry of index.entries) {
    await inside(artifactRoot, entry.sourcePath);
    const sourceBytes = await readFile(entry.sourcePath);
    assert.equal(hash(sourceBytes), entry.sha256After, `Staged source changed ${entry.modelId}`);
    sourceByteLengths.set(entry.modelId, sourceBytes.length);
    sourceArtifactDigests.set(entry.modelId, artifactFingerprint(sourceBytes));
    const currentPath = await inside(projectRoot, resolve(projectRoot, models.get(entry.modelId).relativePath));
    const currentHash = hash(await readFile(currentPath));
    assert.ok([entry.sourceSha256Before, entry.sha256After].includes(currentHash), `Source changed outside recipe ${entry.modelId}`);
  }
  const runId = randomUUID();
  const backupRoot = resolve(evidenceRoot, `backup-${runId}`);
  const receiptPath = resolve(evidenceRoot, `receipts-${runId}.jsonl`);
  if (options['--apply']) {
    await backupProject(projectRoot, backupRoot, manifest, index);
  }
  const require = createRequire(resolve(repository, 'tools/pokemap_mcp/package.json'));
  const { Client } = require('@modelcontextprotocol/client');
  const { StdioClientTransport } = require('@modelcontextprotocol/client/stdio');
  const exportPath = options['--export-path'] ? resolve(options['--export-path']) : null;
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve(repository, 'tools/pokemap_mcp/dist/src/index.js'), '--root', projectRoot,
      '--artifact-root', artifactRoot, '--authoring-timeout-ms', '120000',
      ...(exportPath ? ['--export-root', dirname(exportPath)] : [])], cwd: repository, stderr: 'pipe' });
  const client = new Client({ name: 'unys-original-city-animations', version: '1.0.0' });
  transport.stderr?.on('data', chunk => process.stderr.write(chunk));
  let opened, revision, descriptors, lastMutation = 0;
  let sourceChanges = 0, animatedInstances = 0;
  async function call(name, args = {}) {
    const response = await client.callTool({ name, arguments: args }, { timeout: 125000 });
    assert.ok(response.structuredContent?.ok, JSON.stringify(response.structuredContent?.error));
    return response.structuredContent.data;
  }
  async function mutate(actionId, parameters) {
    await delay(Math.max(0, 1100 - (Date.now() - lastMutation)));
    lastMutation = Date.now();
    const operationId = `city-animation-${randomUUID()}`;
    const planned = await call('pokemap_plan', { projectHandle: opened.projectHandle,
      request: { requestId: operationId, actionId, actionVersion: descriptors.get(actionId).version,
        workspaceHandle: opened.workspaceHandle, parameters, expectedRevision: revision,
        idempotencyKey: operationId, dryRun: false } });
    assert.equal(planned.plan.baseRevision, revision);
    assert.ok(!planned.requiredConfirmation && !planned.plan.requiredConfirmation);
    if (!planned.applicable) {
      assert.equal(planned.nonApplicableReason, 'no_changes');
      return false;
    }
    await appendFile(receiptPath, JSON.stringify({ event: 'intent', actionId, operationId, revision, planId: planned.planId }) + '\n');
    const applied = await call('pokemap_apply', { operation: 'apply', projectHandle: opened.projectHandle,
      planId: planned.planId, operationId });
    assert.equal(applied.receipt.status, 'applied');
    revision = applied.snapshotRevision;
    await appendFile(receiptPath, JSON.stringify({ event: 'applied', receipt: applied.receipt, revision }) + '\n');
    return true;
  }
  async function query(kind, ids, options) {
    return readCanonicalPages(call, opened.projectHandle, revision, kind, ids, options);
  }
  try {
    await client.connect(transport);
    const catalog = await call('pokemap_describe');
    descriptors = new Map(catalog.mutationActions.map(action => [action.id, action]));
    assert.ok(descriptors.has('model3d.source.replace_batch'));
    assert.ok(descriptors.has('map3d.instance.upsert_batch'));
    opened = await call('pokemap_workspace', { operation: 'open', projectRoot });
    const baseline = await call('pokemap_validate', { projectHandle: opened.projectHandle });
    assert.equal(baseline.valid, true, JSON.stringify(baseline.diagnostics));
    revision = baseline.snapshotRevision;
    const canonicalModels = new Map((await query('model3d', [...entries.keys()], { pageSize: 50 })).map(model => [model.id, model]));
    for (const entry of index.entries) assert.deepEqual(protectedModel(canonicalModels.get(entry.modelId)), protectedModel(models.get(entry.modelId)));
    if (!options['--apply']) {
      const preview = { dryRun: true, projectRoot, candidateModels: entries.size, revision,
        ambientInstances: [...beforeMaps.values()].reduce((total, map) => total +
          (map.spatialScene?.instances ?? []).filter(instance => entries.get(instance.modelId)?.recommendedAnimationIndex != null).length, 0) };
      console.log(JSON.stringify(preview));
      return preview;
    }
    const batches = splitSourceBatches(index.entries.map(entry => ({ ...entry,
      byteLength: sourceByteLengths.get(entry.modelId) })));
    for (const batch of batches) {
      const replacements = [];
      const stagedByDigest = new Map();
      for (const entry of batch) {
        const model = models.get(entry.modelId);
        if (hash(await readFile(resolve(projectRoot, model.relativePath))) !== entry.sha256After) {
          let staged = stagedByDigest.get(entry.sha256After);
          if (!staged) {
            staged = await call('pokemap_artifact_stage', { sourcePath: entry.sourcePath, declaredMediaType: 'model/gltf-binary' });
            validateStagedSource(staged, sourceArtifactDigests.get(entry.modelId), sourceByteLengths.get(entry.modelId));
            stagedByDigest.set(entry.sha256After, staged);
          }
          replacements.push({ modelId: model.id, artifactHandle: staged.artifactHandle });
        }
      }
      if (replacements.length && await mutate('model3d.source.replace_batch', { models: replacements })) {
        sourceChanges += replacements.length;
      }
      const currentModels = new Map((await query('model3d', batch.map(entry => entry.modelId),
        { pageSize: 50 })).map(model => [model.id, model]));
      for (const entry of batch) {
        const model = models.get(entry.modelId), current = currentModels.get(entry.modelId);
        assert.deepEqual(protectedModel(current), protectedModel(model));
        assert.equal(hash(await readFile(resolve(projectRoot, model.relativePath))), entry.sha256After);
        if (entry.recommendedAnimationIndex != null) assert.ok(current.inspection.animations.some(clip => clip.index === entry.recommendedAnimationIndex));
      }
      console.log(JSON.stringify({ verifiedModels: batch.length, sourceChanges }));
    }
    for (const map of manifest.maps) {
      const before = beforeMaps.get(map.id);
      const selected = (before.spatialScene?.instances ?? []).filter(instance => {
        const entry = entries.get(instance.modelId);
        return entry?.recommendedAnimationIndex != null &&
          (instance.animationIndex !== entry.recommendedAnimationIndex || !instance.animationLoop ||
            instance.animationSpeed !== (entry.recommendedAnimationSpeed ?? instance.animationSpeed));
      });
      if (!selected.length) continue;
      const [current] = await query('map', [map.id]);
      assert.deepEqual(current.spatialScene.instances, before.spatialScene.instances, `Placed objects changed ${map.id}`);
      for (let i = 0; i < selected.length; i += 50) {
        const instances = selected.slice(i, i + 50).map(instance => instancePlayback(instance, entries.get(instance.modelId)));
        await mutate('map3d.instance.upsert_batch', { mapId: map.id, instances });
        animatedInstances += instances.length;
      }
      const [after] = await query('map', [map.id]);
      assert.deepEqual(protectedMap(after), protectedMap(current), `Map geometry changed ${map.id}`);
      const selectedIds = new Set(selected.map(instance => instance.id));
      const expectedInstances = current.spatialScene.instances.map(instance => selectedIds.has(instance.id)
        ? instancePlayback(instance, entries.get(instance.modelId))
        : instance);
      assert.deepEqual(after.spatialScene.instances, expectedInstances, `Unrelated playback changed ${map.id}`);
      for (const instance of selected) assert.equal(after.spatialScene.instances.find(value => value.id === instance.id).animationIndex,
        entries.get(instance.modelId).recommendedAnimationIndex);
      for (const instance of selected) assert.equal(after.spatialScene.instances.find(value => value.id === instance.id).animationSpeed,
        entries.get(instance.modelId).recommendedAnimationSpeed ?? instance.animationSpeed);
    }
    const final = await call('pokemap_validate', { projectHandle: opened.projectHandle });
    assert.equal(final.valid, true, JSON.stringify(final.diagnostics));
    revision = final.snapshotRevision;
    const afterManifest = JSON.parse(await readFile(resolve(projectRoot, 'project.json'), 'utf8'));
    const protectedManifest = value => ({ ...value, models3d: value.models3d.map(protectedModel) });
    assert.deepEqual(protectedManifest(afterManifest), protectedManifest(manifest), 'Unrelated project data changed');
    for (const map of afterManifest.maps) {
      const after = JSON.parse(await readFile(resolve(projectRoot, map.relativePath), 'utf8'));
      assert.deepEqual(protectedMap(after), protectedMap(beforeMaps.get(map.id)), `Unrelated map data changed ${map.id}`);
    }
    let exported;
    if (exportPath) exported = await call('pokemap_game_export', {
      projectHandle: opened.projectHandle, mode: 'localTest', outputPath: exportPath });
    const result = { completed: true, projectRoot, revision, sourceChanges, animatedInstances,
      backupRoot, receiptPath, atomicity: 'recoverable_cross_file; the full city cohort is not atomic', exported };
    await writeFile(resolve(evidenceRoot, `result-${runId}.json`), JSON.stringify(result, null, 2));
    console.log(JSON.stringify(result));
    return result;
  } finally {
    if (opened) await call('pokemap_workspace', { operation: 'close', workspaceHandle: opened.workspaceHandle }).catch(() => {});
    await client.close();
  }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  applyCityAnimations(argumentsFrom(process.argv.slice(2))).catch(error => {
    console.error(error);
    process.exitCode = 1;
  });
}
