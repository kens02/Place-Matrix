//
//  PlaceEditView.swift
//  Place-Matrix
//
//  Place の新規登録・編集。
//

import SwiftUI
import CoreLocation

/// Place の編集画面。新規登録と編集の両方で使う。
struct PlaceEditView: View {

    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    /// 編集中の内容。保存するまで DB には書き込まない。
    @State private var draft: Place
    /// 開いた時点で適用されていた Template
    private let originalTemplateId: Int64?
    private let isNew: Bool

    @State private var isTemplateChangeConfirmationPresented = false

    /// 保存後に呼ばれる。呼び出し側が続けて詳細を開くなどに使う。
    var onSaved: ((Place) -> Void)?

    init(place: Place, onSaved: ((Place) -> Void)? = nil) {
        _draft = State(initialValue: place)
        self.originalTemplateId = place.templateId
        self.isNew = !place.isSaved
        self.onSaved = onSaved
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("場所") {
                    TextField("名称", text: $draft.name)
                    TextField("カテゴリ（任意）", text: $draft.category)
                }

                Section {
                    NavigationLink {
                        TemplateSelectView(selectedTemplateId: $draft.templateId)
                    } label: {
                        LabeledContent("Template", value: selectedTemplateName)
                    }

                    Picker("表示方法", selection: $draft.displayMode) {
                        ForEach(DisplayMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                } header: {
                    Text("表示")
                } footer: {
                    if willReplaceInformation {
                        Label(
                            "Template を変えると、登録済みの情報は入れ替わります。",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .foregroundStyle(.orange)
                    }
                }

                Section("位置") {
                    LabeledContent("座標", value: MapView.format(draft.coordinate))
                    Button("現在地に合わせる", systemImage: "location.fill") {
                        useCurrentLocation()
                    }
                    .disabled(currentCoordinate == nil)
                }
            }
            .navigationTitle(isNew ? "場所を登録" : "場所を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { confirmSave() }
                        .disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog(
                "登録済みの情報を入れ替えますか？",
                isPresented: $isTemplateChangeConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button("入れ替える", role: .destructive) { save() }
                Button("やめる", role: .cancel) {}
            } message: {
                Text("いまの情報は削除され、選んだ Template の4つの情報が作られます。")
            }
        }
    }

    // MARK: - 表示用の値

    private var selectedTemplateName: String {
        store.template(id: draft.templateId)?.name ?? "未設定"
    }

    /// 保存すると既存の情報が入れ替わる状況か
    private var willReplaceInformation: Bool {
        draft.templateId != nil
            && draft.templateId != originalTemplateId
            && !store.informations(for: draft.id).isEmpty
    }

    private var currentCoordinate: CLLocationCoordinate2D? {
        LocationService.shared.currentLocation?.coordinate
    }

    // MARK: - 操作

    private func useCurrentLocation() {
        guard let coordinate = currentCoordinate else { return }
        draft.latitude = coordinate.latitude
        draft.longitude = coordinate.longitude
    }

    /// 情報が消える場合だけ確認を挟む
    private func confirmSave() {
        if willReplaceInformation {
            isTemplateChangeConfirmationPresented = true
        } else {
            save()
        }
    }

    private func save() {
        draft.name = draft.name.trimmingCharacters(in: .whitespaces)

        guard let saved = store.save(draft) else { return }

        // Template が変わったときだけ情報を作り直す
        if draft.templateId != originalTemplateId,
           let template = store.template(id: draft.templateId) {
            store.applyTemplate(template, to: saved)
        }

        onSaved?(saved)
        dismiss()
    }
}

#Preview {
    PlaceEditView(place: Place(name: "", latitude: 35.6812, longitude: 139.7671))
        .environment(AppStore(database: SQLiteManager(databaseURL: nil)))
}
