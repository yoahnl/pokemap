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

function largeWav(): Buffer {
  const samples = 300_000;
  const bytes = Buffer.alloc(44 + samples);
  bytes.write('RIFF', 0);
  bytes.writeUInt32LE(bytes.length - 8, 4);
  bytes.write('WAVEfmt ', 8);
  bytes.writeUInt32LE(16, 16);
  bytes.writeUInt16LE(1, 20);
  bytes.writeUInt16LE(1, 22);
  bytes.writeUInt32LE(8000, 24);
  bytes.writeUInt32LE(8000, 28);
  bytes.writeUInt16LE(1, 32);
  bytes.writeUInt16LE(8, 34);
  bytes.write('data', 36);
  bytes.writeUInt32LE(samples, 40);
  return bytes;
}

async function runScenario(spl: boolean, withSound = false, explicitAudio = false, motion = false, splV4 = false, timed = false, splV5 = false, sourceProgram = false): Promise<void> {
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
    let particle = spl
      ? await readFile(resolve('../../packages/map_core/test/fixtures/spl_particle_v2.json'))
      : Buffer.from(JSON.stringify({ schemaVersion: 1, emitters: [{
      textureId: 'tex', emissionDurationMs: 10, emissionIntervalMs: 10,
      particleLifetimeMs: 10, particlesPerEmission: 1,
    }] }));
    if (splV4 || splV5) {
      const definition = JSON.parse(particle.toString());
      definition.schemaVersion = 4;
      definition.emitters[0].emission.positionVelocity = 914;
      definition.emitters[0].motion.magnet = { target: { x: 0, y: -19033, z: 0 }, force: 761 };
      definition.emitters[0].child = { velocityRatio: 10, randomVelocityMagnitude: 0, scaleRatio: 38,
        color: { red: 31, green: 21, blue: 31 }, rotation: 'angle', lifetime: 4, texture: 'tex',
        emissionCount: 1, emissionDelay: 0, emissionInterval: 1, fadeAlpha: true,
        scaleEnd: 0, inheritBehaviors: true, draw: 'directionalBillboard' };
      if (splV5) {
        definition.schemaVersion = 5;
        Object.assign(definition.emitters[0].emission, { emissionAxis: 'z', velocityVariance: 0 });
        Object.assign(definition.emitters[0].appearance, { hasRotation: true, minRotation: -64, maxRotation: 64, dirFromPosition: false });
      }
      particle = Buffer.from(JSON.stringify(definition));
    }
    const pngHash = createHash('sha256').update(png).digest('hex');
    const particleHash = createHash('sha256').update(particle).digest('hex');
    const sound = withSound ? largeWav() : null;
    const soundHash = sound ? createHash('sha256').update(sound).digest('hex') : null;
    const recipe = Buffer.from(JSON.stringify({
      schemaVersion: explicitAudio || sourceProgram ? 2 : 1, recipeId: 'visual', revision: '1', moveSourceId: 'source', variant: 'default',
      requiredCapabilities: [sourceProgram ? 'gen5SourceProgram' : 'startParticle', ...(spl ? [splV5 ? 'splParticleV5' : splV4 ? 'splParticleV4' : 'splParticleV2'] : []), ...(sound ? ['sequence', 'sound'] : []), ...(explicitAudio || sourceProgram ? ['audioSelectionV2'] : []), ...(motion ? ['gen5Swing', 'gen5SpritePause'] : []), ...(timed ? ['parallel', 'wait', 'waitEffects'] : [])], provenance: { source: 'synthetic', sourceRevision: '1', sourcePaths: [], converter: 'test' },
      resources: [
        { id: 'tex', role: 'texture', mediaType: 'image/png', sizeBytes: png.length, sha256: pngHash },
        { id: 'particle', role: 'particleDefinition', mediaType: 'application/vnd.avelune.particle+json',
          sizeBytes: particle.length, sha256: particleHash, definitionVersion: splV5 ? 5 : splV4 ? 4 : spl ? 2 : 1, dependencies: ['tex'] },
        ...(sound ? [{ id: 'sound', role: 'sound', mediaType: 'audio/wav', sizeBytes: sound.length, sha256: soundHash }] : []),
      ],
      ...(sourceProgram ? { audio: { kind: 'none' } } : explicitAudio ? { audio: { kind: 'clip', resourceId: 'sound' } } : {}),
      program: sourceProgram ? { kind: 'gen5SourceProgram', sourceProgram: {
        kind: 'gen5SourceProgram', timebaseHz: 60, conversion: 'supported', variant: 'default',
        variants: ['default'], labels: [{ name: 'default', instructionIndex: 0 }], entryIndex: 0,
        instructions: [{ op: 'startEmitter', args: { particle: 199, emitter: 0 }, source: {} },
          { op: 'end', args: {}, source: {} }],
      }, particleBindings: [{ particle: 199, resourceId: 'particle', sourceEmitterIndices: [0] }] }
      : timed ? { kind: 'sequence', steps: [
        { kind: 'parallel', steps: [
          { kind: 'startParticle', resourceId: 'particle', from: 'userMouth', to: 'targetImpact' },
          { kind: 'sequence', steps: [
            { kind: 'wait', durationMs: 1167 },
            { kind: 'startParticle', resourceId: 'particle', from: 'targetImpact', to: 'targetImpact' },
          ] },
        ] },
        { kind: 'waitEffects' },
      ] } : motion ? { kind: 'sequence', steps: [
        { kind: 'gen5SpritePause', target: 'target', paused: true },
        { kind: 'gen5Swing', target: 'user', channel: 'position', x: 4096, y: 0, frames: 4, wait: 1, count: 1 },
        { kind: 'gen5Swing', target: 'target', channel: 'scale', x: 1229, y: -1229, frames: 2, wait: 1, count: 1 },
        { kind: 'startParticle', resourceId: 'particle', from: 'userMouth', to: 'targetImpact' },
        { kind: 'gen5SpritePause', target: 'target', paused: false },
      ] } : sound && !explicitAudio ? { kind: 'sequence', steps: [
        { kind: 'sound', resourceId: 'sound' },
        { kind: 'startParticle', resourceId: 'particle', from: 'userMouth', to: 'targetImpact' },
      ] } : { kind: 'startParticle', resourceId: 'particle', from: 'userMouth', to: 'targetImpact' },
    }, null, 2));
    const hash = createHash('sha256').update(recipe).digest('hex');
    const source = join(root, 'recipe-input.json');
    const particleSource = join(root, 'particle-input.json');
    const pngSource = join(root, 'texture-input.png');
    const soundSource = join(root, 'sound-input.wav');
    await writeFile(source, recipe);
    await writeFile(particleSource, particle);
    await writeFile(pngSource, png);
    if (sound) await writeFile(soundSource, sound);
    await client.connect(transport);
    const description = await call('pokemap_describe', { domain: 'battle', view: 'compact' });
    const action = (description.mutationActions as JsonRecord[]).find(value => value.id === 'pokemon.move_recipe.import');
    assert.ok(action);
    assert.equal(action.inputSchemaAvailable, true);
    if (sound) {
      const detail = await call('pokemap_describe', { domain: 'battle', view: 'full', actionIds: ['pokemon.move_recipe.import'] });
      const detailedAction = (detail.mutationActions as JsonRecord[]).find(value => value.id === 'pokemon.move_recipe.import');
      assert.ok(detailedAction);
      const extensions = record(detailedAction.extensions);
      const properties = record(record(extensions.inputSchema).properties);
      const resources = record(record(properties.resources).items);
      const mediaType = record(record(resources.properties).mediaType);
      for (const type of ['audio/wav', 'audio/ogg', 'audio/mpeg']) assert.ok((mediaType.enum as string[]).includes(type));
      assert.equal(record(extensions.constraints).maxSoundBytes, 8 * 1024 * 1024);
    }
    const opened = await call('pokemap_workspace', { operation: 'open', projectRoot: root });
    const staged = await call('pokemap_artifact_stage', { sourcePath: source, declaredMediaType: 'application/json' });
    const stagedParticle = await call('pokemap_artifact_stage', { sourcePath: particleSource, declaredMediaType: 'application/json' });
    const stagedPng = await call('pokemap_artifact_stage', { sourcePath: pngSource, declaredMediaType: 'image/png' });
    const stagedSound = sound ? await call('pokemap_artifact_stage', { sourcePath: soundSource, declaredMediaType: 'audio/wav' }) : null;
    const parameters = {
      projectBinding: {
        kind: 'avelune.battle-recipe-binding', schemaVersion: 1, unsupportedBehavior: 'legacy',
        binding: { schemaVersion: 1, projectMoveId: 'custom', sourceMoveId: 'source', catalogReleaseId: 'test',
          recipeId: 'visual', variant: 'default', revision: '1', recipeSha256: hash },
      },
      recipeHandle: staged.artifactHandle, resources: [
        { id: 'tex', sha256: pngHash, mediaType: 'image/png', artifactHandle: stagedPng.artifactHandle },
        { id: 'particle', sha256: particleHash, mediaType: 'application/vnd.avelune.particle+json', artifactHandle: stagedParticle.artifactHandle },
        ...(stagedSound ? [{ id: 'sound', sha256: soundHash, mediaType: 'audio/wav', artifactHandle: stagedSound.artifactHandle }] : []),
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
    const soundPath = join(root, 'data/pokemon/battle_recipes/blobs', owner, `${soundHash}.wav`);
    if (sound) assert.deepEqual(await readFile(soundPath), sound);
    if (sourceProgram) {
      const detail = await call('pokemap_describe', { domain: 'battle', view: 'full', actionIds: ['pokemon.move_recipe.import'] });
      const action = (detail.mutationActions as JsonRecord[]).find(value => value.id === 'pokemon.move_recipe.import');
      const properties = record(record(record(action!.extensions).inputSchema).properties);
      assert.equal(record(properties.replaceExisting).type, 'boolean');
      const bindingPath = join(root, 'data/pokemon/battle_recipes/bindings', `${owner}.json`);
      const original = await readFile(bindingPath);
      const replacement = {
        ...parameters,
        projectBinding: { ...parameters.projectBinding, catalogMoveId: 'updated-catalog', recipeMediaId: 'updated-recipe' },
        replaceExisting: true,
      };
      const replacementScope = await call('pokemap_workshop', { operation: 'read', projectHandle: opened.projectHandle,
        actionId: 'pokemon.move_recipe.import', parameters: replacement });
      const replacementPlan = await call('pokemap_plan', { projectHandle: opened.projectHandle, request: {
        requestId: 'replace', actionId: 'pokemon.move_recipe.import', actionVersion: 1,
        workspaceHandle: opened.workspaceHandle, expectedRevision: replacementScope.snapshotRevision,
        idempotencyKey: 'replace', parameters: replacement,
      } });
      const replaced = await call('pokemap_apply', { operation: 'apply', projectHandle: opened.projectHandle,
        planId: replacementPlan.planId, operationId: 'replace' });
      assert.equal(JSON.parse(await readFile(bindingPath, 'utf8')).catalogMoveId, 'updated-catalog');
      await call('pokemap_history', { operation: 'undo', projectHandle: opened.projectHandle,
        entryId: record(replaced.receipt).receiptId, idempotencyKey: 'undo-replace' });
      assert.deepEqual(await readFile(bindingPath), original);
    }
    if (sound) await call('pokemap_workshop', { operation: 'read', projectHandle: opened.projectHandle,
      actionId: 'pokemon.move_recipe.import', parameters });
    await call('pokemap_history', { operation: 'undo', projectHandle: opened.projectHandle,
      entryId: record(applied.receipt).receiptId, idempotencyKey: 'undo' });
    await assert.rejects(readFile(path), { code: 'ENOENT' });
    await assert.rejects(readFile(particlePath), { code: 'ENOENT' });
    await assert.rejects(readFile(pngPath), { code: 'ENOENT' });
    if (sound) await assert.rejects(readFile(soundPath), { code: 'ENOENT' });
    await call('pokemap_history', { operation: 'redo', projectHandle: opened.projectHandle,
      entryId: record(applied.receipt).receiptId, idempotencyKey: 'redo' });
    assert.deepEqual(await readFile(path), recipe);
    assert.deepEqual(await readFile(particlePath), particle);
    assert.deepEqual(await readFile(pngPath), png);
    if (sound) assert.deepEqual(await readFile(soundPath), sound);
    await call('pokemap_workspace', { operation: 'close', workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
}

test('MCP stages, imports and undoes a version 1 move recipe', { timeout: 120_000 }, () => runScenario(false));
test('MCP stages, imports and undoes a version 2 SPL move recipe', { timeout: 120_000 }, () => runScenario(true));
test('MCP stages, imports and undoes a sound and SPL move recipe', { timeout: 120_000 }, () => runScenario(true, true));
test('MCP stages, imports and undoes an explicit audio v2 move recipe', { timeout: 120_000 }, () => runScenario(true, true, true));
test('MCP stages, imports and undoes a Gen 5 combatant motion recipe', { timeout: 120_000 }, () => runScenario(true, true, true, true));
test('MCP stages, imports and undoes a SPL v4 magnet recipe', { timeout: 120_000 }, () => runScenario(true, true, true, true, true));
test('MCP stages, imports and undoes a SPL v5 recipe', { timeout: 120_000 }, () => runScenario(true, true, true, false, false, false, true));
test('MCP stages, imports and undoes a delayed grouped particle recipe', { timeout: 120_000 }, () => runScenario(true, true, true, false, false, true));
test('MCP stages, imports and undoes a Gen 5 source program', { timeout: 120_000 }, () => runScenario(true, false, false, false, false, false, false, true));
