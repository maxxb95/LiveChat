import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import { createConsumer } from '@rails/actioncable'

export interface Message {
  id: number
  content: string
  username?: string
  session_id: string
  created_at: string
  is_mine?: boolean
}

export const useChatStore = defineStore('chat', () => {
  const messages = ref<Message[]>([])
  const sessionId = ref<string>(generateSessionId())
  const isConnected = ref(false)
  const isLoading = ref(false)
  const error = ref<string | null>(null)
  let cable: any = null
  let subscription: any = null

  // Get API URL - use relative URLs when proxied through Vite, or absolute when needed
  function getApiUrl(): string {
    // If explicitly set via environment variable, use that
    if (import.meta.env.VITE_API_URL) {
      return import.meta.env.VITE_API_URL
    }

    // In development with Vite proxy, use relative URLs (empty string = same origin)
    // Vite will proxy /api and /cable requests to the backend
    if (import.meta.env.DEV) {
      return ''
    }

    // For production or when not using proxy, use the ngrok URL
    return 'https://uninwrapped-flossie-autarkical.ngrok-free.dev'
  }

  const API_URL = getApiUrl()

  // Debug: log the API URL being used
  console.log('🔍 API_URL:', API_URL || '(empty - using relative URLs)')

  // Get WebSocket URL - use relative path when API_URL is empty (proxied), otherwise convert http/https to ws/wss
  function getCableUrl(): string {
    if (!API_URL) {
      // Relative URL - browser will use same protocol/host
      return '/cable'
    }
    // Absolute URL - convert http/https to ws/wss
    return API_URL.replace(/^http/, 'ws').replace(/^https/, 'wss') + '/cable'
  }

  const CABLE_URL = getCableUrl()

  // Computed
  const messageCount = computed(() => messages.value.length)
  const hasMessages = computed(() => messages.value.length > 0)

  // Generate a unique session ID
  function generateSessionId(): string {
    return `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
  }

  // Initialize ActionCable connection
  function connect() {
    if (cable) {
      disconnect()
    }

    try {
      // Create consumer with session ID as query parameter
      // WebSocket connections in browsers don't support custom headers reliably
      const urlWithSession = `${CABLE_URL}?session_id=${encodeURIComponent(sessionId.value)}`
      cable = createConsumer(urlWithSession)
      error.value = null

      subscription = cable.subscriptions.create(
        { channel: 'ChatChannel' },
        {
          received(data: Message) {
            // Mark message as mine if it matches our session
            const message = {
              ...data,
              is_mine: data.session_id === sessionId.value,
            }
            addMessage(message)
          },
          connected() {
            console.log('ActionCable connected')
            isConnected.value = true
          },
          disconnected() {
            console.log('ActionCable disconnected')
            isConnected.value = false
          },
        },
      )
    } catch (err: any) {
      error.value = err.message || 'Failed to connect to WebSocket'
      isConnected.value = false
      console.error('ActionCable connection error:', err)
    }
  }

  // Disconnect from ActionCable
  function disconnect() {
    if (subscription) {
      subscription.unsubscribe()
      subscription = null
    }
    if (cable) {
      cable.disconnect()
      cable = null
    }
    isConnected.value = false
  }

  // Add a message to the store
  function addMessage(message: Message) {
    // Check if message already exists (avoid duplicates)
    if (!messages.value.find((m) => m.id === message.id)) {
      messages.value.push(message)
      // Keep only last 100 messages in memory
      if (messages.value.length > 100) {
        messages.value = messages.value.slice(-100)
      }
    }
  }

  // Fetch messages from API
  async function fetchMessages() {
    isLoading.value = true
    error.value = null

    try {
      const response = await fetch(`${API_URL}/api/messages`, {
        headers: {
          'X-Session-ID': sessionId.value,
          'Content-Type': 'application/json',
        },
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const data: Message[] = await response.json()
      // Mark messages as mine based on session_id
      messages.value = data.map((msg) => ({
        ...msg,
        is_mine: msg.session_id === sessionId.value,
      }))
      console.log('Fetched messages:', messages.value.length)
    } catch (err: any) {
      error.value = err.message || 'Failed to fetch messages'
      console.error('Error fetching messages:', err)
    } finally {
      isLoading.value = false
    }
  }

  // Send a new message
  async function sendMessage(content: string, username?: string) {
    if (!content.trim()) {
      return
    }

    isLoading.value = true
    error.value = null

    try {
      const response = await fetch(`${API_URL}/api/messages`, {
        method: 'POST',
        headers: {
          'X-Session-ID': sessionId.value,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: {
            content: content.trim(),
            username: username?.trim() || undefined,
          },
        }),
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.errors?.join(', ') || `HTTP error! status: ${response.status}`)
      }

      // Message will be added via ActionCable broadcast
      // But we can also add it optimistically if needed
      const data: Message = await response.json()
      const message = {
        ...data,
        is_mine: true,
      }
      addMessage(message)
    } catch (err: any) {
      error.value = err.message || 'Failed to send message'
      console.error('Error sending message:', err)
      throw err
    } finally {
      isLoading.value = false
    }
  }

  // Clear all messages
  function clearMessages() {
    messages.value = []
  }

  // Reset session (generate new session ID)
  function resetSession() {
    disconnect()
    sessionId.value = generateSessionId()
    clearMessages()
    connect()
    fetchMessages()
  }

  return {
    // State
    messages,
    sessionId,
    isConnected,
    isLoading,
    error,
    // Computed
    messageCount,
    hasMessages,
    // Actions
    connect,
    disconnect,
    fetchMessages,
    sendMessage,
    addMessage,
    clearMessages,
    resetSession,
  }
})
