#!/bin/bash

# 🛠️ 小说网站管理脚本
# 提供常用的运维操作

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置
APP_NAME="novel-website"
APP_DIR="/home/novel-website"
LOG_DIR="$APP_DIR/logs"

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 显示菜单
show_menu() {
    echo "=================================="
    echo "🛠️  小说网站管理工具"
    echo "=================================="
    echo "1. 📊 查看状态"
    echo "2. 🔄 重启应用"
    echo "3. 🛑 停止应用"
    echo "4. 🚀 启动应用"
    echo "5. 📋 查看日志"
    echo "6. 🔍 实时监控"
    echo "7. 🗂️  查看错误日志"
    echo "8. 💾 备份数据库"
    echo "9. 📦 更新应用"
    echo "10. 🧹 清理日志"
    echo "11. 🔧 系统信息"
    echo "12. 🔐 SSL证书状态"
    echo "0. 🚪 退出"
    echo "=================================="
}

# 检查状态
check_status() {
    log_info "检查系统状态..."
    echo ""
    
    # PM2状态
    echo "📱 PM2应用状态:"
    pm2 list
    echo ""
    
    # 系统服务状态
    echo "🏥 系统服务状态:"
    for service in mongod nginx; do
        if systemctl is-active --quiet $service; then
            echo -e "  ✅ $service: ${GREEN}运行中${NC}"
        else
            echo -e "  ❌ $service: ${RED}已停止${NC}"
        fi
    done
    echo ""
    
    # 端口检查
    echo "🌐 端口监听状态:"
    for port in 80 443 5000 27017; do
        if netstat -tlnp | grep :$port > /dev/null 2>&1; then
            echo -e "  ✅ 端口 $port: ${GREEN}正在监听${NC}"
        else
            echo -e "  ❌ 端口 $port: ${RED}未监听${NC}"
        fi
    done
    echo ""
    
    # 磁盘空间
    echo "💿 磁盘使用情况:"
    df -h | grep -E "(Filesystem|/dev/)" | head -2
    echo ""
    
    # 内存使用
    echo "🧠 内存使用情况:"
    free -h
}

# 重启应用
restart_app() {
    log_info "重启应用..."
    cd $APP_DIR
    pm2 restart $APP_NAME
    log_success "应用重启完成"
}

# 停止应用
stop_app() {
    log_info "停止应用..."
    pm2 stop $APP_NAME
    log_success "应用已停止"
}

# 启动应用
start_app() {
    log_info "启动应用..."
    cd $APP_DIR
    pm2 start ecosystem.config.js --env production
    log_success "应用启动完成"
}

# 查看日志
view_logs() {
    echo "选择日志类型:"
    echo "1. 应用日志 (最近100行)"
    echo "2. 错误日志 (最近100行)"
    echo "3. 实时日志"
    echo "4. Nginx访问日志"
    echo "5. Nginx错误日志"
    
    read -p "请选择 (1-5): " log_choice
    
    case $log_choice in
        1) tail -100 $LOG_DIR/app.log ;;
        2) tail -100 $LOG_DIR/error.log ;;
        3) pm2 logs $APP_NAME ;;
        4) tail -100 /var/log/nginx/access.log ;;
        5) tail -100 /var/log/nginx/error.log ;;
        *) log_error "无效选择" ;;
    esac
}

# 实时监控
real_time_monitor() {
    log_info "启动实时监控 (按 Ctrl+C 退出)..."
    pm2 monit
}

# 查看错误日志
view_error_logs() {
    log_info "最近的错误日志:"
    echo ""
    
    if [ -f "$LOG_DIR/error.log" ]; then
        echo "📋 应用错误日志 (最近20行):"
        tail -20 $LOG_DIR/error.log
        echo ""
    fi
    
    echo "📋 Nginx错误日志 (最近10行):"
    tail -10 /var/log/nginx/error.log
    echo ""
    
    echo "📋 系统日志中的错误 (最近10行):"
    journalctl -p err -n 10 --no-pager
}

# 备份数据库
backup_database() {
    log_info "开始备份数据库..."
    
    BACKUP_DIR="/home/backups"
    BACKUP_FILE="novel-website-backup-$(date +%Y%m%d-%H%M%S).gz"
    
    # 创建备份目录
    mkdir -p $BACKUP_DIR
    
    # 执行备份
    mongodump --db novel-website --gzip --archive=$BACKUP_DIR/$BACKUP_FILE
    
    if [ $? -eq 0 ]; then
        log_success "数据库备份完成: $BACKUP_DIR/$BACKUP_FILE"
        
        # 显示备份文件大小
        BACKUP_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)
        log_info "备份文件大小: $BACKUP_SIZE"
        
        # 保留最近10个备份
        cd $BACKUP_DIR
        ls -t novel-website-backup-*.gz | tail -n +11 | xargs rm -f
        log_info "已清理旧备份，保留最近10个"
    else
        log_error "数据库备份失败"
    fi
}

