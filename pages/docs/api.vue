<template>
  <div class="api-docs-page">
    <div class="container docs-container">
      <!-- Breadcrumbs / Header -->
      <div class="docs-header">
        <div class="docs-tag">
          <span class="status-dot dot-cyan"></span>
          <span>DEVELOPER PLATFORM REFERENCE</span>
        </div>
        <h1 class="docs-title">Luavion REST API Documentation</h1>
        <p class="docs-subtitle">
          Wire programmatic bytecode virtualization directly into your GitHub Actions, GitLab CI/CD pipelines, and automated Roblox deployment workflows.
        </p>

        <!-- Ultra Sales Banner -->
        <div class="ultra-feature-callout surface">
          <div class="callout-icon">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M21 2l-2 2m-7.61 7.61a5.5 5.5 0 1 1-7.778 7.778 5.5 5.5 0 0 1 7.777-7.777zm0 0L15.5 7.5m0 0l3 3L22 7l-3-3m-3.5 3.5L19 4"></path>
            </svg>
          </div>
          <div class="callout-text">
            <span class="callout-title">Ultra Plan Feature</span>
            <p class="callout-desc">
              API keys and programmatic REST endpoints are available exclusively on the <strong>Ultra Plan</strong> ($30/mo or Rp 500,000/mo).
            </p>
          </div>
          <NuxtLink to="/pricing" class="btn btn-sm btn-ultra">
            Upgrade to Ultra
          </NuxtLink>
        </div>
      </div>

      <div class="docs-layout">
        <!-- Sidebar Navigation -->
        <aside class="docs-sidebar">
          <div class="sidebar-section">
            <span class="sidebar-heading">GETTING STARTED</span>
            <a href="#overview" class="sidebar-link">Overview & Base URL</a>
            <a href="#authentication" class="sidebar-link">Authentication</a>
            <a href="#rate-limits" class="sidebar-link">Rate Limits</a>
          </div>

          <div class="sidebar-section">
            <span class="sidebar-heading">ENDPOINTS</span>
            <a href="#post-obfuscate" class="sidebar-link">
              <span class="method-tag post">POST</span>
              <span>/api/v1/obfuscate</span>
            </a>
            <a href="#get-usage" class="sidebar-link">
              <span class="method-tag get">GET</span>
              <span>/api/v1/usage</span>
            </a>
          </div>

          <div class="sidebar-section">
            <span class="sidebar-heading">INTEGRATIONS</span>
            <a href="#code-examples" class="sidebar-link">Code Examples</a>
            <a href="#errors" class="sidebar-link">Error Codes</a>
          </div>
        </aside>

        <!-- Main Content Area -->
        <main class="docs-content">
          <!-- Overview Section -->
          <section id="overview" class="docs-card surface">
            <h2 class="card-heading">1. Overview & Base URL</h2>
            <p class="card-p">
              The Luavion REST API provides synchronous execution of our decentralized register compiler. All requests must be made over HTTPS and use JSON formatting.
            </p>
            <div class="code-box">
              <div class="code-box-header">
                <span class="code-lang">PRODUCTION BASE URL</span>
              </div>
              <pre class="code-pre"><code>https://luavion.com/api/v1</code></pre>
            </div>
          </section>

          <!-- Authentication Section -->
          <section id="authentication" class="docs-card surface">
            <h2 class="card-heading">2. Authentication</h2>
            <p class="card-p">
              Authenticate API requests by including your secret API key in the <code class="code-inline">Authorization</code> header using the standard <code class="code-inline">Bearer</code> scheme.
            </p>
            <div class="code-box">
              <div class="code-box-header">
                <span class="code-lang">HEADER FORMAT</span>
              </div>
              <pre class="code-pre"><code>Authorization: Bearer lua_live_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx</code></pre>
            </div>
            <p class="card-note">
              Ultra customers can generate and manage API keys inside the <NuxtLink to="/keys" class="link-cyan">API Keys Dashboard</NuxtLink>.
            </p>
          </section>

          <!-- Rate Limits Section -->
          <section id="rate-limits" class="docs-card surface">
            <h2 class="card-heading">3. Rate Limiting</h2>
            <p class="card-p">
              API requests are rate limited to <strong>60 requests per minute</strong> per key. If your request exceeds this threshold, the API will return HTTP status code <code class="code-inline">429 Too Many Requests</code>.
            </p>
          </section>

          <!-- POST /api/v1/obfuscate Section -->
          <section id="post-obfuscate" class="docs-card surface">
            <div class="endpoint-badge-row">
              <span class="method-tag post">POST</span>
              <span class="endpoint-path">/api/v1/obfuscate</span>
            </div>
            <h2 class="card-heading">Obfuscate Script</h2>
            <p class="card-p">
              Submits raw Lua/Luau source code and returns the cryptographically compiled payload with telemetry metrics.
            </p>

            <h3 class="sub-heading">Request Parameters (JSON Body)</h3>
            <div class="params-table-wrap">
              <table class="params-table">
                <thead>
                  <tr>
                    <th>Field</th>
                    <th>Type</th>
                    <th>Required</th>
                    <th>Description</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td><code class="param-name">source</code></td>
                    <td>string</td>
                    <td>Yes</td>
                    <td>Raw Lua / Luau source code string to protect.</td>
                  </tr>
                  <tr>
                    <td><code class="param-name">preset</code></td>
                    <td>string</td>
                    <td>No</td>
                    <td>Security preset: <code class="code-inline">BALANCED</code>, <code class="code-inline">HARD</code>, <code class="code-inline">EXTREME</code>, <code class="code-inline">PERFORMANCE</code>, <code class="code-inline">COMPATIBLE</code>, <code class="code-inline">MINIFY</code> (Default: <code class="code-inline">BALANCED</code>).</td>
                  </tr>
                  <tr>
                    <td><code class="param-name">luaVersion</code></td>
                    <td>string</td>
                    <td>No</td>
                    <td>Target runtime: <code class="code-inline">LuaU</code> or <code class="code-inline">Lua51</code> (Default: <code class="code-inline">LuaU</code>).</td>
                  </tr>
                  <tr>
                    <td><code class="param-name">filename</code></td>
                    <td>string</td>
                    <td>No</td>
                    <td>Virtual filename (Default: <code class="code-inline">script.lua</code>).</td>
                  </tr>
                  <tr>
                    <td><code class="param-name">includeBanner</code></td>
                    <td>boolean</td>
                    <td>No</td>
                    <td>Whether to include the watermark and prompt shield (Default: <code class="code-inline">true</code>).</td>
                  </tr>
                </tbody>
              </table>
            </div>

            <h3 class="sub-heading">Example Request</h3>
            <div class="code-box">
              <div class="code-box-header">
                <span class="code-lang">JSON</span>
              </div>
              <pre class="code-pre"><code>{
  "source": "local combat = {}; function combat.strike(target) print('Attacking ' .. target) end; return combat;",
  "preset": "EXTREME",
  "luaVersion": "LuaU"
}</code></pre>
            </div>

            <h3 class="sub-heading">Example Response (200 OK)</h3>
            <div class="code-box">
              <div class="code-box-header">
                <span class="code-lang">JSON RESPONSE</span>
              </div>
              <pre class="code-pre"><code>{
  "ok": true,
  "output": "-- This file was protected using Luavion Obfuscator v9.15.0 https://luavion.com\n--[[...]]\nreturn(function(k,l,m)...end)(...)",
  "stats": {
    "originalBytes": 105,
    "obfuscatedBytes": 1420,
    "expansionRatio": 13.5,
    "durationMs": 42.1,
    "preset": "EXTREME",
    "luaVersion": "LuaU",
    "seed": 948201
  },
  "quota": {
    "used": 42,
    "limit": 7500,
    "remaining": 7458
  }
}</code></pre>
            </div>
          </section>

          <!-- GET /api/v1/usage Section -->
          <section id="get-usage" class="docs-card surface">
            <div class="endpoint-badge-row">
              <span class="method-tag get">GET</span>
              <span class="endpoint-path">/api/v1/usage</span>
            </div>
            <h2 class="card-heading">Check Quota & Key Status</h2>
            <p class="card-p">
              Returns the remaining monthly quota, top-up balance, and active rate limits for the provided API key.
            </p>

            <h3 class="sub-heading">Example Response</h3>
            <div class="code-box">
              <div class="code-box-header">
                <span class="code-lang">JSON RESPONSE</span>
              </div>
              <pre class="code-pre"><code>{
  "ok": true,
  "plan": "ultra",
  "keyName": "GitHub Actions Release",
  "keyPrefix": "lua_live_7a9f...301a",
  "rateLimitPerMinute": 60,
  "quota": {
    "usedThisMonth": 320,
    "monthlyLimit": 7500,
    "topUpBalance": 100,
    "totalRemaining": 7280
  }
}</code></pre>
            </div>
          </section>

          <!-- Code Examples Section -->
          <section id="code-examples" class="docs-card surface">
            <h2 class="card-heading">4. Multi-Language Code Examples</h2>
            <div class="lang-tabs">
              <button 
                class="lang-tab" 
                :class="{ active: activeTab === 'curl' }"
                @click="activeTab = 'curl'"
              >
                cURL
              </button>
              <button 
                class="lang-tab" 
                :class="{ active: activeTab === 'node' }"
                @click="activeTab = 'node'"
              >
                Node.js
              </button>
              <button 
                class="lang-tab" 
                :class="{ active: activeTab === 'python' }"
                @click="activeTab = 'python'"
              >
                Python
              </button>
              <button 
                class="lang-tab" 
                :class="{ active: activeTab === 'lua' }"
                @click="activeTab = 'lua'"
              >
                Roblox Luau
              </button>
            </div>

            <!-- cURL Sample -->
            <div v-if="activeTab === 'curl'" class="code-box">
              <pre class="code-pre"><code>curl -X POST https://luavion.com/api/v1/obfuscate \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "source": "local key = \"secret\"; print(key)",
    "preset": "EXTREME",
    "luaVersion": "LuaU"
  }'</code></pre>
            </div>

            <!-- Node.js Sample -->
            <div v-if="activeTab === 'node'" class="code-box">
              <pre class="code-pre"><code>import fs from 'fs';

