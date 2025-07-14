const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const NovelSchema = new Schema({
  title: {
    type: String,
    required: true,
    trim: true
  },
  slug: {
    type: String,
    unique: true,
    index: true
  },
  author: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  description: {
    type: String,
    required: true
  },
  coverImage: {
    type: String,
    default: 'https://via.placeholder.com/300x400?text=小说封面'
  },
  tags: [{
    type: String,
    trim: true
  }],
  chapters: [{
    type: Schema.Types.ObjectId,
    ref: 'Chapter'
  }],
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

// 生成slug的函数
function generateSlug(title) {
  return title
    .toLowerCase()
    .replace(/[\s\W-]+/g, '-') // 将空格和非单词字符替换为连字符
    .replace(/^-+|-+$/g, '') // 移除首尾的连字符
    .substring(0, 100); // 限制长度
}

// 在保存前自动生成slug
NovelSchema.pre('save', async function(next) {
  this.updatedAt = Date.now();
  
  // 如果标题被修改或者没有slug，则生成新的slug
  if (this.isModified('title') || !this.slug) {
    let baseSlug = generateSlug(this.title);
    let slug = baseSlug;
    let count = 1;
    
    // 检查slug是否已存在，如果存在则添加数字后缀
    while (true) {
      const existingNovel = await mongoose.model('Novel').findOne({ slug, _id: { $ne: this._id } });
      if (!existingNovel) break;
      
      slug = `${baseSlug}-${count}`;
      count++;
    }
    
    this.slug = slug;
  }
  
  next();
});

module.exports = mongoose.model('Novel', NovelSchema); 