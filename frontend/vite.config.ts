import { fileURLToPath, URL } from 'node:url'

import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import vueDevTools from 'vite-plugin-vue-devtools'

// https://vite.dev/config/
export default defineConfig({
  plugins: [vue(), vueDevTools()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
  server: {
    host: true,
    allowedHosts: ['localhost', '.ngrok-free.app', '.ngrok-free.dev', '.ngrok.app', '.ngrok.io'],
    proxy: {
      // Proxy API requests to backend
      // Note: This proxy runs on the SERVER (where Vite is), not in the browser
      // External browsers make requests to the ngrok URL, which Vite then proxies to the backend
      '/api': {
        // Use Docker service name if Vite is in Docker, otherwise localhost (backend port is exposed)
        target: process.env.DOCKER ? 'http://api:3000' : 'http://localhost:3000',
        changeOrigin: true,
        secure: false,
      },
      // Proxy WebSocket (ActionCable) to backend
      '/cable': {
        target: process.env.DOCKER ? 'ws://api:3000' : 'ws://localhost:3000',
        ws: true,
        changeOrigin: true,
        secure: false,
      },
    },
  },
})
