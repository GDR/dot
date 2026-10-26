import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { getJsonSchemaToolParameters } from "../api/constrained-sampling.js";
import {
    convertMessages,
    isThinkingPart,
    mapStopReasonString,
    retainThoughtSignature,
} from "../api/google-shared.js";
import { buildBaseOptions } from "../api/simple-options.js";
import { calculateCost, clampThinkingLevel, createProvider } from "../models.js";
import { formatProviderError, normalizeProviderError } from "../utils/error-body.js";
import { AssistantMessageEventStream } from "../utils/event-stream.js";
import { sanitizeSurrogates } from "../utils/sanitize-unicode.js";
import { getSystemMessageText } from "../utils/text.js";
import {
    collapseSystemMessages,
    getCurrentTools,
    getInitialSystemMessage,
} from "../utils/transcript.js";

const TOKEN_URL = "https://oauth2.googleapis.com/token";
const ENDPOINTS = [
    "https://daily-cloudcode-pa.googleapis.com",
    "https://daily-cloudcode-pa.sandbox.googleapis.com",
    "https://cloudcode-pa.googleapis.com",
];
const USER_AGENT =
    "antigravity/cli/1.4.0 (aidev_client; os_type=linux; arch=amd64; cl=982146307; auth_method=consumer)";
const BASE_URL = ENDPOINTS[0];

const DEFAULT_TOKEN_FILES = [
    path.join(os.homedir(), ".gemini", "jetski-standalone-oauth-token"),
    path.join(os.homedir(), ".gemini", "antigravity-cli", "antigravity-oauth-token"),
];
const DEFAULT_CLIENT_FILE = path.join(os.homedir(), ".gemini", "antigravity-oauth-client.json");
const DEFAULT_PROJECT_ID_FILE = path.join(os.homedir(), ".gemini", "code_assist_project_id.txt");

let cachedOAuthClient = null;

function resolveOAuthClient(parsedTokenFile) {
    if (cachedOAuthClient?.clientId && cachedOAuthClient?.clientSecret) {
        return cachedOAuthClient;
    }

    let clientId = process.env.ANTIGRAVITY_CLIENT_ID || parsedTokenFile?.client_id;
    let clientSecret = process.env.ANTIGRAVITY_CLIENT_SECRET || parsedTokenFile?.client_secret;

    if ((!clientId || !clientSecret) && fs.existsSync(DEFAULT_CLIENT_FILE)) {
        try {
            const clientCfg = JSON.parse(fs.readFileSync(DEFAULT_CLIENT_FILE, "utf8"));
            clientId = clientId || clientCfg.client_id || clientCfg.clientId;
            clientSecret = clientSecret || clientCfg.client_secret || clientCfg.clientSecret;
        } catch {
            // ignore
        }
    }

    if (!clientId && typeof parsedTokenFile?.id_token === "string") {
        try {
            const payload = JSON.parse(
                Buffer.from(parsedTokenFile.id_token.split(".")[1], "base64url").toString("utf8"),
            );
            if (typeof payload?.aud === "string") {
                clientId = payload.aud;
            }
        } catch {
            // ignore
        }
    }

    if (!clientId || !clientSecret) {
        const pathDirs = (process.env.PATH || "").split(path.delimiter).filter(Boolean);
        const agyCandidates = [
            path.join(os.homedir(), ".gemini", "antigravity-cli", "bin", "agy"),
            ...pathDirs.map((dir) => path.join(dir, "agy")),
        ];
        for (const binPath of agyCandidates) {
            try {
                if (!fs.existsSync(binPath)) continue;
                const raw = fs.readFileSync(binPath).toString("latin1");
                if (!clientId) {
                    const idMatch = raw.match(/\d{12}-[a-z0-9]{32}\.apps\.googleusercontent\.com/);
                    if (idMatch) clientId = idMatch[0];
                }
                if (!clientSecret) {
                    const secretMatch = raw.match(/GOCSPX-[A-Za-z0-9_-]{28}/);
                    if (secretMatch) clientSecret = secretMatch[0];
                }
                if (clientId && clientSecret) break;
            } catch {
                // ignore
            }
        }
    }

    if (!clientId || !clientSecret) {
        throw new Error(
            "Missing Antigravity OAuth client credentials. Set ANTIGRAVITY_CLIENT_ID and ANTIGRAVITY_CLIENT_SECRET or install agy CLI.",
        );
    }

    cachedOAuthClient = { clientId, clientSecret };
    return cachedOAuthClient;
}

