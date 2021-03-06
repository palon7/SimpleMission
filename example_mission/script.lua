--[[
Simple mission system 0.1
Copyright (c) 2020 Palon
Released under the MIT license
https://opensource.org/licenses/mit-license.php
]]

g_savedata = {}
-- Config
local pack_name = "demo" -- PLEASE CHANGE HERE BEFORE YOU RELEASE PACK - must be unique
local debug = true -- false before release pack
local check_interval = 60 -- Interval of mission complition check, in tick
local min_mission_interval = 30 -- Interval of random mission spawning
local max_mission_interval = 120
-- Mission Defination
local mm_missions = {
	deliver_object = {
        title = "Deliver object demo",
        location = "deliver_object",   -- name of location
		base_reward = 5000,       -- reward of rescue
		base_research = 10,
		probability = 0.5,
        tasks = {
            {
                step = 0, -- task step
                type = "deliver_object", -- type of task
                name = "Deliver object",
                desc = "Deliver box to hanger.",
				delivery_name = "target",
				delivery_zone = "cb_cz",
				timelimit = 60*60*15,
            }
        },
		no_spawn = true
    },
	deliver_vehicle = {
        title = "Deliver vehicle demo",
        location = "deliver_vehicle",   -- name of location
		base_reward = 5000,       -- reward of rescue
		base_research = 10,
		probability = 0.5,
        tasks = {
            {
                step = 0, -- task step
                type = "deliver_vehicle", -- type of task
                name = "Deliver vehicle",
                desc = "Deliver case to hanger.",
				delivery_name = "target",
				delivery_zone = "cb_cz",
				timelimit = 60*60*15,
            }
        },
		no_spawn = true
    },
	deliver_survivor = {
        title = "Deliver survivor demo",
        location = "deliver_survivor",   -- name of location
		base_reward = 5000,       -- reward of rescue
		base_research = 10,
		probability = 0.5,
        tasks = {
            {
                step = 0, -- task step
                type = "deliver_survivor", -- type of task
                name = "Deliver survivor",
                desc = "Deliver survivor to hanger.",
				tag = "target",
				delivery_zone = "cb_cz",
				timelimit = 60*60*15
            }
        },
		no_spawn = true
    },
    rescue_fire = {
        title = "Rescue&Fire Demo",
        location = "rescue_fire",   -- name of location
		base_reward = 5000,       -- reward of rescue
		base_research = 10,
		probability = 0.5,
        tasks = {
            {
                step = 0, -- task step
                type = "goto_zone", -- type of task
				zone = "zone_target", -- tag of target zone
				zone_size = 15, -- zone size
                name = "Respond to emergency call",
                desc = "Walk to survivor.",
				timelimit = 60*60*15
            },
            {
                step = 1,
                type = "extinguish",
                name = "Extinguish fire",
				desc = "Extinguish the fires.",
				-- timelimit = 60*60,
				timelimit = 60*60*60
             },
             {
                step = 1,
                type = "rescue",
                name = "Rescue 2 survivor",
				desc = "Deliver survivor to hospital.",
				timelimit = 60*60*60,
             }
        },
		no_spawn = true
	},
}

