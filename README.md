# 古风行

第一人称古风探索 / 战斗 / 任务原型。

基于 **Godot 4**（MIT 协议，无商业绑定），可导出 Windows / macOS / Linux 桌面客户端。

---

## 功能概览

| 系统 | 内容 |
|------|------|
| 第一人称操作 | WASD 移动、鼠标视角、奔跑、跳跃 |
| 近战战斗 | 视角长剑、挥砍判定、受击击退、气血、重生 |
| 敌人 AI | 索敌、追击、近战攻击 |
| 对话 | 守院老者分支对话（随任务状态变化） |
| 任务 | 主线任务链 + 左上角目标追踪 |
| 场景 | 程序化「清风院」：正殿、凉亭、水池、灯笼、树木 |

当前美术为**程序化几何占位**，便于快速迭代玩法；正式模型建议用 Blender 制作后导入。

---

## 环境要求

- [Godot 4.3+](https://godotengine.org/download)（推荐 4.3 / 4.4 / 4.7）
- 系统：Windows / macOS / Linux

---

## 快速开始

1. 安装 Godot 4
2. 打开 Godot → **Import** → 选择本仓库中的 `project.godot`
3. 按 **F5**（或点击右上角 Play）运行

命令行运行示例（Windows）：

```bash
godot --path .
```

若输入无响应：先**用鼠标点击游戏窗口**获得焦点，再操作。

---

## 操作说明

| 按键 | 功能 |
|------|------|
| WASD / 方向键 | 移动 |
| 鼠标 | 视角（需锁定鼠标） |
| 鼠标左键 | 挥剑攻击 / 点击窗口锁定鼠标 |
| Shift | 奔跑 |
| 空格 | 跳跃 |
| E | 交互 / 对话 / 拾取 |
| Esc | 释放 / 捕获鼠标 |
| R | 死亡后重生 |

---

## 主线流程

1. **清风院异变** — 与正殿前 **守院老者** 交谈  
2. **寻回旧物** — 拾取左右凉亭古卷 + 供台玉佩  
3. **清剿宵小** — 击败院中 3 名匪徒  
4. **复命老者** — 回报老者，获得治疗  

支线：阅读石碑、采集池边莲花。

---

## 目录结构

```
├── project.godot          # 项目配置
├── icon.svg               # 图标
├── README.md
├── .gitignore
├── scenes/
│   ├── main.tscn          # 主场景
│   └── player.tscn        # 玩家（第一人称 + 武器）
├── scripts/
│   ├── main.gd            # 主场景逻辑
│   ├── player.gd          # 移动 / 视角 / 攻击 / 交互
│   ├── enemy.gd           # 敌人 AI
│   ├── npc.gd             # NPC 与对话分支
│   ├── dialogue_ui.gd     # 对话框 UI
│   ├── world_builder.gd   # 程序化场景搭建
│   ├── interactable.gd    # 可拾取 / 可读物
│   ├── hud.gd             # 血条、任务、提示
│   └── game_state.gd      # 全局状态：血量、任务、收集
└── assets/                # 美术资源（模型 / 贴图 / 音频）
    └── models/            # 建议放置 .glb 模型
```

---

## 美术与建模工作流

Godot **不负责建模**。本项目已用 **Blender 程序化脚本** 生成首批低模 glTF，并接入游戏。

### 本仓库已有模型（Blender 导出）

```
assets/models/
├── architecture/
│   ├── main_hall.glb      # 正殿
│   ├── pavilion.glb       # 凉亭
│   ├── gate.glb           # 院门
│   ├── pillar.glb
│   ├── wall_segment.glb
│   └── roof_module.glb
├── props/
│   ├── lantern.glb        # 灯笼
│   ├── stone_lion.glb     # 石狮
│   ├── stele.glb          # 石碑
│   ├── tree.glb
│   ├── scroll.glb / jade.glb
│   └── sword.glb          # 第一人称武器
└── characters/
    ├── npc_elder.glb      # 守院老者
    └── enemy_bandit.glb   # 匪徒
```

游戏通过 `scripts/model_library.gd` 加载：有 glb 用模型，没有则回退几何占位。

### 重新生成模型

需安装 [Blender 4+](https://www.blender.org/)（本机可用 5.2）：

```powershell
& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" --background --python tools/blender_build_models.py
```

脚本：`tools/blender_build_models.py`  
修改脚本后重跑即可覆盖 `assets/models/**/*.glb`。

### 手工商模流程

| 工具 | 用途 |
|------|------|
| Blender | 主推：建模、UV、贴图、动画 |
| Blockbench | 低多边形 / 简单角色 |

1. Blender 制作 → 导出 **glTF Binary（.glb）**  
2. 放入对应 `assets/models/...` 路径（与 `ModelLibrary.PATHS` 一致）  
3. Godot 重新导入后自动使用  

### 免费素材参考

- [Kenney](https://kenney.nl) — CC0 低模  
- OpenGameArt、itch.io（注意授权）

---

## 导出桌面客户端

1. Godot → **Project → Export**  
2. 添加 Windows / Linux / macOS 预设（首次需下载对应导出模板）  
3. **Export Project** 生成可执行文件  

---

## 技术说明

- 物理层：`world` / `player` / `interactable` / `enemy`
- 全局单例：`GameState`（autoload）
- 输入：玩家移动优先读取物理键位（WASD），降低 InputMap 配置问题
- 渲染：默认 Forward+；低配可在项目设置中改用 Compatibility

---

## 后续计划

- [ ] 用 Blender 替换建筑 / 角色真实模型  
- [ ] 剑招连段、格挡、简易法术  
- [ ] 多场景切换与本地存档  
- [ ] 音效与背景音乐  
- [ ] 更完整的任务与对话系统  

---

## 许可证

- 引擎：Godot（MIT）  
- 本仓库代码：可按项目需要自行约定（默认随仓库公开）  
- 第三方素材请遵守各自授权  

---

## 问题排查

| 现象 | 处理 |
|------|------|
| 按键完全没反应 | 先点击游戏窗口获得焦点 |
| 鼠标不能转视角 | 点击窗口锁定鼠标；Esc 切换锁定 |
| 画面卡顿 / 未响应 | 关闭阴影与 SSAO；或用 `--rendering-method gl_compatibility` 启动 |
| 脚本报错 | 确认 Godot 版本 ≥ 4.3，并用编辑器打开查看 Debugger |
