import { createReadStream } from "node:fs";
import { stat } from "node:fs/promises";
import { createServer } from "node:http";
import { extname, join, normalize } from "node:path";

const PORT = Number(process.env.PORT || 4173);
const HOST = process.env.HOST || "127.0.0.1";
const PUBLIC_DIR = join(process.cwd(), "public");
const MAX_BODY_BYTES = 1024 * 1024;

const MIME_TYPES = {
  ".html": "text/html; charset=utf-8",
  ".js": "application/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".svg": "image/svg+xml",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".txt": "text/plain; charset=utf-8"
};

const HOP_BY_HOP_HEADERS = new Set([
  "connection",
  "keep-alive",
  "proxy-authenticate",
  "proxy-authorization",
  "te",
  "trailer",
  "transfer-encoding",
  "upgrade",
  "host",
  "content-length",
  "accept-encoding"
]);

function sendJson(res, status, payload) {
  res.writeHead(status, {
    "content-type": "application/json; charset=utf-8",
    "cache-control": "no-store"
  });
  res.end(JSON.stringify(payload, null, 2));
}

function parseJsonBody(req) {
  return new Promise((resolve, reject) => {
    let size = 0;
    const chunks = [];

    req.on("data", (chunk) => {
      size += chunk.length;
      if (size > MAX_BODY_BYTES) {
        reject(new Error("Payload too large"));
        req.destroy();
        return;
      }
      chunks.push(chunk);
    });

    req.on("end", () => {
      const raw = Buffer.concat(chunks).toString("utf8").trim();
      if (!raw) {
        resolve({});
        return;
      }

      try {
        resolve(JSON.parse(raw));
      } catch {
        reject(new Error("Request body must be valid JSON"));
      }
    });

    req.on("error", reject);
  });
}

function sanitizeHeaders(inputHeaders) {
  const headers = {};

  if (!inputHeaders || typeof inputHeaders !== "object" || Array.isArray(inputHeaders)) {
    return headers;
  }

  for (const [key, value] of Object.entries(inputHeaders)) {
    if (typeof key !== "string") {
      continue;
    }

    const normalizedKey = key.trim().toLowerCase();
    if (!normalizedKey || HOP_BY_HOP_HEADERS.has(normalizedKey)) {
      continue;
    }

    if (value === null || value === undefined) {
      continue;
    }

    headers[normalizedKey] = String(value);
  }

  return headers;
}

function normalizeMethod(method) {
  const normalized = (method || "GET").toString().trim().toUpperCase();
  return normalized || "GET";
}

function hasBody(method) {
  return !["GET", "HEAD"].includes(method);
}

async function handleProxy(req, res) {
  let payload;
  try {
    payload = await parseJsonBody(req);
  } catch (error) {
    sendJson(res, 400, { error: error.message });
    return;
  }

  const method = normalizeMethod(payload.method);
  const urlRaw = typeof payload.url === "string" ? payload.url.trim() : "";

  if (!urlRaw) {
    sendJson(res, 400, { error: "url is required" });
    return;
  }

  let url;
  try {
    url = new URL(urlRaw);
  } catch {
    sendJson(res, 400, { error: "url must be a valid absolute URL" });
    return;
  }

  if (!["http:", "https:"].includes(url.protocol)) {
    sendJson(res, 400, { error: "Only http and https protocols are supported" });
    return;
  }

  const headers = sanitizeHeaders(payload.headers);
  const requestBody =
    typeof payload.body === "string"
      ? payload.body
      : payload.body == null
        ? ""
        : JSON.stringify(payload.body);
  const timeoutMs = Math.min(Math.max(Number(payload.timeoutMs) || 15000, 1000), 120000);

  const abortController = new AbortController();
  const timeoutHandle = setTimeout(() => abortController.abort(), timeoutMs);

  const startedAt = Date.now();

  try {
    const upstreamResponse = await fetch(url, {
      method,
      headers,
      body: hasBody(method) ? requestBody : undefined,
      redirect: "manual",
      signal: abortController.signal
    });

    const responseBodyText = await upstreamResponse.text();
    const durationMs = Date.now() - startedAt;

    const responseHeaders = {};
    for (const [key, value] of upstreamResponse.headers.entries()) {
      responseHeaders[key] = value;
    }

    sendJson(res, 200, {
      request: {
        method,
        url: url.toString(),
        headers,
        body: hasBody(method) ? requestBody : ""
      },
      response: {
        status: upstreamResponse.status,
        statusText: upstreamResponse.statusText,
        url: upstreamResponse.url,
        headers: responseHeaders,
        bodyText: responseBodyText
      },
      durationMs
    });
  } catch (error) {
    const durationMs = Date.now() - startedAt;
    const timeoutMessage = error?.name === "AbortError" ? `Request timed out after ${timeoutMs} ms` : null;

    sendJson(res, 502, {
      error: timeoutMessage || error.message || "Proxy request failed",
      durationMs
    });
  } finally {
    clearTimeout(timeoutHandle);
  }
}

function safeFilePath(pathname) {
  const path = pathname === "/" ? "/index.html" : pathname;
  const normalizedPath = normalize(path).replace(/^\.\.(\/|\\|$)/, "");
  const fullPath = join(PUBLIC_DIR, normalizedPath);

  if (!fullPath.startsWith(PUBLIC_DIR)) {
    return null;
  }

  return fullPath;
}

async function serveStaticFile(pathname, res) {
  const fullPath = safeFilePath(pathname);
  if (!fullPath) {
    res.writeHead(403, { "content-type": "text/plain; charset=utf-8" });
    res.end("Forbidden");
    return;
  }

  try {
    const fileStat = await stat(fullPath);
    if (!fileStat.isFile()) {
      throw new Error("Not a file");
    }

    const ext = extname(fullPath).toLowerCase();
    const contentType = MIME_TYPES[ext] || "application/octet-stream";

    res.writeHead(200, {
      "content-type": contentType,
      "cache-control": "no-cache"
    });

    createReadStream(fullPath).pipe(res);
  } catch {
    res.writeHead(404, { "content-type": "text/plain; charset=utf-8" });
    res.end("Not found");
  }
}

const server = createServer(async (req, res) => {
  const method = (req.method || "GET").toUpperCase();
  const pathname = new URL(req.url || "/", `http://${req.headers.host || "localhost"}`).pathname;

  if (method === "POST" && pathname === "/proxy") {
    await handleProxy(req, res);
    return;
  }

  if (method === "GET") {
    await serveStaticFile(pathname, res);
    return;
  }

  res.writeHead(405, { "content-type": "text/plain; charset=utf-8" });
  res.end("Method not allowed");
});

server.listen(PORT, HOST, () => {
  console.log(`API testing app running at http://${HOST}:${PORT}`);
});
