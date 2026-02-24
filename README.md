# OpenClaw Safe Updater 🔄

🔒 OpenClaw 自动升级工具，带自动回滚和模型配置保护

## ✨ 功能

- ✅ 自动检查并升级 OpenClaw
- ✅ 升级失败自动回滚到之前版本
- ✅ 自动备份和恢复模型配置
- ✅ 检测模型是否支持多模态（图片）
- ✅ 定时任务（每周自动执行）
- ✅ 完整日志记录
- ✅ 使用相对路径，兼容不同用户

## 🚀 快速开始

```bash
# 克隆项目
git clone https://github.com/dongdada29/openclaw-safe-updater.git
cd openclaw-safe-updater

# 设置执行权限
changelog +x openclaw-updater.sh

# 手动运行测试
./openclaw-updater.sh

# 启用定时任务（每周日 9点自动执行）
launchctl load com.dongdada.openclaw-updater.plist
```

## 📖 工作流程

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

## 📁 文件

| 文件 | 说明 |
|------|------|
| `openclaw-updater.sh` | 主脚本（通用路径） |
| `com.dongdada.openclaw-updater.plist` | macOS LaunchAgent |

## 📊 日志

- 主日志: `~/workspace/logs/openclaw-updater.log`
- 版本记录: `~/workspace/logs/openclaw-version.txt`
- 配置备份: `~/workspace/logs/openclaw-config-backup.tar.gz`
- 模型配置: `~/workspace/logs/model-config-backup.json`

## 🔧 配置

### 修改运行时间

编辑 `com.dongdada.openclaw-updater.plist`:

```xml
<key>StartCalendarInterval</key>
<array>
    <dict>
        <key>Weekday</key>
        <integer>0</integer>  <!-- 0=周日, 1=周一, etc. -->
        <key>Hour</key>
        <integer>9</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
</array>
```

### 支持的模型检测

脚本会自动检测以下模型是否支持多模态（图片）:

- Claude (Opus, Sonnet, Haiku)
- GPT-4 (Vision)
- MiniMax
- Kimi
- 其他支持视觉的模型

## ⚠️ 常见问题

### Gateway 未授权
```bash
openclaw gateway restart
```

### 手动回滚
```bash
# 查看之前版本
cat ~/workspace/logs/openclaw-version.txt

# 手动安装特定版本
npm install -g openclaw@2026.2.19-2
```

## 📝 License

MIT
