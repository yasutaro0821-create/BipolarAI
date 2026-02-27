# POST送信テスト 現状確認

## 📋 現在の状況

### ✅ 完了していること

1. **GASコードの実装**: 完了
   - NetStage/Danger計算
   - TopDrivers抽出
   - Coping3抽出（CrisisPlan_Sourceから）
   - Reboot判定
   - LINEメッセージ生成

2. **デプロイ**: 完了
   - Web App URL: `https://script.google.com/macros/s/AKfycbwhfOswhC5kqt9C3kKU9CLcURie81ROL35pZD0UQgf0QvYKeWRNyEP7m4Y5RF8EQw1V/exec`
   - Health Check: ✅ OK

3. **過去のテスト**: 実施済み
   - 以前にPOST送信テストを実施
   - レスポンスが返ってきたことを確認

### ⚠️ 確認が必要なこと

**すべての機能が正しく動作しているかの最終確認が必要です：**

1. ✅ GASが受け取る → **確認済み（過去のテストでOK）**
2. ✅ DB（Sheets）に正しく書き込み → **要確認**
3. ✅ NetStage/Danger/TopDrivers/Coping3/Rebootを返す → **要確認**
4. ✅ LINE通知（毎日＋Orange以上）も狙い通り出る → **要確認**

---

## 🧪 今すぐ確認すべきこと

### 簡易確認（5分）

1. **https://reqbin.com/ を開く**

2. **以下を設定**:
   - Method: `POST`
   - URL: `https://script.google.com/macros/s/AKfycbwhfOswhC5kqt9C3kKU9CLcURie81ROL35pZD0UQgf0QvYKeWRNyEP7m4Y5RF8EQw1V/exec`
   - Content-Type: `application/json`
   - Body:
   ```json
   {
     "date": "2025-12-22",
     "mood_score": -2,
     "journal_text": "今日は少し疲れました。",
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

3. **「Send」をクリック**

4. **レスポンスを確認**:
   - ✅ `"ok": true` が返ってくる
   - ✅ `"net_stage"` が -5〜+5 の範囲
   - ✅ `"danger"` が 0〜5 の範囲
   - ✅ `"top_drivers"` が3つ返ってくる（`description` が空でない）
   - ✅ `"coping3"` が3つ返ってくる（`text` が空でない）
   - ✅ `"line_message"` が生成されている

5. **スプレッドシートを確認**:
   - `Daily_Log` シートの最新行にデータが追加されている
   - `Daily_Output` シートの最新行に計算結果が追加されている

---

## 📝 確認結果の記録

### テスト結果

- [ ] GASが受け取った: ✅ / ❌
- [ ] DBに書き込まれた: ✅ / ❌
- [ ] NetStage/Dangerが返ってきた: ✅ / ❌
- [ ] TopDriversが3つ返ってきた: ✅ / ❌
- [ ] Coping3が3つ返ってきた: ✅ / ❌
- [ ] LINEメッセージが生成された: ✅ / ❌

### 問題点

- ________________
- ________________

---

## 🎯 次のアクション

### すべてOKの場合

✅ **Mac作業は「箱（iOS）に入れて動かすだけ」になります！**

### 問題があった場合

1. 問題点を記録
2. `POST送信テスト_最終確認.md` を参照
3. 必要に応じて修正

---

**今すぐ簡易確認を実行して、結果を教えてください！**

