#!/bin/bash

# 🇨🇳 小说网站国内环境自动化部署脚本
# 针对国内网络环境优化，使用国内镜像源

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${BLUE}[信息]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[成功]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

log_error() {
    echo -e "${RED}[错误]${NC} $1"
}

# 检查是否为root用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "请使用root权限运行此脚本: sudo ./deploy-china.sh"
        exit 1
    fi
}

# 获取用户输入
get_user_input() {
    echo "=================================="
    echo "🇨🇳 小说网站国内部署向导"
    echo "=================================="
    
    read -p "请输入您的域名 (例如: example.com): " DOMAIN_NAME
    read -p "请输入您的邮箱 (用于SSL证书): " EMAIL
    read -p "请输入MongoDB管理员密码: " MONGO_ADMIN_PASS
    read -p "请输入MongoDB应用密码: " MONGO_APP_PASS
    read -p "请输入JWT密钥 (建议32位以上): " JWT_SECRET
    read -p "请输入Gitee仓库地址 (可选): " GIT_REPO
    
    if [ -z "$DOMAIN_NAME" ] || [ -z "$EMAIL" ] || [ -z "$MONGO_ADMIN_PASS" ] || [ -z "$MONGO_APP_PASS" ] || [ -z "$JWT_SECRET" ]; then
        log_error "必填信息不能为空!"
        exit 1
    fi
    
    log_info "配置信息确认:"
    echo "域名: $DOMAIN_NAME"
    echo "邮箱: $EMAIL"
    echo "Gitee仓库: ${GIT_REPO:-'将使用当前目录'}"
    
    read -p "确认开始部署? (y/N): " CONFIRM
    if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
        log_warn "部署已取消"
        exit 0
    fi
}

# 配置国内镜像源
configure_china_mirrors() {
    log_info "配置国内镜像源..."
    
    # 配置apt国内镜像源 (阿里云)
    if [ -f /etc/apt/sources.list ]; then
        cp /etc/apt/sources.list /etc/apt/sources.list.backup
        cat > /etc/apt/sources.list << 'EOF'
deb http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
EOF
    fi
    
    log_success "国内镜像源配置完成"
}

# 更新系统
update_system() {
    log_info "更新系统软件包..."
    apt update && apt upgrade -y
    
    # 安装基础工具
    apt install -y curl wget git vim htop
    
    log_success "系统更新完成"
}

# 安装Node.js (使用国内镜像)
install_nodejs() {
    log_info "安装Node.js 18.x (使用国内镜像)..."
    
    # 使用阿里云镜像安装Node.js
    curl -fsSL https://mirrors.aliyun.com/nodesource/setup_18.x | bash -
    apt-get install -y nodejs
    
    # 验证安装
    NODE_VERSION=$(node --version)
    NPM_VERSION=$(npm --version)
    log_success "Node.js $NODE_VERSION 和 npm $NPM_VERSION 安装完成"
    
    # 配置npm国内镜像源
    log_info "配置npm淘宝镜像源..."
    npm config set registry https://registry.npmmirror.com
    npm config set disturl https://npmmirror.com/dist
    npm config set electron_mirror https://npmmirror.com/mirrors/electron/
    npm config set sass_binary_site https://npmmirror.com/mirrors/node-sass/
    npm config set phantomjs_cdnurl https://npmmirror.com/mirrors/phantomjs/
    
    # 安装cnpm (备用)
    npm install -g cnpm --registry=https://registry.npmmirror.com
    
    # 安装PM2
    npm install -g pm2
    log_success "PM2 进程管理器安装完成"
}

# 安装MongoDB (使用国内镜像)
install_mongodb() {
    log_info "安装MongoDB (使用国内镜像)..."
    
    # 使用阿里云镜像
    wget -qO - https://mirrors.aliyun.com/mongodb/apt/ubuntu/dists/focal/mongodb-org/6.0/Release.gpg | apt-key add -
    echo "deb [ arch=amd64,arm64 ] https://mirrors.aliyun.com/mongodb/apt/ubuntu focal/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list
    
    # 如果阿里云源失败，使用清华源作为备用
    if ! apt-get update; then
        log_warn "阿里云源失败，尝试使用清华源..."
        echo "deb [ arch=amd64,arm64 ] https://mirrors.tuna.tsinghua.edu.cn/mongodb/apt/ubuntu focal/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list
        apt-get update
    fi
    
    apt-get install -y mongodb-org
    
    # 启动服务
    systemctl start mongod
    systemctl enable mongod
    
    log_success "MongoDB 安装并启动完成"
}

