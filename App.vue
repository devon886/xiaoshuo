<template>
  <div class="app">
    <el-container>
      <el-header class="header">
        <div class="container">
          <NavBar />
        </div>
      </el-header>
      
      <el-main class="main">
        <div class="container">
          <router-view />
        </div>
      </el-main>
      
      <el-footer class="footer">
        <div class="container">
          <p>&copy; 2025 小说网站 - 所有权利保留</p>
        </div>
      </el-footer>
    </el-container>
  </div>
</template>

<script lang="ts">
import { defineComponent, onMounted } from 'vue';
import { useUserStore } from './stores/userStore';
import NavBar from './components/NavBar.vue';

export default defineComponent({
  name: 'App',
  components: {
    NavBar
  },
  setup() {
    const userStore = useUserStore();
    
    onMounted(() => {
      // 初始化时获取用户信息
      userStore.fetchCurrentUser();
    });
    
    return {
      userStore
    };
  }
});
</script>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
  color: #333;
  background-color: #f5f5f5;
  line-height: 1.6;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 15px;
  width: 100%;
}

.header {
  background-color: white;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  position: sticky;
  top: 0;
  z-index: 100;
}

.main {
  min-height: calc(100vh - 120px);
  padding: 20px 0;
}

.footer {
  background-color: #f0f2f5;
  padding: 20px 0;
  text-align: center;
  color: #666;
  height: 60px;
}

.flex-grow {
  flex-grow: 1;
}

.logo-container {
  display: flex;
  align-items: center;
}

.logo {
  font-size: 1.5rem;
  margin: 0;
}

/* Element Plus 覆盖样式 */
.el-menu--horizontal {
  border-bottom: none !important;
}

.el-menu--horizontal > .el-menu-item.is-active {
  border-bottom: 2px solid #409eff !important;
}
</style> 
