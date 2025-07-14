import { createRouter, createWebHistory, RouteRecordRaw } from 'vue-router';
import Home from '../views/Home.vue';
import NovelReader from '../views/NovelReader.vue';
import WritingPage from '../views/WritingPage.vue';
import UserProfile from '../views/UserProfile.vue';
import LoginPage from '../views/LoginPage.vue';
import RegisterPage from '../views/RegisterPage.vue';
import SearchResults from '../views/SearchResults.vue';
import AuthorDashboard from '../views/author/AuthorDashboard.vue';
import NovelEditor from '../views/author/NovelEditor.vue';
import ChapterEditor from '../views/author/ChapterEditor.vue';
import CreateNovel from '../views/author/CreateNovel.vue';

const routes: Array<RouteRecordRaw> = [
  {
    path: '/',
    name: 'Home',
    component: Home
  },
  {
    path: '/novel/:id',
    name: 'NovelReader',
    component: NovelReader
  },
  {
    path: '/write/:novelId/:chapterId?',
    name: 'WritingPage',
    component: WritingPage,
    meta: { requiresAuth: true } // 需要登录才能访问
  },
  {
    path: '/user/:id',
    name: 'UserProfile',
    component: UserProfile
  },
  {
    path: '/login',
    name: 'Login',
    component: LoginPage
  },
  {
    path: '/register',
    name: 'Register',
    component: RegisterPage
  },
  {
    path: '/search',
    name: 'SearchResults',
    component: SearchResults
  },
  {
    path: '/about',
    name: 'About',
    component: () => import('../views/About.vue')
  },
  // 作者相关路由
  {
    path: '/author/dashboard',
    name: 'AuthorDashboard',
    component: AuthorDashboard,
    meta: { requiresAuth: true }
  },
  {
    path: '/author/novel/create',
    name: 'CreateNovel',
    component: CreateNovel,
    meta: { requiresAuth: true }
  },
  {
    path: '/author/novel/:id/edit',
    name: 'NovelEditor',
    component: NovelEditor,
    meta: { requiresAuth: true }
  },
  {
    path: '/author/chapter/:id/edit',
    name: 'ChapterEditor',
    component: ChapterEditor,
    meta: { requiresAuth: true }
  }
];

const router = createRouter({
  history: createWebHistory(),
  routes
});

// 全局前置守卫，用于处理需要登录的路由
router.beforeEach((to, from, next) => {
  const requiresAuth = to.matched.some(record => record.meta.requiresAuth);
  const token = localStorage.getItem('token');
  
  if (requiresAuth && !token) {
    // 需要登录但未登录，重定向到登录页
    next({
      path: '/login',
      query: { redirect: to.fullPath } // 保存原本要访问的路径
    });
  } else {
    next();
  }
});

export default router; 