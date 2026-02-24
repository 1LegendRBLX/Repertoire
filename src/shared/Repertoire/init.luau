--!strict
local AccentComponent = require(script.Process.AccentComponent)
local SceneComponent = require(script.Process.SceneComponent)

local Config = require(script.Config)

export type SequenceComponent = SceneComponent.SequenceComponent
export type AccentComponent = AccentComponent.AccentComponent
export type SceneComponent = SceneComponent.SceneComponent

local Repertoire = {	
	Reactions = Config.Reactions,
	Actions = Config.Actions,
}

function Repertoire.Accent(Inst: Instance): AccentComponent
	return AccentComponent.new(Inst)
end

function Repertoire.Scene(): SceneComponent
	return SceneComponent.new()
end

return Repertoire

--[[
local Component = Accent.Component
local Reactions = Accent.Reactions

local BombScene = Scene.new()

local ExplosionAccent = Component(BombPart.ExplosionSound):AddElement("RandomPlay", { PlaybackSpeed = 2 })
local SmokeAccent = Component(BombPart.ParticleVFX):AddElement("EmitCount")
local BombAccent = Component(BombPart):AddElement("Force", { Spread = 50 })

BombScene:Add({ExplosionAccent, SmokeAccent, BombAccent})

BombAccent:BatchConnect("OnDespawn", {
	SetParent = { "someString" }
})

BombAccent.OnDespawn:Connect(function()
	Reactions.SetParent(BombPart, nil)
end)

local FuseMatchSequence = BombScene:Sequence(function(seq)
	-- spawn vfx
	-- start timer
	-- start sounds etc
end)

local BombSequence = BombScene:Sequence(function(seq)
	BombAccent:Spawn()
	
	FuseMatchSequence:Start():WaitFor()
	
	seq:Wait()
	
	seq:RandomTime(1, 5, function()
		SmokeAccent:Emit()
	end)
	
	SmokeAccent:Repeat(15)
	SmokeAccent:Spawn()
	
	ExplosionAccent:Spawn()
	
	seq:Wait()
	
	BombScene:Cleanup()
end

BombSequence:Start()
BombSequence:Repeat(5)
BombSequence:Cancel()
]]