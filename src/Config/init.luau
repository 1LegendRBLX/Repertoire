--!strict
local TweenService = game:GetService("TweenService")

local Root = script.Parent.Parent

local ForceMod = require("./Lib/ForceMod")
local Promise = require(Root.Promise)

local Config = {
	Settings = {
		Clone = true,
		Logging = false,
		SpawnRateThreshold = 0.1,
	},
}

type AccentComponent = any

export type ApplyRandomNum = (_: any?, Properties: { Min: number, Max: number, Weight: number? }) -> number
export type ApplyNum = (_: any?, Properties: { Num: number }) -> number

local function ApplyNum(_: any?, Properties: { Num: number }): number
	Properties = Properties or { Num = 1 }
	return Properties.Num
end

local function ApplyRandomNum(_: any?, Properties: { Min: number, Max: number, Weight: number? }): number
	local Min, Max, Weight = Properties.Min, Properties.Max, Properties.Weight
	return math.random(Min, Max) / (Weight or 1)
end

local function ApplyAssetScale(Inst: Instance, Scale: number, UseMultiplication: boolean)
	if UseMultiplication then
		Scale = 1 + Scale
	end

	if Inst:IsA("BasePart") then
		Inst.Size = UseMultiplication and Inst.Size * Scale or Vector3.one * Scale
	elseif Inst:IsA("Model") then
		local ScaleTo = UseMultiplication and Inst:GetScale() * Scale or Scale
		Inst:ScaleTo(ScaleTo)
	end
end

Config.Actions = {
	AddCenterAttachment = function(Part: Part): Attachment
		return Instance.new("Attachment", Part)
	end,

	MutateSpawnPart = function(Part: Part, Properties: { [string]: any })
		for Key: string, Value: any in Properties do
			local Success, Error = pcall(function()
				(Part :: any)[Key] = Value
			end)

			if not Success then
				error(Error)
			end
		end
	end,

	Count = function(...)
		return ApplyNum(...)
	end :: ApplyNum,

	EmitCount = function(...)
		return ApplyNum(...)
	end :: ApplyNum,

	Lifetime = function(...)
		return ApplyNum(...)
	end :: ApplyNum,

	EnabledTime = function(...)
		return ApplyNum(...)
	end :: ApplyNum,

	SpawningTime = function(...)
		return ApplyNum(...)
	end :: ApplyNum,

	RandomCount = function(...)
		return ApplyRandomNum(...)
	end :: ApplyRandomNum,

	RandomEmitCount = function(...)
		return ApplyRandomNum(...)
	end :: ApplyRandomNum,

	RandomLifetime = function(...)
		return ApplyRandomNum(...)
	end :: ApplyRandomNum,
}

