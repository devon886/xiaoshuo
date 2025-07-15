<template>
  <div class="home">
    <el-row>
      <el-col :span="24">
        <h1 class="page-title">小说网站首页</h1>
      </el-col>
    </el-row>
    
    <el-row v-if="loading" justify="center" class="loading-row">
      <el-col :span="24" class="text-center">
        <el-skeleton :rows="6" animated />
      </el-col>
    </el-row>
    
    <el-row v-else-if="error" justify="center" class="error-row">
      <el-col :span="24" class="text-center">
        <el-alert
          type="error"
          :title="error"
          show-icon
          :closable="false"
        />
      </el-col>
    </el-row>
    
    <el-row v-else :gutter="20" class="novel-grid">
      <el-col 
        v-for="novel in novels" 
        :key="novel._id"
        :xs="24"
        :sm="12"
        :md="8"
        :lg="6"
        :xl="4"
      >
        <NovelCard :novel="novel" />
      </el-col>
    </el-row>
    
    <!-- 分页控件 -->
    <el-row v-if="!loading && !error && pagination.totalPages > 0" justify="center" class="pagination-row">
      <el-col :span="24" class="text-center">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :page-sizes="[10, 20, 30, 50]"
          layout="total, sizes, prev, pager, next, jumper"
          :total="pagination.total"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
          background
        />
      </el-col>
    </el-row>
  </div>
</template>

<script lang="ts">
import { defineComponent, ref, onMounted, watch } from 'vue';
import NovelCard from '../components/NovelCard.vue';
import axios from 'axios';
import { ElMessage } from 'element-plus';
import { useRoute, useRouter } from 'vue-router';

interface Author {
  _id: string;
  username: string;
  nickname?: string;
}

interface Novel {
  _id: string;
  title: string;
  author: Author | string;
  description: string;
  coverImage: string;
}

interface Pagination {
  total: number;
  totalPages: number;
  currentPage: number;
  limit: number;
}

export default defineComponent({
  name: 'HomeView',
  components: {
    NovelCard
  },
  setup() {
    const route = useRoute();
    const router = useRouter();
    const novels = ref<Novel[]>([]);
    const loading = ref(true);
    const error = ref<string | null>(null);
    const currentPage = ref(parseInt(route.query.page as string) || 1);
    const pageSize = ref(parseInt(route.query.limit as string) || 10);
    const pagination = ref<Pagination>({
      total: 0,
      totalPages: 0,
      currentPage: 1,
      limit: 10
    });

    const fetchNovels = async (page: number, limit: number) => {
      try {
        loading.value = true;
        error.value = null;
        
        const response = await axios.get('../api/novels', {
          params: { page, limit }
        });
        
        novels.value = response.data.novels;
        pagination.value = response.data.pagination;
        loading.value = false;
      } catch (err) {
        console.error('获取小说列表失败:', err);
        error.value = '获取小说列表失败，请稍后再试';
        loading.value = false;
        ElMessage.error('获取小说列表失败，请稍后再试');
      }
    };

    // 处理页码变化
    const handleCurrentChange = (page: number) => {
      currentPage.value = page;
      updateRoute();
    };
    
    // 处理每页显示数量变化
    const handleSizeChange = (size: number) => {
      pageSize.value = size;
      currentPage.value = 1; // 重置为第一页
      updateRoute();
    };
    
    // 更新路由参数
    const updateRoute = () => {
      router.push({
        path: route.path,
        query: {
          ...route.query,
          page: currentPage.value.toString(),
          limit: pageSize.value.toString()
        }
      });
    };
    
    // 监听路由参数变化
    watch(
      () => [route.query.page, route.query.limit],
      () => {
        const page = parseInt(route.query.page as string) || 1;
        const limit = parseInt(route.query.limit as string) || 10;
        
        // 避免重复请求
        if (page !== currentPage.value || limit !== pageSize.value) {
          currentPage.value = page;
          pageSize.value = limit;
          fetchNovels(page, limit);
        }
      }
    );

    onMounted(() => {
      fetchNovels(currentPage.value, pageSize.value);
    });
    
    return {
      novels,
      loading,
      error,
      currentPage,
      pageSize,
      pagination,
      handleCurrentChange,
      handleSizeChange
    };
  }
});
</script>

<style scoped>
.home {
  padding: 20px;
}

.page-title {
  text-align: center;
  margin-bottom: 30px;
}

.novel-grid {
  margin-top: 20px;
}

.loading-row,
.error-row {
  min-height: 300px;
  display: flex;
  align-items: center;
}

.text-center {
  text-align: center;
}

.pagination-row {
  margin-top: 40px;
  margin-bottom: 20px;
}
</style> 
