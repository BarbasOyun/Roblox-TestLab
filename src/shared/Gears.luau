-- UTILS / HELPER FUNCTIONS
-- Controller?

local RunService = game:GetService("RunService")

local gears = {}

-- DATA

function gears.deepCopy(original)
	local copy = {}

	for key, value in pairs(original) do
		if type(value) == "table" then
			copy[key] = gears.deepCopy(value)
		else
			copy[key] = value
		end
	end

	return copy
end

-- INSTANCES / WORLD OBJECT

function gears.getPartCount(parentObject)
	local count = 0

	for _, object in ipairs(parentObject:GetDescendants()) do
		if object:IsA("BasePart") then
			count += 1
		end
	end

	return count
end

function gears.FindHumanoidFromPart(part)
	local character = part.Parent

	if character then
		return character:FindFirstChild("Humanoid")
	end

	return nil
end

-- AUDIO

function gears.safePlaySound(sound)
	sound:Stop()
	sound.TimePosition = 0
	task.wait()
	sound:Play()
end

function gears.safePlaySoundClone(soundPrefab, parent)
	local sound = soundPrefab:Clone()
	sound.Parent = parent
	task.wait()
	sound:Play()
	game.Debris:AddItem(sound, sound.TimeLength + 0.01)
end

-- ASYNC LOGIC

function gears.executeFor(duration, lambda)
	local execute = RunService.Heartbeat:Connect(function()
		lambda()
	end)

	task.delay(duration, function()
		execute:Disconnect()
	end)
end

function gears.waitUntil(condition)
	local startTime = tick()
	local timeout = 10

	while not condition() do
		task.wait()

		if tick() - startTime > timeout then
			warn("waitUntil timed out!")
			return false
		end
	end

	return true
end

-- DEBUG & PERF

-- Simple test
function gears.performanceTest(lambda)
	print("Performance Test START : " .. tick())
	lambda()
	print("Performance Test END : " .. tick())
end

function gears.drawEdge(startPos, endPos, color)
	local adorn = Instance.new("LineHandleAdornment")
	adorn.Length = (endPos - startPos).Magnitude
	adorn.Color3 = color or Color3.new(0, 1, 0)
	adorn.Thickness = 20
	adorn.Adornee = workspace.Terrain
	-- Position it at origin and point it toward the direction
	adorn.CFrame = CFrame.lookAt(startPos, endPos)
	adorn.AlwaysOnTop = true
	adorn.Parent = workspace.Terrain

	game.Debris:AddItem(adorn, 0.01)
end

function gears.drawRay(origin, direction, color)
	gears.drawEdge(origin, origin + direction, color)
end

function gears.drawCircle(basePos, circlePoints)
	local function drawEdge(point1, point2)
		local startPos = basePos + Vector3.new(point1.X, 0, point1.Y)
		local endPos = basePos + Vector3.new(point2.X, 0, point2.Y)
		gears.drawEdge(startPos, endPos)
	end

	-- Draw Edges
	for index = 1, #circlePoints - 1, 1 do
		drawEdge(circlePoints[index], circlePoints[index + 1])
	end

	-- Draw Last Edges : Last Point -> First
	drawEdge(circlePoints[#circlePoints], circlePoints[1])
end

function gears.drawSphere(position, radius, color)
	local adorn = Instance.new("SphereHandleAdornment")
	adorn.Radius = radius
	adorn.Color3 = color or Color3.new(0.5, 0, 0)
	adorn.Transparency = 0.5
	adorn.Adornee = workspace.Terrain -- Must be attached to something
	adorn.CFrame = CFrame.new(position)
	adorn.AlwaysOnTop = true
	adorn.Parent = workspace.Terrain

	game.Debris:AddItem(adorn, 0.01)
end

-- MATH

function gears.increaseToMultiplier(increaseValue)
	-- eg 10% Increase -> 1.1
	return 1 + increaseValue / 100
end

function gears.sumTable(t)
	local total = 0
	for i = 1, #t do
		total += t[i]
	end
	return total
end

function gears.circlePoints(radius, division) -- TODO : Add Progress
	local points = {}
	local pointDistance = (math.pi * 2) / division

	for i = 0, (division - 1), 1 do
		table.insert(points, gears.circlePos(radius, pointDistance * i))
	end

	return points
end

function gears.floatRandom(minNbr, maxNbr)
	local randomDecimal = math.random(1, 10) / 10
	return math.random(minNbr, maxNbr - 1) + randomDecimal
end

function gears.pointsDistance(pointA, pointB)
	return (pointA - pointB).Magnitude
end

function gears.normalizeOrZero(vector2)
	if vector2 == Vector2.zero then
		return Vector2.zero
	end

	return vector2.Unit
end

function gears.loopValue(value, max, resetValue) -- TODO : Add min
	local resetValue2 = resetValue or 0

	if value > max then
		value = resetValue2
	end

	return value
end

function gears.sigmoid(x, slop, length)
	local useSlop = slop or 1
	local useLength = length or 1
	return useLength / (useLength + math.exp(useSlop * x))
end

function gears.parabolaPos(startPos, endPos, height, progress)
	local lerpPos = startPos + (endPos - startPos) * progress
	local y = startPos.Y + (height * 4 * progress * (1 - progress))
	return Vector3.new(lerpPos.X, y, lerpPos.Z)
end

function gears.circlePos(radius, progress)
	-- When used Overtime :
	-- progress = (progress + 0.01) % (math.pi * 2)
	local x = math.cos(progress) * radius
	local y = math.sin(progress) * radius
	return Vector2.new(x, y) -- Add to a position
end

function gears.spherePos(latitude, longitude, radius)
	-- When used Overtime :
	-- latitude = (progress + 0.01) % (math.pi * 2)
	-- longitude = (progress + 0.01) % (math.pi * 2)
	local x = math.sin(latitude) * math.cos(longitude) * radius
	local y = math.sin(latitude) * math.sin(longitude) * radius
	local z = math.cos(latitude) * radius
	return Vector3.new(x, y, z) -- Add to a position
end

return gears
