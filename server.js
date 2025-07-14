const express = require('express');
const cors = require('cors');
const http = require('http');
const connectDB = require('./config/db');
const initSocketIO = require('./socket');
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
server.listen(PORT, () => console.log(`服务器运行在端口 ${PORT}`)); 