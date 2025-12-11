local class = {} -- handles intermission + map picking

local rs = game:GetService('ReplicatedStorage')

function class:new(intermission_time : seconds)
	local self = setmetatable({}, {__index = class})
	self.intermission_time = intermission_time
	return self
end

local function mmss(seconds: number) -- converts to m:ss
	return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

function class:intermission_begin()
	local main_timer_value = rs:WaitForChild('Round'):WaitForChild('vals'):WaitForChild('main_timer')
	local map_value = rs:WaitForChild('Round'):WaitForChild('vals'):WaitForChild('map_store')
	map_value.Value = 'Intermission'
	for i = self.intermission_time, 1, -1 do
		print(i)
		main_timer_value.Value = mmss(i)
		task.wait(1)
	end
end

function class:pick_map(map_folder : Folder)
	print('loaded pick map system [server]')
	local map_value = rs:WaitForChild('Round'):WaitForChild('vals'):WaitForChild('map_store')
	local rand = Random.new()
	local map = map_folder:GetChildren()[rand:NextInteger(1, #map_folder:GetChildren())] -- picks a random map
	print('picked a map [server] | ' .. map.Name)
	map_value.Value  = 'Intermission'
	return map
end

function class:load_map(map_folder : Folder)
	print('LOADED MAP SUCCESSFULLY!')
	local map =  self:pick_map(map_folder)
	local cloned_version = map:Clone()
	local orig_name = cloned_version.Name
	cloned_version.Parent = workspace
	cloned_version.Name = 'CURRENT_MAP'
	cloned_version:SetAttribute('MapName', orig_name)
end

return class
