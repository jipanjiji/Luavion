async function testPresets() {
  for (const preset of ['BALANCED', 'EXTREME', 'PERFORMANCE', 'COMPATIBLE']) {
    const payload = {
      source: 'local x = 42; print("Testing preset: " .. tostring(x));',
      preset,
      luaVersion: 'LuaU'
    };
    const res = await fetch('http://localhost:3344/api/obfuscate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });
    const data = await res.json();
    console.log(`[${preset}] Status: ${res.status}, Ok: ${data.ok}, Latency: ${data.stats?.durationMs}ms, Size: ${data.stats?.obfuscatedBytes} bytes`);
  }
}

testPresets();