# 更新应用
update_app() {
    log_info "开始更新应用..."
    
    cd $APP_DIR
    
    # 备份当前版本
    backup_database
    
    # 更新代码
    if [ -d ".git" ]; then
        log_info "从Git仓库拉取最新代码..."
        git pull origin main
        
        # 安装新依赖
        npm install --production
        
        # 重启应用
        pm2 restart $APP_NAME
        
        log_success "应用更新完成"
    else
        log_warn "未检测到Git仓库，请手动更新代码"
    fi
}

# 清理日志
clean_logs() {
    log_info "清理日志文件..."
    
    # 清理应用日志 (保留最近7天)
    find $LOG_DIR -name "*.log" -type f -mtime +7 -delete
    
    # 清理Nginx日志 (保留最近14天)
    find /var/log/nginx -name "*.log" -type f -mtime +14 -delete
    
    # 清理系统日志
    journalctl --vacuum-time=30d
    
    # 清理PM2日志
    pm2 flush
    
    log_success "日志清理完成"
}

# 系统信息
system_info() {
    log_info "系统信息概览:"
    echo ""
    
    echo "🖥️  系统信息:"
    echo "  操作系统: $(lsb_release -d | cut -f2)"
    echo "  内核版本: $(uname -r)"
    echo "  运行时间: $(uptime -p)"
    echo ""
    
    echo "💾 存储信息:"
    df -h | grep -E "(Filesystem|/dev/)" | head -2
    echo ""
    
    echo "🧠 内存信息:"
    free -h
    echo ""
    
    echo "🔧 软件版本:"
    echo "  Node.js: $(node --version)"
    echo "  npm: $(npm --version)"
    echo "  MongoDB: $(mongod --version | head -1)"
    echo "  Nginx: $(nginx -v 2>&1)"
    echo "  PM2: $(pm2 --version)"
    echo ""
    
    echo "📊 负载信息:"
    echo "  CPU核心数: $(nproc)"
    echo "  当前负载: $(uptime | awk -F'load average:' '{print $2}')"
}

# SSL证书状态
ssl_status() {
    log_info "检查SSL证书状态..."
    
    # 检查证书文件
    CERT_PATH="/etc/letsencrypt/live"
    if [ -d "$CERT_PATH" ]; then
        for domain in $(ls $CERT_PATH); do
            echo "🔐 域名: $domain"
            
            # 获取证书过期时间
            EXPIRE_DATE=$(openssl x509 -in "$CERT_PATH/$domain/cert.pem" -noout -enddate | cut -d= -f2)
            echo "  过期时间: $EXPIRE_DATE"
            
            # 计算剩余天数
            EXPIRE_TIMESTAMP=$(date -d "$EXPIRE_DATE" +%s)
            CURRENT_TIMESTAMP=$(date +%s)
            DAYS_LEFT=$(( ($EXPIRE_TIMESTAMP - $CURRENT_TIMESTAMP) / 86400 ))
            
            if [ $DAYS_LEFT -gt 30 ]; then
                echo -e "  状态: ${GREEN}健康 (剩余 $DAYS_LEFT 天)${NC}"
            elif [ $DAYS_LEFT -gt 7 ]; then
                echo -e "  状态: ${YELLOW}注意 (剩余 $DAYS_LEFT 天)${NC}"
            else
                echo -e "  状态: ${RED}警告 (剩余 $DAYS_LEFT 天)${NC}"
            fi
            echo ""
        done
        
        # 检查自动续期服务
        if systemctl is-enabled --quiet certbot.timer; then
            echo -e "🔄 自动续期: ${GREEN}已启用${NC}"
        else
            echo -e "🔄 自动续期: ${RED}未启用${NC}"
        fi
    else
        log_warn "未找到SSL证书"
    fi
}

# 主循环
main() {
    while true; do
        show_menu
        read -p "请选择操作 (0-12): " choice
        echo ""
        
        case $choice in
            1) check_status ;;
            2) restart_app ;;
            3) stop_app ;;
            4) start_app ;;
            5) view_logs ;;
            6) real_time_monitor ;;
            7) view_error_logs ;;
            8) backup_database ;;
            9) update_app ;;
            10) clean_logs ;;
            11) system_info ;;
            12) ssl_status ;;
            0) 
                log_info "感谢使用小说网站管理工具!"
                exit 0
                ;;
            *)
                log_error "无效选择，请重新输入"
                ;;
        esac
        
        echo ""
        read -p "按回车键继续..."
        clear
    done
}

# 检查是否在正确的目录
if [ ! -f "/home/novel-website/server.js" ]; then
    log_warn "未检测到小说网站应用，某些功能可能无法正常使用"
    echo ""
fi

# 启动主程序
main