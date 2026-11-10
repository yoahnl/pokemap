import { createHash, randomUUID } from "node:crypto";
import { mkdir, mkdtemp, realpath, rm, writeFile } from "node:fs/promises";
import { join, relative, resolve } from "node:path";

import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";

type Json = Record<string, unknown>;
type Species = { id: string; nationalDex: number; formId: string };
type Candidate = { id: string; sha256: string; variant: "regular" | "shiny" };

function object(value: unknown): Json {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new Error("Expected an object.");
  }
  return value as Json;
}

function argumentsForRun(args: string[]) {
  const values: Record<string, string> = {};
  let apply = false;
  for (let index = 0; index < args.length; index++) {
    const key = args[index];
    if (!key) throw new Error('Invalid argument.');
    if (key === "--apply") {
      apply = true;
    } else if (["--project", "--qa-root", "--release", "--species"].includes(key)) {
      const value = args[++index];
      if (!value || values[key]) throw new Error(`Invalid argument: ${key}`);
      values[key] = value;
    } else {
      throw new Error(`Unknown argument: ${key}`);
    }
  }
  if (!values["--project"] || !values["--qa-root"] || !values["--release"]) {
    throw new Error("Required: --project, --qa-root and --release; add --apply to save.");
  }
  if (!/^[a-z0-9][a-z0-9-]{0,127}$/.test(values["--release"]) ||
      (values["--species"] && !/^[a-z0-9][a-z0-9-]{0,127}$/.test(values["--species"]))) {
    throw new Error("Invalid release or species identifier.");
  }
  return { project: values["--project"], qaRoot: values["--qa-root"],
    release: values["--release"], species: values["--species"], apply };
}

async function fetchBytes(url: string, limit: number): Promise<Buffer> {
  const response = await fetch(url, { signal: AbortSignal.timeout(30000) });
  if (!response.ok) throw new Error(`HTTP ${response.status} for ${url}`);
  const length = Number(response.headers.get("content-length") ?? 0);
  if (length > limit) throw new Error("Media exceeds its size limit.");
  const bytes = Buffer.from(await response.arrayBuffer());
  if (bytes.length > limit) throw new Error("Media exceeds its size limit.");
  return bytes;
}

async function candidates(release: string, species: Species): Promise<Candidate[]> {
  const base = `https://pokemon-api.yoahn.me/v1/media/${release}`;
  const selected: Candidate[] = [];
  let after = "";
  for (;;) {
    const query = new URLSearchParams({ limit: "100", ...(after ? { after } : {}) });
    const rows = JSON.parse((await fetchBytes(
      `${base}/owners/pokemon/${species.id}?${query}`, 8 * 1024 * 1024,
    )).toString("utf8")) as unknown;
    if (!Array.isArray(rows) || rows.length > 100) throw new Error("Invalid media page.");
    for (const item of rows) {
      const row = object(item);
      if (typeof row.id !== "string") throw new Error("Invalid media identity.");
      after = row.id;
      const metadata = object(row.metadata);
      if (row.usage !== "overworld" || row.style !== "hgss-inspired" ||
          row.representation !== "sprite2d" || row.contentType !== "image/png" ||
          metadata.nationalDex !== species.nationalDex ||
          (metadata.variant !== "regular" && metadata.variant !== "shiny")) continue;
      const atlas = object(metadata.atlas);
      if (atlas.rows !== 4 || atlas.columns !== 4 ||
          typeof row.sha256 !== "string" || !/^[a-f0-9]{64}$/.test(row.sha256) ||
          !/^[a-z0-9][a-z0-9-]{0,127}$/.test(row.id)) {
        throw new Error(`Invalid atlas for ${species.id}.`);
      }
      selected.push({ id: row.id, sha256: row.sha256, variant: metadata.variant });
    }
    if (rows.length < 100) break;
  }
  if (new Set(selected.map((item) => item.variant)).size !== selected.length) {
    throw new Error(`Ambiguous atlas for ${species.id}.`);
  }
  return selected;
}

