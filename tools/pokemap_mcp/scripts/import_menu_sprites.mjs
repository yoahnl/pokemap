import assert from 'node:assert/strict';
import { readFile, realpath, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { dirname, join, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Client } from '@modelcontextprotocol/client';
import { InMemoryTransport } from '@modelcontextprotocol/server';
import { LocalAuthoringClient } from '../dist/src/authoring_client.js';
import { MemoryArtifactReader } from '../dist/src/artifacts.js';
import { createPokeMapMcpServer } from '../dist/src/server.js';

const args = process.argv.slice(2);
const apply = args.includes('--apply');
const positional = args.filter((value) => value !== '--apply');
assert.equal(positional.length, 4, 'Usage: import_menu_sprites.mjs <project> <source> <inventory.json> <receipt.json> [--apply]');
const [projectRoot, sourceRoot] = await Promise.all(positional.slice(0, 2).map((path) => realpath(path)));
const inventory = JSON.parse(await readFile(positional[2], 'utf8'));
const images = new Map(inventory.assets.map((asset) => [asset.path, asset]));
const aliases = new Map(inventory.mediaAliases.map((alias) => [alias.sourceId, alias.homeSourceId]));
const serverRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const authoring = new LocalAuthoringClient({
  allowedRoots: [projectRoot], artifactRoots: [sourceRoot],
  authoringPackageRoot: resolve(serverRoot, '../../packages/map_authoring'),
  workerTimeoutMs: 120000, requestTimeoutMs: 125000,
});
const server = createPokeMapMcpServer({ authoring, projectRoots: authoring, artifacts: new MemoryArtifactReader() });
const [transport, serverTransport] = InMemoryTransport.createLinkedPair();
const client = new Client({ name: 'pokemap-menu-sprite-import', version: '1.0.0' });
const receipt = { applied: apply, transport: 'mcp-loopback-jsonl-worker', batches: [], unavailable: [], sourceTableSha256: inventory.speciesTableSha256 };
let sequence = 0;
async function call(name, arguments_ = {}, attempts = 0) {
  const response = await client.callTool({ name, arguments: arguments_ }, undefined, { timeout: 180000 });
  const envelope = response.structuredContent;
  if (envelope?.error?.code === 'rate_limited' && attempts < 3) {
    console.log('Waiting for the canonical MCP rate window');
    await new Promise((resolve) => setTimeout(resolve, 55000));
    return call(name, arguments_, attempts + 1);
  }
  assert.ok(!response.isError, JSON.stringify(response.structuredContent));
  assert.equal(envelope.ok, true, JSON.stringify(envelope));
  return envelope.data;
}
try {
  await server.connect(serverTransport);
  await client.connect(transport);
  console.log('MCP connected');
  const description = await call('pokemap_describe');
  assert.ok(description.mutationActions.some((action) => action.id === 'pokemon.media.import'));
  const opened = await call('pokemap_workspace', { operation: 'open', projectRoot });
  console.log('Project opened');
  const { projectHandle, workspaceHandle } = opened;
  let revision = (await call('pokemap_validate', { projectHandle })).snapshotRevision;
  receipt.initialRevision = revision;
  assert.ok(inventory.qualificationInputSha256, 'Regenerate the project inventory before import.');
  for (const [path, expected] of Object.entries(inventory.qualificationInputSha256)) {
    const inputPath = await realpath(join(projectRoot, path));
    assert.ok(!relative(projectRoot, inputPath).startsWith('..'));
    assert.equal(createHash('sha256').update(await readFile(inputPath)).digest('hex'), expected,
      `Project changed since qualification: ${path}. Regenerate the inventory.`);
  }
  const forms = inventory.qualification.filter((entry) => entry.decision === 'matched');
  for (let offset = 0; offset < forms.length; offset += 45) {
    const entries = [];
    const handles = new Map();
    for (const form of forms.slice(offset, offset + 45)) {
      const sourceId = aliases.get(form.sourceId) ?? form.sourceId;
      const homePath = `src/minisprites/pokemon/home/${sourceId}.png`;
      const path = images.has(homePath) ? homePath : `src/previews/gen9/${form.sourceId}.png`;
      const image = images.get(path);
      if (!image) {
        receipt.unavailable.push({ speciesId: form.speciesId, formId: form.formId });
        continue;
      }
      let handle = handles.get(path);
      if (!handle) {
        const sourcePath = await realpath(join(sourceRoot, path));
        assert.ok(!relative(sourceRoot, sourcePath).startsWith('..'));
        const bytes = await readFile(sourcePath);
        assert.equal(createHash('sha256').update(bytes).digest('hex'), image.sha256);
        const staged = await call('pokemap_artifact_stage', { sourcePath, declaredMediaType: 'image/png' });
        const logicalName = Buffer.from('artifact-content');
        const nameLength = Buffer.alloc(8);
        nameLength.writeBigUInt64BE(BigInt(logicalName.length));
        const byteLength = Buffer.alloc(8);
        byteLength.writeBigUInt64BE(BigInt(bytes.length));
        const digest = createHash('sha256').update(nameLength).update(logicalName).update(byteLength).update(bytes).digest('hex');
        assert.equal(staged.digest, `sha256:${digest}`);
        assert.equal(staged.byteLength, bytes.length);
        handle = staged.artifactHandle;
        handles.set(path, handle);
      }
      for (const role of ['icon', 'party']) entries.push({ speciesId: form.speciesId, formId: form.formId, role, artifactHandle: handle });
    }
    if (!entries.length) continue;
    const id = `menu-sprites-${Date.now()}-${sequence++}`;
    const plan = await call('pokemap_plan', { projectHandle, request: {
      requestId: id, idempotencyKey: id, workspaceHandle, expectedRevision: revision,
      actionId: 'pokemon.media.import', actionVersion: 1, parameters: { entries }, dryRun: !apply,
    } });
    const proof = { preview: plan.plan.preview, revision: plan.snapshotRevision };
    if (apply && plan.plan.applicable) {
      const applied = await call('pokemap_apply', { operation: 'apply', projectHandle, planId: plan.planId, operationId: id });
      revision = applied.snapshotRevision;
      proof.receipt = applied.receipt;
    }
    receipt.batches.push(proof);
    receipt.finalRevision = revision;
    await writeFile(positional[3], `${JSON.stringify(receipt, null, 2)}\n`);
    console.log(JSON.stringify({ batch: sequence, added: proof.preview.added.length, preserved: proof.preview.preserved.length, applied: apply && plan.plan.applicable }));
  }
  receipt.validation = await call('pokemap_validate', { projectHandle });
  await writeFile(positional[3], `${JSON.stringify(receipt, null, 2)}\n`);
} catch (error) {
  console.error(error);
  process.exitCode = 1;
} finally {
  await Promise.allSettled([client.close(), server.close(), authoring.close()]);
}
