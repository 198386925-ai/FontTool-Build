# 字体工坊 FontStudio

从零编写的 iOS 字体工具（SwiftUI，iOS 16+），功能：

- **预览**：输入任意文字，选择已导入字体，滑动调整字号，实时渲染
- **字体库**：从文件导入 ttf / otf / ttc，查看字体信息（家族/样式/PostScript 名），左滑删除
- **安装**：把字体库打包成 `.mobileconfig` 描述文件并分享，到 iPhone「设置」中安装后全系统可用
- **海报**：文字画布排版，可拖动 / 缩放 / 旋转，导出为图片
- **工具箱**：字体转换（ttf / otf 与 woff 互转）、字符替换（按规则替换字符并指定字体，可导出图片）

## 打包

推送到 `main` 分支（或手动触发）即在 GitHub Actions（macos-15-intel + Xcode 26）上构建**未签名** IPA：

- 产物命名：`FontStudio-1.0.0-Build(0).ipa`，每次构建 build 号 +1
- 每次构建同时产出干净源码备份 `FontStudio-1.0.0-Build(0)-src.zip`（仅真实源码，不含 build/、output/、.git）
- IPA 发布到 `dist` 分支 `FontStudio-latest.ipa`，Actions artifact 保留 5 天

IPA 未签名，安装前需自行签名。

## 版本规则

- 版本号 `CFBundleShortVersionString`：`1.0.0`（发版时手动 bump）
- 构建号 `CFBundleVersion`：每次构建前 +1，从 0 开始
