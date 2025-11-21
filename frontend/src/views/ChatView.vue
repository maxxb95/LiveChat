<template>
  <div class="chat-container">
    <div class="chat-header">
      <h1>Chat</h1>
      <div class="connection-status">
        <span
          :class="['status-indicator', isConnected ? 'status-connected' : 'status-disconnected']"
          :title="isConnected ? 'Connected' : 'Disconnected'"
        >
          <span class="status-dot"></span>
          <span class="status-text">{{ isConnected ? 'Connected' : 'Disconnected' }}</span>
        </span>
      </div>
    </div>

    <div v-if="error && isConnected" class="error-message">
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
        :class="['message', isMyMessage(message) ? 'message-mine' : 'message-other']"
      >
        <div class="message-header">
          <span class="message-username">
            {{ getMessageLabel(message) }}
          </span>
          <span class="message-time">
            {{ formatTime(message.created_at) }}
          </span>
        </div>
        <div class="message-content">{{ message.content }}</div>
      </div>
    </div>

    <div v-if="typingUsersList.length > 0" class="typing-indicator">
      <span class="typing-text">
        <span v-for="(user, index) in typingUsersList" :key="index">
          {{ user }}<span v-if="index < typingUsersList.length - 1">, </span>
        </span>
        <span v-if="typingUsersList.length === 1"> is typing...</span>
        <span v-else> are typing...</span>
      </span>
    </div>

    <div class="chat-input-container">
      <div class="message-input-wrapper">
        <input
          ref="messageInput"
          v-model="messageText"
          type="text"
          placeholder="Type a message..."
          class="message-input"
          :disabled="isLoading"
          @input="handleTyping"
          @keydown="handleTyping"
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
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, nextTick, watch, computed } from 'vue'
import { storeToRefs } from 'pinia'
import { formatDistanceToNow } from 'date-fns'
import { useChatStore } from '../stores/chat'

const chatStore = useChatStore()
// Use storeToRefs to maintain reactivity when destructuring
const { messages, isLoading, error, hasMessages, isConnected, typingUsers } = storeToRefs(chatStore)
const { connect, disconnect, fetchMessages, sendMessage, sendTypingStatus, clearTypingStatus } =
  chatStore

const messageText = ref('')
const messagesContainer = ref<HTMLElement | null>(null)
const messageInput = ref<HTMLInputElement | null>(null)

let typingTimeout: ReturnType<typeof setTimeout> | null = null
const TYPING_TIMEOUT = 3000

// List of typing users (excluding self)
const typingUsersList = computed(() => {
  return Array.from(typingUsers.value).map(() => 'Anonymous')
})

// Scroll to bottom of chat window when new messages arrive
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

const getMessageLabel = (message: { normalized_ip?: string; ip_address?: string }) => {
  return isMyMessage(message) ? 'You' : 'Anonymous'
}

const isMyMessage = (message: { normalized_ip?: string; ip_address?: string }) => {
  // Check if message is from user's IP using normalized IP for IPv6 privacy extension handling
  const userNormalizedIp = chatStore.userNormalizedIp
  const messageNormalizedIp = message.normalized_ip || message.ip_address
  return userNormalizedIp && messageNormalizedIp === userNormalizedIp
}

const handleTyping = () => {
  sendTypingStatus(true)

  if (typingTimeout) {
    clearTimeout(typingTimeout)
  }

  // Set timeout to send typing stopped after inactivity
  typingTimeout = setTimeout(() => {
    sendTypingStatus(false)
    typingTimeout = null
  }, TYPING_TIMEOUT)
}

const handleSendMessage = async () => {
  if (!messageText.value.trim() || isLoading.value) {
    return
  }

  if (typingTimeout) {
    clearTimeout(typingTimeout)
    typingTimeout = null
  }
  sendTypingStatus(false)
  clearTypingStatus()

  const content = messageText.value
  messageText.value = ''

  try {
    await sendMessage(content)
    focusMessageInput()
  } catch (err) {
    // Error is already set in the store
    console.error('Failed to send message:', err)
  }
}

const formatTime = (dateString: string) => {
  if (dateString) {
    const date = new Date(dateString)
    return formatDistanceToNow(date, { addSuffix: true })
  }
  return dateString
}

onMounted(async () => {
  connect()
  await fetchMessages()
  focusMessageInput()
})

onUnmounted(() => {
  if (typingTimeout) {
    clearTimeout(typingTimeout)
    sendTypingStatus(false)
  }
  disconnect()
})
</script>

<style scoped>
.chat-container {
  display: flex;
  flex-direction: column;
  height: 100vh;
  height: 100dvh; /* Dynamic viewport height for mobile browsers */
  width: 100vw;
  width: 100dvw; /* Dynamic viewport width for mobile browsers */
  background: #fff;
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
}

.chat-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem 1.5rem;
  border-bottom: 1px solid #e0e0e0;
  background: #f8f9fa;
  flex-shrink: 0;
  position: relative;
  z-index: 10;
}

.chat-header h1 {
  margin: 0;
  font-size: 1.5rem;
  font-weight: 600;
  color: #333;
}

.connection-status {
  display: flex;
  align-items: center;
}

.status-indicator {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.875rem;
  padding: 0.25rem 0.75rem;
  border-radius: 12px;
  transition: all 0.2s;
}

.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  display: inline-block;
  animation: pulse 2s infinite;
}

.status-connected .status-dot {
  background: #28a745;
  box-shadow: 0 0 0 0 rgba(40, 167, 69, 0.7);
}

.status-disconnected .status-dot {
  background: #dc3545;
  box-shadow: 0 0 0 0 rgba(220, 53, 69, 0.7);
  animation: pulse-red 2s infinite;
}

.status-text {
  font-weight: 500;
}

.status-connected {
  color: #28a745;
  background: rgba(40, 167, 69, 0.1);
}

.status-disconnected {
  color: #dc3545;
  background: rgba(220, 53, 69, 0.1);
}

@keyframes pulse {
  0% {
    box-shadow: 0 0 0 0 rgba(40, 167, 69, 0.7);
  }
  70% {
    box-shadow: 0 0 0 4px rgba(40, 167, 69, 0);
  }
  100% {
    box-shadow: 0 0 0 0 rgba(40, 167, 69, 0);
  }
}

@keyframes pulse-red {
  0% {
    box-shadow: 0 0 0 0 rgba(220, 53, 69, 0.7);
  }
  70% {
    box-shadow: 0 0 0 4px rgba(220, 53, 69, 0);
  }
  100% {
    box-shadow: 0 0 0 0 rgba(220, 53, 69, 0);
  }
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

.typing-indicator {
  padding: 0.5rem 1.5rem;
  background: #f0f0f0;
  border-top: 1px solid #e0e0e0;
  font-size: 0.875rem;
  color: #666;
  font-style: italic;
  min-height: 2rem;
  display: flex;
  align-items: center;
}

.typing-text {
  display: flex;
  align-items: center;
  gap: 0.25rem;
}

.chat-input-container {
  padding: 1rem 1.5rem;
  border-top: 1px solid #e0e0e0;
  background: #f8f9fa;
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
