<template>
  <div class="novel-reader">
    <div v-if="loading" class="loading-container">
      <div class="loading">加载中...</div>
    </div>
    <div v-else-if="error" class="error-container">
      <div class="error">{{ error }}</div>
    </div>
    <div v-else>
      <div class="reader-header">
        <router-link to="/" class="back-link">
          <span class="back-icon">←</span> 返回首页
        </router-link>
        <h1>{{ novel.title }}</h1>
        <p class="author">作者: {{ getAuthorName(novel.author) }}</p>
      </div>
      
      <div class="chapter-content">
        <h2>{{ currentChapter.title }}</h2>
        <div class="content" v-html="currentChapter.content"></div>
      </div>
      
      <div class="reader-actions">
        <div class="navigation-buttons">
          <button 
            @click="prevChapter" 
            :disabled="!hasPrevChapter"
            class="nav-button"
          >
            上一章
          </button>
          <button 
            @click="nextChapter" 
            :disabled="!hasNextChapter"
            class="nav-button"
          >
            下一章
          </button>
        </div>
        
        <div class="edit-actions">
          <button @click="goToEditPage" class="edit-button">
            <span class="edit-icon">✎</span> 编辑章节
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent, ref, computed, onMounted, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import axios from 'axios';
import { showSuccessToast, showErrorToast } from '../utils/toast';

interface Author {
  _id: string;
  username: string;
  nickname?: string;
}

interface Chapter {
  _id: string;
  title: string;
  content: string;
  chapterNumber: number;
}

interface Novel {
  _id: string;
  title: string;
  slug?: string;
  author: Author | string;
  chapters: Chapter[] | { _id: string, title: string, chapterNumber: number }[];
}

export default defineComponent({
  name: 'NovelReader',
  setup() {
    const route = useRoute();
    const router = useRouter();
    
    const novel = ref<Novel>({
      _id: '',
      title: '',
      author: '',
      chapters: []
    });
    
    const currentChapter = ref<Chapter>({
      _id: '',
      title: '',
      content: '',
      chapterNumber: 0
    });
    
    const loading = ref(true);
    const error = ref<string | null>(null);
    const currentChapterId = ref<string | null>(null);
    
    // 获取小说详情
    const fetchNovel = async () => {
      try {
        loading.value = true;
        error.value = null;
        
        const idOrSlug = route.params.id as string;
        const response = await axios.get(`http://localhost:5000/api/novels/${idOrSlug}`);
        novel.value = response.data;
        
        // 处理章节查询参数
        const chapterQuery = route.query.chapter as string;
        
        if (chapterQuery && novel.value.chapters) {
          // 如果URL中有章节参数，查找对应章节
          const chapter = novel.value.chapters.find(c => c._id === chapterQuery);
          if (chapter) {
            currentChapterId.value = chapter._id;
          } else {
            // 如果找不到指定章节，默认加载第一章
            currentChapterId.value = novel.value.chapters[0]?._id || null;
          }
        } else {
          // 默认加载第一章
          currentChapterId.value = novel.value.chapters[0]?._id || null;
        }
        
        // 如果有章节ID，加载章节内容
        if (currentChapterId.value) {
          await fetchChapter(currentChapterId.value);
        } else {
          error.value = '未找到章节内容';
        }
        
        loading.value = false;
      } catch (err) {
        console.error('获取小说详情失败:', err);
        error.value = '获取小说详情失败，请稍后再试';
        loading.value = false;
      }
    };
    
    // 获取章节内容
    const fetchChapter = async (chapterId: string) => {
      try {
        const response = await axios.get(`http://localhost:5000/api/chapters/${chapterId}`);
        currentChapter.value = response.data;
      } catch (err) {
        console.error('获取章节内容失败:', err);
        error.value = '获取章节内容失败，请稍后再试';
      }
    };
    
    // 获取作者名称
    const getAuthorName = (author: Author | string) => {
      if (!author) return '未知作者';
      if (typeof author === 'string') return '未知作者';
      return author.nickname || author.username || '未知作者';
    };
    
    // 当前章节索引
    const currentChapterIndex = computed(() => {
      if (!novel.value.chapters || novel.value.chapters.length === 0 || !currentChapterId.value) {
        return -1;
      }
      
      return novel.value.chapters.findIndex(chapter => chapter._id === currentChapterId.value);
    });
    
    // 是否有上一章
    const hasPrevChapter = computed(() => {
      return currentChapterIndex.value > 0;
    });
    
    // 是否有下一章
    const hasNextChapter = computed(() => {
      return currentChapterIndex.value < novel.value.chapters.length - 1 && currentChapterIndex.value >= 0;
    });
    
    // 上一章
    const prevChapter = async () => {
      if (hasPrevChapter.value) {
        const prevChapterId = novel.value.chapters[currentChapterIndex.value - 1]._id;
        currentChapterId.value = prevChapterId;
        await fetchChapter(prevChapterId);
        updateRoute(prevChapterId);
        window.scrollTo(0, 0);
      }
    };
    
    // 下一章
    const nextChapter = async () => {
      if (hasNextChapter.value) {
        const nextChapterId = novel.value.chapters[currentChapterIndex.value + 1]._id;
        currentChapterId.value = nextChapterId;
        await fetchChapter(nextChapterId);
        updateRoute(nextChapterId);
        window.scrollTo(0, 0);
      }
    };
    
    // 更新路由，不重新加载页面
    const updateRoute = (chapterId: string) => {
      router.replace({
        path: route.path,
        query: { chapter: chapterId }
      });
    };
    
    // 导航到写作页面
    const goToEditPage = () => {
      router.push(`/write/${novel.value._id}/${currentChapterId.value}`);
    };
    
    // 监听路由变化
    watch(
      () => route.query,
      async (newQuery) => {
        if (newQuery.chapter && newQuery.chapter !== currentChapterId.value) {
          currentChapterId.value = newQuery.chapter as string;
          await fetchChapter(currentChapterId.value);
          window.scrollTo(0, 0);
        }
      }
    );
    
    onMounted(() => {
      fetchNovel();
    });
    
    return {
      novel,
      currentChapter,
      loading,
      error,
      hasPrevChapter,
      hasNextChapter,
      prevChapter,
      nextChapter,
      goToEditPage,
      getAuthorName
    };
  }
});
</script>

