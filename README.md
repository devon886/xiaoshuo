# 小说网站后端API

基于Node.js、Express和MongoDB的小说网站后端API。

## 功能

- 用户认证（注册、登录）
- 用户资料管理
- 小说创建和管理
- 章节创建和管理

## 数据模型

### User模型
- 用户名（字符串、必需、唯一）
- 密码（字符串，必需）
- 昵称（字符串，默认："新用户"）
- 头像（字符串，默认：默认头像URL）
- 个人简介（字符串，默认："这个人很懒，什么都没留下。"）
- 创建时间（日期，默认：Date.now）

### Novel模型
- 标题（字符串，必需）
- 作者（ObjectId，参考："User"，必需）
- 描述（字符串，必需）
- 封面图片（字符串，默认：默认封面URL）
- 标签（字符串数组）
- 章节（ObjectId数组，参考：'Chapter'）
- 创建时间（日期，默认：Date.now）
- 更新时间（日期，默认：Date.now）

### Chapter模型
- 小说（ObjectId，参考：'Novel'，必填）
- 标题（字符串，必需）
- 内容（字符串，必需）
- 章节编号（数字，必填）
- 创建时间（日期，默认：Date.now）

## API端点

### 用户相关
- POST /api/users/register - 注册新用户
- POST /api/users/login - 用户登录
- GET /api/users/me - 获取当前用户信息
- PUT /api/users/me - 更新用户信息

### 小说相关
- POST /api/novels - 创建新小说
- GET /api/novels - 获取所有小说
- GET /api/novels/:id - 获取单个小说详情
- PUT /api/novels/:id - 更新小说信息
- DELETE /api/novels/:id - 删除小说

### 章节相关
- POST /api/novels/:novelId/chapters - 创建新章节
- GET /api/chapters/:chapterId - 获取章节内容
- PUT /api/chapters/:chapterId - 更新章节内容
- DELETE /api/chapters/:chapterId - 删除章节

## 安装和运行

1. 安装依赖
```
npm install
```

2. 创建.env文件并配置环境变量
```
PORT=5000
MONGO_URI=mongodb://localhost:27017/novel-website
JWT_SECRET=your_jwt_secret_key
NODE_ENV=development
```

3. 运行开发服务器
```
npm run dev
```

4. 生产环境运行
```
npm start
``` 