#!/bin/bash
# OpenClaw Safe Updater with Auto-Rollback & Model Safety
# 尝试升级，测试，失败自动回滚，包含模型配置保护

# ===== 配置 =====
# 使用绝对路径，确保从任何位置运行都能正常工作
LOG_DIR="${LOG_DIR:-${HOME}/workspace/logs}"
LOG_FILE="${LOG_DIR}/openclaw-updater.log"
VERSION_FILE="${LOG_DIR}/openclaw-version.txt"
CONFIG_BACKUP="${LOG_DIR}/openclaw-config-backup.tar.gz"
MODEL_CONFIG_BACKUP="${LOG_DIR}/model-config-backup.json"

# ===== 函数 =====
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 检查模型是否支持多模态（图片）
check_vision_support() {
    local model="$1"
    
    # 支持图片的模型列表
    local vision_models=("claude-opus" "claude-sonnet" "claude-haiku" "gpt-4" "gpt-4o" "minimax" "kimi")
    
    for vm in "${vision_models[@]}"; do
        if [[ "$model" == *"$vm"* ]]; then
            return 0  # 支持
        fi
    done
    return 1  # 不支持
}

# 检查当前模型配置
check_model_config() {
    log "检查模型配置..."
    
    local config_file="$HOME/.openclaw/defaults.json"
    
    if [ ! -f "$config_file" ]; then
        log "⚠️ 未找到模型配置文件"
        return 1
    fi
    
    # 提取模型名称
    local current_model=$(cat "$config_file" 2>/dev/null | grep -o '"model"[^,}]*' | head -1)
    log "当前模型: $current_model"
    
    # 检查是否支持多模态
    if [ -n "$current_model" ]; then
        if check_vision_support "$current_model"; then
            log "✅ 模型支持多模态（图片）"
        else
            log "⚠️ 模型可能不支持多模态，如有图片需求建议切换到支持视觉的模型"
        fi
    fi
}

# 备份配置
backup_config() {
    log "备份配置..."
    mkdir -p "$LOG_DIR"
    
    # 备份整个配置目录
    tar -czf "$CONFIG_BACKUP" "$HOME/.openclaw" 2>/dev/null
    log "配置已备份到: $CONFIG_BACKUP"
    
    # 单独备份模型配置
    if [ -f "$HOME/.openclaw/defaults.json" ]; then
        cp "$HOME/.openclaw/defaults.json" "$MODEL_CONFIG_BACKUP"
        log "模型配置已备份"
    fi
}

# 恢复配置
restore_config() {
    log "恢复配置..."
    
    # 解压配置备份
    if [ -f "$CONFIG_BACKUP" ]; then
        tar -xzf "$CONFIG_BACKUP" -C "$HOME" 2>/dev/null
        log "配置已恢复"
    fi
    
    # 恢复模型配置
    if [ -f "$MODEL_CONFIG_BACKUP" ]; then
        cp "$MODEL_CONFIG_BACKUP" "$HOME/.openclaw/defaults.json"
        log "模型配置已恢复"
    fi
}

# 测试 Gateway
test_gateway() {
    if openclaw gateway status 2>&1 | grep -q "running"; then
        return 0
    fi
    return 1
}

# 升级流程
do_upgrade() {
    log "开始升级 OpenClaw..."
    npm update -g openclaw 2>&1 | tee -a "$LOG_FILE"
    sleep 3
}

# 回滚流程
do_rollback() {
    local old_version="$1"
    log "回滚到版本: $old_version"
    npm install -g "openclaw@$old_version" 2>&1 | tee -a "$LOG_FILE"
    sleep 3
}

# ===== 主流程 =====
log "=== OpenClaw Safe Updater Started ==="

# 1. 记录当前版本
CURRENT_VERSION=$(openclaw --version 2>/dev/null)
log "当前版本: $CURRENT_VERSION"
echo "$CURRENT_VERSION" > "$VERSION_FILE"

# 2. 备份配置
backup_config

# 3. 尝试升级
do_upgrade

# 4. 检查新版本
NEW_VERSION=$(openclaw --version 2>/dev/null)
log "新版本: $NEW_VERSION"

# 5. 判断是否需要处理
if [ "$CURRENT_VERSION" != "$NEW_VERSION" ]; then
    log "检测到新版本，测试 Gateway..."
    
    if test_gateway; then
        log "✅ 升级成功! Gateway 正常运行"
        check_model_config
    else
        log "⚠️ Gateway 启动失败，尝试重启..."
        openclaw gateway restart 2>&1 | tee -a "$LOG_FILE"
        sleep 5
        
        if test_gateway; then
            log "✅ Gateway 重启成功"
        else
            log "❌ Gateway 仍然失败，开始回滚..."
            
            do_rollback "$CURRENT_VERSION"
            restore_config
            
            ROLLBACK_VERSION=$(openclaw --version 2>/dev/null)
            log "已回滚到: $ROLLBACK_VERSION"
            
            openclaw gateway restart 2>&1 | tee -a "$LOG_FILE"
            
            if test_gateway; then
                log "✅ 回滚成功，系统正常运行"
            else
                log "🚨 回滚后仍有问题，需要手动检查"
            fi
        fi
    fi
else
    log "ℹ️ 已是最新版本，无需升级"
    check_model_config
fi

log "=== Updater Finished ==="
echo "---" >> "$LOG_FILE"
