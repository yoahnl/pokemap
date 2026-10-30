import assert from "node:assert/strict";
import { chmod, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";

import { Client } from "@modelcontextprotocol/client";
import { InMemoryTransport } from "@modelcontextprotocol/server";

import { LocalAuthoringClient, type JsonRecord } from "../src/authoring_client.js";
import { MemoryArtifactReader } from "../src/artifacts.js";
import {
  createNativeRender3dExecutor,
  createNativeScan3dExecutor,
  createRenderHostBinaryResolver,
  NativeRenderHost,
} from "../src/native_render_host.js";
import { LocalRuntimeGateway } from "../src/runtime_gateway.js";
import { createPokeMapMcpServer } from "../src/server.js";
import { PokeMapToolError } from "../src/tool_error.js";

const repositoryRoot = resolve(process.cwd(), "../..");
const projectRoot = resolve(repositoryRoot, "examples/playable_runtime_host/golden_fangame_slice");
const png = Buffer.from(
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==",
  "base64",
);

const fakeHost = `#!/usr/bin/env node
const { appendFileSync, writeFileSync } = require("node:fs");
const { createInterface } = require("node:readline");
appendFileSync(process.env.FAKE_HOST_LOG, "start\\n");
createInterface({ input: process.stdin }).on("line", (line) => {
  const { id, command, args = {} } = JSON.parse(line);
  const reply = (body) => process.stdout.write(JSON.stringify({ id, command, ...body }) + "\\n");
  if (command === "shutdown") { reply({ status: "success", data: {} }); process.exit(0); }
  if (command === "scan") {
    const views = ["groundGap", "borderObjectOverlap"].map((kind, index) => {
      const outputPath = args.outputDirectory + "/" + kind + "-" + index + ".png";
      writeFileSync(outputPath, Buffer.from(process.env.FAKE_HOST_PNG, "base64"));
      return { kind, center: { x: 32.5, z: 72 }, holeRatio: index === 0 ? 0.02 : 0, backgroundRatio: 0.03, target: {}, outputPath };
    });
    views.push({ kind: "grid", center: { x: 24, z: 80 }, holeRatio: 0, backgroundRatio: 0 });
    return reply({ status: "success", data: { mapId: args.mapId, groundGapCount: 14, viewCount: 3, maxViews: args.maxViews, grid: args.grid, views } });
  }
  if (args.mapId === "crash") process.exit(3);
  if (args.mapId === "hang") return;
  if (args.mapId === "flat") return reply({ status: "failure", error: { code: "render.map_not_spatial", message: "No 3D scene." } });
  process.stdout.write("engine noise that is not JSON\\n");
  writeFileSync(args.outputPath, Buffer.from(process.env.FAKE_HOST_PNG, "base64"));
  reply({ status: "success", data: { mapId: args.mapId, revision: "sha256:fake", width: 1, height: 1, center: args.center ?? null, view: args.view, outputPath: args.outputPath } });
});
`;

async function fakeHostFixture() {
  const root = await mkdtemp(join(tmpdir(), "pokemap-fake-render-host-"));
  const binary = join(root, "host.cjs");
  const log = join(root, "starts.log");
  await writeFile(binary, fakeHost, "utf8");
  await writeFile(log, "", "utf8");
  await chmod(binary, 0o755);
  process.env.FAKE_HOST_LOG = log;
  process.env.FAKE_HOST_PNG = png.toString("base64");
  return {
    root,
    binary,
    starts: async () => (await readFile(log, "utf8")).split("\n").filter(Boolean).length,
    cleanup: () => rm(root, { recursive: true, force: true }),
  };
}

const request = {
  projectHandle: "unused",
  mapId: "route-32",
  magnification: 3,
  view: "game" as const,
  minuteOfDay: 720,
};

test("one persistent host serves successive renders and registers PNG artifacts", async () => {
  const fixture = await fakeHostFixture();
  const host = new NativeRenderHost({ resolveBinary: async () => fixture.binary });
  const artifacts = new MemoryArtifactReader();
  const render = createNativeRender3dExecutor({ artifacts, host });
  try {
    const first = await render("/games/jeu", { ...request, center: { x: 25, z: 64 } });
    const second = await render("/games/jeu", { ...request, view: "top" });
    assert.equal(await fixture.starts(), 1);
    assert.equal(first.data.mimeType, "image/png");
    assert.deepEqual(first.data.center, { x: 25, z: 64 });
    assert.equal(first.data.outputPath, undefined);
    assert.equal(second.data.view, "top");
    const uri = String(first.artifacts[0]?.uri);
    assert.match(uri, /^artifact:\/\/sha256\/[0-9a-f]{64}$/);
    assert.equal(first.artifacts[0]?.byteLength, png.byteLength);
    const read = await artifacts.read(uri);
    assert.ok(Buffer.from(String(read.blob), "base64").equals(png));
  } finally {
    await host.close();
    await fixture.cleanup();
  }
});

test("explicit close rejects an active request and concurrent closers await the same child",async()=>{
  const fixture=await fakeHostFixture();
  const host=new NativeRenderHost({resolveBinary:async()=>fixture.binary,requestTimeoutMs:60_000});
  const pending=host.request("render",{mapId:"hang"});
  const rejected=assert.rejects(pending,error=>error instanceof PokeMapToolError&&error.code==="render3d.host_exited");
  try {
    while(!host.running) await new Promise<void>(accept=>setImmediate(accept));
    await Promise.all([host.close(),host.close(),rejected]);
    assert.equal(host.running,false);
  } finally {await host.close();await fixture.cleanup();}
});

test("host failures, crashes and timeouts surface as tool errors and recover", async () => {
  const fixture = await fakeHostFixture();
  const host = new NativeRenderHost({ resolveBinary: async () => fixture.binary, requestTimeoutMs: 400 });
  const render = createNativeRender3dExecutor({ artifacts: new MemoryArtifactReader(), host });
  const code = async (mapId: string) => {
    try {
      await render("/games/jeu", { ...request, mapId });
      return "ok";
    } catch (error) {
      assert.ok(error instanceof PokeMapToolError);
      return error.code;
    }
  };
  try {
    assert.equal(await code("flat"), "render.map_not_spatial");
    assert.equal(await code("crash"), "render3d.host_exited");
    assert.equal(await code("route-32"), "ok");
    assert.equal(await code("hang"), "render3d.host_timeout");
    assert.equal(await code("route-32"), "ok");
    assert.equal(await fixture.starts(), 3);
  } finally {
    await host.close();
    await fixture.cleanup();
  }
});

test("closing the host stops its process and refuses later renders", async () => {
  const fixture = await fakeHostFixture();
  const host = new NativeRenderHost({ resolveBinary: async () => fixture.binary });
  try {
    await createNativeRender3dExecutor({ artifacts: new MemoryArtifactReader(), host })("/games/jeu", request);
    assert.equal(host.running, true);
    await host.close();
    assert.equal(host.running, false);
    await assert.rejects(host.request("render", {}), (error) =>
      error instanceof PokeMapToolError && error.code === "render3d.host_closed");
  } finally {
    await fixture.cleanup();
  }
});

test("a scan registers one PNG per view without leaking host paths", async () => {
  const fixture = await fakeHostFixture();
  const host = new NativeRenderHost({ resolveBinary: async () => fixture.binary });
  const artifacts = new MemoryArtifactReader();
  try {
    const scanned = await createNativeScan3dExecutor({ artifacts, host })("/games/jeu", {
      projectHandle: "unused",
      mapId: "route-32",
      maxViews: 5,
      magnification: 4,
      grid: true,
    });
    assert.equal(scanned.data.groundGapCount, 14);
    assert.equal(scanned.data.maxViews, 5);
    const views = scanned.data.views as JsonRecord[];
    assert.deepEqual(views.map((view) => view.kind), ["groundGap", "borderObjectOverlap", "grid"]);
    assert.equal(scanned.data.grid, true);
    assert.equal(views[2]?.artifactUri, undefined);
    assert.ok(views.every((view) => view.outputPath === undefined));
    assert.equal(scanned.artifacts.length, 2);
    assert.equal(views[0]?.artifactUri, scanned.artifacts[0]?.uri);
    const read = await artifacts.read(String(views[1]?.artifactUri));
    assert.ok(Buffer.from(String(read.blob), "base64").equals(png));
  } finally {
    await host.close();
    await fixture.cleanup();
  }
});

test("the host resolver refuses platforms without Metal", async () => {
  const resolveBinary = createRenderHostBinaryResolver({
    hostRoot: "/nowhere",
    repositoryRoot,
    flutterExecutable: "flutter",
    platform: "linux",
  });
  await assert.rejects(resolveBinary(), (error) =>
    error instanceof PokeMapToolError && error.code === "render3d.unsupported_platform");
});

test("pokemap_render_3d renders the opened project and returns a readable artifact", async () => {
  const fixture = await fakeHostFixture();
  const authoring = new LocalAuthoringClient({
    allowedRoots: [projectRoot],
    authoringPackageRoot: resolve(repositoryRoot, "packages/map_authoring"),
  });
  const artifacts = new MemoryArtifactReader();
  const host = new NativeRenderHost({ resolveBinary: async () => fixture.binary });
  const runtime = new LocalRuntimeGateway({
    roots: authoring,
    artifacts,
    runtimePackageRoot: resolve(repositoryRoot, "packages/map_runtime"),
    runtimeHostRoot: resolve(repositoryRoot, "examples/playable_runtime_host"),
    repositoryRoot,
    render3dExecutor: createNativeRender3dExecutor({ artifacts, host }),
    scan3dExecutor: createNativeScan3dExecutor({ artifacts, host }),
  });
  const server = createPokeMapMcpServer({ authoring, artifacts, runtime });
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
  const client = new Client({ name: "pokemap-render3d-test", version: "1.0.0" });
  await server.connect(serverTransport);
  await client.connect(clientTransport);
  const call = async (name: string, args: JsonRecord) => {
    const result = await client.callTool({ name, arguments: args });
    const envelope = result.structuredContent as { ok: boolean; data: JsonRecord; artifacts: JsonRecord[] };
    return { isError: result.isError, ...envelope };
  };
  try {
    const listed = (await client.listTools()).tools.find((tool) => tool.name === "pokemap_render_3d");
    assert.ok(listed?.description?.includes("Border"));
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    const rendered = await call("pokemap_render_3d", {
      projectHandle: opened.data.projectHandle,
      mapId: "golden_town",
      center: { x: 3, z: 2 },
    });
    assert.equal(rendered.ok, true, JSON.stringify(rendered));
    assert.equal(rendered.data.mapId, "golden_town");
    assert.equal(rendered.data.view, "game");
    const artifact = await call("pokemap_artifact", { uri: String(rendered.artifacts[0]?.uri) });
    assert.equal(artifact.data.mediaType, "image/png");
    const scan = await call("pokemap_render_3d_scan", {
      projectHandle: opened.data.projectHandle,
      mapId: "golden_town",
    });
    assert.equal(scan.ok, true, JSON.stringify(scan));
    assert.equal(scan.data.maxViews, 12);
    assert.equal(scan.artifacts.length, 2);
    const invalid = await call("pokemap_render_3d", {
      projectHandle: opened.data.projectHandle,
      mapId: "golden_town",
      magnification: 20,
    });
    assert.equal(invalid.isError, true);
  } finally {
    await client.close();
    await server.close();
    await runtime.close();
    await authoring.close();
    await host.close();
    await fixture.cleanup();
  }
});
