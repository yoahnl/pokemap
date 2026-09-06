import { writeFile } from 'node:fs/promises';
import { setTimeout as delay } from 'node:timers/promises';

const [uri, destination, firstOpen = 'warm', count = '50'] = process.argv.slice(2);
if (!uri || !destination || !['cold', 'warm'].includes(firstOpen)) {
  throw new Error('Expected VM WebSocket URI, JSON destination, cold|warm, cycle count.');
}
const cycles = Number(count);
if (!Number.isInteger(cycles) || cycles < 1 || cycles > 100) {
  throw new Error('Cycle count must be between 1 and 100.');
}
const base = uri.replace(/^ws:/, 'http:').replace(/ws$/, '');
const vm = await (await fetch(`${base}getVM`, { signal: AbortSignal.timeout(15000) })).json();
const isolate = vm.result.isolates.find((entry) => entry.name === 'main');
if (!isolate) throw new Error('Main isolate unavailable.');
async function call(extension, args = {}) {
  const query = new URLSearchParams({ isolateId: isolate.id, ...args });
  const response = await fetch(`${base}ext.flutter.${extension}?${query}`, {
    signal: AbortSignal.timeout(15000),
  });
  const result = await response.json();
  if (result.error) throw new Error(JSON.stringify(result.error));
  return result.result;
}
const state = () => call('player.qaContext');
const metrics = (operation) => call('player.qaPerformance', { operation });
const key = (value) => call('marionette.pressKey', { key: value });
const elements = async () => (await call('marionette.interactiveElements')).elements;
const initial = await state();
if (!initial.loaded || initial.paused || initial.inputContext !== 'overworld') {
  throw new Error(`Expected active overworld: ${JSON.stringify(initial)}`);
}
const before = await metrics('stop');
if (before.mode !== 'profile') throw new Error('Profile build required.');
const results = [];
let after;
let finalState;
let failure = null;
const cleanupErrors = [];
try {
  for (let index = 0; index < cycles; index++) {
    await metrics('start');
    const start = performance.now();
    await key('m');
    let shellMs;
    let readyMs;
    let pokedexSummary;
    while (performance.now() - start < 15000) {
      const current = await elements();
      if (current.some((entry) => entry.key === 'pause-root-menu-title')) {
        shellMs ??= performance.now() - start;
        if (current.some((entry) => /Lecture impossible|Unable to load/.test(entry.text ?? ''))) {
          throw new Error(`Menu data failed at cycle ${index + 1}.`);
        }
        pokedexSummary = current.find((entry) => /^Pokédex\s*:\s*\d+\s*\/\s*\d+/.test(entry.text ?? ''))?.text;
        if (pokedexSummary && !current.some((entry) => entry.text?.includes('Chargement'))) {
          readyMs = performance.now() - start;
          break;
        }
      }
      await delay(10);
    }
    if (readyMs === undefined) throw new Error(`Menu not ready at cycle ${index + 1}.`);
    const paused = await state();
    if (!paused.paused) throw new Error('Menu did not pause the game.');
    await delay(180);
    await key('escape');
    const resumed = await state();
    if (resumed.paused || resumed.inputContext !== 'overworld') {
      throw new Error(`Game did not resume at cycle ${index + 1}.`);
    }
    if (JSON.stringify(resumed.position) !== JSON.stringify(initial.position)) {
      throw new Error('Player moved during menu cycling.');
    }
    await delay(180);
    const measured = await metrics('stop');
    results.push({ cycle: index + 1, shellMs, readyMs, pokedexSummary, ...measured });
    if ((index + 1) % 10 === 0) console.log(`Verified ${index + 1}/${cycles} cycles.`);
  }
} catch (error) {
  failure = String(error);
} finally {
  try {
    after = await metrics('stop');
  } catch (error) {
    cleanupErrors.push(`stop: ${String(error)}`);
  }
  try {
    finalState = await state();
  } catch (error) {
    cleanupErrors.push(`state: ${String(error)}`);
  }
}
if (cleanupErrors.length && !failure) failure = cleanupErrors.join('; ');
const receipt = {
  generatedAt: new Date().toISOString(), firstOpen,
  status: failure ? 'failed' : 'completed', error: failure, cleanupErrors,
  measurement: 'French Train fixture. VM keyboard dispatch to observed shell/data readiness including numeric Pokedex summary; 10 ms polling; includes service overhead. Frame samples are attributed by callback delivery time, which is batched by Flutter; they do not define exact per-cycle frame windows. The driver includes menu transitions and 180 ms resumed dwell. Cold means a manually verified process restart, not an automated cache reset.',
  initial, before, results, after: after ?? null, final: finalState ?? null,
};
await writeFile(destination, `${JSON.stringify(receipt, null, 2)}\n`);
if (failure) throw new Error(failure);
const percentile = (values, rank) => values.length
  ? [...values].sort((a, b) => a - b)[Math.ceil(values.length * rank) - 1]
  : null;
const frames = results.flatMap((entry) => entry.framesBuildRasterMicros);
console.log(JSON.stringify({
  destination, cycles, firstOpen, firstReadyMs: results[0].readyMs,
  warmReadyP95Ms: percentile(results.slice(firstOpen === 'cold' ? 1 : 0).map((entry) => entry.readyMs), .95),
  buildP95Ms: percentile(frames.map((entry) => entry[0] / 1000), .95),
  rasterP95Ms: percentile(frames.map((entry) => entry[1] / 1000), .95),
  rssBefore: before.rssBytes, rssAfter: after.rssBytes,
  cacheBefore: before.imageCacheBytes, cacheAfter: after.imageCacheBytes,
}));
