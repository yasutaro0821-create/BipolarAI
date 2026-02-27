# GASエディタへのコード貼り付け手順

clasp pushがエラーになる場合の簡単な方法です。

---

## 手順

### 1. Code.gsを開く

1. エクスプローラーで `C:\Users\yasut\BipolarAI` を開く
2. `Code.gs` を右クリック
3. 「プログラムから開く」→「メモ帳」（またはお好みのエディタ）

### 2. コードをコピー

1. メモ帳で `Ctrl+A`（全選択）
2. `Ctrl+C`（コピー）

### 3. GASエディタを開く

ブラウザで以下を開く：

```
https://script.google.com/home/projects/1CQCYu6NIh_6AODKesZQL3Ng6nz4BtFZU5lyEmGP84a7f2EYpkt4dSk0S/edit
```

### 4. コードを貼り付け

1. GASエディタで既存のコード（`function myFunction() {}` など）を全選択（`Ctrl+A`）
2. 削除（`Delete` キー）
3. 貼り付け（`Ctrl+V`）

### 5. 保存

- `Ctrl+S` または「保存」ボタン（💾）

### 6. 動作確認

ブラウザで以下にアクセス：

```
https://script.google.com/macros/s/AKfycbwhfOswhC5kqt9C3kKU9CLcURie81ROL35pZD0UQgf0QvYKeWRNyEP7m4Y5RF8EQw1V/exec?mode=health
```

**成功した場合**：
```json
{"ok":true,"service":"bipolar-ai-gas","version":"v1.0.0","now":"2025-12-21T..."}
```

---

## 次のステップ

### OpenAI APIキーの設定

1. GASエディタで「プロジェクトの設定」（⚙️）をクリック
2. 「スクリプト プロパティ」セクションで「スクリプト プロパティを追加」をクリック
3. 以下を設定：
   - **プロパティ**: `OPENAI_API_KEY`
   - **値**: `config.json` に記載のAPIキー
     ```
     YOUR_OPENAI_API_KEY（config.jsonを参照）
     ```
4. 「保存」をクリック

---

## デプロイの更新

コードを更新した後、デプロイを更新する必要があります：

1. GASエディタで「デプロイ」→「デプロイを管理」をクリック
2. 既存のデプロイの右側の「編集」（✏️）をクリック
3. 「バージョン」を「新バージョン」に変更
4. 「デプロイ」をクリック

**注意**: デプロイを更新しないと、変更が反映されません。

---

## トラブルシューティング

### エラー: "Script function not found: doGet"

**原因**: コードがアップロードされていない、または保存されていない

**対処法**:
1. GASエディタでコードが正しく貼り付けられているか確認
2. 保存（Ctrl+S）を実行
3. デプロイを更新

### エラー: "OPENAI_API_KEY not set"

**原因**: スクリプトプロパティが設定されていない

**対処法**:
1. 「プロジェクトの設定」→「スクリプト プロパティ」を確認
2. `OPENAI_API_KEY` が正しく設定されているか確認

---

**これでコードがアップロードされます！**

