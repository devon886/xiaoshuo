const express = require('express');
const cors = require('cors');
const http = require('http');
const connectDB = require('./db');
const initSocketIO = require('./index');
require('dotenv').config();

// 初始化Express应用
const app = express();
const server = http.createServer(app);

// 初始化Socket.io
const io = initSocketIO(server);

// 连接数据库
connectDB();

// 中间件
app.use(express.json({ extended: false }));
app.use(cors());

// 定义路由
app.use('/api/auth', require('./routes/auth'));
app.use('/api/users', require('./routes/users'));
app.use('/api/novels', require('./routes/novels'));
app.use('/api/novels', require('./routes/novelChapters'));
app.use('/api/chapters', require('./routes/chapters'));
app.use('/api/search', require('./routes/search'));

// 定义基本路由
app.get('/', (req, res) => {
  res.send('小说网站API运行中...');
});

// 设置端口并启动服务器
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server is running on port ${PORT}`)); 
const path = require('path');

// ... 在你定义完所有 API 路由之后，加入以下代码 ...

// 判断是否为生产环境
if (process.env.NODE_ENV === 'production') {
  // 设置静态文件托管，指向前端构建产物 dist 目录
  app.use(express.static(path.join(__dirname, 'dist')));

  // 对于所有未匹配到 API 的请求，都返回前端的入口 index.html
  // 这样 Vue Router 就能接管路由
  app.get('*', (req, res) => {
    res.sendFile(path.resolve(__dirname, 'dist', 'index.html'));
  });
}
