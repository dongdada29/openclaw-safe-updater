# OpenClaw Safe Updater

🔄 OpenClaw 自动升级工具，带自动回滚和模型配置保护

## 功能

- ✅ 自动检查并升级 OpenClaw
- ✅ 升级失败自动回滚
- ✅ 自动备份和恢复模型配置
- ✅ 定时任务（每周自动执行）
- ✅ 完整日志记录

## 安装

```bash
# 克隆项目
git clone https://github.com/dongdada29/openclaw-safe-updater.git
cd openclaw-safe-updater

# 设置执行权限
chmod +x openclaw-updater.sh

# 启用定时任务（每周日 9点自动执行）
launchctl load com.dongdada.openclaw-updater.plist
```

## 使用

### 手动运行

```bash
./openclaw-updater.sh
```

### 查看日志

```bash
cat ~/workspace/logs/openclaw-updater.log
```

### 停止定时任务

```bash
launchctl unload com.dongdada.openclaw-updater.plist
```

## 工作流程

```
1. 记录当前版本 + 备份配置
       ↓
2. 尝试升级 (npm update)
       ↓
3. 测试 Gateway 状态
       ↓
4. 检查模型配置
       ↓
5. 失败? → 自动回滚 + 恢复配置
```

## 文件

| 文件 | 说明 |
|------|------|
| `openclaw-updater.sh` | 主脚本 |
| `com.dongdada.openclaw-updater.plist` | macOS LaunchAgent |

## 配置

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

## License

MIT
