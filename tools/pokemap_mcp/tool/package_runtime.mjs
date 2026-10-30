import { build } from "esbuild";
import { createHash } from "node:crypto";
import { spawn } from "node:child_process";
import {
  chmod,
  cp,
  mkdir,
  mkdtemp,
  readFile,
  readdir,
  rename,
  rm,
  stat,
  writeFile,
} from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const repository = resolve(dirname(fileURLToPath(import.meta.url)), "../../..");
const argumentsMap = new Map();
for (let i = 2; i < process.argv.length; i += 2) {
  const key = process.argv[i],
    value = process.argv[i + 1];
  if (
    ![
      "--output",
      "--runtime-bundle",
      "--authoring-executable",
      "--node-archive",
      "--version",
      "--commit",
      "--dart",
      "--flutter-root",
    ].includes(key) ||
    !value ||
    argumentsMap.has(key)
  )
    throw Error("Invalid runtime assembly arguments.");
  argumentsMap.set(key, value);
}
if (!argumentsMap.has("--output") || !argumentsMap.has("--runtime-bundle"))
  throw Error("--output and --runtime-bundle are required.");
const output = resolve(argumentsMap.get("--output"));
try {
  await stat(output);
  throw Error("The runtime assembly destination must not exist.");
} catch (error) {
  if (error.code !== "ENOENT") throw error;
}
const nodeVersion = "v24.22.2";
const archives = {
  "darwin-arm64": [
    "tar.gz",
    "aa9549349e47dffaa42dcf95d6e06ade8c4bdafc980979883b88767670df385a",
  ],
  "darwin-x64": [
    "tar.gz",
    "d5e336d588c45be0c37dbd52cc29895593009ca4997a77a1fd02815131ed0e52",
  ],
  "linux-x64": [
    "tar.xz",
    "48cc0e21e048790e54c0cf5749c2725005313d652651c40b7a21feb9697aaf75",
  ],
  "win32-x64": [
    "zip",
    "ca1bff5d8ead13c9f2ea404a176db46bd430704d5b5113734049fa365e7799e2",
  ],
};
const archive = archives[`${process.platform}-${process.arch}`];
if (!archive)
  throw Error(
    "No pinned Node distribution supports this platform and architecture.",
  );
const platform = process.platform === "win32" ? "win" : process.platform;
const archiveName = `node-${nodeVersion}-${platform}-${process.arch}.${archive[0]}`;
await mkdir(dirname(output), { recursive: true });
const staging = await mkdtemp(join(dirname(output), ".mcp-staging-"));
const run = async (command, args, cwd = repository) =>
  new Promise((accept, reject) => {
    const child = spawn(command, args, {
      cwd,
      stdio: ["ignore", "pipe", "pipe"],
      shell: false,
    });
    const chunks = [];
    child.stdout.on("data", (chunk) => chunks.push(chunk));
    child.stderr.on("data", (chunk) => process.stderr.write(chunk));
    child.once("error", reject);
    child.once("close", (code) =>
      code === 0
        ? accept(Buffer.concat(chunks).toString().trim())
        : reject(
            Error(`Runtime assembly command failed (${code}): ${command}`),
          ),
    );
  });