function findLocalTokenFile() {
    const custom = process.env.ANTIGRAVITY_OAUTH_TOKEN_FILE;
    if (custom && fs.existsSync(custom)) return custom;
    for (const candidate of DEFAULT_TOKEN_FILES) {
        try {
            if (fs.existsSync(candidate)) return candidate;
        } catch {
            // ignore
        }
    }
    return undefined;
}

// Auto-populate process.env.ANTIGRAVITY_OAUTH_TOKEN when a local token file is present
// so LearnHarness's catalogProviders() marks "antigravity" as keyPresent: true.
export function bootstrapAntigravityEnv() {
    if (!process.env.ANTIGRAVITY_OAUTH_TOKEN && findLocalTokenFile()) {
        process.env.ANTIGRAVITY_OAUTH_TOKEN = "local-antigravity-oauth";
    }
}
bootstrapAntigravityEnv();

let cachedAuth = null;

function readLocalProjectId() {
    if (process.env.ANTIGRAVITY_PROJECT_ID) {
        return process.env.ANTIGRAVITY_PROJECT_ID.trim();
    }
    try {
        if (fs.existsSync(DEFAULT_PROJECT_ID_FILE)) {
            const id = fs.readFileSync(DEFAULT_PROJECT_ID_FILE, "utf8").trim();
            if (id) return id;
        }
    } catch {
        // ignore
    }
    return undefined;
}

async function discoverProjectId(accessToken, signal) {
    const local = readLocalProjectId();
    if (local) return local;
    for (const endpoint of ENDPOINTS) {
        try {
            const res = await fetch(`${endpoint}/v1internal:loadCodeAssist`, {
                method: "POST",
                headers: {
                    Authorization: `Bearer ${accessToken}`,
                    "Content-Type": "application/json",
                    "User-Agent": USER_AGENT,
                },
                body: JSON.stringify({ metadata: { ideType: "ANTIGRAVITY" } }),
                signal,
            });
            if (!res.ok) continue;
            const data = await res.json();
            if (typeof data.cloudaicompanionProject === "string" && data.cloudaicompanionProject) {
                return data.cloudaicompanionProject;
            }
            if (data.cloudaicompanionProject?.id) {
                return data.cloudaicompanionProject.id;
            }
        } catch {
            // try next
        }
    }
    return "charming-canopy-c8n20";
}

async function refreshAccessToken(refreshToken, parsedFile, signal) {
    const { clientId, clientSecret } = resolveOAuthClient(parsedFile);
    const response = await fetch(TOKEN_URL, {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams({
            client_id: clientId,
            client_secret: clientSecret,
            refresh_token: refreshToken,
            grant_type: "refresh_token",
        }),
        signal,
    });
    if (!response.ok) {
        const text = await response.text();
        throw new Error(`Antigravity OAuth token refresh failed (${response.status}): ${text}`);
    }
    const data = await response.json();
    return {
        accessToken: data.access_token,
        refreshToken: data.refresh_token || refreshToken,
        expiresMs: Date.now() + (data.expires_in || 3600) * 1000 - 5 * 60 * 1000,
        expirySeconds: Math.floor(Date.now() / 1000) + (data.expires_in || 3600),
    };
}

