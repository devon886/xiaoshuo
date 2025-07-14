<template>
  <div class="create-novel">
    <el-row :gutter="20" class="mb-4">
      <el-col :span="24">
        <el-card shadow="hover">
          <template #header>
            <div class="card-header">
              <h2>创建新小说</h2>
            </div>
          </template>
          
          <div class="loading-container">
            <el-skeleton :rows="3" animated />
            <p class="redirect-text">正在准备创建页面，请稍候...</p>
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script lang="ts">
import { defineComponent, onMounted } from 'vue';
import { useRouter } from 'vue-router';

export default defineComponent({
  name: 'CreateNovel',
  setup() {
    const router = useRouter();
    
    onMounted(() => {
      // 直接重定向到小说编辑页，使用 create 参数
      setTimeout(() => {
        router.replace('/author/novel/create/edit');
      }, 500);
    });
    
    return {};
  }
});
</script>

<style scoped>
.create-novel {
  padding: 20px;
}

.mb-4 {
  margin-bottom: 20px;
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
  text-align: center;
}

.redirect-text {
  margin-top: 20px;
  color: #606266;
}
</style> 