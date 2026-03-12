local Debris = game:GetService("Debris")

local ForceMod = {}

local LinearVelocity = Instance.new("LinearVelocity")
local Attachment = Instance.new("Attachment")

LinearVelocity.MaxForce = math.huge
LinearVelocity.Enabled = false

export type Settings = {
	Velocity: number,
	Direction: Vector3,
	RelativeTo: Enum.ActuatorRelativeTo,
	Spread: Vector2,
	RandomRange: number,
}

ForceMod.DefaultSettings = {
	Velocity = 10,
	Direction = Vector3.new(0, 0, -1),
	RelativeTo = "Attachment0",
	Spread = Vector2.new(0, 0),
	RandomRange = 0,
}

local function ApplySpread(direction: Vector3, spread: Vector2): Vector3
	local xSpreadRad = math.rad(math.random(-spread.X, spread.X))
	local ySpreadRad = math.rad(math.random(-spread.Y, spread.Y))

	local spreadRotation = CFrame.Angles(ySpreadRad, xSpreadRad, 0)

	local baseCFrame = CFrame.lookAt(Vector3.zero, direction)
	local finalCFrame = baseCFrame * spreadRotation

	return finalCFrame.LookVector
end

local function CreateForce(Parent, Settings: Settings)
	local Velocity = ForceMod.DefaultSettings.Velocity
	local Direction = ForceMod.DefaultSettings.Direction
	local RelativeTo = ForceMod.DefaultSettings.RelativeTo
	local Spread = ForceMod.DefaultSettings.Spread
	local RandomRange = ForceMod.DefaultSettings.RandomRange

	if Settings.Velocity then
		Velocity = Settings.Velocity
	end
	if Settings.Direction then
		Direction = Settings.Direction
	end
	if Settings.RelativeTo then
		RelativeTo = Settings.RelativeTo
	end
	if Settings.Spread then
		Spread = Settings.Spread
	end
	if Settings.RandomRange then
		RandomRange = Settings.RandomRange
	end

	local new_velocity = LinearVelocity:Clone()
	local v_attachment

	new_velocity.RelativeTo = RelativeTo

	if Parent:IsA("BasePart") then
		v_attachment = Attachment:Clone()
	elseif Parent:IsA("Attachment") then
		v_attachment = Parent
	end

	new_velocity.Attachment0 = v_attachment
	new_velocity.Parent = v_attachment

	if type(Spread) == "number" then
		Spread = Vector2.new(Spread, Spread)
	end

	local minMult = math.clamp(1 - (RandomRange / 100), 0.1, math.huge)
	local maxMult = 1 + (RandomRange / 100)
	local random_multiplier = math.random() * (maxMult - minMult) + minMult
	random_multiplier = math.clamp(random_multiplier, 0.1, LinearVelocity.MaxForce)

	new_velocity.VectorVelocity = ApplySpread(Direction, Spread) * (Velocity * random_multiplier)

	if v_attachment ~= Parent then
		v_attachment.Parent = Parent
	end

	new_velocity.Enabled = true
	return new_velocity, v_attachment
end

function ForceMod.ApplyConstant(Parent: Instance, Settings: Settings)
	if not Parent then
		return
	end

	local Force = CreateForce(Parent, Settings)
	return Force
end

function ForceMod.ApplyForce(Parent: BasePart? | Model, Settings: Settings)
	if Parent and Parent:IsA("Model") then
		Parent = Parent.PrimaryPart or nil
	end

	if not Parent then
		return
	end

	local Force, VelocityAttachment = CreateForce(Parent, Settings)
	Debris:AddItem(Force, 0.2)

	return Force, VelocityAttachment
end

return ForceMod
