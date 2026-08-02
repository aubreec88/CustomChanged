--!optimize 2
--!native

type ChangedData = {
	TrackedInstance:Instance,
	TrackedProperty:string,
	
	Callback:(...any?)->(...any?)?,
}

type CreatedData = {
	TrackedInstance:Instance,
	TrackedProperty:string,

	Callback:(...any?)->(...any?)?,
	
	Connected:boolean,
}

local Main = {}
Main.__index = Main

export type Changeful = typeof(setmetatable({} :: CreatedData, Main))

-- Creates the base that will be used for the connection. <butter>
function Main.Create(Values:ChangedData):Changeful
	local meta:Changeful = setmetatable({
		TrackedInstance = Values.TrackedInstance,
		TrackedProperty = Values.TrackedProperty,
		
		Callback = Values.Callback,
		
		Connected = true,
	} :: CreatedData, Main) :: Changeful
	
	-- Automatically garbage collection. <butter>
	Values.TrackedInstance.Destroying:Once(function()
		meta:Disconnect()
	end)
	
	return meta
end

local function GetCurrentValue(self:Changeful)
	return self.TrackedInstance[self.TrackedProperty]
end

-- This kinda seemed like the best way to do it so.... <butter>
local function forceLoop(self:Changeful)
	local lastValue = GetCurrentValue(self)
	
	repeat task.wait() until lastValue ~= GetCurrentValue(self) or not self.Connected
	
	if not self.Connected then
		return
	end
	
	self.Callback(GetCurrentValue(self))
	
	forceLoop(self)
end

-- Triggers as long as you don't disconnect it. <butter>
function Main.Connect(self:Changeful)
	task.spawn(function()
		self.Connected = true
		
		forceLoop(self)
	end)
end

-- Triggers only once. <butter>
function Main.Once(self:Changeful)
	task.spawn(function()
		self.Connected = true
		
		local lastValue = GetCurrentValue(self)
		
		repeat task.wait() until lastValue ~= GetCurrentValue(self) or not self.Connected
		
		if not self.Connected then
			return
		end
		
		self.Callback(self.TrackedInstance[self.TrackedProperty])
		
		self:Disconnect()
		
		return
	end)
end

function Main.Disconnect(self:Changeful)
	self.Connected = false
end

return Main
