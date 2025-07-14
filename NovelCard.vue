<template>
  <el-card 
    shadow="hover" 
    class="novel-card" 
    @click="navigateToNovel"
    :body-style="{ padding: '0px' }"
  >
    <div class="novel-cover">
      <el-image 
        :src="novel.coverImage || 'https://via.placeholder.com/150x200?text=小说封面'" 
        :alt="novel.title"
        fit="cover"
        lazy
      />
    </div>
    <div class="novel-info">
      <h3 class="novel-title">{{ novel.title }}</h3>
      <p class="author">
        <el-tag size="small" type="info">
          <el-icon><User /></el-icon>
          {{ getAuthorName(novel.author) }}
        </el-tag>
      </p>
    </div>
  </el-card>
</template>

<script lang="ts">
import { defineComponent, PropType } from 'vue';
import { useRouter } from 'vue-router';
import { User } from '@element-plus/icons-vue';

interface Author {
  _id: string;
  username: string;
  nickname?: string;
}

interface Novel {
  _id: string;
  title: string;
  author: Author | string;
  coverImage: string;
  description: string;
  slug?: string;
}

export default defineComponent({
  name: 'NovelCard',
  components: {
    User
  },
  props: {
    novel: {
      type: Object as PropType<Novel>,
      required: true
    }
  },
  setup(props) {
    const router = useRouter();
    
    const navigateToNovel = () => {
      // 如果有slug则使用slug，否则使用ID
      const identifier = props.novel.slug || props.novel._id;
      router.push(`/novel/${identifier}`);
    };
    
    const getAuthorName = (author: Author | string) => {
      if (!author) return '未知作者';
      if (typeof author === 'string') return '未知作者';
      return author.nickname || author.username || '未知作者';
    };
    
    return {
      navigateToNovel,
      getAuthorName
    };
  }
});
</script>

<style scoped>
.novel-card {
  height: 100%;
  cursor: pointer;
  transition: transform 0.3s ease;
}

.novel-card:hover {
  transform: translateY(-5px);
}

.novel-cover {
  width: 100%;
  height: 200px;
  overflow: hidden;
}

.novel-cover :deep(.el-image) {
  width: 100%;
  height: 100%;
}

.novel-info {
  padding: 15px;
}

.novel-title {
  margin: 0 0 10px 0;
  font-size: 18px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.author {
  margin: 0;
}
</style> 