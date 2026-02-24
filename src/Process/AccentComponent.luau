--!nonstrict
local Root = script.Parent.Parent.Parent

local Signal = require(Root.Signal)
local Config = require("../Config")

local CACHED_PART = Instance.new("Part")
CACHED_PART.Name = 'AccentPart'
CACHED_PART.Size = Vector3.one * 1
CACHED_PART.CanCollide = false
CACHED_PART.CanQuery = false
CACHED_PART.Anchored = true
CACHED_PART.Transparency = .5

local PART_CLASS_NAMES = {
	"Part",
	"Model",
	"MeshPart",
	"TrussPart",
	"CornerWedge",
}

local AccentComponent = {}
AccentComponent.__index = AccentComponent

type ActionBuilder<P> = {
	new: (self: ActionBuilder<P>) -> AccentComponent,
	Hook: (self: ActionBuilder<P>, AccentSignal: Signal.Signal<...any>) -> ActionBuilder<P>,
	Props: (self: ActionBuilder<P>, Props: P?) -> AccentComponent,
}

export type AccentSettings = typeof(Config.Settings)

export type AccentComponent = typeof(setmetatable({} :: {
	Instance: Instance,
	ClassName: string,
	AccentPart: Part?,
	ParentTo: Instance,
	Settings: AccentSettings,
	
	CloneStorage: { Instance },
	
	OnTouched: Signal.Signal<Instance, BasePart>,
	OnDespawned: Signal.Signal<Instance>,
	OnSpawned: Signal.Signal<Instance>,

	_actionMap: { 
		[string]: boolean 
	},
	
	_reactions: {
		{
			Handler: (Instance, any) -> any?,
			Connection: Signal.Connection?,
			Props: any,
		}
	},
	
	_actions: {
		{
			Handler: (Instance, any) -> any?,
			Props: any,
		}
	},
	_despawnDone: boolean,
	_map: { [number]: boolean },
}, AccentComponent))

--[=[
	@private
]=]
local function isBasePartOrModelClass(Part: Instance): boolean
	for _, ClassName in PART_CLASS_NAMES do
		if ClassName == Part.ClassName then
			return true
		end
	end

	return false
end

local count = 1

--[=[
	@private
]=]
local function getBuilder<T, P>(Data: { Handler: (T, P) -> any?, Props: P, Connection: Signal.Connection?}, ReturnObject: T): ActionBuilder<P>
	local Builder = {} :: ActionBuilder<P>

	function Builder:new()
		return ReturnObject
	end

	function Builder:Hook(AccentSignal: Signal.Signal<...any>)
		local IsSignal = AccentSignal == (ReturnObject::any).OnDespawned
		local myCount = math.random(1,99999999)
		if IsSignal then
			(ReturnObject::any)._map[myCount] = false	
		end
		
		Data.Connection = AccentSignal:Connect(function(...)
			Data.Handler(..., Data.Props)

			if not IsSignal then
				return
			end
			
			(ReturnObject::any):_completeReaction(myCount)
		end)
		
		return Builder
	end

	function Builder:Props(Props: P)
		Data.Props = Props
		return ReturnObject
	end

	return Builder
end

function AccentComponent.new(Inst: Instance, AccentSettings: AccentSettings?): AccentComponent
	if not Inst then error(`[{script.Name}] Instance is invalid`) end
	
	AccentSettings = AccentSettings or {} :: any
	
	local Settings = {} :: AccentSettings
	for Key, Value in Config.Settings :: any do
		(Settings::any)[Key] = (AccentSettings::any)[Key] or Value
	end
	
	return (setmetatable({
		Settings = Settings,
		ParentTo = workspace,
		Instance = Inst:Clone(),
		ClassName = Inst.ClassName,
		
		CloneStorage = {},

		OnDespawned = Signal.new(),
		OnSpawned = Signal.new(),
		OnTouched = Signal.new(),
		
		_actionMap = {}, -- action name map for O(1)
		_reactions = {},
		_actions = {},
		_map = {},
		_despawnDone = false,
	}, AccentComponent) :: any) :: AccentComponent
end

function AccentComponent.AddAction<T, P>(self: AccentComponent, Handler: (T, P) -> any?): ActionBuilder<P>
	local ReturnObject = self
	
	local ActionData = {
		Handler = Handler :: (T, P) -> any?,
		Connection = nil :: any,
		Props = (nil :: any) :: P,
	}
	
	table.insert(self._actions::any, ActionData)

	return getBuilder(ActionData, ReturnObject)
