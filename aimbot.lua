-- Preventing Multiple Processes

if not LPH_OBFUSCATED and not LPH_JIT_ULTRA then
	LPH_JIT_ULTRA = function(f) return f end
	LPH_JIT_MAX = function(f) return f end
	LPH_JIT = function(f) return f end
	LPH_ENCSTR = function(s) return s end
	LPH_STRENC = function(s) return s end
	LPH_CRASH = function() while true do end return end
end

pcall(function()
	getgenv().Aimbot.Functions:Exit()
end)

-- Environment

getgenv().Aimbot = {}
local Environment = getgenv().Aimbot

-- Services

local RunService 		= game:GetService("RunService")
local UserInputService 	= game:GetService("UserInputService")
local HttpService 		= game:GetService("HttpService")
local TweenService 		= game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UniversalTables 	= require(ReplicatedStorage.Modules:WaitForChild("UniversalTables"))
local StarterGui 		= game:GetService("StarterGui")
local Players 			= game:GetService("Players")
local Camera 			= game:GetService("Workspace").CurrentCamera

local mt = getrawmetatable(game)
setreadonly(mt, false)

-- Break solters anti cheat
local badremote = game.ReplicatedStorage.Remotes:WaitForChild("\208\149rrrorLog")
badremote:Destroy()

-- Variables

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Title = "Exunys Developer"
local FileNames = {"Aimbot", "Configuration.json", "Drawing.json"}
local RequiredDistance = math.huge
local Typing = false
local Running = false
local Animation = nil
local ServiceConnections = {RenderSteppedConnection = nil, InputBeganConnection = nil, InputEndedConnection = nil, TypingStartedConnection = nil, TypingEndedConnection = nil}
local IsPartVisible = loadstring(game:HttpGet("https://raw.githubusercontent.com/TechHog8984/TechHub-V3/main/script/misc/ispartvisible.lua"))()
local mousemoverel = mousemoverel or (Input and Input.MouseMove)



-- Support Functions

-- local badremote = game.ReplicatedStorage.Remotes:WaitForChild("\208\149rrrorLog")
-- badremote:Destroy()

-- Script Settings

Environment.Settings = {
	SendNotifications = true,
	SaveSettings = false, -- Re-execute upon changing
	ReloadOnTeleport = true,
	Enabled = false,
	TargetLock = false, -- Script will relock to the closet person if locked if false
	SilentAimEnabled = false,
	SilentAimMisschance = 0,
	TeamCheck = false,
	AliveCheck = true,
	WallCheck = false, -- Laggy
	Sensitivity = 0, -- Animation length (in seconds) before fully locking onto target
	ThirdPerson = false, -- Uses mousemoverel instead of CFrame to support locking in third person (could be choppy)
	ThirdPersonSensitivity = 3, -- Boundary: 0.1 - 5
	TriggerKey = "MouseButton2",
	SnapLines = false,
	SnapLineColor = "255, 0, 0",
	Prediction = false,
	PredictionMultiplier = 20,
	MaxDistance = 1000,
	AiAimbotEnabled = false,
	WallBang = false,
	WallType = "Wood",
	WallTypes = {"Wood", "WoodPlanks", "Fabric", "CorrodedMetal", "Plastic"},
	Toggle = false,
	LockPart = "Head", -- Body part to lock on
	AILocked = false
}

Environment.FOVSettings = {
	Enabled = false,
	Visible = true,
	Amount = 90,
	Color = "255, 255, 255",
	LockedColor = "255, 0, 0",
	Transparency = 0.5,
	Sides = 60,
	Thickness = 1,
	Filled = false
}

Environment.FOVCircle = Drawing.new("Circle")
Environment.SnapLine  = Drawing.new("Line")
Environment.Locked    = nil

-- Core Functions

local function Encode(Table)
	if Table and type(Table) == "table" then
		local EncodedTable = HttpService:JSONEncode(Table)

		return EncodedTable
	end
end

local function Decode(String)
	if String and type(String) == "string" then
		local DecodedTable = HttpService:JSONDecode(String)

		return DecodedTable
	end
end

local function GetColor(Color)
	local R = tonumber(string.match(Color, "([%d]+)[%s]*,[%s]*[%d]+[%s]*,[%s]*[%d]+"))
	local G = tonumber(string.match(Color, "[%d]+[%s]*,[%s]*([%d]+)[%s]*,[%s]*[%d]+"))
	local B = tonumber(string.match(Color, "[%d]+[%s]*,[%s]*[%d]+[%s]*,[%s]*([%d]+)"))

	return Color3.fromRGB(R, G, B)
