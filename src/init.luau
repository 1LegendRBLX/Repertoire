--!strict
local RunService = game:GetService("RunService")

local IS_SERVER = RunService:IsServer()

if IS_SERVER then
	local InstanceContainer = Instance.new("Folder")
	InstanceContainer.Name = "_repertoire"
	InstanceContainer.Parent = workspace
end

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

function Repertoire.Accent(Inst: Instance, Settings: { any }?): AccentComponent
	return AccentComponent.new(Inst, Settings)
end

function Repertoire.Scene(): SceneComponent
	return SceneComponent.new()
end

return Repertoire
