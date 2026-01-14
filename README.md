# FocusAt 番茄钟 (V0)

## 平台
- macOS
- watchOS（本地独立存储）

## 图标来源
- OpenMoji 1F345 Tomato (CC BY-SA 4.0): https://openmoji.org/library/emoji-1F345/

## 版本计划

### V0 核心基石
- 功能：Focus 25 / Break 5（写死），EndAt 真相计时逻辑，本地通知。
- 界面：仅窗口模式，极致轻量，确保休眠/唤醒时间准确。

### V1 任务与流程（Context & Flow）
- 目标：解决“我在专注什么”，并遵循标准的番茄工作法流程。
- 任务关联：启动时输入当前专注内容（支持快速选择最近任务）。
- 长休息逻辑（Long Break）：自动追踪周期，每完成 4 个番茄钟，提示/进入一次长休息（如 15-20 分钟）。
- 标签系统：分类标签（如：工作、学习、阅读），便于后续统计。
- 打断处理：增加提前结束/放弃状态，区分完成与被干扰。
- 数据底座：记录上限与 schemaVersion，便于后续迁移与性能控制。

### V2 体验与个性化（Immersion）
- 目标：提升使用的愉悦感，适配 macOS 桌面使用习惯。
- 菜单栏助手（Menu Bar）：常驻状态栏，支持下拉快速开始/暂停，显示剩余时间图标。
- 灵活配置：自定义 Focus/Short Break/Long Break 时长，支持自动开始下一轮（Auto-start）。
- 白噪音（Soundscapes）：内置 2-3 种极简白噪音（如雨声、咖啡馆、时钟滴答声），随计时自动播放/停止。
- 极简模式（Mini Mode）：支持悬浮小窗或画中画模式，减少屏幕占用。

### V3 数据与洞察（Quantify）
- 目标：通过数据反馈激励用户，复盘工作效率。
- 可视化统计：引入日/周/月视图图表，展示专注时长趋势与时段分布热力图。
- 日历同步（Calendar Sync）：将完成的专注时段自动写入系统日历（单向或双向），方便回顾“时间都去哪了”。
- 导出功能：支持 CSV/JSON 导出，方便二次数据分析。
- 存储迁移：支持升级到 SQLite / SwiftData / CloudKit 的平滑迁移路径。

### V4 生态与自动化（Ecosystem）
- 目标：融入 Apple 原生生态，实现多端无缝流转。
- 多端同步：iOS / watchOS 独立 App，通过 CloudKit（iCloud）实时同步状态与记录。
- 原生特性：iOS 支持灵动岛与实时活动显示倒计时；watchOS 支持 Complications 表盘显示。
- 自动化：支持 Siri Shortcuts 与 AppleScript，允许通过脚本控制（如开启专注时自动开启 Mac 的“勿扰模式”）。