const sourceCode = fs.readFileSync('main.lua', 'utf8');

const res = await fetch('https://luavion.com/api/v1/obfuscate', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer ' + process.env.LUAVION_API_KEY,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    source: sourceCode,
    preset: 'EXTREME',
    luaVersion: 'LuaU'
  })
});

const data = await res.json();
if (data.ok) {
  fs.writeFileSync('main.protected.lua', data.output);
  console.log(`Protected script generated (${data.stats.durationMs}ms)`);
}</code></pre>
            </div>

            <!-- Python Sample -->
            <div v-if="activeTab === 'python'" class="code-box">
              <pre class="code-pre"><code>import requests

headers = {
    "Authorization": "Bearer YOUR_API_KEY",
    "Content-Type": "application/json"
}

payload = {
    "source": "print('Protected by Luavion API')",
    "preset": "EXTREME",
    "luaVersion": "LuaU"
}

response = requests.post("https://luavion.com/api/v1/obfuscate", json=payload, headers=headers)
data = response.json()

if data.get("ok"):
    with open("dist.lua", "w", encoding="utf-8") as f:
        f.write(data["output"])
    print(f"Compiled in {data['stats']['durationMs']}ms")</code></pre>
            </div>

            <!-- Roblox Luau Sample -->
            <div v-if="activeTab === 'lua'" class="code-box">
              <pre class="code-pre"><code>local HttpService = game:GetService("HttpService")

