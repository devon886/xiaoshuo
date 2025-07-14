const jwt = require('jsonwebtoken');

module.exports = function(req, res, next) {
  // 从请求头获取token
  const token = req.header('x-auth-token');

  // 检查是否有token
  if (!token) {
    return res.status(401).json({ message: '没有token，授权失败' });
  }

  try {
    // 验证token
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'defaultsecret');

    // 将用户信息添加到请求对象
    req.user = decoded.user;
    next();
  } catch (err) {
    res.status(401).json({ message: 'token无效' });
  }
}; 