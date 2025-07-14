<template>
  <div class="user-profile">
    <div class="loading-container" v-if="loading">
      <div class="loading">加载中...</div>
    </div>
    <div class="error-container" v-else-if="error">
      <div class="error">{{ error }}</div>
    </div>
    <template v-else>
      <div class="profile-header">
        <div class="avatar-container">
          <img :src="user.avatar || 'https://via.placeholder.com/150x150?text=用户头像'" :alt="user.nickname || user.username" class="avatar" />
        </div>
        <div class="user-info">
          <h1>{{ user.nickname || user.username }}</h1>
          <p class="username">@{{ user.username }}</p>
          <p class="bio">{{ user.bio || '该用户暂未设置个人简介' }}</p>
          <p class="joined">加入时间：{{ formatDate(user.createdAt) }}</p>
        </div>
      </div>
      
      <!-- 标签页切换 -->
      <div class="tabs-container">
        <el-tabs v-model="activeTab">
          <el-tab-pane label="发布的小说" name="novels">
            <div v-if="novels.length === 0" class="no-novels">
              该用户还没有发布小说
            </div>
            <div v-else class="novels-grid">
              <div v-for="novel in novels" :key="novel._id" class="novel-card" @click="goToNovel(novel._id || novel.slug || '')">
                <div class="novel-cover">
                  <img :src="novel.coverImage || 'https://via.placeholder.com/150x200?text=小说封面'" :alt="novel.title" />
                </div>
                <div class="novel-info">
                  <h3>{{ novel.title }}</h3>
                  <p class="description">{{ truncateText(novel.description, 100) }}</p>
                  <div class="tags" v-if="novel.tags && novel.tags.length > 0">
                    <span v-for="(tag, index) in novel.tags" :key="index" class="tag">{{ tag }}</span>
                  </div>
                  <p class="date">{{ formatDate(novel.createdAt) }}</p>
                </div>
              </div>
            </div>
          </el-tab-pane>
          
          <el-tab-pane label="我的书架" name="bookshelf">
            <div v-if="bookshelf.length === 0" class="empty-bookshelf">
              <el-empty description="">
                <template #image>
                  <img src="https://via.placeholder.com/200x200?text=空书架" alt="空书架" class="empty-image" />
                </template>
                <template #description>
                  <div class="empty-text">
                    <h3>您的书架还是空的</h3>
                    <p>浏览小说并收藏您喜欢的作品，它们会出现在这里</p>
                  </div>
                </template>
                <el-button type="primary" @click="goToHome">
                  去发现好书
                </el-button>
              </el-empty>
            </div>
            <div v-else class="novels-grid">
              <div v-for="novel in bookshelf" :key="novel._id" class="novel-card" @click="goToNovel(novel._id || novel.slug || '')">
                <div class="novel-cover">
                  <img :src="novel.coverImage || 'https://via.placeholder.com/150x200?text=小说封面'" :alt="novel.title" />
                </div>
                <div class="novel-info">
                  <h3>{{ novel.title }}</h3>
                  <p class="description">{{ truncateText(novel.description, 100) }}</p>
                  <div class="tags" v-if="novel.tags && novel.tags.length > 0">
                    <span v-for="(tag, index) in novel.tags" :key="index" class="tag">{{ tag }}</span>
                  </div>
                  <p class="date">{{ formatDate(novel.createdAt) }}</p>
                </div>
              </div>
            </div>
          </el-tab-pane>
        </el-tabs>
      </div>
    </template>
  </div>
</template>