async function main() {
  const options = argumentsForRun(process.argv.slice(2));
  const project = await realpath(options.project);
  const qaRoot = await realpath(options.qaRoot);
  const allowedQaRoot = await realpath("/Users/karim/Library/Caches/AveluneQA");
  const qaRelative = relative(allowedQaRoot, qaRoot);
  if (qaRelative.startsWith("..") || qaRelative === "") throw new Error("Invalid QA root.");
  await mkdir(qaRoot, { recursive: true });
  const temporary = await mkdtemp(join(qaRoot, "follower-import-"));
  const client = new Client({ name: "avelune-follower-import", version: "1.0.0" });
  const transport = new StdioClientTransport({
    command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", project, "--artifact-root", temporary,
      "--authoring-timeout-ms", "120000"],
    cwd: process.cwd(), stderr: "pipe",
  });
  let workspace: string | undefined;
  async function call(name: string, input: Json): Promise<Json> {
    const response = await client.callTool({ name, arguments: input }, { timeout: 130000 });
    const envelope = object(response.structuredContent);
    if (envelope.ok !== true) throw new Error(`${name}: ${JSON.stringify(envelope.error)}`);
    return object(envelope.data);
  }
  try {
    await client.connect(transport);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: project });
    const projectHandle = String(opened.projectHandle);
    workspace = String(opened.workspaceHandle);
    const species: Species[] = [];
    let cursor: string | undefined;
    do {
      const page = await call("pokemap_query", { projectHandle, operation: "list",
        resourceKind: "pokemonDocument", filters: { documentKind: "species" },
        view: "detail", pageSize: 100, ...(cursor ? { cursor } : {}) });
      for (const item of page.items as unknown[]) {
        const document = object(object(item).document);
        const forms = object(document.forms);
        if (typeof document.id !== "string" || !/^[a-z0-9][a-z0-9-]{0,127}$/.test(document.id) ||
            typeof document.nationalDex !== "number" || document.nationalDex < 1 ||
            document.nationalDex > 493 || forms.isBaseForm === false ||
            (options.species && options.species !== document.id)) continue;
        species.push({ id: document.id, nationalDex: document.nationalDex,
          formId: typeof forms.formId === "string" && forms.formId ? forms.formId : "base" });
      }
      cursor = typeof page.nextCursor === "string" ? page.nextCursor : undefined;
    } while (cursor);
    console.log(JSON.stringify({ stage: "inventory", species: species.length }));
    const entries: Json[] = [];
    const failures: string[] = [];
    for (let offset = 0; offset < species.length; offset += 6) {
      await Promise.all(species.slice(offset, offset + 6).map(async (entry) => {
        try {
          const atlases = await candidates(options.release, entry);
          if (!atlases.length) throw new Error("No matching atlas.");
          for (const atlas of atlases) {
            const bytes = await fetchBytes(
              `https://pokemon-api.yoahn.me/v1/media/${options.release}/${atlas.id}`,
              8 * 1024 * 1024,
            );
            if (createHash("sha256").update(bytes).digest("hex") !== atlas.sha256) {
              throw new Error("Media fingerprint differs.");
            }
            const path = join(temporary, `${entry.id}-${atlas.variant}.png`);
            await writeFile(path, bytes);
            const staged = await call("pokemap_artifact_stage", { sourcePath: path, declaredMediaType: "image/png" });
            entries.push({ speciesId: entry.id, formId: entry.formId,
              role: atlas.variant === "regular" ? "overworld" : "overworldShiny",
              artifactHandle: staged.artifactHandle });
          }
        } catch (error) {
          failures.push(`${entry.id}: ${String(error)}`);
        }
      }));
      console.log(JSON.stringify({ stage: "download", processed: Math.min(offset + 6, species.length),
        total: species.length, atlases: entries.length, failures: failures.length }));
    }
    if (entries.length === 0) throw new Error(`No importable atlases. ${failures.join("; ")}`);
    const validation = await call("pokemap_validate", { projectHandle });
    const operationId = `followers-${randomUUID()}`;
    const planned = await call("pokemap_plan", { projectHandle, request: {
      requestId: operationId, actionId: "pokemon.media.import", actionVersion: 1,
      workspaceHandle: workspace, expectedRevision: validation.snapshotRevision,
      idempotencyKey: operationId, parameters: { entries },
    } });
    const preview = object(object(planned.plan).preview);
    console.log(JSON.stringify({ stage: "preview", atlases: entries.length,
      added: (preview.added as unknown[]).length,
      preserved: (preview.preserved as unknown[]).length,
      conflicts: (preview.conflicts as unknown[]).length, failures }));
    if (options.apply && planned.applicable !== false) {
      const applied = await call("pokemap_apply", { operation: "apply", projectHandle,
        planId: planned.planId, operationId });
      console.log(JSON.stringify({ stage: "applied", receipt: object(applied.receipt).receiptId }));
    }
  } finally {
    if (workspace) {
      try { await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace }); } catch { }
    }
    await client.close();
    await transport.close();
    await rm(temporary, { recursive: true, force: true });
  }
}

main().catch((error: unknown) => {
  console.error(error);
  process.exitCode = 1;
});
