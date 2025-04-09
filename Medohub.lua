--// Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Player Setup
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

LocalPlayer.CharacterAdded:Connect(function(char)
	Character = char
end)

--// Toggle States
local toggleStates = {
	["Auto Farm Level"] = false,
	["Fast Attack"] = false,
	["Auto Click"] = false
}

--// GUI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MEDO_Hub"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

--// Main Frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 280, 0, 220)
frame.Position = UDim2.new(0, 20, 0.5, -110)
frame.AnchorPoint = Vector2.new(0, 0.5)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

--// Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.Text = "MEDO Hub"
title.TextColor3 = Color3.new(1, 1, 1)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Parent = frame

--// Shrink Button
local logoBtn = Instance.new("TextButton")
logoBtn.Size = UDim2.new(0, 50, 0, 50)
logoBtn.Position = UDim2.new(1, -60, 1, -60)
logoBtn.AnchorPoint = Vector2.new(1, 1)
logoBtn.Text = "M"
logoBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
logoBtn.TextColor3 = Color3.new(1, 1, 1)
logoBtn.Font = Enum.Font.GothamBold
logoBtn.TextSize = 22
logoBtn.AutoButtonColor = true
logoBtn.Draggable = true
logoBtn.Parent = screenGui

logoBtn.MouseButton1Click:Connect(function()
	frame.Visible = not frame.Visible
	for name, state in pairs(toggleStates) do
		for _, btn in ipairs(frame:GetChildren()) do
			if btn:IsA("TextButton") and btn.Text:find(name) then
				btn.Text = name .. (state and " [ON]" or " [OFF]")
				btn.BackgroundColor3 = state and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(120, 40, 40)
			end
		end
	end
end)

--// Toggle Button Creator
local function createToggleButton(name, yPos, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.9, 0, 0, 35)
	btn.Position = UDim2.new(0.05, 0, 0, yPos)
	btn.Text = name .. " [OFF]"
	btn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 14
	btn.Parent = frame

	btn.MouseButton1Click:Connect(function()
		toggleStates[name] = not toggleStates[name]
		btn.Text = name .. (toggleStates[name] and " [ON]" or " [OFF]")
		btn.BackgroundColor3 = toggleStates[name] and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(120, 40, 40)
		callback(toggleStates[name])
	end)
end

--// Tween Helper (speed = 460)
local function tweenToPosition(part, goalCFrame)
	local distance = (part.Position - goalCFrame.Position).Magnitude
	local time = distance / 460
	local tween = TweenService:Create(part, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = goalCFrame})
	tween:Play()
	tween.Completed:Wait()
end

--// Quest Definitions
local function getQuestForLevel(level)
	local questTable = {
		{min = 0, max = 10, name = "Bandit", pos = Vector3.new(100, 10, 100)},
		{min = 11, max = 30, name = "Monkey", pos = Vector3.new(300, 10, 100)},
	}
	for _, q in ipairs(questTable) do
		if level >= q.min and level <= q.max then
			return q
		end
	end
	return nil
end

--// Auto Quest Handler
local function autoQuest()
	local data = LocalPlayer:FindFirstChild("Data")
	local levelObj = data and data:FindFirstChild("Level")
	if not levelObj then return end

	local questInfo = getQuestForLevel(levelObj.Value)
	if not questInfo then return end

	local root = Character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	tweenToPosition(root, CFrame.new(questInfo.pos))

	local remote = ReplicatedStorage:FindFirstChild("Remotes")
	if remote and remote:FindFirstChild("CommF") then
		remote.CommF:InvokeServer("StartQuest", questInfo.name, 1)
	end
end

--// Feature: Auto Farm Level
createToggleButton("Auto Farm Level", 40, function()
	task.spawn(function()
		local target = nil
		while toggleStates["Auto Farm Level"] and RunService.RenderStepped:Wait() do
			autoQuest()

			local enemies = workspace:FindFirstChild("Enemies")
			if not enemies then continue end

			if not target or not target.Parent or target.Humanoid.Health <= 0 then
				local minDist = math.huge
				for _, enemy in ipairs(enemies:GetChildren()) do
					if enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 then
						local dist = (enemy.HumanoidRootPart.Position - Character.HumanoidRootPart.Position).Magnitude
						if dist < minDist then
							minDist = dist
							target = enemy
						end
					end
				end
			end

			if target and target:FindFirstChild("HumanoidRootPart") then
				pcall(function()
					tweenToPosition(Character.HumanoidRootPart, target.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3))
					local tool = Character:FindFirstChildOfClass("Tool")
					if tool then tool:Activate() end
				end)
			end
		end
	end)
end)

--// Feature: Fast Attack
createToggleButton("Fast Attack", 80, function()
	task.spawn(function()
		while toggleStates["Fast Attack"] do
			task.wait(0.05)
			local tool = Character:FindFirstChildOfClass("Tool")
			if tool then tool:Activate() end
		end
	end)
end)

--// Feature: Auto Click
createToggleButton("Auto Click", 120, function()
	task.spawn(function()
		while toggleStates["Auto Click"] do
			task.wait(0.1)
			local tool = Character:FindFirstChildOfClass("Tool")
			if tool then tool:Activate() end
		end
	end)
end)
