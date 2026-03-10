--!strict
local TweenService = game:GetService("TweenService")

local Root = script.Parent.Parent

local ForceMod = require("./Lib/ForceMod")
local Promise = require(Root.Promise)

local Config = {
	Settings = {
		Clone = true,
		Logging = 5,
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
		-- Inst.Scale = UseMultiplication and Inst.Scale * Scale or Vector3.one * Scale
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
		return Promise.new(function(resolve)
			local Scale = Properties.Scale or 0.001
			local Info = Properties.TweenInfo

			local Tween

			if Inst:IsA("BasePart") then
				Tween = TweenService:Create(Inst, Info, { Size = Vector3.one * Scale })
			elseif Inst:IsA("Model") then
				local NumVal = Instance.new("NumberValue")
				NumVal.Value = Inst:GetScale()

				local ChangedConnection
				ChangedConnection = NumVal.Changed:Connect(function()
					Inst:ScaleTo(NumVal.Value)
				end)

				Tween = TweenService:Create(NumVal, Info, { Value = Scale })

				Tween.Completed:Once(function()
					ChangedConnection:Disconnect()
					resolve()
				end)
			else
				warn(`[{script.Name}] Unknown Instance type. Should be a BasePart or Model`)
			end

			Tween:Play()

			if Inst:IsA("BasePart") then
				Tween.Completed:Once(resolve)
			end
		end)
	end,

	RandomColorPalette = function(Inst: Instance, Properties: { Palette: { Color3 } })
		return Promise.try(function()
			local Palette = Properties.Palette
			if not Palette then
				return
			end

			local Chosen = Palette[math.random(1, #Palette)]

			if Inst:IsA("BasePart") then
				Inst.Color = Chosen
			else
				for _, Part in Inst:GetDescendants() do
					if not Part:IsA("BasePart") then
						continue
					end

					Part.Color = Chosen
				end
			end
		end)
	end,

	SetScale = function(Inst: Instance, Properties: { Scale: number, UseMultiplication: boolean? })
		local Scale = Properties.Scale or 1
		local UseMultiplication = Properties.UseMultiplication or true

		ApplyAssetScale(Inst, Scale, UseMultiplication)
	end,

	RandomScale = function(
		Inst: Instance,
		Properties: { MinScale: number, MaxScale: number, Weight: number?, UseMultiplication: boolean? }
	)
		local MinScale, MaxScale, Weight = Properties.MinScale, Properties.MaxScale, Properties.Weight
		local Scale = math.random(MinScale or 1, MaxScale or 1) / (Weight or 1)
		local UseMultiplication = Properties.UseMultiplication or true

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
		Properties: (ForceMod.Settings & {
			ParentTo: Instance?,
		}) | {}
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
