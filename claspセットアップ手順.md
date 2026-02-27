# claspセットアップ手順（非エンジニア向け）

claspを使うと、パソコンからGoogle Apps Scriptのコードを管理できます。

---

## 📋 目次

1. [claspとは](#claspとは)
2. [Node.jsのインストール](#nodejsのインストール)
3. [claspのインストール](#claspのインストール)
4. [claspでログイン](#claspでログイン)
5. [既存のGASプロジェクトに接続](#既存のgasプロジェクトに接続)
6. [コードをアップロード](#コードをアップロード)
7. [よくある質問](#よくある質問)

---

## claspとは

claspは、Google Apps Scriptのコードをパソコンで編集・管理するためのツールです。

**メリット**：
- パソコンでコードを編集できる（GASエディタより使いやすい）
- バックアップが簡単
- 複数のファイルを管理しやすい

---

## Node.jsのインストール

claspを使うには、まずNode.jsをインストールする必要があります。

### 1. Node.jsのダウンロード

1. ブラウザで以下を開く：
   ```
   https://nodejs.org/ja/
   ```

2. 「推奨版」の「ダウンロード」ボタンをクリック
   - 例：`v20.11.0 LTS` など

3. ダウンロードしたファイル（`.msi`）を実行

### 2. インストール

1. インストーラーを起動
2. 「次へ」をクリック（デフォルト設定でOK）
3. インストールが完了したら「閉じる」をクリック

### 3. インストール確認

1. **PowerShell**を開く（Windowsキー → 「PowerShell」と入力）
2. 以下を入力してEnter：
   ```powershell
   node --version
   ```
3. バージョン番号（例：`v20.11.0`）が表示されればOK

---

## claspのインストール

### 1. PowerShellで実行

PowerShellを開いて、以下を入力してEnter：

```powershell
npm install -g @google/clasp
```

**所要時間**：約1-2分

**注意**：初回は時間がかかることがあります。エラーが出た場合は、下の「トラブルシューティング」を参照してください。

### 2. インストール確認

以下を入力してEnter：

```powershell
clasp --version
```

バージョン番号（例：`2.4.2`）が表示されればOKです。

---

## claspでログイン

### 1. ログインコマンド

PowerShellで以下を入力してEnter：

```powershell
clasp login
```

### 2. ブラウザが開く

1. 自動的にブラウザが開きます
2. Googleアカウントを選択（双極AIのスプレッドシートと同じアカウント）
3. 「許可」をクリック

### 3. 完了確認

PowerShellに「Success!」と表示されればOKです。

---

## 既存のGASプロジェクトに接続

既に作成済みのGASプロジェクト（スクリプトID: `1CQCYu6NIh_6AODKesZQL3Ng6nz4BtFZU5lyEmGP84a7f2EYpkt4dSk0S`）に接続します。

### 1. BipolarAIフォルダに移動

PowerShellで以下を入力してEnter：

```powershell
cd C:\Users\yasut\BipolarAI
```

### 2. 既存プロジェクトをクローン

以下を入力してEnter：

```powershell
clasp clone 1CQCYu6NIh_6AODKesZQL3Ng6nz4BtFZU5lyEmGP84a7f2EYpkt4dSk0S
```

**注意**：もし「プロジェクトが見つかりません」というエラーが出た場合は、先にGASでプロジェクトを作成する必要があります（下記参照）。

### 3. 成功確認

`appsscript.json` というファイルが作成されれば成功です。

---

## コードをアップロード

### 1. コードを編集

`gas_code.gs` を編集します（メモ帳やVS Codeなどで開けます）。

### 2. アップロード

PowerShellで以下を入力してEnter：

```powershell
clasp push
```

### 3. 確認

「Pushed X files.」と表示されれば成功です。

---

## 初めてGASプロジェクトを作成する場合

もし既存のプロジェクトがない場合は、以下で新規作成できます。

### 1. 新規プロジェクト作成

PowerShellで以下を入力してEnter：

```powershell
cd C:\Users\yasut\BipolarAI
clasp create --type standalone --title "双極AI"
```

### 2. プロジェクトIDを確認

作成された `appsscript.json` を開いて、`scriptId` を確認します。

### 3. config.jsonを更新

`config.json` の `script_id` を、上記で確認したIDに更新します。

---

## よくある質問

### Q: `npm` コマンドが見つからない

**A**: Node.jsが正しくインストールされていない可能性があります。

1. Node.jsを再インストール
2. PowerShellを再起動
3. `node --version` で確認

### Q: `clasp login` でエラーが出る

**A**: 以下を試してください：

1. ブラウザで手動ログイン：
   ```
   https://script.google.com/
   ```
2. 再度 `clasp login` を実行

### Q: `clasp clone` で「プロジェクトが見つかりません」

**A**: 以下のいずれかを確認：

1. スクリプトIDが正しいか
2. ログインしているGoogleアカウントが、GASプロジェクトにアクセスできるか
3. GASプロジェクトが存在するか（[script.google.com](https://script.google.com/)で確認）

### Q: `clasp push` でエラーが出る

**A**: 以下を確認：

1. `gas_code.gs` が正しい場所にあるか（`C:\Users\yasut\BipolarAI\`）
2. ファイル名が正しいか
3. コードに構文エラーがないか

### Q: コードを編集するには？

**A**: 以下のいずれかで編集できます：

1. **メモ帳**：`gas_code.gs` を右クリック → 「プログラムから開く」→「メモ帳」
2. **VS Code**（推奨）：[VS Code](https://code.visualstudio.com/)をインストールして開く

---

## 便利なコマンド一覧

| コマンド | 説明 |
|---------|------|
| `clasp login` | Googleアカウントでログイン |
| `clasp clone <SCRIPT_ID>` | 既存プロジェクトをダウンロード |
| `clasp push` | コードをGASにアップロード |
| `clasp pull` | GASからコードをダウンロード |
| `clasp open` | GASエディタをブラウザで開く |
| `clasp deploy` | Webアプリとしてデプロイ |

---

## 次のステップ

1. **claspでログイン**
2. **既存プロジェクトに接続**（または新規作成）
3. **`gas_code.gs` を編集**
4. **`clasp push` でアップロード**
5. **GASエディタで動作確認**

---

**困ったときは**：
- `clasp --help` でヘルプを表示
- エラーメッセージをコピーして検索
- `セットアップ手順.md` も参照してください

