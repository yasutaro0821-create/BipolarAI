# 双極AI iOSアプリ開発ガイド

## 前提条件

iOSアプリの開発には、**macOS環境とXcode**が必要です。

### 必要な環境

1. **macOS**（MacBook、iMac、Mac miniなど）
2. **Xcode**（最新版推奨）
3. **Apple Developerアカウント**（実機テスト用、無料でも可）

### Windows環境での開発

WindowsではXcodeが使えないため、以下のいずれかの方法が必要です：

1. **Macを用意する**（推奨）
2. **クラウドMacサービス**（MacStadium、AWS Mac instancesなど）
3. **仮想マシン**（macOSのライセンス要件に注意）

## プロジェクト作成手順

### 1. Xcodeでプロジェクトを作成

1. Xcodeを起動
2. 「Create a new Xcode project」を選択
3. 「iOS」→「App」を選択
4. 以下の設定を入力：
   - **Product Name**: `BipolarAI`
   - **Interface**: `SwiftUI`
   - **Language**: `Swift`
   - **Storage**: `None`（後で追加）
5. 保存場所を選択（例：`~/Documents/BipolarAI`）

### 2. プロジェクト構造

```
BipolarAI/
├── BipolarAIApp.swift          # アプリのエントリーポイント
├── ContentView.swift            # メイン画面
├── Models/
│   ├── DailyLog.swift          # 日次ログデータモデル
│   └── CalculationResult.swift  # 計算結果データモデル
├── Views/
│   ├── InputView.swift         # 入力画面（Mood + 定型質問）
│   ├── ResultView.swift        # 結果表示画面
│   └── Components/
│       └── StageButton.swift   # ステージボタンコンポーネント
├── Services/
│   └── GASService.swift        # GAS API通信サービス
└── Utils/
    └── Constants.swift         # 定数（API URLなど）
```

## 次のステップ

プロジェクトを作成したら、以下のファイルを順番に実装します：

1. **Models**（データモデル）
2. **Services**（GAS API通信）
3. **Views**（UI画面）
4. **App**（エントリーポイント）

## 注意事項

- Windows環境では、コードの準備とレビューは可能ですが、実際のビルドとテストにはmacOSが必要です
- プロジェクトを作成したら、プロジェクトのパスを共有してください

