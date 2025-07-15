<template>
  <div class="novel-editor">
    <el-row :gutter="20" class="mb-4">
      <el-col :span="24">
        <el-page-header @back="goBack" :title="isCreate ? '创建新小说' : '编辑小说'">
          <template #content>
            <span class="page-header-title">{{ novel.title || '未命名小说' }}</span>
          </template>
        </el-page-header>
      </el-col>
    </el-row>

    <div v-if="loading" class="loading-container">
      <el-skeleton :rows="10" animated />
    </div>

    <el-alert
      v-if="error"
      type="error"
      :title="error"
      show-icon
      :closable="false"
      class="mb-4"
    />

    <template v-else>
      <!-- 小说基本信息表单 -->
      <el-row :gutter="20" class="mb-4">
        <el-col :span="24">
          <el-card shadow="hover">
            <template #header>
              <div class="card-header">
                <h3>小说信息</h3>
                <div>
                  <el-button 
                    type="success" 
                    @click="saveNovel" 
                    :loading="saving"
                    :disabled="!formChanged"
                  >
                    保存修改
                  </el-button>
                  <el-button 
                    v-if="!isCreate && novel.status !== 'published'" 
                    type="primary" 
                    @click="publishNovel"
                    :loading="publishing"
                  >
                    发布小说
                  </el-button>
                </div>
              </div>
            </template>

            <el-form 
              ref="formRef" 
              :model="novel" 
              :rules="rules" 
              label-position="top"
            >
              <el-row :gutter="20">
                <el-col :xs="24" :sm="16">
                  <el-form-item label="小说标题" prop="title">
                    <el-input v-model="novel.title" placeholder="请输入小说标题" />
                  </el-form-item>

                  <el-form-item label="小说简介" prop="description">
                    <el-input 
                      v-model="novel.description" 
                      type="textarea" 
                      :rows="5" 
                      placeholder="请输入小说简介"
                    />
                  </el-form-item>

                  <el-form-item label="类型" prop="genre">
                    <el-select v-model="novel.genre" placeholder="请选择小说类型">
                      <el-option label="奇幻" value="fantasy" />
                      <el-option label="科幻" value="sci-fi" />
                      <el-option label="悬疑" value="mystery" />
                      <el-option label="言情" value="romance" />
                      <el-option label="武侠" value="wuxia" />
                      <el-option label="历史" value="historical" />
                      <el-option label="其他" value="other" />
                    </el-select>
                  </el-form-item>

                  <el-form-item label="标签" prop="tags">
                    <el-tag
                      v-for="tag in novel.tags"
                      :key="tag"
                      closable
                      @close="removeTag(tag)"
                      class="tag-item"
                    >
                      {{ tag }}
                    </el-tag>
                    <el-input
                      v-if="inputTagVisible"
                      ref="tagInputRef"
                      v-model="inputTag"
                      class="tag-input"
                      size="small"
                      @keyup.enter="addTag"
                      @blur="addTag"
                    />
                    <el-button v-else class="tag-button" size="small" @click="showTagInput">
                      + 添加标签
                    </el-button>
                  </el-form-item>
                </el-col>

                <el-col :xs="24" :sm="8">
                  <el-form-item label="封面图片">
                    <el-upload
                      class="cover-uploader"
                      action="http://localhost:5000/api/upload"
                      :show-file-list="false"
                      :on-success="handleCoverSuccess"
                      :before-upload="beforeCoverUpload"
                    >
                      <el-image
                        v-if="novel.coverImage"
                        :src="novel.coverImage"
                        class="cover-image"
                        fit="cover"
                      />
                      <el-icon v-else class="cover-uploader-icon"><Plus /></el-icon>
                    </el-upload>
                    <div class="cover-tip">点击上传封面图片</div>
                  </el-form-item>

                  <el-form-item label="状态">
                    <el-tag :type="getStatusType(novel.status)">
                      {{ getStatusText(novel.status) }}
                    </el-tag>
                  </el-form-item>
                </el-col>
              </el-row>
            </el-form>
          </el-card>
        </el-col>
      </el-row>

      <!-- 章节列表 -->
      <el-row :gutter="20" v-if="!isCreate">
        <el-col :span="24">
          <el-card shadow="hover">
            <template #header>
              <div class="card-header">
                <h3>章节列表</h3>
                <el-button type="primary" @click="createChapter">
                  <el-icon><Plus /></el-icon>
                  新增章节
                </el-button>
              </div>
            </template>

            <div v-if="loadingChapters" class="loading-container">
              <el-skeleton :rows="3" animated />
            </div>

            <el-empty v-else-if="chapters.length === 0" description="暂无章节，请添加新章节" />

            <el-table v-else :data="chapters" style="width: 100%">
              <el-table-column prop="chapterNumber" label="章节" width="80" />
              <el-table-column prop="title" label="标题" />
              <el-table-column prop="updatedAt" label="最后更新" width="180">
                <template #default="scope">
                  {{ formatDate(scope.row.updatedAt) }}
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
                    @click="editChapter(scope.row._id)"
                    size="small"
                  >
                    编辑
                  </el-button>
                  <el-button 
                    type="danger" 
                    @click="confirmDeleteChapter(scope.row)"
                    size="small"
                  >
                    删除
                  </el-button>
                </template>
              </el-table-column>
            </el-table>
          </el-card>
        </el-col>
      </el-row>
    </template>
  </div>
