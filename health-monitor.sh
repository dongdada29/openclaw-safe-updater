#!/bin/bash
# OpenClaw Health Monitor - 故障检测脚本
# 基于 GitHub Issues 分析的自动检测

LOG_DIR="${HOME}/workspace/logs"
HEALTH_LOG="${LOG_DIR}/openclaw-health.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$HEALTH_LOG"
}

log "=== OpenClaw Health Monitor Started ==="

# 1. Gateway 状态检测
check_gateway() {
    log "检查 Gateway 状态..."
    
    if openclaw gateway status 2>&1 | grep -q "running"; then
        log "✅ Gateway 正常运行"
        return 0
    else
        log "❌ Gateway 未运行，尝试重启..."
        openclaw gateway restart 2>&1 | tee -a "$HEALTH_LOG"
        return 1
    fi
}

# 2. 磁盘空间检测
check_disk() {
    log "检查磁盘空间..."
    
    # 获取根分区使用率
    DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
    
    if [ "$DISK_USAGE" -gt 90 ]; then
        log "🚨 磁盘使用率: ${DISK_USAGE}% - 过高!"
        return 1
    elif [ "$DISK_USAGE" -gt 80 ]; then
        log "⚠️ 磁盘使用率: ${DISK_USAGE}% - 偏高"
        return 2
    else
        log "✅ 磁盘空间充足: ${DISK_USAGE}%"
        return 0
    fi
}

# 3. Session 文件清理
clean_sessions() {
    log "检查 Session 文件..."
    
    SESSION_DIR="$HOME/.openclaw/agents/main/sessions"
    
    if [ -d "$SESSION_DIR" ]; then
        # 计算文件数量
        FILE_COUNT=$(find "$SESSION_DIR" -name "*.jsonl" 2>/dev/null | wc -l)
        log "当前 Session 文件数: $FILE_COUNT"
        
        # 如果超过 1000 个，清理旧的
        if [ "$FILE_COUNT" -gt 1000 ]; then
            log "🧹 清理旧 Session 文件..."
            find "$SESSION_DIR" -name "*.jsonl" -mtime +30 -delete 2>/dev/null
            log "已清理 30 天前的 Session 文件"
        fi
    fi
}

# 4. 日志文件大小检测
check_logs() {
    log "检查日志文件..."
    
    # 检查日志目录大小
    LOG_SIZE=$(du -sh "$LOG_DIR" 2>/dev/null | cut -f1)
    log "日志目录大小: $LOG_SIZE"
    
    # 如果超过 1GB，清理旧日志
    if [ -d "$LOG_DIR" ]; then
        LOG_SIZE_BYTES=$(du -sb "$LOG_DIR" 2>/dev/null | cut -f1)
        if [ "$LOG_SIZE_BYTES" -gt 1073741824 ]; then
            log "🧹 清理旧日志文件..."
            find "$LOG_DIR" -name "*.log" -mtime +7 -delete 2>/dev/null
            log "已清理 7 天前的日志文件"
        fi
    fi
}

# 5. 内存使用检测
check_memory() {
    log "检查内存使用..."
    
    # 获取 Gateway 进程内存 (如果存在)
    if pgrep -f "openclaw-gateway" > /dev/null; then
        MEMORY=$(ps -o rss= -p $(pgrep -f "openclaw-gateway") 2>/dev/null | awk '{print $1/1024}')
        log "Gateway 内存使用: ${MEMORY} MB"
        
        # 如果超过 2GB，标记警告
        if (( $(echo "$MEMORY > 2048" | bc -l 2>/dev/null || echo 0) )); then
            log "⚠️ Gateway 内存使用过高"
            return 2
        fi
    fi
    
    log "✅ 内存使用正常"
    return 0
}

# 6. 配置完整性检测
check_config() {
    log "检查配置完整性..."
    
    # 检查关键配置文件
    CONFIGS=(
        "$HOME/.openclaw/defaults.json"
        "$HOME/.openclaw/config.json"
    )
    
    for config in "${CONFIGS[@]}"; do
        if [ -f "$config" ]; then
            # 检查 JSON 格式是否有效
            if ! python3 -c "import json; json.load(open('$config'))" 2>/dev/null; then
                log "❌ 配置文件损坏: $config"
                return 1
            fi
        fi
    done
    
    log "✅ 配置完整性检查通过"
    return 0
}

# ===== 主流程 =====
ISSUES=0

# 执行所有检测
check_gateway || ((ISSUES++))
check_disk || ((ISSUES++))
check_memory || ((ISSUES++))
check_config || ((ISSUES++))
clean_sessions
check_logs

# 总结
log "=== Health Check Complete ==="
if [ "$ISSUES" -eq 0 ]; then
    log "✅ 所有检查通过"
else
    log "⚠️ 发现 $ISSUES 个问题"
fi

echo "---" >> "$HEALTH_LOG"