<style scoped>
.novel-reader {
  max-width: 800px;
  margin: 0 auto;
  padding: 20px;
}

.loading-container,
.error-container {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 300px;
}

.loading {
  font-size: 18px;
  color: #666;
}

.error {
  color: #e53e3e;
  font-size: 18px;
}

.reader-header {
  margin-bottom: 30px;
  text-align: center;
  position: relative;
}

.back-link {
  position: absolute;
  left: 0;
  top: 0;
  text-decoration: none;
  color: #333;
  display: flex;
  align-items: center;
}

.back-icon {
  font-size: 20px;
  margin-right: 5px;
}

.author {
  color: #666;
  margin-top: 5px;
}

.chapter-content {
  line-height: 1.8;
  font-size: 18px;
  margin-bottom: 40px;
}

.chapter-content h2 {
  text-align: center;
  margin-bottom: 20px;
}

.content {
  text-indent: 2em;
}

.content p {
  margin-bottom: 1em;
}

.reader-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 30px;
  padding-top: 20px;
  border-top: 1px solid #eee;
}

.navigation-buttons {
  display: flex;
  gap: 15px;
}

.nav-button {
  padding: 10px 20px;
  background-color: #4a5568;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 16px;
  transition: background-color 0.3s;
}

.nav-button:hover:not(:disabled) {
  background-color: #2d3748;
}

.nav-button:disabled {
  background-color: #cbd5e0;
  cursor: not-allowed;
}

.edit-button {
  padding: 10px 20px;
  background-color: #3182ce;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 16px;
  display: flex;
  align-items: center;
  transition: background-color 0.3s;
}

.edit-button:hover {
  background-color: #2b6cb0;
}

.edit-icon {
  margin-right: 5px;
  font-size: 18px;
}

@media (max-width: 768px) {
  .novel-reader {
    padding: 15px;
  }
  
  .chapter-content {
    font-size: 16px;
  }
  
  .reader-actions {
    flex-direction: column;
    gap: 15px;
  }
  
  .navigation-buttons {
    width: 100%;
    justify-content: space-between;
  }
  
  .edit-actions {
    width: 100%;
    display: flex;
    justify-content: center;
  }
}
</style> 