async function resolveAntigravityAuth(rawKey, signal) {
    const now = Date.now();
    if (cachedAuth && cachedAuth.expiresMs > now) {
        return cachedAuth;
    }

    const tokenFile = findLocalTokenFile();
    let parsedFile = null;
    let accessToken = undefined;
    let refreshToken = undefined;
    let expiresMs = 0;

    if (tokenFile) {
        try {
            parsedFile = JSON.parse(fs.readFileSync(tokenFile, "utf8"));
            const tok = parsedFile?.token ?? parsedFile;
            accessToken = tok?.access_token ?? tok?.access;
            refreshToken = tok?.refresh_token ?? tok?.refresh;
            const rawExpiry = Number(tok?.expiry ?? tok?.expires ?? 0);
            if (rawExpiry > 0) {
                expiresMs = (rawExpiry < 1e12 ? rawExpiry * 1000 : rawExpiry) - 5 * 60 * 1000;
            }
        } catch {
            // fallback to rawKey
        }
    }

    if (!refreshToken && rawKey && rawKey !== "local-antigravity-oauth") {
        const trimmed = rawKey.trim();
        if (trimmed.startsWith("{")) {
            try {
                const obj = JSON.parse(trimmed);
                const tok = obj?.token ?? obj;
                accessToken = tok?.access_token ?? tok?.access ?? accessToken;
                refreshToken = tok?.refresh_token ?? tok?.refresh ?? refreshToken;
            } catch {
                // ignore
            }
        } else if (trimmed.startsWith("1//")) {
            refreshToken = trimmed;
        } else if (trimmed.startsWith("ya29.")) {
            accessToken = trimmed;
            expiresMs = now + 30 * 60 * 1000;
        }
    }

    if ((!accessToken || expiresMs <= now) && refreshToken) {
        const refreshed = await refreshAccessToken(refreshToken, parsedFile, signal);
        accessToken = refreshed.accessToken;
        refreshToken = refreshed.refreshToken;
        expiresMs = refreshed.expiresMs;

        if (tokenFile && parsedFile?.token) {
            try {
                parsedFile.token.access_token = accessToken;
                parsedFile.token.refresh_token = refreshToken;
                parsedFile.token.expiry = refreshed.expirySeconds;
                fs.writeFileSync(tokenFile, JSON.stringify(parsedFile));
            } catch {
                // read-only or permission issue; memory cache still works
            }
        }
    }

    if (!accessToken) {
        throw new Error(
            "No Antigravity OAuth credentials found in ~/.gemini/jetski-standalone-oauth-token or ~/.gemini/antigravity-cli/antigravity-oauth-token",
        );
    }

    const projectId = await discoverProjectId(accessToken, signal);
    cachedAuth = { accessToken, refreshToken, expiresMs, projectId };
    return cachedAuth;
}

const GROUPED_THINKING_VARIANTS = {
    "gemini-4-argon": {
        low: "gemini-4-argon-low",
        medium: "gemini-4-argon-medium",
        high: "gemini-4-argon-high",
    },
    "gemini-3.8-flash": {
        low: "gemini-3.8-flash-low",
        medium: "gemini-3.8-flash-medium",
        high: "gemini-3.8-flash-high",
    },
    "claude-opus-5-5": {
        low: "claude-opus-5-5-low",
        medium: "claude-opus-5-5-medium",
        high: "claude-opus-5-5-high",
    },
    "claude-sonnet-5-5": {
        low: "claude-sonnet-5-5-low",
        medium: "claude-sonnet-5-5-medium",
        high: "claude-sonnet-5-5-high",
    },
};

const THREE_LEVEL_MAP = {
    off: null,
    minimal: null,
    low: "low",
    medium: "medium",
    high: "high",
    xhigh: null,
    max: null,
};

const FOUR_LEVEL_MAP = {
    off: null,
    minimal: "minimal",
    low: "low",
    medium: "medium",
    high: "high",
    xhigh: null,
    max: null,
};