<script lang="ts">
import { defineComponent, ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import axios from 'axios';

interface User {
  _id: string;
  username: string;
  nickname?: string;
  avatar?: string;
  bio?: string;
  createdAt: string;
}

interface Novel {
  _id: string;
  slug?: string;
  title: string;
  description: string;
  coverImage: string;
  tags: string[];
  createdAt: string;
}

interface UserResponse {
  user: User;
  novels: Novel[];
  bookshelf?: Novel[];
}

export default defineComponent({
  name: 'UserProfile',
  setup() {
    const route = useRoute();
    const router = useRouter();
    const userId = route.params.id as string;
    
    const user = ref<User>({
      _id: '',
      username: '',
      createdAt: ''
    });
    const novels = ref<Novel[]>([]);
    const bookshelf = ref<Novel[]>([]);
    const loading = ref(true);
    const error = ref<string | null>(null);
    const activeTab = ref('novels');
    
    // 获取用户信息和小说
    const fetchUserProfile = async () => {
      try {
        loading.value = true;
        error.value = null;
        
        // 获取用户信息和小说
        const response = await axios.get<UserResponse>(`http://localhost:5000/api/users/${userId}`);
        user.value = response.data.user;
        novels.value = response.data.novels;
        bookshelf.value = response.data.bookshelf || [];
      } catch (err) {
        console.error('获取用户资料失败:', err);
        error.value = '获取用户资料失败，请稍后再试';
      } finally {
        loading.value = false;
      }
    };
    
    // 格式化日期
    const formatDate = (dateString: string) => {
      if (!dateString) return '未知日期';
      const date = new Date(dateString);
      return date.toLocaleDateString('zh-CN', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
      });
    };
    
    // 截断文本
    const truncateText = (text: string, maxLength: number) => {
      if (!text) return '';
      if (text.length <= maxLength) return text;
      return text.slice(0, maxLength) + '...';
    };
    
    // 跳转到小说详情页
    const goToNovel = (identifier: string) => {
      router.push(`/novel/${identifier}`);
    };
    
    // 跳转到首页
    const goToHome = () => {
      router.push('/');
    };
    
    onMounted(() => {
      fetchUserProfile();
    });
    
    return {
      user,
      novels,
      bookshelf,
      loading,
      error,
      activeTab,
      formatDate,
      truncateText,
      goToNovel,
      goToHome
    };
  }
});
</script>

<style scoped>
.user-profile {
  max-width: 1000px;
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

.profile-header {
  display: flex;
  margin-bottom: 40px;
  padding-bottom: 20px;
  border-bottom: 1px solid #eee;
}

.avatar-container {
  margin-right: 30px;
}

.avatar {
  width: 150px;
  height: 150px;
  border-radius: 50%;
  object-fit: cover;
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
}

.user-info {
  flex: 1;
}

.user-info h1 {
  margin: 0 0 10px 0;
  font-size: 28px;
}

.username {
  color: #666;
  margin-bottom: 15px;
}

.bio {
  margin-bottom: 15px;
  line-height: 1.6;
}

.joined {
  color: #666;
  font-size: 14px;
}

.tabs-container {
  margin-bottom: 20px;
}

.no-novels {
  padding: 30px;
  text-align: center;
  background-color: #f9f9f9;
  border-radius: 8px;
  color: #666;
}

.empty-bookshelf {
  padding: 40px 0;
  text-align: center;
}

.empty-image {
  width: 200px;
  height: 200px;
  object-fit: cover;
  border-radius: 8px;
}

.empty-text {
  margin: 20px 0;
}

.empty-text h3 {
  font-size: 20px;
  margin-bottom: 10px;
  color: #409EFF;
}

.empty-text p {
  color: #606266;
  font-size: 16px;
}

.novels-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 20px;
}

.novel-card {
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  transition: transform 0.3s ease;
  cursor: pointer;
  background-color: white;
}

.novel-card:hover {
  transform: translateY(-5px);
}

.novel-cover img {
  width: 100%;
  height: 180px;
  object-fit: cover;
}

.novel-info {
  padding: 15px;
}

.novel-info h3 {
  margin: 0 0 10px 0;
  font-size: 18px;
}

.description {
  margin-bottom: 10px;
  color: #555;
  font-size: 14px;
  line-height: 1.5;
}

.tags {
  display: flex;
  flex-wrap: wrap;
  gap: 5px;
  margin-bottom: 10px;
}

.tag {
  background-color: #e2e8f0;
  padding: 3px 8px;
  border-radius: 4px;
  font-size: 12px;
  color: #4a5568;
}

.date {
  font-size: 12px;
  color: #888;
}

@media (max-width: 768px) {
  .profile-header {
    flex-direction: column;
    align-items: center;
    text-align: center;
  }
  
  .avatar-container {
    margin-right: 0;
    margin-bottom: 20px;
  }
  
  .novels-grid {
    grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  }
}

@media (max-width: 480px) {
  .novels-grid {
    grid-template-columns: 1fr;
  }
}
</style> 