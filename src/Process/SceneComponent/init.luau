--!strict
local SequenceComponent = require("@self/SequenceComponent")
local AccentComponent = require("./AccentComponent")

export type SequenceComponent = SequenceComponent.SequenceComponent
type AccentComponent = AccentComponent.AccentComponent

local SceneComponent = {}
SceneComponent.__index = SceneComponent

export type SceneComponent = typeof(setmetatable({} :: {
	AccentComponents: { AccentComponent },
	SequenceComponents: { SequenceComponent },
}, SceneComponent))

function SceneComponent.new(): SceneComponent
	return setmetatable({
		AccentComponents = {},
		SequenceComponents = {},
	}, SceneComponent)
end

function SceneComponent.Sequence(self: SceneComponent, Process: (self: SequenceComponent) -> ()): SequenceComponent
	local Sequence = SequenceComponent.new(self, Process)
	table.insert(self.SequenceComponents, Sequence)
	return Sequence
end

function SceneComponent.Cleanup(self: SceneComponent)
	for _, Sequence in self.SequenceComponents do
		Sequence:Destroy()
	end
	
	for _, Accent in self.AccentComponents do
		Accent:Destroy()
	end
end

function SceneComponent.Destroy(self: SceneComponent)
	self:Cleanup()
	
	table.clear(self::any)
	setmetatable(self::any, nil)
end

return {
	new = SceneComponent.new,
}