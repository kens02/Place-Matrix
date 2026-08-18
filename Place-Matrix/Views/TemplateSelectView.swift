//
//  TemplateSelectView.swift
//  Place-Matrix
//
//  Place に適用する Template を選ぶ画面。
//

import SwiftUI

/// Template の選択（仕様書 §5）。
///
/// 「どの4情報を4分割表示するか」を決める。
struct TemplateSelectView: View {

    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    /// 選択中の Template。未設定は nil。
    @Binding var selectedTemplateId: Int64?

    var body: some View {
        List {
            Section {
                ForEach(store.templates) { template in
                    Button {
                        select(template.id)
                    } label: {
                        row(for: template)
                    }
                    .buttonStyle(.plain)
                }
            } footer: {
                Text("Template を選ぶと、その4つの情報が「不明」の状態で作られます。")
            }

            Section {
                Button("Template を使わない") {
                    select(nil)
                }
            }
        }
        .navigationTitle("Template")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(for template: Template) -> some View {
        let items = store.templateItems(templateId: template.id)

        return HStack(spacing: 14) {
            // 未設定（レベル0）の状態でどう並ぶかを見せる
            FourQuadrantIndicator(
                informations: Dictionary(
                    items.map { ($0.position, $0.makeInformation(placeId: Place.unsavedId)) },
                    uniquingKeysWith: { _, latest in latest }
                ),
                size: .small
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(template.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(items.map(\.informationName).joined(separator: " / "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if selectedTemplateId == template.id {
                Image(systemName: "checkmark")
                    .foregroundStyle(.tint)
                    .fontWeight(.semibold)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private func select(_ id: Int64?) {
        selectedTemplateId = id
        dismiss()
    }
}

#Preview {
    NavigationStack {
        TemplateSelectView(selectedTemplateId: .constant(nil))
    }
    .environment(AppStore(database: SQLiteManager(databaseURL: nil)))
}
