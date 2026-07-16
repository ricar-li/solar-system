# 🪐 太阳系探险 (Solar System Explorer)

iPad 原生教育 app：SceneKit 3D 太阳系 + SwiftUI 科普卡片。贴图 / 星空全部程序化生成，零外部素材。

## 运行

```bash
# 需 Xcode（本机可用 Xcode-beta）
open SolarSystem.xcodeproj
# 选 iPad 模拟器或真机，⌘R
```

重新生成工程（若改了 `project.yml`）：

```bash
xcodegen generate
```

命令行构建示例：

```bash
DEVELOPER_DIR="$HOME/Downloads/Xcode-beta.app/Contents/Developer" \
  xcodebuild -project SolarSystem.xcodeproj -scheme SolarSystem \
  -sdk iphonesimulator -destination "generic/platform=iOS Simulator" \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
```

## 操作

| 手势 / 控件 | 作用 |
|-------------|------|
| 单指拖动 | 旋转太阳系 |
| 双指缩放 | 拉近 / 拉远 |
| 点行星或底部条 | 选中 + **镜头飞向** + 科普卡 |
| **双击空白** 或 「全景」 | 重置视角 |
| 轨道 / 名字 | 开关轨道环与中文标签 |
| 🐢 / 速度滑条 | 暂停公转自转、调速 |
| **猜猜看** | 三选一趣味答题 |

## v1.1

- 选中镜头平滑飞向
- 重置全景（按钮 + 双击）
- 火星—木星间小行星带
- 猜猜看 Quiz
- 信息卡「上一颗 / 下一颗」

## 结构

```
Sources/
  SolarSystemApp.swift    入口
  ContentView.swift       HUD + 信息卡 + Quiz
  SpaceView.swift         SceneKit 场景与手势
  PlanetData.swift        太阳 + 八大行星科普
  Models.swift            Planet 模型
  TextureGenerator.swift  程序化贴图
  QuizEngine.swift        出题逻辑
```

目标平台：**iPhone + iPad**（iOS 16+，设备族 1,2）。竖屏/横屏自适应；iPhone 上信息卡为底部抽屉。  
Game Studio 文档见 `design/`、`production/`。
