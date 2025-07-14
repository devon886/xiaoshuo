<template>
  <div class="navbar">
    <el-menu
      mode="horizontal"
      :ellipsis="false"
      router
      :default-active="activeIndex"
      class="nav-menu"
    >
      <div class="logo-container">
        <router-link to="/" class="logo-link">
          <h1 class="logo">小说网站</h1>
        </router-link>
      </div>
      
      <el-menu-item index="/">
        <el-icon><HomeFilled /></el-icon>
        首页
      </el-menu-item>
      
      <el-menu-item index="/about">
        <el-icon><InfoFilled /></el-icon>
        关于
      </el-menu-item>
      
      <!-- 搜索框 -->
      <div class="search-container">
        <el-input
          v-model="searchQuery"
          placeholder="搜索小说..."
          class="search-input"
          @keyup.enter="handleSearch"
        >
          <template #append>
            <el-button @click="handleSearch">
              <el-icon><Search /></el-icon>
            </el-button>
          </template>
        </el-input>
      </div>
      
      <div class="flex-grow"></div>
      
      <!-- 已登录用户菜单 -->
      <template v-if="userStore.isLoggedIn">
        <el-menu-item index="/author/dashboard">
          <el-icon><Edit /></el-icon>
          创作中心
        </el-menu-item>
        
        <el-sub-menu index="user">
          <template #title>
            <el-icon><User /></el-icon>
            我的账户
          </template>
          <el-menu-item :index="`/user/${currentUserId}`">
            <el-icon><UserFilled /></el-icon>
            我的主页
          </el-menu-item>
          <el-menu-item index="/author/dashboard">
            <el-icon><Edit /></el-icon>
            作者后台
          </el-menu-item>
          <el-menu-item @click.prevent="handleLogout">
            <el-icon><SwitchButton /></el-icon>
            退出登录
          </el-menu-item>
        </el-sub-menu>
      </template>
      
      <!-- 未登录用户菜单 -->
      <template v-else>
        <el-menu-item index="/login">
          <el-icon><Key /></el-icon>
          登录
        </el-menu-item>
        <el-menu-item index="/register">
          <el-icon><UserFilled /></el-icon>
          注册
        </el-menu-item>
      </template>
    </el-menu>
  </div>
</template>

<script lang="ts">
import { defineComponent, ref, computed } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useUserStore } from '../stores/userStore';
import { 
  HomeFilled, 
  InfoFilled, 
  User, 
  UserFilled, 
  SwitchButton, 
  Key,
  Edit,
  Search
} from '@element-plus/icons-vue';

export default defineComponent({
  name: 'NavBar',
  components: {
    HomeFilled,
    InfoFilled,
    User,
    UserFilled,
    SwitchButton,
    Key,
    Edit,
    Search
  },
  setup() {
    const router = useRouter();
    const route = useRoute();
    const userStore = useUserStore();
    const searchQuery = ref('');
    
    // 获取当前路由路径作为活动菜单项
    const activeIndex = computed(() => {
      return route.path;
    });
    
    // 获取当前用户ID
    const currentUserId = computed(() => {
      return userStore.user?.id || '';
    });
    
    // 处理退出登录
    const handleLogout = () => {
      userStore.logout();
      router.push('/');
    };
    
    // 处理搜索
    const handleSearch = () => {
      if (searchQuery.value.trim()) {
        router.push({
          path: '/search',
          query: { query: searchQuery.value.trim() }
        });
        searchQuery.value = ''; // 清空搜索框
      }
    };
    
    return {
      userStore,
      currentUserId,
      handleLogout,
      activeIndex,
      searchQuery,
      handleSearch
    };
  }
});
</script>

<style scoped>
.navbar {
  width: 100%;
}

.nav-menu {
  display: flex;
  align-items: center;
}

.logo-container {
  margin-right: 20px;
}

.logo-link {
  text-decoration: none;
  color: inherit;
}

.logo {
  margin: 0;
  font-size: 1.5rem;
}

.search-container {
  margin: 0 20px;
  width: 300px;
}

.search-input {
  width: 100%;
}

.flex-grow {
  flex-grow: 1;
}

@media (max-width: 768px) {
  .search-container {
    width: 150px;
  }
}
</style> 