-- Variables
local tick_counter = 0
local spawn_mission_id = nil
local spawned_object = {}
local task_type = {
	-- Go to specified zone: Least one player need to enter specified zone
	goto_zone = {
		init = function(mission, task)
			zone = mission.zones[task.zone]
			if zone == nil then
				log("Error: "..task.name..": Zone not found")
				return
			end
			--local marker_x, marker_y, marker_z = matrix.position(zone.transform)
			-- addMarker(mission, task.id, createMarker(zone.x, zone.z, task.name, task.desc, 3),task.timeleft)
		end,
		update = function(mission, task)
			zone = mission.zones[task.zone]
			removeMarker(mission, task.id)
			addMarker(mission, task.id, createMarker(zone.x, zone.z, task.name, task.desc, 3), task.timeleft)
			if zone == nil then
				return
			end
			if playerIsInZone(zone, task.zone_size) then
				completeTask(mission, task, true)
			end
		end
	},
	-- Extinguish fire: Player need to extinguish all fire in location, filter by tag
	extinguish = {
		init = function(mission, task)
			--[[
			for i,fire in pairs(getMissionObjects(mission.data.location, "fire", task.tag)) do
				x,y,z = calcWorldPos(mission, fire)
				log(x..","..y..","..z..": id"..fire.id.."/"..fire.type)
				addMarker(mission, task.id, createMarker(x, z, task.name, task.desc, 5), task.timeleft)
			end
			]]
		end,
		update = function(mission, task)
			removeMarker(mission, task.id)
			for i,fire in pairs(getMissionObjects(mission.data.location, "fire", task.tag)) do
				x,y,z = calcWorldPos(mission, fire)
				addMarker(mission, task.id, createMarker(x, z, task.name, task.desc, 5), task.timeleft)
			end

			local completed = true

			for i, obj in pairs(filterSpawnedObjects(mission.objects, "fire", task.tag)) do
				if server.getFireData(obj.id) then
					completed = false
				end
			end

			if not task.ignore_vehicle then
				for i, vehicle in pairs(filterSpawnedObjects(mission.objects, "vehicle")) do
					if server.getVehicleFireCount(vehicle.id) > 0 then
						completed = false
					end
				end
			end


			if completed then
				logd("all fire gone!")
				-- Remove fire
				for i, fire in pairs(filterSpawnedObjects(mission.objects, "fire", task.tag)) do
					server.despawnObject(fire.id, true)
				end
				completeTask(mission, task)
			end
		end
	},
	-- Rescue survivor: Player need to transport all survivor in location to any hospital, filter by tag
	rescue = {
		init = function(mission, task)
			objectives = filterSpawnedObjects(mission.objects, "character", task.tag)
		end,
		update = function(mission, task)
			objectives = filterSpawnedObjects(mission.objects, "character", task.tag)
			death = 0
			survive = 0
			removeMarker(mission, task.id)
			for i, obj in pairs(objectives) do
				local hp, transform, is_incapacitated, is_dead = server.getCharacterData(obj.id)
				if is_dead then
					death = death + 1
				else
					local x,y,z = matrix.position(transform)
					local zones_survivor = server.getZones("hospital")
					local is_in_zone = isPosInZones(transform, zones_survivor)

					addMarker(mission, task.id, createMarker(x, z, task.name, task.desc, 1), task.timeleft)

					if hp < 100 and hp > 0 and not task.no_bleed then
						bleed_counter = obj.bleed_counter or 0
						index = obj.original_index
						mission.objects[index].bleed_counter = bleed_counter + 1
	
						if bleed_counter > (600 / check_interval) then
							mission.objects[index].bleed_counter = 0
							hp = hp - 1
							server.setCharacterData(obj.id, hp, true)
						end
					end

					-- check zone arrived
					if is_in_zone then
						--server.setCharacterData(obj.id, hp, false)
						server.setCharacterData(obj.id, 100, true)
						survive = survive + 1
					end
				end
			end

			-- Check all survivor dead or transported
			if death + survive == #objectives then
				if survive > 0 then
					logd("rescue completed!")
					for i, obj in pairs(objectives) do
						server.setCharacterData(obj.id, 100, false)
					end
					-- add reward per survivor
					if task.base_reward == nil then task.base_reward = 0 end
					if task.base_research == nil then task.base_research = 0 end

					for i = 1, survive do
						if task.reward_per_survivor then
							task.base_reward = task.base_reward + task.reward_per_survivor
						end
						if task.research_per_survivor then
							task.base_research = task.base_research + task.research_per_survivor
						end
					end

					completeTask(mission, task)
				else
					logd("rescue failed!")
					failTask(mission, task)
				end
			end
		end
	},
	-- Deliver vehicle: Player need to transport all vehicle in location to specified delivery zone, filter by tag
	deliver_vehicle = {
		init = function(mission, task)
		end,
		update = function(mission, task)
			objectives = filterSpawnedObjects(mission.objects, "vehicle", task.delivery_name)
			delivered = 0
			removeMarker(mission, task.id)
			-- add marker target
			local zones = server.getZones(task.delivery_zone)
			local first_zone = firstZone(zones)

			local zone_x, zone_y, zone_z = matrix.position(first_zone.transform)
			addMarker(mission, task.id, createMarker(zone_x, zone_z, task.name, "Delivery to here", 0), task.timeleft)
			
			for i, obj in pairs(objectives) do
				local transform = server.getVehiclePos(obj.id)
				local x,y,z = matrix.position(transform)
				local is_in_zone = isPosInZones(transform, zones)

				addMarker(mission, task.id, createMarker(x, z, task.name, task.desc, 2), task.timeleft)
				--server.addMapLine(-1, 9512+i , first_zone.transform, transform, 1)
				-- check zone arrived
				if is_in_zone then
					delivered = delivered + 1
				end
			end

			if delivered == #objectives then
				logd("deliver completed!")
				completeTask(mission, task)
			end
		end
	},
	-- Deliver survivor: Player need to transport all character in location to specified delivery zone, filter by tag
	deliver_survivor = {
		init = function(mission, task)
		end,
		update = function(mission, task)
			objectives = filterSpawnedObjects(mission.objects, "character", task.tag)
			death = 0
			survive = 0
			removeMarker(mission, task.id)
			for i, obj in pairs(objectives) do
				local hp, transform, is_incapacitated, is_dead = server.getCharacterData(obj.id)
				if is_dead then
					death = death + 1
				else
					local x,y,z = matrix.position(transform)
					local zones_survivor = server.getZones(task.delivery_zone)
					local is_in_zone = isPosInZones(transform, zones_survivor)

					addMarker(mission, task.id, createMarker(x, z, task.name, task.desc, 1), task.timeleft)
	
					if hp < 100 and hp > 0 and not task.no_bleed then
						bleed_counter = obj.bleed_counter or 0
						index = obj.original_index
						mission.objects[index].bleed_counter = bleed_counter + 1
	
						if bleed_counter > (600 / check_interval) then
							mission.objects[index].bleed_counter = 0
							hp = hp - 1
							server.setCharacterData(obj.id, hp, true)
						end
					end

	
					-- check zone arrived
					if is_in_zone then
						server.setCharacterData(obj.id, hp, false)
						survive = survive + 1
					end
				end
			end

			-- Check all survivor dead or transported
			if death + survive == #objectives then
				if survive > 0 then
					logd("rescue completed!")
					completeTask(mission, task)
				else
					logd("rescue failed!")
					failTask(mission, task)
				end
			end
		end
	},
	-- Deliver object: Player need to transport all object in location to specified delivery zone, filter by tag
	deliver_object = {
		init = function(mission, task)
		end,
		update = function(mission, task)
			objectives = filterSpawnedObjects(mission.objects, "object", task.delivery_name)
			delivered = 0
			removeMarker(mission, task.id)
			-- add marker target
			local zones = server.getZones(task.delivery_zone)
			local first_zone = firstZone(zones)

			local zone_x, zone_y, zone_z = matrix.position(first_zone.transform)
			addMarker(mission, task.id, createMarker(zone_x, zone_z, task.name, "Delivery to here", 0), task.timeleft)
			
			for i, obj in pairs(objectives) do
				local found, transform = server.getObjectPos(obj.id)
				local x,y,z = matrix.position(transform)
				local is_in_zone = isPosInZones(transform, zones)

				addMarker(mission, task.id, createMarker(x, z, task.name, task.desc, 2), task.timeleft)
				--server.addMapLine(-1, 9512+i , first_zone.transform, transform, 1)
				-- check zone arrived
				if is_in_zone then
					delivered = delivered + 1
				end
			end

			if delivered == #objectives then
				logd("deliver completed!")
				completeTask(mission, task)
			end
		end
	},
	-- TODO: Remove vehicle
}


