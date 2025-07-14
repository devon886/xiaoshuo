<template>
  <div class="register-page">
    <el-card class="auth-card">
      <template #header>
        <h2 class="card-title">注册</h2>
      </template>
      
      <el-alert
        v-if="error"
        type="error"
        :title="error"
        show-icon
        :closable="false"
        class="mb-4"
      />
      
      <el-form 
        ref="formRef"
        :model="formData"
        :rules="rules"
        label-position="top"
        @submit.prevent="handleSubmit"
      >
        <el-form-item label="用户名" prop="username">
          <el-input 
            v-model="formData.username" 
            placeholder="请输入用户名"
            :disabled="loading"
            prefix-icon="User"
          />
        </el-form-item>
        
        <el-form-item label="密码" prop="password">
          <el-input 
            v-model="formData.password" 
            type="password" 
            placeholder="请输入密码"
            :disabled="loading"
            prefix-icon="Lock"
            show-password
          />
        </el-form-item>
        
        <el-form-item label="确认密码" prop="confirmPassword">
          <el-input 
            v-model="formData.confirmPassword" 
            type="password" 
            placeholder="请再次输入密码"
            :disabled="loading"
            prefix-icon="Lock"
            show-password
          />
        </el-form-item>
        
        <el-form-item label="昵称 (可选)" prop="nickname">
          <el-input 
            v-model="formData.nickname" 
            placeholder="请输入昵称"
            :disabled="loading"
            prefix-icon="UserFilled"
          />
        </el-form-item>
        
        <el-form-item>
          <el-button 
            type="primary" 
            native-type="submit" 
            :loading="loading"
            class="submit-btn"
          >
            注册
          </el-button>
        </el-form-item>
      </el-form>
      
      <div class="auth-switch">
        已有账号？
        <router-link to="/login">
          <el-link type="primary">立即登录</el-link>
        </router-link>
      </div>
    </el-card>
  </div>
</template>

<script lang="ts">
import { defineComponent, ref, reactive } from 'vue';
import { useRouter } from 'vue-router';
import { useUserStore } from '../stores/userStore';
import { ElMessage } from 'element-plus';
import type { FormInstance, FormRules } from 'element-plus';

export default defineComponent({
  name: 'RegisterPage',
  setup() {
    const router = useRouter();
    const userStore = useUserStore();
    const formRef = ref<FormInstance>();
    
    // 表单数据
    const formData = reactive({
      username: '',
      password: '',
      confirmPassword: '',
      nickname: ''
    });
    
    // 自定义验证规则：确认密码
    const validateConfirmPassword = (rule: any, value: string, callback: any) => {
      if (value === '') {
        callback(new Error('请再次输入密码'));
      } else if (value !== formData.password) {
        callback(new Error('两次输入的密码不一致'));
      } else {
        callback();
      }
    };
    
    // 表单验证规则
    const rules = reactive<FormRules>({
      username: [
        { required: true, message: '请输入用户名', trigger: 'blur' },
        { min: 3, message: '用户名长度不能小于3个字符', trigger: 'blur' }
      ],
      password: [
        { required: true, message: '请输入密码', trigger: 'blur' },
        { min: 6, message: '密码长度不能小于6个字符', trigger: 'blur' }
      ],
      confirmPassword: [
        { required: true, message: '请再次输入密码', trigger: 'blur' },
        { validator: validateConfirmPassword, trigger: 'blur' }
      ],
      nickname: [
        { max: 20, message: '昵称长度不能超过20个字符', trigger: 'blur' }
      ]
    });
    
    const loading = ref(false);
    const error = ref('');
    
    // 处理表单提交
    const handleSubmit = async () => {
      if (!formRef.value) return;
      
      await formRef.value.validate(async (valid) => {
        if (valid) {
          try {
            loading.value = true;
            error.value = '';
            
            const result = await userStore.register(
              formData.username, 
              formData.password, 
              formData.nickname || undefined
            );
            
            if (result.success) {
              ElMessage({
                type: 'success',
                message: '注册成功'
              });
              
              // 注册成功，跳转到首页
              router.push('/');
            } else {
              error.value = result.error || '注册失败，请稍后再试';
            }
          } catch (err: any) {
            console.error('注册错误:', err);
            error.value = '发生错误，请稍后再试';
          } finally {
            loading.value = false;
          }
        }
      });
    };
    
    return {
      formRef,
      formData,
      rules,
      loading,
      error,
      handleSubmit
    };
  }
});
</script>

<style scoped>
.register-page {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: calc(100vh - 140px);
  padding: 20px;
}

.auth-card {
  width: 100%;
  max-width: 400px;
}

.card-title {
  margin: 0;
  text-align: center;
  font-size: 24px;
}

.submit-btn {
  width: 100%;
}

.auth-switch {
  margin-top: 20px;
  text-align: center;
  font-size: 14px;
}

.mb-4 {
  margin-bottom: 20px;
}
</style> 