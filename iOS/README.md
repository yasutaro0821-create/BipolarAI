# 双極AI iOSアプリ コード

## ファイル構成

```
iOS/
├── Models/
│   ├── DailyLog.swift              # 日次ログデータモデル
│   └── CalculationResult.swift     # 計算結果データモデル
├── Services/
│   └── GASService.swift            # GAS API通信サービス
├── Views/
│   ├── InputView.swift             # 入力画面（Mood + 定型質問4本）
│   ├── ResultView.swift            # 結果表示画面
│   └── Components/
│       └── StageButton.swift      # ステージ選択ボタン
├── Utils/
│   └── Constants.swift             # 定数（API URLなど）
├── BipolarAIApp.swift              # アプリエントリーポイント
└── ContentView.swift               # メイン画面
```

## 実装状況

### ✅ 完了済み（フェーズA）

- [x] データモデル（DailyLog, CalculationResult）
- [x] GAS API通信サービス
- [x] 入力画面（Mood + 定型質問4本）
- [x] 結果表示画面
- [x] アプリ統合

## 次のステップ

### 1. Xcodeプロジェクトを作成

Mac環境でXcodeを起動し、以下の手順でプロジェクトを作成：

1. 「Create a new Xcode project」を選択
2. 「iOS」→「App」を選択
3. プロジェクト名：`BipolarAI`
4. Interface：`SwiftUI`を選択
5. Language：`Swift`を選択
6. 保存場所を選択

### 2. コードをコピー

作成したプロジェクトに、このフォルダ内のSwiftファイルをコピー：

1. `Models/` フォルダ内のファイルをXcodeプロジェクトの `Models/` フォルダにコピー
2. `Services/` フォルダ内のファイルをXcodeプロジェクトの `Services/` フォルダにコピー
3. `Views/` フォルダ内のファイルをXcodeプロジェクトの `Views/` フォルダにコピー
4. `Utils/` フォルダ内のファイルをXcodeプロジェクトの `Utils/` フォルダにコピー
5. `BipolarAIApp.swift` と `ContentView.swift` をプロジェクトのルートにコピー

### 3. GASエンドポイントURLを更新

`Utils/Constants.swift` の `GAS_ENDPOINT_URL` を最新のデプロイURLに更新：

```swift
static let GAS_ENDPOINT_URL = "https://script.google.com/macros/s/YOUR_DEPLOYMENT_ID/exec"
```

確認方法：
- GASエディタ → デプロイ → 管理 → アクティブなデプロイ → URLをコピー

### 4. ビルドとテスト

1. Xcodeでプロジェクトを開く
2. シミュレーターまたは実機を選択
3. 「Run」ボタンをクリック（⌘R）
4. アプリが起動したら、入力画面でデータを入力して送信
5. 結果画面が表示されることを確認

## 注意事項

### GASエンドポイントURL

- デプロイするたびにURLが変わる可能性があります
- 最新のURLを `Constants.swift` に設定してください

### エラーハンドリング

- ネットワークエラーやサーバーエラーは、入力画面にエラーメッセージとして表示されます
- エラーが発生した場合は、GASエンドポイントが正しく動作しているか確認してください

## フェーズB以降

フェーズAが動作確認できたら、以下を実装：

- フェーズB：HealthKit連携
- フェーズC：LINE Notify API連携
- フェーズD：Reboot通知UI

詳細は `開発フロー.md` を参照してください。

