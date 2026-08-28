import assert from "node:assert/strict";
import { resolve } from "node:path";
import { test } from "node:test";

import { AveluneMcpConfigError, parseConfig } from "../src/config.js";

test("parses a session file and narrow package roots", () => {
  const config = parseConfig([
    "--session-file",
    "build/session.json",
    "--root",
    "fixtures",
    "--root",
    "../exports",
  ]);

  assert.equal(config.sessionFile, resolve("build/session.json"));
  assert.deepEqual(config.allowedRoots, [
    resolve("fixtures"),
    resolve("../exports"),
  ]);
});

test("requires both a session file and at least one root", () => {
  assert.throws(
    () => parseConfig(["--session-file", "session.json"]),
    (error: unknown) =>
      error instanceof AveluneMcpConfigError &&
      error.message.includes("--root"),
  );
  assert.throws(
    () => parseConfig(["--root", "fixtures"]),
    (error: unknown) =>
      error instanceof AveluneMcpConfigError &&
      error.message.includes("--session-file"),
  );
});
