-- HANDLES players

----------------

local players = game:GetService('Players')
local rs = game:GetService('ReplicatedStorage')
local events = rs:WaitForChild('Round'):WaitForChild('RoundEvents')

-- modules --

local main_mod = require(script.modules.main_module)
local ROUND_SETTINGS  = require(rs:WaitForChild('Round'):WaitForChild('SETTINGS'))

------------------

local function transtion_check()
	local transition_bool = rs:WaitForChild('Round'):WaitForChild('vals'):WaitForChild('ext'):WaitForChild('bools'):WaitForChild('transition_done')
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
	main_mod.handle_spawning(plr)
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
	----
	local players_in_round = {}
--	local PLAYER_IN_GAME = nil
	for i, player in pairs(players:GetPlayers()) do
		table.insert(players_in_round, player)
	--	PLAYER_IN_GAME = player
		print(players_in_round)
	end
	
	main_mod.intermission(ROUND_SETTINGS.ROUND_SETTINGS.INTERMISSION_TIME)
	----------------------------------------
	
	local current_map = workspace:FindFirstChild('CURRENT_MAP')
	if not current_map then
		current_map = workspace:WaitForChild('CURRENT_MAP', 10)
	end
	
	for ind, plr in pairs(players_in_round) do
		main_mod.set_team(players_in_round, plr)
		main_mod.set_tag(plr)
	end
	main_mod.transition(events:WaitForChild('client'):WaitForChild('TransitionClient'), players_in_round)

	for _, plr in pairs(players_in_round) do
		main_mod.teleport_players(players_in_round, current_map, plr) -- teleports to map
		main_mod.handle_users(current_map, plr)
	end
	
	if transtion_check() == false then
		main_mod.sound_tracks(current_map)
		main_mod.start_round(players_in_round, ROUND_SETTINGS.ROUND_SETTINGS.ROUND_TIME)
	else
		warn('well oops')
	end
	
	for _, plr in pairs(players_in_round) do
		main_mod.end_round(players_in_round, current_map, plr)
	end
end