</template>

<script lang="ts">
import { defineComponent, ref, reactive, computed, onMounted, nextTick } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useUserStore } from '../../stores/userStore';
import { ElMessageBox } from 'element-plus';
import axios from 'axios';
import { Plus } from '@element-plus/icons-vue';
import type { FormInstance, FormRules, UploadProps } from 'element-plus';
import { showSuccessToast, showErrorToast } from '../../utils/toast';

interface Chapter {
  _id: string;
  title: string;
  content: string;
  chapterNumber: number;
  novel: string;
  status: string;
  createdAt: string;
  updatedAt: string;
}

export default defineComponent({
  name: 'NovelEditor',
  components: {
    Plus
  },
  setup() {
    const route = useRoute();
    const router = useRouter();
    const userStore = useUserStore();
    const formRef = ref<FormInstance>();
    const tagInputRef = ref();
    
    const novelId = computed(() => route.params.id as string);
    const isCreate = computed(() => novelId.value === 'create');
    
    const novel = reactive({
      _id: '',
      title: '',
      description: '',
      coverImage: '',
      genre: '',
      tags: [] as string[],
      status: 'draft',
      author: '',
    });
    
    const originalNovel = ref({});
    const formChanged = computed(() => {
      return JSON.stringify(novel) !== JSON.stringify(originalNovel.value);
    });
    
    const loading = ref(true);
    const saving = ref(false);
    const publishing = ref(false);
    const error = ref('');
    
    const chapters = ref<Chapter[]>([]);
    const loadingChapters = ref(false);
    
    const inputTagVisible = ref(false);
    const inputTag = ref('');
    
    // 表单验证规则
    const rules = reactive<FormRules>({
      title: [
        { required: true, message: '请输入小说标题', trigger: 'blur' },
        { min: 2, max: 50, message: '标题长度应在2到50个字符之间', trigger: 'blur' }
      ],
      description: [
        { required: true, message: '请输入小说简介', trigger: 'blur' },
        { min: 10, max: 1000, message: '简介长度应在10到1000个字符之间', trigger: 'blur' }
      ],
      genre: [
        { required: true, message: '请选择小说类型', trigger: 'change' }
      ]
    });
    
    // 获取小说详情
    const fetchNovelDetails = async () => {
      if (isCreate.value) {
        loading.value = false;
        return;
      }
      
      try {
        loading.value = true;
        const response = await axios.get(`../api/novels/${novelId.value}`);
        const novelData = response.data;
        
        // 更新小说数据
        Object.assign(novel, novelData);
        
        // 保存原始数据用于比较
        originalNovel.value = JSON.parse(JSON.stringify(novelData));
        
        loading.value = false;
        
        // 获取章节列表
        fetchChapters();
      } catch (err) {
        console.error('获取小说详情失败:', err);
        error.value = '获取小说详情失败，请稍后再试';
        loading.value = false;
      }
    };
    
    // 获取章节列表
    const fetchChapters = async () => {
      try {
        loadingChapters.value = true;
        const response = await axios.get(`../api/novels/${novelId.value}/chapters`);
        chapters.value = response.data;
        loadingChapters.value = false;
      } catch (err) {
        console.error('获取章节列表失败:', err);
        showErrorToast('获取章节列表失败，请稍后再试');
        loadingChapters.value = false;
      }
    };
    
    // 保存小说信息
    const saveNovel = async () => {
      if (!formRef.value) return;
      
      await formRef.value.validate(async (valid) => {
        if (valid) {
          saving.value = true;
          
          try {
            let response;
            
            if (isCreate.value) {
              // 创建新小说
              novel.author = userStore.user?.id || '';
              response = await axios.post('../api/novels', novel);
              
              showSuccessToast('小说创建成功');
              router.push(`/author/novel/${response.data._id}/edit`);
            } else {
              // 更新小说
              response = await axios.put(`../api/novels/${novelId.value}`, novel);
              
              // 更新原始数据
              originalNovel.value = JSON.parse(JSON.stringify(novel));
              
              showSuccessToast('保存成功');
            }
          } catch (err) {
            console.error('保存小说失败:', err);
            showErrorToast('保存失败，请稍后再试');
          } finally {
            saving.value = false;
          }
        }
      });
    };
    
    // 发布小说
    const publishNovel = async () => {
      try {
        publishing.value = true;
        
        await axios.put(`../api/novels/${novelId.value}/publish`);
        
        novel.status = 'published';
        originalNovel.value = JSON.parse(JSON.stringify(novel));
        
        showSuccessToast('小说已发布');
        publishing.value = false;
      } catch (err) {
        console.error('发布小说失败:', err);
        showErrorToast('发布失败，请稍后再试');
        publishing.value = false;
      }
    };
    
    // 创建新章节
    const createChapter = async () => {
      try {
        const response = await axios.post(`../api/novels/${novelId.value}/chapters`, {
          title: `第${chapters.value.length + 1}章`,
          chapterNumber: chapters.value.length + 1,
        });
        
        // 跳转到章节编辑页
        router.push(`/author/chapter/${response.data._id}/edit`);
      } catch (err) {
        console.error('创建章节失败:', err);
        showErrorToast('创建章节失败，请稍后再试');
      }
    };
    
    // 编辑章节
    const editChapter = (chapterId: string) => {
      router.push(`/author/chapter/${chapterId}/edit`);
    };
    
    // 确认删除章节
    const confirmDeleteChapter = (chapter: Chapter) => {
      ElMessageBox.confirm(
        `确定要删除章节"${chapter.title}"吗？此操作不可逆。`,
        '警告',
        {
          confirmButtonText: '确定',
          cancelButtonText: '取消',
          type: 'warning',
        }
      )
        .then(() => {
          deleteChapter(chapter._id);
        })
        .catch(() => {
          ElMessage({
            type: 'info',
            message: '已取消删除',
          });
        });
    };
    
    // 删除章节
    const deleteChapter = async (chapterId: string) => {
      try {
        await axios.delete(`../api/chapters/${chapterId}`);
        
        showSuccessToast('删除成功');
        
        // 重新获取章节列表
        fetchChapters();
      } catch (err) {
        console.error('删除章节失败:', err);
        showErrorToast('删除章节失败，请稍后再试');
      }
    };
    
    // 返回上一页
    const goBack = () => {
      router.push('/author/dashboard');
    };
    
    // 显示标签输入框
    const showTagInput = () => {
      inputTagVisible.value = true;
      nextTick(() => {
        tagInputRef.value.input.focus();
      });
    };
    
    // 添加标签
    const addTag = () => {
      if (inputTag.value) {
        if (novel.tags.indexOf(inputTag.value) === -1) {
          novel.tags.push(inputTag.value);
        }
      }
      inputTagVisible.value = false;
      inputTag.value = '';
    };
    
    // 移除标签
    const removeTag = (tag: string) => {
      novel.tags.splice(novel.tags.indexOf(tag), 1);
    };
    
    // 封面上传成功
    const handleCoverSuccess: UploadProps['onSuccess'] = (
      response,
      uploadFile
    ) => {
      novel.coverImage = response.url;
    };
    
    // 封面上传前的验证
    const beforeCoverUpload: UploadProps['beforeUpload'] = (file) => {
      const isJPG = file.type === 'image/jpeg';
      const isPNG = file.type === 'image/png';
      const isLt2M = file.size / 1024 / 1024 < 2;
      
      if (!isJPG && !isPNG) {
        showErrorToast('封面图片只能是 JPG 或 PNG 格式!');
        return false;
      }
      if (!isLt2M) {
        showErrorToast('封面图片大小不能超过 2MB!');
        return false;
      }
      return true;
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
      fetchNovelDetails();
    });
    
    return {
      novel,
      formRef,
      rules,
      loading,
      saving,
      publishing,
      error,
      chapters,
      loadingChapters,
      isCreate,
      tagInputRef,
      inputTagVisible,
      inputTag,
      formChanged,
      saveNovel,
      publishNovel,
      createChapter,
      editChapter,
      confirmDeleteChapter,
      goBack,
      showTagInput,
      addTag,
      removeTag,
      handleCoverSuccess,
      beforeCoverUpload,
      formatDate,
      getStatusType,
      getStatusText,
    };
  },
});
</script>

<style scoped>
.novel-editor {
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

.card-header h3 {
  margin: 0;
}

.loading-container {
  padding: 20px 0;
}

.page-header-title {
  font-size: 18px;
  font-weight: bold;
}

.cover-uploader {
  width: 100%;
  border: 1px dashed #d9d9d9;
  border-radius: 6px;
  cursor: pointer;
  position: relative;
  overflow: hidden;
  transition: border-color 0.3s;
}

.cover-uploader:hover {
  border-color: #409eff;
}

.cover-uploader-icon {
  font-size: 28px;
  color: #8c939d;
  width: 178px;
  height: 250px;
  line-height: 250px;
  text-align: center;
}

.cover-image {
  width: 100%;
  height: 250px;
  display: block;
}

.cover-tip {
  text-align: center;
  margin-top: 8px;
  color: #606266;
  font-size: 12px;
}

.tag-item {
  margin-right: 10px;
  margin-bottom: 10px;
}

.tag-input {
  width: 90px;
  margin-right: 10px;
  vertical-align: bottom;
}

.tag-button {
  margin-bottom: 10px;
}
</style> 
