import axios from 'axios';

// 创建一个 axios 实例
const api = axios.create({
  baseURL: '/api', // 假设后端 API 的基础路径是 /api
  timeout: 10000, // 请求超时时间
  headers: {
    'Content-Type': 'application/json'
  }
});

// 小说相关的 API 请求
export const novelsApi = {
  // 获取所有小说列表
  getAllNovels() {
    return api.get('/novels');
  },
  
  // 获取单本小说详情
  getNovelById(id: number) {
    return api.get(`/novels/${id}`);
  },
  
  // 获取小说的章节列表
  getNovelChapters(novelId: number) {
    return api.get(`/novels/${novelId}/chapters`);
  },
  
  // 获取单个章节内容
  getChapterContent(novelId: number, chapterId: number) {
    return api.get(`/novels/${novelId}/chapters/${chapterId}`);
  }
};

// 用户相关的 API 请求
export const userApi = {
  // 用户登录
  login(username: string, password: string) {
    return api.post('/auth/login', { username, password });
  },
  
  // 用户注册
  register(username: string, password: string, email: string) {
    return api.post('/auth/register', { username, password, email });
  },
  
  // 获取用户书架
  getBookshelf() {
    return api.get('/user/bookshelf');
  },
  
  // 添加小说到书架
  addToBookshelf(novelId: number) {
    return api.post('/user/bookshelf', { novelId });
  }
};

// 请求拦截器
api.interceptors.request.use(
  config => {
    // 从 localStorage 获取 token
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  error => {
    return Promise.reject(error);
  }
);

// 响应拦截器
api.interceptors.response.use(
  response => {
    return response.data;
  },
  error => {
    // 处理错误响应
    if (error.response) {
      // 服务器返回错误状态码
      if (error.response.status === 401) {
        // 未授权，可能是 token 过期
        localStorage.removeItem('token');
        // 这里可以添加重定向到登录页的逻辑
      }
    }
    return Promise.reject(error);
  }
);

export default api; 