function mkChatModel({
    id,
    name,
    reasoning = true,
    thinkingLevelMap = THREE_LEVEL_MAP,
    input = ["text", "image"],
    contextWindow = 1048576,
    maxTokens = 65536,
}) {
    return {
        id,
        name,
        api: "google-antigravity",
        provider: "antigravity",
        baseUrl: BASE_URL,
        reasoning,
        ...(reasoning && thinkingLevelMap ? { thinkingLevelMap } : {}),
        input,
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow,
        maxTokens,
        type: "chat",
    };
}

export const ANTIGRAVITY_MODELS = [
    mkChatModel({
        id: "gemini-4-argon",
        name: "Gemini 4 Argon",
        thinkingLevelMap: THREE_LEVEL_MAP,
        contextWindow: 1048576,
        maxTokens: 65536,
    }),
    mkChatModel({
        id: "gemini-3.8-flash",
        name: "Gemini 3.8 Flash",
        thinkingLevelMap: THREE_LEVEL_MAP,
        contextWindow: 1048576,
        maxTokens: 65536,
    }),
    mkChatModel({
        id: "claude-opus-5-5",
        name: "Claude Opus 5.5",
        thinkingLevelMap: THREE_LEVEL_MAP,
        contextWindow: 200000,
        maxTokens: 64000,
    }),
    mkChatModel({
        id: "claude-sonnet-5-5",
        name: "Claude Sonnet 5.5",
        thinkingLevelMap: THREE_LEVEL_MAP,
        contextWindow: 200000,
        maxTokens: 64000,
    }),
    mkChatModel({
        id: "gemini-3-flash",
        name: "Gemini 3 Flash",
        thinkingLevelMap: FOUR_LEVEL_MAP,
        contextWindow: 1048576,
        maxTokens: 65536,
    }),
    mkChatModel({
        id: "gemini-3.5-flash-lite",
        name: "Gemini 3.5 Flash Lite",
        thinkingLevelMap: FOUR_LEVEL_MAP,
        contextWindow: 1048576,
        maxTokens: 65536,
    }),
    mkChatModel({
        id: "gemini-3.1-flash-lite",
        name: "Gemini 3.1 Flash Lite",
        thinkingLevelMap: FOUR_LEVEL_MAP,
        contextWindow: 1048576,
        maxTokens: 65536,
    }),
    mkChatModel({
        id: "gemini-2.5-pro",
        name: "Gemini 2.5 Pro",
        thinkingLevelMap: FOUR_LEVEL_MAP,
        contextWindow: 1048576,
        maxTokens: 65536,
    }),
    mkChatModel({
        id: "gemini-2.5-flash",
        name: "Gemini 2.5 Flash",
        thinkingLevelMap: FOUR_LEVEL_MAP,
        contextWindow: 1048576,
        maxTokens: 65536,
    }),
    mkChatModel({
        id: "gpt-oss-120b-medium",
        name: "GPT-OSS 120B (Medium)",
        thinkingLevelMap: {
            off: null,
            minimal: null,
            low: null,
            medium: "medium",
            high: null,
            xhigh: null,
            max: null,
        },
        input: ["text"],
        contextWindow: 131072,
        maxTokens: 32768,
    }),
];

const UNSUPPORTED_SCHEMA_KEYS = new Set([
    "$schema",
    "$defs",
    "definitions",
    "additionalProperties",
    "$id",
    "$anchor",
    "$dynamicAnchor",
    "$vocabulary",
    "$comment",
    "$ref",
    "default",
    "examples",
    "title",
]);
const ALLOWED_STRING_FORMATS = new Set(["enum", "date-time", "date", "time"]);