end

local function SendNotification(TitleArg, DescriptionArg, DurationArg)
	if Environment.Settings.SendNotifications then
		StarterGui:SetCore("SendNotification", {
			Title = TitleArg,
			Text = DescriptionArg,
			Duration = DurationArg
		})
	end
end

-- Functions

local function SaveSettings()
	if Environment.Settings.SaveSettings then
		if isfile(Title.."/"..FileNames[1].."/"..FileNames[2]) then
			writefile(Title.."/"..FileNames[1].."/"..FileNames[2], Encode(Environment.Settings))
		end

		if isfile(Title.."/"..FileNames[1].."/"..FileNames[3]) then
			writefile(Title.."/"..FileNames[1].."/"..FileNames[3], Encode(Environment.FOVSettings))
		end
	end
end

-- Check if key is being held down
local function IsDown(EnumItem)
	return (EnumItem.EnumType == Enum.KeyCode and UserInputService:IsKeyDown(EnumItem)) or (EnumItem.EnumType == Enum.UserInputType and UserInputService:IsMouseButtonPressed(EnumItem))
end

-- Get the wall type the mouse is over
Mouse.Move:Connect(function()
	if Environment.Settings.WallBang then
		out = (tostring(Mouse.Target.Material)):gsub("Enum.Material.", "")
		Environment.Settings.WallType = out
	end
end)


-- Return the closest player to the mouse
local function GetClosestPlayer()
	-- Get the closest player
	local ClosestPlayer 		  = nil
	local RequiredDistanceFOV 	  = nil
	local WallBangPossible 		  = false
	if Environment.Locked == nil then
		Environment.Settings.AILocked = false
	end

	if Environment.FOVSettings.Enabled then
		RequiredDistanceFOV = Environment.FOVSettings.Amount
	else
		RequiredDistanceFOV = Camera.ViewportSize.X / 2
	end
	
	for _, v in next, Players:GetPlayers() do
		if v ~= LocalPlayer then
			local HumanoidRootPart = v.Character and v.Character:FindFirstChild("HumanoidRootPart")
			if v.Character and HumanoidRootPart then
				if Environment.Settings.TeamCheck then 
					if LocalPlayer:GetFriendStatus(v) ~= Enum.FriendStatus.Friend then 
						local dwHumanoid = v.Character:FindFirstChild("Humanoid")
						if Environment.Settings.AliveCheck and dwHumanoid and v.Character.Humanoid.Health <= 0 then continue end
						if Environment.Settings.WallBang then
							for i,v in pairs(Environment.Settings.WallTypes) do
								if v == Environment.Settings.WallType then
									WallBangPossible = true
									break
								end
							end
							if not WallBangPossible then 
								if Environment.Settings.WallCheck and not IsPartVisible(HumanoidRootPart, v.Character) then continue end 
							end
						else
							if Environment.Settings.WallCheck and not IsPartVisible(HumanoidRootPart, v.Character) then continue end
						end

						local Vector, OnScreen   = Camera:WorldToViewportPoint(v.Character[Environment.Settings.LockPart].Position)
						local DistanceFromMouse  = (Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2.new(Vector.X, Vector.Y)).Magnitude
						local DistanceFromPlayer = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - v.Character.HumanoidRootPart.Position).Magnitude + 0.5)
						if OnScreen then
							if DistanceFromMouse < RequiredDistanceFOV then
								if DistanceFromPlayer < Environment.Settings.MaxDistance then
									RequiredDistanceFOV = DistanceFromMouse
									ClosestPlayer = v
									if Environment.Locked == nil then
										Environment.Settings.AILocked = false
									end
								end
							end
						end
					end
				else
					local dwHumanoid = v.Character:FindFirstChild("Humanoid")
					if Environment.Settings.AliveCheck and dwHumanoid and v.Character.Humanoid.Health <= 0 then continue end
					if Environment.Settings.WallBang then
						for i,v in pairs(Environment.Settings.WallTypes) do
							if v == Environment.Settings.WallType then
								WallBangPossible = true
								break
							end
						end
						if not WallBangPossible then 
							if Environment.Settings.WallCheck and not IsPartVisible(HumanoidRootPart, v.Character) then continue end 
						end
					else
						if Environment.Settings.WallCheck and not IsPartVisible(HumanoidRootPart, v.Character) then continue end
					end

					local Vector, OnScreen   = Camera:WorldToViewportPoint(v.Character[Environment.Settings.LockPart].Position)
					local DistanceFromMouse  = (Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2.new(Vector.X, Vector.Y)).Magnitude
					local DistanceFromPlayer = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - v.Character.HumanoidRootPart.Position).Magnitude + 0.5)
					if OnScreen then
						if DistanceFromMouse < RequiredDistanceFOV then
							if DistanceFromPlayer < Environment.Settings.MaxDistance then
								RequiredDistanceFOV = DistanceFromMouse
								ClosestPlayer = v
								if Environment.Locked == nil then
									Environment.Settings.AILocked = false
								end
							end
						end
					end
				end
			end
		end
	end

	if Environment.Settings.AiAimbotEnabled then
		for _, v in next, game:GetService("Workspace").AiZones:GetDescendants() do
			if v:FindFirstChild("HumanoidRootPart") then
				if Environment.Settings.AliveCheck and v.Humanoid.Health <= 0 then continue end
				if Environment.Settings.WallBang then
					for i,v in pairs(Environment.Settings.WallTypes) do
						if v == Environment.Settings.WallType then
							WallBangPossible = true
							break
						end
					end
					if not WallBangPossible then 
						if Environment.Settings.WallCheck and not IsPartVisible(v.HumanoidRootPart, v) then continue end 
					end
				else
					if Environment.Settings.WallCheck and not IsPartVisible(v.HumanoidRootPart, v) then continue end
				end

				local Vector, OnScreen   = Camera:WorldToViewportPoint(v.HumanoidRootPart.Position)
				local DistanceFromMouse  = (Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2.new(Vector.X, Vector.Y)).Magnitude
				local DistanceFromPlayer = (LocalPlayer.Character.HumanoidRootPart.Position - v.HumanoidRootPart.Position).Magnitude
				if OnScreen then
					if DistanceFromMouse < RequiredDistanceFOV then
						if DistanceFromPlayer < Environment.Settings.MaxDistance then
							RequiredDistanceFOV = DistanceFromMouse
							ClosestPlayer = v
							if Environment.Locked == nil then
								Environment.Settings.AILocked = true
							end
						end
					end
				end
			end
		end
	end

	-- work out which is closest
	if Environment.Locked == nil then
		Environment.Locked = ClosestPlayer
	end
