import { createHash } from 'node:crypto';
import { readFile, realpath } from 'node:fs/promises';
import { resolve, join } from 'node:path';
import { Client } from '@modelcontextprotocol/client';
import { StdioClientTransport } from '@modelcontextprotocol/client/stdio';

type RecordValue = Record<string, unknown>;

function record(value: unknown): RecordValue {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new Error('Expected a canonical object response');
  }
  return value as RecordValue;
}

function coordinates(value: unknown): [number, number, number] {
  if (!Array.isArray(value) || value.length !== 3
    || !value.every(entry => typeof entry === 'number' && Number.isFinite(entry))) {
    throw new Error('Expected three finite coordinates');
  }
  return value as [number, number, number];
}

function rectangle(value: unknown): [number, number, number, number] {
  if (!Array.isArray(value) || value.length !== 4
    || !value.every(entry => typeof entry === 'number' && Number.isFinite(entry))) {
    throw new Error('Expected four finite rectangle coordinates');
  }
  return value as [number, number, number, number];
}

const args = process.argv.slice(2);
function option(name: string): string {
  const index = args.indexOf(name);
  const value = args[index + 1];
  if (index < 0 || !value) {
    throw new Error(`Required argument ${name}`);
  }
  return resolve(value);
}

const assetRoot = await realpath(option('--assets'));
const playerRoot = await realpath(option('--player'));
const parent = await realpath(option('--parent'));
const folderIndex = args.indexOf('--folder');
const folderName = folderIndex >= 0 ? args[folderIndex + 1] : 'hgss_first_map';
if (!folderName || !/^[a-zA-Z0-9_-]+$/.test(folderName)) {
  throw new Error('The folder must be one simple directory name');
}
const layoutBytes = await readFile(join(assetRoot, 'layout.json'));
const layout = record(JSON.parse(layoutBytes.toString('utf8')));
const provenance = record(JSON.parse(await readFile(join(assetRoot, 'provenance.json'), 'utf8')));
if (layout.width !== 16 || layout.depth !== 14
  || createHash('sha256').update(layoutBytes).digest('hex') !== provenance.layoutSha256) {
  throw new Error('Expected the unchanged 16 × 14 HGSS layout');
}
for (const [file, sha256] of [
  ['walk.png', 'ea9f9bdc96c95a5abaceee896577f4611c49ba76586654244568ff3a637123f3'],
  ['run.png', '983f3e0c33120df5b08344e49331227a387134bc06507df049532550244ed9be'],
] as const) {
  const bytes = await readFile(join(playerRoot, file));
  if (createHash('sha256').update(bytes).digest('hex') !== sha256
    || bytes.readUInt32BE(16) !== 128 || bytes.readUInt32BE(20) !== 128) {
    throw new Error(`Expected the original PSDK 128 × 128 player sheet: ${file}`);
  }
}
for (const raw of provenance.models as unknown[]) {
  const model = record(raw);
  const bytes = await readFile(join(assetRoot, String(model.file)));
  if (createHash('sha256').update(bytes).digest('hex') !== model.sha256) {
    throw new Error(`Source model digest differs: ${model.file}`);
  }
}
const transport = new StdioClientTransport({
  command: process.execPath,
  args: [resolve('dist/src/index.js'), '--root', parent,
    '--artifact-root', assetRoot, '--artifact-root', playerRoot],
  cwd: process.cwd(), stderr: 'pipe',
});
const client = new Client({ name: 'avelune-hgss-small-map-author', version: '1.0.0' });
let sequence = 0;
let workspaceHandle: string | undefined;
let projectHandle: string;

async function call(name: string, parameters: RecordValue): Promise<RecordValue> {
  const result = await client.callTool({ name, arguments: parameters });
  const envelope = record(result.structuredContent);
  if (result.isError || envelope.ok !== true) {
    throw new Error(`${name}: ${JSON.stringify(envelope.error)}`);
  }
  return record(envelope.data);
}

async function mutate(actionId: string, parameters: RecordValue): Promise<void> {
  const validation = await call('pokemap_validate', { projectHandle });
  const id = `small-map-${++sequence}`;
  const plan = await call('pokemap_plan', { projectHandle, request: {
    requestId: id, idempotencyKey: id, workspaceHandle, actionId,
    actionVersion: 1, expectedRevision: validation.snapshotRevision, parameters,
  } });
  const applied = await call('pokemap_apply', {
    operation: 'apply', projectHandle, planId: plan.planId, operationId: id,
  });
  if (record(applied.receipt).status !== 'applied') {
    throw new Error(`Mutation ${actionId} did not apply`);
  }
}

