//
//  LevelIndicator.swift
//  Place-Matrix
//
//  状態レベルの表示。
//

import SwiftUI

/// 状態レベルを「色 + レベル名称」で表す。
///
/// 色だけで意味を判断させないため、既定では名称も一緒に表示する（仕様書 §15）。
struct LevelIndicator: View {

    enum Style {
        /// 丸い色点とレベル名称
        case dot
        /// 色で塗ったバッジ
        case badge
    }

    let level: Int
    /// ユーザーが独自に付けた名称。空ならレベルの既定名を使う。
    var levelName: String = ""
    var style: Style = .dot
    var font: Font = .caption

    private var definition: LevelDefinition {
        LevelPalette.definition(for: level)
    }

    private var displayName: String {
        levelName.trimmingCharacters(in: .whitespaces).isEmpty ? definition.name : levelName
    }

    var body: some View {
        switch style {
        case .dot:
            HStack(spacing: 5) {
                Circle()
                    .fill(definition.color)
                    .frame(width: 10, height: 10)
                Text(displayName)
                    .font(font)
                    .foregroundStyle(.primary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(displayName)

        case .badge:
            Text(displayName)
                .font(font)
                .fontWeight(.semibold)
                .foregroundStyle(definition.foreground)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(definition.color, in: Capsule())
                .accessibilityLabel(displayName)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 20) {
        ForEach(LevelPalette.definitions) { definition in
            HStack(spacing: 20) {
                LevelIndicator(level: definition.level, style: .dot)
                LevelIndicator(level: definition.level, style: .badge)
            }
        }
        Divider()
        LevelIndicator(level: 3, levelName: "要注意", style: .badge)
    }
    .padding()
}
