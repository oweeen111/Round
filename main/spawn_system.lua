--[[

	owner - @GwinanTheApple
	DO NOT SHARE WITH ANYONE PLEASE! THIS IS SMALLTORCH WORK!

]]

local class = {}

local SS = game:GetService('ServerStorage')
local Teams = game:GetService('Teams')

function class:new(map : Folder, player : Player)
	local self = setmetatable({}, {__index = class})
	self.map = map
	self.player = player
	self.player_id = tostring(player.UserId)
	return self
end

function class:save_spawn()
	print('loaded')
	local GAME_VALUE = self.player:FindFirstChild('GAME_TAG')
	if not GAME_VALUE then  
		warn('no game val ')
		return 
	end
	local spawns = {
		red_spawns = self.map:FindFirstChild('RedSpawns'),
		blue_spawns = self.map:FindFirstChild('BlueSpawns')
	}
	if not spawns.red_spawns or not spawns.blue_spawns then return end
	print('passed check')
	local spawn_storage = SS:FindFirstChild('SPAWN_DATA')
	if not spawn_storage then
		spawn_storage = Instance.new('Folder')
		spawn_storage.Name = 'SPAWN_DATA'
		spawn_storage.Parent = SS
	end
	local function create_player_data()
		local data = spawn_storage:FindFirstChild(self.player_id)
		if not data then
			data = Instance.new('StringValue')
			data.Name = self.player_id
			data.Value = self.player.Team and self.player.Team.Name or "None"
			data.Parent = spawn_storage
		end
		return data
	end
	local function handle_respawn()
		self.player.CharacterAdded:Connect(function(char)
			print('dead')
			local data = spawn_storage:FindFirstChild(self.player_id)
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
	-- connect red spawns
	for _, spawn_loc in pairs(spawns.red_spawns:GetChildren()) do
		spawn_loc.Touched:Connect(function(hit)
			print('touched')
			if spawn_loc.Parent ~= spawns.red_spawns then return end
			print('2x')

			if self.player.Team == Teams:FindFirstChild('Red') then
				create_player_data()
				local char = self.player.Character
				if not char then warn('no char') return end
				handle_respawn()
			else
				warn('NOT ON RED TEAM | ON BLUE TEAM/LOBBY TEAM')
			end
		end)
	end
	-- connect blue spawns
	for _, spawn_loc in pairs(spawns.blue_spawns:GetChildren()) do
		spawn_loc.Touched:Connect(function(hit)
			if spawn_loc.Parent ~= spawns.blue_spawns then return end
			print('touched blue')

			if self.player.Team == Teams:FindFirstChild('Blue') then
				print('e')
				create_player_data()
				local char = self.player.Character
				if not char then warn('no char') return end
				handle_respawn()
			else
				warn('NOT ON BLUE TEAM | ON RED TEAM/LOBBY TEAM')
			end
		end)
	end
end

return class

-- work on this later
