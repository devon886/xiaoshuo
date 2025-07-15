<template>
  <div class="writing-page">
    <div class="writing-header">
      <h1>{{ novelTitle }}</h1>
      <div class="chapter-info">
        <span>章节 {{ chapterNumber }}: {{ chapterTitle }}</span>
        <div class="collaboration-status" :class="{ active: isConnected }">
          {{ isConnected ? '已连接' : '未连接' }}
        </div>
      </div>
      <div class="collaborators">
        <div v-for="user in activeCollaborators" :key="user.id" class="collaborator">
          <div class="user-avatar" :style="{ backgroundColor: user.color }">
            {{ user.name.charAt(0) }}
          </div>
        </div>
      </div>
    </div>

    <div class="writing-content">
      <textarea
        v-model="content"
        @input="handleContentChange"
        @keyup="handleCursorPosition"
        @click="handleCursorPosition"
        placeholder="开始创作你的故事..."
        ref="editor"
      ></textarea>
    </div>

    <div class="writing-actions">
      <div class="save-status" v-if="saveStatus">
        <span :class="saveStatusClass">{{ saveStatusText }}</span>
      </div>
      <button class="save-btn" @click="saveContent" :disabled="saveInProgress">保存</button>
      <button class="publish-btn" @click="publishChapter">发布</button>
    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent, ref, onMounted, onBeforeUnmount, computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import axios from 'axios';
import { createSocketService, getSocketService } from '../services/SocketService';
import type { RoomUser } from '../services/SocketService';

export default defineComponent({
  name: 'WritingPage',
  setup() {
    const route = useRoute();
    const router = useRouter();
    const novelId = route.params.novelId?.toString() || '';
    const chapterId = route.params.chapterId?.toString() || '';
    
    const isConnected = ref(false);
    const content = ref('');
    const editor = ref<HTMLTextAreaElement | null>(null);
    const novelTitle = ref('');
    const chapterTitle = ref('');
    const chapterNumber = ref(1);
    const roomId = `novel_${novelId}_chapter_${chapterId}`;
    const activeCollaborators = ref<RoomUser[]>([]);
    const lastSentContent = ref('');
    const debounceTimeout = ref<number | null>(null);
    const saveInProgress = ref(false);
    const saveStatus = ref<'saving' | 'saved' | 'error' | null>(null);
    
    const saveStatusText = computed(() => {
      switch (saveStatus.value) {
        case 'saving': return '正在保存...';
        case 'saved': return '所有更改已保存';
        case 'error': return '保存失败';
        default: return '';
      }
    });
    
    const saveStatusClass = computed(() => {
      switch (saveStatus.value) {
        case 'saving': return 'status-saving';
        case 'saved': return 'status-saved';
        case 'error': return 'status-error';
        default: return '';
      }
    });
    
    // 获取章节详情
    const fetchChapterDetails = async () => {
      try {
        const response = await axios.get(`../api/chapters/${chapterId}`);
        const chapter = response.data;
        
        content.value = chapter.content || '';
        lastSentContent.value = chapter.content || '';
        chapterTitle.value = chapter.title || '未命名章节';
        chapterNumber.value = chapter.chapterNumber || 1;
        
        // 获取小说标题
        if (chapter.novel) {
          const novelResponse = await axios.get(`../api/novels/${chapter.novel}`);
          novelTitle.value = novelResponse.data.title || '未命名小说';
        }
      } catch (error) {
        console.error('获取章节详情失败:', error);
      }
    };
    
    // 初始化Socket连接
    const initSocketConnection = async () => {
      try {
        // 创建并连接Socket服务
        createSocketService({ 
          serverUrl: 'http://localhost:5000'
        });
        
        const socketService = getSocketService();
        
        // 设置token用于身份验证
        socketService.setAuthToken(localStorage.getItem('token') || '');
        
        await socketService.connect();
        isConnected.value = socketService.isConnected();
        
        // 注册事件监听器
        socketService.on('save-success', (data: { chapterId: string, message: string }) => {
          if (data.chapterId === chapterId) {
            saveStatus.value = 'saved';
            saveInProgress.value = false;
            console.log('自动保存成功:', data.message);
          }
        });
        
        socketService.on('save-error', (data: { chapterId: string, message: string }) => {
          if (data.chapterId === chapterId) {
            saveStatus.value = 'error';
            saveInProgress.value = false;
            console.error('自动保存失败:', data.message);
          }
        });
        
        socketService.on('text-updated', (data: { text: string, cursorPosition?: number, userId: string }) => {
          // 只有当我们没有编辑时才更新内容
          if (document.activeElement !== editor.value) {
            content.value = data.text;
            lastSentContent.value = data.text;
          } else {
            console.log('收到更新，但由于正在编辑，未应用');
          }
        });
        
        socketService.on('user-connected', (data: { userId: string, userCount: number }) => {
          console.log('新用户加入:', data.userId);
          
          // 添加新协作者到列表
          activeCollaborators.value.push({
            id: data.userId,
            name: `用户${activeCollaborators.value.length + 1}`,
            color: getRandomColor()
          });
        });
        
        socketService.on('user-disconnected', (data: { userId: string, userCount: number }) => {
          console.log('用户离开:', data.userId);
          
          // 从列表中移除协作者
          const index = activeCollaborators.value.findIndex(user => user.id === data.userId);
          if (index !== -1) {
            activeCollaborators.value.splice(index, 1);
          }
        });
        
        // 加入协作房间
        socketService.joinRoom(roomId);
      } catch (error) {
        console.error('初始化Socket连接失败:', error);
        isConnected.value = false;
      }
    };
    
    // 处理内容变化
    const handleContentChange = () => {
      // 防抖处理，减少发送频率
      if (debounceTimeout.value !== null) {
        clearTimeout(debounceTimeout.value);
      }
      
      debounceTimeout.value = window.setTimeout(() => {
        // 只有当内容真正变化时才发送
        if (content.value !== lastSentContent.value) {
          saveStatus.value = 'saving';
          saveInProgress.value = true;
          
          try {
            const socketService = getSocketService();
            
            // 发送保存章节事件
            socketService.emit('save-chapter', {
              chapterId: chapterId,
              title: chapterTitle.value,
              content: content.value,
              chapterNumber: chapterNumber.value
            });
            
            lastSentContent.value = content.value;
          } catch (error) {
            console.error('发送文本更新失败:', error);
            saveStatus.value = 'error';
            saveInProgress.value = false;
          }
        }
        debounceTimeout.value = null;
      }, 2000); // 2秒后触发自动保存
    };
    
    // 处理光标位置变化
    const handleCursorPosition = () => {
      if (editor.value) {
        const cursorPosition = editor.value.selectionStart;
        // 可以发送光标位置给其他用户，实现协同编辑时的光标显示
        // 这里简化处理，不发送光标位置
      }
    };
    
    // 保存内容
    const saveContent = async () => {
      try {
        saveStatus.value = 'saving';
        saveInProgress.value = true;
        
        await axios.put(`../api/chapters/${chapterId}`, {
          title: chapterTitle.value,
          content: content.value,
          chapterNumber: chapterNumber.value
        });
        
        saveStatus.value = 'saved';
        lastSentContent.value = content.value;
      } catch (error) {
        console.error('保存失败:', error);
        saveStatus.value = 'error';
      } finally {
        saveInProgress.value = false;
      }
    };
    
    // 发布章节
    const publishChapter = async () => {
      try {
        // 先保存内容
        await saveContent();
        
        // 发布章节
        await axios.put(`../api/chapters/${chapterId}/publish`);
        
        alert('章节已发布');
        // 可以选择跳转到小说详情页
        // router.push(`/novel/${novelId}`);
      } catch (error) {
        console.error('发布失败:', error);
        alert('发布失败');
      }
    };
    
    // 生成随机颜色
    const getRandomColor = () => {
      const letters = '0123456789ABCDEF';
      let color = '#';
      for (let i = 0; i < 6; i++) {
        color += letters[Math.floor(Math.random() * 16)];
      }
      return color;
    };
    
    // 组件挂载时初始化连接
    onMounted(() => {
      if (chapterId) {
        fetchChapterDetails();
        initSocketConnection();
      } else {
        router.push('/');
      }
    });
    
    // 组件卸载前断开连接
    onBeforeUnmount(() => {
      try {
        if (debounceTimeout.value !== null) {
          clearTimeout(debounceTimeout.value);
        }
        
        const socketService = getSocketService();
        socketService.leaveRoom();
      } catch (error) {
        console.error('离开房间失败:', error);
      }
    });
    
    return {
      content,
      editor,
      novelTitle,
      chapterTitle,
      chapterNumber,
      isConnected,
      activeCollaborators,
      handleContentChange,
      handleCursorPosition,
      saveContent,
      publishChapter,
      saveStatus,
      saveStatusText,
      saveStatusClass,
      saveInProgress
    };
  }
});
</script>

