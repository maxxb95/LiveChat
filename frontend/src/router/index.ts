import { createRouter, createWebHistory } from 'vue-router'
import ChatView from '../views/ChatView.vue'
import RoomListView from '../views/RoomListView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'rooms',
      component: RoomListView,
    },
    {
      path: '/:roomId',
      name: 'chat-room',
      component: ChatView,
    },
  ],
})

export default router
