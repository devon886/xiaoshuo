import axios from 'axios';

// 设置基础URL
const API_URL = '../api/novels';

// 创建axios实例
const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json'
  }
});

// 请求拦截器，添加token到请求头
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// 认证相关API
export const authApi = {
  // 用户注册
  register: async (username: string, password: string, nickname?: string) => {
    const response = await api.post('/auth/register', {
      username,
      password,
      nickname
    });
    return response.data;
  },

  // 用户登录
  login: async (username: string, password: string) => {
    const response = await api.post('/auth/login', {
      username,
      password
    });
    return response.data;
  },

  // 获取当前用户信息
  getCurrentUser: async () => {
    const response = await api.get('/users/me');
    return response.data;
  },

  // 更新用户信息
  updateUser: async (userData: { nickname?: string, bio?: string, avatar?: string }) => {
    const response = await api.put('/users/me', userData);
    return response.data;
  }
};

// 用户相关API
export const userApi = {
  // 获取指定用户的公开信息
  getUserById: async (userId: string) => {
    const response = await api.get(`/users/${userId}`);
    return response.data;
  },
  
  // 获取用户发布的小说
  getUserNovels: async (userId: string) => {
    const response = await api.get(`/users/${userId}/novels`);
    return response.data;
  }
};

export default api; 
