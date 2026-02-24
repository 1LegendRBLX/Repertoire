--!strict
local SequenceComponent = {}
SequenceComponent.__index = SequenceComponent

export type SequenceComponent = typeof(setmetatable({} :: {
	Process: (self: SequenceComponent) -> (),
	IsActive: boolean,
	Scene: any,
	_thread: thread?,
	_cancelToken: boolean,
}, SequenceComponent))

function SequenceComponent.new(Scene, Process: (self: SequenceComponent) -> ()): SequenceComponent
	return setmetatable({
		Process = Process,
		IsActive = false,
		Scene = Scene,

		_thread = nil,
		_cancelToken = false,
	}, SequenceComponent) :: SequenceComponent
end

function SequenceComponent.Start(self: SequenceComponent): SequenceComponent
	if self.IsActive then warn(`[{script.Name}] Sequence already active`) 
		return self 
	end
	
	self.IsActive = true
	self._cancelToken = false
	
	self._thread = self:_createThread(self.Process)
	task.spawn(function()
		coroutine.resume(self._thread :: thread)
	end)
	
	return self
end

function SequenceComponent.IsInSequence(self: SequenceComponent): boolean
	return self.IsActive
end

function SequenceComponent.Wait(self: SequenceComponent, Duration: number)
	self:Yield(Duration)
end

function SequenceComponent.Yield(self: SequenceComponent, Duration: number?)
	if not self.IsActive then return end
	
	local EndTime = Duration and (os.clock() + Duration) or nil
	
	while self.IsActive and not self._cancelToken do
		if EndTime and os.clock() >= EndTime then
			break
		end
		
		coroutine.yield()
	end
end

function SequenceComponent.Cancel(self: SequenceComponent): SequenceComponent
	if not self.IsActive then return self end
	
	print("CANCELLED")
	self._cancelToken = true
	self.IsActive = false
	
	self._thread = nil
	
	return self
end

function SequenceComponent.Destroy(self: SequenceComponent)
	self:Cancel()
	table.clear(self::any)
	setmetatable(self::any, nil)
end

function SequenceComponent._createThread(self: SequenceComponent, Process: (self: SequenceComponent) -> ()): thread
	return coroutine.create(function()
		Process(self)
		self.IsActive = false
	end)	
end

return {
	new = SequenceComponent.new
}