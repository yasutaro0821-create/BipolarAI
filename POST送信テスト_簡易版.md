# POST送信テスト 簡易版（5分で確認）

**目的**: GASが正しく動作するか、最小限の確認

---

## 🚀 手順（5分）

### 1. テストツールを開く

https://reqbin.com/ を開く

### 2. 設定

- **Method**: `POST`
- **URL**: 
  ```
  https://script.google.com/macros/s/AKfycbwhfOswhC5kqt9C3kKU9CLcURie81ROL35pZD0UQgf0QvYKeWRNyEP7m4Y5RF8EQw1V/exec
  ```
- **Content-Type**: `application/json`
- **Body**: 以下を貼り付け

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

### 3. 送信

「Send」ボタンをクリック

### 4. 確認（30秒）

レスポンスで以下を確認：

- ✅ `"ok": true` が返ってくる
- ✅ `"net_stage"` が -5〜+5 の範囲
- ✅ `"danger"` が 0〜5 の範囲
- ✅ `"top_drivers"` が3つ返ってくる（`description` が空でない）
- ✅ `"coping3"` が3つ返ってくる（`text` が空でない）
- ✅ `"line_message"` が生成されている

### 5. スプレッドシート確認（1分）

Googleスプレッドシートを開いて確認：

- ✅ `Daily_Log` シートの最新行にデータが追加されている
- ✅ `Daily_Output` シートの最新行に計算結果が追加されている

---

## ✅ 完了条件

上記すべてが確認できれば、**GAS（頭脳）は正常に動作しています！**

Mac作業は「箱（iOS）に入れて動かすだけ」になります。

---

## ⚠️ 問題があった場合

詳細は `POST送信テスト_最終確認.md` を参照してください。

