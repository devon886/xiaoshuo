<template>
  <div class="search-results">
    <h1 class="search-title">搜索结果: "{{ searchQuery }}"</h1>
    
    <div v-if="loading" class="loading-container">
      <el-skeleton :rows="10" animated />
    </div>
    
    <el-alert
      v-if="error"
      type="error"
      :title="error"
      show-icon
      :closable="false"
      class="mb-4"
    />
    
    <div v-else>
      <div v-if="results.length === 0" class="no-results">
        <el-empty description="没有找到匹配的小说" />
      </div>
      
      <div v-else class="results-list">
        <el-card v-for="novel in results" :key="novel._id" class="result-card" shadow="hover">
          <div class="result-content">
            <div class="novel-cover">
              <img :src="novel.coverImage || 'https://via.placeholder.com/120x160?text=封面'" :alt="novel.title" />
            </div>
            <div class="novel-info">
              <h2>
                <router-link :to="`/novel/${novel._id}`">{{ novel.title }}</router-link>
              </h2>
              <p class="author">作者: {{ getAuthorName(novel.author) }}</p>
              <p class="description">{{ truncateText(novel.description, 150) }}</p>
              <div class="tags" v-if="novel.tags && novel.tags.length > 0">
                <el-tag v-for="(tag, index) in novel.tags" :key="index" size="small" class="tag">{{ tag }}</el-tag>
              </div>
            </div>
          </div>
        </el-card>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent, ref, onMounted, watch } from 'vue';
import { useRoute } from 'vue-router';
import axios from 'axios';

interface Author {
  _id: string;
  username: string;
  nickname?: string;
}

interface Novel {
  _id: string;
  title: string;
  description: string;
  coverImage: string;
  author: Author | string;
  tags: string[];
}

export default defineComponent({
  name: 'SearchResults',
  setup() {
    const route = useRoute();
    const searchQuery = ref('');
    const results = ref<Novel[]>([]);
    const loading = ref(false);
    const error = ref('');
    
    // 获取搜索结果
    const fetchSearchResults = async (query: string) => {
      if (!query) return;
      
      loading.value = true;
      error.value = '';
      
      try {
        const response = await axios.get(`../api/search`, {
          params: { q: query }
        });
        
        results.value = response.data;
      } catch (err) {
        console.error('搜索失败:', err);
        error.value = '搜索失败，请稍后再试';
      } finally {
        loading.value = false;
      }
    };
    
    // 截断文本
    const truncateText = (text: string, maxLength: number) => {
      if (!text) return '';
      return text.length > maxLength ? text.slice(0, maxLength) + '...' : text;
    };
    
    // 获取作者名称
    const getAuthorName = (author: Author | string) => {
      if (!author) return '未知作者';
      if (typeof author === 'string') return '未知作者';
      return author.nickname || author.username;
    };
    
    // 监听路由查询参数变化
    watch(
      () => route.query.query,
      (newQuery) => {
        if (newQuery) {
          searchQuery.value = newQuery as string;
          fetchSearchResults(searchQuery.value);
        }
      },
      { immediate: true }
    );
    
    return {
      searchQuery,
      results,
      loading,
      error,
      truncateText,
      getAuthorName
    };
  }
});
</script>

<style scoped>
.search-results {
  padding: 20px 0;
}

.search-title {
  margin-bottom: 20px;
  font-size: 1.8rem;
}

.loading-container {
  padding: 20px 0;
}

.mb-4 {
  margin-bottom: 20px;
}

.no-results {
  padding: 40px 0;
  text-align: center;
}

.results-list {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.result-card {
  transition: transform 0.3s;
}

.result-card:hover {
  transform: translateY(-3px);
}

.result-content {
  display: flex;
  gap: 20px;
}

.novel-cover {
  flex-shrink: 0;
}

.novel-cover img {
  width: 120px;
  height: 160px;
  object-fit: cover;
  border-radius: 4px;
}

.novel-info {
  flex-grow: 1;
}

.novel-info h2 {
  margin-top: 0;
  margin-bottom: 10px;
}

.novel-info h2 a {
  color: #333;
  text-decoration: none;
}

.novel-info h2 a:hover {
  color: #409eff;
}

.author {
  color: #666;
  margin-bottom: 10px;
}

.description {
  color: #333;
  margin-bottom: 10px;
  line-height: 1.5;
}

.tags {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.tag {
  margin-right: 0;
}

@media (max-width: 768px) {
  .result-content {
    flex-direction: column;
  }
  
  .novel-cover {
    margin-bottom: 15px;
  }
  
  .novel-cover img {
    width: 100%;
    height: auto;
    max-height: 200px;
  }
}
</style> 
