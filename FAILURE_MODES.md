# OpenClaw 故障预防与检测指南

> 基于 GitHub Issues 社区反馈的系统性故障分析

---

## 🔴 一、致命故障模式 (会导致整体崩溃)

### 1. Gateway 崩溃循环 (Crash Loop)

**典型场景:**
- DNS 解析失败 (EAI_AGAIN)
- 配置文件损坏 (double-write bug)
- 端口冲突

**相关 Issues:**
- #24581: Gateway crash-loop on transient DNS failures
- #24725: Gateway config corruption causing 14h+ crash loop
- #24894: Webhook route re-registration collision

**检测方法:**
```bash
# 检查 Gateway 状态
openclaw gateway status

# 查看崩溃日志
tail -100 ~/workspace/logs/openclaw-updater.error.log
```

**预防措施:**
- 配置文件版本控制
- DNS 备用服务器配置
- 崩溃自动回滚 (当前升级脚本已实现)

---

### 2. 无限循环/死循环

**典型场景:**
- 并行工具结果导致消息排序冲突
- API 400 错误触发压缩循环
- 消息块损坏导致循环

**相关 Issues:**
- #25442: MiniMax M2.5 message ordering conflict
- #25433: SiliconFlow 400 触发压缩循环
- #25411: orphaned tool_result block missing
- #24777: scope-upgrade rejection 无退避重连

**检测方法:**
```bash
# 检查消息队列
openclaw sessions list

# 查看 API 调用日志
openclaw doctor --deep
```

**预防措施:**
- 添加循环检测计数器
- 实施指数退避重试
- 消息完整性校验

---

### 3. 内存泄漏/资源耗尽

**典型场景:**
- Session transcript 文件积累
- 内存泄漏导致 OOM
- 磁盘空间耗尽

**相关 Issues:**
- #25373: orphan transcript .jsonl files accumulate
- #24393: WhatsApp PDF 附件导致 gateway crash

**检测方法:**
```bash
# 检查磁盘空间
df -h

# 检查 Gateway 内存
openclaw status

# 清理旧会话
rm -rf ~/.openclaw/agents/*/sessions/*.jsonl
```

---

## 🟠 二、功能性故障

### 1. 通道连接失败

| 通道 | 常见问题 |
|------|----------|
| Discord | Voice 解密失败 |
| Telegram | Media 下载失败 |
| WhatsApp | Schema 错误 |
| Signal | 签名验证失败 |
| Chrome Extension | Token 验证失败 |

**相关 Issues:**
- #25292: Chrome extension crashes
- #24913: Nextcloud Talk plugin fails
- #24508: Chrome extension auth broken
- #24880: Discord voice decryption failed

---

### 2. 消息路由问题

**典型场景:**
- Cron 公告劫持 DM 路由
- 消息丢失
- 回复路由错误

**相关 Issues:**
- #25450: Cron announce hijacks DM session routing
- #25447: message tool missing target routes

---

### 3. 执行工具问题

**典型场景:**
- exec 工具静默失败
- PATH 配置问题
- 命令不存在但无报错

**相关 Issues:**
- #24587: exec tool swallows "command not found"
- #25399: Windows PATH 问题

---

## 🟡 三、配置相关问题

### 1. 升级导致配置丢失

**典型场景:**
- Windows gateway.cmd 被覆盖
- Docker 配置丢失
- 插件配置失效

**相关 Issues:**
- #25443: gateway install overwrites customizations
- #25430: Doctor warning too mild for sandbox mode

---

### 2. 模型配置问题

**典型场景:**
- 模型不支持多模态
- API 密钥过期
- 配额耗尽

**相关 Issues:**
- #25371: OpenRouter 401 被误分类为 Context overflow

---

## 🛡️ 四、预防措施清单

### 自动化检测

| 检测项 | 命令 | 频率 |
|--------|------|------|
| Gateway 状态 | `openclaw gateway status` | 每小时 |
| 磁盘空间 | `df -h` | 每天 |
| 内存使用 | `openclaw status` | 每小时 |
| 错误日志 | `tail -50 logs/` | 每天 |
| Session 文件 | `ls -la sessions/` | 每周 |

### 备份策略

| 项目 | 备份位置 | 频率 |
|------|----------|------|
| 配置 | `~/.openclaw/` | 每次升级前 |
| 模型配置 | `defaults.json` | 每次升级前 |
| 会话 | `sessions/*.jsonl` | 每周 |

### 应急响应

1. **检测到崩溃** → 自动回滚到上一版本
2. **检测到循环** → 停止并通知
3. **检测到磁盘满** → 清理旧会话文件
4. **检测到配置损坏** → 恢复备份

---

## 📋 五、持续改进

### 定期任务

- [ ] 每周检查 GitHub Issues 新增问题
- [ ] 每月审查日志中的新错误模式
- [ ] 季度性更新检测脚本
- [ ] 更新本文档

### 信息来源

- GitHub Issues: https://github.com/openclaw/openclaw/issues
- Discord 社区
- Moltbook 讨论

---

*最后更新: 2026-02-24*