function sanitizeSchemaForAntigravity(schema) {
    if (!schema || typeof schema !== "object") return schema;
    if (Array.isArray(schema)) return schema.map(sanitizeSchemaForAntigravity);

    if ("const" in schema && !("enum" in schema)) {
        const { const: constVal, ...rest } = schema;
        return sanitizeSchemaForAntigravity({
            ...rest,
            enum: [constVal],
            type: rest.type || typeof constVal,
        });
    }

    for (const unionKey of ["anyOf", "oneOf"]) {
        if (Array.isArray(schema[unionKey])) {
            const branches = schema[unionKey];
            const enumValues = [];
            let allEnum = true;
            let inferredType = schema.type;
            for (const b of branches) {
                if (b && typeof b === "object") {
                    if ("const" in b) {
                        enumValues.push(b.const);
                        if (!inferredType && b.type) inferredType = b.type;
                    } else if (Array.isArray(b.enum)) {
                        enumValues.push(...b.enum);
                        if (!inferredType && b.type) inferredType = b.type;
                    } else {
                        allEnum = false;
                        break;
                    }
                } else {
                    allEnum = false;
                    break;
                }
            }
            if (allEnum && enumValues.length > 0) {
                const { [unionKey]: _removed, ...rest } = schema;
                return sanitizeSchemaForAntigravity({
                    ...rest,
                    type: inferredType || "string",
                    enum: enumValues,
                });
            }
            const nonNull = branches.filter(
                (b) => !(b && typeof b === "object" && b.type === "null"),
            );
            const chosen = nonNull[0] || branches[0] || { type: "string" };
            const { [unionKey]: _removed, ...rest } = schema;
            return sanitizeSchemaForAntigravity({ ...rest, ...chosen });
        }
    }

    const out = {};
    for (const [k, v] of Object.entries(schema)) {
        if (UNSUPPORTED_SCHEMA_KEYS.has(k)) continue;
        if (k === "properties" && v && typeof v === "object" && !Array.isArray(v)) {
            const props = {};
            for (const [propName, propSchema] of Object.entries(v)) {
                props[propName] = sanitizeSchemaForAntigravity(propSchema);
            }
            out.properties = props;
            continue;
        }
        if (
            k === "format" &&
            schema.type === "string" &&
            typeof v === "string" &&
            !ALLOWED_STRING_FORMATS.has(v)
        ) {
            continue;
        }
        if (k === "type" && Array.isArray(v)) {
            const nonNull = v.filter((t) => t !== "null");
            out[k] = nonNull[0] || v[0] || "string";
            continue;
        }
        out[k] = sanitizeSchemaForAntigravity(v);
    }
    if (Array.isArray(out.required)) {
        if (out.properties && typeof out.properties === "object") {
            out.required = out.required.filter((req) => Object.hasOwn(out.properties, req));
            if (out.required.length === 0) delete out.required;
        } else {
            delete out.required;
        }
    }
    return out;
}

function convertAntigravityTools(tools) {
    if (!tools || tools.length === 0) return undefined;
    return [
        {
            functionDeclarations: tools.map((tool) => {
                const rawParams = getJsonSchemaToolParameters(tool, false);
                return {
                    name: tool.name,
                    description: tool.description,
                    parameters: sanitizeSchemaForAntigravity(rawParams),
                };
            }),
        },
    ];
}

function resolveRuntimeModelId(modelId, level) {
    const variants = GROUPED_THINKING_VARIANTS[modelId];
    if (!variants) return modelId;
    const normalized = level === "low" || level === "medium" || level === "high" ? level : "medium";
    return variants[normalized] ?? variants.medium;
}

let toolCallCounter = 0;

