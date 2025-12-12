local rs = game:GetService('ReplicatedStorage')

local function mmss(seconds: number)
	return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

-- intermission
local function intermission_begin(intermission_time)
  
	local main_timer_value = rs:WaitForChild('Round'):WaitForChild('vals'):WaitForChild('main_timer')
	local map_value = rs:WaitForChild('Round'):WaitForChild('vals'):WaitForChild('map_store')
	map_value.Value = 'Intermission'
	for i = intermission_time, 1, -1 do
		print(i)
		main_timer_value.Value = mmss(i)
		task.wait(1)
	end
  
end

local function pick_map(map_folder : Folder)
	print('loaded pick map system [server]')
	local map_value = rs:WaitForChild('Round'):WaitForChild('vals'):WaitForChild('map_store')
	local rand = Random.new()
	local children = map_folder:GetChildren()
	local map = children[rand:NextInteger(1, #children)]
	print('picked a map [server] | ' .. map.Name)
	map_value.Value  = 'Intermission'
  
	return map
end

local function load_map(map_folder : Folder)
	print('LOADED MAP SUCCESSFULLY!')
	local map = pick_map(map_folder)
	local cloned_version = map:Clone()
	local orig_name = cloned_version.Name
	cloned_version.Parent = workspace
	cloned_version.Name = 'CURRENT_MAP'
	cloned_version:SetAttribute('MapName', orig_name)
end

-- HANDLES players

----------------

local players = game:GetService('Players')
local rs_main = game:GetService('ReplicatedStorage')
local events = rs_main:WaitForChild('Round'):WaitForChild('RoundEvents')

-- testing
local function teleport_players_placeholder(users_in_round, location, player) end
local function choose_teams_placeholder(users_in_round, player) end
local function START_ROUND_placeholder(timer, mapname) end
local function set_tag_placeholder(player, team) end
local function END_ROUND_placeholder(users_in_round, map, player) end
local function round_sound_tracks_placeholder(map) end

-- modules --
local ROUND_SETTINGS  = require(rs_main:WaitForChild('Round'):WaitForChild('SETTINGS'))

------------------

local function transtion_check()
	local transition_bool = rs_main:WaitForChild('Round'):WaitForChild('vals'):WaitForChild('ext'):WaitForChild('bools'):WaitForChild('transition_done')
	transition_bool.Changed:Connect(function(val : boolean)
	--	print('changed to ' .. val)
		if val == false then
			print('FALSEEE')
		else
			print('transitioning now.. [main_module]')
		end
	end)
	return transition_bool.Value
end

players.PlayerAdded:Connect(function(plr : Player)
	local lobby_folder = workspace:WaitForChild('Lobby', 3)
	local spawns = lobby_folder:WaitForChild('Spawns')
	plr.CharacterAdded:Connect(function(char : Character)
		local spawn_folder = game:GetService('ServerStorage'):FindFirstChild('SPAWN_DATA')
		if spawn_folder and spawn_folder:FindFirstChild(plr.UserId) then
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
end)

local ss = game:GetService('ServerStorage')
local map_folder = ss:WaitForChild('Round'):WaitForChild('Maps')

-- spawn stuff
local Teams = game:GetService('Teams')
local function save_spawn(map : Folder, player : Player)
	print('loaded')
	local GAME_VALUE = player:FindFirstChild('GAME_TAG')
	if not GAME_VALUE then  
		warn('no game val ')
		return 
	end
	local spawns = {
		red_spawns = map:FindFirstChild('RedSpawns'),
		blue_spawns = map:FindFirstChild('BlueSpawns')
	}
  
	if not spawns.red_spawns or not spawns.blue_spawns then return end
	print('passed check')
	local spawn_storage = ss:FindFirstChild('SPAWN_DATA')
	if not spawn_storage then
		spawn_storage = Instance.new('Folder')
		spawn_storage.Name = 'SPAWN_DATA'
		spawn_storage.Parent = ss
	end
  
	local player_id = tostring(player.UserId)
  
	local function create_player_data()
		local data = spawn_storage:FindFirstChild(player_id)
		if not data then
			data = Instance.new('StringValue')
			data.Name = player_id
			data.Value = player.Team and player.Team.Name or "None"
			data.Parent = spawn_storage
		end
		return data
	end
  
	local function handle_respawn()
		player.CharacterAdded:Connect(function(char)
			print('dead')
			local data = spawn_storage:FindFirstChild(player_id)
			if not data or not data:IsA('StringValue') then
				warn('no player data found')
				return
			end

			local hrp = char:WaitForChild('HumanoidRootPart', 5)
			if not hrp then
				warn('no hrp')
				return
			end

			if data.Value == 'Red' then
				print('respawning')
				local redList = spawns.red_spawns:GetChildren()
				if #redList > 0 then
					local random_spawn = redList[math.random(1, #redList)]
					hrp.CFrame = random_spawn.CFrame
				end
			elseif data.Value == 'Blue' then
				print('respawning')
				local blueList = spawns.blue_spawns:GetChildren()
				if #blueList > 0 then
					local random_spawn = blueList[math.random(1, #blueList)]
					hrp.CFrame = random_spawn.CFrame
				end
			else
				warn('not red or blue')
			end
		end)
	end
  
	for _, spawn_loc in pairs(spawns.red_spawns:GetChildren()) do
		spawn_loc.Touched:Connect(function(hit)
			print('touched')
			if spawn_loc.Parent ~= spawns.red_spawns then return end
			print('2x')

			if player.Team == Teams:FindFirstChild('Red') then
				create_player_data()
				local char = player.Character
				if not char then warn('no char') return end
				handle_respawn()
			else
				warn('NOT ON RED TEAM | ON BLUE TEAM/LOBBY TEAM')
			end
		end)
	end
  
	for _, spawn_loc in pairs(spawns.blue_spawns:GetChildren()) do
		spawn_loc.Touched:Connect(function(hit)
			if spawn_loc.Parent ~= spawns.blue_spawns then return end
			print('touched blue')

			if player.Team == Teams:FindFirstChild('Blue') then
				print('e')
				create_player_data()
				local char = player.Character
				if not char then warn('no char') return end
				handle_respawn()
			else
				warn('NOT ON BLUE TEAM | ON RED TEAM/LOBBY TEAM')
			end
		end)
    
	end
end

-- round_mod
local function change_state(new_state : string)
	local timer_val = rs_main:WaitForChild('Round'):WaitForChild('vals'):WaitForChild('main_timer')
	timer_val.Value = new_state
end

local function transition(event : RemoteEvent, players_in_round : table)
	local transition_bool = rs_main:WaitForChild('Round'):WaitForChild('vals'):WaitForChild('ext'):WaitForChild('bools'):WaitForChild('transition_done')
	transition_bool.Value = true
	event:FireAllClients(players_in_round)
	task.wait(3.1)
	transition_bool.Value = false
end

local function handle_spawning(player : Player)
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

local function intermission_func(val : StringValue)
	print('loaded intermission [server]')
	load_map(map_folder)
	intermission_begin(val)
end

local function teleport_players_func(users_in_round : table, location : Folder, player : Player)
	teleport_players_placeholder(users_in_round, location, player)
end

local function set_team_func(users_in_round : table, player : Player)
	choose_teams_placeholder(users_in_round, player)
end

local function set_tag_func(player : Player)
	change_state('Loading..')
	set_tag_placeholder(player, player.Team)
end

local function handle_users_func(map : Folder, player : Player)
	save_spawn(map, player)
end

local function start_round_func(users_in_round : table, timer : secs)
	START_ROUND_placeholder(timer, workspace:WaitForChild('CURRENT_MAP', 10):GetAttribute('MapName'))
end

local function sound_tracks_func(map : Folder)
	round_sound_tracks_placeholder(map)
end

local function end_round_func(users_in_round : table, map : Folder, player : Player)
	END_ROUND_placeholder(users_in_round, map, player)
end

-- main handler
local function main()
	players.PlayerAdded:Connect(function(plr : Player)
		handle_spawning(plr)
	end)

	while true do
		local users_in_game = {}
		repeat
			users_in_game = {}
			for _, p in pairs(players:GetPlayers()) do
				table.insert(users_in_game, p)
			end
			print(#users_in_game)
			task.wait(0.3)
		until #users_in_game >= 1

		print('continuing')
		local players_in_round = {}
		for i, player in pairs(players:GetPlayers()) do
			table.insert(players_in_round, player)
			print(players_in_round)
		end

		intermission_func(ROUND_SETTINGS.ROUND_SETTINGS.INTERMISSION_TIME)

		local current_map = workspace:FindFirstChild('CURRENT_MAP')
		if not current_map then
			current_map = workspace:WaitForChild('CURRENT_MAP', 10)
		end

		for ind, plr in pairs(players_in_round) do
			set_team_func(players_in_round, plr)
			set_tag_func(plr)
		end

		transition(events:WaitForChild('client'):WaitForChild('TransitionClient'), players_in_round)

		for _, plr in pairs(players_in_round) do
			teleport_players_func(players_in_round, current_map, plr)
			handle_users_func(current_map, plr)
		end

		if transtion_check() == false then
			sound_tracks_func(current_map)
			start_round_func(players_in_round, ROUND_SETTINGS.ROUND_SETTINGS.ROUND_TIME)
		else
			warn('well oops')
		end

		for _, plr in pairs(players_in_round) do
			end_round_func(players_in_round, current_map, plr)
		end
	end
end

main()
