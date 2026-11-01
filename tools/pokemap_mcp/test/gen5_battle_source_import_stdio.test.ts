import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { execFile } from 'node:child_process';
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { promisify } from 'node:util';
import test from 'node:test';
import { Client } from '@modelcontextprotocol/client';
import { StdioClientTransport } from '@modelcontextprotocol/client/stdio';
import type { JsonRecord } from '../src/authoring_client.js';

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === 'object' && !Array.isArray(value));
  return value as JsonRecord;
}

test('MCP imports and undoes a verified Gen 5 source', { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), 'gen5-source-mcp-'));
  const packageRoot = resolve('../../packages/map_authoring');
  const dart = process.env.POKEMAP_TEST_DART ?? 'dart';
  const transport = new StdioClientTransport({
    command: process.execPath,
    args: [resolve('dist/src/index.js'), '--root', root, '--dart', dart,
      '--authoring-timeout-ms', '60000'],
    cwd: process.cwd(), stderr: 'pipe',
  });
  const client = new Client({ name: 'gen5-source-proof', version: '1.0.0' });
  async function call(name: string, args: JsonRecord = {}): Promise<JsonRecord> {
    const envelope = record((await client.callTool({ name, arguments: args })).structuredContent);
    assert.equal(envelope.ok, true, JSON.stringify(envelope));
    return record(envelope.data);
  }
  try {
    await promisify(execFile)(dart, [
      `--packages=${join(packageRoot, '.dart_tool/package_config.json')}`,
      join(packageRoot, 'test/support/create_working_catalog_fixture.dart'), root, '--companion',
    ], { timeout: 60_000 });
    const speciesPath = 'data/pokemon/species/bird.json';
    const species = Buffer.from(JSON.stringify({ schemaVersion: 1, id: 'bird', nationalDex: 25,
      forms: { formId: 'bronze' } }));
    await writeFile(join(root, speciesPath), species);
    const names = ['front.png', 'back.png', 'front_animations.nanr.lz11',
      'back_animations.nanr.lz11', 'front_cells.ncer', 'back_cells.ncer',
      'front_multi_cells.nmcr', 'back_multi_cells.nmcr', 'front_multi_animations.nmar',
      'back_multi_animations.nmar', 'front_info.bin', 'back_info.bin', 'normal.pal', 'shiny.pal'];
    const assets = Object.fromEntries(names.map((name, index) => {
      const bytes = Buffer.from([index + 1]);
      return [name, { encoding: 'base64', size: bytes.length,
        sha256: createHash('sha256').update(bytes).digest('hex'), data: bytes.toString('base64') }];
    }));
    const bundle = Buffer.from(JSON.stringify({
      kind: 'avelune.gen5-battle-source-bundle', schemaVersion: 1, game: 'black2-white2',
      scope: 'default-form', species: 'syntheticmon', nationalDex: 25,
      release: 'synthetic-release', reconstruction: 'a\u0300 verifier',
      source: { repository: 'fuddlesworth/pokebw2', revision: 'a'.repeat(40),
        directory: 'res/pokemon/syntheticmon', redistributionStatus: 'unverified' }, assets,
    }));
    const digest = createHash('sha256').update(bundle).digest('hex');
    const binding = { kind: 'avelune.gen5-battle-source-binding', schemaVersion: 1,
      projectSpeciesId: 'bird', species: 'syntheticmon', nationalDex: 25,
      release: 'synthetic-release', sourceRevision: 'a'.repeat(40), bundleSha256: digest };
    const input = join(root, 'source-input.json');
    await writeFile(input, bundle);
    await client.connect(transport);
    const description = await call('pokemap_describe', {
      domain: 'battle', view: 'full', actionIds: ['pokemon.gen5_battle_source.import'],
    });
    assert.ok((description.mutationActions as JsonRecord[])
      .some(action => action.id === 'pokemon.gen5_battle_source.import'));
    const opened = await call('pokemap_workspace', { operation: 'open', projectRoot: root });
    const staged = await call('pokemap_artifact_stage', {
      sourcePath: input, declaredMediaType: 'application/json',
    });
    const parameters = { binding, bundleHandle: staged.artifactHandle, speciesPath };
    const scoped = await call('pokemap_workshop', { operation: 'read', projectHandle: opened.projectHandle,
      actionId: 'pokemon.gen5_battle_source.import', parameters });
    const plan = await call('pokemap_plan', { projectHandle: opened.projectHandle, request: {
      requestId: 'gen5', actionId: 'pokemon.gen5_battle_source.import', actionVersion: 1,
      workspaceHandle: opened.workspaceHandle, expectedRevision: scoped.snapshotRevision,
      idempotencyKey: 'gen5', parameters,
    } });
    const applied = await call('pokemap_apply', { operation: 'apply', projectHandle: opened.projectHandle,
      planId: plan.planId, operationId: 'gen5' });
    const owner = createHash('sha256').update('bird').digest('hex');
    const bindingPath = join(root, 'data/pokemon/gen5_battle_sources/bindings', `${owner}.json`);
    const bundlePath = join(root, 'data/pokemon/gen5_battle_sources/blobs', owner, `${digest}.json`);
    assert.deepEqual(await readFile(bindingPath), Buffer.from(JSON.stringify(binding)));
    assert.deepEqual(await readFile(bundlePath), bundle);
    assert.deepEqual(await readFile(join(root, speciesPath)), species);
    await call('pokemap_history', { operation: 'undo', projectHandle: opened.projectHandle,
      entryId: record(applied.receipt).receiptId, idempotencyKey: 'undo' });
    await assert.rejects(readFile(bindingPath), { code: 'ENOENT' });
    await assert.rejects(readFile(bundlePath), { code: 'ENOENT' });
    await call('pokemap_history', { operation: 'redo', projectHandle: opened.projectHandle,
      entryId: record(applied.receipt).receiptId, idempotencyKey: 'redo' });
    assert.deepEqual(await readFile(bundlePath), bundle);
    await call('pokemap_workspace', { operation: 'close', workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});
