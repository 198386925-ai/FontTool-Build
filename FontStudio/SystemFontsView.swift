import SwiftUI
import UIKit

/// 浏览 iOS 内置字体
struct SystemFontsView: View {
    let families = UIFont.familyNames.sorted()
    @State private var query = ""

    var filtered: [String] {
        query.isEmpty
            ? families
            : families.filter { $0.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            List(filtered, id: \.self) { family in
                NavigationLink(destination: FamilyDetailView(family: family)) {
                    Text(family)
                        .font(Font.custom(family, size: 18))
                }
            }
            .searchable(text: $query, prompt: "搜索字体")
            .navigationTitle("系统字体")
        }
    }
}

struct FamilyDetailView: View {
    let family: String

    var names: [String] { UIFont.fontNames(forFamilyName: family) }

    var body: some View {
        List(names, id: \.self) { name in
            VStack(alignment: .leading, spacing: 4) {
                Text("字体工坊 Aa 123")
                    .font(Font.custom(name, size: 24))
                Text(name)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .navigationTitle(family)
        .navigationBarTitleDisplayMode(.inline)
    }
}
