import { spawn } from "node:child_process";
import { createHash } from "node:crypto";
import {
  cp,
  mkdir,
  readFile,
  readdir,
  realpath,
  rm,
  stat,
  writeFile,
} from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const repository = resolve(dirname(fileURLToPath(import.meta.url)), "../../..");
const args = new Map();
for (let index = 2; index < process.argv.length; index += 2) {
  if (
    !["--work-root", "--output"].includes(process.argv[index]) ||
    !process.argv[index + 1] ||
    args.has(process.argv[index])
  )
    throw Error("Invalid runtime build arguments.");
  args.set(process.argv[index], resolve(process.argv[index + 1]));
}
if (args.size !== 2) throw Error("--work-root and --output are required.");
const work = args.get("--work-root"),
  output = args.get("--output");
await mkdir(work, { recursive: true });
const source = join(work, "runtime-source");
try {
  await stat(source);
  throw Error("The runtime build source destination must not exist.");
} catch (error) {
  if (error.code !== "ENOENT") throw error;
}
const run = async (
  command,
  argumentsList,
  cwd = repository,
  environment = {},
) =>
  new Promise((accept, reject) => {
    const child = spawn(command, argumentsList, {
      cwd,
      env: { ...process.env, ...environment },
      shell: false,
      stdio: ["ignore", "pipe", "pipe"],
    });
    const chunks = [];
    child.stdout.on("data", (chunk) => {
      chunks.push(chunk);
      process.stderr.write(chunk);
    });
    child.stderr.on("data", (chunk) => process.stderr.write(chunk));
    child.once("error", reject);
    child.once("close", (code) =>
      code === 0
        ? accept(Buffer.concat(chunks).toString().trim())
        : reject(Error(`Runtime build command failed (${code}): ${command}`)),
    );
  });
