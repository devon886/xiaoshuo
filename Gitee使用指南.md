# 📁 Gitee代码托管指南 (国内推荐)

## 🎯 为什么选择Gitee

- **速度快** - 国内访问速度比GitHub快10倍
- **稳定性** - 不受网络环境影响
- **中文界面** - 完全中文支持
- **免费服务** - 个人项目完全免费
- **企业支持** - 国内企业首选

---

## 🚀 快速开始

### 1. 注册Gitee账号

1. 访问 [Gitee官网](https://gitee.com)
2. 点击右上角"注册"
3. 使用手机号或邮箱注册
4. 完成手机验证

### 2. 创建仓库

1. 登录后点击 "+" → "新建仓库"
2. 填写仓库信息:
   ```
   仓库名称: novel-website
   仓库介绍: 小说网站项目
   选择语言: JavaScript
   添加.gitignore: Node
   选择开源许可证: MIT
   ```
3. 点击"创建"

### 3. 上传您的项目代码

#### 方法1: 通过网页上传 (推荐新手)

1. 在仓库页面点击"上传文件"
2. 拖拽或选择项目文件夹
3. 填写提交信息: "初始化小说网站项目"
4. 点击"提交"

#### 方法2: 使用Git命令行

```bash
# 在项目目录下执行
git init
git add .
git commit -m "初始化小说网站项目"
git remote add origin https://gitee.com/您的用户名/novel-website.git
git push -u origin master
```

---

## 🔧 部署配置

### 获取仓库地址

在Gitee项目页面，点击"克隆/下载"，复制HTTPS地址:
```
https://gitee.com/您的用户名/novel-website.git
```

### 在部署脚本中使用

运行 `deploy-china.sh` 时，输入Gitee仓库地址:
```bash
请输入Gitee仓库地址: https://gitee.com/您的用户名/novel-website.git
```

### 自动部署配置

1. **推送代码到Gitee**
   ```bash
   git add .
   git commit -m "更新网站功能"
   git push origin master
   ```

2. **服务器自动拉取更新**
   ```bash
   # 在服务器上执行
   cd /home/novel-website
   git pull origin master
   npm install --production
   pm2 restart novel-website
   ```

---

## 🎨 Gitee Pages (免费静态网站)

### 启用Gitee Pages

1. 在仓库页面点击"服务" → "Gitee Pages"
2. 选择部署分支: `master`
3. 选择部署目录: `dist` (前端构建产物)
4. 点击"启动"

### 访问地址
```
https://您的用户名.gitee.io/novel-website
```

### 自动更新Pages

每次推送代码后，需要手动更新Pages:
1. 进入仓库的 Gitee Pages 页面
2. 点击"更新"按钮

---

## 🔄 版本管理最佳实践

### 分支策略

```bash
# 主分支 (生产环境)
master

# 开发分支
git checkout -b develop

# 功能分支
git checkout -b feature/user-login

# 修复分支
git checkout -b hotfix/login-bug
```

### 提交规范

```bash
# 功能新增
git commit -m "feat: 添加用户登录功能"

# 错误修复
git commit -m "fix: 修复登录页面显示问题"

# 文档更新
git commit -m "docs: 更新部署文档"

# 代码重构
git commit -m "refactor: 重构用户管理模块"
```

### 标签管理

```bash
# 创建版本标签
git tag v1.0.0
git push origin v1.0.0

# 查看所有标签
git tag -l

# 删除标签
git tag -d v1.0.0
git push origin :refs/tags/v1.0.0
```

---

## 👥 团队协作

### 添加团队成员

1. 在仓库页面点击"管理" → "仓库成员管理"
2. 点击"添加仓库成员"
3. 输入成员的Gitee用户名或邮箱
4. 选择权限级别:
   - **管理者**: 完全权限
   - **开发者**: 读写权限
   - **报告者**: 只读权限

### Pull Request 工作流

1. **创建功能分支**
   ```bash
   git checkout -b feature/new-chapter-editor
   ```

2. **开发并提交**
   ```bash
   git add .
   git commit -m "feat: 新增章节编辑器"
   git push origin feature/new-chapter-editor
   ```

3. **创建Pull Request**
   - 在Gitee页面点击"Pull Requests"
   - 点击"新建Pull Request"
   - 选择源分支和目标分支
   - 填写说明信息
   - 指定审查人员

4. **代码审查与合并**
   - 团队成员审查代码
   - 讨论和修改
   - 审查通过后合并到主分支

---

## 🛡️ 私有仓库配置

### 设置仓库为私有

1. 进入仓库"设置" → "基本信息"
2. 在"仓库属性"中选择"私有"
3. 保存设置

### 访问权限管理

1. **SSH密钥配置** (推荐)
   ```bash
   # 生成SSH密钥
   ssh-keygen -t rsa -C "your-email@example.com"
   
   # 添加到Gitee
   cat ~/.ssh/id_rsa.pub
   # 复制内容到Gitee个人设置 → SSH公钥
   ```

2. **HTTPS访问令牌**
   - 个人设置 → 私人令牌
   - 生成新令牌
   - 使用令牌代替密码

---

## 📊 项目管理功能

### Issue 管理

1. **创建Issue**
   - 点击"Issues" → "新建Issue"
   - 分类: Bug报告、功能请求、文档改进
   - 指派给相关开发者
   - 添加标签和里程碑

2. **Issue模板**
   ```markdown
   ## Bug描述
   简要描述遇到的问题
   
   ## 重现步骤
   1. 打开网站
   2. 点击登录按钮
   3. 输入用户名密码
   
   ## 期望结果
   应该正常登录
   
   ## 实际结果
   显示错误信息
   
   ## 环境信息
   - 浏览器: Chrome 90
   - 操作系统: Windows 10
   ```

### 里程碑规划

1. 创建里程碑: "v1.0 基础功能"
2. 设置截止日期
3. 关联相关Issue和Pull Request
4. 跟踪完成进度

---

## 🔍 代码搜索与浏览

### 高级搜索

在仓库页面使用搜索功能:
```
# 搜索文件名
filename:server.js

# 搜索代码内容
function getUserInfo

# 搜索特定文件类型
extension:vue

# 搜索提交信息
message:"修复登录"
```

### 代码浏览技巧

1. **快捷键**
   - `t`: 文件搜索
   - `b`: 切换分支
   - `y`: 获取永久链接

2. **代码高亮**
   - 支持100+编程语言
   - 语法高亮和代码折叠

---

## 📈 数据统计

### 提交统计

在仓库页面查看:
- 提交频率图表
- 代码贡献者统计
- 代码行数变化

### 下载统计

- Release下载次数
- 克隆数量统计
- 访问流量分析

---

## 🎁 Gitee特色功能

### 1. 代码片段 (Gist)

分享代码片段:
1. 访问 [https://gitee.com/gists](https://gitee.com/gists)
2. 创建新的代码片段
3. 支持语法高亮和版本控制

### 2. 图床功能

上传图片获取外链:
1. 仓库页面上传图片
2. 右键复制图片链接
3. 在Markdown中使用

### 3. 项目模板

使用官方模板快速创建项目:
- Vue.js项目模板
- React项目模板
- Node.js项目模板

---

## 📞 技术支持

### Gitee帮助中心
- 官方文档: [https://gitee.com/help](https://gitee.com/help)
- 视频教程: Gitee官方B站频道
- 社区论坛: [https://gitee.com/groups](https://gitee.com/groups)

### 常见问题

1. **推送失败**
   - 检查网络连接
   - 确认用户权限
   - 更新Git客户端

2. **大文件处理**
   - 使用Git LFS
   - 文件大小限制100MB

3. **私有仓库限制**
   - 免费用户5个私有仓库
   - 付费用户无限制

---

## 🎉 总结

Gitee为国内开发者提供了：
- ⚡ **极速访问** - 国内服务器，无需翻墙
- 🔒 **安全可靠** - 企业级安全保障
- 🛠️ **功能丰富** - 完整的DevOps工具链
- 💰 **性价比高** - 个人用户免费

选择Gitee，让您的小说网站开发更加高效！ 🚀