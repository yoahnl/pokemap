import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { execFile } from 'node:child_process';
import { mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
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

test('MCP stages, imports and undoes an exact move recipe', { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), 'battle-recipe-mcp-'));
  const dart = process.env.POKEMAP_TEST_DART ?? 'dart';
  const packageRoot = resolve('../../packages/map_authoring');
  const client = new Client({ name: 'battle-recipe-proof', version: '1.0.0' });
  const transport = new StdioClientTransport({
    command: process.execPath,
    args: [resolve('dist/src/index.js'), '--root', root, '--dart', dart, '--authoring-timeout-ms', '60000'],
    cwd: process.cwd(), stderr: 'pipe',
  });
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
    const moves = join(root, 'data/pokemon/catalogs/moves.json');
    await mkdir(join(root, 'data/pokemon/catalogs'), { recursive: true });
    await writeFile(moves, JSON.stringify({ catalog: 'moves', entries: [{ id: 'custom' }] }));
    const png = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAASUlEQVR42mNkoAA4LEj4D2MfSFjASI4ZTAwDDEYdMOqAUQeMOmDUAaMOGHAHMCJXqaNRMCBRMNoiGnXAqANGHTDqgFEHjHgHAADb/Qp9KEMvVQAAAABJRU5ErkJggg==', 'base64');
    const particle = Buffer.from(JSON.stringify({ schemaVersion: 1, emitters: [{
      textureId: 'tex', emissionDurationMs: 10, emissionIntervalMs: 10,
      particleLifetimeMs: 10, particlesPerEmission: 1,
    }] }));
    const pngHash = createHash('sha256').update(png).digest('hex');
    const particleHash = createHash('sha256').update(particle).digest('hex');
    const recipe = Buffer.from(JSON.stringify({
      schemaVersion: 1, recipeId: 'visual', revision: '1', moveSourceId: 'source', variant: 'default',
      requiredCapabilities: ['startParticle'], provenance: { source: 'synthetic', sourceRevision: '1', sourcePaths: [], converter: 'test' },
      resources: [
        { id: 'tex', role: 'texture', mediaType: 'image/png', sizeBytes: png.length, sha256: pngHash },
        { id: 'particle', role: 'particleDefinition', mediaType: 'application/vnd.avelune.particle+json',
          sizeBytes: particle.length, sha256: particleHash, definitionVersion: 1, dependencies: ['tex'] },
      ],
      program: { kind: 'startParticle', resourceId: 'particle', from: 'userMouth', to: 'targetImpact' },
    }, null, 2));
    const hash = createHash('sha256').update(recipe).digest('hex');
    const source = join(root, 'recipe-input.json');
    const particleSource = join(root, 'particle-input.json');
    const pngSource = join(root, 'texture-input.png');
    await writeFile(source, recipe);
    await writeFile(particleSource, particle);
    await writeFile(pngSource, png);
    await client.connect(transport);
    const description = await call('pokemap_describe', { domain: 'battle', view: 'compact' });
    const action = (description.mutationActions as JsonRecord[]).find(value => value.id === 'pokemon.move_recipe.import');
    assert.ok(action);
    assert.equal(action.inputSchemaAvailable, true);
    const opened = await call('pokemap_workspace', { operation: 'open', projectRoot: root });
    const staged = await call('pokemap_artifact_stage', { sourcePath: source, declaredMediaType: 'application/json' });
    const stagedParticle = await call('pokemap_artifact_stage', { sourcePath: particleSource, declaredMediaType: 'application/json' });
    const stagedPng = await call('pokemap_artifact_stage', { sourcePath: pngSource, declaredMediaType: 'image/png' });
    const parameters = {
      projectBinding: {
        kind: 'avelune.battle-recipe-binding', schemaVersion: 1, unsupportedBehavior: 'legacy',
        binding: { schemaVersion: 1, projectMoveId: 'custom', sourceMoveId: 'source', catalogReleaseId: 'test',
          recipeId: 'visual', variant: 'default', revision: '1', recipeSha256: hash },
      },
      recipeHandle: staged.artifactHandle, resources: [
        { id: 'tex', sha256: pngHash, mediaType: 'image/png', artifactHandle: stagedPng.artifactHandle },
        { id: 'particle', sha256: particleHash, mediaType: 'application/vnd.avelune.particle+json', artifactHandle: stagedParticle.artifactHandle },
      ],
    };
    const scoped = await call('pokemap_workshop', { operation: 'read', projectHandle: opened.projectHandle,
      actionId: 'pokemon.move_recipe.import', parameters });
    const plan = await call('pokemap_plan', { projectHandle: opened.projectHandle, request: {
      requestId: 'recipe', actionId: 'pokemon.move_recipe.import', actionVersion: 1,
      workspaceHandle: opened.workspaceHandle, expectedRevision: scoped.snapshotRevision,
      idempotencyKey: 'recipe', parameters,
    } });
    const applied = await call('pokemap_apply', { operation: 'apply', projectHandle: opened.projectHandle,
      planId: plan.planId, operationId: 'recipe' });
    const owner = createHash('sha256').update('custom').digest('hex');
    const path = join(root, 'data/pokemon/battle_recipes/blobs', owner, `${hash}.json`);
    const particlePath = join(root, 'data/pokemon/battle_recipes/blobs', owner, `${particleHash}.json`);
    const pngPath = join(root, 'data/pokemon/battle_recipes/blobs', owner, `${pngHash}.png`);
    assert.deepEqual(await readFile(path), recipe);
    assert.deepEqual(await readFile(particlePath), particle);
    assert.deepEqual(await readFile(pngPath), png);
    await call('pokemap_history', { operation: 'undo', projectHandle: opened.projectHandle,
      entryId: record(applied.receipt).receiptId, idempotencyKey: 'undo' });
    await assert.rejects(readFile(path), { code: 'ENOENT' });
    await assert.rejects(readFile(particlePath), { code: 'ENOENT' });
    await assert.rejects(readFile(pngPath), { code: 'ENOENT' });
    await call('pokemap_history', { operation: 'redo', projectHandle: opened.projectHandle,
      entryId: record(applied.receipt).receiptId, idempotencyKey: 'redo' });
    assert.deepEqual(await readFile(path), recipe);
    assert.deepEqual(await readFile(particlePath), particle);
    assert.deepEqual(await readFile(pngPath), png);
    await call('pokemap_workspace', { operation: 'close', workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});