----------------
-- CallBack 
----------------

function onTick(delta_worldtime)
	math.randomseed(server.getTimeMillisec() + 3)

	-- spawn random mission
	if server.getTutorial() == false then
		if g_savedata.m_counter <= 0 then
			logd("Spawning mission")
			g_savedata.m_counter = 60 * 60 * math.random(min_mission_interval, max_mission_interval) -- Set next spawn
			spawnRandomMission()
		else
			g_savedata.m_counter = g_savedata.m_counter - delta_worldtime
		end
	end
	-- process task timeleft
	for i,mission in pairs(g_savedata.m_missions) do
		local tasks = currentTask(mission)
		for j, task in pairs(g_savedata.m_missions[i].data.tasks) do
			-- check task timelimit
			if g_savedata.m_missions[i].data.tasks[j].timeleft ~= nil then
				g_savedata.m_missions[i].data.tasks[j].timeleft = task.timeleft - delta_worldtime
			end
			
		end
	end
	-- tick counter process
	tick_counter = tick_counter + 1
	-- Process active task
	if tick_counter >= check_interval then
		for i,mission in pairs(g_savedata.m_missions) do
			local tasks = currentTask(mission)
			local completed_tasks = 0
			local failed_tasks = 0

			-- process task
			for j, task in pairs(tasks) do
				-- check mission timelimit
				if task.timeleft ~= nil and  task.timeleft <= 0 then
					logd("task expired")
					failTask(mission, task)
				end
				if task.completed then
					completed_tasks = completed_tasks + 1
					if task.failed then
						failed_tasks = failed_tasks + 1
					end
				else
					task_type[task.type].update(mission, task)
				end

				-- check all task complete
				if completed_tasks == #tasks then
					-- if all task failed, fail mission
					if completed_tasks == failed_tasks then
						endMission(mission, false)
						return
					end
					-- Init next tasks
					mission.step = mission.step + 1
					initTask(mission)
					-- complete mission if no more task
					if #currentTask(mission) == 0 then
						endMission(mission, true)
					end
				end
			end
		end
		tick_counter = 0
	end