local function protectScript(rawLuaSource: string)
    local url = "https://luavion.com/api/v1/obfuscate"
    local body = HttpService:JSONEncode({
        source = rawLuaSource,
        preset = "BALANCED",
        luaVersion = "LuaU"
    })

    local response = HttpService:RequestAsync({
        Url = url,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["Authorization"] = "Bearer " .. "YOUR_API_KEY"
        },
        Body = body
    })

    if response.Success then
        local data = HttpService:JSONDecode(response.Body)
        return data.output
    end
    error("Obfuscation API failed: " .. response.StatusMessage)
end</code></pre>
            </div>
          </section>

          <!-- Error Codes Section -->
          <section id="errors" class="docs-card surface">
            <h2 class="card-heading">5. HTTP Error Codes</h2>
            <div class="params-table-wrap">
              <table class="params-table">
                <thead>
                  <tr>
                    <th>Status</th>
                    <th>Code Name</th>
                    <th>Meaning & Solution</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td><code class="param-status">400</code></td>
                    <td>Bad Request</td>
                    <td>Missing or invalid parameters (e.g. empty <code class="code-inline">source</code>).</td>
                  </tr>
                  <tr>
                    <td><code class="param-status">401</code></td>
                    <td>Unauthorized</td>
                    <td>Missing, malformed, or revoked API key in Authorization header.</td>
                  </tr>
                  <tr>
                    <td><code class="param-status">403</code></td>
                    <td>Forbidden</td>
                    <td>API key belongs to an account that is not on the Ultra plan, or monthly quota exceeded.</td>
                  </tr>
                  <tr>
                    <td><code class="param-status">413</code></td>
                    <td>Payload Too Large</td>
                    <td>Input script exceeds the 5 MB file size limit for Ultra.</td>
                  </tr>
                  <tr>
                    <td><code class="param-status">422</code></td>
                    <td>Unprocessable Entity</td>
                    <td>Syntax or parsing error in the submitted Lua source code.</td>
                  </tr>
                  <tr>
                    <td><code class="param-status">429</code></td>
                    <td>Too Many Requests</td>
                    <td>Rate limit exceeded (limit: 60 requests per minute).</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </section>
        </main>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const activeTab = ref('curl')

