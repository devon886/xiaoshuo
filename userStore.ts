import { defineStore } from 'pinia';
import { authApi } from '../api/auth';

interface User {
  id: string;
  username: string;
  nickname?: string;
}

interface UserState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
}

export const useUserStore = defineStore('user', {
  state: (): UserState => ({
    user: null,
    token: localStorage.getItem('token'),
    isAuthenticated: !!localStorage.getItem('token')
  }),
  
  getters: {
    getCurrentUser: (state) => state.user,
    isLoggedIn: (state) => state.isAuthenticated
  },
  
  actions: {
    async login(username: string, password: string) {
      try {
        const response = await authApi.login(username, password);
        this.token = response.token;
        this.isAuthenticated = true;
        localStorage.setItem('token', response.token);
        
        // 获取用户信息
        await this.fetchCurrentUser();
        
        return { success: true };
      } catch (error: any) {
        return { 
          success: false, 
          error: error.response?.data?.message || '登录失败，请稍后再试'
        };
      }
    },
    
    async register(username: string, password: string, nickname?: string) {
      try {
        const response = await authApi.register(username, password, nickname);
        this.token = response.token;
        this.isAuthenticated = true;
        localStorage.setItem('token', response.token);
        
        // 获取用户信息
        await this.fetchCurrentUser();
        
        return { success: true };
      } catch (error: any) {
        return { 
          success: false, 
          error: error.response?.data?.message || '注册失败，请稍后再试'
        };
      }
    },
    
    async fetchCurrentUser() {
      try {
        if (!this.token) return;
        
        const userData = await authApi.getCurrentUser();
        this.user = {
          id: userData.id || userData._id,
          username: userData.username,
          nickname: userData.nickname
        };
      } catch (error) {
        console.error('获取用户信息失败:', error);
        this.logout();
      }
    },
    
    logout() {
      this.user = null;
      this.token = null;
      this.isAuthenticated = false;
      localStorage.removeItem('token');
    }
  }
}); 