export const stream = (model, context, options) => {
    const eventStream = new AssistantMessageEventStream();
    const normalizedContext = collapseSystemMessages(context);

    (async () => {
        const output = {
            role: "assistant",
            content: [],
            api: model.api,
            provider: model.provider,
            model: model.id,
            usage: {
                input: 0,
                output: 0,
                cacheRead: 0,
                cacheWrite: 0,
                totalTokens: 0,
                cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 },
            },
            stopReason: "pending",
            timestamp: Date.now(),
        };

        try {
            const { accessToken, projectId } = await resolveAntigravityAuth(
                options?.apiKey,
                options?.signal,
            );
            const runtimeModel = resolveRuntimeModelId(model.id, options?.thinking?.level);

            const contents = convertMessages(model, normalizedContext);
            const initialSystemMessage = getInitialSystemMessage(normalizedContext.messages);
            const currentTools = getCurrentTools(normalizedContext.messages);
            const systemText = initialSystemMessage
                ? getSystemMessageText(initialSystemMessage)
                : "";

            const generationConfig = {};
            if (options?.temperature !== undefined) {
                generationConfig.temperature = options.temperature;
            }
            if (options?.maxTokens !== undefined) {
                generationConfig.maxOutputTokens = options.maxTokens;
            }

            if (options?.thinking?.enabled && model.reasoning) {
                const thinkingConfig = { includeThoughts: true };
                if (options.thinking.budgetTokens !== undefined) {
                    thinkingConfig.thinkingBudget = options.thinking.budgetTokens;
                    if (
                        runtimeModel.startsWith("claude-") &&
                        (!generationConfig.maxOutputTokens ||
                            generationConfig.maxOutputTokens <= thinkingConfig.thinkingBudget)
                    ) {
                        generationConfig.maxOutputTokens = Math.min(
                            model.maxTokens || 64000,
                            thinkingConfig.thinkingBudget + 16384,
                        );
                    }
                }
                generationConfig.thinkingConfig = thinkingConfig;
            }

            const requestPayload = {
                contents,
                ...(systemText && {
                    systemInstruction: {
                        parts: [{ text: sanitizeSurrogates(systemText) }],
                    },
                }),
                ...(Object.keys(generationConfig).length > 0 && { generationConfig }),
                ...(currentTools.length > 0 && { tools: convertAntigravityTools(currentTools) }),
            };

            let bodyObj = {
                project: projectId,
                model: runtimeModel,
                request: requestPayload,
                requestType: "agent",
                userAgent: "antigravity",
                requestId: `agent-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`,
            };

            const nextParams = await options?.onPayload?.(bodyObj, model);
            if (nextParams !== undefined) {
                bodyObj = nextParams;
            }

            const baseUrl = (model.baseUrl || BASE_URL).replace(/\/$/, "");
            const response = await fetch(`${baseUrl}/v1internal:streamGenerateContent?alt=sse`, {
                method: "POST",
                headers: {
                    Authorization: `Bearer ${accessToken}`,
                    "Content-Type": "application/json",
                    Accept: "text/event-stream",
                    "User-Agent": USER_AGENT,
                    ...(options?.headers ?? {}),
                },
                body: JSON.stringify(bodyObj),
                signal: options?.signal,
            });

            if (!response.ok) {
                const errorText = await response.text();
                throw new Error(
                    `Antigravity API error (${response.status} ${response.statusText}): ${errorText}`,
                );
            }

            if (!response.body) {
                throw new Error("Antigravity API returned empty response body");
            }

            eventStream.push({ type: "start", partial: output });

            let currentBlock = null;
            const blocks = output.content;
            const blockIndex = () => blocks.length - 1;

            const closeCurrentBlock = () => {
                if (!currentBlock) return;
                if (currentBlock.type === "text") {
                    eventStream.push({
                        type: "text_end",
                        contentIndex: blockIndex(),
                        content: currentBlock.text,
                        partial: output,
                    });
                } else if (currentBlock.type === "thinking") {
                    eventStream.push({
                        type: "thinking_end",
                        contentIndex: blockIndex(),
                        content: currentBlock.thinking,
                        partial: output,
                    });
                }
                currentBlock = null;
            };

            const reader = response.body.getReader();
            const decoder = new TextDecoder();
            let buffer = "";

            while (true) {
                const { done, value } = await reader.read();
                if (done) break;
                buffer += decoder.decode(value, { stream: true });
                const lines = buffer.split("\n");
                buffer = lines.pop() || "";

                for (const line of lines) {
                    if (!line.startsWith("data:")) continue;
                    const jsonStr = line.slice(5).trim();
                    if (!jsonStr || jsonStr === "[DONE]") continue;

                    let chunk;
                    try {
                        chunk = JSON.parse(jsonStr);
                    } catch {
                        continue;
                    }

                    await options?.onProviderStreamEvent?.(chunk, model);
                    const responseData = chunk.response ?? chunk;
                    output.responseId ||= responseData.responseId;

                    const candidate = responseData.candidates?.[0];
                    if (candidate?.content?.parts) {
                        for (const part of candidate.content.parts) {
                            if (part.text !== undefined) {
                                const isThinking = isThinkingPart(part);
                                if (
                                    !currentBlock ||
                                    (isThinking && currentBlock.type !== "thinking") ||
                                    (!isThinking && currentBlock.type !== "text")
                                ) {
                                    closeCurrentBlock();
                                    if (isThinking) {
                                        currentBlock = {
                                            type: "thinking",
                                            thinking: "",
                                            thinkingSignature: undefined,
                                        };
                                        output.content.push(currentBlock);
                                        eventStream.push({
                                            type: "thinking_start",
                                            contentIndex: blockIndex(),
                                            partial: output,
                                        });
                                    } else {
                                        currentBlock = { type: "text", text: "" };
                                        output.content.push(currentBlock);
                                        eventStream.push({
                                            type: "text_start",
                                            contentIndex: blockIndex(),
                                            partial: output,
                                        });
                                    }
                                }
                                if (currentBlock.type === "thinking") {
                                    currentBlock.thinking += part.text;
                                    currentBlock.thinkingSignature = retainThoughtSignature(
                                        currentBlock.thinkingSignature,
                                        part.thoughtSignature,
                                    );
                                    if (part.text.length > 0) {
                                        eventStream.push({
                                            type: "thinking_delta",
                                            contentIndex: blockIndex(),
                                            delta: part.text,
                                            partial: output,
                                        });
                                    }
                                } else {
                                    currentBlock.text += part.text;
                                    currentBlock.textSignature = retainThoughtSignature(
                                        currentBlock.textSignature,
                                        part.thoughtSignature,
                                    );
                                    if (part.text.length > 0) {
                                        eventStream.push({
                                            type: "text_delta",
                                            contentIndex: blockIndex(),
                                            delta: part.text,
                                            partial: output,
                                        });
                                    }
                                }
                            }

                            if (part.functionCall) {
                                closeCurrentBlock();
                                const providedId = part.functionCall.id;
                                const needsNewId =
                                    !providedId ||
                                    output.content.some(
                                        (b) => b.type === "toolCall" && b.id === providedId,
                                    );
                                const toolCallId = needsNewId
                                    ? `${part.functionCall.name}_${Date.now()}_${++toolCallCounter}`
                                    : providedId;
                                const toolCall = {
                                    type: "toolCall",
                                    id: toolCallId,
                                    name: part.functionCall.name || "",
                                    arguments: part.functionCall.args ?? {},
                                    ...(part.thoughtSignature && {
                                        thoughtSignature: part.thoughtSignature,
                                    }),
                                };
                                output.content.push(toolCall);
                                eventStream.push({
                                    type: "toolcall_start",
                                    contentIndex: blockIndex(),
                                    partial: output,
                                });
                                eventStream.push({
                                    type: "toolcall_delta",
                                    contentIndex: blockIndex(),
                                    delta: JSON.stringify(toolCall.arguments),
                                    partial: output,
                                });
                                eventStream.push({
                                    type: "toolcall_end",
                                    contentIndex: blockIndex(),
                                    toolCall,
                                    partial: output,
                                });
                            }
                        }
                    }

                    if (candidate?.finishReason) {
                        output.rawStopReason = candidate.finishReason;
                        output.stopReason = mapStopReasonString(candidate.finishReason);
                        if (
                            output.content.some((b) => b.type === "toolCall") &&
                            output.stopReason === "stop"
                        ) {
                            output.stopReason = "toolUse";
                        }
                    }

                    if (responseData.usageMetadata) {
                        const u = responseData.usageMetadata;
                        output.usage = {
                            input: (u.promptTokenCount || 0) - (u.cachedContentTokenCount || 0),
                            output: (u.candidatesTokenCount || 0) + (u.thoughtsTokenCount || 0),
                            cacheRead: u.cachedContentTokenCount || 0,
                            cacheWrite: 0,
                            reasoning: u.thoughtsTokenCount || 0,
                            totalTokens: u.totalTokenCount || 0,
                            cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 },
                        };
                        calculateCost(model, output.usage);
                    }
                }
            }

            closeCurrentBlock();

            if (options?.signal?.aborted) {
                throw new Error("Request was aborted");
            }
            if (output.stopReason === "pending") {
                output.stopReason = output.content.some((b) => b.type === "toolCall")
                    ? "toolUse"
                    : "stop";
            }
            if (output.stopReason === "aborted" || output.stopReason === "error") {
                throw new Error(
                    output.rawStopReason
                        ? `Antigravity stopped with: ${output.rawStopReason}`
                        : "Antigravity stream error",
                );
            }

            eventStream.push({ type: "done", reason: output.stopReason, message: output });
            eventStream.end();
        } catch (error) {
            output.stopReason = options?.signal?.aborted ? "aborted" : "error";
            output.errorMessage = formatProviderError(normalizeProviderError(error));
            eventStream.push({ type: "error", reason: output.stopReason, error: output });
            eventStream.end();
        }
    })();

    return eventStream;
};

