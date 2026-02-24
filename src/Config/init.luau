local TweenS = game:GetService('TweenService')
local ForceMod = require('./Lib/ForceMod')

local Config = {}

Config.Settings = {
	Clone = true,
	SpawnRateThreshold = 0.1
}

type AccentCompnent = any
export type ApplyRandomNum = (_: any?, Properties: { Min: number, Max: number, Weight: number?}) -> number
export type ApplyNum = (_: any?, Properties: { Num: number } ) -> number

local function ApplyNum (_: any?, Properties: {Num: number})
	Properties = Properties or {Num = 1}
	return Properties.Num
end

local function ApplyRandomNum (_: any?, Properties: {Min: number, Max: number, Weight: number?})
	local Min, Max, Weight = Properties.Min, Properties.Max, Properties.Weight
	return math.random(Min, Max) / (Weight or 1)
end

local function ApplyAssetScale (Inst: Instance, Scale: number, UseMultiplication: boolean)
	if UseMultiplication then
		Scale = 1 + Scale
	end

	if Inst:IsA('BasePart') then
		Inst.Size = UseMultiplication and Inst.Size * Scale or Vector3.one * Scale
	elseif Inst:IsA('Model') then
		-- Inst.Scale = UseMultiplication and Inst.Scale * Scale or Vector3.one * Scale
	end
end

Config.Actions = {
	AddCenterAttachment = function(Part: Part): Attachment
		return Instance.new("Attachment", Part)
	end,
	
	MutateSpawnPart = function(Part: Part, Properties: { [string]: any } )
		for Key: string, Value: any in Properties do
			local Success, Error = pcall(function()
				(Part::any)[Key] = Value
			end)
			
			if not Success then
				error(Error)
			end
		end
	end,
	
	Count = function(...) return ApplyNum(...) end :: ApplyNum,
	
	EmitCount = function(...) return ApplyNum(...) end :: ApplyNum,

	Lifetime = function(...) return ApplyNum(...) end :: ApplyNum,
	
	EnabledTime = function(...) return ApplyNum(...) end :: ApplyNum,

	SpawningTime = function(...) return ApplyNum(...) end :: ApplyNum,

	RandomCount = function(...) return ApplyRandomNum(...) end :: ApplyRandomNum,
	
	RandomEmitCount = function(...) return ApplyRandomNum(...) end :: ApplyRandomNum,
	
	RandomLifetime = function(...) return ApplyRandomNum(...) end :: ApplyRandomNum,
}

Config.Reactions = {
	BreakJoints = function(Inst: Instance, Properties: { IgnoreJoints: 'Welds' | 'Motors' })
		local function DestroyJoints(Parent: Instance)
			if not Parent:IsA("BasePart") then return end
			
			local IgnoreType = {
				Welds = {'Weld', 'WeldConstraint'},
				Motors = {'Motor', 'Motor6D'}
			}
		
			for _, Joint in Parent:GetJoints() do
				local IgnoreJoint = (Properties and Properties.IgnoreJoints)
				local TargetType = IgnoreJoint and Properties.IgnoreJoints
				if TargetType and (not Joint:IsA(TargetType[1]) or not Joint:IsA(TargetType[2])) then continue end
				
				Joint:Destroy()
			end
		end

		if Inst:IsA("BasePart") then
			DestroyJoints(Inst)
		elseif Inst:IsA("Model") then
			for _, Descendant in Inst:GetDescendants() do
				if not Descendant:IsA('BasePart') then continue end
				DestroyJoints(Descendant)
			end
		end
	end,
	
	TweenScale = function(Inst: Instance, Properties: {Scale: number, TweenInfo: TweenInfo})
		Properties = Properties or {Scale = .001, TweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)}
		
		local Scale = Properties.Scale
		local Info = Properties.TweenInfo
		
		local Tween
		
		if Inst:IsA('BasePart') then
			Tween = TweenS:Create(Inst, Info, {Size = Vector3.one * Scale})
			Tween:Play()
		elseif Inst:IsA('Model') then
			local ChangedConnection: RBXScriptConnection
			local NumVal = Instance.new('NumberValue')
			NumVal.Value = Inst.Scale
			
			Tween = TweenS:Create(NumVal, Info, {Value = Scale})
			Tween:Play()
			Tween.Completed:Once(function()
				ChangedConnection:Disconnect()
			end)
			
			ChangedConnection = NumVal.Changed:Connect(function()
				Inst.Scale = NumVal
			end)
		end
		
		Tween.Completed:Wait()
	end,
	
	SetScale = function(Inst: Instance, Properties: {Scale: number, UseMultiplication: boolean?})
		local Scale = Properties.Scale or 1
		local UseMultiplication = Properties.UseMultiplication or true
		
		ApplyAssetScale(Inst, Scale, UseMultiplication)
	end,
	
	RandomScale = function(Inst: Instance, Properties: {MinScale: number, MaxScale: number, Weight: number?, UseMultiplication: boolean?})
		local MinScale, MaxScale, Weight = Properties.MinScale, Properties.MaxScale, Properties.Weight
		local Scale = math.random(MinScale or 1, MaxScale or 1 ) / (Weight or 1)
		local UseMultiplication = Properties.UseMultiplication or true

		ApplyAssetScale(Inst, Scale, UseMultiplication)
	end,
	
	SpawnAccent = function (Inst: Instance, Properties: {AccentComponent: AccentCompnent, SpawnPosition: Vector3?})
		if not Properties or not Properties.AccentComponent then return end
		
		local Position = Properties and Properties.SpawnPosition or (Inst::BasePart).Position
		Properties.AccentComponent:Spawn(Position)
	end,
	
	Force = function (Inst: Instance, Properties: {RandomRange: number?, RelativeTo: Enum.ActuatorRelativeTo?, Spread: number?, Velocity: number?, Direction: Vector3?, ParentTo: Instance?})
		Properties = Properties or {}
		local ParentTo = Properties.ParentTo or Inst
		ForceMod.ApplyForce(ParentTo, Properties)
	end,
}

Config.Validation = {
	Instance = {
		Config.Actions.Count,
		Config.Actions.RandomCount,
		Config.Actions.SpawningTime
	},
	Model = {
		Config.Reactions.BreakWelds,
		Config.Reactions.TweenScale,
		Config.Actions.Lifetime,
		Config.Actions.RandomLifetime
	},
	BasePart = {
		Config.Reactions.BreakWelds,
		Config.Reactions.TweenScale,
		Config.Actions.Lifetime,
		Config.Actions.RandomLifetime
	},
	Sound = {
		Config.Actions.AddCenterAttachment,
		Config.Actions.MutateSpawnPart
	},
	ParticleEmitter = {
		Config.Actions.AddCenterAttachment,
		Config.Actions.MutateSpawnPart
	},
} :: { [string]: any }

return Config