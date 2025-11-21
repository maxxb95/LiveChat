import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import { createConsumer } from '@rails/actioncable'

export interface Message {
  id: number
  content: string
  username?: string
  session_id: string
  ip_address?: string
  normalized_ip?: string
  created_at: string
  is_mine?: boolean
}

export const useChatStore = defineStore('chat', () => {
  const messages = ref<Message[]>([])
  const sessionId = ref<string>(generateSessionId())
  const userIpAddress = ref<string | null>(null)
  const userNormalizedIp = ref<string | null>(null)
  const isConnected = ref(true)
  const isLoading = ref(false)
  const error = ref<string | null>(null)
  const typingUsers = ref<Set<string>>(new Set())
  let cable: any = null
  let subscription: any = null

  const messageCount = computed(() => messages.value.length)
  const hasMessages = computed(() => messages.value.length > 0)

  // Generate a unique session ID
  function generateSessionId(): string {
    return `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
  }

  // Initialize ActionCable connection
  async function connect() {
    if (cable) {
      disconnect()
    }

    await fetchUserIp()

    try {
      cable = createConsumer('/cable')
      error.value = null

      subscription = cable.subscriptions.create(
        { channel: 'ChatChannel' },
        {
          received(data: any) {
            if (data.type === 'typing') {
              handleTypingEvent(data)
            } else {
              addMessage(data as Message)
            }
          },
          connected() {
            console.log('ActionCable connected')
            isConnected.value = true
            error.value = null
          },
          disconnected() {
            console.log('ActionCable disconnected')
            isConnected.value = false
          },
          rejected() {
            console.log('ActionCable subscription rejected')
            isConnected.value = false
            error.value = 'Connection rejected. Please try reconnecting.'
          },
        },
      )
    } catch (err: any) {
      error.value = err.message || 'Failed to connect to WebSocket'
      isConnected.value = false
      console.error('ActionCable connection error:', err)
    }
  }

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

  function addMessage(message: Message) {
    if (!messages.value.find((m) => m.id === message.id)) {
      messages.value.push(message)
      // TODO - Infinite scroll
      if (messages.value.length > 100) {
        messages.value = messages.value.slice(-100)
      }
    }
  }

  function handleTypingEvent(data: { normalized_ip?: string; is_typing: boolean }) {
    const userIp = data.normalized_ip
    // Ignore self typing
    if (!userIp || userIp === userNormalizedIp.value) {
      return
    }

    if (data.is_typing) {
      typingUsers.value.add(userIp)
    } else {
      typingUsers.value.delete(userIp)
    }
  }

  function sendTypingStatus(isTyping: boolean) {
    if (subscription) {
      subscription.perform('typing', { is_typing: isTyping })
    }
  }

  function clearTypingStatus() {
    if (userNormalizedIp.value) {
      typingUsers.value.delete(userNormalizedIp.value)
    }
  }

  async function fetchUserIp() {
    if (userIpAddress.value) {
      return userIpAddress.value
    }

    try {
      const response = await fetch(`/api/ip`, {
        headers: {
          'X-Session-ID': sessionId.value,
          'Content-Type': 'application/json',
        },
      })

      if (response.ok) {
        const data = await response.json()
        userIpAddress.value = data.ip_address
        userNormalizedIp.value = data.normalized_ip || data.ip_address
        return userIpAddress.value
      }
    } catch (err: any) {
      console.error('Error fetching user IP:', err)
    }
    return null
  }

  async function fetchMessages() {
    isLoading.value = true
    error.value = null

    try {
      const response = await fetch(`/api/messages`, {
        headers: {
          'X-Session-ID': sessionId.value,
          'Content-Type': 'application/json',
        },
      })

      if (!response.ok) {
        throw new Error(`Unknown HTTP error with status: ${response.status}`)
      }

      const responseData = await response.json()
      const data: Message[] = responseData.messages
      messages.value = data
    } catch (err: any) {
      error.value = err.message || 'Failed to fetch messages'
      console.error('Error fetching messages:', err)
    } finally {
      isLoading.value = false
    }
  }

  async function sendMessage(msg: string) {
    if (!msg.trim()) {
      return
    }

    isLoading.value = true
    error.value = null

    try {
      const response = await fetch(`/api/messages`, {
        method: 'POST',
        headers: {
          'X-Session-ID': sessionId.value,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: {
            content: msg.trim(),
          },
        }),
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(
          errorData.errors?.join(', ') || `Unknown HTTP error with status: ${response.status}`,
        )
      }
    } catch (err: any) {
      error.value = err.message || 'Failed to send message'
      console.error('Error sending message:', err)
      throw err
    } finally {
      isLoading.value = false
    }
  }

  function clearMessages() {
    messages.value = []
  }

  return {
    // State
    messages,
    sessionId,
    userIpAddress,
    userNormalizedIp,
    isConnected,
    isLoading,
    error,
    typingUsers,
    // Computed
    messageCount,
    hasMessages,
    // Actions
    connect,
    disconnect,
    fetchMessages,
    fetchUserIp,
    sendMessage,
    addMessage,
    sendTypingStatus,
    clearTypingStatus,
    clearMessages,
  }
})