function getThinkingBudget(modelId, level, customBudgets) {
    if (customBudgets?.[level] !== undefined) return customBudgets[level];
    if (modelId in GROUPED_THINKING_VARIANTS) {
        return undefined;
    }
    const budgets = {
        minimal: 1024,
        low: 4096,
        medium: 8192,
        high: 24576,
    };
    return budgets[level];
}

export const streamSimple = (model, context, options) => {
    const apiKey = options?.apiKey || process.env.ANTIGRAVITY_OAUTH_TOKEN || "local-antigravity-oauth";
    const base = {
        ...buildBaseOptions(model, context, options, apiKey),
        toolChoice: options?.toolChoice,
    };

    if (!options?.reasoning) {
        return stream(model, context, { ...base, thinking: { enabled: false } });
    }
    const clamped = clampThinkingLevel(model, options.reasoning);
    if (clamped === "off") {
        return stream(model, context, { ...base, thinking: { enabled: false } });
    }

    return stream(model, context, {
        ...base,
        thinking: {
            enabled: true,
            level: clamped,
            budgetTokens: getThinkingBudget(model.id, clamped, options?.thinkingBudgets),
        },
    });
};

export function antigravityProvider() {
    bootstrapAntigravityEnv();
    return createProvider({
        id: "antigravity",
        name: "Antigravity",
        baseUrl: BASE_URL,
        auth: {
            apiKey: {
                name: "Antigravity OAuth",
                login: async (interaction) => {
                    interaction.signal.throwIfAborted();
                    const key = await interaction.prompt({
                        type: "secret",
                        message: "Enter Antigravity OAuth refresh token or leave local token file",
                    });
                    interaction.signal.throwIfAborted();
                    return { type: "api_key", key };
                },
                resolve: async ({ ctx, credential, signal }) => {
                    signal.throwIfAborted();
                    if (credential?.key) {
                        return {
                            auth: { apiKey: credential.key },
                            env: credential.env,
                            source: "stored credential",
                        };
                    }
                    const envVal = await ctx.env("ANTIGRAVITY_OAUTH_TOKEN");
                    if (envVal) {
                        return { auth: { apiKey: envVal }, source: "ANTIGRAVITY_OAUTH_TOKEN" };
                    }
                    if (findLocalTokenFile()) {
                        return {
                            auth: { apiKey: "local-antigravity-oauth" },
                            source: "local-oauth-file",
                        };
                    }
                    return undefined;
                },
            },
        },
        models: ANTIGRAVITY_MODELS,
        api: { stream, streamSimple },
    });
}
