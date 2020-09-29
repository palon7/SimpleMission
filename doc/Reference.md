# SimpleMission Reference

## Mission

The definition of a mission is written in the `local mm_missions` array.

```lua
local mm_missions = {
    fire_research = { -- Indentifer of mission
        title = "Reseach center fire",
        ...
    },
    fire_windmill = {
        title = "Windmill fire",
        ...
    }
}
```

### Parameter
The following parameters can be use for each mission.

|Parameter|Required|Description|
|---------|----|----|
|`title`|o|Title of mission.|
|`location`|o|Location of mission.<br>You need to create location by mission editor, and name it.|
|`tasks`|o|Define tasks.(See below)|
|`base_reward`||Cash reward for completing a mission.|
|`base_research`||Research point reward for completing a mission.|
|`probability`||The probability that the mission will occur, set by 0.01~1.0. (Default: 1.0)|
|`no_spawn`||If true, the mission will not spawn unless the `?spawn_mission` command is issued. |

### Task
A task is an objective in a mission. Tasks are defined in the `tasks` array in mission.

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

|Parameter|Required|Description|
|---------|----|----|
|`step`|o|Step of task. See below description.|
|`type`|o|Type of task. See "Task types".|
|`name`|o|Title of task.|
|`desc`|o|Description on task. Show in map hover message.|
|`timelimit`||Time to expire task in tick.(1 second = 60 ticks)<br>ex. `60*60*30` = 30 minutes|
|`base_reward`||Cash reward for completing a mission.|
|`base_research`||Research point reward for completing a mission.|

### About "step"
The task parameter `step` sets the order of the tasks.

For example, if you set "move to zone" task with `step = 0`, and set "rescue survivor" task and "extinguish fire" task with `step=1`, then the rescue survivor and extinguish fire tasks will appear only after moving to the zone first.

If you set the same `step` to multiple tasks, these tasks will appear at the same time. When all tasks have been completed, current step is increased by 1.

### Task types
The task parameter `type` define type of tasks. The additional parameters that can be specified vary depending on the type.

Currently available value: `goto_zone`, `rescue`, `extinguish`, `deliver_vehicle`, `deliver_survivor`, `deliver_object`

#### goto_zone

Move to the specified zone.

|Parameter|Required|Description|
|-----------|----|----|
|`zone`|o|Zone name in location. Specified by "tag" field in mission editor.|
|`zone_size`|o|Zone radius in meter. (Zone radius in editor is ignored)|

#### rescue

Rescue the survivors and transport them to the hospital.

You must rescue everyone placed in location by default. It does not matter where the hospital is located, it must be transferred to a delivery zone tagged as `hospital`.\
Injured survivors lose 1 hp every 10 seconds.

|Parameter|Required|Description|
|-----------|----|----|
|`reward_per_survivor`||Cash reward per survivor.|
|`research_per_survivor`||Research point reward per survivor.|
|`rescue_name`||If specified, only survivor with matching "marker text" will be rescued.|
|`no_bleed`||If true, survivors will not lose HP over time, even if they are injured. |

#### extinguish

Extinguish the fire.

You must extinguish all fire placed in location, and all burning vehicle that are placed in location by default.

|Parameter|Required|Description|
|-----------|----|----|
|`tag`||Tag name to filter. If specified, only fire with matching tags will be rescued|
|`ignore_vehicle`||If true, don't check burning vehicles|

#### deliver_vehicle

Deliver vehicle to zone.

|Parameter|Required|Description|
|-----------|----|----|
|`delivery_zone`|o|Target cargo zone name. **If the Marker text in the Cargo zone is empty, it will not work properly**|
|`delivery_name`||Name to filter. If specified, only vehicle with matching "marker text" will be rescued.|

#### deliver_survivor

Deliver survivor to zone.

|Parameter|Required|Description|
|-----------|----|----|
|`delivery_zone`|o|Target cargo zone name. **If the Marker text in the Cargo zone is empty, it will not work properly**|
|`delivery_name`||Name to filter. If specified, only vehicle with matching "marker text" will be rescued.|
|`reward_per_survivor`||Cash reward for completing a mission.|
|`research_per_survivor`||Research point reward for completing a mission.|

#### deliver_object

Deliver object to zone.

|Parameter|Required|Description|
|-----------|----|----|
|`delivery_zone`|o|Target cargo zone name. **If the Marker text in the Cargo zone is empty, it will not work properly**|
|`delivery_name`||Name to filter. If specified, only object with matching "marker text" will be rescued.|

## Command

|command|description|
|-|-|-|
|`?spawn <pack_name> <mission_name>`|Spawn mission immediately.<br>`<pack_name>`: Configured pack name.<br>`<mission_name>`: Indentifer of mission to spawn.|
|`?spawn_random <pack_name>`|Spawn random mission immediately.<br>`<pack_name>`: Configured pack name.|
|`?del_mission <pack_name> <mission_name>`|Delete mission immediately.<br>`<pack_name>`: Configured pack name.<br>`<mission_name>`: Indentifer of mission to delete.|
|`?missions <pack_name>`|List currently active missions.<br>`<pack_name>`: Configured pack name.|
|`?location <pack_name>`|List all location in pack.<br>`<pack_name>`: Configured pack name.|

### About probability
Missions are randomly generated within a set occurrence interval.
The missions are randomly selected by the following algorithm.


1. list the missions that are not currently in progress and add all `probability`
2. generate a random number whose maximum value is the sum of `probability`.
3. select a mission that is within that random number range.

So, for example, if there is only one mission with a `probability` of 0.01, that mission will be selected.

Also, if the mission's `probability` is all 0.01, it is selected with equal probability. Note that `probability` is only a relative probability.

### Notes
* Changes in Lua scripts are reflected by reloading the savegame, but you need to use the `?reload_scripts` command or recreate the saved data to reflect changes made in the mission editor.
* The changes in the Enviroment mod probably won't be reflected unless you recreate the savegame.
* The Cargo zone specified in the `delivery_zone` must have a "Marker text" to be recognized.