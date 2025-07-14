const express = require('express');
const router = express.Router();
const chapterController = require('../controllers/chapterController');
const auth = require('../middleware/auth');

// @route   GET /api/chapters/:id
// @desc    获取单个章节的详细内容
// @access  Public
router.get('/:id', chapterController.getChapterById);

// @route   PUT /api/chapters/:id
// @desc    更新一个章节的内容
// @access  Private
router.put('/:id', auth, chapterController.updateChapter);

// @route   PUT /api/chapters/:id/publish
// @desc    发布章节
// @access  Private
router.put('/:id/publish', auth, chapterController.publishChapter);

module.exports = router; 