try {
  const commit =
    argumentsMap.get("--commit") ?? (await run("git", ["rev-parse", "HEAD"]));
  if (!/^[a-f0-9]{40}$/.test(commit)) throw Error("Invalid build commit.");
  const version =
    argumentsMap.get("--version") ??
    (
      await readFile(
        join(repository, "apps/avelune_studio/pubspec.yaml"),
        "utf8",
      )
    ).match(/^version:\s*(\S+)/m)?.[1];
  if (!version) throw Error("Studio version is unavailable.");
  const download = argumentsMap.get("--node-archive")
    ? await readFile(resolve(argumentsMap.get("--node-archive")))
    : Buffer.from(
        await (
          await fetch(
            `https://nodejs.org/dist/${nodeVersion}/${archiveName}`,
          ).then((response) => {
            if (!response.ok)
              throw Error("Unable to fetch the pinned Node distribution.");
            return response;
          })
        ).arrayBuffer(),
      );
  if (createHash("sha256").update(download).digest("hex") !== archive[1])
    throw Error("The pinned Node archive failed integrity verification.");
  const archivePath = join(staging, archiveName);
  await writeFile(archivePath, download);
  if (process.platform === "win32")
    await run("tar", ["-xf", archivePath, "-C", staging]);
  else await run("tar", ["-xf", archivePath, "-C", staging]);
  const extracted = join(
    staging,
    `node-${nodeVersion}-${platform}-${process.arch}`,
  );
  await mkdir(join(staging, "bundle", "bin"), { recursive: true });
  const bundle = join(staging, "bundle");
  const nodeName =
    process.platform === "darwin"
      ? `node-${process.arch}`
      : process.platform === "win32"
        ? "node.exe"
        : "node";
  const authoringName =
    process.platform === "darwin"
      ? `authoring-${process.arch}`
      : process.platform === "win32"
        ? "authoring.exe"
        : "authoring";
  const flutterRoot = argumentsMap.has("--flutter-root")
    ? resolve(argumentsMap.get("--flutter-root"))
    : undefined;
  const sdkRoot = flutterRoot
    ? join(flutterRoot, "bin/cache/dart-sdk")
    : undefined;
  if (!sdkRoot) throw Error("--flutter-root is required to include the Dart SDK licence.");
  const dart =
    argumentsMap.get("--dart") ??
    (sdkRoot
      ? join(
          sdkRoot,
          process.platform === "win32" ? "bin/dart.exe" : "bin/dart",
        )
      : "dart");
  await cp(
    join(extracted, process.platform === "win32" ? "node.exe" : "bin/node"),
    join(bundle, "bin", nodeName),
  );
  await mkdir(join(bundle, "licenses"));
  await cp(join(extracted, "LICENSE"), join(bundle, "licenses", "node.txt"));
  await cp(join(sdkRoot, "LICENSE"), join(bundle, "licenses", "dart.txt"));
  const bundled = await build({
    entryPoints: [join(repository, "tools/pokemap_mcp/src/index.ts")],
    outfile: join(bundle, "server.mjs"),
    bundle: true,
    metafile: true,
    platform: "node",
    format: "esm",
    target: "node24",
    banner: {
      js: 'import {createRequire as __createRequire} from "node:module";const require=__createRequire(import.meta.url);',
    },
  });
  const authoring = join(bundle, "bin", authoringName);
  const authoringPackage = join(repository, "packages/map_authoring");
  const kernel = join(staging, "authoring.dill");
  if (process.platform === "darwin") {
    if (!sdkRoot || argumentsMap.has("--authoring-executable"))
      throw Error(
        "Universal macOS workers require --flutter-root and the shared AOT snapshot build.",
      );
    if (!(await run(dart, ["--version"])).includes("Dart SDK version: 3.13.4"))
      throw Error("The macOS AOT runtime pins require Dart 3.13.4.");
    await run(dart, ["pub", "get"], authoringPackage);
    const catalog = await readFile(
      join(authoringPackage, "assets/project_templates.v1.json"),
    );
    await run(
      join(sdkRoot, "bin/dartaotruntime"),
      [
        join(sdkRoot, "bin/snapshots/gen_kernel_aot.dart.snapshot"),
        `--platform=${join(sdkRoot, "lib/_internal/vm_platform_product.dill")}`,
        "--packages=.dart_tool/package_config.json",
        "--aot",
        "--tfa",
        "--target=vm",
        "--target-os=macos",
        "--no-embed-sources",
        "-Ddart.vm.product=true",
        `-DPOKEMAP_AUTHORING_TEMPLATE_CATALOG_BASE64=${catalog.toString("base64")}`,
        "-o",
        kernel,
        "bin/pokemap_authoring.dart",
      ],
      authoringPackage,
    );
    await run(
      join(
        flutterRoot,
        `bin/cache/artifacts/engine/darwin-x64-release/gen_snapshot_${process.arch}`,
      ),
      [
        "--snapshot_kind=app-aot-elf",
        `--elf=${join(bundle, `bin/authoring-${process.arch}.aot`)}`,
        kernel,
      ],
    );
    await cp(join(sdkRoot, "bin/dartaotruntime"), authoring);
  } else if (argumentsMap.has("--authoring-executable"))
    await cp(resolve(argumentsMap.get("--authoring-executable")), authoring);
  else {
    const catalog = await readFile(
      join(
        repository,
        "packages/map_authoring/assets/project_templates.v1.json",
      ),
    );
    await run(
      dart,
      [
        "compile",
        "exe",
        `-DPOKEMAP_AUTHORING_TEMPLATE_CATALOG_BASE64=${catalog.toString("base64")}`,
        "bin/pokemap_authoring.dart",
        "-o",
        authoring,
      ],
      join(repository, "packages/map_authoring"),
    );
  }
  const runtimeSource = resolve(argumentsMap.get("--runtime-bundle"));
  await cp(
    runtimeSource,
    join(bundle, process.platform === "darwin" ? "runtime.app" : "runtime"),
    { recursive: true, verbatimSymlinks: true },
  );
  await writeFile(
    join(bundle, "licenses", "avelune.txt"),
    `Avelune Studio ${version}\nSource commit: ${commit}\nPrivate project (publish_to: none). No public source licence is declared in the repository.\nThird-party notices are supplied separately.\n`,
  );
  const packageRoots = new Set();
  for (const input of Object.keys(bundled.metafile.inputs)) {
    if (!input.includes("node_modules/")) continue;
    let parent = dirname(resolve(input));
    while (parent !== dirname(parent)) {
      try {
        const metadata = JSON.parse(
          await readFile(join(parent, "package.json"), "utf8"),
        );
        if (typeof metadata.name === "string") {
          packageRoots.add(parent);
          break;
        }
      } catch {}
      parent = dirname(parent);
    }
  }
  const serverLicenses = ["licenses/avelune.txt"];
  for (const root of packageRoots) {
    const metadata = JSON.parse(
      await readFile(join(root, "package.json"), "utf8"),
    );
    const license = (await readdir(root)).find((name) =>
      /^licen[sc]e(?:\.|$)/i.test(name),
    );
    if (!license)
      throw Error(`A bundled dependency has no licence file: ${metadata.name}`);
    const target = `licenses/${metadata.name.replaceAll("/", "_").replaceAll("@", "")}.txt`;
    await cp(join(root, license), join(bundle, target));
    serverLicenses.push(target);
  }
  const components = [];
  const record = async (path, id, kind, capabilities, licenses) => {
    const bytes = await readFile(join(bundle, path));
    components.push({
      id,
      kind,
      path,
      sha256: createHash("sha256").update(bytes).digest("hex"),
      capabilities,
      licenses,
    });
  };
  await record(
    `bin/${nodeName}`,
    "node",
    "executable",
    ["mcp.stdio", "mcp.http"],
    ["licenses/node.txt"],
  );
  await record(
    "server.mjs",
    "server",
    "resource",
    ["mcp.catalog", "mcp.profiles", "runtime.jobs"],
    serverLicenses,
  );
  await record(
    `bin/${authoringName}`,
    "authoring",
    "executable",
    ["authoring", "validation", "export", "discovery"],
    ["licenses/avelune.txt", "licenses/dart.txt"],
  );
  if (process.platform === "darwin") {
    await record(
      `bin/authoring-${process.arch}.aot`,
      "authoring-snapshot",
      "resource",
      ["authoring.snapshot"],
      ["licenses/avelune.txt"],
    );
    components.find((component) => component.id === "authoring").entrypoint =
      "authoring-snapshot";
  }
  const headlessNode =
    process.platform === "darwin"
      ? `bin/node-headless-${process.arch}`
      : `bin/${nodeName}`;
  const headlessAuthoring =
    process.platform === "darwin"
      ? `bin/authoring-headless-${process.arch}`
      : `bin/${authoringName}`;
  if (process.platform === "darwin") {
    await cp(join(bundle, "bin", nodeName), join(bundle, headlessNode));
    await cp(authoring, join(bundle, headlessAuthoring));
    await cp(
      join(bundle, "runtime.app"),
      join(bundle, "runtime-headless.app"),
      { recursive: true, verbatimSymlinks: true },
    );
  }
  await record(
    headlessNode,
    "node-headless",
    "executable",
    ["mcp.stdio", "mcp.http"],
    ["licenses/node.txt"],
  );
  await record(
    headlessAuthoring,
    "authoring-headless",
    "executable",
    ["authoring", "validation", "export", "discovery"],
    ["licenses/avelune.txt", "licenses/dart.txt"],
  );
  if (process.platform === "darwin") {
    components.find(
      (component) => component.id === "authoring-headless",
    ).entrypoint = "authoring-snapshot";
  }
  if (process.platform === "darwin") {
    const headersName = `node-${nodeVersion}-headers.tar.gz`;
    const headers = Buffer.from(
      await (
        await fetch(
          `https://nodejs.org/dist/${nodeVersion}/${headersName}`,
        ).then((response) => {
          if (!response.ok)
            throw Error("Unable to fetch the pinned Node headers.");
          return response;
        })
      ).arrayBuffer(),
    );
    if (
      createHash("sha256").update(headers).digest("hex") !==
      "c5cc7d27906f5b22405a24726a05b9a20c728360225aebed284836c4ae315af5"
    )
      throw Error("The pinned Node headers failed integrity verification.");
    const headersPath = join(staging, headersName);
    await writeFile(headersPath, headers);
    await run("tar", ["-xf", headersPath, "-C", staging]);
    await run("xcrun", [
      "clang++",
      "-arch",
      "arm64",
      "-arch",
      "x86_64",
      "-fobjc-arc",
      "-std=c++17",
      "-dynamiclib",
      "-framework",
      "Foundation",
      "-framework",
      "CoreFoundation",
      "-install_name",
      "@rpath/libavelune_access.dylib",
      join(repository, "tools/pokemap_mcp/native/project_access.mm"),
      "-o",
      join(bundle, "bin/libavelune_access.dylib"),
    ]);
    await run("xcrun", [
      "clang++",
      "-arch",
      "arm64",
      "-arch",
      "x86_64",
      "-std=c++17",
      "-bundle",
      "-undefined",
      "dynamic_lookup",
      "-DNAPI_VERSION=8",
      "-DNODE_GYP_MODULE_NAME=avelune_project_access",
      "-I",
      join(staging, `node-${nodeVersion}`, "include/node"),
      join(repository, "tools/pokemap_mcp/native/project_access_addon.cc"),
      "-L",
      join(bundle, "bin"),
      "-lavelune_access",
      "-Wl,-rpath,@loader_path",
      "-o",
      join(bundle, "bin/project_access.node"),
    ]);
    await record(
      "bin/libavelune_access.dylib",
      "project-access-library",
      "resource",
      ["workspace.security-scope", "process.parent-watchdog"],
      ["licenses/avelune.txt"],
    );
    await record(
      "bin/project_access.node",
      "project-access-node",
      "resource",
      ["workspace.security-scope"],
      ["licenses/avelune.txt"],
    );
  }
  const headless =
    process.platform === "win32" ? "avelune-mcp.cmd" : "avelune-mcp";
  await writeFile(
    join(bundle, headless),
    process.platform === "win32"
      ? '@echo off\r\n"%~dp0bin\\node.exe" "%~dp0server.mjs" --runtime-manifest "%~dp0runtime-manifest.json" %*\r\n'
      : process.platform === "darwin"
        ? '#!/bin/sh\nAVELUNE_MCP_DIR=$(CDPATH= cd -- "${0%/*}" && pwd)\ncase "$(/usr/bin/uname -m)" in arm64) AVELUNE_MCP_ARCH=arm64;; x86_64) AVELUNE_MCP_ARCH=x64;; *) exit 64;; esac\nexec "$AVELUNE_MCP_DIR/bin/node-headless-$AVELUNE_MCP_ARCH" "$AVELUNE_MCP_DIR/server.mjs" --runtime-manifest "$AVELUNE_MCP_DIR/runtime-manifest-$AVELUNE_MCP_ARCH.json" "$@"\n'
        : '#!/bin/sh\nAVELUNE_MCP_DIR=$(CDPATH= cd -- "${0%/*}" && pwd)\nexec "$AVELUNE_MCP_DIR/bin/node" "$AVELUNE_MCP_DIR/server.mjs" --runtime-manifest "$AVELUNE_MCP_DIR/runtime-manifest.json" "$@"\n',
  );
  if (process.platform !== "win32") await chmod(join(bundle, headless), 0o755);
  await record(
    headless,
    "headless-entry",
    "resource",
    ["mcp.stdio", "mcp.http"],
    ["licenses/avelune.txt"],
  );
  const runtimePath =
    process.platform === "darwin"
      ? "runtime.app/Contents/MacOS/pokemap_render_host"
      : `runtime/${process.platform === "win32" ? "pokemap_render_host.exe" : "pokemap_render_host"}`;
  const runtimeCapabilities = [
    "render.2d",
    ...(process.platform !== "win32"
      ? ["playtest.headless", "playtest.interactive"]
      : []),
    ...(process.platform === "darwin" ? ["render.3d", "scan.3d"] : []),
  ];
  await record(runtimePath, "runtime", "executable", runtimeCapabilities, [
    "licenses/avelune.txt",
  ]);
  await record(
    process.platform === "darwin"
      ? runtimePath.replace("runtime.app/", "runtime-headless.app/")
      : runtimePath,
    "runtime-headless",
    "executable",
    runtimeCapabilities,
    ["licenses/avelune.txt"],
  );
  if (process.platform !== "darwin") {
    const name =
      process.platform === "win32"
        ? "avelune_parent_watchdog.dll"
        : "libavelune_parent_watchdog.so";
    await record(
      `runtime/data/${name}`,
      "parent-watchdog-library",
      "resource",
      ["process.parent-watchdog"],
      ["licenses/avelune.txt"],
    );
  }
  let index = 0;
  const inventory = async (directory, prefix) => {
    for (const entry of (
      await readdir(directory, { withFileTypes: true })
    ).sort((a, b) => a.name.localeCompare(b.name))) {
      const path = `${prefix}/${entry.name}`;
      if (entry.isSymbolicLink()) continue;
      if (entry.isDirectory())
        await inventory(join(directory, entry.name), path);
      else if (!components.some((component) => component.path === path))
        await record(
          path,
          `runtime-resource-${++index}`,
          "resource",
          ["runtime.resource"],
          ["licenses/avelune.txt"],
        );
    }
  };
  await inventory(
    join(bundle, process.platform === "darwin" ? "runtime.app" : "runtime"),
    process.platform === "darwin" ? "runtime.app" : "runtime",
  );
  if (process.platform === "darwin")
    await inventory(
      join(bundle, "runtime-headless.app"),
      "runtime-headless.app",
    );
  await writeFile(
    join(bundle, "runtime-manifest.json"),
    JSON.stringify(
      {
        schemaVersion: 1,
        platform: process.platform,
        architecture: process.arch,
        provenance: { version, commit },
        components,
      },
      null,
      2,
    ) + "\n",
  );
  if (process.platform === "darwin") {
    await cp(
      join(bundle, "runtime-manifest.json"),
      join(bundle, `runtime-manifest-${process.arch}.json`),
    );
    const alternate = process.arch === "arm64" ? "x64" : "arm64";
    const name = `node-${nodeVersion}-darwin-${alternate}.tar.gz`;
    const data = Buffer.from(
      await (
        await fetch(`https://nodejs.org/dist/${nodeVersion}/${name}`).then(
          (response) => {
            if (!response.ok)
              throw Error("Unable to fetch the alternate Node distribution.");
            return response;
          },
        )
      ).arrayBuffer(),
    );
    if (
      createHash("sha256").update(data).digest("hex") !==
      archives[`darwin-${alternate}`][1]
    )
      throw Error("The alternate Node archive failed integrity verification.");
    const path = join(staging, name);
    await writeFile(path, data);
    await run("tar", ["-xf", path, "-C", staging]);
    await cp(
      join(staging, `node-${nodeVersion}-darwin-${alternate}`, "bin/node"),
      join(bundle, `bin/node-${alternate}`),
    );
    await cp(
      join(bundle, `bin/node-${alternate}`),
      join(bundle, `bin/node-headless-${alternate}`),
    );
    const dartArchiveName = `dartsdk-macos-${alternate}-release.zip`;
    const dartArchive = Buffer.from(
      await (
        await fetch(
          `https://storage.googleapis.com/dart-archive/channels/stable/release/3.13.4/sdk/${dartArchiveName}`,
        ).then((response) => {
          if (!response.ok)
            throw Error(
              "Unable to fetch the pinned alternate Dart AOT runtime.",
            );
          return response;
        })
      ).arrayBuffer(),
    );
    const dartHashes = {
      x64: "a8a75eb653a658d0e8238ec4a5b00a4a0023411d5d6ecc5f57e7cc19f7ae71e7",
      arm64: "b36bdca9cd4bf987e1453e1e3ec45fb2c2a8c4df3246b510b66d3922bab04463",
    };
    if (
      createHash("sha256").update(dartArchive).digest("hex") !==
      dartHashes[alternate]
    )
      throw Error("The alternate Dart archive failed integrity verification.");
    const dartArchivePath = join(staging, dartArchiveName);
    await writeFile(dartArchivePath, dartArchive);
    await run("unzip", [
      "-q",
      dartArchivePath,
      "dart-sdk/bin/dartaotruntime",
      "-d",
      join(staging, "alternate-dart"),
    ]);
    await cp(
      join(staging, "alternate-dart/dart-sdk/bin/dartaotruntime"),
      join(bundle, `bin/authoring-${alternate}`),
    );
    await run(
      join(
        flutterRoot,
        `bin/cache/artifacts/engine/darwin-x64-release/gen_snapshot_${alternate}`,
      ),
      [
        "--snapshot_kind=app-aot-elf",
        `--elf=${join(bundle, `bin/authoring-${alternate}.aot`)}`,
        kernel,
      ],
    );
    await cp(
      join(bundle, `bin/authoring-${alternate}`),
      join(bundle, `bin/authoring-headless-${alternate}`),
    );
    const alternateComponents = await Promise.all(
      components.map(async (component) => {
        if (
          ![
            "node",
            "authoring",
            "node-headless",
            "authoring-headless",
            "authoring-snapshot",
          ].includes(component.id)
        )
          return component;
        const path =
          component.id === "authoring-snapshot"
            ? `bin/authoring-${alternate}.aot`
            : `bin/${component.id}-${alternate}`;
        return {
          ...component,
          path,
          sha256: createHash("sha256")
            .update(await readFile(join(bundle, path)))
            .digest("hex"),
        };
      }),
    );
    await writeFile(
      join(bundle, `runtime-manifest-${alternate}.json`),
      JSON.stringify(
        {
          schemaVersion: 1,
          platform: process.platform,
          architecture: alternate,
          provenance: { version, commit },
          components: alternateComponents,
        },
        null,
        2,
      ) + "\n",
    );
  }
  await rename(bundle, output);
  process.stdout.write(
    JSON.stringify({
      output,
      platform: process.platform,
      architecture: process.arch,
      components: components.length,
      version,
      commit,
    }) + "\n",
  );
} finally {
  await rm(staging, { recursive: true, force: true });
}
