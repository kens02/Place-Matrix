//
//  SingleInformationIndicator.swift
//  Place-Matrix
//
//  1つの Information を1つのインジケータとして表示する。
//

import SwiftUI

/// 単一情報インジケータ（仕様書 §10）。
///
/// サイズに応じて表示内容を変える。
/// - large:  アイコン + 名称 + レベル名称
/// - medium: アイコン + 名称 + 色
/// - small:  アイコン + 色
struct SingleInformationIndicator: View {

    let information: Information
    var size: IndicatorSize = .medium

    private var definition: LevelDefinition {
        LevelPalette.definition(for: information.level)
    }

    var body: some View {
        Group {
            switch size {
            case .small:
                compactBody
            case .medium, .large:
                detailedBody
            }
        }
        .frame(width: size.side, height: size.side)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(information.name) \(information.resolvedLevelName)")
    }

    /// 小さい表示。色で塗りつぶし、アイコンだけを載せる。
    private var compactBody: some View {
        RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
            .fill(definition.color)
            .overlay {
                InformationIconView(
                    iconName: information.iconName,
                    size: size.iconSize,
                    color: definition.foreground
                )
            }
    }

    /// 中・大の表示。色だけに頼らず、名称とレベル名も添える。
    private var detailedBody: some View {
        VStack(spacing: size == .large ? 8 : 4) {
            InformationIconView(
                iconName: information.iconName,
                size: size.iconSize,
                color: definition.color
            )

            if size.showsName {
                Text(information.name)
                    .font(size.nameFont)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            if size.showsLevelName {
                LevelIndicator(
                    level: information.level,
                    levelName: information.levelName,
                    style: .badge,
                    font: size.levelNameFont
                )
            } else {
                // レベル名を出さないサイズでは、色の帯で状態を示す
                Capsule()
                    .fill(definition.color)
                    .frame(width: size.side * 0.42, height: 5)
            }
        }
        .padding(size == .large ? 12 : 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background, in: RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                .strokeBorder(definition.color, lineWidth: size == .large ? 3 : 2)
        }
    }
}

#Preview("サイズ別") {
    let electricity = Information(name: "電気", iconName: "bolt.fill", level: 1, position: .single)

    return VStack(spacing: 24) {
        HStack(alignment: .bottom, spacing: 20) {
            SingleInformationIndicator(information: electricity, size: .small)
            SingleInformationIndicator(information: electricity, size: .medium)
            SingleInformationIndicator(information: electricity, size: .large)
        }
        Text("small / medium / large").font(.caption).foregroundStyle(.secondary)
    }
    .padding()
}

#Preview("レベル別") {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            ForEach(LevelPalette.definitions) { definition in
                SingleInformationIndicator(
                    information: Information(
                        name: "電気",
                        iconName: "bolt.fill",
                        level: definition.level,
                        position: .single
                    ),
                    size: .small
                )
            }
        }
        HStack(spacing: 12) {
            ForEach(LevelPalette.definitions) { definition in
                SingleInformationIndicator(
                    information: Information(
                        name: "電気",
                        iconName: "bolt.fill",
                        level: definition.level,
                        position: .single
                    ),
                    size: .medium
                )
            }
        }
    }
    .padding()
}
