import assert from 'node:assert/strict';
import { execFile } from 'node:child_process';
import { mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
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

test('catalog map audio uses scoped workshop JSONL through live MCP without global preparation', { timeout: 120_000 }, async () => {
  const qa = process.env.AVELUNE_QA_ROOT ?? '/Users/karim/Library/Caches/AveluneQA/chapter7-audio';
  await mkdir(qa, { recursive: true });
  const root = await mkdtemp(join(qa, 'map-audio-mcp-'));
  const packageRoot = resolve('../../packages/map_authoring');
  const client = new Client({ name: 'catalog-map-audio', version: '1.0.0' });
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve('dist/src/index.js'), '--root', root, '--artifact-root', root, '--authoring-timeout-ms', '60000'],
    cwd: process.cwd(), stderr: 'pipe' });
  async function call(name: string, parameters: JsonRecord): Promise<JsonRecord> {
    const envelope = record((await client.callTool({ name, arguments: parameters })).structuredContent);
    assert.equal(envelope.ok, true, JSON.stringify(envelope));
    return record(envelope.data);
  }
  try {
    await promisify(execFile)('dart', [`--packages=${join(packageRoot, '.dart_tool/package_config.json')}`,
      join(packageRoot, 'test/support/create_map_audio_catalog_fixture.dart'), root], { timeout: 60_000 });
    const descriptor = await readFile(join(root, 'project.json'));
    const foreign = await readFile(join(root, 'maps/foreign.json'));
    await client.connect(transport);
    const described = await call('pokemap_describe', {});
    assert.ok((described.mutationActions as JsonRecord[]).some(row => row.id === 'map.audio.update'));
    let opened = await call('pokemap_workspace', { operation: 'open', projectRoot: root });
    let sequence = 0;
    async function mutate(actionId: string, parameters: JsonRecord): Promise<JsonRecord> {
      const scoped = await call('pokemap_workshop', { operation: 'read', projectHandle: opened.projectHandle, actionId, parameters });
      const operationId = `audio-${++sequence}`;
      const before = await readFile(join(root, 'maps/map.json'));
      const planned = await call('pokemap_plan', { projectHandle: opened.projectHandle, request: {
        requestId: operationId, actionId, actionVersion: 1, workspaceHandle: opened.workspaceHandle,
        expectedRevision: scoped.snapshotRevision, parameters, extensions: scoped.planExtensions, idempotencyKey: operationId,
      } });
      assert.deepEqual(await readFile(join(root, 'maps/map.json')), before);
      return call('pokemap_apply', { operation: 'apply', projectHandle: opened.projectHandle, planId: planned.planId, operationId });
    }
    const wav = Buffer.alloc(8044);
    wav.write('RIFF', 0); wav.writeUInt32LE(wav.length - 8, 4); wav.write('WAVEfmt ', 8);
    wav.writeUInt32LE(16, 16); wav.writeUInt16LE(1, 20); wav.writeUInt16LE(1, 22);
    wav.writeUInt32LE(8000, 24); wav.writeUInt32LE(8000, 28); wav.writeUInt16LE(1, 32); wav.writeUInt16LE(8, 34);
    wav.write('data', 36); wav.writeUInt32LE(8000, 40); wav.fill(128, 44);
    const sourcePath = join(root, 'source.wav');
    await writeFile(sourcePath, wav);
    const staged = await call('pokemap_artifact_stage', { sourcePath, declaredMediaType: 'audio/wav' });
    await mutate('scene.dialogue.audioMedia.import', { artifactHandle: staged.artifactHandle, assetId: 'music', mediaId: 'music',
      label: 'Music', logicalPath: 'assets/music.wav', mediaKind: 'music' });
    for (const volume of [.7, .4]) {
      const before = await readFile(join(root, 'maps/map.json'));
      const applied = await mutate('map.audio.update', { mapId: 'map', musicPath: 'assets/music.wav', musicVolume: volume });
      const after = record(JSON.parse(await readFile(join(root, 'maps/map.json'), 'utf8')));
      assert.equal(record(after.mapMetadata).musicVolume, volume);
      assert.equal(record(after.mapMetadata).musicPath, 'assets/music.wav');
      assert.deepEqual(after.properties, { preserved: 'map content' });
      await call('pokemap_history', { operation: 'undo', projectHandle: opened.projectHandle,
        entryId: record(applied.receipt).receiptId, idempotencyKey: `undo-${sequence}` });
      assert.deepEqual(await readFile(join(root, 'maps/map.json')), before);
      await mutate('map.audio.update', { mapId: 'map', musicPath: 'assets/music.wav', musicVolume: volume });
    }
    await call('pokemap_workspace', { operation: 'close', workspaceHandle: opened.workspaceHandle });
    opened = await call('pokemap_workspace', { operation: 'open', projectRoot: root });
    const final = await call('pokemap_workshop', { operation: 'read', projectHandle: opened.projectHandle,
      actionId: 'map.audio.update', parameters: { mapId: 'map', musicVolume: .4 } });
    const finalMap = (final.maps as JsonRecord[])[0];
    assert.ok(finalMap);
    assert.equal(record(finalMap.mapMetadata).musicVolume, .4);
    assert.deepEqual(await readFile(join(root, 'maps/foreign.json')), foreign);
    assert.deepEqual(await readFile(join(root, 'project.json')), descriptor);
    await call('pokemap_workspace', { operation: 'close', workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});
