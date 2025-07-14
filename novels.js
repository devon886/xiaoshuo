const express = require('express');
const router = express.Router();
const novelController = require('../controllers/novelController');
const auth = require('../middleware/auth');

// @route   GET /api/novels
// @desc    获取所有小说的列表（精简信息）
// @access  Public
router.get('/', novelController.getAllNovels);

// @route   GET /api/novels/:id
// @desc    获取单本小说的详细信息，包括章节列表
// @access  Public
router.get('/:id', novelController.getNovelById);

// @route   POST /api/novels
// @desc    创建一本新的小说
// @access  Private
router.post('/', auth, novelController.createNovel);

// @route   PUT /api/novels/:id
// @desc    更新一本小说的信息
// @access  Private
router.put('/:id', auth, novelController.updateNovel);

module.exports = router; 