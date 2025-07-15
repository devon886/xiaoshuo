const express = require('express');
const router = express.Router();
const searchController = require('./searchController');

// @route   GET /api/search
// @desc    搜索小说
// @access  Public
router.get('/', searchController.searchNovels);

module.exports = router; 