# 配置MongoDB安全性
configure_mongodb() {
    log_info "配置MongoDB安全认证..."
    
    # 等待MongoDB启动
    sleep 5
    
    # 检查MongoDB是否正常启动
    if ! systemctl is-active --quiet mongod; then
        log_error "MongoDB启动失败，请检查日志"
        systemctl status mongod
        exit 1
    fi
    
    # 创建管理员用户
    mongosh --eval "
    use admin;
    try {
        db.createUser({
            user: 'admin',
            pwd: '$MONGO_ADMIN_PASS',
            roles: [{ role: 'userAdminAnyDatabase', db: 'admin' }]
        });
        print('管理员用户创建成功');
    } catch(e) {
        print('管理员用户可能已存在');
    }
    
    use novel-website;
    try {
        db.createUser({
            user: 'novel-user',
            pwd: '$MONGO_APP_PASS',
            roles: [{ role: 'readWrite', db: 'novel-website' }]
        });
        print('应用用户创建成功');
    } catch(e) {
        print('应用用户可能已存在');
    }
    "
    
    # 启用认证
    if ! grep -q "authorization: enabled" /etc/mongod.conf; then
        echo "security:" >> /etc/mongod.conf
        echo "  authorization: enabled" >> /etc/mongod.conf
    fi
    
    # 重启MongoDB
    systemctl restart mongod
    
    log_success "MongoDB 安全配置完成"
}

# 部署应用代码
deploy_application() {
    log_info "部署应用代码..."
    
    # 创建应用目录
    mkdir -p /home/novel-website
    cd /home/novel-website
    
    if [ -n "$GIT_REPO" ]; then
        # 从Gitee仓库克隆
        log_info "从Gitee克隆代码..."
        if git clone "$GIT_REPO" .; then
            log_success "代码克隆成功"
        else
            log_error "代码克隆失败，请检查仓库地址"
            exit 1
        fi
    else
        log_warn "未提供Git仓库，请手动上传项目文件到 /home/novel-website/"
        log_warn "您可以使用: scp -r /local/project/* root@server-ip:/home/novel-website/"
        read -p "请确认代码已上传完成，按回车键继续..."
    fi
    
    # 检查package.json是否存在
    if [ ! -f "package.json" ]; then
        log_error "未找到package.json文件，请确认代码已正确上传"
        exit 1
    fi
    
    # 安装依赖 (使用cnpm加速)
    log_info "安装项目依赖..."
    if command -v cnpm >/dev/null 2>&1; then
        cnpm install --production
    else
        npm install --production
    fi
    
    log_success "应用代码部署完成"
}

# 配置环境变量
configure_environment() {
    log_info "配置环境变量..."
    
    cat > /home/novel-website/.env << EOF
# 基础配置
NODE_ENV=production
PORT=5000

# 数据库配置
MONGO_URI=mongodb://novel-user:$MONGO_APP_PASS@localhost:27017/novel-website

# JWT密钥
JWT_SECRET=$JWT_SECRET

# CORS配置
CORS_ORIGIN=https://$DOMAIN_NAME

# 日志配置
LOG_LEVEL=info
LOG_FILE=./logs/app.log
EOF
    
    log_success "环境变量配置完成"
}

# 创建PM2配置
configure_pm2() {
    log_info "配置PM2进程管理..."
    
    cat > /home/novel-website/ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'novel-website',
    script: 'server.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'development'
    },
    env_production: {
      NODE_ENV: 'production',
      PORT: 5000
    },
    log_file: './logs/app.log',
    error_file: './logs/error.log',
    out_file: './logs/out.log',
    max_memory_restart: '500M',
    watch: false,
    ignore_watch: ['node_modules', 'logs'],
    // 国内环境优化
    min_uptime: '10s',
    max_restarts: 10,
    autorestart: true,
    cron_restart: '0 2 * * *', // 每天凌晨2点重启
    merge_logs: true,
    time: true
  }]
}
EOF
    
    # 创建日志目录
    mkdir -p /home/novel-website/logs
    
    log_success "PM2配置完成"
}

# 安装Nginx
install_nginx() {
    log_info "安装Nginx..."
    
    apt install nginx -y
    systemctl start nginx
    systemctl enable nginx
    
    # 删除默认站点
    rm -f /etc/nginx/sites-enabled/default
    
    log_success "Nginx 安装完成"
}

