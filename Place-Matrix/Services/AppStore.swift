//
//  AppStore.swift
//  Place-Matrix
//
//  View と Repository をつなぐ唯一の窓口。
//

import Foundation
import Observation

/// アプリ全体の状態を保持する。
///
/// View は DB を直接触らず、必ずこのクラス経由で Repository を利用する（仕様書 §17）。
/// 画面ごとに ViewModel を作らず、状態をここへ集約して構成を単純に保つ。
@Observable
final class AppStore {

    // MARK: - 公開する状態

    private(set) var places: [Place] = []
    private(set) var templates: [Template] = []

    /// placeId → その Place が持つ Information（表示順）
    private(set) var informationByPlace: [Int64: [Information]] = [:]

    /// 一覧の検索キーワード。変更したら `reloadPlaces()` を呼ぶ。
    var searchText: String = ""

    /// DB の準備が終わったか
    private(set) var isReady = false

    /// 直近のエラー。View 側でアラート表示に使う。
    var errorMessage: String?

    // MARK: - 依存

    private let database: SQLiteManager
    private let placeRepository: PlaceRepository
    private let informationRepository: InformationRepository
    private let templateRepository: TemplateRepository

    init(database: SQLiteManager = .shared) {
        self.database = database
        self.placeRepository = PlaceRepository(database: database)
        self.informationRepository = InformationRepository(database: database)
        self.templateRepository = TemplateRepository(database: database)
    }

    // MARK: - 起動

    /// DB を開いて初期データを読み込む。アプリ起動時に一度だけ呼ぶ。
    func start() {
        guard !isReady else { return }
        perform {
            try database.open()
            templates = try templateRepository.fetchAll()
            places = try placeRepository.fetchAll()
            informationByPlace = try informationRepository.fetchAllGroupedByPlace()
            isReady = true
        }
    }

    // MARK: - 読み込み

    /// 検索キーワードを反映して一覧を読み直す
    func reloadPlaces() {
        perform {
            places = try placeRepository.search(keyword: searchText)
            informationByPlace = try informationRepository.fetchAllGroupedByPlace()
        }
    }

    /// 指定 Place の Information（表示順）
    func informations(for placeId: Int64) -> [Information] {
        informationByPlace[placeId] ?? []
    }

    /// 4分割インジケータ用に、位置をキーにして返す
    func quadrants(for placeId: Int64) -> [Position: Information] {
        Dictionary(informations(for: placeId).map { ($0.position, $0) }) { _, latest in latest }
    }

    /// 単一情報表示で使う Information。位置 `.single` を優先し、なければ先頭を使う。
    func primaryInformation(for placeId: Int64) -> Information? {
        let all = informations(for: placeId)
        return all.first { $0.position == .single } ?? all.first
    }

    func template(id: Int64?) -> Template? {
        guard let id else { return nil }
        return templates.first { $0.id == id }
    }

    /// Place に適用中の Template 名（未設定なら nil）
    func templateName(for place: Place) -> String? {
        template(id: place.templateId)?.name
    }

    func templateItems(templateId: Int64) -> [TemplateItem] {
        (try? templateRepository.items(templateId: templateId)) ?? []
    }

    // MARK: - Place の操作

    /// 追加または更新し、保存後の Place を返す
    @discardableResult
    func save(_ place: Place) -> Place? {
        var saved: Place?
        perform {
            saved = try placeRepository.save(place)
            refreshPlaces()
        }
        return saved
    }

    func delete(placeId: Int64) {
        perform {
            try placeRepository.delete(id: placeId)
            informationByPlace[placeId] = nil
            refreshPlaces()
        }
    }

    /// Template を Place へ適用する。既存の Information は入れ替わる。
    func applyTemplate(_ template: Template, to place: Place) {
        perform {
            var target = place
            if !target.isSaved {
                target = try placeRepository.insert(target)
            }
            let items = try templateRepository.items(templateId: template.id)
            try informationRepository.replaceAll(placeId: target.id, with: items)

            target.templateId = template.id
            target.displayMode = template.displayMode
            _ = try placeRepository.update(target)

            refreshPlaces()
            refreshInformation(placeId: target.id)
        }
    }

    // MARK: - Information の操作

    @discardableResult
    func save(_ information: Information) -> Information? {
        var saved: Information?
        perform {
            saved = try informationRepository.save(information)
            refreshInformation(placeId: information.placeId)
        }
        return saved
    }

    func delete(information: Information) {
        perform {
            try informationRepository.delete(id: information.id)
            refreshInformation(placeId: information.placeId)
        }
    }

    // MARK: - 内部処理

    private func refreshPlaces() {
        places = (try? placeRepository.search(keyword: searchText)) ?? places
    }

    private func refreshInformation(placeId: Int64) {
        informationByPlace[placeId] = (try? informationRepository.fetch(placeId: placeId)) ?? []
    }

    /// Repository の例外をまとめて受け止め、エラーメッセージに変換する
    private func perform(_ work: () throws -> Void) {
        do {
            try work()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
