const User = require('./User');
const Novel = require('./Novel');
const jwt = require('jsonwebtoken');

// 注册新用户
exports.registerUser = async (req, res) => {
  try {
    const { username, password, nickname } = req.body;

    // 检查用户是否已存在
    let user = await User.findOne({ username });
    if (user) {
      return res.status(400).json({ message: '用户名已被使用' });
    }

    // 创建新用户
    user = new User({
      username,
      password,
      nickname: nickname || undefined
    });

    await user.save();

    // 创建JWT令牌
    const payload = {
      user: {
        id: user.id
      }
    };

    jwt.sign(
      payload,
      process.env.JWT_SECRET || 'defaultsecret',
      { expiresIn: '7d' },
      (err, token) => {
        if (err) throw err;
        res.json({ token });
      }
    );
  } catch (err) {
    console.error(err.message);
    res.status(500).send('服务器错误');
  }
};

// 用户登录
exports.loginUser = async (req, res) => {
  try {
    const { username, password } = req.body;

    // 检查用户是否存在
    const user = await User.findOne({ username });
    if (!user) {
      return res.status(400).json({ message: '用户名或密码不正确' });
    }

    // 验证密码
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(400).json({ message: '用户名或密码不正确' });
    }

    // 创建JWT令牌
    const payload = {
      user: {
        id: user.id
      }
    };

    jwt.sign(
      payload,
      process.env.JWT_SECRET || 'defaultsecret',
      { expiresIn: '7d' },
      (err, token) => {
        if (err) throw err;
        res.json({ token });
      }
    );
  } catch (err) {
    console.error(err.message);
    res.status(500).send('服务器错误');
  }
};

// 获取当前用户信息
exports.getCurrentUser = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password');
    res.json(user);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('服务器错误');
  }
};

// 更新用户信息
exports.updateUser = async (req, res) => {
  try {
    const { nickname, bio, avatar } = req.body;
    
    // 构建更新对象
    const userFields = {};
    if (nickname) userFields.nickname = nickname;
    if (bio) userFields.bio = bio;
    if (avatar) userFields.avatar = avatar;

    // 更新用户
    const user = await User.findByIdAndUpdate(
      req.user.id,
      { $set: userFields },
      { new: true }
    ).select('-password');

    res.json(user);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('服务器错误');
  }
};

// 获取指定用户的公开信息
exports.getUserById = async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('-password');
    
    if (!user) {
      return res.status(404).json({ message: '用户不存在' });
    }

    // 获取用户发布的小说
    const novels = await Novel.find({ author: user._id })
      .select('title description coverImage tags createdAt')
      .sort({ createdAt: -1 });

    res.json({
      user: {
        id: user._id,
        username: user.username,
        nickname: user.nickname,
        avatar: user.avatar,
        bio: user.bio,
        createdAt: user.createdAt
      },
      novels
    });
  } catch (err) {
    console.error(err.message);
    if (err.kind === 'ObjectId') {
      return res.status(404).json({ message: '用户不存在' });
    }
    res.status(500).send('服务器错误');
  }
}; 

// 获取用户发布的小说
exports.getUserNovels = async (req, res) => {
  try {
    const userId = req.params.id;
    
    // 查找该用户发布的所有小说
    const novels = await Novel.find({ author: userId })
      .select('title description coverImage tags createdAt updatedAt')
      .sort({ createdAt: -1 });
    
    res.json(novels);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: '服务器错误' });
  }
}; 