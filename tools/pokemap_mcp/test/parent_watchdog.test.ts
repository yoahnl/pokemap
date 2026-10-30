import assert from "node:assert/strict";
import { execFile, spawn } from "node:child_process";
import { mkdir, mkdtemp, rm, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join, resolve } from "node:path";
import { createInterface } from "node:readline";
import { promisify } from "node:util";
import { test } from "node:test";

const execute = promisify(execFile);

test(
  "the native owned-parent watchdog exits after its exact parent is killed",
  {
    skip:
      process.env.POKEMAP_RUN_DISTRIBUTION_QA !== "1" ||
      process.platform === "win32",
    timeout: 20_000,
  },
  async () => {
    const qa = join(
      homedir(),
      "Library/Caches/AveluneQA/mcp-studio-integration/watchdog",
    );
    await mkdir(qa, { recursive: true });
    const root = await mkdtemp(join(qa, "native-"));
    const source = join(root, "main.cc"),
      binary = join(root, "watchdog-child");
    await writeFile(
      source,
      '#include <iostream>\n#include <thread>\n#include <chrono>\n#include <cstdlib>\nextern "C" int avelune_watch_parent(int);\nint main(int argc,char**argv){if(argc!=2||avelune_watch_parent(std::atoi(argv[1])))return 2;std::cout<<"ready"<<std::endl;for(;;)std::this_thread::sleep_for(std::chrono::seconds(1));}\n',
    );
    const compiler = process.platform === "darwin" ? "xcrun" : "c++";
    await execute(compiler, [
      ...(process.platform === "darwin" ? ["clang++"] : []),
      "-std=c++17",
      "-pthread",
      source,
      resolve("native/parent_watchdog/parent_watchdog.cc"),
      "-o",
      binary,
    ]);
    const proxy = spawn(
      process.execPath,
      [
        "--input-type=module",
        "-e",
        'import {spawn} from "node:child_process";const c=spawn(process.argv[1],[String(process.pid)],{stdio:["ignore","pipe","pipe"]});c.stdout.once("data",()=>console.log(JSON.stringify({pid:c.pid})));',
        binary,
      ],
      { stdio: ["ignore", "pipe", "pipe"] },
    );
    let childPid: number | undefined, identity: string | undefined;
    const describe = async (pid: number) => {
      try {
        return (
          await execute("ps", ["-p", String(pid), "-o", "lstart=,stat=,args="])
        ).stdout.trim();
      } catch {
        return "";
      }
    };
    try {
      const pid = await new Promise<number>((accept, reject) => {
        const timer = setTimeout(
          () => reject(Error("The owned worker did not start.")),
          5000,
        );
        const lines = createInterface({ input: proxy.stdout });
        lines.once("line", (line) => {
          clearTimeout(timer);
          lines.close();
          accept((JSON.parse(line) as { pid: number }).pid);
        });
        proxy.once("error", reject);
      });
      childPid = pid;
      identity = await describe(pid);
      assert.ok(identity.endsWith(`${binary} ${proxy.pid}`));
      const exited = new Promise<void>((accept) =>
        proxy.once("exit", () => accept()),
      );
      assert.equal(proxy.kill("SIGKILL"), true);
      await exited;
      let alive = true;
      for (let attempt = 0; attempt < 40; attempt++) {
        const current = await describe(pid);
        alive = Boolean(current) && !current.split(/\s+/)[5]?.startsWith("Z");
        if (!alive) break;
        await new Promise((accept) => setTimeout(accept, 50));
      }
      assert.equal(
        alive,
        false,
        "The native worker survived its owned parent.",
      );
    } finally {
      if (proxy.exitCode === null && proxy.signalCode === null)
        proxy.kill("SIGTERM");
      if (childPid && identity) {
        const current = await describe(childPid);
        if (current === identity) process.kill(childPid, "SIGTERM");
      }
      await rm(root, { recursive: true, force: true });
    }
  },
);
