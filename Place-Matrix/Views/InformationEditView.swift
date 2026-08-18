//
//  InformationEditView.swift
//  Place-Matrix
//
//  Information の登録・編集。
//

import SwiftUI

/// Information の編集画面（仕様書 §18-5）。
///
/// ピクトグラム・Level・LevelName・Memo・表示位置を設定する。
struct InformationEditView: View {

    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var draft: Information
    private let isNew: Bool
    /// この Place が4分割表示かどうか。単一表示なら位置を選ばせない。
    private let allowsPositionChange: Bool

    @State private var isDeleteConfirmationPresented = false

    init(information: Information, allowsPositionChange: Bool) {
        _draft = State(initialValue: information)
        self.isNew = !information.isSaved
        self.allowsPositionChange = allowsPositionChange
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("情報") {
                    TextField("名称", text: $draft.name)
                }

                Section("ピクトグラム") {
                    iconPicker
                }

                Section {
                    levelPicker
                    TextField(
                        "レベル名称（未入力なら「\(LevelPalette.defaultName(for: draft.level))」）",
                        text: $draft.levelName
                    )
                } header: {
                    Text("状態")
                } footer: {
                    Text("色だけでなく名称でも状態が分かるようにしています。")
                }

                if allowsPositionChange {
                    Section("表示位置") {
                        Picker("位置", selection: $draft.position) {
                            ForEach(Position.quadrants) { position in
                                Text(position.displayName).tag(position)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Section("メモ") {
                    TextField("メモ（任意）", text: $draft.memo, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    preview
                }

                if !isNew {
                    Section {
                        Button("この情報を削除", role: .destructive) {
                            isDeleteConfirmationPresented = true
                        }
                    }
                }
            }
            .navigationTitle(isNew ? "情報を追加" : "情報を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog(
                "この情報を削除しますか？",
                isPresented: $isDeleteConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button("削除する", role: .destructive) {
                    store.delete(information: draft)
                    dismiss()
                }
                Button("やめる", role: .cancel) {}
            }
        }
    }

    // MARK: - 部品

    private var iconPicker: some View {
        ForEach(IconCatalog.groups) { group in
            VStack(alignment: .leading, spacing: 8) {
                Text(group.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 52), spacing: 8)], spacing: 8) {
                    ForEach(group.icons) { icon in
                        iconCell(icon)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func iconCell(_ icon: IconCatalog.Icon) -> some View {
        let isSelected = draft.iconName == icon.systemName

        return Button {
            draft.iconName = icon.systemName
        } label: {
            VStack(spacing: 3) {
                InformationIconView(
                    iconName: icon.systemName,
                    size: 20,
                    color: isSelected ? .white : .primary
                )
                Text(icon.label)
                    .font(.system(size: 9))
                    .foregroundStyle(isSelected ? .white : .secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                isSelected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(Color(.secondarySystemFill)),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    private var levelPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("レベル")
                .font(.subheadline)

            HStack(spacing: 6) {
                ForEach(LevelPalette.definitions) { definition in
                    levelCell(definition)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func levelCell(_ definition: LevelDefinition) -> some View {
        let isSelected = draft.level == definition.level

        return Button {
            draft.level = definition.level
        } label: {
            VStack(spacing: 3) {
                Text("\(definition.level)")
                    .font(.system(size: 15, weight: .bold))
                Text(definition.name)
                    .font(.system(size: 10, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(isSelected ? definition.foreground : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                isSelected ? AnyShapeStyle(definition.color) : AnyShapeStyle(Color(.secondarySystemFill)),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(definition.color, lineWidth: isSelected ? 0 : 2)
            }
        }
        .buttonStyle(.plain)
    }

    /// 設定した内容がどう見えるかをその場で確認できるようにする
    private var preview: some View {
        HStack {
            Spacer()
            SingleInformationIndicator(information: draft, size: .large)
            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - 操作

    private func save() {
        draft.name = draft.name.trimmingCharacters(in: .whitespaces)
        store.save(draft)
        dismiss()
    }
}

#Preview {
    InformationEditView(
        information: Information(placeId: 1, name: "電気", iconName: "bolt.fill", level: 2, position: .topLeft),
        allowsPositionChange: true
    )
    .environment(AppStore(database: SQLiteManager(databaseURL: nil)))
}
