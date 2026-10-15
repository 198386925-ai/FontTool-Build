import SwiftUI

/// 安装字体到系统：生成描述文件并分享
struct InstallView: View {
    @EnvironmentObject var fontManager: FontManager

    @State private var profileURL: URL?
    @State private var showingShare = false
    @State private var showError = false
    @State private var errorText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("说明")) {
                    Text("iOS 不允许 App 直接安装系统字体。本工具会把字体打包成描述文件（.mobileconfig），你把它传到 iPhone 并在「设置」中安装，字体即可在全系统使用。")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("将打包以下字体（共 \(fontManager.fonts.count) 个）")) {
                    if fontManager.fonts.isEmpty {
                        Text("字体库是空的，请先去「字体库」导入字体。")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(fontManager.fonts) { f in
                            Text(f.displayName)
                        }
                    }
                }

                Section {
                    Button("生成描述文件并分享") { generate() }
                        .disabled(fontManager.fonts.isEmpty)
                }

                Section(header: Text("安装步骤")) {
                    Text("1. 通过隔空投送 / 文件 / 聊天工具把 .mobileconfig 传到 iPhone\n2. 打开「设置」，顶部会出现「已下载描述文件」\n3. 点击安装，输入锁屏密码并确认\n4. 安装完成后，字体在全系统可用")
                        .font(.callout)
                }
            }
            .navigationTitle("安装字体")
            .sheet(isPresented: $showingShare) {
                if let url = profileURL {
                    ShareSheet(items: [url])
                }
            }
            .alert("生成失败", isPresented: $showError, actions: {
                Button("好", role: .cancel) {}
            }, message: {
                Text(errorText)
            })
        }
    }

    private func generate() {
        do {
            let urls = fontManager.fonts.map { fontManager.fileURL(for: $0) }
            profileURL = try ProfileGenerator.makeProfile(
                fontURLs: urls, displayName: "字体工坊字体包"
            )
            showingShare = true
        } catch {
            errorText = error.localizedDescription
            showError = true
        }
    }
}
