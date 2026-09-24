export default defineEventHandler(() => {
  return [
    {
      id: 'BALANCED',
      name: 'Balanced',
      badge: 'Recommended',
      security: 'High',
      vmProfile: 'STRONG',
      desc: 'Optimized Register VM with polymorphic string escapes, MBA expressions, and Roblox geometric math attestation.',
      features: ['Polymorphic String Escapes', 'MBA Expressions (0.25)', 'Roblox Math Attestation (COMPAT)', 'Strong Register VM', 'Troll Honeypots']
    },
    {
      id: 'EXTREME',
      name: 'Extreme',
      badge: 'Maximum Defense',
      security: 'Military-Grade',
      vmProfile: 'EXTREME',
      desc: 'Deep virtualization with Galois dynamic hash-bucket dispatching, anti-proxy probes, dead-code branches, and strict float attestation.',
      features: ['Dynamic Galois Dispatch', 'Roblox Math Attestation (STRICT)', 'Anti-Proxy Probes', 'Opaque Predicates', 'Dead Code Injection', 'Ephemeral String Ring']
    },
    {
      id: 'HARD',
      name: 'Hard',
      badge: 'Anti-Tamper',
      security: 'Very High',
      vmProfile: 'HARD',
      desc: 'Aggressive anti-hook and reflection defenses with environment API hashing and strict closure verification.',
      features: ['API Hashing', 'Anti-Proxy Probes', 'Roblox Math Attestation', 'Hardened Register VM']
    },
    {
      id: 'PERFORMANCE',
      name: 'Performance',
      badge: 'High FPS',
      security: 'Standard',
      vmProfile: 'PERFORMANCE',
      desc: 'Minimal runtime overhead designed for high-frequency loops (RenderStepped, raycasting, physics solvers).',
      features: ['Zero Frame-Drop VM', 'Troll Honeypots', 'Fast Opcode Pipeline', 'Low Memory Overhead']
    },
    {
      id: 'COMPATIBLE',
      name: 'Compatible',
      badge: 'Universal',
      security: 'Safe',
      vmProfile: 'SAFE',
      desc: 'Maximum portability across all Roblox executors and legacy Lua 5.1 environments.',
      features: ['Safe Register VM', 'Basic Expression Synthesis', 'Universal Luau/5.1 Support']
    },
    {
      id: 'MINIFY',
      name: 'Minify',
      badge: 'Raw AST',
      security: 'None (Minifier)',
      vmProfile: 'None',
      desc: 'Whitespace and identifier compression without virtualization. Lightweight code reduction.',
      features: ['Shuffled Mangled Identifiers', 'Whitespace Removal', 'No Runtime Overhead']
    }
  ]
})
