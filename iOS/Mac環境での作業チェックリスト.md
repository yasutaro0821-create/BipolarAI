# Mac環境での作業チェックリスト

クラウドMacを時間課金で使用する際の、効率的な作業手順です。

## 事前準備（Windows環境で完了）

### ✅ コードの準備（完了）

- [x] フェーズA：基本機能のコード
- [x] フェーズB：HealthKit連携コード（基本構造）
- [x] フェーズC：LINE Notify APIコード
- [x] フェーズD：Reboot UIコード
- [x] ドキュメント整備

## Mac環境での作業手順

### ステップ1: Xcodeプロジェクトを作成（5分）

1. Xcodeを起動
2. 「Create a new Xcode project」を選択
3. プロジェクト名：`BipolarAI`
4. Interface：`SwiftUI`を選択
5. 保存場所を選択

### ステップ2: コードをコピー（10分）

1. `C:\Users\yasut\BipolarAI\iOS\` フォルダをMacに転送
   - クラウドストレージ（iCloud、Google Driveなど）を使用
   - または、GitHub/GitLabにプッシュしてMacでクローン

2. Xcodeプロジェクトにファイルを追加
   - プロジェクトナビゲーターで右クリック → 「Add Files to "BipolarAI"...」
   - `iOS` フォルダを選択
   - 「Copy items if needed」にチェック
   - 「Create groups」を選択
   - 「Add」をクリック

### ステップ3: 設定（5分）

1. **Info.plistにHealthKit権限を追加**
   - プロジェクトナビゲーターで `Info.plist` を選択
   - 以下のキーを追加：
     ```xml
     <key>NSHealthShareUsageDescription</key>
     <string>健康データを読み取って、双極性障害の状態を分析します</string>
     ```

2. **Signing & CapabilitiesでHealthKitを追加**
   - プロジェクトを選択
   - 「Signing & Capabilities」タブ
   - 「+ Capability」をクリック
   - 「HealthKit」を追加

3. **GASエンドポイントURLを更新**
   - `Utils/Constants.swift` を開く
   - `GAS_ENDPOINT_URL` を最新のデプロイURLに更新

### ステップ4: ビルドとテスト（10分）

1. シミュレーターを選択（iPhone 15など）
2. 「Run」ボタンをクリック（⌘R）
3. ビルドエラーを確認・修正
4. アプリが起動したら、入力画面でテスト

### ステップ5: HealthKitServiceの実装（30分）

`Services/HealthKitService.swift` の各メソッドを実装：

- [ ] `fetchStepCount` の実装
- [ ] `fetchActiveEnergy` の実装
- [ ] `fetchDietaryEnergy` の実装
- [ ] `fetchSleepData` の実装
- [ ] `fetchMindfulSession` の実装
- [ ] `fetchAlcoholicBeverages` の実装（利用可能な場合）
- [ ] `fetchLatestWeight` の実装

詳細は `HealthKit実装詳細.md` を参照

### ステップ6: 実機テスト（20分）

1. iPhoneをMacに接続
2. Xcodeで実機を選択
3. 「Run」ボタンをクリック
4. HealthKitのアクセス許可を確認
5. 各機能をテスト

### ステップ7: エラー修正と改善（必要に応じて）

- ビルドエラーの修正
- 動作確認とバグ修正
- UIの改善

## 時間の目安

- **最小限の動作確認**: 約30分
- **HealthKit実装込み**: 約1時間
- **完全なテスト**: 約1.5時間

## 効率的な進め方

1. **まずはフェーズAだけ動作確認**（30分）
   - HealthKitは後回し
   - 基本的な入力→送信→結果表示が動けばOK

2. **HealthKitは後で実装**（別セッション）
   - フェーズAが動いてから
   - 実機が必要なので、まとめて実装

3. **LINE通知とRebootは最後**（別セッション）
   - 基本機能が動いてから
   - 設定画面でトークン入力してテスト

## 注意事項

- **HealthKitは実機でのみ動作**（シミュレーターでは動作しません）
- **GASエンドポイントURLは最新のものに更新**（デプロイするたびに変わる可能性）
- **ビルドエラーは順番に修正**（依存関係を確認）

## 次のセッションでやること

1. HealthKitServiceの実装を完成
2. 実機でのテスト
3. LINE通知のテスト
4. Reboot UIのテスト

---

**このチェックリストに従って進めれば、効率的に作業できます！**