end

function onCustomCommand(message, user_id, admin, auth, command, one, two, three, four, five, six, seven, eight, nine, ten, eleven, twelve, thirteen, fourteen, fifteen)
	if command == "?del_mission" and admin == true  and one == pack_name then
		log("Deleting mission " .. two)
		for i,v in pairs(g_savedata.m_missions) do
			if v.name == two then
				endMission(v, false, true)
				log("mission deleted")
			end
		end
	elseif command == "?spawn" and admin == true and one == pack_name then
		log("Spawn mission")
		startMission(two)
	elseif command == "?spawn_random" and admin == true and one == pack_name then
		log("Spawn random mission")
		spawnRandomMission()
	elseif command == "?missions" and admin == true and one == pack_name then
		--printTable(g_savedata.m_missions, "missions")
		for i,v in pairs(g_savedata.m_missions) do
			--printTable(v.data.tasks, "task")
			log("#" .. v.id .. ": " .. v.name)
		end
	elseif command == "?locations" and admin == true and one == pack_name then
		for i, d in iterLocations(tonumber(one) or 0) do
			-- printTable(d, "location_" .. i)
			log(i .. " => " .. d.name)
		end
	elseif command == "?test" and admin == true and one == pack_name then
		for i,v in pairs(mm_missions) do
			log(i)
		end
	end
end

function onPlayerJoin(steam_id, name, peer_id, admin, auth)
end

function onSpawnMissionObject(id, name, type, playlist_index)
	--logd(id..":"..type..","..name.." #"..playlist_index)
	-- Capture spawned object here, because there is no other way to get "global" object id
	if spawn_mission_id ~= nil then
		o = {
			id = id,
			name = name,
			type = type,
			playlist_index = playlist_index
		}
		table.insert(spawned_object[spawn_mission_id], o)
	end
end

function onCreate()
	-- build mission type location data to save
	if g_savedata.m_missions == nil then
		g_savedata = 
		{ 
			m_counter = 60 * 60,
			m_missions = {},
			m_id = 0,
		}
	end
end

----------------
-- Logic 
----------------

function completeTask(mission, task, silent)
	task.completed = true
	removeMarker(mission, task.id)
	-- check for reward
	local text = task.name
	if task.base_reward ~= nil and task.base_reward > 0 then
		reward = task.base_reward
		server.setCurrency(server.getCurrency() + reward, server.getResearchPoints())
		text = text .. "\nCASH +$" .. reward
	end
	if task.base_research ~= nil and task.base_research > 0 then
		research =  task.base_research
		server.setCurrency(server.getCurrency(), server.getResearchPoints() + research)
		text = text .. "\nRESEARCH +" .. research 
	end
	-- Do not notify if silent == true or has only one task
	if not silent then
		server.notify(-1, "Task completed",  task.name, 4)
	end
