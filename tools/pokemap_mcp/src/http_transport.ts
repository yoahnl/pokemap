import { randomBytes, randomUUID, timingSafeEqual } from "node:crypto";
import {
  createServer,
  type IncomingMessage,
  type ServerResponse,
} from "node:http";
import { Readable } from "node:stream";
import type { Socket } from "node:net";
import {
  WebStandardStreamableHTTPServerTransport,
  isInitializeRequest,
} from "@modelcontextprotocol/server";
import { FALLBACK_PROTOCOL_VERSION } from "./protocol.js";
import type { PokeMapServerRuntime } from "./server_runtime.js";

export interface PokeMapHttpOptions {
  createRuntime(
    signal: AbortSignal,
  ): Promise<PokeMapServerRuntime> | PokeMapServerRuntime;
  port?: number;
  token?: string;
  maxSessions?: number;
  sessionIdleMs?: number;
}

interface Session {
  transport: WebStandardStreamableHTTPServerTransport;
  runtime: PokeMapServerRuntime;
  server: ReturnType<PokeMapServerRuntime["createServer"]>;
  touched: number;
  closing?: Promise<void>;
}

export async function startPokeMapHttp(options: PokeMapHttpOptions) {
  const token = options.token ?? randomBytes(32).toString("base64url");
  if (Buffer.byteLength(token) < 32)
    throw new Error("The local MCP credential must contain at least 32 bytes.");
  const sessions = new Map<string, Session>(),
    pending = new Set<Session>(),
    sockets = new Set<Socket>();
  const admissions = new Map<AbortController, Promise<void>>();
  let closing: Promise<void> | undefined,
    port = 0,
    generation = 0,
    suspended = false,
    starting = 0;
  const maxSessions = options.maxSessions ?? 16,
    idleMs = options.sessionIdleMs ?? 15 * 60 * 1000;
  if (
    !Number.isInteger(maxSessions) ||
    maxSessions < 1 ||
    !Number.isSafeInteger(idleMs) ||
    idleMs < 1
  )
    throw new Error("Invalid MCP session limits.");
  async function release(session: Session): Promise<void> {
    if (session.closing) return session.closing;
    session.closing = Promise.resolve().then(async () => {
      for (const [id, value] of sessions)
        if (value === session) sessions.delete(id);
      pending.delete(session);
      await Promise.allSettled([
        session.server.close(),
        session.transport.close(),
      ]);
      await session.runtime.close();
    });
    return session.closing;
  }
  async function invalidateSessions(): Promise<void> {
    generation++;
    suspended = true;
    try {
      for (const controller of admissions.keys()) controller.abort();
      await Promise.allSettled([...admissions.values()]);
      const results = await Promise.allSettled(
        [...new Set([...sessions.values(), ...pending])].map(release),
      );
      const failure = results.find((result) => result.status === "rejected");
      if (failure?.status === "rejected") throw failure.reason;
    } finally {
      suspended = false;
    }
  }
  const listener = createServer((request, response) => {
    void handle(request, response).catch(() => {
      if (!response.headersSent)
        response.writeHead(500, { "Content-Type": "application/json" });
      response.end(JSON.stringify({ error: "The local MCP request failed." }));
    });
  });
  listener.on("connection", (socket) => {
    sockets.add(socket);
    socket.on("close", () => sockets.delete(socket));
  });
  listener.maxHeadersCount = 64;
  listener.headersTimeout = 15000;
  async function handle(
    request: IncomingMessage,
    response: ServerResponse,
  ): Promise<void> {
    const allowedHosts = [`127.0.0.1:${port}`, `localhost:${port}`];
    const expectedOrigin = `http://127.0.0.1:${port}`;
    if (
      !allowedHosts.includes(request.headers.host ?? "") ||
      (request.headers.origin !== undefined &&
        request.headers.origin !== expectedOrigin)
    ) {
      response.writeHead(403);
      response.end();
      return;
    }
    const supplied = Buffer.from(request.headers.authorization ?? "");
    const expected = Buffer.from(`Bearer ${token}`);
    if (
      supplied.length !== expected.length ||
      !timingSafeEqual(supplied, expected)
    ) {
      response.writeHead(401, { "WWW-Authenticate": "Bearer" });
      response.end();
      return;
    }
    if (request.url !== "/mcp") {
      response.writeHead(404);
      response.end();
      return;
    }
    if (closing || suspended) {
      response.writeHead(503);
      response.end();
      return;
    }
    if (!["POST", "GET", "DELETE"].includes(request.method ?? "")) {
      response.writeHead(405);
      response.end();
      return;
    }
    let body: Buffer | undefined, parsed: unknown;
    if (request.method === "POST") {
      const chunks: Buffer[] = [];
      let count = 0;
      for await (const chunk of request) {
        const bytes = Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk);
        count += bytes.length;
        if (count > 2 * 1024 * 1024) {
          response.writeHead(413);
          response.end();
          return;
        }
        chunks.push(bytes);
      }
      body = Buffer.concat(chunks);
      try {
        parsed = JSON.parse(body.toString("utf8"));
      } catch {
        response.writeHead(400);
        response.end();
        return;
      }
    }
    const sessionHeader = request.headers["mcp-session-id"];
    let session =
      typeof sessionHeader === "string"
        ? sessions.get(sessionHeader)
        : undefined;
    if (!session) {
      if (sessionHeader !== undefined) {
        response.writeHead(404);
        response.end();
        return;
      }
      if (request.method !== "POST" || !isInitializeRequest(parsed)) {
        response.writeHead(400);
        response.end();
        return;
      }
      if (sessions.size + pending.size + starting >= maxSessions) {
        response.writeHead(429);
        response.end();
        return;
      }
      const admissionGeneration = generation;
      const admission = new AbortController();
      let completeAdmission!: () => void;
      admissions.set(
        admission,
        new Promise<void>((accept) => {
          completeAdmission = accept;
        }),
      );
      starting++;
      let runtime: PokeMapServerRuntime;
      try {
        runtime = await options.createRuntime(admission.signal);
        if (closing || suspended || admissionGeneration !== generation) {
          await runtime.close();
          response.writeHead(503);
          response.end();
          return;
        }
        const transport = new WebStandardStreamableHTTPServerTransport({
          sessionIdGenerator: randomUUID,
          enableJsonResponse: true,
          onsessioninitialized: (id) => {
            if (session && !session.closing) {
              pending.delete(session);
              sessions.set(id, session);
            }
          },
          onsessionclosed: () => {
            if (session) void release(session).catch(() => {});
          },
        });
        let server: Session["server"];
        try {
          server = runtime.createServer([FALLBACK_PROTOCOL_VERSION]);
        } catch (error) {
          await runtime.close();
          await transport.close();
          throw error;
        }
        session = { runtime, transport, server, touched: Date.now() };
        pending.add(session);
        try {
          await server.connect(transport);
        } catch (error) {
          await release(session);
          throw error;
        }
      } finally {
        starting--;
        admissions.delete(admission);
        completeAdmission();
      }
    }
    if (session.closing) {
      response.writeHead(410);
      response.end();
      return;
    }
    session.touched = Date.now();
    const headers = new Headers();
    for (const [name, value] of Object.entries(request.headers)) {
      if (typeof value === "string") headers.set(name, value);
      else if (Array.isArray(value))
        for (const item of value) headers.append(name, item);
    }
    const controller = new AbortController();
    request.once("aborted", () => controller.abort());
    response.once("close", () => {
      if (!response.writableEnded) controller.abort();
    });
    const webRequest = new Request(`${expectedOrigin}/mcp`, {
      method: request.method!,
      headers,
      ...(body ? { body: body.toString("utf8") } : {}),
      signal: controller.signal,
    });
    let result: Response;
    try {
      result = await session.transport.handleRequest(webRequest, {
        parsedBody: parsed,
      });
    } catch (error) {
      if (!session.transport.sessionId) await release(session);
      throw error;
    }
    if (!session.transport.sessionId) await release(session);
    response.writeHead(result.status, Object.fromEntries(result.headers));
    if (result.body) {
      const stream = Readable.fromWeb(
        result.body as import("node:stream/web").ReadableStream,
      );
      response.once("close", () => stream.destroy());
      stream.on("error", () => response.destroy());
      stream.pipe(response);
    } else response.end();
  }
  await new Promise<void>((accept, reject) => {
    listener.once("error", reject);
    listener.listen(options.port ?? 0, "127.0.0.1", () => {
      listener.off("error", reject);
      accept();
    });
  });
  const address = listener.address();
  if (!address || typeof address === "string")
    throw new Error("The local MCP endpoint did not bind.");
  port = address.port;
  const timer = setInterval(
    () => {
      for (const session of sessions.values())
        if (Date.now() - session.touched > idleMs)
          void release(session).catch(() => {});
    },
    Math.min(idleMs, 30000),
  );
  timer.unref();
  return {
    url: `http://127.0.0.1:${port}/mcp`,
    token,
    sessionCount: () => sessions.size,
    invalidateSessions,
    close: () =>
      (closing ??= (async () => {
        clearInterval(timer);
        await invalidateSessions();
        for (const socket of sockets) socket.destroy();
        await new Promise<void>((accept, reject) =>
          listener.close((error) => (error ? reject(error) : accept())),
        );
      })()),
  };
}
