const express = require('express');
const router = express.Router();
const chapterController = require('../controllers/chapterController');
const auth = require('../middleware/auth');

// @route   POST /api/novels/:novelId/chapters
// @desc    为指定小说添加一个新章节
// @access  Private
router.post('/:novelId/chapters', auth, chapterController.createChapter);

module.exports = router; 