useHead({
  title: 'Public REST API Reference | Luavion Ultra',
  meta: [
    { name: 'description', content: 'Comprehensive developer documentation and REST API endpoint reference for Luavion Lua obfuscation platform.' }
  ]
})
</script>

<style scoped>
.api-docs-page {
  padding: 48px 0 96px;
  min-height: 80vh;
}

.docs-header {
  margin-bottom: 48px;
}

.docs-tag {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  font-size: 11px;
  font-weight: 600;
  color: var(--accent-cyan);
  letter-spacing: 0.08em;
  margin-bottom: 12px;
}

.docs-title {
  font-size: 32px;
  font-weight: 600;
  letter-spacing: -0.02em;
  color: #ffffff;
  margin-bottom: 12px;
}

.docs-subtitle {
  font-size: 14px;
  color: var(--text-secondary);
  max-width: 640px;
  line-height: 1.6;
  margin-bottom: 24px;
}

.ultra-feature-callout {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px 20px;
  border: 1px solid rgba(168, 85, 247, 0.4);
  background: rgba(168, 85, 247, 0.08);
  border-radius: var(--radius-md);
  flex-wrap: wrap;
}

.callout-icon {
  color: #c084fc;
}

.callout-text {
  flex: 1;
  min-width: 240px;
}

.callout-title {
  display: block;
  font-size: 12px;
  font-weight: 600;
  color: #ffffff;
  letter-spacing: 0.04em;
}

.callout-desc {
  font-size: 12px;
  color: var(--text-secondary);
}

