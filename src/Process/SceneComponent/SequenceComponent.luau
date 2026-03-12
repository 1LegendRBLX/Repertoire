--!strict
local Root = script.Parent.Parent.Parent.Parent

local Promise = require(Root.Promise)

type YieldInstruction =
	{ Type: "wait", Duration: number }
	| { Type: "promise", Promise: Promise.Promise }
	| { Type: "frame" }

local SequenceComponent = {}
SequenceComponent.__index = SequenceComponent

export type SequenceComponent = typeof(setmetatable(
	{} :: {
		Process: (self: SequenceComponent) -> (),
		IsActive: boolean,
		Scene: any,
		SelfDestruct: boolean,
		_thread: thread?,
	},
	SequenceComponent
))

export type SequenceConfig = {
	SelfDestruct: boolean?, -- do we clean the scene when completed?
}

function SequenceComponent.new(
	Scene,
	Process: (self: SequenceComponent) -> (),
	Config: SequenceConfig?
): SequenceComponent
	return setmetatable({
		Process = Process,
		IsActive = false,
		Scene = Scene,

		SelfDestruct = (Config and Config.SelfDestruct) or false,

		_thread = nil,
	}, SequenceComponent) :: SequenceComponent
end

function SequenceComponent.Start(self: SequenceComponent): SequenceComponent
	if self.IsActive then
		return self
	end

	self.IsActive = true

	self._thread = coroutine.create(function()
		self.Process(self)
	end)

	self:_step()

	return self
end

function SequenceComponent.IsInSequence(self: SequenceComponent): boolean
	return self.IsActive
end

function SequenceComponent.Wait(self, Duration: number): ...any
	return coroutine.yield({
		Type = "wait",
		Duration = Duration,
	})
end

function SequenceComponent.Await(self, AwaitPromise: Promise.Promise): ...any
	return coroutine.yield({
		Type = "promise",
		Promise = AwaitPromise,
	})
end

function SequenceComponent.NextFrame(self)
	return coroutine.yield({
		Type = "frame",
	})
end

function SequenceComponent.Cancel(self: SequenceComponent): SequenceComponent
	if not self.IsActive then
		return self
	end

	self.IsActive = false

	self._thread = nil

	return self
end

function SequenceComponent.Destroy(self: SequenceComponent)
	self:Cancel()
	table.clear(self :: any)
	setmetatable(self :: any, nil)
end

function SequenceComponent._step(self)
	if not self.IsActive then
		return
	end

	if not self._thread then
		return
	end

	local Ok, Yielded = coroutine.resume(self._thread)

	if not Ok then
		error(Yielded)
	end

	if coroutine.status(self._thread) == "dead" then
		self:_complete()
		return
	end

	self:_handleYield(Yielded)
end

function SequenceComponent._handleYield(self: SequenceComponent, Instruction: YieldInstruction)
	if not Instruction then
		warn(debug.traceback())
		return
	end

	if Instruction.Type == "wait" then
		task.delay(Instruction.Duration, function()
			if self.IsActive then
				self:_step()
			end
		end)
	elseif Instruction.Type == "frame" then
		task.defer(function()
			self:_step()
		end)
	elseif Instruction.Type == "promise" then
		Instruction.Promise
			:andThen(function()
				self:_step()
			end)
			:catch(function(err)
				error(err)
			end)
	end
end

function SequenceComponent._complete(self: SequenceComponent)
	self.IsActive = false

	if self.SelfDestruct then
		self.Scene:Destroy()
	end
end

return {
	new = SequenceComponent.new,
}
