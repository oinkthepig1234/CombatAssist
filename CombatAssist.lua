local CombatAssist = {
	Settings = {
		TriggerBot = {
			Enabled = false,
			IncludeSilentAimFov = false,
			UseRay = {
				Value = false,
				Params = RaycastParams.new(), --you should prolly change this and if you doing based on exclusion add the character to that list
				RayCastPart = workspace.CurrentCamera --this should generally work in first person shooters however if ur using like freecam or something like that u might want to switch to like the gun part or head
			},
			IgnoreNpcs = false --if set to true it will check for players
		}
	},
	Signals = {}
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.Camera

local TriggerBotConfig = CombatAssist.Settings.TriggerBot

local OldTriggerbotTarget = nil

local Connections = {}

local Bindables = {
	["NewTarget"] = Instance.new("BindableEvent")
}

local Signals = {
	["NewTarget"] = {}
}

local CurrentTargetInfo = {}

local function Connect(SignalName:String, Callback:Function)
	local ConnectionTable = Connections[SignalName]
	if not ConnectionTable then
		ConnectionTable = {}
		Connections[SignalName] = ConnectionTable
	end
	if table.find(ConnectionTable, Callback) then
		return
	end
	table.insert(ConnectionTable, Callback)
	local Connection = {Connected = true}
	function Connection:Disconnect()
		if not Connection.Connected then
			warn("Connection is Already Disconnected")
			return
		end
		table.remove(ConnectionTable, table.find(ConnectionTable, Callback))
	end
	return Connection
end

local function FireSignal(Signal, ...)
	Bindables[Signal]:Fire(...)
	if not Connections[Signal] then
		return
	end
	for i,v in pairs(Connections[Signal]) do
		task.spawn(v, ...)
	end
end

local function Heartbeat()
	if TriggerBotConfig.Enabled == false then
		return
	end
	if not Mouse.Target then
		return
	end
	local Target = (not TriggerBotConfig.UseRay.Value and Mouse.Target) or workspace:Raycast(TriggerBotConfig.UseRay.RayCastPart.CFrame.Position, Vector3.new(TriggerBotConfig.UseRay.RayCastPart.CFrame:ToEulerAnglesXYZ()), TriggerBotConfig.UseRay.Params)
	local HitPart = (TriggerBotConfig.UseRay.Value and (Target.Instance or 1)) or Target
	if HitPart == 1 then
		return
	end
	if HitPart.Parent == OldTriggerbotTarget then
		
		return
	end
	if not HitPart.Parent:FindFirstChild("Humanoid") then
		return
	end
	if TriggerBotConfig.IgnoreNpcs and not Players:GetPlayerFromCharacter(HitPart.Parent) then
		return
	end
	OldTriggerbotTarget = HitPart.Parent
	CurrentTargetInfo.StillTargeting = false
	CurrentTargetInfo = {
		StillTargeting = true,
		HitPart = HitPart,
		Distance = (TriggerBotConfig.UseRay.Value and Target.Distance) or (Mouse.Hit - TriggerBotConfig.UseRay.RayCastPart.CFrame.Position).Magnitude
	}
	FireSignal("NewTarget", HitPart.Parent, CurrentTargetInfo)
end

RunService.Heartbeat:Connect(Heartbeat)

for i,v in pairs(Signals) do
	function v:Connect(...)
		return Connect(i, ...)
	end
	function v:Wait()
		return Bindables[i].Event:Wait()
	end
	CombatAssist.Signals[i] = v
end

return CombatAssist
