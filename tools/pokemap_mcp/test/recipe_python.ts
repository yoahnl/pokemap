import { execFile } from "node:child_process";
import { promisify } from "node:util";

const execute = promisify(execFile);

export async function runRecipePython(cwd: string, script: string, ...parameters: string[]): Promise<void> {
  const args = ["-B", "-c", script, ...parameters];
  const options = { cwd, timeout: 60_000 };
  const interpreter = process.env.POKEMAP_TEST_PYTHON;
  if (interpreter) {
    await execute(interpreter, args, options);
    return;
  }
  try {
    await execute("uv", ["run", "--no-project", "--python", "3.14", "--with", "Pillow==13.0.0",
      "python", ...args], options);
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
    await execute("python3", args, options);
  }
}
