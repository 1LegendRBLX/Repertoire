--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Repertoire = require(ReplicatedStorage.Packages.Repertoire)

local Reactions = Repertoire.Reactions
local Actions = Repertoire.Actions
local Accent = Repertoire.Accent
local Scene = Repertoire.Scene

local Bombo2Scene = Scene()

local Bombo2 = Accent(workspace.Bomb2)
Bombo2:AddAction(Actions.RandomLifetime):Props({ Min = 1, Max = 8 })
Bombo2:AddAction(Actions.RandomLifetime):Props({ Min = 1, Max = 8 })
Bombo2:AddAction(Actions.RandomCount):Props({ Min = 10, Max = 20 })

Bombo2:AddReaction(Reactions.RandomScale):Hook(Bombo2.OnSpawned):Props({
	MinScale = -20,
	MaxScale = 70,
	Weight = 120,
	UseMultiplication = true,
})

Bombo2:AddReaction(Reactions.Force):Hook(Bombo2.OnSpawned):Props({
	Velocity = 15,
	Direction = Vector3.yAxis * 1,
	RandomRange = 30,
	Spread = 45,
})
Bombo2:AddReaction(Reactions.TweenScale):Hook(Bombo2.OnDespawned):Props({
	Scale = 0.1,
	TweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
})

local Sequence = Bombo2Scene:Sequence(function(seq)
	Bombo2:Spawn(Vector3.yAxis * 20)
end)
Sequence:Start()

-- local Bombo = Accent(workspace.Bomb)
-- Bombo:AddAction(Actions.RandomLifetime):Props({ Min = 1, Max = 1 })
-- Bombo:AddAction(Actions.RandomCount):Props({ Min = 1, Max = 2 })
-- Bombo:AddReaction(Reactions.RandomScale):Hook(Bombo.OnSpawned):Props({
-- 	MinScale = -20,
-- 	MaxScale = 70,
-- 	Weight = 120,
-- 	UseMultiplication = true,
-- })
-- Bombo:AddReaction(Reactions.Force):Hook(Bombo.OnSpawned):Props({
-- 	Velocity = 15,
-- 	Direction = Vector3.yAxis * 1,
-- 	RandomRange = 30,
-- 	Spread = 45,
-- })
-- Bombo:AddReaction(Reactions.TweenScale):Hook(Bombo.OnDespawned):Props({
-- 	Scale = 0.1,
-- 	TweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
-- })
-- Bombo:AddReaction(Reactions.SpawnAccent):Hook(Bombo.OnDespawned):Props({
-- 	AccentComponent = Bombo2,
-- })
-- Bombo:Spawn(Vector3.one * 20)

--Bombo2:Spawn(Vector3.new(0,20,0))

--local Repertoire = require(game:GetService("ReplicatedStorage").Repertoire)

--local Reactions = Repertoire.Reactions
--local Actions = Repertoire.Actions
--local Accent = Repertoire.Accent
--local Scene = Repertoire.Scene

--local PartInstance = workspace:WaitForChild("Bomb") :: BasePart
--local ParticleInstance = PartInstance:WaitForChild("SmokeVFX") :: ParticleEmitter
--local SoundInstance = PartInstance:WaitForChild("Sound") :: Sound

--local BombScene = Scene()

--local Bomb = Accent(PartInstance):AddAction(Actions.AddCenterAttachment):props({ Name = "SpawnPoint"})
--local ExplosionSound = Accent(SoundInstance)
--local SmokeFX = Accent(ParticleInstance)

--Bomb:Spawn(Vector3.new(0,10,0))

--local BombSequence = BombScene:Sequence(function(Sequence)
--	print("Started sequence")

--	--Bomb:Spawn()
--	--ExplosionSound:Spawn()

--	print("DO BOMB STUFF 1")
--	Sequence:Wait(4)
--	print("DO BOMB STUFF 2")

--	-- SmokeFX:Spawn()
--end)

--BombScene:Sequence(function(Seq)

--end)

--BombSequence:Start()

--task.delay(2, function()
--	-- THIS CANCELS THE SEQUENCE! DO BOMB STUFF 2 DID NOT RUN.
--	BombSequence:Cancel()
--end)