try {
  await client.connect(transport);
  const describe = await call('pokemap_describe', {});
  if (!(describe.mutationActions as RecordValue[]).some(
    action => action.id === 'map3d.navigation.configure',
  )) throw new Error('Rebuild the canonical 3D navigation worker before creating this map');
  const request = {
    name: 'La halte des falaises', folderName, parentPath: parent,
    template: 'empty', dimension: 'threeD', tileSize: 32,
    mapWidth: layout.width, mapHeight: layout.depth,
    spatialCamera: { mode: 'fixed', pitchDegrees: 48.7, yawDegrees: 0,
      fieldOfViewDegrees: 24, distance: 42 },
  };
  const preview = await call('pokemap_project_create_preview', { request });
  const created = await call('pokemap_project_create', { request, confirmation: preview.confirmation });
  const opened = await call('pokemap_workspace', { operation: 'open', projectRoot: created.projectPath });
  workspaceHandle = String(opened.workspaceHandle);
  projectHandle = String(opened.projectHandle);
  const mapId = String((created.mapIds as string[])[0]);
  for (const [modelId, name] of [
    ['terrain', 'Sol et chemin HGSS'], ['cliff_straight', 'Falaise HGSS · un étage'],
    ['stairs', 'Escalier HGSS · un étage'], ['house', 'Maison d’Oliville'],
  ]) {
    const staged = await call('pokemap_artifact_stage', {
      sourcePath: join(assetRoot, `${modelId}.glb`), declaredMediaType: 'model/gltf-binary',
    });
    await mutate('model3d.import', { modelId, name, artifactHandle: staged.artifactHandle });
  }
  const cells = [];
  for (let z = 0; z < 7; z++) for (let x = 0; x < 16; x++) {
    cells.push({ x, z, level: z === 6 ? 1 : 2 });
  }
  await mutate('map3d.terrain.set_levels', { mapId, cells });
  for (const [index, raw] of (layout.placements as unknown[]).entries()) {
    const placement = record(raw), position = coordinates(placement.position);
    await mutate('map3d.instance.upsert', { mapId, instance: {
      id: `${placement.model}_${index}`, modelId: placement.model,
      position: { x: position[0], y: position[1] + .02, z: position[2] },
      rotationDegrees: 0, scale: 1, animationIndex: null,
      blocksMovement: placement.model === 'house',
    } });
  }
  for (const state of ['walk', 'run']) {
    const staged = await call('pokemap_artifact_stage', {
      sourcePath: join(playerRoot, `${state}.png`), declaredMediaType: 'image/png',
    });
    if (state === 'walk') {
      await mutate('tileset.import_image', { artifactHandle: staged.artifactHandle,
        tilesetId: 'psdk_player', name: 'Voyageur PSDK', tileWidth: 32, tileHeight: 32 });
      await mutate('characterStudio.character.create', {
        name: 'Voyageur PSDK', tilesetId: 'psdk_player', frameWidth: 1, frameHeight: 1,
      });
    }
    await mutate('characterStudio.asset.import', { artifactHandle: staged.artifactHandle,
      assetId: `psdk_${state}`, logicalPath: `assets/characters/psdk/${state}.png`,
      mediaKind: 'spriteSheet', tags: ['PSDK', 'hgss-first-map'] });
  }
  for (const [row, direction] of ['south', 'west', 'east', 'north'].entries()) {
    for (const state of ['idle', 'walk', 'run']) {
      await mutate('characterStudio.animationClip.upsert', {
        characterId: 'voyageur-psdk', kind: 'system', state, direction, loop: true,
        sourceAssetId: state === 'run' ? 'psdk_run' : 'psdk_walk',
        frames: (state === 'idle' ? [0] : [1, 2, 3, 2]).map(x => ({
          source: { x: x * 32, y: row * 32, width: 32, height: 32 },
          durationMs: state === 'run' ? 85 : 117,
        })),
      });
    }
  }
  await mutate('characterStudio.character.setDefault', { characterId: 'voyageur-psdk' });
  const spawn = coordinates(layout.playerSpawn);
  await mutate('map3d.navigation.configure', { mapId, navigation: {
    spawn: { x: spawn[0], z: spawn[2] }, allowDiagonalMovement: false,
    ramps: (layout.ramps as RecordValue[]).map((ramp, index) => {
      const rect = rectangle(ramp.rect);
      return { id: `stairs_${index}`, x: rect[0], z: rect[1],
        width: rect[2] - rect[0], depth: rect[3] - rect[1],
        lowLevel: ramp.heightSouth, highLevel: ramp.heightNorth, direction: ramp.direction };
    }),
    blockedAreas: (layout.blockedRects as unknown[]).slice(0, 2).map(value => {
      const rect = rectangle(value);
      return { x: rect[0], z: rect[1], width: rect[2] - rect[0], depth: rect[3] - rect[1] };
    }),
  } });
  const staged = await call('pokemap_artifact_stage', {
    sourcePath: join(assetRoot, 'provenance.json'),
  });
  await mutate('asset.import', { artifactHandle: staged.artifactHandle,
    assetId: 'hgss_source_provenance', logicalPath: 'assets/provenance/hgss.json', tags: ['provenance'] });
  const validation = await call('pokemap_validate', { projectHandle });
  if (validation.valid !== true) throw new Error(`Project validation failed: ${JSON.stringify(validation)}`);
  console.log(JSON.stringify({ projectPath: created.projectPath, mapId,
    models: 4, instances: (layout.placements as unknown[]).length, valid: true }));
} finally {
  try {
    if (workspaceHandle) await call('pokemap_workspace', { operation: 'close', workspaceHandle });
  } finally {
    try {
      await client.close();
    } finally {
      await transport.close();
    }
  }
}
