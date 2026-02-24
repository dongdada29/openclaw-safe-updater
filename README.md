# OpenClaw Safe Updater 🔄

🔒 OpenClaw 自动升级工具，带自动回滚、故障检测和模型配置保护

## ✨ 功能

### 核心功能
- ✅ 自动检查并升级 OpenClaw
- ✅ 升级失败自动回滚到之前版本
- ✅ 自动备份和恢复模型配置
- ✅ 检测模型是否支持多模态（图片）
- ✅ 完整日志记录
- ✅ 使用相对路径，兼容不同用户

### 健康监控
- ✅ Gateway 状态检测
- ✅ 磁盘空间检测
- ✅ 内存使用检测
- ✅ 配置完整性检测
- ✅ Session 文件自动清理
- ✅ 日志文件自动清理

## 🚀 快速开始

```bash
# 克隆项目
git clone https://github.com/dongdada29/openclaw-safe-updater.git
cd openclaw-safe-updater

# 设置执行权限
chmod +x *.sh

# 手动运行健康检查
./health-monitor.sh

# 手动运行升级
./openclaw-updater.sh

# 启用定时任务（每周日 9点自动执行）
launchctl load com.dongdada.openclaw-updater.plist
```

## 📖 工作流程

### 升级流程
```
1. 记录当前版本 + 备份配置
       ↓
2. 尝试升级 (npm update)
       ↓
3. 测试 Gateway 状态
       ↓
4. 检查模型配置（是否支持多模态）
       ↓
5. 失败? → 自动回滚 + 恢复配置
```

### 健康检查流程
```
1. Gateway 状态检测
       ↓
2. 磁盘空间检测 (>80% 警告)
       ↓
3. 内存使用检测
       ↓
4. 配置完整性检测
       ↓
5. 清理旧 Session 和日志
```

## 📁 文件

| 文件 | 说明 |
|------|------|
| `openclaw-updater.sh` | 自动升级脚本 |
| `health-monitor.sh` | 健康监控脚本 |
| `com.dongdada.openclaw-updater.plist` | macOS LaunchAgent |
| `FAILURE_MODES.md` | 故障模式分析文档 |

## 📊 日志

- 健康检查: `~/workspace/logs/openclaw-health.log`
- 升级日志: `~/workspace/logs/openclaw-updater.log`
- 版本记录: `~/workspace/logs/openclaw-version.txt`

## 🔧 配置

### 修改运行时间

编辑 `com.dongdada.openclaw-updater.plist`:

```xml
<key>StartCalendarInterval</key>
<array>
    <dict>
        <key>Weekday</key>
        <integer>0</integer>  <!-- 0=周日 -->
        <key>Hour</key>
        <integer>9</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
</array>
```

## 📋 故障模式分析

详见 [FAILURE_MODES.md](./FAILURE_MODES.md)

### 主要故障类型

| 类型 | 严重性 | 检测 |
|------|--------|------|
| Gateway 崩溃循环 | 🔴 致命 | ✅ health-monitor |
| 无限循环 | 🟠 严重 | ⚠️ 需手动 |
| 内存泄漏 | 🟠 严重 | ✅ health-monitor |
| 磁盘空间耗尽 | 🟠 严重 | ✅ health-monitor |
| 配置损坏 | 🟡 中等 | ✅ health-monitor |

## 📝 License

MIT
