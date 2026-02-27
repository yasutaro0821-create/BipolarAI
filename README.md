# 双極AI プロジェクト

双極性障害のセルフマネジメントツール

---

## 📋 目次

1. [プロジェクト概要](#プロジェクト概要)
2. [設定情報](#設定情報)
3. [セットアップ手順](#セットアップ手順)
4. [ファイル構成](#ファイル構成)
5. [仕様書](#仕様書)

---

## プロジェクト概要

### 何をするシステムか

双極性障害Ⅱ型のセルフマネジメントを支援するiOSアプリ＋クラウドシステムです。

- **iOSアプリ（SwiftUI）**: 日次のMood入力、HealthKit連携、位置情報取得
- **Google Apps Script（GAS）**: Thinking判定（OpenAI）、NetStage/Danger計算、Coping3生成
- **Google Sheets**: データ保存、CrisisPlan参照

### 技術スタック

- **iOS**: SwiftUI、HealthKit、CoreLocation
- **クラウド**: Google Apps Script（WebApp）
- **AI**: OpenAI（Thinking解析のみ）
- **DB**: Google Sheets

---

## 設定情報

### 設定ファイル

機密情報は `config.json` に保存されています（`.gitignore`に追加済み）。

- **OpenAI APIキー**: 設定済み
- **GoogleスプレッドシートID**: `1Dk4MK5ITmAimxFhnY1Ji-qxw7qx2BIgxDni03aL269k`
- **Google Apps ScriptスクリプトID**: `1CQCYu6NIh_6AODKesZQL3Ng6nz4BtFZU5lyEmGP84a7f2EYpkt4dSk0S`

### スプレッドシート

[双極AI DBテンプレート Vol.8](https://docs.google.com/spreadsheets/d/1Dk4MK5ITmAimxFhnY1Ji-qxw7qx2BIgxDni03aL269k/edit?gid=2018717524#gid=2018717524)

---

## セットアップ手順

### claspを使う方法（推奨）

**非エンジニア向けの詳細手順**：`claspセットアップ手順.md` を参照してください。

claspを使うと、パソコンからGASコードを管理できます。

**簡単な手順**：
1. Node.jsをインストール（[nodejs.org](https://nodejs.org/ja/)）
2. claspをインストール：`npm install -g @google/clasp`
3. ログイン：`clasp login`
4. 既存プロジェクトに接続：`clasp clone 1CQCYu6NIh_6AODKesZQL3Ng6nz4BtFZU5lyEmGP84a7f2EYpkt4dSk0S`
5. コードをアップロード：`clasp push`

詳細は `claspセットアップ手順.md` を参照してください。

### GASエディタを使う方法

詳細は `セットアップ手順.md` を参照してください。

**重要**: OpenAI APIキーはGAS側のスクリプトプロパティに設定する必要があります。

### クイックスタート

1. **GASプロジェクトの作成**
   - [Google Apps Script](https://script.google.com/) で新規プロジェクト作成
   - `gas_code.gs` の内容をコピー＆ペースト

2. **OpenAI APIキーの設定**
   - GASエディタで「プロジェクトの設定」→「スクリプト プロパティ」
   - プロパティ: `OPENAI_API_KEY`
   - 値: `config.json` に記載のAPIキー

3. **Webアプリとしてデプロイ**
   - 「デプロイ」→「新しいデプロイ」→「ウェブアプリ」
   - WebアプリのURLをコピー（iOSアプリ側で使用）

---

## ファイル構成

```
C:\Users\yasut\BipolarAI\
├── README.md              ← このファイル
├── config.json           ← 設定情報（機密）
├── gas_code.gs           ← GASコード
├── appsscript.json       ← clasp設定ファイル
├── セットアップ手順.md     ← セットアップ手順（GASエディタ用）
├── claspセットアップ手順.md ← claspセットアップ手順（非エンジニア向け）
├── 開発フロー.md          ← 開発の順番（最短で完成させる王道）
├── スプレッドシート構造.md  ← スプレッドシートの構造ドキュメント
└── 仕様書.md             ← 完全仕様書（Vol.8）
```

### 各ファイルの役割

| ファイル | 役割 |
|---------|------|
| `config.json` | OpenAI APIキー、スプレッドシートID、GASスクリプトID |
| `gas_code.gs` | GAS側のコード（OpenAI呼び出し、NetStage/Danger計算） |
| `appsscript.json` | clasp用の設定ファイル |
| `セットアップ手順.md` | GAS設定、デプロイ手順（GASエディタ用） |
| `claspセットアップ手順.md` | claspのセットアップ手順（非エンジニア向け・推奨） |
| `開発フロー.md` | 開発の順番（最短で完成させる王道） |
| `スプレッドシート構造.md` | スプレッドシートの構造ドキュメント |
| `仕様書.md` | 完全仕様書（実装用） |

---

## 仕様書

完全仕様書は `仕様書.md` を参照してください。

### 主要機能

1. **NetStage（-5..+5）**: 状態の方向（躁寄り/鬱寄り）と強さ
2. **Danger（0..5）**: 方向を問わない「危険度」（介入優先度）
3. **TopDrivers**: なぜそう判定したか（寄与が大きい上位3要因）
4. **Coping3**: クライシスプランから抽出する推奨アクション3つ
5. **Reboot Program**: ログ中断が続いたときの段階的介入（最大90日）

### 実装が必要な関数

GASコード（`gas_code.gs`）で実装が必要な関数：

- `_calculateNetStageAndDanger()` - NetStage/Danger計算（仕様書 10.2, 10.3）
- `_extractTopDrivers()` - TopDrivers抽出（仕様書 11）
- `_extractCoping3()` - Coping3抽出（仕様書 12）
- `_checkRebootStatus()` - Reboot判定（仕様書 14）

---

## 開発フロー

**最短で完成させる王道の順番**：`開発フロー.md` を参照してください。

### フェーズA：骨格完成（最優先）

1. **アプリで Mood + 定型4本 を入力できる**
2. **アプリがサーバーに送る**
3. **サーバーが NetStage/Danger を計算して返す**（✅ 実装済み）
4. **サーバーが Google Sheets に保存**（✅ 実装済み）
5. **アプリが結果を表示**

→ ここまで動けば「骨格完成」です。UIはまだ粗くていい。

### フェーズB：HealthKit連携

- 歩数、摂取kcal、マインドフルネス、飲酒など
- Sleepは「取れた日だけ」使う

### フェーズC：LINE通知

- 入力送信直後に10〜15行LINEを送る
- Orange以上は即時で追加LINE

### フェーズD：Reboot通知

- 4日欠測でReboot開始
- アプリ通知に最小行動ボタン

詳細は `開発フロー.md` を参照してください。

## 次のステップ

1. **GASコードをアップロード**
   ```powershell
   cd C:\Users\yasut\BipolarAI_clasp
   clasp push
   ```

2. **フェーズAの実装開始（iOSアプリ）**
   - Mood入力UI
   - 定型質問4本入力UI
   - GASエンドポイントへのPOST送信
   - 結果表示UI

---

## トラブルシューティング

### OpenAI APIキーが取得できない

- スクリプトプロパティに正しく設定されているか確認
- GASエディタで「表示」→「ログ」でエラーを確認

### スプレッドシートが見つからない

- スプレッドシートIDが正しいか確認
- GASプロジェクトと同じGoogleアカウントでスプレッドシートにアクセスできるか確認

### Webアプリが動作しない

- デプロイが正しく完了しているか確認
- アクセス権限が正しく設定されているか確認

---

**何か分からないことがあれば、`仕様書.md` を参照してください！**

