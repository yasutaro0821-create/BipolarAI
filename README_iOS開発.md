# 双極AI iOSアプリ開発

## 現在の状況

- ✅ GAS側の実装完了
- ✅ デプロイスクリプト完成
- ⏳ iOSアプリの実装（これから）

## 開発環境

iOSアプリの開発には、**macOS環境とXcode**が必要です。

### Windows環境の場合

WindowsではXcodeが使えないため、以下のいずれかが必要です：

1. **Macを用意する**（推奨）
2. **クラウドMacサービス**を使用
3. **仮想マシン**（macOSのライセンス要件に注意）

## プロジェクト作成

詳細は `iOS_プロジェクト作成手順.md` を参照してください。

## 実装順序（フェーズA）

1. **データモデル**（Models）
   - DailyLog.swift
   - CalculationResult.swift

2. **API通信**（Services）
   - GASService.swift

3. **UI画面**（Views）
   - InputView.swift（Mood + 定型質問4本）
   - ResultView.swift（結果表示）

4. **アプリ統合**（App）
   - BipolarAIApp.swift
   - ContentView.swift

## 次のアクション

1. Mac環境を用意する
2. Xcodeでプロジェクトを作成する
3. プロジェクトの場所を共有する
4. コードの実装を開始する

