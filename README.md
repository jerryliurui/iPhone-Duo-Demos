# iPhone Duo 小 Demo 合集

四个独立的 SwiftUI 小 App，用可操作的场景观察 iPhone Duo 的布局变化。每个 Demo 只关注一组交互，可以单独打开、编译和修改，无需账号、服务器或第三方依赖。

| App | 可以玩什么 | 关注的适配点 |
|---|---|---|
| [折页 FoldNotes](Apps/FoldNotes) | 阅读、讨论、草稿、收藏、瀑布流 | 系统导航、ArrangementView、reserved regions、铰链输入、两列到四列 |
| [对弈钟 DuelClock](Apps/DuelClock) | 双人 3 分钟计时、交棒、暂停、重置 | 两块计时区域、面对面的阅读方向、布局切换时保留计时状态 |
| [折叠鼓机 FoldBeat](Apps/FoldBeat) | 四个鼓垫、四种合成音色、可调速度的四拍节拍器 | 节拍反馈和演奏区分开、ArrangementView 的空间分配 |
| [掌上调色台 PocketPalette](Apps/PocketPalette) | 绘画、六种颜色、笔触粗细、撤销与清空 | 画布与工具分区、归一化笔迹坐标、折叠时保留内容 |

## 开始运行

1. 下载整个仓库（Code → Download ZIP）或 `git clone`。
2. 使用 **Xcode 27.1**，安装 **iOS 27.1 / iPhone Duo Simulator**。
3. 打开 `Apps/<App>/<App>.xcodeproj`，选择同名 Scheme。
4. 选择 iPhone Duo 模拟器并运行。在 Device Hub 改变闭合、半展开、完全展开姿态。
5. 通过 App 的「布局设置」菜单切换「启用适配」。折页的开关位于其页面菜单。

项目默认关闭代码签名，方便模拟器构建。在真机运行时需要自行启用签名、选择开发团队，并使用自己的 bundle identifier。仓库不含开发者团队、描述文件或证书。

## 工程结构

```text
Apps/
  FoldNotes/       # 阅读与内容流
  DuelClock/      # 双人对弈钟
  FoldBeat/       # 合成鼓音与节拍
  PocketPalette/  # 画布与调色工具
    Sources/      # SwiftUI 界面与状态
    scripts/generate_project.py
    <App>.xcodeproj
Tests/            # 对弈钟状态回归检查
Docs/             # 设计说明与验证记录
```

四个 App 互相独立，没有隐藏的共享依赖。项目文件已提交；增加或移除 Swift 文件后，可在对应 App 下执行 `python3 scripts/generate_project.py` 重新生成工程。生成器只收集 `Sources/` 下的 Swift 文件。

```sh
xcodebuild -project Apps/DuelClock/DuelClock.xcodeproj \
  -scheme DuelClock -sdk iphonesimulator \
  -derivedDataPath /tmp/DuelClockBuild build

swiftc Apps/DuelClock/Sources/MatchClock.swift Tests/main.swift \
  -o /tmp/duo-clock-tests && /tmp/duo-clock-tests
```

## 怎么看适配前后

这里的「基础实现」是同一 App 内的**教学基线**，不是线上旧版本、旧 SDK 的实测故障。同内容、同姿态下切换开关，才适合比较空间利用和操作方式。状态放在布局分支之外，切换布局不会有意重置正在进行的操作。

`ArrangementView` 是系统 API；计时状态、鼓声合成与笔迹坐标是 Demo 自己的业务实现。普通宽度适配也可以解决的问题，不应全部归功于 Duo 新 API。

## 使用边界

- 对弈钟为休闲演示：无加秒、赛事规则或长时计时精度认证。离开前台自动暂停；进程结束不恢复对局。
- 鼓声由本地 PCM 合成，无外部采样素材。节拍器是界面定时器驱动的练习工具，不是专业低延迟音序器。离开前台停止节拍。
- 调色台保留当前进程里的笔迹；归一化坐标随画布缩放，宽高比变化会改变笔迹比例。尚无导出或持久化。
- 折页文章和评论为虚构演示内容；收藏与草稿保存在本机。
- 模拟器可以检查布局与状态，不等于真机触感、音频延迟、折叠机构或性能验证。详细记录见 [验证说明](Docs/VALIDATION.md)。

## 许可与隐私

MIT License。代码、原创演示内容和程序合成音色可在遵守许可证的前提下复用。系统图标、系统软件及 Apple 名称归其权利人所有；本项目不是 Apple 官方项目。

公开版本不包含个人业务 App、笔记原始素材、账号数据、证书、密钥、个人邮箱或工作目录。提交使用项目通用身份。