end


-- Typing Check

ServiceConnections.TypingStartedConnection = UserInputService.TextBoxFocused:Connect(function()
	Typing = true
end)
ServiceConnections.TypingEndedConnection = UserInputService.TextBoxFocusReleased:Connect(function()
	Typing = false
end)

-- Silent Aim hook function
LPH_JIT_ULTRA(function()
	local oldHook = nil	
	oldHook = hookfunction(require(ReplicatedStorage.Modules.FPS.Bullet).CreateBullet, function(...)
		local args = {...}
		if Environment.Settings.SilentAimEnabled then
			local shouldMiss = false
			if Environment.Settings.SilentAimMisschance >= math.random(1, 100) then
				shouldMiss = true
			end

			GetClosestPlayer()
			if Environment.Locked ~= nil then
				local head = nil
				if Environment.Settings.AILocked then
					head = Environment.Locked:FindFirstChild("Head").Position
				else
					head = Environment.Locked.Character:FindFirstChild("Head").Position
				end

				if shouldMiss then
					local Where = math.random(1, 4)
					if Where == 1 then
						head = head + Vector3.new(0, 0, 10)
					elseif Where == 2 then
						head = head + Vector3.new(0, 0, -10)
					elseif Where == 3 then
						head = head + Vector3.new(10, 0, 0)
					elseif Where == 4 then
						head = head + Vector3.new(-10, 0, 0)
					end
				end

				if head ~= nil then
					args[9] = {CFrame = CFrame.lookAt(
						LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(
							0, UniversalTables.UniversalTable.GameSettings.RootScanHeight, 0
						),
						head + Vector3.new(0,3,0)
					)}
				end
				return oldHook(table.unpack(args))
			end
		end

		return oldHook(table.unpack(args))
	end)
end)()

