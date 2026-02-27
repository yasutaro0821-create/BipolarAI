# POST送信テスト手順（非エンジニア向け）

実際のデータでGASエンドポイントをテストする方法です。

---

## 方法1: ブラウザの開発者ツールを使う（最も簡単）

### 手順

1. **ブラウザを開く**
   - ChromeまたはEdgeを開く

2. **開発者ツールを開く**
   - `F12` キーを押す
   - または、右クリック → 「検証」をクリック

3. **Consoleタブを開く**
   - 開発者ツールの上部にある「Console」タブをクリック

4. **以下のコードをコピー＆ペースト**

```javascript
fetch('https://script.google.com/macros/s/AKfycbwhfOswhC5kqt9C3kKU9CLcURie81ROL35pZD0UQgf0QvYKeWRNyEP7m4Y5RF8EQw1V/exec', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    "date": "2025-12-21",
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
  })
})
.then(response => response.json())
.then(data => {
  console.log('成功:', data);
  alert('成功しました！Consoleを確認してください。');
})
.catch(error => {
  console.error('エラー:', error);
  alert('エラーが発生しました。Consoleを確認してください。');
});
```

5. **Enterキーを押す**

6. **結果を確認**
   - Consoleに結果が表示されます
   - 成功した場合は、`{ok: true, net_stage: ..., danger: ..., ...}` のようなJSONが表示されます

---

## 方法2: Postmanを使う（より詳細な確認ができる）

### Postmanのインストール

1. **Postmanをダウンロード**
   - ブラウザで以下を開く：
     ```
     https://www.postman.com/downloads/
     ```
   - 「Download」をクリック
   - インストール

2. **Postmanを起動**

### POST送信の手順

1. **新しいリクエストを作成**
   - 「New」→「HTTP Request」をクリック

2. **URLを入力**
   - メソッドを「POST」に変更
   - URL欄に以下を入力：
     ```
     https://script.google.com/macros/s/AKfycbwhfOswhC5kqt9C3kKU9CLcURie81ROL35pZD0UQgf0QvYKeWRNyEP7m4Y5RF8EQw1V/exec
     ```

3. **Bodyを設定**
   - 「Body」タブをクリック
   - 「raw」を選択
   - 右側のドロップダウンで「JSON」を選択
   - 以下のJSONを貼り付け：

```json
{
  "date": "2025-12-21",
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

4. **Sendボタンをクリック**

5. **結果を確認**
   - 下部にレスポンスが表示されます
   - 成功した場合、`{"ok":true, "net_stage":..., "danger":..., ...}` が表示されます

---

## 方法3: オンラインツールを使う（最も簡単）

### REST Client（オンライン）

1. **ブラウザで以下を開く**
   ```
   https://reqbin.com/
   ```

2. **設定**
   - Method: `POST` を選択
   - URL: 以下を入力
     ```
     https://script.google.com/macros/s/AKfycbwhfOswhC5kqt9C3kKU9CLcURie81ROL35pZD0UQgf0QvYKeWRNyEP7m4Y5RF8EQw1V/exec
     ```
   - Content-Type: `application/json` を選択
   - Body: 以下のJSONを貼り付け

```json
{
  "date": "2025-12-21",
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

3. **Sendボタンをクリック**

4. **結果を確認**
   - 右側にレスポンスが表示されます

---

## 成功した場合のレスポンス例

```json
{
  "ok": true,
  "log_id": 1,
  "output_id": 1,
  "net_stage": -1,
  "danger": 0,
  "risk_color": "Lime",
  "subj_stage": -2,
  "obj_stage": 0,
  "gap": 2,
  "top_drivers": [
    {
      "domain": "gap",
      "contribution": 20,
      "description": "主観（Mood+定型質問）と客観指標がズレています（差: 2）。どちらを優先しますか？"
    },
    ...
  ],
  "coping3": [
    {
      "domain": "共通",
      "text": "十分な休息を取ってください。"
    },
    ...
  ],
  "reboot": {
    "reboot_needed": false,
    "reboot_level": null,
    "reboot_step": null
  },
  "line_message": "📅 2025-12-21\n状態: NetStage -1 / Danger 0\nリスク: Lime\n...",
  "line_send_immediate": false,
  "version": "v1.0.0"
}
```

---

## エラーが出た場合

### エラー: "Sheet not found"

**原因**: スプレッドシートに必要なシートが存在しない

**対処法**:
1. スプレッドシートを開く
2. 以下のシートが存在するか確認：
   - Daily_Log
   - Daily_Output
   - Drivers_Long
   - Coping_Long
   - CrisisPlan_Source
   - Settings_Algorithm
   - Settings_Weights
   - Enabled_Metrics

### エラー: "OPENAI_API_KEY not set"

**原因**: スクリプトプロパティが設定されていない

**対処法**:
1. GASエディタで「プロジェクトの設定」→「スクリプト プロパティ」
2. `OPENAI_API_KEY` を追加

### エラー: "CORS" または "Access-Control-Allow-Origin"

**原因**: ブラウザからの直接アクセスでCORSエラー

**対処法**:
- 方法1（ブラウザ）を使う場合は、CORSエラーが出る可能性があります
- その場合は、方法2（Postman）または方法3（オンラインツール）を使用してください

---

## 推奨：方法3（オンラインツール）

**最も簡単で、エラーが出にくい方法です。**

1. https://reqbin.com/ を開く
2. POSTを選択
3. URLとJSONを貼り付け
4. Sendをクリック

これで完了です！

---

**テストが成功したら、フェーズAの実装に進めます！**

