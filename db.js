const mongoose = require('mongoose');
require('dotenv').config();

// MongoDB连接URL
const mongoURI = process.env.MONGO_URI || 'mongodb://localhost:27017/novel-website';

// 连接到MongoDB
const connectDB = async () => {
  try {
    await mongoose.connect(mongoURI, {
      useNewUrlParser: true,
      useUnifiedTopology: true
    });
    console.log('MongoDB连接成功');
  } catch (err) {
    console.error('MongoDB连接失败:', err.message);
    process.exit(1);
  }
};

module.exports = connectDB; 