# 配置Nginx (针对国内优化)
configure_nginx() {
    log_info "配置Nginx反向代理 (国内优化)..."
    
    cat > /etc/nginx/sites-available/novel-website << EOF
# 国内优化的Nginx配置
server {
    listen 80;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;
    
    # 国内用户体验优化
    client_max_body_size 10M;
    client_body_timeout 60s;
    client_header_timeout 60s;
    
    # 启用Gzip压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1k;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;
    
    # 静态文件缓存 (适合国内CDN)
    location /assets/ {
        root /home/novel-website/dist;
        expires 30d;
        add_header Cache-Control "public, no-transform";
        add_header Vary "Accept-Encoding";
    }
    
    # API代理
    location /api/ {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # 超时设置 (适合国内网络)
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # Socket.io支持
    location /socket.io/ {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket超时
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }
    
    # 前端应用
    location / {
        root /home/novel-website/dist;
        try_files \$uri \$uri/ /index.html;
        
        # 安全头部
        add_header X-Frame-Options "SAMEORIGIN";
        add_header X-Content-Type-Options "nosniff";
        add_header X-XSS-Protection "1; mode=block";
        
        # 移动端优化
        add_header Vary "User-Agent";
    }
    
    # 防止访问敏感文件
    location ~ /\. {
        deny all;
    }
    
    location ~ \.(env|log)$ {
        deny all;
    }
}
EOF
    
    # 启用站点
    ln -sf /etc/nginx/sites-available/novel-website /etc/nginx/sites-enabled/
    
    # 测试配置
    if nginx -t; then
        log_success "Nginx配置验证通过"
    else
        log_error "Nginx配置有误"
        exit 1
    fi
    
    # 重启Nginx
    systemctl restart nginx
    
    log_success "Nginx配置完成"
}

# 配置SSL证书
configure_ssl() {
    log_info "配置SSL证书..."
    
    # 安装Certbot
    apt install certbot python3-certbot-nginx -y
    
    # 获取证书 (国内可能需要特殊配置)
    log_info "申请SSL证书 (可能需要几分钟)..."
    if certbot --nginx -d "$DOMAIN_NAME" -d "www.$DOMAIN_NAME" --email "$EMAIL" --agree-tos --non-interactive --redirect; then
        log_success "SSL证书申请成功"
    else
        log_warn "SSL证书申请失败，将使用HTTP访问"
        log_warn "您可以稍后手动申请: certbot --nginx -d $DOMAIN_NAME"
    fi
    
    # 设置自动续期
    systemctl enable certbot.timer
    
    log_success "SSL证书配置完成"
}

# 配置防火墙 (适合国内服务器)
configure_firewall() {
    log_info "配置防火墙..."
    
    # 检查是否有云服务商的安全组
    if command -v ufw >/dev/null 2>&1; then
        ufw --force enable
        ufw allow ssh
        ufw allow 'Nginx Full'
        
        # 允许常用端口
        ufw allow 22/tcp comment 'SSH'
        ufw allow 80/tcp comment 'HTTP'
        ufw allow 443/tcp comment 'HTTPS'
        
        log_success "UFW防火墙配置完成"
    else
        log_warn "未找到UFW，请手动配置防火墙规则"
    fi
    
    # 针对国内服务器的安全建议
    log_info "应用安全加固..."
    
    # 修改SSH端口 (可选)
    read -p "是否修改SSH端口以提高安全性? (y/N): " CHANGE_SSH
    if [ "$CHANGE_SSH" = "y" ] || [ "$CHANGE_SSH" = "Y" ]; then
        read -p "请输入新的SSH端口 (建议2000-65535): " NEW_SSH_PORT
        if [ -n "$NEW_SSH_PORT" ] && [ "$NEW_SSH_PORT" -gt 1000 ] && [ "$NEW_SSH_PORT" -lt 65536 ]; then
            sed -i "s/#Port 22/Port $NEW_SSH_PORT/" /etc/ssh/sshd_config
            systemctl restart sshd
            ufw allow "$NEW_SSH_PORT/tcp" comment 'New SSH'
            log_success "SSH端口已修改为 $NEW_SSH_PORT"
            log_warn "请记住新端口，下次连接使用: ssh -p $NEW_SSH_PORT root@$DOMAIN_NAME"
        fi
    fi
}

# 启动应用
start_application() {
    log_info "启动应用..."
    
    cd /home/novel-website
    
    # 检查server.js是否存在
    if [ ! -f "server.js" ]; then
        log_error "未找到server.js文件，请检查代码是否正确上传"
        exit 1
    fi
    
    # 启动PM2应用
    pm2 start ecosystem.config.js --env production
    pm2 save
    
    # 设置开机自启
    if pm2 startup | grep -q "sudo"; then
        # 执行PM2推荐的启动命令
        eval $(pm2 startup | tail -1)
    fi
    
    log_success "应用启动完成"
}

# 验证部署
verify_deployment() {
    log_info "验证部署状态..."
    
    sleep 3
    
    # 检查PM2状态
    if pm2 list | grep -q "novel-website.*online"; then
        log_success "✅ PM2应用运行正常"
    else
        log_error "❌ PM2应用未正常运行"
        pm2 logs novel-website --lines 10
    fi
    
    # 检查MongoDB状态
    if systemctl is-active --quiet mongod; then
        log_success "✅ MongoDB服务运行正常"
    else
        log_error "❌ MongoDB服务未运行"
    fi
    
    # 检查Nginx状态
    if systemctl is-active --quiet nginx; then
        log_success "✅ Nginx服务运行正常"
    else
        log_error "❌ Nginx服务未运行"
    fi
    
    # 检查端口
    if netstat -tlnp | grep :80 > /dev/null; then
        log_success "✅ HTTP端口(80)正常监听"
    else
        log_warn "⚠️  HTTP端口(80)未监听"
    fi
    
    if netstat -tlnp | grep :443 > /dev/null; then
        log_success "✅ HTTPS端口(443)正常监听"
    else
        log_warn "⚠️  HTTPS端口(443)未监听"
    fi
    
    # 检查应用响应
    log_info "测试应用响应..."
    if curl -s http://localhost:5000 > /dev/null; then
        log_success "✅ 应用响应正常"
    else
        log_error "❌ 应用无响应"
    fi
}

# 显示部署结果
show_deployment_result() {
    echo ""
    echo "=================================="
    echo "🎉 国内部署完成!"
    echo "=================================="
    echo ""
    echo "📊 部署信息:"
    echo "  网站地址: https://$DOMAIN_NAME"
    echo "  API地址:  https://$DOMAIN_NAME/api"
    echo "  服务器IP: $(curl -s ip.sb 2>/dev/null || curl -s ifconfig.me)"
    echo ""
    echo "🔧 管理命令:"
    echo "  查看应用状态: pm2 status"
    echo "  查看应用日志: pm2 logs novel-website"
    echo "  重启应用:    pm2 restart novel-website"
    echo "  查看Nginx状态: systemctl status nginx"
    echo ""
    echo "📁 重要路径:"
    echo "  应用目录: /home/novel-website"
    echo "  日志目录: /home/novel-website/logs"
    echo "  Nginx配置: /etc/nginx/sites-available/novel-website"
    echo ""
    echo "🔐 数据库信息:"
    echo "  MongoDB管理员: admin"
    echo "  应用数据库用户: novel-user"
    echo "  数据库名: novel-website"
    echo ""
    echo "🇨🇳 国内优化:"
    echo "  - 使用了阿里云/淘宝镜像源"
    echo "  - 配置了Gzip压缩"
    echo "  - 优化了超时设置"
    echo "  - 添加了安全头部"
    echo ""
    
    # 显示下一步建议
    echo "🚀 接下来您可以:"
    echo "  1. 访问 https://$DOMAIN_NAME 查看网站"
    echo "  2. 上传管理脚本进行日常维护"
    echo "  3. 配置CDN加速提升访问速度"
    echo "  4. 添加百度统计等分析工具"
    echo "  5. 提交网站给搜索引擎收录"
    echo ""
    log_success "部署完成! 您的小说网站已经可以访问了！"
}

# 主函数
main() {
    echo "🇨🇳 开始国内环境自动化部署..."
    
    check_root
    get_user_input
    
    configure_china_mirrors
    update_system
    install_nodejs
    install_mongodb
    configure_mongodb
    deploy_application
    configure_environment
    configure_pm2
    install_nginx
    configure_nginx
    configure_ssl
    configure_firewall
    start_application
    
    verify_deployment
    show_deployment_result
}

# 错误处理
trap 'log_error "部署过程中发生错误，请检查上述输出"; exit 1' ERR

# 执行主函数
main "$@"