-- Aimbot Function
local function Load()
	ServiceConnections.RenderSteppedConnection = RunService.RenderStepped:Connect(function()

		if Environment.FOVSettings.Enabled and Environment.Settings.Enabled then
			Environment.FOVCircle.Radius = Environment.FOVSettings.Amount
			Environment.FOVCircle.Thickness = Environment.FOVSettings.Thickness
			Environment.FOVCircle.Filled = Environment.FOVSettings.Filled
			Environment.FOVCircle.NumSides = Environment.FOVSettings.Sides
			Environment.FOVCircle.Color = GetColor(Environment.FOVSettings.Color)
			Environment.FOVCircle.Transparency = Environment.FOVSettings.Transparency
			Environment.FOVCircle.Visible = Environment.FOVSettings.Visible
			Environment.FOVCircle.Position = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
		else
			Environment.FOVCircle.Visible = false
		end

		if Environment.Settings.SnapLines then
			if Environment.Settings.Enabled or Environment.Settings.SilentAimEnabled then
				GetClosestPlayer()

				if Environment.Locked ~= nil then
					local player = Environment.Locked

					if not Environment.Settings.AILocked then
						player = Environment.Locked.Character
					end

					local Vector, OnScreen = Camera:WorldToViewportPoint(player[Environment.Settings.LockPart].Position)
					if OnScreen then
						Environment.SnapLine.Visible = true
						Environment.SnapLine.From = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
						Environment.SnapLine.To = Vector2.new(Vector.X, Vector.Y)
						Environment.SnapLine.Color = GetColor(Environment.Settings.SnapLineColor)
						Environment.SnapLine.Thickness = 1
					else
						Environment.SnapLine.Visible = false
					end
				else
					Environment.SnapLine.Visible = false
				end
			end
		else
			Environment.SnapLine.Visible = false
		end

		if Environment.Settings.Enabled and IsDown(Enum.UserInputType[Environment.Settings.TriggerKey]) then
			if not Environment.Settings.SilentAimEnabled then
				GetClosestPlayer()
				if Environment.Locked ~= nil then
					local Prediction = Vector3.new(0, 0, 0)
					local player = Environment.Locked

					if not Environment.Settings.AILocked then
						player = Environment.Locked.Character
					end

					if Environment.Settings.Prediction then
						local PlayerRoot = player:FindFirstChild("HumanoidRootPart") or player:FindFirstChild("Torso")
						if PlayerRoot then
							Prediction = PlayerRoot.Velocity * (Environment.Settings.PredictionMultiplier / 10) * (LocalPlayer.Character.Head.Position - player[Environment.Settings.LockPart].Position).magnitude / 1000
						end
					end
					
					if Environment.Settings.Sensitivity > 0 then
						Animation = TweenService:Create(Camera, TweenInfo.new(Environment.Settings.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = CFrame.new(Camera.CFrame.Position, player[Environment.Settings.LockPart].Position + Prediction)})
						Animation:Play()
					else
						Camera.CFrame = CFrame.new(Camera.CFrame.Position, player[Environment.Settings.LockPart].Position - Prediction)
					end
					Environment.FOVCircle.Color = GetColor(Environment.FOVSettings.LockedColor)
				end
			end
		else
			Environment.Locked = nil
			if Animation ~= nil then
				Animation:Cancel()
			end
			Environment.FOVCircle.Color = GetColor(Environment.FOVSettings.Color)
		end
	end)

	ServiceConnections.InputBeganConnection = UserInputService.InputBegan:Connect(function(Input)
		if not Typing then
			pcall(function()
				if Input.UserInputType == Enum.UserInputType[Environment.Settings.TriggerKey] then
					if Environment.Settings.Toggle then
						Running = not Running

						if not Running then
							Environment.Locked = nil
							Animation:Cancel()
							Environment.FOVCircle.Color = GetColor(Environment.FOVSettings.Color)
						end
					else
						Running = true
					end
				end
			end)
		end
	end)

	ServiceConnections.InputEndedConnection = UserInputService.InputEnded:Connect(function(Input)
		if not Typing then
			pcall(function()
				if Input.UserInputType == Enum.UserInputType[Environment.Settings.TriggerKey] then
					if not Environment.Settings.Toggle then
						Running = false
						Environment.Locked = nil
						Animation:Cancel()
						Environment.FOVCircle.Color = GetColor(Environment.FOVSettings.Color)
					end
				end
			end)
		end
	end)
end

-- Functions

Environment.Functions = {}

function Environment.Functions:Exit()
	for _, v in next, ServiceConnections do
		v:Disconnect()
	end

	Environment.FOVCircle:Remove()
	Environment.SnapLine:Remove()

	getgenv().Aimbot.Functions = nil
	getgenv().Aimbot = nil
end


Load()
