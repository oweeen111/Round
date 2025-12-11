local round_mod = {} -- handles all classes

-- services --

local ss = game:GetService('ServerStorage')
local rs = game:GetService('ReplicatedStorage')

-- variables --

local map_folder = ss:WaitForChild('Round'):WaitForChild('Maps')

-- classes --

local classes_folder = script.Parent.Parent:WaitForChild('classes')

local intermission_class = require(classes_folder:WaitForChild('intermission_class'))
local teleport_class = require(classes_folder:WaitForChild('teleport_class'))
local spawn_class = require(classes_folder:WaitForChild('spawn_class')) -- handles spawn data so u dont spawn in the wrong place
local round_class = require(classes_folder:WaitForChild('startround_class'))
local tags_class = require(classes_folder:WaitForChild('tags_class'))
local end_class = require(classes_folder:WaitForChild('end_class'))
local sound_tracks_class = require(classes_folder:WaitForChild('ext_classes'):WaitForChild('sound_tracks'))

----functions------

local function change_state(new_state : string)
	local timer_val = rs:WaitForChild('Round'):WaitForChild('vals'):WaitForChild('main_timer')
	timer_val.Value = new_state
end

function round_mod.transition(event : RemoteEvent, players_in_round : table) : server
	local transition_bool = rs:WaitForChild('Round'):WaitForChild('vals'):WaitForChild('ext'):WaitForChild('bools'):WaitForChild('transition_done')
	transition_bool.Value = true
	event:FireAllClients(players_in_round)
	task.wait(3.1)
	transition_bool.Value = false
end

function round_mod.handle_spawning(player : Player)
	local lobby_folder = workspace:WaitForChild('Lobby', 3)
	local spawns = lobby_folder:WaitForChild('Spawns')
	player.CharacterAdded:Connect(function(char : Character)
		local spawn_folder = ss:FindFirstChild('SPAWN_DATA')
		if spawn_folder and spawn_folder:FindFirstChild(player.UserId) then
			warn('found user')
			return
		end
		local hrp = char:FindFirstChild('HumanoidRootPart')
		if not hrp then
			hrp = char:WaitForChild('HumanoidRootPart', 10)
		end
		local random_spawn = spawns:GetChildren()[math.random(1, #spawns:GetChildren())]
		hrp.CFrame = random_spawn.CFrame
	end)
end

function round_mod.intermission(val : StringValue)
	print('loaded intermission [server]')
	local int_obj = intermission_class:new(val)
	int_obj:load_map(map_folder) -- pick at the same time as intermission to avoid issues with teleporting people [until i add voting]
	int_obj:intermission_begin()
end

function round_mod.teleport_players(users_in_round : table, location : Folder, player : Player) -- spawn locations folder for map
	local transition_bool = rs:WaitForChild('Round'):WaitForChild('vals'):WaitForChild('ext'):WaitForChild('bools'):WaitForChild('transition_done')
	local tel_obj = teleport_class:new(users_in_round)
	tel_obj:teleport_players(location, player)
end

function round_mod.set_team(users_in_round : table, player : Player)
	local round_obj = round_class:new(users_in_round)
	round_obj:choose_teams(player)
end

function round_mod.set_tag(player : Player)
	change_state('Loading..')
	local tag_obj = tags_class:new(player)
	tag_obj:set_tag(player.Team)
end

function round_mod.handle_users(map : Folder,player : Player)
	local spawn_obj = spawn_class:new(map, player)
	spawn_obj:save_spawn()
end

function round_mod.start_round(users_in_round : table, timer : secs)
	local round_obj = round_class:new(users_in_round)
	local MAP = workspace:WaitForChild('CURRENT_MAP', 10)
	round_obj:START_ROUND(timer, MAP:GetAttribute('MapName'))
end

function round_mod.sound_tracks(map : Folder)
	local sound_obj = sound_tracks_class:new(map)
	sound_obj:round_sound_tracks()
end

function round_mod.end_round(users_in_round : table, map : Folder, player : Player)
	local end_obj = end_class:new(users_in_round)
	end_obj:END_ROUND(map, player)
end

--------------------

return round_mod
