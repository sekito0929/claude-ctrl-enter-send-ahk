# claude-ctrl-enter-send-ahk

Windows 版 Claude デスクトップアプリで、**Enter を改行、Ctrl+Enter を送信**に変える AutoHotkey v2 スクリプトです。
日本語入力(IME)で変換中の Enter は、これまでどおり**変換の確定**として働きます。

> 非公式のツールです。Anthropic とは関係ありません。

| 操作 | 動作 |
|---|---|
| Enter(変換中) | 変換を確定 |
| Enter(それ以外) | 改行 |
| Ctrl+Enter | 送信 |

## 必要なもの

- Windows 10 / 11
- [AutoHotkey v2](https://www.autohotkey.com/)
- Claude デスクトップアプリ(実行ファイル名 `Claude.exe`)

## 使い方

1. `claude-ctrl-enter.ahk` をダウンロードし、置きたいフォルダに保存します。
2. ファイルをダブルクリックして起動します。タスクトレイに緑の「H」アイコンが出れば動いています。
3. パソコンの起動時に自動で動かしたい場合は、`Win+R` で `shell:startup` を開き、スクリプトの**ショートカット**をそこに置きます(本体を置くより、更新したときに管理しやすくなります)。

止めるときは、タスクトレイの「H」アイコンを右クリックして Exit を選びます。

## しくみと制限

Electron 製のアプリでは、外部のプログラムから「IME で変換中かどうか」を直接読み取れません。そこでこのスクリプトは、IME がオンのあいだに打った文字キーの数を数えて、変換中かどうかを推定しています。

- 変換中と判定したときだけ、Enter をそのまま渡します(変換の確定)。それ以外は Shift+Enter を送ります(改行)。
- 判定に迷う場面では、送信ではなく改行になるほうに倒しています。
- Space で変換したあとに Backspace で直した場合など、Enter で確定できないことがあります。そのときは **Ctrl+Enter** で確定できます(変換中の Ctrl+Enter は確定だけで、送信されません)。
- キー入れ替えソフト(PowerToys の Keyboard Manager など)を使っていると、判定に影響することがあります。

## プライバシーと安全性

- ネットワークには一切接続しません。
- 入力した文章は、保存も送信もしません。
- 設定欄の `LOGGING := true` で診断ログを有効にできます(初期値は無効)。ログに残るのはキー名、判定用の数値、IME のオン/オフだけで、入力した文章は記録しません。
- キーボードの入力を監視するスクリプトです。入手元が信頼できるか確認し、中身を読んでから実行してください。
- 起動時に、同じ名前(`claude-ctrl-enter`)を含むほかの AutoHotkey スクリプトを終了します。2つ同時に動いて誤動作するのを防ぐためです。

## 設定

ファイル先頭の設定欄で変更できます。

```autohotkey
global TARGET_EXE := "Claude.exe"   ; 対象アプリの実行ファイル名
global LOGGING    := false          ; true で診断ログを出力
```

## English

AutoHotkey v2 script for the Claude desktop app on Windows: **Enter inserts a newline, Ctrl+Enter sends**. While the Japanese IME is composing, Enter still confirms the conversion. Composition is estimated by counting keys typed while the IME is on, because Electron apps do not expose the composition to other processes. No network access; typed text is never stored. Unofficial, not affiliated with Anthropic.

## License

MIT
