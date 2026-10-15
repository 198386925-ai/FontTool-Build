import SwiftUI

/// 安装字体到系统：生成描述文件并分享（极简风）
struct InstallView: View {
    @EnvironmentObject var fontManager: FontManager

    @State private var profileURL: URL?
    @State private var showingShare = false
    @State private var showError = false
    @State private var errorText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 说明卡
                    VStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.accentColor)
                            .cornerRadius(18)
                        Text("安装字体到系统")
                            .font(.title2)
                            .bold()
                        Text("iOS 不允许 App 直接安装系统字体。这里会把字体打包成描述文件（.mobileconfig），传到 iPhone 并在「设置」中安装，字体即可在全系统使用。")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)

                    // 字体清单卡
                    VStack(alignment: .leading, spacing: 8) {
                        Text("将打包以下字体（共 \(fontManager.fonts.count) 个）")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        if fontManager.fonts.isEmpty {
                            Text("字体库是空的，请先去「字体库」导入字体。")
                                .font(.callout)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(fontManager.fonts.prefix(5)) { f in
                                HStack {
                                    Image(systemName: "doc")
                                        .foregroundColor(.secondary)
                                    Text(f.displayName)
                                        .font(.callout)
                                        .lineLimit(1)
                                }
                            }
                            if fontManager.fonts.count > 5 {
                                Text("等共 \(fontManager.fonts.count) 个")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)

                    // 操作按钮
                    Button(action: generate) {
                        Text("生成描述文件并分享")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(fontManager.fonts.isEmpty ? Color.gray : Color.accentColor)
                            .cornerRadius(16)
                    }
                    .disabled(fontManager.fonts.isEmpty)

                    // 步骤卡
                    VStack(alignment: .leading, spacing: 12) {
                        Text("安装步骤")
                            .font(.headline)
                        ForEach(Array(steps.enumerated()), id: \.offset) { i, s in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(i + 1)")
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Color.accentColor)
                                    .clipShape(Circle())
                                Text(s)
                                    .font(.callout)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
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

    private var steps: [String] {
        [
            "通过隔空投送 / 文件 / 聊天工具把 .mobileconfig 传到 iPhone",
            "打开「设置」，顶部会出现「已下载描述文件」",
            "点击安装，输入锁屏密码并确认",
            "安装完成后，字体在全系统可用",
        ]
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
