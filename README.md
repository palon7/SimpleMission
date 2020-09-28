# SimpleMission
Custom mission script for Stormworks.

It is intended to create missions with a simple settings, without writing lua.

## Feature
* Create a series of missions that happen at a fixed location
* You can create a mission without writing Lua
* You can specify objective like: move to location, extinguish fires, rescue survivors, deliver objects/characters/vehicles.
* Manage step-by-step objective
* Random spawning of missions, or spawning by command (you can also create missions that only spawn by command)
* Adjusting rewards and probability of occurrence
* Display of map markers and notifications
* Time limit for each objective

## Getting Started

1. Code -> Download as zip or `git clone https://github.com/palon7/simplemission.git`
2. Copy script.lua content to playlist lua
3. Edit mission defination (see [Reference](/doc/Reference.md))
4. Test mission
5. Change `debug` to `false`, change `pack_name`
6. Release your pack!

See also: [Tutorial](/doc/Tutorial_JP.md)(Not translated yet)

## Testing 

Copy `example_missions` folder to `<stormworks install path>/data/missions/`

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

----
(Japanese)

Stormworks用のカスタムミッションスクリプトです。

## 機能
* 固定の場所で起きる、一連のミッションを作成
* Luaを書かずにミッションを作成できます
* 指定場所への移動、火災の消火、生存者の救助、オブジェクト・キャラクター・車両の配達を目標として指定可能
* ステップ毎の目標を管理
* ミッションのランダムスポーン、コマンドでのスポーン（コマンドでのみスポーンするミッションも作成可能）
* 報酬、発生確率の調整
* マップマーカー・通知の表示
* 目標毎の時間制限

## クイックスタート

1. Code -> Download as zipをクリックするか、`git clone https://github.com/palon7/simplemission.git`でダウンロードする
2. script.luaの内容をミッションプレイリストのLuaにコピーする
3. ミッションを設定する ([リファレンス](/doc/Reference_JP.md)を参照)
4. ミッションをテストする
5. `debug`を`false`に設定し、`pack_name`を変更する
6. リリースする

詳しくは[チュートリアル](/doc/Tutorial_JP.md)をご覧ください。

## テスト

スクリプトのテスト用にミッションをいくつか用意しています。
`example_missions`フォルダを`<stormworks install path>/data/missions/`にコピーしてください。

## License

MIT Licenseでリリースされています - [LICENSE.md](/LICENSE.md)をご確認ください