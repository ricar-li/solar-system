# SolarSystem（太阳系探险）· Agent Handoff

## 一句话
SwiftUI + SceneKit 儿童科普：点行星看资料 + 猜猜看。中文 UI，iPhone+iPad。

## 构建

```bash
export DEVELOPER_DIR=/Users/ricarli/Downloads/Xcode-beta.app/Contents/Developer
cd /Users/ricarli/Desktop/SolarSystem
xcodebuild -project SolarSystem.xcodeproj -scheme SolarSystem \
  -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M5)' \
  -derivedDataPath build build
```

- Family: `1,2` · Team: `Y6Z8UXDHU2` · iOS 16+
- XcodeGen: `project.yml` → `xcodegen generate` 若改配置

## 关键文件

| 文件 | 职责 |
|------|------|
| `Sources/ContentView.swift` | HUD、信息卡、猜猜看、自适应 compact |
| `Sources/SpaceView.swift` | SCNView、公转、跟随、手势 |
| `Sources/PlanetData.swift` | 中文科普数据 |
| `Sources/QuizEngine.swift` | 三选一 |

## 已完成（2026-07-16 kid UX）

- [x] 选中行星 **相机跟随**（renderer 内 update lookTarget）
- [x] `onReset`：双击与「全景」同步清空 `selected`
- [x] 点选 parent walk + 小行星更好点
- [x] 选中/答题时轨道自动停；关闭恢复
- [x] 手机信息卡 dim scrim；可藏底部 chrome
- [x] 猜猜看「🔭 去看看它」；分数「答对 N 题」
- [x] Tip `@AppStorage("kid.tip.dismissed")`
- [x] 金星 emoji 修正（非 🌕）

## 续作

1. 手机 **横屏**专用布局（侧卡 + 折叠控件）  
2. TTS「读给我听」zh-CN  
3. 启动纹理/星空后台生成，减首帧卡顿  
4. 小行星带节点合并 / 手机减数量  
5. 无障碍 accessibilityLabel  

## 回归

- 点水星能否稳住画面中  
- 双击空白 = 全景且不再飞回旧选择  
- 答题后「去看看它」飞向正确行星  

---

## 同系列其它游戏（路径）

| 游戏 | 路径 | Handoff |
|------|------|---------|
| 方块冒险 CubeQuest | `/Users/ricarli/Desktop/CubeQuest` | `HANDOFF.md` |
| 太阳系 SolarSystem | `/Users/ricarli/Desktop/SolarSystem` | `HANDOFF.md` |
| 坦克 Tank | `/Users/ricarli/Desktop/Tank` | `HANDOFF.md` |
| 象棋 ChessiPad | `/Users/ricarli/Desktop/ChessiPad` | `HANDOFF.md` |
| Minecraft-cc | `/Users/ricarli/Desktop/Minecraft-cc` | `HANDOFF.md` |
| 狗狗世界 Dog | `/Users/ricarli/Desktop/Dog` | `HANDOFF.md` |

> 总索引已取消；每局只读自己目录下的 `HANDOFF.md`。
