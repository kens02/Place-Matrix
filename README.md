# Place Matrix

地図上の場所に紐づく情報を登録し、その状態を **一目で** 把握できる iPhone アプリです。

場所（Place）に対して複数の情報（Information）を登録し、
**単一情報インジケータ** または **4分割インジケータ** として地図上に可視化します。

```
単一情報表示                4分割インジケータ
┌──────────┐              ┌────────┬────────┐
│    ⚡    │              │ 💧 水道│ 📡 通信│
│   電気   │              │   🟢   │   🟠   │
│   🟢    │              ├────────┼────────┤
│   正常   │              │ ⚡ 電気│ 🔥 ガス│
└──────────┘              │   🟡   │   🔴   │
                          └────────┴────────┘
```

## 特徴

- **色だけに依存しない UI** — ピクトグラム + 名称 + レベル名称 + 色 の4要素で状態を伝えます
- **4分割は固定フィールドではない** — 4つの Information を表示位置（topLeft / topRight / bottomLeft / bottomRight）を指定して配置します
- **Template** で「どの4情報を表示するか」を管理します（Infrastructure / Disaster / Medical / Traffic）
- **オフライン完結** — SQLite にローカル保存し、アプリ再起動後もデータが残ります

## 状態レベル

色は情報の意味ではなく「状態レベル」を表します。

| Level | 名称 | 色 |
|------:|------|-----|
| 0 | 不明 | gray |
| 1 | 正常 | green |
| 2 | 注意 | yellow |
| 3 | 警戒 | orange |
| 4 | 危険 | red |

## 技術構成

- Swift / SwiftUI
- MapKit（MVP では Apple Map のみ）
- Core Location
- SQLite（`import SQLite3` を直接使用）
- **外部ライブラリ不使用** — Apple 標準 API を優先

### 動作環境

- Xcode 26.x
- iOS 26.5 以上

## アーキテクチャ

View から DB を直接操作せず、必ず Repository を経由します。

```
View  →  AppStore  →  Repository  →  SQLiteManager  →  SQLite
```

```
Place-Matrix/
  Models/         Place / Information / Template / LevelPalette
  Database/       SQLiteManager
  Repositories/   Place / Information / Template
  Services/       LocationService / AppStore
  Components/     SingleInformationIndicator / FourQuadrantIndicator など
  Views/          Map / List / Detail / Edit
```

表示ロジックは `Components/` に集約し、MapView と詳細画面で重複実装しません。

## ビルド

```bash
xcodebuild -project Place-Matrix.xcodeproj \
           -scheme Place-Matrix \
           -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
           build
```

Xcode で開く場合は `Place-Matrix.xcodeproj` をそのまま開いてください。

> `xcode-select` がコマンドラインツールを指している環境では、
> 先頭に `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` を付けて実行してください。

## 仕様書

詳細な仕様は [docs/仕様書.txt](docs/仕様書.txt) を参照してください。

## 使い方

1. **地図**タブで地図をタップ → 「次へ」で場所の登録画面が開きます
2. 名称を入力し、**Template**（Infrastructure / Disaster / Medical / Traffic）を選んで保存すると、
   その4つの情報が「不明」の状態で作られます
3. 場所をタップして詳細を開き、各情報の**レベル・レベル名称・メモ・ピクトグラム**を設定します
4. 設定した状態は地図上のインジケータに即座に反映されます
5. **一覧**タブでは名称・カテゴリによる検索と、スワイプでの削除ができます

表示方法は場所ごとに **4分割** と **単一情報** を切り替えられます。

## MVP の達成状況

仕様書 §18 のゴールをすべて満たしています。

| # | ゴール | 状態 |
|---|---|:--:|
| 1 | 地図上で現在地を取得できる | ✅ |
| 2 | 場所を登録できる | ✅ |
| 3 | Place に Template を設定できる | ✅ |
| 4 | Template に応じて Information を4つ登録できる | ✅ |
| 5 | ピクトグラム / Level / LevelName / Memo を設定できる | ✅ |
| 6 | Place を地図上に表示できる | ✅ |
| 7 | 4分割インジケータで icon + 色 を表示できる | ✅ |
| 8 | 単一 Information を SingleInformationIndicator で表示できる | ✅ |
| 9 | Place をタップすると詳細を表示できる | ✅ |
| 10 | SQLite に保存され、アプリ再起動後もデータが残る | ✅ |
| 11 | データを編集・削除できる | ✅ |
| 12 | 基本的な検索・一覧表示ができる | ✅ |

## 開発の進め方

小さな単位で実装し、各段階でビルドとシミュレータ実機での動作確認を行いました。

- [x] Phase 0 — Git / GitHub 基盤
- [x] Phase 1 — Models + レベル定義
- [x] Phase 2 — SQLiteManager
- [x] Phase 3 — Repositories + AppStore
- [x] Phase 4 — 表示コンポーネント
- [x] Phase 5 — 地図 + 現在地
- [x] Phase 6 — 一覧・詳細
- [x] Phase 7 — 編集（CRUD）
- [x] Phase 8 — E2E 検証

## 今後の検討事項

Google Maps / 写真 / CSV / JSON / クラウド同期 / iCloud / 複数 Template / カスタムアイコン / 菱形表示 / 色設定のカスタマイズ
