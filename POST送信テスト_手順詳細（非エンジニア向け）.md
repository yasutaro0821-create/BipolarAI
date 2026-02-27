# POST送信テスト 手順詳細（非エンジニア向け）

**目的**: GAS（頭脳）が正しく動作するか確認する

**所要時間**: 約5分

---

## 📋 準備するもの

- パソコン（Windows/MacどちらでもOK）
- インターネット接続
- ブラウザ（Chrome、Edge、Firefoxなど）
- Googleスプレッドシートへのアクセス権限

---

## 🚀 ステップ1: reqbin.comを開く（1分）

### 1-1. ブラウザを開く

パソコンのブラウザ（Chrome、Edgeなど）を開きます。

### 1-2. reqbin.comにアクセス

ブラウザのアドレスバーに以下を入力して、Enterキーを押します：

```
https://reqbin.com/
```

または、以下のリンクをクリック：
https://reqbin.com/

### 1-3. ページが開くのを待つ

「REST Client」という画面が表示されます。

---

## 🚀 ステップ2: POST送信の設定（2分）

### 2-1. Method（メソッド）を選択

画面の左上に「GET」というボタンがあるので、それをクリックします。

ドロップダウンメニューが表示されるので、**「POST」**を選択します。

### 2-2. URLを入力

「Enter request URL」という欄があります。そこに以下をコピー＆ペーストします：

```
https://script.google.com/macros/s/AKfycbwhfOswhC5kqt9C3kKU9CLcURie81ROL35pZD0UQgf0QvYKeWRNyEP7m4Y5RF8EQw1V/exec
```

**コピー方法**:
1. 上のURLをマウスで選択（ドラッグ）
2. 右クリック → 「コピー」
3. reqbin.comのURL欄に貼り付け（右クリック → 「貼り付け」）

### 2-3. Content-Typeを設定

画面の「Headers」タブをクリックします。

「Add Header」ボタンをクリックします。

- **Name（名前）**: `Content-Type`
- **Value（値）**: `application/json`

を入力して、「Add」をクリックします。

### 2-4. Body（送信データ）を入力

画面の「Body」タブをクリックします。

「raw」が選択されていることを確認します。

右側に「Text」というドロップダウンがあるので、それをクリックして**「JSON」**を選択します。

大きなテキストボックスに、以下をコピー＆ペーストします：

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

**注意**: 上記のJSONをそのままコピーしてください。`"date": "2025-12-22"` の日付は、今日の日付に変更してもOKです（例：`"2025-12-23"`）。

---

## 🚀 ステップ3: 送信して結果を確認（1分）

### 3-1. Sendボタンをクリック

画面の右上または下部に「Send」というボタンがあります。それをクリックします。

### 3-2. 結果を待つ

少し待つと（数秒）、画面の右側または下部に結果が表示されます。

### 3-3. 結果を確認

表示された結果（JSON形式）を確認します。

**成功している場合**、以下のような内容が表示されます：

```json
{
  "ok": true,
  "log_id": 7,
  "output_id": 5,
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
      "description": "主観（Mood+定型質問）と客観指標がズレています（差: 2）。"
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
    ...
  },
  "line_message": "📅 2025-12-22\n状態: NetStage -1 / Danger 0\n...",
  "line_send_immediate": false,
  "version": "v1.0.0"
}
```

### 3-4. 確認ポイント

以下の項目が表示されているか確認してください：

- ✅ `"ok": true` が表示されている
- ✅ `"net_stage"` が -5〜+5 の範囲の数字（例：-1、0、+2）
- ✅ `"danger"` が 0〜5 の範囲の数字（例：0、1、3）
- ✅ `"top_drivers"` が3つ表示されている（`description` が空でない）
- ✅ `"coping3"` が3つ表示されている（`text` が空でない）
- ✅ `"line_message"` が表示されている（長いテキスト）

**エラーが出た場合**:
- `"ok": false` が表示される
- `"error"` という項目にエラーメッセージが表示される
- その場合は、エラーメッセージをコピーして共有してください

---

## 🚀 ステップ4: スプレッドシートを確認（1分）

### 4-1. Googleスプレッドシートを開く

