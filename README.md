# Repertoire

Repertoire is a package designed to make front-end visuals abstracted and personalized for developers. Internally, it creates objects and enables the attachment of dynamic components such as forces, randomized properties, and more!

Repertoire is designed to support:
- BaseParts
- Models
- ParticleEmitters
- Sounds

<img width="540" height="540" alt="repertoire_bomb" src="https://github.com/user-attachments/assets/ac937851-a354-468d-a44b-43e9cab964ec" />

## Usage

Repertoire primarily uses an **AccentComponent**, which is an object that orchestrates front-end components and attaches them to instances. You can create and spawn one with:
```lua
local AccentObject = Repertoire.Accent(somePart)
AccentObject:Spawn(Vector3.zero)
```

### Some ways to use Accents
- Add a `RandomPlay` reaction to a sound and hook it to `OnSpawned` to randomize sound properties when spawned.
- Add a `RandomLifetime` or `RandomCount` action to add randomness to the clones spawned from the accent.

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

**Actions**: Mutates properties and handles specific functionality within the Repertoire process.
**Reactions**: Pre-configured functions meant to connect to signals.

### Example
```lua
local Repertoire = require(Repertoire)

local Reactions = Repertoire.Reactions
local Actions = Repertoire.Actions
local Accent = Repertoire.Accent
local Scene = Repertoire.Scene

local Bomb = Accent(someBombPart)

-- this bomb part will have a lifetime between 1 and 2 seconds
Bomb:AddAction(Actions.RandomLifetime):Props({
    Min = 1, 
    Max = 2
}) -- fully typed with intellisense!

-- the bomb part will fly up in the air every time it is spawned
Bomb:AddReaction(Reactions.Force):Hook(Bomb.OnSpawned):Props({
	Velocity = 15,
	Direction = Vector3.yAxis,
	RandomRange = 30,
	Spread = 45,
})

-- the bomb part will tween to a scale of 0.1 when it is supposed to despawn.
Bomb:AddReaction(Reactions.TweenScale):Hook(Bomb.OnDespawned):Props({
	Scale = 0.1,
	TweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
})

-- the bomb will play at the given destination
Bomb:Spawn(Vector3.zero)
```
