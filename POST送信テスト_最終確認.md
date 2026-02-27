# POST送信テスト 最終確認手順

**目的**: GAS（頭脳）が正しく動作することを確認し、Mac作業を「箱（iOS）に入れて動かすだけ」にする

---

## ✅ 確認項目チェックリスト

### 1. GASが受け取る ✅
- [ ] POSTリクエストが正常に受け取られる
- [ ] エラーレスポンスが返らない

### 2. DB（Sheets）に正しく書き込み ✅
- [ ] `Daily_Log` シートにデータが追加される
- [ ] `Daily_Output` シートに計算結果が追加される
- [ ] `Drivers_Long` シートにTopDriversが追加される
- [ ] `Coping_Long` シートにCoping3が追加される
- [ ] `Reboot_Log` シートにReboot状態が記録される（該当時）

### 3. NetStage/Danger/TopDrivers/Coping3/Rebootを返す ✅
- [ ] `net_stage` が正しく計算されている（-5〜+5）
- [ ] `danger` が正しく計算されている（0〜5）
- [ ] `risk_color` が正しく設定されている
- [ ] `subj_stage` と `obj_stage` が正しく計算されている
- [ ] `top_drivers` が3つ返ってくる（空でない）
- [ ] `coping3` が3つ返ってくる（CrisisPlan_Sourceから正しく抽出）
- [ ] `reboot` 状態が正しく返ってくる

### 4. LINE通知（毎日＋Orange以上）も狙い通り出る ✅
- [ ] `line_message` が生成されている（10〜15行）
- [ ] `line_send_immediate` が正しく設定されている（Orange以上でtrue）
- [ ] LINE Notify APIで実際に送信できる（アプリ側で実装）

---

## 🧪 テストケース

### テストケース1: 通常の入力（正常系）

**目的**: 基本的な機能が動作することを確認

**送信データ**:
```json
{
  "date": "2025-12-22",
  "mood_score": -2,
  "journal_text": "今日は少し疲れました。仕事は順調でした。",
  "meds_am_taken": true,
  "meds_pm_taken": true,
  "q_mood_stage": -2,
  "q_thinking_stage": -1,
  "q_body_stage": 0,
  "q_behavior_stage": -1,
  "q4_status": "answered",
  "steps": 5000,
  "intake_energy_kcal": 2000
}
```

**期待される結果**:
- ✅ `ok: true`
- ✅ `net_stage`: -2〜0の範囲
- ✅ `danger`: 0〜2の範囲
- ✅ `top_drivers`: 3つ、すべて `description` が空でない
- ✅ `coping3`: 3つ、すべて `text` が空でない（CrisisPlan_Sourceから抽出）
- ✅ `line_message`: 10〜15行のメッセージ
- ✅ `line_send_immediate`: false（Danger < 3の場合）

**確認方法**:
1. https://reqbin.com/ でPOST送信
2. レスポンスを確認
3. スプレッドシートの各シートを確認

---

### テストケース2: Orange以上（危険度が高い）

**目的**: Orange以上で即時LINE通知が設定されることを確認

**送信データ**:
```json
{
  "date": "2025-12-22",
  "mood_score": 3,
  "journal_text": "今日はとても調子がいい。何でもできる気がする。",
  "meds_am_taken": false,
  "meds_pm_taken": false,
  "q_mood_stage": 3,
  "q_thinking_stage": 2,
  "q_body_stage": 2,
  "q_behavior_stage": 3,
  "q4_status": "answered",
  "steps": 15000,
  "intake_energy_kcal": 800,
  "alcohol_drinks": 2
}
```

**期待される結果**:
- ✅ `danger`: 3以上
- ✅ `risk_color`: "Orange" または "Red" または "DarkRed"
- ✅ `line_send_immediate`: true
- ✅ `top_drivers`: 1位はDanger側の要因（例：飲酒、服薬忘れ）
- ✅ `coping3`: Danger主因Domainから抽出

**確認方法**:
1. POST送信
2. `line_send_immediate` が `true` であることを確認
3. `top_drivers` の1位がDanger側であることを確認

---

### テストケース3: Rebootが必要な状態

**目的**: Reboot状態が正しく判定されることを確認

**前提条件**:
- 過去4日以上チェックインがない状態をシミュレート
- または、`missing_checkin_streak_days >= 4` の状態

**送信データ**:
```json
{
  "date": "2025-12-22",
  "mood_score": -3,
  "journal_text": "",
  "meds_am_taken": true,
  "meds_pm_taken": true,
  "q_mood_stage": 0,
  "q_thinking_stage": 0,
  "q_body_stage": 0,
  "q_behavior_stage": 0,
  "q4_status": "unable"
}
```

**期待される結果**:
- ✅ `reboot.reboot_needed`: true
- ✅ `reboot.reboot_level`: "L1" または "L2" または "L3"
- ✅ `reboot.reboot_step`: "Reset" または "Reframe" または "Reconnect"
- ✅ `danger`: 3以上（Missingnessによる）

**確認方法**:
1. POST送信
2. `reboot.reboot_needed` が `true` であることを確認
3. `Reboot_Log` シートに記録されていることを確認

---

### テストケース4: Coping3が正しく抽出される

**目的**: CrisisPlan_Sourceから正しくCoping3が抽出されることを確認

