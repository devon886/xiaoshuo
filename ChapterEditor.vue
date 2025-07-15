<template>
  <div class="chapter-editor">
    <el-row :gutter="20" class="mb-4">
      <el-col :span="24">
        <el-page-header @back="goBack" title="章节编辑">
          <template #content>
            <span class="page-header-title">{{ chapter.title || '未命名章节' }}</span>
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
      <el-row :gutter="20" class="mb-4">
        <el-col :span="24">
          <el-card shadow="hover">
            <template #header>
              <div class="card-header">
                <div class="chapter-info">
                  <h3>{{ novelTitle }}</h3>
                  <el-tag v-if="chapter.status" :type="getStatusType(chapter.status)" class="ml-2">
                    {{ getStatusText(chapter.status) }}
                  </el-tag>
                </div>
                <div class="action-buttons">
                  <el-tag class="save-status ml-2" :type="saveStatusType">
                    {{ saveStatusText }}
                  </el-tag>
                  <el-button 
                    type="success" 
                    @click="saveChapter" 
                    :loading="saving"
                    :disabled="!contentChanged || saveStatus === 'saving'"
                  >
                    保存
                  </el-button>
                  <el-button 
                    v-if="chapter.status !== 'published'" 
                    type="primary" 
                    @click="publishChapter"
                    :loading="publishing"
                  >
                    发布
                  </el-button>
                </div>
              </div>
            </template>

            <el-form ref="formRef" :model="chapter" :rules="rules" label-position="top">
              <el-form-item label="章节标题" prop="title">
                <el-input 
                  v-model="chapter.title" 
                  placeholder="请输入章节标题" 
                  @input="markAsChanged"
                />
              </el-form-item>
              
              <el-form-item label="章节序号" prop="chapterNumber">
                <el-input-number 
                  v-model="chapter.chapterNumber" 
                  :min="1" 
                  :step="1"
                  @change="markAsChanged"
                />
              </el-form-item>

              <el-form-item label="章节内容" prop="content" class="content-editor">
                <div ref="editorContainer" class="editor-container"></div>
              </el-form-item>
            </el-form>
          </el-card>
        </el-col>
      </el-row>
    </template>
  </div>
</template>

