const Novel = require('../models/Novel');
const Chapter = require('../models/Chapter');
const mongoose = require('mongoose');

// 获取所有小说的列表（精简信息，支持分页）
exports.getAllNovels = async (req, res) => {
  try {
    // 获取分页参数
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;
    
    // 计算总数量和总页数
    const total = await Novel.countDocuments();
    const totalPages = Math.ceil(total / limit);
    
    // 查询当前页的数据
    const novels = await Novel.find()
      .select('title author description coverImage tags')
      .populate('author', 'username nickname')
      .sort({ createdAt: -1 }) // 按创建时间降序排列
      .skip(skip)
      .limit(limit);
    
    res.json({
      novels,
      pagination: {
        total,
        totalPages,
        currentPage: page,
        limit
      }
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: '服务器错误' });
  }
};

// 获取单本小说的详细信息，包括章节列表
exports.getNovelById = async (req, res) => {
  try {
    const idOrSlug = req.params.id;
    
    // 尝试查找小说（通过ID或slug）
    const novel = await Novel.findOne({
      $or: [
        { _id: mongoose.Types.ObjectId.isValid(idOrSlug) ? idOrSlug : null },
        { slug: idOrSlug }
      ]
    })
      .populate('author', 'username nickname')
      .populate({
        path: 'chapters',
        select: 'title chapterNumber createdAt',
        options: { sort: { chapterNumber: 1 } }
      });
    
    if (!novel) {
      return res.status(404).json({ message: '小说不存在' });
    }
    
    res.json(novel);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: '服务器错误' });
  }
};

// 创建一本新的小说
exports.createNovel = async (req, res) => {
  try {
    const { title, description, coverImage, tags } = req.body;
    
    const newNovel = new Novel({
      title,
      author: req.user.id, // 从JWT获取的用户ID
      description,
      coverImage,
      tags
    });
    
    const novel = await newNovel.save();
    res.status(201).json(novel);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: '服务器错误' });
  }
};

// 更新一本小说的信息
exports.updateNovel = async (req, res) => {
  try {
    const { title, description, coverImage, tags } = req.body;
    
    // 先查找小说
    let novel = await Novel.findById(req.params.id);
    
    if (!novel) {
      return res.status(404).json({ message: '小说不存在' });
    }
    
    // 检查是否为作者本人
    if (novel.author.toString() !== req.user.id) {
      return res.status(403).json({ message: '没有权限修改此小说' });
    }
    
    // 更新小说信息
    novel.title = title || novel.title;
    novel.description = description || novel.description;
    novel.coverImage = coverImage || novel.coverImage;
    novel.tags = tags || novel.tags;
    
    await novel.save();
    
    res.json(novel);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: '服务器错误' });
  }
};

// 删除小说
exports.deleteNovel = async (req, res) => {
  try {
    // 查找小说
    const novel = await Novel.findById(req.params.id);
    if (!novel) {
      return res.status(404).json({ message: '小说不存在' });
    }

    // 确认当前用户是小说作者
    if (novel.author.toString() !== req.user.id) {
      return res.status(401).json({ message: '没有权限' });
    }

    // 删除所有相关章节
    await Chapter.deleteMany({ novel: req.params.id });

    // 删除小说
    await novel.remove();

    res.json({ message: '小说已删除' });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('服务器错误');
  }
}; 