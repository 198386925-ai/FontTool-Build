import SwiftUI
import UIKit

/// 海报文字图层
struct PosterLayer: Identifiable {
    let id = UUID()
    var text: String = "字体工坊"
    var fontPSName: String = "__system__"
    var fontSize: CGFloat = 72
    var colorRGB: (Double, Double, Double, Double) = (1, 1, 1, 1)
    var offset: CGSize = .zero
    var scale: CGFloat = 1
    var rotation: Double = 0 // 度

    var color: Color {
        Color(red: colorRGB.0, green: colorRGB.1, blue: colorRGB.2, opacity: colorRGB.3)
    }

    func font() -> Font {
        fontPSName == "__system__"
            ? Font.system(size: fontSize).weight(.bold)
            : Font.custom(fontPSName, size: fontSize)
    }
}

/// 单个图层视图：点选 + 拖动 / 缩放 / 旋转
struct PosterLayerView: View {
    @Binding var layer: PosterLayer
    var isSelected: Bool
    var onSelect: () -> Void

    @State private var dragT: CGSize = .zero
    @State private var scaleT: CGFloat = 1
    @State private var rotT: Angle = .zero

    var body: some View {
        Text(layer.text.isEmpty ? " " : layer.text)
            .font(layer.font())
            .foregroundColor(layer.color)
            .scaleEffect(layer.scale * scaleT)
            .rotationEffect(.degrees(layer.rotation) + rotT)
            .offset(x: layer.offset.width + dragT.width, y: layer.offset.height + dragT.height)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.accentColor, lineWidth: 2)
                    .padding(-10)
                    .opacity(isSelected ? 1 : 0)
            )
            .onTapGesture { onSelect() }
            .gesture(
                DragGesture()
                    .onChanged { v in onSelect(); dragT = v.translation }
                    .onEnded { _ in
                        layer.offset.width += dragT.width
                        layer.offset.height += dragT.height
                        dragT = .zero
                    }
                    .simultaneously(with:
                        MagnificationGesture()
                            .onChanged { v in onSelect(); scaleT = v }
                            .onEnded { _ in layer.scale *= scaleT; scaleT = 1 }
                    )
                    .simultaneously(with:
                        RotationGesture()
                            .onChanged { v in onSelect(); rotT = v }
                            .onEnded { _ in layer.rotation += rotT.degrees; rotT = .zero }
                    )
            )
    }
}

/// 海报画布
struct PosterCanvas: View {
    @Binding var layers: [PosterLayer]
    var selectedID: UUID?
    var canvasSize: CGSize
    var bg: Color
    var onSelect: (UUID?) -> Void

    var body: some View {
        ZStack {
            bg.onTapGesture { onSelect(nil) }
            ForEach($layers) { $layer in
                PosterLayerView(layer: $layer, isSelected: $layer.wrappedValue.id == selectedID) {
                    onSelect($layer.wrappedValue.id)
                }
                .position(x: canvasSize.width / 2, y: canvasSize.height / 2)
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .clipped()
    }
}

/// 图层编辑面板
struct PosterLayerEditor: View {
    @Binding var layer: PosterLayer
    var fonts: [FontInfo]

    var body: some View {
        VStack(spacing: 8) {
            TextField("文字内容", text: $layer.text)
                .textFieldStyle(.roundedBorder)
            HStack {
                Picker("字体", selection: $layer.fontPSName) {
                    Text("系统粗体").tag("__system__")
                    ForEach(fonts) { f in Text(f.displayName).tag(f.postScriptName) }
                }
                .pickerStyle(.menu)
                Spacer()
                ColorPicker("颜色", selection: Binding(
                    get: { layer.color },
                    set: { c in
                        let comps = UIColor(c).cgColor.components ?? [1, 1, 1, 1]
                        if comps.count >= 3 {
                            layer.colorRGB = (Double(comps[0]), Double(comps[1]), Double(comps[2]),
                                              Double(comps.count >= 4 ? comps[3] : 1))
                        }
                    }
                ))
            }
            HStack {
                Text("大小")
                Slider(value: $layer.fontSize, in: 12...300, step: 1)
                Text("\(Int(layer.fontSize))").frame(width: 40, alignment: .trailing)
            }
        }
        .padding(.horizontal)
    }
}

/// 字体海报编辑
struct PosterView: View {
    @EnvironmentObject var fontManager: FontManager

    @State private var layers: [PosterLayer] = [PosterLayer()]
    @State private var selectedID: UUID?
    @State private var canvasColor: Color = Color(red: 0.16, green: 0.17, blue: 0.38)
    @State private var exportURL: URL?
    @State private var showingShare = false
    @State private var message = ""
    @State private var showMessage = false

    let canvasSize = CGSize(width: 1080, height: 1440) // 3:4

    var selectedLayer: Binding<PosterLayer>? {
        guard let id = selectedID,
              let idx = layers.firstIndex(where: { $0.id == id }) else { return nil }
        return $layers[idx]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                GeometryReader { geo in
                    let s = min(geo.size.width / canvasSize.width,
                                geo.size.height / canvasSize.height)
                    PosterCanvas(layers: $layers, selectedID: selectedID,
                                 canvasSize: canvasSize, bg: canvasColor) { selectedID = $0 }
                        .frame(width: canvasSize.width * s, height: canvasSize.height * s)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
                .background(Color(UIColor.systemGroupedBackground))

                if let b = selectedLayer {
                    PosterLayerEditor(layer: b, fonts: fontManager.fonts)
                        .padding(.vertical, 6)
                } else {
                    Text("点选画布上的文字进行编辑，可拖动 / 双指缩放 / 旋转")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 6)
                }

                HStack {
                    Button("添加文字") {
                        let l = PosterLayer(text: "新文字")
                        layers.append(l)
                        selectedID = l.id
                    }
                    Spacer()
                    ColorPicker("背景", selection: $canvasColor)
                    Spacer()
                    Button("删除所选") {
                        if let id = selectedID {
                            layers.removeAll { $0.id == id }
                            selectedID = nil
                        }
                    }
                    .disabled(selectedID == nil)
                    Spacer()
                    Button("导出图片", action: export)
                        .disabled(layers.isEmpty)
                }
                .padding()
            }
            .navigationTitle("海报")
            .sheet(isPresented: $showingShare) {
                if let u = exportURL { ShareSheet(items: [u]) }
            }
            .alert("提示", isPresented: $showMessage, actions: {
                Button("好", role: .cancel) {}
            }, message: {
                Text(message)
            })
        }
    }

    private func export() {
        let view = PosterCanvas(layers: $layers, selectedID: nil,
                                canvasSize: canvasSize, bg: canvasColor) { _ in }
        let renderer = ImageRenderer(content: view)
        guard let img = renderer.uiImage, let data = img.pngData() else {
            message = "导出失败，请重试"; showMessage = true; return
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("字体工坊-海报.png")
        do {
            try data.write(to: url, options: .atomic)
            exportURL = url
            showingShare = true
        } catch {
            message = error.localizedDescription; showMessage = true
        }
    }
}
