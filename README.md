# 🛡️ Luavion Web Application & Obfuscation Platform

> **Next-Generation Luau Bytecode Virtualization**  
> Decentralized Register VM with Cryptographic Geometric Attestation. Engineered to defeat AST dumpers, control-flow deswitchers, and sandbox introspection.

---

## ⚡ Tech Stack & Architecture

- **Frontend**: [Nuxt 3](https://nuxt.com/) (Vue 3, Vue Router, Composition API)
- **Backend / Serverless**: [Nitro](https://nitro.unjs.io/) (Node.js engine running Wasmoon WebAssembly Luau VM)
- **Deployment**: [Vercel](https://vercel.com/) (Native Serverless Functions via `@vercel/nft`)
- **Typography & Design System**: Geist Mono throughout, Dark-first Linear/Vercel precision aesthetic

---

## 🚀 Running Locally

1. **Navigate to the project directory**:
   ```bash
   cd luavion
   ```

2. **Install dependencies** (if not already installed):
   ```bash
   npm install
   ```

3. **Start the development server**:
   ```bash
   npm run dev -- -p 3344
   ```
   Open [http://localhost:3344](http://localhost:3344) in your browser.

4. **Production Build Test**:
   ```bash
   npm run build
   ```

---

## ☁️ Deploying to Vercel

### Option 1: Vercel CLI (Fastest)
```bash
cd luavion
npm i -g vercel
vercel
```

### Option 2: GitHub / Git Push
1. Push your repository to GitHub / GitLab.
2. In the Vercel dashboard, click **"Add New Project"** and select your repository.
3. If `luavion/` is inside a subdirectory, set **Root Directory** to `luavion`.
4. Framework Preset will automatically detect **Nuxt.js**.
5. Click **Deploy**!

---

## 🧭 Pages & Routes

- `/` — **Landing Page**:
  - Hero introduction
  - Live interactive obfuscation preview
  - Core defensive pillars (Decentralized Register VM, Geometric Attestation, MBA Expressions, Ephemeral Ring)
  - Security architecture deep-dive (defeating CFG deswitchers and fail-closed sandbox detection)
  - Objective comparison matrix (**Luavion vs Prometheus vs Moonsec vs Luraph**)
  - Comprehensive FAQ accordion
- `/app` — **Obfuscator Studio**:
  - Dual-pane layout: Input on the left, protected output on the right
  - Drag-and-drop file upload (`.lua`, `.luau`, `.txt`)
  - Preset selector (`BALANCED`, `EXTREME`, `HARD`, `PERFORMANCE`, `COMPATIBLE`, `MINIFY`)
  - Target VM toggle (`Luau` vs `Lua 5.1`)
  - Seed randomizer and PrettyPrint toggles
  - One-click copy with toast notification
  - Download `.lua` button
  - Real-time compiler statistics (latency ms, size expansion ratio, byte counts)
  - Collapsible compiler pipeline step drawer

---

## 🔒 Security Presets

| Preset | Security Level | VM Profile | Description |
| :--- | :--- | :--- | :--- |
| **BALANCED** *(Recommended)* | High | `STRONG` | Register VM + Polymorphic String Escapes + MBA Expressions + Roblox Geometric Attestation. |
| **EXTREME** | Military-Grade | `EXTREME` | Dynamic Galois opcode buckets + Opaque predicates + Dead-code injection + Strict float attestation. |
| **HARD** | Very High | `HARD` | API reflection hashing + Anti-proxy probes + Hardened VM. |
| **PERFORMANCE** | Standard | `PERFORMANCE` | Low GC overhead designed for high-frequency physics, autofarm, and render loops. |
| **COMPATIBLE** | Safe | `SAFE` | Maximum portability across legacy Lua 5.1 and all mobile/desktop executors. |
| **MINIFY** | None | `None` | Fast whitespace compression and variable mangling without virtualization. |
