//
//  FourQuadrantIndicator.swift
//  Place-Matrix
//
//  1つの正方形を4分割し、4つの Information を表示する。
//

import SwiftUI

/// 4分割インジケータ（仕様書 §9）。
///
/// 4つの固定フィールドではなく、表示位置を指定して配置された
/// 4つの Information を並べる。位置が埋まっていない区画は未設定として描く。
struct FourQuadrantIndicator: View {

    /// 位置をキーにした Information
    let informations: [Position: Information]
    var size: IndicatorSize = .medium

    /// 区画の境目に見える線の太さ
    private let dividerWidth: CGFloat = 1.5

    init(informations: [Position: Information], size: IndicatorSize = .medium) {
        self.informations = informations
        self.size = size
    }

    /// 配列から作る場合の入り口
    init(informations: [Information], size: IndicatorSize = .medium) {
        self.init(
            informations: Dictionary(informations.map { ($0.position, $0) }) { _, latest in latest },
            size: size
        )
    }

    var body: some View {
        Grid(horizontalSpacing: dividerWidth, verticalSpacing: dividerWidth) {
            GridRow {
                quadrant(at: .topLeft)
                quadrant(at: .topRight)
            }
            GridRow {
                quadrant(at: .bottomLeft)
                quadrant(at: .bottomRight)
            }
        }
        // 区画のすきまから覗かせて仕切り線に見せる
        .background(Color(.systemBackground))
        .frame(width: size.side, height: size.side)
        .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                .strokeBorder(Color(.separator), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    @ViewBuilder
    private func quadrant(at position: Position) -> some View {
        if let information = informations[position] {
            QuadrantCell(information: information, size: size)
        } else {
            EmptyQuadrantCell()
        }
    }

    private var accessibilityDescription: String {
        Position.quadrants
            .compactMap { informations[$0] }
            .map { "\($0.name) \($0.resolvedLevelName)" }
            .joined(separator: "、")
    }
}

/// 情報が入っている区画
private struct QuadrantCell: View {
    let information: Information
    let size: IndicatorSize

    private var definition: LevelDefinition {
        LevelPalette.definition(for: information.level)
    }

    var body: some View {
        definition.color
            .overlay {
                VStack(spacing: 1) {
                    InformationIconView(
                        iconName: information.iconName,
                        size: size.quadrantIconSize,
                        color: definition.foreground
                    )
                    // 小さい表示ではアイコンと色だけに簡略化する（仕様書 §9）
                    if size.showsName {
                        Text(information.shortName)
                            .font(size.quadrantNameFont)
                            .foregroundStyle(definition.foreground)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                }
                .padding(2)
            }
    }
}

/// まだ Information が割り当てられていない区画
private struct EmptyQuadrantCell: View {
    var body: some View {
        Color(.secondarySystemBackground)
            .overlay {
                Image(systemName: "minus")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
    }
}

#Preview("サイズ別") {
    let infrastructure: [Position: Information] = [
        .topLeft: Information(name: "水道", iconName: "drop.fill", level: 1, position: .topLeft),
        .topRight: Information(name: "通信", iconName: "antenna.radiowaves.left.and.right", level: 3, position: .topRight),
        .bottomLeft: Information(name: "電気", iconName: "bolt.fill", level: 2, position: .bottomLeft),
        .bottomRight: Information(name: "ガス", iconName: "flame.fill", level: 4, position: .bottomRight),
    ]

    return VStack(spacing: 24) {
        HStack(alignment: .bottom, spacing: 20) {
            FourQuadrantIndicator(informations: infrastructure, size: .small)
            FourQuadrantIndicator(informations: infrastructure, size: .medium)
        }
        FourQuadrantIndicator(informations: infrastructure, size: .large)
        Text("仕様書 §14 の表示例（水道🟢 通信🟠 電気🟡 ガス🔴）")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
}

#Preview("一部だけ設定") {
    FourQuadrantIndicator(
        informations: [
            .topLeft: Information(name: "火災", iconName: "flame.fill", level: 4, position: .topLeft),
            .bottomRight: Information(name: "倒壊", iconName: "house.fill", level: 2, position: .bottomRight),
        ],
        size: .large
    )
    .padding()
}
