import assert from "node:assert/strict";
import { mkdtemp, realpath, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";

import {
  AveluneController,
  AveluneMcpError,
  type AveluneApi,
  type ControlState,
} from "../src/controller.js";

test("uploads an allowed package and requires a proven install transition", async () => {
  const root = await mkdtemp(join(tmpdir(), "avelune-mcp-root-"));
  const packagePath = join(root, "controlled.avelunegame");
  await writeFile(packagePath, "fixture");
  const states = [
    state(0, "idle"),
    state(1, "succeeded"),
  ];
  const uploaded: string[] = [];
  const controller = new AveluneController({
    api: fakeApi(states, (path) => uploaded.push(path)),
    allowedRoots: [root],
  });

  const result = await controller.install(packagePath, 5_000);

  assert.deepEqual(uploaded, [await realpath(packagePath)]);
  assert.equal(result.install.generation, 1);
  assert.equal(result.install.status, "succeeded");
});

test("rejects package paths outside configured roots", async () => {
  const root = await mkdtemp(join(tmpdir(), "avelune-mcp-root-"));
  const outside = join(await mkdtemp(join(tmpdir(), "avelune-outside-")), "x.avelunegame");
  await writeFile(outside, "fixture");
  const controller = new AveluneController({
    api: fakeApi([state(0, "idle")]),
    allowedRoots: [root],
  });

  await assert.rejects(
    () => controller.install(outside, 5_000),
    (error: unknown) =>
      error instanceof AveluneMcpError &&
      error.code === "package.pathOutsideAllowedRoots",
  );
});

test("waits for the Player surface without clicking widgets", async () => {
  let clock = 0;
  const controller = new AveluneController({
    api: fakeApi([
      state(0, "idle"),
      { ...state(0, "idle"), surface: "player", activeGameId: "game.controlled" },
    ]),
    allowedRoots: [tmpdir()],
    now: () => clock,
    sleep: async (milliseconds) => {
      clock += milliseconds;
    },
  });

  const result = await controller.waitFor(
    "playerOpened",
    "game.controlled",
    5_000,
  );
  assert.equal(result.surface, "player");
});

function fakeApi(
  states: ControlState[],
  onInstall: (path: string) => void = () => {},
): AveluneApi {
  let index = 0;
  return {
    describe: async () => ({
      name: "Avelune Control API",
      protocolVersion: 1,
      capabilities: ["state", "install", "launch", "returnToHub"],
    }),
    state: async () => states[Math.min(index++, states.length - 1)]!,
    install: async (path) => {
      onInstall(path);
      return states.at(-1)!;
    },
    launch: async () => states.at(-1)!,
    returnToHub: async () => states.at(-1)!,
  };
}

function state(
  generation: number,
  status: ControlState["install"]["status"],
): ControlState {
  return {
    protocolVersion: 1,
    dashboardStatus: "ready",
    surface: "hub",
    activeGameId: null,
    install: { generation, status, message: null },
    games: [],
  };
}
