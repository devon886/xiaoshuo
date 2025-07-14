const Novel = require('../models/Novel');
const User = require('../models/User');

// 搜索小说
exports.searchNovels = async (req, res) => {
  try {
    const { q } = req.query;
    
    if (!q || q.trim() === '') {
      return res.json([]);
    }
    
    // 创建搜索关键词的正则表达式（不区分大小写）
    const searchRegex = new RegExp(q, 'i');
    
    // 查找匹配的小说
    const novels = await Novel.find({
      $or: [
        { title: searchRegex },
        { description: searchRegex },
        // 标签中包含搜索词
        { tags: searchRegex }
      ]
    }).populate('author', 'username nickname');
    
    // 查找匹配作者名的小说
    const authors = await User.find({
      $or: [
        { username: searchRegex },
        { nickname: searchRegex }
      ]
    });
    
    const authorIds = authors.map(author => author._id);
    
    // 查找这些作者的小说
    const novelsByAuthor = await Novel.find({
      author: { $in: authorIds }
    }).populate('author', 'username nickname');
    
    // 合并结果并去重
    const allNovels = [...novels];
    
    novelsByAuthor.forEach(novel => {
      // 检查是否已经在结果中
      const exists = allNovels.some(n => n._id.toString() === novel._id.toString());
      if (!exists) {
        allNovels.push(novel);
      }
    });
    
    res.json(allNovels);
  } catch (err) {
    console.error('搜索失败:', err);
    res.status(500).json({ message: '服务器错误' });
  }
}; 