end

function AccentComponent.AddReaction<T, P>(self: AccentComponent, Handler: (T, P) -> any?): ActionBuilder<P>
	local ReturnObject = self

	local ReactionData = {
		Handler = Handler :: (T, P) -> any?,
		Connection = nil :: Signal.Connection?,
		Props = (nil :: any) :: P,
	}

	table.insert(self._reactions::any, ReactionData)

	return getBuilder(ReactionData, ReturnObject)
end

function AccentComponent.Spawn(self: AccentComponent, SpawnPosition: Vector3, ParentTo: Instance?): AccentComponent
	self.ParentTo = ParentTo or self.ParentTo
	
	local IsBasePartOrModel = isBasePartOrModelClass(self.Instance)
	if not IsBasePartOrModel then
		self.AccentPart = self:_createPart(SpawnPosition)
	end
	
	local RandomizeLifetime = self:_hasAction('RandomLifetime')
	
	local SpawnProperties = {
		SpawnCount = self:_callAction("Count") or self:_callAction("RandomCount") or 1,
		LifeTime = self:_callAction("Lifetime") or self:_callAction("RandomLifetime") or 5
	}
	
	for i = 1, SpawnProperties.SpawnCount do
		local NewClone = self:_cloneInstance(SpawnPosition)
		NewClone.Parent = self.AccentPart or self.ParentTo
		
		self.OnSpawned:Fire(NewClone)
		
		SpawnProperties.LifeTime = RandomizeLifetime and self:_callAction("RandomLifetime") or SpawnProperties.LifeTime
		task.delay(SpawnProperties.LifeTime, function()
			if not NewClone.Parent and not table.find(self.CloneStorage, NewClone) then return end
			self:Despawn(NewClone)
		end)
	end
	
	return self
end

function AccentComponent.Despawn(self: AccentComponent, Inst: Instance)
	local index = table.find(self.CloneStorage, Inst)
	table.remove(self.CloneStorage, index)
	
	self.OnDespawned:Fire(Inst)
	local jmosSafetyCheck
	jmosSafetyCheck = task.delay(4, function ()
		if not Inst or not Inst.Parent then return end

		warn('I think sumt is wrong! Emergency destory instance protocol is activating!!!!');
		
		(Inst::any):Destroy()
		jmosSafetyCheck = nil
	end)
	repeat task.wait() until self._despawnDone
	Inst:Destroy()
	if jmosSafetyCheck then
		task.cancel(jmosSafetyCheck)
	end
	
	return self
end

function AccentComponent.Destroy(self: AccentComponent)
	table.clear(self :: any)
	setmetatable(self :: any, nil)
end

function AccentComponent._completeReaction(self: AccentComponent, HandlerIndex: number)
	if self._map[HandlerIndex] ~= nil then
		self._map[HandlerIndex] = true
	end
	
	for i, v in self._map do
		if not v then
			return
		end
	end
	
	self._despawnDone = true
end

-- temp
function AccentComponent._hasAction(self: AccentComponent, ActionName: string, ...: any): boolean
	for i, v in Config.Actions :: any do
		if i ~= ActionName then continue end

		for _, j in self._actions do
			if j.Handler == v then
				return true
			end
		end
	end

	return false
end

-- TEMPPP (green fn!)
function AccentComponent._callAction(self: AccentComponent, ActionName: string, ...: any): any?
	for i, v in Config.Actions :: any do
		if i ~= ActionName then continue end

		for _, j in self._actions do
			if j.Handler == v then
				return j.Handler(..., j.Props)
			end
		end
	end
	
	return false
end

function AccentComponent._cloneInstance (self: AccentComponent, Position: Vector3): Instance
	local Clone = self.Instance:Clone()
	
	if Clone:IsA('BasePart') then
		Clone.Position = Position
	elseif Clone:IsA('Model') then
		Clone:PivotTo(CFrame.new(Position))
	end
	
	table.insert(self.CloneStorage, Clone)
	
	return Clone
end

function AccentComponent._createPart(self: AccentComponent, Position: Vector3): Part
	local Clone = CACHED_PART:Clone()
	
	self:_callAction("MutateSpawnPart", Clone)
	self:_callAction("AddCenterAttachment", Clone)
	
	Clone.Position = Position
	Clone.Parent = self.ParentTo
	
	return Clone
end

return {
	new = AccentComponent.new
}