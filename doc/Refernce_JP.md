# SimpleMission

## 概要

Stormworks向けのカスタムミッション管理スクリプトです。

シンプルな記述でミッションを作成することを目的としています。

## Mission

`local mm_missions`内にミッションの定義を記載します。\
`ミッションID = {}`の書式で一つのミッションを定義し、`{}`の中に内容を記載します。それぞれのミッションの間には`,`が必要です。

例:

```lua
local mm_missions = {
    fire_research = { -- ミッションID
        title = "Reseach center fire",
        ...
    },
    fire_windmill = {
        title = "Windmill fire",
        ...
    }
}
```

### パラメータ
それぞれのミッションには、以下のようなパラメータを設定できます。

|パラメータ名|必須|説明|
|-----------|----|----|
|`title`|o|タイトル。通知などで表示されます|
|`location`|o|ミッションに使用するlocation。<br>ミッションエディタで作成し名前を付ける必要があります。|
|`tasks`|o|タスクを定義します。詳しくは下記参照|
|`base_reward`||クリアした際の報酬金額。|
|`base_research`||クリアした際の報酬研究ポイント。|
|`probability`||発生確率を0.01~1.0で指定します。(デフォルト:1.0)<br>絶対的な確率ではなく、他のミッションとの相対的な発生確率になります。(後述します）|
|`no_spawn`||trueに設定されている場合、`?spawn_mission`コマンドで指定されない限りミッションは開始しません。 |

### タスク
ミッション内の目標をタスクと呼びます。タスクは、ミッション内の `tasks` で以下のように定義します。

```lua
local mm_missions = {
    fire_research = { -- Mission ID
        ...
        tasks = {
            {
                step = 0, 
                type = "goto_zone",
                ...
            },
            {
                step = 1, 
                type = "rescue",
                ...
            },
            {
                step = 1, 
                type = "extinguish",
                ...
            },
        }
    }
}
```

|パラメータ名|必須|説明|
|-----------|----|----|
|`step`|o|ステップ番号。詳しくは下記説明を参照|
|`type`|o|種類。詳しくは下記説明を参照|
|`name`|o|タイトル。通知などで表示されます|
|`desc`|o|詳細説明。マップではタイトルの下に表示されます|
|`timelimit`||時間制限。tick単位で指定します(1秒=60tick)<br>例: `60*60*30` = 30分|
|`base_reward`||クリアした際の報酬金額|
|`base_research`||クリアした際の報酬研究ポイント|

### step,typeについて

タスクのパラメータ `step` はタスクの順番を設定します。\
たとえば、 `step=0`に指定地点へ移動、 `step=1`に消火・救助のタスクを指定すると、まず指定地点へ移動してから初めて消火・救助のタスクが現れるようにすることができます。

パラメータ `type` では、タスクの種類が指定できます。typeによって指定できるパラメータが異なります。\
現在使用できるtypeは `goto_zone`, `rescue`, `deliver_vehicle`, `deliver_survivor`, `deliver_object`です。

#### goto_zone

指定されたゾーンまで移動するタスクです。

|パラメータ名|必須|説明|
|-----------|----|----|
|`zone`|o|location内のzone名。ミッションエディタではtagの欄で設定します|
|`zone_size`|o|m単位でのゾーンの半径|

#### rescue

生存者を救助して病院に運ぶタスクです。\
デフォルトではlocationに配置された全員を救助する必要があります。病院の場所は問いません。（`hospital`として指定されているDelivery zoneへの移送が対象）

|パラメータ名|必須|説明|
|-----------|----|----|
|`tag`||フィルターするtag。指定している場合はtagが一致する生存者のみ救助対象になります|
|`reward_per_survivor`||Cash reward for completing a mission.|
|`research_per_survivor`||Research point reward for completing a mission.|
|`rescue_name`||Name to filter. If specified, only survivor with matching "marker text" will be rescued.|

#### extinguish

火災を消火するタスクです。\
デフォルトにはlocationに配置されたすべてのFireと、locationに配置されているvehicleの炎が対象になります。

|パラメータ名|必須|説明|
|-----------|----|----|
|`tag`||フィルターするtag。指定している場合はtagが一致するFireのみ消火対象になります|
|`ignore_vehicle`||trueが指定されている場合は燃えているvehicleを対象にしません|

#### deliver_vehicle

Vehicleを指定されたゾーンまで移動させるタスクです。

|Parameter|Required|Description|
|-----------|----|----|
|`delivery_zone`|o|Target cargo zone name. tag|
|`delivery_name`||Name to filter. If specified, only vehicle with matching "marker text" will be rescued.|

#### deliver_survivor

Deliver survivor to zone.

|Parameter|Required|Description|
|-----------|----|----|
|`delivery_name`||Name to filter. If specified, only vehicle with matching "marker text" will be rescued.|
|`delivery_zone`||Name of target delivery zone. <br>You need to create "delivery zone" in enviroment mod by mission editor, and enter name to "tag".|
|`reward_per_survivor`||Cash reward for completing a mission.|
|`research_per_survivor`||Research point reward for completing a mission.|

#### deliver_object

Deliver object to zone.

|Parameter|Required|Description|
|-----------|----|----|
|`delivery_zone`|o|Target cargo zone name.|
|`delivery_name`||Name to filter. If specified, only object with matching "marker text" will be rescued.|

## Command

|command|description|
|-|-|-|
|`?spawn <pack_name> <mission_name>`|Spawn mission immediately.<br>`<pack_name>`: Configured pack name.<br>`<mission_name>`: Indentifer of mission to spawn.|
|`?spawn_random <pack_name>`|Spawn random mission immediately.<br>`<pack_name>`: Configured pack name.|
|`?del_mission <pack_name> <mission_name>`|Delete mission immediately.<br>`<pack_name>`: Configured pack name.<br>`<mission_name>`: Indentifer of mission to delete.|
|`?missions <pack_name>`|List currently active missions.<br>`<pack_name>`: Configured pack name.|
|`?location <pack_name>`|List all location in pack
.<br>`<pack_name>`: Configured pack name.|

### ミッションの発生確率について
ミッションは、設定された発生間隔の範囲でランダムに発生します。\
この際、以下のアルゴリズムで抽選が行われます。

1. 現在進行中ではないミッションを列挙し、すべての`probability`を加算する
2. `probability`の合計値を最大値として乱数を生成する
3. その乱数の範囲に入ったミッションを選択する

そのため、たとえば`probability`が0.01でも対象のミッションが一つしかない場合はそのミッションが選択されます。\
また、ミッションの`probability`がすべて0.01の場合は等しい確率で選択されます。あくまで`probability`は相対的な確率に過ぎないことに留意してください。

### その他の注意事項
* Luaスクリプトの変更はセーブデータの再読込で反映されますが、ミッションエディタでの変更は`?reload_scripts`コマンドを使用するかセーブデータを作り直さないと反映されません。
* Enviroment modの変更はセーブデータを作り直さないと反映されません。
* delivery_zoneに指定するCargo zoneにはMarker textがないと認識されません。