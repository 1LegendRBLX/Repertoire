local Debris = game:GetService("Debris")

local ForceMod = {}

local LinearVelocity = Instance.new("LinearVelocity")
local AngularVelocity = Instance.new("AngularVelocity")
local ForceCaches = {
	["LinearForce"] = LinearVelocity,
	["AngularForce"] = AngularVelocity,
}

local Attachment = Instance.new("Attachment")

AngularVelocity.MaxTorque = math.huge
AngularVelocity.Enabled = false

LinearVelocity.MaxForce = math.huge
LinearVelocity.Enabled = false

export type ForceTypes = "LinearForce" | "AngularForce"

export type Settings = {
	ForceType: ForceTypes,
	Velocity: number,
	Direction: Vector3,
	RelativeTo: Enum.ActuatorRelativeTo,
	Spread: Vector2,
	RandomRange: number,
}

ForceMod.DefaultSettings = {
	ForceType = "LinearForce",
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
	local ForceType = Settings and Settings.ForceType or ForceMod.DefaultSettings.ForceType
	local Velocity = Settings and Settings.Velocity or ForceMod.DefaultSettings.Velocity
	local Direction = Settings and Settings.Direction or ForceMod.DefaultSettings.Direction
	local RelativeTo = Settings and Settings.RelativeTo or ForceMod.DefaultSettings.RelativeTo
	local Spread = Settings and Settings.Spread or ForceMod.DefaultSettings.Spread
	local RandomRange = Settings and Settings.RandomRange or ForceMod.DefaultSettings.RandomRange

	local new_velocity = ForceCaches[ForceType]:Clone()
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

	if ForceType == "LinearForce" then
		new_velocity.VectorVelocity = ApplySpread(Direction, Spread) * (Velocity * random_multiplier)
	elseif ForceType == "AngularForce" then
		new_velocity.AngularVelocity = ApplySpread(Direction, Spread) * (Velocity * random_multiplier)
	end

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

function ForceMod.ApplyAngularForce(Parent: BasePart? | Model, Settings: Settings)
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
