local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages._Index["sleitnick_signal@1.5.0"].signal)

local CameraController = Knit.CreateController({ Name = "CameraController" })

CameraController.LockedChanged = Signal.new()

CameraController.Distance = 20
CameraController.Locked = false

CameraController.RenderName = "CustomCamRender"
CameraController.Priority = Enum.RenderPriority.Camera.Value

function CameraController:KnitStart()
	print("CameraController KnitStart called")
	-- Access Service
	--     local SomeService = Knit.GetService("SomeService")
	--     SomeService:DoSomething()
	--     SomeService.SomeEvent:Connect(function(...) end)
	--     SomeService.AnotherEvent:Fire("Some data")
end

function CameraController:KnitInit()
	print("CameraController KnitInit called")
end

function CameraController:LockTo(part)
	if self.Locked then
		return
	end -- Stop if already locked
	local cam = workspace.CurrentCamera
	self.Locked = true
	cam.CameraType = Enum.CameraType.Scriptable
	-- Bind to RenderStep:
	RunService:BindToRenderStep(self.RenderName, self.Priority, function()
		cam.CFrame = part.CFrame * CFrame.new(0, 0, self.Distance)
	end)
	-- Trigger Event
	self.LockedChanged:Fire(true)
end

function CameraController:Unlock()
	if not self.Locked then
		return
	end -- Stop if already unlocked
	local cam = workspace.CurrentCamera
	self.Locked = false
	cam.CameraType = Enum.CameraType.Custom
	-- Unbind:
	RunService:UnbindFromRenderStep(self.RenderName)
	-- Trigger Event
	self.LockedChanged:Fire(false)
end

return CameraController
