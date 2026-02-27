# clasp実行手順（既にインストール済みの場合）

既にNode.jsとclaspがインストールされている場合の手順です。

---

## 1. PowerShellを開く

1. Windowsキーを押す
2. 「PowerShell」と入力
3. 「Windows PowerShell」をクリック

---

## 2. BipolarAIフォルダに移動

PowerShellで以下を入力してEnter：

```powershell
cd C:\Users\yasut\BipolarAI
```

---

## 3. claspでログイン（初回のみ）

以下を入力してEnter：

```powershell
clasp login
```

**初回の場合**：
- ブラウザが自動的に開きます
- Googleアカウントを選択（双極AIのスプレッドシートと同じアカウント）
- 「許可」をクリック
- PowerShellに「Success!」と表示されればOK

**既にログイン済みの場合**：
- そのまま次のステップへ

---

## 4. 既存のGASプロジェクトに接続

以下を入力してEnter：

```powershell
clasp clone 1CQCYu6NIh_6AODKesZQL3Ng6nz4BtFZU5lyEmGP84a7f2EYpkt4dSk0S
```

**成功した場合**：
- `appsscript.json` ファイルが作成されます
- 「Cloned 1 files.」と表示されます

**エラーが出た場合**：
- 「プロジェクトが見つかりません」→ GASプロジェクトが存在するか確認
- 「権限がありません」→ ログインしているアカウントが正しいか確認

---

## 5. コードをアップロード

以下を入力してEnter：

```powershell
clasp push
```

**成功した場合**：
- 「Pushed X files.」と表示されます
- GASエディタでコードが更新されます

---

## 6. 動作確認

### GASエディタで確認

以下を入力してEnter：

```powershell
clasp open
```

ブラウザでGASエディタが開きます。コードが正しくアップロードされているか確認してください。

---

## よくあるエラーと対処法

### エラー: 「プロジェクトが見つかりません」

**原因**: GASプロジェクトがまだ作成されていない

**対処法**:
1. [Google Apps Script](https://script.google.com/) にアクセス
2. 「新しいプロジェクト」をクリック
3. プロジェクト名を「双極AI」に変更
4. プロジェクトIDを確認（URLの `/d/` と `/edit` の間）
5. `config.json` の `script_id` を更新
6. 再度 `clasp clone` を実行

### エラー: 「権限がありません」

**原因**: ログインしているアカウントがGASプロジェクトにアクセスできない

**対処法**:
1. 正しいGoogleアカウントでログインしているか確認
2. GASプロジェクトの共有設定を確認
3. 再度 `clasp login` を実行

### エラー: 「ファイルが見つかりません」

**原因**: `gas_code.gs` が正しい場所にない

**対処法**:
1. `cd C:\Users\yasut\BipolarAI` で正しいフォルダにいるか確認
2. `dir` で `gas_code.gs` があるか確認
3. ファイル名が正しいか確認（`gas_code.gs`）

---

## 便利なコマンド

| コマンド | 説明 |
|---------|------|
| `clasp push` | コードをGASにアップロード |
| `clasp pull` | GASからコードをダウンロード |
| `clasp open` | GASエディタをブラウザで開く |
| `clasp logs` | 実行ログを表示 |
| `clasp deploy` | Webアプリとしてデプロイ |

---

## 次のステップ

1. **コードをアップロード**（`clasp push`）
2. **GASエディタで確認**（`clasp open`）
3. **OpenAI APIキーを設定**
   - GASエディタで「プロジェクトの設定」→「スクリプト プロパティ」
   - プロパティ: `OPENAI_API_KEY`
   - 値: `config.json` に記載のAPIキー
4. **Webアプリとしてデプロイ**
   - GASエディタで「デプロイ」→「新しいデプロイ」→「ウェブアプリ」

---

**困ったときは**：
- `clasp --help` でヘルプを表示
- エラーメッセージをコピーして検索

