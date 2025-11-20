<script setup lang="ts">
import { ref } from 'vue'

const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:3000'
const getResponse = ref<string>('')
const postResponse = ref<string>('')
const loading = ref({ get: false, post: false })
const error = ref({ get: '', post: '' })

const testGet = async () => {
  loading.value.get = true
  error.value.get = ''
  getResponse.value = ''

  try {
    const response = await fetch(`${apiUrl}/test`)
    const data = await response.json()
    getResponse.value = JSON.stringify(data, null, 2)
  } catch (err) {
    error.value.get = err instanceof Error ? err.message : 'Failed to connect'
    getResponse.value = ''
  } finally {
    loading.value.get = false
  }
}

const testPost = async () => {
  loading.value.post = true
  error.value.post = ''
  postResponse.value = ''

  try {
    const response = await fetch(`${apiUrl}/test`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: 'Hello from frontend!',
        timestamp: new Date().toISOString(),
      }),
    })
    const data = await response.json()
    postResponse.value = JSON.stringify(data, null, 2)
  } catch (err) {
    error.value.post = err instanceof Error ? err.message : 'Failed to connect'
    postResponse.value = ''
  } finally {
    loading.value.post = false
  }
}
</script>

<template>
  <div class="test-connection">
    <h2>Backend Connection Test</h2>
    <p class="api-url">API URL: {{ apiUrl }}</p>

    <div class="test-section">
      <div class="test-controls">
        <h3>GET Request</h3>
        <button @click="testGet" :disabled="loading.get">
          {{ loading.get ? 'Testing...' : 'Test GET' }}
        </button>
      </div>
      <div v-if="error.get" class="error">{{ error.get }}</div>
      <pre v-if="getResponse" class="response">{{ getResponse }}</pre>
    </div>

    <div class="test-section">
      <div class="test-controls">
        <h3>POST Request</h3>
        <button @click="testPost" :disabled="loading.post">
          {{ loading.post ? 'Testing...' : 'Test POST' }}
        </button>
      </div>
      <div v-if="error.post" class="error">{{ error.post }}</div>
      <pre v-if="postResponse" class="response">{{ postResponse }}</pre>
    </div>
  </div>
</template>

<style scoped>
.test-connection {
  max-width: 800px;
  margin: 2rem auto;
  padding: 2rem;
}

.test-connection h2 {
  margin-bottom: 1rem;
  color: var(--color-heading);
}

.api-url {
  margin-bottom: 2rem;
  padding: 0.5rem;
  background: var(--color-background-soft);
  border-radius: 4px;
  font-family: monospace;
  font-size: 0.9rem;
}

.test-section {
  margin-bottom: 2rem;
  padding: 1.5rem;
  background: var(--color-background-soft);
  border-radius: 8px;
}

.test-controls {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 1rem;
}

.test-controls h3 {
  margin: 0;
  flex: 1;
}

button {
  padding: 0.5rem 1.5rem;
  background: #42b883;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 1rem;
  transition: background 0.2s;
}

button:hover:not(:disabled) {
  background: #35a372;
}

button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.error {
  color: #ff6b6b;
  margin: 1rem 0;
  padding: 0.5rem;
  background: rgba(255, 107, 107, 0.1);
  border-radius: 4px;
}

.response {
  margin-top: 1rem;
  padding: 1rem;
  background: var(--color-background);
  border: 1px solid var(--color-border);
  border-radius: 4px;
  overflow-x: auto;
  font-size: 0.9rem;
  line-height: 1.5;
}
</style>
