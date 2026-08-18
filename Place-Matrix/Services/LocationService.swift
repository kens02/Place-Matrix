//
//  LocationService.swift
//  Place-Matrix
//
//  現在地の取得。位置情報の扱いを View から切り離す。
//

import Foundation
import CoreLocation
import Observation

/// CLLocationManager を包み、権限と現在地だけを View に見せる（仕様書 §17）。
@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()

    private(set) var authorizationStatus: CLAuthorizationStatus
    private(set) var currentLocation: CLLocation?
    private(set) var errorMessage: String?

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    /// 権限があるか（使用中の許可のみで足りる）
    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    /// ユーザーが明示的に拒否した状態か
    var isDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    /// まだ尋ねていなければ許可を求め、許可済みなら更新を始める
    func requestAuthorizationIfNeeded() {
        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdating()
        default:
            break
        }
    }

    func startUpdating() {
        guard isAuthorized else { return }
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if isAuthorized {
            errorMessage = nil
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        currentLocation = latest
        errorMessage = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // 一時的に測位できないだけのことが多いため、状態は保持したままにする
        errorMessage = error.localizedDescription
    }
}
