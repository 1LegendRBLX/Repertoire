local Config = {}

Config.Actions = {

	AddCenterAttachment = function(Inst: BasePart | Model, Properties: { Name: string } )
		local Attachment = Instance.new("Attachment")
		if Properties and Properties.Name then
			Attachment.Name = Properties.Name
		end
		Attachment.Parent = Inst
	end,

	--EnabledTime = function(Sound: Sound, Properties: { string } )

	--end,
}


Config.Reactions = {

	BreakWelds = function(Inst: Instance)
		local function DestroyJoints(Parent: Instance)
			if not Parent:IsA("BasePart") then return end

			for _, Joint in Parent:GetJoints() do
				Joint:Destroy()
			end
		end

		if Inst:IsA("BasePart") then
			DestroyJoints(Inst)

		elseif Inst:IsA("Model") then
			for _, Descendant in Inst:GetDescendants() do
				DestroyJoints(Descendant)
			end
		end
	end, 
}
--SetParent = function(Inst: Instance, Properties: { string } )

--end,

--SetScale = function(Inst: BasePart | Model, Properties: { string } )

--end,

--SetColor = function(Inst: BasePart | Model, Properties: { string } )

--end,

--RandomColor = function(Inst: BasePart | Model, Properties: { string } )

--end,

--RandomPlay = function(Sound: Sound, Properties: { string } )

--end,

--EmitCount = function(Sound: Sound, Properties: { string } )

--end,

--Force = function(Sound: Sound, Properties: { string } )

--end,

Config.Connections = {

}

Config.Validation = {
	Sound = {
		--Config.Actions.AddCenterAttachment
		--Config.Actions.RandomPlay
	},
	BasePart = {
		--Config.Actions.Force
	},
	ParticleEmitter = {
		--Config.Actions.AddCenterAttachment
	},
	Instance = {

	}
} :: { [string]: any }

return Config