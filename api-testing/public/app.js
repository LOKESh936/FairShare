const storageKey = "api-testing:last-request";
const historyKey = "api-testing:history";
const tokenKey = "api-testing:last-token";

const form = document.getElementById("request-form");
const urlInput = document.getElementById("request-url");
const methodInput = document.getElementById("request-method");
const timeoutInput = document.getElementById("request-timeout");
const headersInput = document.getElementById("request-headers");
const bodyInput = document.getElementById("request-body");
const sendButton = document.getElementById("send-button");

const clearResponseButton = document.getElementById("clear-response");
const statusPill = document.getElementById("status-pill");
const metaLine = document.getElementById("meta-line");
const responseHeaders = document.getElementById("response-headers");
const responseBody = document.getElementById("response-body");
const historyList = document.getElementById("history-list");

function setStatus(type, text) {
  statusPill.className = `status-pill status-${type}`;
  statusPill.textContent = text;
}

function parseHeaders(raw) {
  const value = raw.trim();
  if (!value) {
    return {};
  }

  const parsed = JSON.parse(value);
  if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
    throw new Error("Headers must be a JSON object.");
  }

  return parsed;
}

function extractTokenFromResponseBody(bodyText) {
  if (!bodyText || typeof bodyText !== "string") {
    return null;
  }

  try {
    const payload = JSON.parse(bodyText);
    return typeof payload.token === "string" ? payload.token.trim() : null;
  } catch {
    return null;
  }
}

function getAuthorizationHeader(headers) {
  return headers.Authorization || headers.authorization || "";
}

function extractBearerToken(authHeaderValue) {
  const raw = String(authHeaderValue || "").trim();
  if (!raw) return "";
  return raw.replace(/^Bearer\s+/i, "").trim();
}

function isValidJwtShape(token) {
  return token.split(".").length === 3;
}

function prettyJson(input) {
  try {
    return JSON.stringify(JSON.parse(input), null, 2);
  } catch {
    return input;
  }
}

function resetResponsePanel() {
  setStatus("idle", "Idle");
  metaLine.textContent = "No request sent yet.";
  responseHeaders.textContent = "{}";
  responseBody.textContent = "Send a request to see data here.";
}

function getRequestSnapshot() {
  return {
    url: urlInput.value.trim(),
    method: methodInput.value,
    timeoutMs: Number(timeoutInput.value) || 15000,
    headersRaw: headersInput.value,
    body: bodyInput.value
  };
}

function setRequestSnapshot(snapshot) {
  if (!snapshot) return;
  urlInput.value = snapshot.url || "";
  methodInput.value = snapshot.method || "GET";
  timeoutInput.value = String(snapshot.timeoutMs || 15000);
  headersInput.value = snapshot.headersRaw || "";
  bodyInput.value = snapshot.body || "";
}

function saveCurrentRequest() {
  const snapshot = getRequestSnapshot();
  localStorage.setItem(storageKey, JSON.stringify(snapshot));

  const currentHistory = JSON.parse(localStorage.getItem(historyKey) || "[]");
  const compact = `${snapshot.method} ${snapshot.url}`;
  const nextHistory = [snapshot, ...currentHistory.filter((item) => `${item.method} ${item.url}` !== compact)].slice(0, 8);
  localStorage.setItem(historyKey, JSON.stringify(nextHistory));
  renderHistory();
}

function renderHistory() {
  const history = JSON.parse(localStorage.getItem(historyKey) || "[]");
  historyList.innerHTML = "";

  if (!history.length) {
    const li = document.createElement("li");
    li.textContent = "No recent requests yet.";
    li.style.color = "#5a6761";
    li.style.fontSize = "0.9rem";
    historyList.appendChild(li);
    return;
  }

  for (const item of history) {
    const li = document.createElement("li");
    const button = document.createElement("button");
    button.type = "button";
    button.textContent = `${item.method} ${item.url}`;
    button.addEventListener("click", () => setRequestSnapshot(item));
    li.appendChild(button);
    historyList.appendChild(li);
  }
}

async function sendRequest(event) {
  event.preventDefault();
  const snapshot = getRequestSnapshot();

  if (!snapshot.url) {
    setStatus("error", "Invalid");
    metaLine.textContent = "Request URL is required.";
    return;
  }

  let headers;
  try {
    headers = parseHeaders(snapshot.headersRaw);
  } catch (error) {
    setStatus("error", "Invalid");
    metaLine.textContent = error.message;
    return;
  }

  const isAuthRequest = /\/auth\/(login|register)\b/.test(snapshot.url);
  const savedToken = (localStorage.getItem(tokenKey) || "").trim();
  const incomingAuthHeader = getAuthorizationHeader(headers);

  if (!isAuthRequest && !incomingAuthHeader && savedToken) {
    headers.Authorization = `Bearer ${savedToken}`;
  }

  const authHeaderToValidate = getAuthorizationHeader(headers);
  if (authHeaderToValidate) {
    const bearerToken = extractBearerToken(authHeaderToValidate);
    if (!isValidJwtShape(bearerToken)) {
      setStatus("error", "Invalid");
      metaLine.textContent =
        "Authorization token looks incomplete. JWT must have 3 dot-separated parts.";
      return;
    }
  }

  sendButton.disabled = true;
  setStatus("pending", "Sending");
  metaLine.textContent = `Sending ${snapshot.method} request...`;

  try {
    const proxyResponse = await fetch("/proxy", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        url: snapshot.url,
        method: snapshot.method,
        headers,
        body: snapshot.body,
        timeoutMs: snapshot.timeoutMs
      })
    });

    const payload = await proxyResponse.json();

    if (!proxyResponse.ok || payload.error) {
      setStatus("error", "Error");
      metaLine.textContent = payload.error || "Request failed.";
      responseHeaders.textContent = "{}";
      responseBody.textContent = prettyJson(JSON.stringify(payload, null, 2));
      return;
    }

    const status = payload.response?.status || 0;
    const tone = status >= 200 && status < 400 ? "success" : "error";
    setStatus(tone, `${status} ${payload.response?.statusText || ""}`.trim());
    const tokenFromResponse = extractTokenFromResponseBody(payload.response?.bodyText || "");
    if (tokenFromResponse) {
      localStorage.setItem(tokenKey, tokenFromResponse);
    }

    metaLine.textContent = `${payload.request.method} ${payload.request.url} in ${payload.durationMs} ms${tokenFromResponse ? " • token saved" : ""}`;
    responseHeaders.textContent = JSON.stringify(payload.response.headers || {}, null, 2);
    responseBody.textContent = prettyJson(payload.response.bodyText || "");
    saveCurrentRequest();
  } catch (error) {
    setStatus("error", "Error");
    metaLine.textContent = error.message || "Unexpected error";
  } finally {
    sendButton.disabled = false;
  }
}

form.addEventListener("submit", sendRequest);
clearResponseButton.addEventListener("click", resetResponsePanel);

setRequestSnapshot(JSON.parse(localStorage.getItem(storageKey) || "null"));
renderHistory();
resetResponsePanel();