<script lang="ts">
import { defineComponent, ref, reactive, computed, onMounted, onBeforeUnmount, nextTick, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { ElMessageBox } from 'element-plus';
import axios from 'axios';
import Quill from 'quill';
import 'quill/dist/quill.snow.css';
import type { FormInstance, FormRules } from 'element-plus';
import { io, Socket } from 'socket.io-client';
import { showSuccessToast, showErrorToast, showInfoToast } from '../../utils/toast';

export default defineComponent({
  name: 'ChapterEditor',
  setup() {
    const route = useRoute();
    const router = useRouter();
    const formRef = ref<FormInstance>();
    const editorContainer = ref<HTMLElement | null>(null);
    
    const chapterId = computed(() => route.params.id as string);
    
    const chapter = reactive({
      _id: '',
      title: '',
      content: '',
      chapterNumber: 1,
      novel: '',
      status: 'draft',
      createdAt: '',
      updatedAt: '',
    });
    
    const novelTitle = ref('');
    const originalChapter = ref({});
    const contentChanged = ref(false);
    
    const loading = ref(true);
    const saving = ref(false);
    const publishing = ref(false);
    const error = ref('');
    
    // Socket.io 连接和自动保存状态
    let socket: Socket | null = null;
    const saveStatus = ref<'saved' | 'saving' | 'error' | 'idle'>('idle');
    const saveStatusText = computed(() => {
      const statusMap = {
        'saved': '所有更改已保存',
        'saving': '正在保存...',
        'error': '保存失败',
        'idle': '准备就绪'
      };
      return statusMap[saveStatus.value];
    });
    const saveStatusType = computed(() => {
      const statusMap = {
        'saved': 'success',
        'saving': 'info',
        'error': 'danger',
        'idle': ''
      };
      return statusMap[saveStatus.value];
    });
    
    let editor: any = null;
    let saveInterval: number | null = null;
    let saveDebounceTimer: number | null = null;
    
    // 表单验证规则
    const rules = reactive<FormRules>({
      title: [
        { required: true, message: '请输入章节标题', trigger: 'blur' },
        { min: 2, max: 100, message: '标题长度应在2到100个字符之间', trigger: 'blur' }
      ],
      chapterNumber: [
        { required: true, message: '请输入章节序号', trigger: 'blur' }
      ],
      content: [
        { required: true, message: '请输入章节内容', trigger: 'blur' }
      ]
    });
    
    // 初始化 Socket.io 连接
    const initSocketConnection = () => {
      socket = io('../api/novels', {
        auth: {
          token: localStorage.getItem('token') // 使用存储的用户令牌进行身份验证
        }
      });
      
      socket.on('connect', () => {
        console.log('已连接到 Socket.io 服务器');
      });
      
      socket.on('save-success', (data) => {
        if (data.chapterId === chapter._id) {
          saveStatus.value = 'saved';
          contentChanged.value = false;
          // 更新原始数据
          originalChapter.value = JSON.parse(JSON.stringify(chapter));
        }
      });
      
      socket.on('save-error', (data) => {
        if (data.chapterId === chapter._id) {
          saveStatus.value = 'error';
          showErrorToast(data.message || '自动保存失败');
        }
      });
      
      socket.on('disconnect', () => {
        console.log('与 Socket.io 服务器断开连接');
      });
    };
    
    // 获取章节详情
    const fetchChapterDetails = async () => {
      try {
        loading.value = true;
        const response = await axios.get(`../api/novels/${chapterId.value}`);
        const chapterData = response.data;
        
        // 更新章节数据
        Object.assign(chapter, chapterData);
        
        // 保存原始数据用于比较
        originalChapter.value = JSON.parse(JSON.stringify(chapterData));
        
        // 获取小说标题
        fetchNovelTitle(chapterData.novel);
        
        loading.value = false;
        
        // 初始化编辑器
        nextTick(() => {
          initQuillEditor();
        });
      } catch (err) {
        console.error('获取章节详情失败:', err);
        error.value = '获取章节详情失败，请稍后再试';
        loading.value = false;
      }
    };
    
    // 获取小说标题
    const fetchNovelTitle = async (novelId: string) => {
      try {
        const response = await axios.get(`../api/chapters/${novelId}`);
        novelTitle.value = response.data.title;
      } catch (err) {
        console.error('获取小说标题失败:', err);
      }
    };
    
    // 初始化 Quill 编辑器
    const initQuillEditor = () => {
      if (!editorContainer.value) return;
      
      // Quill 编辑器配置
      const toolbarOptions = [
        ['bold', 'italic', 'underline', 'strike'],
        ['blockquote', 'code-block'],
        [{ 'header': 1 }, { 'header': 2 }],
        [{ 'list': 'ordered' }, { 'list': 'bullet' }],
        [{ 'indent': '-1' }, { 'indent': '+1' }],
        [{ 'direction': 'rtl' }],
        [{ 'size': ['small', false, 'large', 'huge'] }],
        [{ 'header': [1, 2, 3, 4, 5, 6, false] }],
        [{ 'color': [] }, { 'background': [] }],
        [{ 'font': [] }],
        [{ 'align': [] }],
        ['clean']
      ];
      
      // 创建 Quill 实例
      editor = new Quill(editorContainer.value, {
        modules: {
          toolbar: toolbarOptions
        },
        theme: 'snow',
        placeholder: '请输入章节内容...'
      });
      
      // 设置初始内容
      if (chapter.content) {
        editor.root.innerHTML = chapter.content;
      }
      
      // 监听内容变化
      editor.on('text-change', () => {
        chapter.content = editor.root.innerHTML;
        markAsChanged();
      });
    };
    
    // 标记内容已修改并触发自动保存
    const markAsChanged = () => {
      contentChanged.value = true;
      debouncedAutoSave();
    };
    
    // 防抖自动保存
    const debouncedAutoSave = () => {
      if (saveDebounceTimer) {
        clearTimeout(saveDebounceTimer);
      }
      
      saveDebounceTimer = window.setTimeout(() => {
        autoSaveChapter();
      }, 2000); // 2秒后触发自动保存
    };
    
    // 通过 Socket.io 自动保存章节
    const autoSaveChapter = () => {
      if (!contentChanged.value || !socket || !chapter._id) return;
      
      // 更新内容
      if (editor) {
        chapter.content = editor.root.innerHTML;
      }
      
      // 设置保存状态
      saveStatus.value = 'saving';
      
      // 发送保存事件到服务器
      socket.emit('save-chapter', {
        chapterId: chapter._id,
        title: chapter.title,
        content: chapter.content,
        chapterNumber: chapter.chapterNumber
      });
    };
    
    // 手动保存章节
    const saveChapter = async () => {
      if (!formRef.value) return;
      
      // 更新内容
      if (editor) {
        chapter.content = editor.root.innerHTML;
      }
      
      await formRef.value.validate(async (valid) => {
        if (valid) {
          saving.value = true;
          saveStatus.value = 'saving';
          
          try {
            await axios.put(`../api/chapters/${chapterId.value}`, chapter);
            
            // 更新原始数据
            originalChapter.value = JSON.parse(JSON.stringify(chapter));
            contentChanged.value = false;
            saveStatus.value = 'saved';
            
            showSuccessToast('保存成功');
          } catch (err) {
            console.error('保存章节失败:', err);
            showErrorToast('保存失败，请稍后再试');
            saveStatus.value = 'error';
          } finally {
            saving.value = false;
          }
        }
      });
    };
    
    // 发布章节
    const publishChapter = async () => {
      // 先保存当前内容
      if (contentChanged.value) {
        ElMessageBox.confirm(
          '发布前需要先保存当前内容，是否继续？',
          '提示',
          {
            confirmButtonText: '保存并发布',
            cancelButtonText: '取消',
            type: 'info',
          }
        )
          .then(() => {
            saveChapter().then(() => {
              doPublish();
            });
          })
          .catch(() => {
            showInfoToast('已取消发布');
          });
      } else {
        doPublish();
      }
    };
    
    // 执行发布操作
    const doPublish = async () => {
      try {
        publishing.value = true;
        
        await axios.put(`../api/chapters/${chapterId.value}/publish`);
        
        chapter.status = 'published';
        originalChapter.value = JSON.parse(JSON.stringify(chapter));
        contentChanged.value = false;
        
        showSuccessToast('章节已发布');
        publishing.value = false;
      } catch (err) {
        console.error('发布章节失败:', err);
        showErrorToast('发布失败，请稍后再试');
        publishing.value = false;
      }
    };
    
    // 返回小说编辑页
    const goBack = () => {
      if (contentChanged.value) {
        ElMessageBox.confirm(
          '您有未保存的修改，确定要离开吗？',
          '警告',
          {
            confirmButtonText: '离开',
            cancelButtonText: '取消',
            type: 'warning',
          }
        )
          .then(() => {
            navigateBack();
          })
          .catch(() => {});
      } else {
        navigateBack();
      }
    };
    
    // 导航回小说编辑页
    const navigateBack = () => {
      router.push(`/author/novel/${chapter.novel}/edit`);
    };
    
    // 监听标题和章节序号变化
    watch(() => chapter.title, () => {
      markAsChanged();
    });
    
    watch(() => chapter.chapterNumber, () => {
      markAsChanged();
    });
    
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
    
    // 离开前提示保存
    const beforeUnload = (e: BeforeUnloadEvent) => {
      if (contentChanged.value) {
        e.preventDefault();
        e.returnValue = '';
      }
    };
    
    onMounted(() => {
      fetchChapterDetails();
      initSocketConnection();
      window.addEventListener('beforeunload', beforeUnload);
    });
    
    onBeforeUnmount(() => {
      if (saveInterval) {
        clearInterval(saveInterval);
      }
      if (saveDebounceTimer) {
        clearTimeout(saveDebounceTimer);
      }
      if (socket) {
        socket.disconnect();
      }
      window.removeEventListener('beforeunload', beforeUnload);
    });
    
    return {
      chapter,
      formRef,
      editorContainer,
      rules,
      loading,
      saving,
      publishing,
      error,
      novelTitle,
      contentChanged,
      saveChapter,
      publishChapter,
      goBack,
      markAsChanged,
      formatDate,
      getStatusType,
      getStatusText,
      saveStatus,
      saveStatusText,
      saveStatusType,
    };
  },
});
</script>

<style scoped>
.chapter-editor {
  padding: 20px;
}

.mb-4 {
  margin-bottom: 20px;
}

.ml-2 {
  margin-left: 8px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.chapter-info {
  display: flex;
  align-items: center;
}

.chapter-info h3 {
  margin: 0;
}

.loading-container {
  padding: 20px 0;
}

.page-header-title {
  font-size: 18px;
  font-weight: bold;
}

.content-editor {
  margin-top: 20px;
}

.editor-container {
  height: 500px;
  margin-bottom: 30px;
}

.save-status {
  margin-right: 10px;
}

/* 覆盖 Quill 编辑器样式 */
:deep(.ql-container) {
  font-size: 16px;
  font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
}

:deep(.ql-editor) {
  min-height: 450px;
}
</style> 
