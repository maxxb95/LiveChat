<template>
  <div class="room-list-container">
    <div class="room-list-header">
      <h1>Chat Rooms</h1>
    </div>

    <div class="create-room-section">
      <h2>Create New Room</h2>
      <div class="create-room-form">
        <input
          v-model="newRoomName"
          type="text"
          placeholder="Enter room name..."
          class="room-name-input"
          :disabled="isCreating"
          @keyup.enter="handleCreateRoom"
        />
        <button
          @click="handleCreateRoom"
          :disabled="isCreating || !newRoomName.trim()"
          class="create-room-button"
        >
          {{ isCreating ? 'Creating...' : 'Create Room' }}
        </button>
      </div>
      <div v-if="createError" class="error-message">{{ createError }}</div>
    </div>

    <div class="rooms-section">
      <h2>Available Rooms</h2>
      <div v-if="isLoading" class="loading">Loading rooms...</div>
      <div v-else-if="error" class="error-message">{{ error }}</div>
      <div v-else-if="rooms.length === 0" class="empty-state">No rooms yet. Create one above!</div>
      <div v-else class="rooms-list">
        <div
          v-for="room in rooms"
          :key="room.id"
          class="room-item"
          @click="navigateToRoom(room.id)"
        >
          <div class="room-info">
            <h3 class="room-name">{{ room.name }}</h3>
            <p class="room-meta">Created {{ formatTime(room.created_at) }}</p>
          </div>
          <div class="room-arrow">→</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { formatDistanceToNow } from 'date-fns'

interface ChatRoom {
  id: number
  name: string
  created_at: string
  updated_at: string
}

const router = useRouter()
const rooms = ref<ChatRoom[]>([])
const newRoomName = ref('')
const isLoading = ref(false)
const isCreating = ref(false)
const error = ref<string | null>(null)
const createError = ref<string | null>(null)

const fetchRooms = async () => {
  isLoading.value = true
  error.value = null

  try {
    const response = await fetch('/api/chat_room_tables', {
      headers: {
        'Content-Type': 'application/json',
      },
    })

    if (!response.ok) {
      throw new Error(`Failed to fetch rooms: ${response.status}`)
    }

    const data: ChatRoom[] = await response.json()
    rooms.value = data
  } catch (err: any) {
    error.value = err.message || 'Failed to fetch rooms'
    console.error('Error fetching rooms:', err)
  } finally {
    isLoading.value = false
  }
}

const handleCreateRoom = async () => {
  if (!newRoomName.value.trim() || isCreating.value) {
    return
  }

  isCreating.value = true
  createError.value = null

  try {
    const response = await fetch('/api/chat_room_tables', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        chat_room_table: {
          name: newRoomName.value.trim(),
        },
      }),
    })

    if (!response.ok) {
      const errorData = await response.json()
      throw new Error(errorData.errors?.join(', ') || `Failed to create room: ${response.status}`)
    }

    const newRoom: ChatRoom = await response.json()
    rooms.value.push(newRoom)
    newRoomName.value = ''

    // Navigate to the newly created room
    navigateToRoom(newRoom.id)
  } catch (err: any) {
    createError.value = err.message || 'Failed to create room'
    console.error('Error creating room:', err)
  } finally {
    isCreating.value = false
  }
}

const navigateToRoom = (roomId: number) => {
  router.push(`/${roomId}`)
}

const formatTime = (dateString: string) => {
  if (dateString) {
    const date = new Date(dateString)
    return formatDistanceToNow(date, { addSuffix: true })
  }
  return dateString
}

onMounted(() => {
  fetchRooms()
})
</script>

<style scoped>
.room-list-container {
  max-width: 800px;
  margin: 0 auto;
  padding: 2rem;
  min-height: 100vh;
  background: #fafafa;
}

.room-list-header {
  margin-bottom: 2rem;
}

.room-list-header h1 {
  margin: 0;
  font-size: 2rem;
  font-weight: 600;
  color: #333;
}

.create-room-section {
  background: white;
  padding: 1.5rem;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  margin-bottom: 2rem;
}

.create-room-section h2 {
  margin: 0 0 1rem 0;
  font-size: 1.25rem;
  font-weight: 600;
  color: #333;
}

.create-room-form {
  display: flex;
  gap: 0.75rem;
  margin-bottom: 0.75rem;
}

.room-name-input {
  flex: 1;
  padding: 0.75rem;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 1rem;
}

.room-name-input:focus {
  outline: none;
  border-color: #007bff;
  box-shadow: 0 0 0 3px rgba(0, 123, 255, 0.1);
}

.create-room-button {
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

.create-room-button:hover:not(:disabled) {
  background: #0056b3;
}

.create-room-button:disabled {
  background: #ccc;
  cursor: not-allowed;
}

.rooms-section {
  background: white;
  padding: 1.5rem;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.rooms-section h2 {
  margin: 0 0 1rem 0;
  font-size: 1.25rem;
  font-weight: 600;
  color: #333;
}

.loading,
.empty-state {
  text-align: center;
  color: #999;
  padding: 2rem;
  font-style: italic;
}

.error-message {
  padding: 0.75rem;
  background: #fee;
  color: #c33;
  border-radius: 6px;
  margin-top: 0.75rem;
}

.rooms-list {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.room-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  border: 1px solid #e0e0e0;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s;
  background: white;
}

.room-item:hover {
  border-color: #007bff;
  background: #f8f9ff;
  transform: translateX(4px);
}

.room-info {
  flex: 1;
}

.room-name {
  margin: 0 0 0.25rem 0;
  font-size: 1.1rem;
  font-weight: 600;
  color: #333;
}

.room-meta {
  margin: 0;
  font-size: 0.875rem;
  color: #666;
}

.room-arrow {
  font-size: 1.5rem;
  color: #007bff;
  margin-left: 1rem;
}
</style>
