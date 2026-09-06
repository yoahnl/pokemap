import assert from 'node:assert/strict';
import { execFile } from 'node:child_process';
import { mkdtemp, readFile, rm } from 'node:fs/promises';
import { createServer } from 'node:http';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { promisify } from 'node:util';
import test from 'node:test';

const execute = promisify(execFile);
const driver = fileURLToPath(new URL('./menu11_profile_check.mjs', import.meta.url));

async function runFixture({ failureCycle, cleanupFails = false, cycles = 2, firstOpen = 'warm' } = {}) {
  const directory = await mkdtemp(join(tmpdir(), 'menu11-driver-'));
  const destination = join(directory, 'receipt.json');
  let cycle = 0;
  let paused = false;
  let recording = false;
  let failed = false;
  let cleanupAttempted = false;
  const server = createServer((request, response) => {
    const url = new URL(request.url, 'http://127.0.0.1');
    const method = url.pathname.split('/').at(-1);
    let result;
    let error;
    switch (method) {
      case 'getVM':
        result = { isolates: [{ name: 'main', id: 'isolates/fixture' }] };
        break;
      case 'ext.flutter.player.qaContext':
        result = { loaded: true, paused, inputContext: 'overworld', position: { x: 16, y: 9 } };
        break;
      case 'ext.flutter.player.qaPerformance': {
        const operation = url.searchParams.get('operation');
        if (operation === 'start') recording = true;
        if (operation === 'stop') {
          if (failed) cleanupAttempted = true;
          if (failed && cleanupFails) error = { message: 'fixture cleanup failure' };
          else recording = false;
        }
        result = {
          mode: 'profile', revision: 'fixture', recording,
          framesBuildRasterMicros: [[1000, 2000]], rssBytes: 3000, imageCacheBytes: 4000,
        };
        break;
      }
      case 'ext.flutter.marionette.pressKey':
        paused = url.searchParams.get('key') === 'm';
        if (paused) cycle++;
        result = {};
        break;
      case 'ext.flutter.marionette.interactiveElements':
        if (cycle === failureCycle) {
          failed = true;
          error = { message: 'fixture menu failure' };
        } else {
          result = { elements: [
            { key: 'pause-root-menu-title' }, { text: 'Pokédex : 8 / 1101' },
          ] };
        }
        break;
      default:
        error = { message: 'unexpected method' };
    }
    response.setHeader('Content-Type', 'application/json');
    response.end(JSON.stringify(error ? { error } : { result }));
  });
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  try {
    const uri = `ws://127.0.0.1:${server.address().port}/fixture/ws`;
    let exitCode = 0;
    try {
      await execute(process.execPath, [driver, uri, destination, firstOpen, String(cycles)], { timeout: 10000 });
    } catch (error) {
      exitCode = error.code;
    }
    return { exitCode, receipt: JSON.parse(await readFile(destination, 'utf8')), recording, cleanupAttempted };
  } finally {
    await new Promise((resolve) => server.close(resolve));
    await rm(directory, { recursive: true, force: true });
  }
}

test('a failed cycle stops recording and preserves successful cycles', async () => {
  const result = await runFixture({ failureCycle: 2 });
  assert.equal(result.exitCode, 1);
  assert.equal(result.receipt.status, 'failed');
  assert.equal(result.receipt.results.length, 1);
  assert.match(result.receipt.error, /fixture menu failure/);
  assert.equal(result.cleanupAttempted, true);
  assert.equal(result.recording, false);
});

test('cleanup failure preserves the original failure in a partial receipt', async () => {
  const result = await runFixture({ failureCycle: 1, cleanupFails: true });
  assert.equal(result.exitCode, 1);
  assert.equal(result.receipt.status, 'failed');
  assert.match(result.receipt.error, /fixture menu failure/);
  assert.equal(result.receipt.results.length, 0);
  assert.match(result.receipt.cleanupErrors.join('\n'), /fixture cleanup failure/);
  assert.equal(result.cleanupAttempted, true);
});

test('successful cold-only run records completion without a warm sample', async () => {
  const result = await runFixture({ cycles: 1, firstOpen: 'cold' });
  assert.equal(result.exitCode, 0);
  assert.equal(result.receipt.status, 'completed');
  assert.equal(result.receipt.error, null);
  assert.equal(result.receipt.results.length, 1);
  assert.equal(result.recording, false);
});
