const Chapter = require('../models/Chapter');
const Novel = require('../models/Novel');

// 获取单个章节的详细内容
exports.getChapterById = async (req, res) => {
  try {
    const chapter = await Chapter.findById(req.params.id)
      .populate('novel', 'title author');
    
    if (!chapter) {
      return res.status(404).json({ message: '章节不存在' });
    }
    
    res.json(chapter);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: '服务器错误' });
  }
};

// 为指定小说添加一个新章节
exports.createChapter = async (req, res) => {
  try {
    const novelId = req.params.novelId;
    const { title, content, chapterNumber } = req.body;
    
    // 查找小说并验证作者权限
    const novel = await Novel.findById(novelId);
    
    if (!novel) {
      return res.status(404).json({ message: '小说不存在' });
    }
    
    // 检查是否为作者本人
    if (novel.author.toString() !== req.user.id) {
      return res.status(403).json({ message: '没有权限为此小说添加章节' });
    }
    
    // 检查章节编号是否已存在
    const existingChapter = await Chapter.findOne({
      novel: novelId,
      chapterNumber
    });
    
    if (existingChapter) {
      return res.status(400).json({ message: '该章节编号已存在' });
    }
    
    // 创建新章节
    const newChapter = new Chapter({
      novel: novelId,
      title,
      content,
      chapterNumber
    });
    
    const chapter = await newChapter.save();
    
    // 将章节ID添加到小说的chapters数组中
    novel.chapters.push(chapter._id);
    await novel.save();
    
    res.status(201).json(chapter);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: '服务器错误' });
  }
};

// 更新一个章节的内容
exports.updateChapter = async (req, res) => {
  try {
    const { title, content, chapterNumber } = req.body;
    
    // 查找章节
    let chapter = await Chapter.findById(req.params.id).populate('novel', 'author');
    
    if (!chapter) {
      return res.status(404).json({ message: '章节不存在' });
    }
    
    // 检查是否为作者本人
    if (chapter.novel.author.toString() !== req.user.id) {
      return res.status(403).json({ message: '没有权限修改此章节' });
    }
    
    // 更新章节信息
    chapter.title = title || chapter.title;
    chapter.content = content || chapter.content;
    if (chapterNumber) chapter.chapterNumber = chapterNumber;
    
    await chapter.save();
    
    res.json(chapter);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: '服务器错误' });
  }
};

// 发布章节
exports.publishChapter = async (req, res) => {
  try {
    // 查找章节
    let chapter = await Chapter.findById(req.params.id).populate('novel', 'author');
    
    if (!chapter) {
      return res.status(404).json({ message: '章节不存在' });
    }
    
    // 检查是否为作者本人
    if (chapter.novel.author.toString() !== req.user.id) {
      return res.status(403).json({ message: '没有权限发布此章节' });
    }
    
    // 更新章节状态
    chapter.status = 'published';
    
    await chapter.save();
    
    res.json({ 
      message: '章节已发布',
      chapter
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: '服务器错误' });
  }
};

// 删除章节
exports.deleteChapter = async (req, res) => {
  try {
    // 查找章节
    const chapter = await Chapter.findById(req.params.chapterId);
    if (!chapter) {
      return res.status(404).json({ message: '章节不存在' });
    }

    // 检查权限
    const novel = await Novel.findById(chapter.novel);
    if (novel.author.toString() !== req.user.id) {
      return res.status(401).json({ message: '没有权限' });
    }

    // 从小说的章节列表中移除该章节
    novel.chapters = novel.chapters.filter(
      chapterId => chapterId.toString() !== req.params.chapterId
    );
    await novel.save();

    // 删除章节
    await chapter.remove();

    res.json({ message: '章节已删除' });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('服务器错误');
  }
}; 