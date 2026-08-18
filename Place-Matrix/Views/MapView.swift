//
//  MapView.swift
//  Place-Matrix
//
//  地図に Place を表示する画面。
//

import SwiftUI
import MapKit

/// 地図画面（仕様書 §8）。
///
/// Annotation にはカスタムの SwiftUI View（PlaceAnnotationView）を使う。
struct MapView: View {

    @Environment(AppStore.self) private var store
    private let location = LocationService.shared

    /// 既定は .automatic。登録済みの場所と現在地がすべて収まるように地図が自動で寄る。
    @State private var camera: MapCameraPosition = .automatic
    @State private var selectedPlaceId: Int64?
    /// 地図をタップして選んだ、まだ登録していない地点
    @State private var pendingCoordinate: CLLocationCoordinate2D?
    /// 編集画面に渡す、まだ保存していない Place
    @State private var editingPlace: Place?
    var body: some View {
        NavigationStack {
            MapReader { proxy in
                Map(position: $camera) {
                    mapContent
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }
                .onTapGesture { point in
                    // タップした画面上の位置を緯度経度へ変換する
                    if let coordinate = proxy.convert(point, from: .local) {
                        selectedPlaceId = nil
                        pendingCoordinate = coordinate
                    }
                }
            }
            .navigationTitle("地図")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("全体表示", systemImage: "scope") {
                        fitToPlaces()
                    }
                    .disabled(store.places.isEmpty)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if pendingCoordinate != nil {
                    addPlaceCard
                } else if location.isDenied {
                    locationDeniedNotice
                }
            }
            .sheet(item: $editingPlace) { place in
                PlaceEditView(place: place) { saved in
                    selectedPlaceId = saved.id
                }
            }
            .onAppear {
                location.requestAuthorizationIfNeeded()
            }
        }
    }

    // MARK: - 地図に載せるもの

    /// 現在地・登録済みの場所・追加候補の地点。
    /// Map のクロージャに直接書くと型チェックが重くなるため切り出している。
    @MapContentBuilder
    private var mapContent: some MapContent {
        UserAnnotation()

        ForEach(store.places) { place in
            Annotation(place.name, coordinate: place.coordinate) {
                annotation(for: place)
            }
            .annotationTitles(.hidden)
        }

        if let pendingCoordinate {
            Marker("新しい地点", systemImage: "plus", coordinate: pendingCoordinate)
                .tint(Color.accentColor)
        }
    }

    private func annotation(for place: Place) -> some View {
        PlaceAnnotationView(
            place: place,
            informations: store.informations(for: place.id),
            isSelected: selectedPlaceId == place.id
        )
        .onTapGesture {
            select(place)
        }
    }

    // MARK: - 部品

    /// タップした地点をそのまま登録するためのカード
    private var addPlaceCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text("この地点に場所を登録")
                        .font(.subheadline.weight(.semibold))
                    if let pendingCoordinate {
                        Text(Self.format(pendingCoordinate))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }

            HStack(spacing: 12) {
                Button("やめる") {
                    pendingCoordinate = nil
                }
                .buttonStyle(.bordered)

                Button("次へ") {
                    addPendingPlace()
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    /// 位置情報が拒否されているときの案内
    private var locationDeniedNotice: some View {
        Label("位置情報が許可されていないため現在地を表示できません", systemImage: "location.slash")
            .font(.caption)
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal)
            .padding(.bottom, 8)
    }

    // MARK: - 操作

    private func select(_ place: Place) {
        pendingCoordinate = nil
        selectedPlaceId = (selectedPlaceId == place.id) ? nil : place.id
    }

    /// タップした地点を編集画面へ渡す。保存は編集画面側で行う。
    private func addPendingPlace() {
        guard let coordinate = pendingCoordinate else { return }
        editingPlace = Place(coordinate: coordinate)
        pendingCoordinate = nil
    }

    /// 登録済みの場所がすべて入るように地図を寄せる
    private func fitToPlaces() {
        guard let region = Self.region(covering: store.places) else { return }
        withAnimation { camera = .region(region) }
    }

    // MARK: - 計算

    /// 与えられた場所をすべて含む表示範囲
    static func region(covering places: [Place]) -> MKCoordinateRegion? {
        guard !places.isEmpty else { return nil }

        let latitudes = places.map(\.latitude)
        let longitudes = places.map(\.longitude)
        guard let minLatitude = latitudes.min(), let maxLatitude = latitudes.max(),
              let minLongitude = longitudes.min(), let maxLongitude = longitudes.max()
        else { return nil }

        let center = CLLocationCoordinate2D(
            latitude: (minLatitude + maxLatitude) / 2,
            longitude: (minLongitude + maxLongitude) / 2
        )
        // 端の場所がふちに張り付かないよう少し広げ、1件だけのときも潰れないようにする
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLatitude - minLatitude) * 1.5, 0.01),
            longitudeDelta: max((maxLongitude - minLongitude) * 1.5, 0.01)
        )
        return MKCoordinateRegion(center: center, span: span)
    }

    static func format(_ coordinate: CLLocationCoordinate2D) -> String {
        String(format: "緯度 %.5f, 経度 %.5f", coordinate.latitude, coordinate.longitude)
    }
}

#Preview {
    MapView()
        .environment(AppStore(database: SQLiteManager(databaseURL: nil)))
}
