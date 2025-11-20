<template>
  <div class="chat-container">
    <div class="chat-header">
      <h1>Chat</h1>
      <div class="chat-status">
        <span :class="['status-indicator', isConnected ? 'connected' : 'disconnected']"></span>
        <span class="status-text">
          {{ isConnected ? 'Connected' : 'Disconnected' }}
        </span>
        <button @click="resetSession" class="reset-btn" title="Reset Session">🔄</button>
      </div>
    </div>

    <div v-if="error" class="error-message">
      {{ error }}
    </div>

    <div ref="messagesContainer" class="messages-container">
      <div v-if="isLoading && !hasMessages" class="loading">Loading messages...</div>
      <div v-else-if="!hasMessages" class="empty-state">
        No messages yet. Start the conversation!
      </div>
      <div
        v-for="message in messages"
        :key="message.id"
        :class="['message', message.is_mine ? 'message-mine' : 'message-other']"
      >
        <div class="message-header">
          <span class="message-username">
            {{ message.username || 'Anonymous' }}
          </span>
          <span class="message-time">
            {{ formatTime(message.created_at) }}
          </span>
        </div>
        <div class="message-content">{{ message.content }}</div>
      </div>
    </div>

    <div class="chat-input-container">
      <div class="input-group">
        <input
          v-model="username"
          type="text"
          placeholder="Your name (optional)"
          class="username-input"
          @keyup.enter="focusMessageInput"
        />
        <div class="message-input-wrapper">
          <input
            ref="messageInput"
            v-model="messageText"
            type="text"
            placeholder="Type a message..."
            class="message-input"
            :disabled="isLoading"
            @keyup.enter="handleSendMessage"
          />
          <button
            @click="handleSendMessage"
            :disabled="isLoading || !messageText.trim()"
            class="send-button"
          >
            Send
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, nextTick, watch } from 'vue'
import { useChatStore } from '../stores/chat'

const chatStore = useChatStore()
const {
  messages,
  isConnected,
  isLoading,
  error,
  hasMessages,
  connect,
  disconnect,
  fetchMessages,
  sendMessage,
  resetSession: resetChatSession,
} = chatStore

const messageText = ref('')
const username = ref('')
const messagesContainer = ref<HTMLElement | null>(null)
const messageInput = ref<HTMLInputElement | null>(null)

// Scroll to bottom when new messages arrive
const scrollToBottom = () => {
  nextTick(() => {
    if (messagesContainer.value) {
      messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight
    }
  })
}

watch(
  messages,
  () => {
    scrollToBottom()
  },
  { deep: true },
)

const focusMessageInput = () => {
  messageInput.value?.focus()
}

const handleSendMessage = async () => {
  if (!messageText.value.trim() || isLoading.value) {
    return
  }

  const content = messageText.value
  messageText.value = ''

  try {
    await sendMessage(content, username.value || undefined)
    focusMessageInput()
  } catch (err) {
    // Error is already set in the store
    console.error('Failed to send message:', err)
  }
}

const formatTime = (dateString: string) => {
  const date = new Date(dateString)
  const now = new Date()
  const diff = now.getTime() - date.getTime()
  const seconds = Math.floor(diff / 1000)
  const minutes = Math.floor(seconds / 60)
  const hours = Math.floor(minutes / 60)

  if (seconds < 60) {
    return 'just now'
  } else if (minutes < 60) {
    return `${minutes}m ago`
  } else if (hours < 24) {
    return `${hours}h ago`
  } else {
    return date.toLocaleDateString()
  }
}

const resetSession = () => {
  if (confirm('Reset your session? You will get a new session ID.')) {
    resetChatSession()
    fetchMessages()
  }
}

onMounted(async () => {
  connect()
  console.log('Fetching messages on mount...')
  await fetchMessages()
  console.log('Messages after fetch:', messages.length)
  focusMessageInput()
})

onUnmounted(() => {
  disconnect()
})
</script>

<style scoped>
.chat-container {
  display: flex;
  flex-direction: column;
  height: 100vh;
  max-width: 800px;
  margin: 0 auto;
  background: #fff;
  box-shadow: 0 0 20px rgba(0, 0, 0, 0.1);
}

.chat-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem 1.5rem;
  border-bottom: 1px solid #e0e0e0;
  background: #f8f9fa;
}

.chat-header h1 {
  margin: 0;
  font-size: 1.5rem;
  font-weight: 600;
}

.chat-status {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.status-indicator {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: #dc3545;
}

.status-indicator.connected {
  background: #28a745;
}

.status-text {
  font-size: 0.875rem;
  color: #666;
}

.reset-btn {
  background: none;
  border: none;
  font-size: 1.2rem;
  cursor: pointer;
  padding: 0.25rem 0.5rem;
  border-radius: 4px;
  transition: background 0.2s;
}

.reset-btn:hover {
  background: #e0e0e0;
}

.error-message {
  padding: 0.75rem 1.5rem;
  background: #fee;
  color: #c33;
  border-bottom: 1px solid #fcc;
}

.messages-container {
  flex: 1;
  overflow-y: auto;
  padding: 1rem;
  display: flex;
  flex-direction: column;
  gap: 1rem;
  background: #fafafa;
}

.loading,
.empty-state {
  text-align: center;
  color: #999;
  padding: 2rem;
  font-style: italic;
}

.message {
  display: flex;
  flex-direction: column;
  max-width: 70%;
  padding: 0.75rem 1rem;
  border-radius: 12px;
  animation: slideIn 0.2s ease-out;
}

@keyframes slideIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.message-mine {
  align-self: flex-end;
  background: #007bff;
  color: white;
}

.message-other {
  align-self: flex-start;
  background: white;
  color: #333;
  border: 1px solid #e0e0e0;
}

.message-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.25rem;
  font-size: 0.75rem;
  opacity: 0.9;
}

.message-username {
  font-weight: 600;
}

.message-time {
  margin-left: 0.5rem;
}

.message-content {
  word-wrap: break-word;
  line-height: 1.4;
}

.chat-input-container {
  padding: 1rem 1.5rem;
  border-top: 1px solid #e0e0e0;
  background: #f8f9fa;
}

.input-group {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.username-input {
  padding: 0.5rem;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 0.875rem;
}

.message-input-wrapper {
  display: flex;
  gap: 0.5rem;
}

.message-input {
  flex: 1;
  padding: 0.75rem;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 1rem;
}

.message-input:focus {
  outline: none;
  border-color: #007bff;
  box-shadow: 0 0 0 3px rgba(0, 123, 255, 0.1);
}

.send-button {
  padding: 0.75rem 1.5rem;
  background: #007bff;
  color: white;
  border: none;
  border-radius: 6px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.2s;
}

.send-button:hover:not(:disabled) {
  background: #0056b3;
}

.send-button:disabled {
  background: #ccc;
  cursor: not-allowed;
}
</style>