ブラウザで以下のURLを開きます：

```
https://docs.google.com/spreadsheets/d/1Dk4MK5ITmAimxFhnY1Ji-qxw7qx2BIgxDni03aL269k/edit
```

または、Googleドライブから「双極AI DBテンプレート Vol.8」を開きます。

### 4-2. Daily_Logシートを確認

スプレッドシートの下部にあるタブから「Daily_Log」をクリックします。

**確認ポイント**:
- 最新の行（一番下）に、今送信したデータが追加されている
- `date` 列に今日の日付（例：2025-12-22）
- `mood_score` 列に `-2`
- `journal_text` 列に「今日は少し疲れました。」
- など、送信したデータが記録されている

### 4-3. Daily_Outputシートを確認

スプレッドシートの下部にあるタブから「Daily_Output」をクリックします。

**確認ポイント**:
- 最新の行（一番下）に、計算結果が追加されている
- `net_stage` 列に数字（例：-1）
- `danger` 列に数字（例：0）
- `risk_color` 列に色（例：Lime）
- `top_driver_1`、`top_driver_2`、`top_driver_3` に説明が入っている
- `coping_1`、`coping_2`、`coping_3` にテキストが入っている

---

## ✅ 完了条件

以下のすべてが確認できれば、**テスト成功**です：

1. ✅ reqbin.comで `"ok": true` が返ってきた
2. ✅ `net_stage` と `danger` が正しく計算されている
3. ✅ `top_drivers` が3つ返ってきた（`description` が空でない）
4. ✅ `coping3` が3つ返ってきた（`text` が空でない）
5. ✅ `line_message` が生成されている
6. ✅ スプレッドシートの `Daily_Log` にデータが追加された
7. ✅ スプレッドシートの `Daily_Output` に計算結果が追加された

---

## 📝 結果を共有する方法

### 成功した場合

以下のように報告してください：

```
✅ テスト成功！

確認できたこと：
- ok: true が返ってきた
- net_stage: -1
- danger: 0
- top_drivers: 3つ返ってきた
- coping3: 3つ返ってきた
- line_message: 生成されている
- Daily_Log: データが追加された
- Daily_Output: 計算結果が追加された
```

### エラーが出た場合

以下の情報を共有してください：

1. **エラーメッセージ**: reqbin.comに表示されたエラーメッセージをコピー
2. **レスポンスの内容**: 表示されたJSONをコピー（全部）
3. **どのステップでエラーが出たか**: ステップ3（送信時）か、ステップ4（スプレッドシート確認時）か

---

## ⚠️ よくある問題と対処法

### 問題1: reqbin.comが開けない

**対処法**:
- インターネット接続を確認
- 別のブラウザで試す
- しばらく待ってから再度アクセス

### 問題2: Sendボタンを押しても何も起こらない

**対処法**:
- URLが正しく入力されているか確認
- BodyのJSONが正しく入力されているか確認（コピー＆ペーストで確実に）
- ブラウザのコンソール（F12キー）でエラーが出ていないか確認

### 問題3: エラー "Sheet not found"

**対処法**:
- スプレッドシートに必要なシート（Daily_Log、Daily_Outputなど）が存在するか確認
- スプレッドシートIDが正しいか確認

### 問題4: エラー "OPENAI_API_KEY not set"

**対処法**:
- GASエディタでスクリプトプロパティに `OPENAI_API_KEY` が設定されているか確認
- 設定方法は `セットアップ手順.md` を参照

### 問題5: Coping3が空またはデフォルト値

**対処法**:
- レスポンスに `_debug_coping` という項目があるか確認
- ある場合は、その内容を共有してください
- CrisisPlan_Sourceシートが正しく設定されているか確認

---

## 🎯 次のステップ

### テストが成功した場合

✅ **Mac作業は「箱（iOS）に入れて動かすだけ」になります！**

次のステップ：
1. Mac環境でXcodeプロジェクトを作成
2. iOSコードをコピー
3. ビルドして動作確認

### テストで問題があった場合

1. エラーメッセージを共有
2. 問題を修正
3. 再度テスト

---

**この手順に従って、今すぐテストを実行してください！**

結果を共有していただければ、次のステップに進みます。

