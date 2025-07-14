const http = require('http');
const express = require('express');
const socketIo = require('socket.io');
const cors = require('cors');

// 创建Express应用
const app = express();
app.use(cors());

// 创建HTTP服务器
const server = http.createServer(app);

// 创建Socket.io实例
const io = socketIo(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

// 基本路由
app.get('/', (req, res) => {
  res.send('Socket.io测试服务器运行中...');
});

// Socket.io连接处理
io.on('connection', (socket) => {
  console.log('新客户端连接:', socket.id);

  // 加入特定的协作房间
  socket.on('join-room', (roomId) => {
    socket.join(roomId);
    console.log(`客户端 ${socket.id} 加入房间 ${roomId}`);
    
    // 通知房间内其他人有新用户加入
    socket.to(roomId).emit('user-connected', socket.id);
  });

  // 处理文本更新
  socket.on('text-update', (data) => {
    const { roomId, text, cursorPosition } = data;
    
    console.log(`收到来自 ${socket.id} 的文本更新，房间: ${roomId}`);
    console.log(`文本内容: ${text.substring(0, 20)}...`);
    
    // 广播文本更新给房间内的其他用户
    socket.to(roomId).emit('text-updated', {
      text,
      cursorPosition,
      userId: socket.id
    });
  });

  // 处理断开连接
  socket.on('disconnect', () => {
    console.log('客户端断开连接:', socket.id);
  });
});

// 启动服务器
const PORT = process.env.PORT || 5001;
server.listen(PORT, () => {
  console.log(`Socket.io测试服务器运行在端口 ${PORT}`);
}); 