.btn-ultra {
  background: linear-gradient(135deg, #a855f7, var(--accent));
  color: var(--bg-void);
  font-weight: 600;
  border: none;
}

/* Layout */
.docs-layout {
  display: grid;
  grid-template-columns: 240px 1fr;
  gap: 48px;
  align-items: flex-start;
}

.docs-sidebar {
  position: sticky;
  top: 84px;
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.sidebar-section {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.sidebar-heading {
  font-size: 10px;
  font-weight: 600;
  letter-spacing: 0.08em;
  color: var(--text-muted);
  margin-bottom: 4px;
}

.sidebar-link {
  color: var(--text-secondary);
  text-decoration: none;
  font-size: 12px;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 4px 0;
  transition: color var(--duration-fast);
}
.sidebar-link:hover {
  color: var(--accent-cyan);
}

.method-tag {
  font-size: 9px;
  font-weight: 600;
  padding: 2px 5px;
  border-radius: 3px;
  letter-spacing: 0.04em;
}

.method-tag.post {
  background: rgba(255,255,255,0.12);
  color: var(--accent-cyan);
}

.method-tag.get {
  background: rgba(16, 185, 129, 0.15);
  color: var(--status-emerald);
}

.docs-content {
  display: flex;
  flex-direction: column;
  gap: 32px;
}

.docs-card {
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-md);
  padding: 28px;
}

.card-heading {
  font-size: 18px;
  font-weight: 600;
  color: #ffffff;
  margin-bottom: 12px;
}

.sub-heading {
  font-size: 13px;
  font-weight: 600;
  color: #ffffff;
  margin: 20px 0 10px;
  letter-spacing: 0.02em;
}

.card-p {
  font-size: 13px;
  color: var(--text-secondary);
  line-height: 1.6;
  margin-bottom: 16px;
}

.card-note {
  font-size: 12px;
  color: var(--text-muted);
  margin-top: 10px;
}

.link-cyan {
  color: var(--accent-cyan);
  text-decoration: none;
}
.link-cyan:hover {
  text-decoration: underline;
}

.endpoint-badge-row {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 10px;
}

.endpoint-path {
  font-size: 14px;
  font-weight: 600;
  color: #ffffff;
}

/* Code Boxes */
.code-box {
  background: #04060a;
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-xs);
  overflow: hidden;
  margin-bottom: 16px;
}

.code-box-header {
  background: var(--bg-surface-raised);
  padding: 6px 12px;
  border-bottom: 1px solid var(--border-subtle);
}

.code-lang {
  font-size: 10px;
  font-weight: 600;
  letter-spacing: 0.06em;
  color: var(--text-muted);
}

.code-pre {
  padding: 14px;
  font-size: 12px;
  line-height: 1.6;
  overflow-x: auto;
  color: #e2e8f0;
}

/* Tables */
.params-table-wrap {
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-xs);
  overflow-x: auto;
  margin-bottom: 16px;
}

.params-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 12px;
}

.params-table th,
.params-table td {
  padding: 10px 14px;
  text-align: left;
  border-bottom: 1px solid var(--border-subtle);
}

.params-table th {
  background: var(--bg-surface-raised);
  font-size: 10px;
  font-weight: 600;
  color: var(--text-muted);
  letter-spacing: 0.05em;
}

.param-name {
  color: var(--accent-cyan);
}

.param-status {
  color: #fbbf24;
  font-weight: 600;
}

/* Lang Tabs */
.lang-tabs {
  display: flex;
  gap: 4px;
  margin-bottom: 12px;
  border-bottom: 1px solid var(--border-subtle);
  padding-bottom: 8px;
}

.lang-tab {
  background: transparent;
  border: none;
  color: var(--text-muted);
  font-size: 12px;
  font-weight: 600;
  padding: 6px 12px;
  border-radius: var(--radius-xs);
  cursor: pointer;
  font-family: inherit;
}
.lang-tab.active {
  background: var(--bg-surface-raised);
  color: var(--text-primary);
}

@media (max-width: 860px) {
  .docs-layout {
    grid-template-columns: 1fr;
  }
  .docs-sidebar {
    position: static;
    flex-direction: row;
    flex-wrap: wrap;
    gap: 24px;
  }
}
</style>
