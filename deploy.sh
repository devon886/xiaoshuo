#!/bin/bash

# 🚀 小说网站自动化部署脚本
# 适用于Ubuntu 20.04+ 系统

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否为root用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "请使用root权限运行此脚本: sudo ./deploy.sh"
        exit 1
    fi
}

# 获取用户输入
get_user_input() {
    echo "=================================="
    echo "🚀 小说网站部署向导"
    echo "=================================="
    
    read -p "请输入您的域名 (例如: example.com): " DOMAIN_NAME
    read -p "请输入您的邮箱 (用于SSL证书): " EMAIL
    read -p "请输入MongoDB管理员密码: " MONGO_ADMIN_PASS
    read -p "请输入MongoDB应用密码: " MONGO_APP_PASS
    read -p "请输入JWT密钥 (建议32位以上): " JWT_SECRET
    read -p "请输入项目Git仓库地址 (可选): " GIT_REPO
    
    if [ -z "$DOMAIN_NAME" ] || [ -z "$EMAIL" ] || [ -z "$MONGO_ADMIN_PASS" ] || [ -z "$MONGO_APP_PASS" ] || [ -z "$JWT_SECRET" ]; then
        log_error "必填信息不能为空!"
        exit 1
    fi
    
    log_info "配置信息确认:"
    echo "域名: $DOMAIN_NAME"
    echo "邮箱: $EMAIL"
    echo "Git仓库: ${GIT_REPO:-'将使用当前目录'}"
    
    read -p "确认开始部署? (y/N): " CONFIRM
    if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
        log_warn "部署已取消"
        exit 0
    fi
}

# 更新系统
update_system() {
    log_info "更新系统软件包..."
    apt update && apt upgrade -y
    log_success "系统更新完成"
}

# 安装Node.js
install_nodejs() {
    log_info "安装Node.js 18.x..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
    
    # 验证安装
    NODE_VERSION=$(node --version)
    NPM_VERSION=$(npm --version)
    log_success "Node.js $NODE_VERSION 和 npm $NPM_VERSION 安装完成"
    
    # 安装PM2
    npm install -g pm2
    log_success "PM2 进程管理器安装完成"
}

# 安装MongoDB
install_mongodb() {
    log_info "安装MongoDB..."
    
    # 导入公钥
    wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | apt-key add -
    
    # 添加MongoDB源
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list
    
    # 安装
    apt-get update
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
    sleep 3
    
    # 创建管理员用户
    mongosh --eval "
    use admin;
    db.createUser({
        user: 'admin',
        pwd: '$MONGO_ADMIN_PASS',
        roles: [{ role: 'userAdminAnyDatabase', db: 'admin' }]
    });
    
    use novel-website;
    db.createUser({
        user: 'novel-user',
        pwd: '$MONGO_APP_PASS',
        roles: [{ role: 'readWrite', db: 'novel-website' }]
    });
    "
    
    # 启用认证
    sed -i 's/#security:/security:\n  authorization: enabled/' /etc/mongod.conf
    
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
        # 从Git仓库克隆
        git clone "$GIT_REPO" .
    else
        # 如果没有提供Git仓库，假设当前目录就是项目目录
        log_warn "未提供Git仓库，请手动上传项目文件到 /home/novel-website/"
        log_warn "您可以使用: scp -r /local/project/* root@server-ip:/home/novel-website/"
        return
    fi
    
    # 安装依赖
    npm install --production
    
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
    ignore_watch: ['node_modules', 'logs']
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
    
    log_success "Nginx 安装完成"
}

# 配置Nginx
configure_nginx() {
    log_info "配置Nginx反向代理..."
    
    cat > /etc/nginx/sites-available/novel-website << EOF
server {
    listen 80;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;
    
    # 静态文件缓存
    location /assets/ {
        root /home/novel-website/dist;
        expires 1y;
        add_header Cache-Control "public, immutable";
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
    }
    
    # 前端应用
    location / {
        root /home/novel-website/dist;
        try_files \$uri \$uri/ /index.html;
        add_header X-Frame-Options "SAMEORIGIN";
        add_header X-Content-Type-Options "nosniff";
    }
}
EOF
    
    # 启用站点
    ln -sf /etc/nginx/sites-available/novel-website /etc/nginx/sites-enabled/
    
    # 测试配置
    nginx -t
    
    # 重启Nginx
    systemctl restart nginx
    
    log_success "Nginx配置完成"
}

# 配置SSL证书
configure_ssl() {
    log_info "配置SSL证书..."
    
    # 安装Certbot
    apt install certbot python3-certbot-nginx -y
    
    # 获取证书
    certbot --nginx -d "$DOMAIN_NAME" -d "www.$DOMAIN_NAME" --email "$EMAIL" --agree-tos --non-interactive
    
    # 设置自动续期
    systemctl enable certbot.timer
    
    log_success "SSL证书配置完成"
}

# 配置防火墙
configure_firewall() {
    log_info "配置防火墙..."
    
    ufw --force enable
    ufw allow ssh
    ufw allow 'Nginx Full'
    
    log_success "防火墙配置完成"
}

# 启动应用
start_application() {
    log_info "启动应用..."
    
    cd /home/novel-website
    
    # 启动PM2应用
    pm2 start ecosystem.config.js --env production
    pm2 save
    pm2 startup
    
    log_success "应用启动完成"
}

# 验证部署
verify_deployment() {
    log_info "验证部署状态..."
    
    # 检查PM2状态
    PM2_STATUS=$(pm2 list | grep novel-website | grep online || echo "")
    if [ -n "$PM2_STATUS" ]; then
        log_success "✅ PM2应用运行正常"
    else
        log_error "❌ PM2应用未正常运行"
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
}

# 显示部署结果
show_deployment_result() {
    echo ""
    echo "=================================="
    echo "🎉 部署完成!"
    echo "=================================="
    echo ""
    echo "📊 部署信息:"
    echo "  网站地址: https://$DOMAIN_NAME"
    echo "  API地址:  https://$DOMAIN_NAME/api"
    echo "  服务器IP: $(curl -s ifconfig.me)"
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
    log_success "部署完成! 请访问 https://$DOMAIN_NAME 查看您的网站"
}

# 主函数
main() {
    echo "🚀 开始自动化部署..."
    
    check_root
    get_user_input
    
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