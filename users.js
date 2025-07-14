const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const auth = require('../middleware/auth');

// @route   POST api/users/register
// @desc    注册用户
// @access  Public
router.post('/register', userController.registerUser);

// @route   POST api/users/login
// @desc    用户登录
// @access  Public
router.post('/login', userController.loginUser);

// @route   GET /api/users/me
// @desc    获取当前用户信息
// @access  Private
router.get('/me', auth, userController.getCurrentUser);

// @route   PUT /api/users/me
// @desc    更新当前用户信息
// @access  Private
router.put('/me', auth, userController.updateUser);

// @route   GET /api/users/:id
// @desc    获取用户公开信息
// @access  Public
router.get('/:id', userController.getUserById);

// @route   GET /api/users/:id/novels
// @desc    获取用户发布的小说
// @access  Public
router.get('/:id/novels', userController.getUserNovels);

module.exports = router; 