**送信データ**:
```json
{
  "date": "2025-12-22",
  "mood_score": -3,
  "journal_text": "今日はとてもつらい。何もしたくない。",
  "meds_am_taken": true,
  "meds_pm_taken": true,
  "q_mood_stage": -3,
  "q_thinking_stage": -2,
  "q_body_stage": -2,
  "q_behavior_stage": -2,
  "q4_status": "answered",
  "steps": 2000,
  "intake_energy_kcal": 1500
}
```

**期待される結果**:
- ✅ `coping3`: 3つ、すべて `text` が空でない
- ✅ `coping3[0].domain`: CrisisPlan_Sourceの項目名（例：「睡眠」「共通」）
- ✅ `coping3[0].text`: CrisisPlan_Sourceから抽出されたテキスト（矢印「←」「→」が含まれていない）
- ✅ `_debug_coping` が返ってくる場合、`foundCount: 3` であること

**確認方法**:
1. POST送信
2. `coping3` の各要素を確認
3. スプレッドシートの `CrisisPlan_Source` シートと照合
4. `Coping_Long` シートに記録されていることを確認

---

## 🚀 テスト実行手順

### ステップ1: テストツールを準備

**推奨**: https://reqbin.com/ を使用

1. ブラウザで https://reqbin.com/ を開く
2. Method: `POST` を選択
3. URL欄に以下を入力：
   ```
   https://script.google.com/macros/s/AKfycbwhfOswhC5kqt9C3kKU9CLcURie81ROL35pZD0UQgf0QvYKeWRNyEP7m4Y5RF8EQw1V/exec
   ```
4. Content-Type: `application/json` を選択

### ステップ2: テストケース1を実行

1. Body欄にテストケース1のJSONを貼り付け
2. 「Send」ボタンをクリック
3. レスポンスを確認
4. チェックリストに従って確認

### ステップ3: スプレッドシートを確認

1. Googleスプレッドシートを開く
2. 以下のシートを確認：
   - `Daily_Log`: 最新行にデータが追加されているか
   - `Daily_Output`: 最新行に計算結果が追加されているか
   - `Drivers_Long`: TopDriversが記録されているか
   - `Coping_Long`: Coping3が記録されているか

### ステップ4: テストケース2〜4を実行

同様の手順で、テストケース2〜4を実行

---

## 📊 確認結果の記録

### テストケース1: 通常の入力

- [ ] GASが受け取った: ✅ / ❌
- [ ] DBに書き込まれた: ✅ / ❌
- [ ] NetStage/Dangerが返ってきた: ✅ / ❌
- [ ] TopDriversが3つ返ってきた: ✅ / ❌
- [ ] Coping3が3つ返ってきた: ✅ / ❌
- [ ] LINEメッセージが生成された: ✅ / ❌
- [ ] 問題点: ________________

### テストケース2: Orange以上

- [ ] Danger >= 3: ✅ / ❌
- [ ] line_send_immediate = true: ✅ / ❌
- [ ] TopDriversの1位がDanger側: ✅ / ❌
- [ ] 問題点: ________________

### テストケース3: Reboot

- [ ] reboot_needed = true: ✅ / ❌
- [ ] reboot_levelが設定されている: ✅ / ❌
- [ ] Reboot_Logに記録された: ✅ / ❌
- [ ] 問題点: ________________

### テストケース4: Coping3

- [ ] Coping3が3つ返ってきた: ✅ / ❌
- [ ] CrisisPlan_Sourceから正しく抽出: ✅ / ❌
- [ ] 矢印が含まれていない: ✅ / ❌
- [ ] 問題点: ________________

---

## ⚠️ よくある問題と対処法

### 問題1: Coping3が空またはデフォルト値

**原因**: CrisisPlan_Sourceシートの読み取りエラー

**対処法**:
1. `_debug_coping` フィールドを確認
2. `sheetFound` が `true` か確認
3. `stageCols` が正しく検出されているか確認
4. CrisisPlan_Sourceシートのヘッダー行を確認（「-5(激鬱) デスゾーン」など）

### 問題2: TopDriversが空

**原因**: 計算結果が正しく生成されていない

**対処法**:
1. `net_stage` と `danger` が正しく計算されているか確認
2. `top_drivers` の生成ロジックを確認

### 問題3: LINEメッセージが生成されない

**原因**: `_generateLineMessage` 関数のエラー

**対処法**:
1. GASエディタのログを確認
2. `line_message` フィールドが空でないか確認

### 問題4: Rebootが正しく判定されない

**原因**: `_checkRebootStatus` 関数のロジックエラー

**対処法**:
1. `last_checkin_date` と `last_journal_date` を確認
2. `missing_checkin_streak_days` と `missing_journal_streak_days` を確認

---

## ✅ 完了条件

すべてのテストケースで以下が確認できれば完了：

1. ✅ GASが受け取る
2. ✅ DB（Sheets）に正しく書き込み
3. ✅ NetStage/Danger/TopDrivers/Coping3/Rebootを返す
4. ✅ LINE通知（毎日＋Orange以上）も狙い通り出る

**これがOKなら、Mac作業は「箱（iOS）に入れて動かすだけ」になります！**

---

## 📝 次のステップ

テストが完了したら：

1. 問題があれば修正
2. 再度テスト
3. すべてOKなら、Mac環境でiOSアプリのビルドに進む

