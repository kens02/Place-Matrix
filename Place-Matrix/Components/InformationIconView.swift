//
//  InformationIconView.swift
//  Place-Matrix
//
//  Information のピクトグラム表示。
//

import SwiftUI

/// Information のアイコンを表示する。
///
/// iconName は文字列で保持されているため、存在しない名前は
/// IconCatalog 側で代替アイコンに置き換えられる（仕様書 §6）。
struct InformationIconView: View {
    let iconName: String
    var size: CGFloat = 24
    var color: Color = .primary

    init(iconName: String, size: CGFloat = 24, color: Color = .primary) {
        self.iconName = iconName
        self.size = size
        self.color = color
    }

    init(information: Information, size: CGFloat = 24, color: Color = .primary) {
        self.init(iconName: information.iconName, size: size, color: color)
    }

    var body: some View {
        Image(systemName: IconCatalog.resolvedIconName(iconName))
            .font(.system(size: size))
            .foregroundStyle(color)
            // アイコンごとの幅の違いでレイアウトがずれないよう枠を固定する
            .frame(width: size * 1.4, height: size * 1.15)
    }
}

#Preview {
    VStack(spacing: 16) {
        InformationIconView(iconName: "bolt.fill", size: 40, color: .yellow)
        InformationIconView(iconName: "drop.fill", size: 40, color: .blue)
        // 存在しない名前は代替アイコンになる
        InformationIconView(iconName: "not.a.real.symbol", size: 40, color: .red)
    }
    .padding()
}
