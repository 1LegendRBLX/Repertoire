--!strict
local AccentComponent = require(script.Parent.AccentComponent)
local SequenceComponent = require(script.SequenceComponent)

export type SequenceComponent = SequenceComponent.SequenceComponent
export type SequenceConfig = SequenceComponent.SequenceConfig
type AccentComponent = AccentComponent.AccentComponent

local SceneComponent = {}
SceneComponent.__index = SceneComponent

export type SceneComponent = typeof(setmetatable(
	{} :: {
		AccentComponents: { AccentComponent },
		SequenceComponents: { SequenceComponent },
	},
	SceneComponent
))

function SceneComponent.new(): SceneComponent
	return setmetatable({
		SequenceComponents = {},
		AccentComponents = {},
	}, SceneComponent)
end

function SceneComponent.Sequence(
	self: SceneComponent,
	Process: (self: SequenceComponent) -> (),
	Config: SequenceConfig?
): SequenceComponent
	local Sequence = SequenceComponent.new(self, Process, Config)
	table.insert(self.SequenceComponents, Sequence)
	return Sequence
end

function SceneComponent.AddAccentComponents(self: SceneComponent, Components: { AccentComponent })
	for _, Component: any in Components do
		table.insert(self.AccentComponents, Component)
	end
end

function SceneComponent.Cleanup(self: SceneComponent)
	for _, AccentComponent in self.AccentComponents do
		(AccentComponent :: AccentComponent):Destroy()
	end

	for _, Sequence in self.SequenceComponents do
		(Sequence :: SequenceComponent):Destroy()
	end
end

function SceneComponent.Destroy(self: SceneComponent)
	self:Cleanup()

	table.clear(self :: any)
	setmetatable(self :: any, nil)
end

return {
	new = SceneComponent.new,
}