<style scoped>
.writing-page {
  max-width: 900px;
  margin: 0 auto;
  padding: 20px;
}

.writing-header {
  margin-bottom: 20px;
}

.writing-header h1 {
  margin-bottom: 10px;
}

.chapter-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 15px;
}

.collaboration-status {
  padding: 5px 10px;
  border-radius: 15px;
  font-size: 14px;
  background-color: #f44336;
  color: white;
}

.collaboration-status.active {
  background-color: #4caf50;
}

.collaborators {
  display: flex;
  gap: 10px;
  margin-top: 10px;
}

.collaborator {
  display: flex;
  align-items: center;
}

.user-avatar {
  width: 30px;
  height: 30px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-weight: bold;
}

.writing-content {
  margin-bottom: 20px;
}

.writing-content textarea {
  width: 100%;
  min-height: 500px;
  padding: 15px;
  font-size: 16px;
  line-height: 1.6;
  border: 1px solid #ddd;
  border-radius: 5px;
  resize: vertical;
}

.writing-actions {
  display: flex;
  gap: 15px;
  justify-content: flex-end;
  align-items: center;
}

.save-status {
  margin-right: auto;
  font-size: 14px;
}

.status-saving {
  color: #2196f3;
}

.status-saved {
  color: #4caf50;
}

.status-error {
  color: #f44336;
}

button {
  padding: 10px 20px;
  border: none;
  border-radius: 5px;
  cursor: pointer;
  font-size: 16px;
  transition: background-color 0.3s;
}

button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.save-btn {
  background-color: #2196f3;
  color: white;
}

.save-btn:hover:not(:disabled) {
  background-color: #0b7dda;
}

.publish-btn {
  background-color: #4caf50;
  color: white;
}

.publish-btn:hover {
  background-color: #45a049;
}

@media (max-width: 768px) {
  .writing-page {
    padding: 10px;
  }
  
  .writing-content textarea {
    min-height: 300px;
  }
}
</style> 
