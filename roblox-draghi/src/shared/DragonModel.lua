-- Costruisce un drago a blocchi con le forme di Roblox, senza modelli esterni.
-- Il client lo muove ogni frame con Pose(); le ali sbattono da sole.
local Dragons = require(script.Parent.Config.Dragons)
local Elements = require(script.Parent.Config.Elements)

local DragonModel = {}

local function part(parent, size, color, ellipsoid, material)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = material or Enum.Material.SmoothPlastic
	p.Color = color
	p.Size = size
	if ellipsoid then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
	end
	p.Parent = parent
	return p
end

-- Ritorna { Model, Root, Pieces } dove ogni pezzo ha Offset (e Wing = +1/-1 per le ali).
function DragonModel.Build(dragonId: string, shiny: boolean?, scale: number?)
	local def = Dragons.Get(dragonId) or Dragons.Get("SproutDrake")
	local el = Elements.List[def.Element] or Elements.List.Nature
	local s = scale or 1
	local main = el.Color
	local accent = el.Color2
	if shiny then
		main = main:Lerp(Color3.new(1, 1, 1), 0.35)
	end

	local model = Instance.new("Model")
	model.Name = def.Name
	local pieces = {}

	local function add(size, color, offset, ellipsoid, material)
		local p = part(model, size * s, color, ellipsoid, material)
		local o = offset
		o = CFrame.new(o.Position * s) * (o - o.Position)
		table.insert(pieces, { Part = p, Offset = o })
		return p
	end

	local body = add(Vector3.new(2, 1.8, 2.8), main, CFrame.new(0, 0, 0), true)
	add(Vector3.new(1.4, 1.1, 2), accent, CFrame.new(0, -0.4, -0.2), true)
	add(Vector3.new(1.6, 1.5, 1.6), main, CFrame.new(0, 0.95, -1.5), true)
	add(Vector3.new(1, 0.7, 0.9), main, CFrame.new(0, 0.7, -2.3), true)
	add(Vector3.new(0.7, 0.7, 2.2), main, CFrame.new(0, -0.1, 1.9) * CFrame.Angles(0.35, 0, 0), true)
	add(Vector3.new(0.2, 0.7, 0.7), accent, CFrame.new(0, 0.35, 3) * CFrame.Angles(0.35, 0, 0))
	for _, side in { -1, 1 } do
		add(Vector3.new(0.45, 0.45, 0.45), Color3.new(1, 1, 1), CFrame.new(0.45 * side, 1.2, -2.1), true)
		add(Vector3.new(0.24, 0.24, 0.24), Color3.fromRGB(20, 17, 28), CFrame.new(0.47 * side, 1.2, -2.3), true)
		add(Vector3.new(0.25, 0.75, 0.25), accent, CFrame.new(0.4 * side, 1.85, -1.3) * CFrame.Angles(-0.45, 0, 0.25 * side))
		add(Vector3.new(0.5, 0.8, 0.5), main, CFrame.new(0.6 * side, -0.9, -0.6), true)
		local wing = part(model, Vector3.new(2.6, 0.15, 1.7) * s, accent, false)
		wing.Transparency = 0.05
		table.insert(pieces, { Part = wing, Wing = side, Hinge = CFrame.new(1 * side * s, 0.6 * s, 0.2 * s), Out = CFrame.new(1.3 * side * s, 0, 0) })
	end
	if def.Crown then
		local gold = Color3.fromRGB(255, 210, 61)
		add(Vector3.new(1, 0.25, 1), gold, CFrame.new(0, 1.75, -1.5), false, Enum.Material.Neon)
		for i = -1, 1 do
			add(Vector3.new(0.22, 0.5, 0.22), gold, CFrame.new(0.35 * i, 2.05, -1.5), false, Enum.Material.Neon)
		end
	end

	if shiny then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = Color3.new(1, 1, 1)
		sparkles.Parent = body
	end
	local rarity = def.Rarity
	if rarity == "Legendary" or rarity == "Limited" or rarity == "Exclusive" then
		local light = Instance.new("PointLight")
		light.Color = el.Color
		light.Range = 10 * s
		light.Brightness = 1.2
		light.Parent = body
	end

	model.PrimaryPart = body
	return { Model = model, Root = body, Pieces = pieces, Scale = s }
end

-- Mette il drago nella posizione `cf`. `t` serve per far sbattere le ali.
-- Ritorna le liste parti/posizioni da passare a workspace:BulkMoveTo.
function DragonModel.Pose(rig, cf: CFrame, t: number, parts, cframes)
	local flap = math.sin(t * 9) * 0.55
	for _, piece in rig.Pieces do
		local target
		if piece.Wing then
			target = cf * piece.Hinge * CFrame.Angles(0, 0, flap * piece.Wing) * piece.Out
		else
			target = cf * piece.Offset
		end
		table.insert(parts, piece.Part)
		table.insert(cframes, target)
	end
end

return DragonModel
