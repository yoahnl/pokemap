import { lstat, readFile, readdir, realpath, rm } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import type { JsonRecord } from "../../src/authoring_client.js";

export async function fixtureAdmissionCleanup(
  projectRoot: string,
): Promise<() => Promise<number>> {
  const canonicalRoot = await realpath(projectRoot);
  const directory = join(homedir(), ".avelune/authoring/catalog-admissions");
  const listFiles = () => readdir(directory).catch((error: NodeJS.ErrnoException) => {
    if (error.code === "ENOENT") return [];
    throw error;
  });
  const filesBefore = new Set(await listFiles());

  return async () => {
    let removed = 0;
    for (const name of await listFiles()) {
      if (filesBefore.has(name) || !/^[a-f0-9]{64}\.json$/.test(name)) continue;
      const path = join(directory, name);
      const stat = await lstat(path).catch(() => undefined);
      if (!stat?.isFile() || stat.size > 8192) continue;
      const bytes = await readFile(path, "utf8").catch(() => undefined);
      if (bytes === undefined) continue;
      let value: JsonRecord;
      try {
        value = JSON.parse(bytes) as JsonRecord;
      } catch {
        continue;
      }
      if (!value || typeof value !== "object" || Array.isArray(value)) continue;
      if (
        value.projectRoot === canonicalRoot ||
        (value.admission as JsonRecord | undefined)?.projectRoot === canonicalRoot
      ) {
        await rm(path);
        removed++;
      }
    }
    return removed;
  };
}
