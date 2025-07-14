const socketIo = require('socket.io');
const jwt = require('jsonwebtoken');
const Chapter = require('../models/Chapter');
const Novel = require('../models/Novel');

// 初始化Socket.io服务
const initSocketIO = (server) => {
  const io = socketIo(server, {
    cors: {
      origin: '*', // 在生产环境中应该限制为特定域名
      methods: ['GET', 'POST']
    }
  });

  // 协作房间管理
  const rooms = new Map();
  
  // 中间件处理身份验证
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token;
      
      if (!token) {
        return next(new Error('身份验证失败'));
      }
      
      // 验证令牌
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      socket.userId = decoded.id;
      next();
    } catch (err) {
      console.error('Socket.io 身份验证错误:', err);
      next(new Error('身份验证失败'));
    }
  });

  // Socket.io连接处理
  io.on('connection', (socket) => {
    console.log('新客户端连接:', socket.id, '用户ID:', socket.userId);

    // 加入特定的协作房间
    socket.on('join-room', (roomId) => {
      socket.join(roomId);
      console.log(`客户端 ${socket.id} 加入房间 ${roomId}`);
      
      // 初始化房间数据（如果不存在）
      if (!rooms.has(roomId)) {
        rooms.set(roomId, {
          users: new Set(),
          lastContent: ''
        });
      }
      
      // 添加用户到房间
      const room = rooms.get(roomId);
      room.users.add(socket.id);
      
      // 发送当前房间内容给新用户
      if (room.lastContent) {
        socket.emit('init-content', room.lastContent);
      }
      
      // 通知房间内其他人有新用户加入
      socket.to(roomId).emit('user-connected', {
        userId: socket.id,
        userCount: room.users.size
      });
    });

    // 处理文本更新
    socket.on('text-update', (data) => {
      const { roomId, text, cursorPosition } = data;
      
      // 更新房间的最新内容
      if (rooms.has(roomId)) {
        rooms.get(roomId).lastContent = text;
      }
      
      // 广播文本更新给房间内的其他用户
      socket.to(roomId).emit('text-updated', {
        text,
        cursorPosition,
        userId: socket.id
      });
      
      console.log(`收到来自 ${socket.id} 的文本更新，房间: ${roomId}`);
    });
    
    // 处理章节自动保存
    socket.on('save-chapter', async (data) => {
      try {
        const { chapterId, title, content, chapterNumber } = data;
        
        // 查找章节
        const chapter = await Chapter.findById(chapterId).populate('novel', 'author');
        
        if (!chapter) {
          socket.emit('save-error', {
            chapterId,
            message: '章节不存在'
          });
          return;
        }
        
        // 验证权限（只有章节所属小说的作者才能保存）
        if (chapter.novel.author.toString() !== socket.userId) {
          socket.emit('save-error', {
            chapterId,
            message: '没有权限修改此章节'
          });
          return;
        }
        
        // 更新章节
        chapter.title = title || chapter.title;
        chapter.content = content || chapter.content;
        if (chapterNumber) chapter.chapterNumber = chapterNumber;
        
        await chapter.save();
        
        // 发送保存成功事件
        socket.emit('save-success', {
          chapterId,
          message: '保存成功',
          updatedAt: chapter.updatedAt || new Date()
        });
        
        console.log(`章节 ${chapterId} 已自动保存`);
      } catch (err) {
        console.error('自动保存章节失败:', err);
        socket.emit('save-error', {
          chapterId: data.chapterId,
          message: '保存失败，请稍后再试'
        });
      }
    });

    // 离开房间
    socket.on('leave-room', (roomId) => {
      handleLeaveRoom(socket, roomId);
    });

    // 处理断开连接
    socket.on('disconnect', () => {
      console.log('客户端断开连接:', socket.id);
      
      // 从所有房间中移除用户
      rooms.forEach((room, roomId) => {
        if (room.users.has(socket.id)) {
          handleLeaveRoom(socket, roomId);
        }
      });
    });
  });

  // 处理用户离开房间的逻辑
  const handleLeaveRoom = (socket, roomId) => {
    if (rooms.has(roomId)) {
      const room = rooms.get(roomId);
      
      // 从房间中移除用户
      room.users.delete(socket.id);
      
      // 通知其他用户
      socket.to(roomId).emit('user-disconnected', {
        userId: socket.id,
        userCount: room.users.size
      });
      
      // 如果房间为空，则删除房间数据
      if (room.users.size === 0) {
        rooms.delete(roomId);
        console.log(`房间 ${roomId} 已删除（无用户）`);
      }
    }
    
    // 离开房间
    socket.leave(roomId);
    console.log(`客户端 ${socket.id} 离开房间 ${roomId}`);
  };

  return io;
};

module.exports = initSocketIO; 