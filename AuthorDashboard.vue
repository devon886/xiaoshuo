<template>
  <div class="author-dashboard">
    <el-row :gutter="20" class="mb-4">
      <el-col :span="24">
        <el-card shadow="hover">
          <template #header>
            <div class="card-header">
              <h2>作者仪表板</h2>
              <el-button type="primary" @click="createNewNovel">
                <el-icon><Plus /></el-icon>
                创建新小说
              </el-button>
            </div>
          </template>
          
          <div v-if="loading" class="loading-container">
            <el-skeleton :rows="3" animated />
          </div>
          
          <div v-else-if="novels.length === 0" class="empty-state">
            <el-empty description="">
              <template #image>
                <img src="https://via.placeholder.com/200x200?text=开始创作" alt="开始创作" class="empty-image" />
              </template>
              <template #description>
                <div class="empty-text">
                  <h3>开始您的创作之旅</h3>
                  <p>您还没有创建任何小说，点击下方按钮开始创作您的第一本小说吧！</p>
                </div>
              </template>
              <el-button type="primary" @click="createNewNovel">
                <el-icon><Plus /></el-icon>
                创建我的第一本小说
              </el-button>
            </el-empty>
          </div>
          
          <el-alert
            v-if="error"
            type="error"
            :title="error"
            show-icon
            :closable="false"
            class="mb-4"
          />
          
          <div v-else-if="novels.length > 0" class="novel-list">
            <el-table :data="novels" style="width: 100%">
              <el-table-column width="120">
                <template #default="scope">
                  <el-image 
                    :src="scope.row.coverImage || 'https://via.placeholder.com/80x120?text=封面'"
                    fit="cover"
                    style="width: 80px; height: 120px"
                    :preview-src-list="[scope.row.coverImage]"
                  />
                </template>
              </el-table-column>
              
              <el-table-column prop="title" label="标题" />
              
              <el-table-column prop="createdAt" label="创建时间" width="180">
                <template #default="scope">
                  {{ formatDate(scope.row.createdAt) }}
                </template>
              </el-table-column>
              
              <el-table-column prop="status" label="状态" width="100">
                <template #default="scope">
                  <el-tag :type="getStatusType(scope.row.status)">
                    {{ getStatusText(scope.row.status) }}
                  </el-tag>
                </template>
              </el-table-column>
              
              <el-table-column label="操作" width="200">
                <template #default="scope">
                  <el-button 
                    type="primary" 
                    @click="manageNovel(scope.row._id)"
                    size="small"
                  >
                    管理
                  </el-button>
                  <el-button 
                    type="danger" 
                    @click="confirmDelete(scope.row)"
                    size="small"
                  >
                    删除
                  </el-button>
                </template>
              </el-table-column>
            </el-table>
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script lang="ts">
import { defineComponent, ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useUserStore } from '../../stores/userStore';
import { ElMessageBox } from 'element-plus';
import axios from 'axios';
import { Plus } from '@element-plus/icons-vue';
import { showSuccessToast, showErrorToast } from '../../utils/toast';

interface Novel {
  _id: string;
  title: string;
  description: string;
  coverImage: string;
  author: string;
  status: string;
  createdAt: string;
  updatedAt: string;
}

export default defineComponent({
  name: 'AuthorDashboard',
  components: {
    Plus
  },
  setup() {
    const router = useRouter();
    const userStore = useUserStore();
    const novels = ref<Novel[]>([]);
    const loading = ref(true);
    const error = ref('');

    // 获取作者的小说列表
    const fetchAuthorNovels = async () => {
      if (!userStore.isLoggedIn || !userStore.user) {
        error.value = '请先登录';
        loading.value = false;
        return;
      }

      try {
        loading.value = true;
        const response = await axios.get(`http://localhost:5000/api/novels?authorId=${userStore.user.id}`);
        novels.value = response.data;
        loading.value = false;
      } catch (err) {
        console.error('获取小说列表失败:', err);
        error.value = '获取小说列表失败，请稍后再试';
        loading.value = false;
        showErrorToast('获取小说列表失败，请稍后再试');
      }
    };

    // 创建新小说
    const createNewNovel = () => {
      router.push('/author/novel/create');
    };

    // 管理小说
    const manageNovel = (id: string) => {
      router.push(`/author/novel/${id}/edit`);
    };

    // 确认删除小说
    const confirmDelete = (novel: Novel) => {
      ElMessageBox.confirm(
        `确定要删除小说"${novel.title}"吗？此操作不可逆。`,
        '警告',
        {
          confirmButtonText: '确定',
          cancelButtonText: '取消',
          type: 'warning',
        }
      )
        .then(() => {
          deleteNovel(novel._id);
        })
        .catch(() => {
          // 用户取消删除，不做任何操作
        });
    };

    // 删除小说
    const deleteNovel = async (id: string) => {
      try {
        await axios.delete(`http://localhost:5000/api/novels/${id}`);
        showSuccessToast('小说已成功删除');
        // 重新获取小说列表
        fetchAuthorNovels();
      } catch (err) {
        console.error('删除小说失败:', err);
        showErrorToast('删除小说失败，请稍后再试');
      }
    };

    // 格式化日期
    const formatDate = (dateString: string) => {
      const date = new Date(dateString);
      return date.toLocaleDateString('zh-CN', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
      });
    };

    // 获取状态类型
    const getStatusType = (status: string) => {
      const statusMap: Record<string, string> = {
        'draft': 'info',
        'published': 'success',
        'pending': 'warning',
      };
      return statusMap[status] || 'info';
    };

    // 获取状态文本
    const getStatusText = (status: string) => {
      const statusMap: Record<string, string> = {
        'draft': '草稿',
        'published': '已发布',
        'pending': '审核中',
      };
      return statusMap[status] || '草稿';
    };

    onMounted(() => {
      fetchAuthorNovels();
    });

    return {
      novels,
      loading,
      error,
      createNewNovel,
      manageNovel,
      confirmDelete,
      formatDate,
      getStatusType,
      getStatusText,
    };
  },
});
</script>

<style scoped>
.author-dashboard {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.card-header h2 {
  margin: 0;
}

.loading-container {
  padding: 20px 0;
}

.mb-4 {
  margin-bottom: 20px;
}

.empty-state {
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
</style> 