const digestTree = async (root) => {
  const entries = [];
  const visit = async (directory, prefix) => {
    for (const entry of await readdir(directory, { withFileTypes: true })) {
      const relative = prefix ? `${prefix}/${entry.name}` : entry.name;
      if (entry.isDirectory())
        await visit(join(directory, entry.name), relative);
      else if (entry.isFile())
        entries.push([
          relative,
          createHash("sha256")
            .update(await readFile(join(directory, entry.name)))
            .digest("hex"),
        ]);
    }
  };
  await visit(root, "");
  entries.sort((a, b) => (a[0] < b[0] ? -1 : a[0] > b[0] ? 1 : 0));
  return createHash("sha256")
    .update(entries.map(([path, hash]) => `${path}\0${hash}`).join("\0"))
    .digest("hex");
};
try {
  await mkdir(source);
  const host = join(repository, "tools/pokemap_render_host");
  await cp(join(host, "lib"), join(source, "lib"), { recursive: true });
  if (process.platform === "darwin")
    await cp(join(host, "macos"), join(source, "macos"), {
      recursive: true,
      filter: (path) =>
        !path
          .split(/[\\/]/)
          .some((part) => ["Pods", "ephemeral", "xcuserdata"].includes(part)),
    });
  let pubspec = await readFile(join(host, "pubspec.yaml"), "utf8");
  pubspec = pubspec.replace(
    /^(\s+path:\s*)(\.\.[^\r\n]*)/gm,
    (_, prefix, path) =>
      `${prefix}${JSON.stringify(resolve(host, path.trim()))}`,
  );
  await writeFile(join(source, "pubspec.yaml"), pubspec);
  try {
    await cp(join(host, "pubspec.lock"), join(source, "pubspec.lock"));
  } catch (error) {
    if (error.code !== "ENOENT") throw error;
  }
  await cp(
    join(host, "analysis_options.yaml"),
    join(source, "analysis_options.yaml"),
  );
  const windowsFlutter =
    process.platform === "win32"
      ? (await run("where.exe", ["flutter.bat"])).split(/\r?\n/)[0]
      : undefined;
  const windowsSdk = windowsFlutter
    ? dirname(dirname(await realpath(windowsFlutter)))
    : undefined;
  const runFlutter = (argumentsList) =>
    windowsSdk
      ? run(
          join(windowsSdk, "bin/cache/dart-sdk/bin/dart.exe"),
          [
            join(windowsSdk, "bin/cache/flutter_tools.snapshot"),
            ...argumentsList,
          ],
          source,
          { FLUTTER_ROOT: windowsSdk },
        )
      : run("flutter", argumentsList, source);
  if (process.platform !== "darwin")
    await runFlutter([
      "create",
      "--platforms",
      process.platform === "win32" ? "windows" : "linux",
      "--project-name",
      "pokemap_render_host",
      "--no-pub",
      ".",
    ]);
  if (process.platform !== "darwin") {
    const cmake = join(
      source,
      process.platform === "win32" ? "windows" : "linux",
      "CMakeLists.txt",
    );
    const directory = join(
      repository,
      "tools/pokemap_mcp/native/parent_watchdog",
    ).replaceAll("\\", "/");
    await writeFile(
      cmake,
      (await readFile(cmake, "utf8")) +
        `\nadd_subdirectory(${JSON.stringify(directory)} parent_watchdog)\n`,
    );
  }
  await runFlutter(["pub", "get"]);
  const commit = (await run("git", ["rev-parse", "HEAD"])).trim();
  const digest = await digestTree(
    join(repository, "examples/playable_runtime_host/lib/src/evaluation"),
  );
  const platform =
    process.platform === "darwin"
      ? "macos"
      : process.platform === "win32"
        ? "windows"
        : "linux";
  await runFlutter([
    "build",
    platform,
    "--release",
    "--dart-define=AVELUNE_RUNTIME_COMPANION=true",
    `--dart-define=AVELUNE_BUILD_COMMIT=${commit}`,
    `--dart-define=AVELUNE_EVALUATION_CODE_DIGEST=${digest}`,
  ]);
  const runtime =
    process.platform === "darwin"
      ? join(
          source,
          "build/macos/Build/Products/Release/pokemap_render_host.app",
        )
      : process.platform === "win32"
        ? join(source, "build/windows/x64/runner/Release")
        : join(source, "build/linux/x64/release/bundle");
  if (process.platform !== "darwin") {
    const name =
      process.platform === "win32"
        ? "avelune_parent_watchdog.dll"
        : "libavelune_parent_watchdog.so";
    const found = [];
    const visit = async (path) => {
      for (const entry of await readdir(path, { withFileTypes: true })) {
        const next = join(path, entry.name);
        if (entry.isDirectory()) await visit(next);
        else if (entry.isFile() && entry.name === name) found.push(next);
      }
    };
    await visit(join(source, "build", platform));
    if (found.length !== 1)
      throw Error("The owned parent watchdog build is missing or ambiguous.");
    await mkdir(join(runtime, "data"), { recursive: true });
    await cp(found[0], join(runtime, "data", name));
  }
  if (process.platform === "darwin") {
    const flutterBin = await run("which", ["flutter"]);
    const flutterRoot = dirname(dirname(await realpath(flutterBin)));
    await run(
      "python3",
      [join(repository, "tools/scripts/ensure_studio_qa_engine.py")],
      repository,
      {
        AVELUNE_QA_BUILD: "1",
        CONFIGURATION: "Release",
        FLUTTER_BUILD_MODE: "release",
        FLUTTER_ROOT: flutterRoot,
        TARGET_BUILD_DIR: dirname(runtime),
        FULL_PRODUCT_NAME: "pokemap_render_host.app",
        TARGET_TEMP_DIR: join(work, "engine"),
        PRODUCT_BUNDLE_IDENTIFIER: "dev.avelune.pokemapRenderHost",
      },
    );
  }
  const retainedRuntime = join(work, "runtime-built");
  try {
    await stat(retainedRuntime);
    throw Error(
      "The retained runtime destination already exists; reuse it with package_runtime.mjs or remove its owned build first.",
    );
  } catch (error) {
    if (error.code !== "ENOENT") throw error;
  }
  await cp(runtime, retainedRuntime, {
    recursive: true,
    verbatimSymlinks: true,
  });
  const flutterExecutable = windowsFlutter ?? (await run("which", ["flutter"]));
  const flutterSdk =
    windowsSdk ?? dirname(dirname(await realpath(flutterExecutable)));
  await run(process.execPath, [
    join(repository, "tools/pokemap_mcp/tool/package_runtime.mjs"),
    "--output",
    output,
    "--runtime-bundle",
    retainedRuntime,
    "--commit",
    commit,
    "--flutter-root",
    flutterSdk,
    ...(windowsSdk
      ? ["--dart", join(windowsSdk, "bin/cache/dart-sdk/bin/dart.exe")]
      : []),
  ]);
} finally {
  await rm(source, { recursive: true, force: true });
}