Config.Reactions = {
	BreakJoints = function(Inst: Instance, Properties: { IgnoreJoints: "Welds" | "Motors" })
		local function DestroyJoints(Parent: Instance)
			if not Parent:IsA("BasePart") then
				return
			end

			for _, Joint in Parent:GetJoints() do
				local IgnoreJoint = (Properties and Properties.IgnoreJoints)

				if IgnoreJoint == "Welds" and Joint:IsA("Weld") then
					continue
				end

				if IgnoreJoint == "Motors" and Joint:IsA("Motor6D") then
					continue
				end

				Joint:Destroy()
			end
		end

		if Inst:IsA("BasePart") then
			DestroyJoints(Inst)
		elseif Inst:IsA("Model") then
			for _, Descendant in Inst:GetDescendants() do
				if not Descendant:IsA("BasePart") then
					continue
				end
				DestroyJoints(Descendant)
			end
		end
	end,

	TweenScale = function(Inst: Instance, Properties: { Scale: number, TweenInfo: TweenInfo })
		local Scale = (Properties and Properties.Scale) and Properties.Scale or 0.001
		local Info = (Properties and Properties.TweenInfo) and Properties.TweenInfo or TweenInfo.new(1)

		return Promise.new(function(resolve)
			local Tween: Tween

			if Inst:IsA("BasePart") then
				Tween = TweenService:Create(Inst, Info, { Size = Vector3.one * Scale })
			elseif Inst:IsA("Model") then
				local NumVal = Instance.new("NumberValue")
				NumVal.Value = Inst:GetScale()

				local ChangedConnection
				ChangedConnection = NumVal.Changed:Connect(function()
					(Inst :: Model):ScaleTo(NumVal.Value)
				end)

				Tween = TweenService:Create(NumVal, Info, { Value = Scale })

				Tween.Completed:Once(function()
					if ChangedConnection then
						ChangedConnection:Disconnect()
					end
					resolve()
				end)
			else
				warn(`[{script.Name}] Unknown Instance type. Should be a BasePart or Model`)
			end

			if Tween then
				Tween:Play()
			end

			if Inst:IsA("BasePart") and Tween then
				Tween.Completed:Once(function()
					resolve()
				end)
			end
		end)
	end,

	RandomColorPalette = function(Inst: Instance, Properties: { Palette: { Color3 }, Recursive: boolean })
		local Palette = Properties.Palette
		local Recursive = (Properties and Properties.Recursive) and Properties.Recursive or false

		if not Palette then
			return
		end

		local Chosen = Palette[math.random(1, #Palette)]

		if Inst:IsA("BasePart") then
			Inst.Color = Chosen
		end

		if Inst:IsA("Model") or Recursive then
			for _, Part in Inst:GetDescendants() do
				if not Part:IsA("BasePart") then
					continue
				end

				Part.Color = Chosen
			end
		end
	end,

	SetScale = function(Inst: Instance, Properties: { Scale: number, UseMultiplication: boolean? })
		local Scale = Properties.Scale or 1
		local UseMultiplication = (Properties.UseMultiplication ~= nil) and Properties.UseMultiplication or true

		ApplyAssetScale(Inst, Scale, UseMultiplication)
	end,

	SetMaterial = function(Inst: BasePart, Properties: { Material: Enum.Material, Recursive: boolean })
		local Recursive = (Properties and Properties.Recursive) and Properties.Recursive or false
		local Material = (Properties and Properties.Material) and Properties.Material or Enum.Material.Plastic

		if Inst:IsA("BasePart") then
			Inst.Material = Material
		end

		if Inst:IsA("Model") or Recursive then
			for _, Part in Inst:GetDescendants() do
				if not Part:IsA("BasePart") then
					continue
				end

				Part.Material = Material
			end
		end
	end,

	AddTrail = function(
		Inst: BasePart,
		Properties: { ColorSequence: ColorSequence, Scale: number, Width: Vector2, Lifetime: number }
	)
		local Scale = Properties and Properties.Scale or 0.5
		local ColorSequence = Properties and Properties.ColorSequence or ColorSequence.new(Color3.new(1, 1, 1))
		local Width = Properties and Properties.Width or Vector2.new(1, 0.5)

		local A0 = Instance.new("Attachment")
		local A1 = Instance.new("Attachment")
		local Trail = Instance.new("Trail")

		A0.Parent = Inst
		A1.Parent = Inst
		Trail.Parent = Inst

		local AOffsetSize = (Inst.Size / 2) * Scale
		A0.Position = Vector3.one * AOffsetSize
		A1.Position = Vector3.one * -AOffsetSize

		Trail.Color = ColorSequence
		Trail.WidthScale = NumberSequence.new({
			NumberSequenceKeypoint.new(0, Width.X),
			NumberSequenceKeypoint.new(1, Width.Y),
		})
	end,

	RandomScale = function(
		Inst: Instance,
		Properties: { MinScale: number, MaxScale: number, Weight: number?, UseMultiplication: boolean? }
	)
		local MinScale, MaxScale, Weight = Properties.MinScale, Properties.MaxScale, Properties.Weight
		local Scale = math.random(MinScale or 1, MaxScale or 1) / (Weight or 1)
		local UseMultiplication

		if Properties and Properties.UseMultiplication ~= nil then
			UseMultiplication = Properties.UseMultiplication
		else
			UseMultiplication = true
		end

		ApplyAssetScale(Inst, Scale, UseMultiplication)
	end,

	SpawnAccent = function(Inst: Instance, Properties: { AccentComponent: AccentComponent, SpawnPosition: Vector3? })
		if not Properties or not Properties.AccentComponent then
			return
		end

		local Position = Properties and Properties.SpawnPosition or (Inst :: BasePart).Position
		return Properties.AccentComponent:Spawn(Position)
	end,

	Force = function(
		Inst: Instance,
		Properties: {
			Velocity: number?,
			Direction: Vector3?,
			RelativeTo: Enum.ActuatorRelativeTo?,
			Spread: (number | Vector2)?,
			RandomRange: number?,
			ParentTo: Instance?,
		}
	)
		local TrueProperties = Properties or {} :: any
		local ParentTo = TrueProperties.ParentTo or Inst
		ForceMod.ApplyForce(ParentTo, TrueProperties)
	end,
}

Config.Validation = {
	Instance = {
		Config.Actions.Count,
		Config.Actions.RandomCount,
		Config.Actions.SpawningTime,
	},
	Model = {
		Config.Reactions.BreakJoints,
		Config.Reactions.TweenScale,
		Config.Actions.Lifetime,
		Config.Actions.RandomLifetime,
	},
	BasePart = {
		Config.Reactions.BreakJoints,
		Config.Reactions.TweenScale,
		Config.Actions.Lifetime,
		Config.Actions.RandomLifetime,
	},
	Sound = {
		Config.Actions.AddCenterAttachment,
		Config.Actions.MutateSpawnPart,
	},
	ParticleEmitter = {
		Config.Actions.AddCenterAttachment,
		Config.Actions.MutateSpawnPart,
	},
} :: { [string]: { any } }

return Config
