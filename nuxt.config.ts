// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2024-11-01',
  devtools: { enabled: false },

  app: {
    head: {
      title: 'Luavion | Next-Generation Luau Bytecode Virtualization',
      meta: [
        { charset: 'utf-8' },
        { name: 'viewport', content: 'width=device-width, initial-scale=1' },
        { name: 'description', content: 'Advanced Luau and Lua 5.1 bytecode virtualization with decentralized register VMs, geometric math attestation, and polymorphic execution flow.' }
      ],
      link: [
        { rel: 'preconnect', href: 'https://fonts.googleapis.com' },
        { rel: 'preconnect', href: 'https://fonts.gstatic.com', crossorigin: '' },
        { rel: 'stylesheet', href: 'https://fonts.googleapis.com/css2?family=Geist+Mono:wght@300;400;500;600;700&display=swap' }
      ]
    }
  },

  css: ['~/assets/css/main.css'],

  nitro: {
    preset: 'vercel',
    serverAssets: [
      {
        baseName: 'engine',
        dir: './server/engine'
      }
    ]
  }
})
