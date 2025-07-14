const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const ChapterSchema = new Schema({
  novel: {
    type: Schema.Types.ObjectId,
    ref: 'Novel',
    required: true
  },
  title: {
    type: String,
    required: true,
    trim: true
  },
  content: {
    type: String,
    required: true
  },
  chapterNumber: {
    type: Number,
    required: true
  },
  status: {
    type: String,
    enum: ['draft', 'published', 'pending'],
    default: 'draft'
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

// 确保章节编号在同一小说中是唯一的
ChapterSchema.index({ novel: 1, chapterNumber: 1 }, { unique: true });

// 更新updatedAt字段的中间件
ChapterSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

module.exports = mongoose.model('Chapter', ChapterSchema); 