end

function failTask(mission, task, silent)
	task.completed = true
	task.failed = true
	removeMarker(mission, task.id)

	-- Do not notify if silent == true or has only one task
	if (not silent) and (#currentTask(mission) > 1) then
		server.notify(-1, "Task failed",  task.name, 2)
	end
end

function spawnRandomMission()
	local mission_count = 0;
	local mission_prob_count = 0;

	math.randomseed(server.getTimeMillisec())
	-- scan and count probality
	for name, data in pairs(mm_missions) do
		if (not data.no_spawn) and (not findActiveMission(name)) then
			mission_count = mission_count + 1
			mission_prob_count = mission_prob_count + (data.probability or 1.0)
			logd("misision-".. name)
		end
	end

	-- select mission
	if mission_count > 0 then
		local random_value = math.random(0, math.floor(mission_prob_count * 100)) / 100
		local selected_mission_name = nil

		for name,data in pairs(mm_missions) do
			if (not data.no_spawn) and (not findActiveMission(name)) then
				prob = data.probability or 1.0
				logd(prob.." "..random_value)
				if random_value > prob then
					random_value = random_value - prob
				else
					logd(name .. " selected")
					selected_mission_name = name
					break
				end
			end
		end
		if selected_mission_name ~= nil then
			startMission(selected_mission_name)
		end
	end

end


function startMission(name)
    mission_id = g_savedata.m_id
    playlist_index = server.getPlaylistIndexCurrent()
    
    -- Check mission data
	if name == nil then
	    log("Mission name not specified")
	    return
	elseif mm_missions[name] == nil then
	    log("Mission not found:" .. name)
	    return
	elseif findActiveMission(name) then
	    logd("Mission already active")
	    return
	end

	-- TODO: max mission count check
	mission = mm_missions[name]
	location = mission.location

    -- Spawn location
	if findLocation(location) == nil then
	    log("Location not found:" .. location)
	    return
	end
	logd("Spawn location")
	spawn_mission_id = mission_id -- to handle object by onSpawnMissionObject
	spawned_object[spawn_mission_id] = {}

	location_index = server.getLocationIndexByName(playlist_index, location)
	pos = server.spawnMissionLocation(matrix.translation(0,0,0),playlist_index, location_index)
	
	spawn_mission_id = nil

	-- Create mission data
	logd("Activating mission")
	local mission_data = {}
	mission_data.id     = mission_id
	mission_data.name   = name
	mission_data.active = true
	mission_data.step   = 0
	mission_data.data = mission
	mission_data.markers = {}
	mission_data.zones = {}
	mission_data.objects = spawned_object[mission_id]
	
	mission_data.x, mission_data.y, mission_data.z = matrix.position(pos)
	
	-- Notify
	server.notify(-1, "New Mission",  mission.title, 0)

	-- Scan and store zone
	for i, o in pairs(getMissionObjects(location, "zone")) do
		x,y,z = calcWorldPos(mission_data, o)

		mission_data.zones[o.name] = {
			x = x,
			y = y,
			z = z
		}
	end
	-- Initialize task
	for k,v in pairs(mission_data.data.tasks) do
		v.id = k
		--v.init = task_type[v.type].init
		--v.update = task_type[v.type].update
		v.completed = false
		if v.timelimit ~= nil then
			v.timeleft = v.timelimit
		end
	end

	logd("pos x=" .. mission_data.x .. " z=" .. mission_data.z)

	-- Store to save
	g_savedata.m_missions[mission_id] = mission_data
	g_savedata.m_id = mission_id + 1

	-- list current task
	for k, v in pairs(currentTask(mission_data)) do
		--printTable(v, "task")
	end
	initTask(mission_data, true)
	logd("Complete")
end

function endMission(mission, completed, quickly)
	-- cleanup marker
	for k,v in pairs(mission.data.tasks) do
		removeMarker(mission, v.id)
	end
	-- despawn object
	despawnObjects(mission.objects, quickly)
	-- cleanup mission
	logd("Clean mission #" .. mission.id)
	for k,v in pairs(g_savedata.m_missions) do
		if v.id == mission.id then
			g_savedata.m_missions[k] = nil
		end
	end
	-- Notify
	if completed then
		local text = mission.data.title
		if mission.data.base_reward ~= nil then
			reward = mission.data.base_reward
			server.setCurrency(server.getCurrency() + reward, server.getResearchPoints())
			text = text .. "\nCASH +$" .. reward
		end
		if mission.data.base_research ~= nil then
			research =  mission.data.base_research
			server.setCurrency(server.getCurrency(), server.getResearchPoints() + research)
			text = text .. "\nRESEARCH +" .. research 
		end
		server.notify(-1, "Mission Completed", text , 4)
	else
		server.notify(-1, "Mission Failed",  mission.data.title, 2)
	end
end

function initTask(mission, is_first_task)
	for k,v in pairs(currentTask(mission)) do
		if not is_first_task then
			server.notify(-1, "Mission Update",  v.name, mission.title)
		end
		task_type[v.type].init(mission, v)
	end
end

function award(reward, research, title, text)
	if reward ~= nil then
		server.setCurrency(server.getCurrency() + reward, server.getResearchPoints())
		text = text .. "\nCASH +$" .. reward
	end
	if research ~= nil then
		server.setCurrency(server.getCurrency(), server.getResearchPoints() + research)
		text = text .. "\nRESEARCH +" .. research 
	end
	server.notify(-1, title, text , 4)
end

function despawnObjects(objects, is_force_despawn)
	for k,v in pairs(objects) do
		if v.type == "vehicle" then
			server.despawnVehicle(v.id, is_force_despawn)
		elseif v.type == "character" then
			server.despawnCharacter(v.id, is_force_despawn)
		else
			server.despawnObject(v.id, is_force_despawn)
		end
	end
end



----------------
-- Util
----------------

-- Map
function addMarker(mission_data, task_id, marker_data, timeleft)
	if mission_data.markers[task_id] == nil then
		mission_data.markers[task_id] = {}
	end

	if timeleft ~= nil then
		marker_data.timeleft = timeleft
	end

	table.insert(mission_data.markers[task_id], marker_data)
	showMarker(marker_data)
end

function showMarker(marker_data, peer_id)
	label = marker_data.hover_label
	if marker_data.timeleft ~= nil then
		label = label .. " (" .. calcLeftTime(marker_data.timeleft)  .. ")"
	end

	server.addMapObject(peer_id or -1, marker_data.id, 0, marker_data.type, marker_data.x, 100, marker_data.z, 0, 0, 0, 0, 0, marker_data.display_label, 0, marker_data.radius, label)
end

function removeMarker(mission_data, task_id)
	-- skip if marker nil
	if mission_data.markers[task_id] == nil then return end

	for i,marker in pairs(mission_data.markers[task_id]) do
		server.removeMapObject(-1, marker.id)
	end
end

function createMarker(x, z, display_label, hover_label, type)	
	local map_id = server.getMapID()

	return { 
		id = map_id, 
		type = type,
		x = x, 
		z = z, 
		radius = 1, 
		display_label = display_label, 
		hover_label = hover_label 
	}
end

-- Logic
function calcWorldPos(mission, obj)
	x,y,z = matrix.position(obj.transform)
	x = mission.x + x
	y = mission.y + y
	z = mission.z + z
	return x, y, z
end

function calcLeftTime(time)
	if time < 3600 then return "0m" end
	sec = math.floor(time / 60)
	min = math.floor(sec / 60)
	if min >= 60 then
		hour = math.floor(min / 60)
		min = min % 60
		return hour .. "h " .. min .. "m"
	else
		return min .. "min"
	end
end

function firstZone(zones)
	for k, v in pairs(zones) do
		return v
	end

	return nil
end

function isPosInZones(transform, zones)
	for k, v in pairs(zones) do
		if server.isInZone(transform, v.name) then
			return true
		end
	end

	return false
end

function playerIsInZone(zone, radius)
	local players = server.getPlayers()

	for player_index, player_object in pairs(players) do
		local player_transform = server.getPlayerPos(player_object.id)
		-- zone exist in mission
		dest = zone

		if dest ~= nil then
			-- check zone
			local x,y,z = matrix.position(player_transform)
			local dist = ( ((dest.x - x) ^2) + ((dest.z - z)^2) ) ^ 0.5

			if (dist <= radius) then
				return true
			end
		else
			log("zone not found:"..zone)
		end
	end

	return false
end


function filterSpawnedObjects(spawned_object, type, name)
	result = {}
	for i,o in pairs(spawned_object) do
		if o.type == type then
			if name == nil or o.name == name then
				o.original_index = i
				table.insert(result, o)
			end
		end
	end
	return result
end

function getMissionObjects(location, type, tag)
	result = {}
	-- Check object data
	playlist_index = server.getPlaylistIndexCurrent()
	location_index = server.getLocationIndexByName(playlist_index, location)
	location_data = server.getLocationData(playlist_index, location_index)

	-- Scan 
	for i=0, location_data.object_count-1 do
		o = server.getLocationObjectData(playIist_index, location_index, i)
		-- filter by type
		if o.type == type or type == nil then
			if tag ~= nil then
				-- filter by tag
				for j,t in pairs(o.tags) do
					if t == tag then
						table.insert( result, o )
						break
					end
				end
			else
				-- no filter specified
				table.insert( result, o )
			end
		end
	end
	return result
end

function getZone(name)
	zones = {}
	all_zones = server.getZones()

	-- find tag
	for k, v in pairs(all_zones) do
		for i, j in pairs(v.tags) do
			if j == name then
				logd("Zone found:"..j)
				table.insert(zones, v)
			end
		end
	end

	logd("zone count:" .. #zones)
	if zones ~= nil and #zones > 0 then
		if #zones > 1 then
			logd("Warning: multiple zone found")
		end
		--printTable(zones, "zones")

		return table.remove(zones)
	else
		log("Zone " .. name .. " not found")
	end
end

function currentTask(mission_data)
    result = {}
    for k, v in pairs(mission_data.data.tasks) do
        if (v.step == mission_data.step) then
            table.insert(result, v)
        end
    end
    return result
end

function iterLocations()
	local playlist_data = server.getPlaylistData(server.getPlaylistIndexCurrent())
	local location_count = 0
	if playlist_data ~= nil then location_count = playlist_data.location_count end
	local location_index = 0
	
	return function()
		local location_data = nil
		local index = location_count

		while location_data == nil and location_index < location_count do
			location_data = server.getLocationData(playlist_index, location_index)
			index = location_index
			location_index = location_index + 1
		end

		if location_data ~= nil then
			return index, location_data
		else
			return nil
		end
	end
end

function findLocation(name)
    return server.getLocationIndexByName(server.getPlaylistIndexCurrent(), name)
end

function findActiveMission(name)
	for k, v in pairs(g_savedata.m_missions) do
      if v.name == name then
		logd(v.name .. "__" .. name)
        return true
      end
    end
    return false
end

-- Debug utils

function tableLength(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

function printTable(table, name, m)
	local margin = m or ""

	if tableLength(table) == 0 then
		server.announce("", margin .. name .. " = {}")
	else
		server.announce("", margin .. name .. " = {")
		
		for k, v in pairs(table) do
			local vtype = type(v)

			if vtype == "table" then
				printTable(v, k, margin .. "    ")
			elseif vtype == "string" then
				server.announce("", margin .. "    " .. k .. " = \"" .. tostring(v) .. "\",")
			elseif vtype == "number" or vtype == "function" or vtype == "boolean" then
				server.announce("", margin .. "    " .. k .. " = " .. tostring(v) .. ",")
			else
				server.announce("", margin .. "    " .. k .. " = " .. tostring(v) .. " (" .. type(v) .. "),")
			end
		end

		server.announce("", margin .. "},")
	end
end

function log(text)
	server.announce("[MM]", text)
end

function logd(text)
	if debug then
		server.announce("[MM-d]", text)
	end
end