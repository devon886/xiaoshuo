<template>
  <div class="login-page">
    <div class="auth-container">
      <h1>{{ isLogin ? '登录' : '注册' }}</h1>
      
      <div v-if="error" class="error-message">
        {{ error }}
      </div>
      
      <form @submit.prevent="handleSubmit" class="auth-form">
        <div class="form-group">
          <label for="username">用户名</label>
          <input 
            type="text" 
            id="username" 
            v-model="username" 
            required 
            :disabled="loading"
            placeholder="请输入用户名"
          />
        </div>
        
        <div class="form-group">
          <label for="password">密码</label>
          <input 
            type="password" 
            id="password" 
            v-model="password" 
            required 
            :disabled="loading"
            placeholder="请输入密码"
          />
        </div>
        
        <div v-if="!isLogin" class="form-group">
          <label for="nickname">昵称 (可选)</label>
          <input 
            type="text" 
            id="nickname" 
            v-model="nickname" 
            :disabled="loading"
            placeholder="请输入昵称"
          />
        </div>
        
        <button 
          type="submit" 
          class="submit-btn" 
          :disabled="loading"
        >
          {{ loading ? '处理中...' : (isLogin ? '登录' : '注册') }}
        </button>
      </form>
      
      <div class="auth-switch">
        {{ isLogin ? '还没有账号？' : '已有账号？' }}
        <a href="#" @click.prevent="toggleAuthMode">
          {{ isLogin ? '立即注册' : '立即登录' }}
        </a>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent, ref, computed } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { authApi } from '../api/auth';

export default defineComponent({
  name: 'LoginPage',
  setup() {
    const router = useRouter();
    const route = useRoute();
    
    // 表单数据
    const username = ref('');
    const password = ref('');
    const nickname = ref('');
    const loading = ref(false);
    const error = ref('');
    const authMode = ref('login'); // 'login' 或 'register'
    
    // 计算属性
    const isLogin = computed(() => authMode.value === 'login');
    
    // 切换登录/注册模式
    const toggleAuthMode = () => {
      authMode.value = isLogin.value ? 'register' : 'login';
      error.value = '';
    };
    
    // 处理表单提交
    const handleSubmit = async () => {
      try {
        loading.value = true;
        error.value = '';
        
        let response;
        if (isLogin.value) {
          // 登录
          response = await authApi.login(username.value, password.value);
        } else {
          // 注册
          response = await authApi.register(username.value, password.value, nickname.value);
        }
        
        // 保存token到本地存储
        localStorage.setItem('token', response.token);
        
        // 重定向到首页或之前尝试访问的页面
        const redirectPath = route.query.redirect as string || '/';
        router.push(redirectPath);
        
      } catch (err: any) {
        console.error('认证错误:', err);
        error.value = err.response?.data?.message || '发生错误，请稍后再试';
      } finally {
        loading.value = false;
      }
    };
    
    return {
      username,
      password,
      nickname,
      loading,
      error,
      isLogin,
      toggleAuthMode,
      handleSubmit
    };
  }
});
</script>

<style scoped>
.login-page {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: calc(100vh - 140px);
  padding: 20px;
}

.auth-container {
  width: 100%;
  max-width: 400px;
  padding: 30px;
  background-color: white;
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
}

.auth-container h1 {
  margin-top: 0;
  margin-bottom: 20px;
  text-align: center;
  font-size: 24px;
}

.error-message {
  padding: 10px;
  margin-bottom: 20px;
  background-color: #fee2e2;
  border-radius: 4px;
  color: #b91c1c;
  font-size: 14px;
}

.auth-form {
  margin-bottom: 20px;
}

.form-group {
  margin-bottom: 15px;
}

.form-group label {
  display: block;
  margin-bottom: 5px;
  font-weight: 500;
}

.form-group input {
  width: 100%;
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 16px;
}

.form-group input:focus {
  outline: none;
  border-color: #3b82f6;
}

.submit-btn {
  width: 100%;
  padding: 12px;
  background-color: #3b82f6;
  color: white;
  border: none;
  border-radius: 4px;
  font-size: 16px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.3s;
}

.submit-btn:hover:not(:disabled) {
  background-color: #2563eb;
}

.submit-btn:disabled {
  background-color: #93c5fd;
  cursor: not-allowed;
}

.auth-switch {
  text-align: center;
  font-size: 14px;
}

.auth-switch a {
  color: #3b82f6;
  text-decoration: none;
  font-weight: 500;
}

.auth-switch a:hover {
  text-decoration: underline;
}
</style> 
