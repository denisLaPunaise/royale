--!strict
--[[
	Les liaisons — les routes de campagne qui relient les zones, et les ponts
	sur la riviere. Elles passent en premier : les zones construisent ensuite
	autour de la place qu'elles ont prise.

	Les routes ne sont pas des droites : elles suivent le relief, contournent
	le Cratere et les collines, comme une vraie departementale. Sous chaque
	pont, une cachette solide (CONCEPT.md : « dessous de pont »).
]]

local ROAD_WIDTH = 14

return function(K: any)
	local O, V = K.O, K.V
	local C, P = O.C, O.P
	local random: Random = K.random
	local folder = K.zoneFolder("Liaisons")

	-- Trouve la riviere en travers d'une ligne nord-sud : rend le milieu de
	-- l'eau et sa largeur (au rayon, eau comprise).
	local waterParams = RaycastParams.new()
	waterParams.FilterType = Enum.RaycastFilterType.Include
	waterParams.FilterDescendantsInstances = { workspace.Terrain }
	waterParams.IgnoreWater = false
	local function riverAcross(x: number, zFrom: number, zTo: number): (number?, number)
		local first, last = nil, nil
		local step = if zTo > zFrom then 2 else -2
		for z = zFrom, zTo, step do
			local hit =
				workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -400, 0), waterParams)
			if hit and hit.Material == Enum.Material.Water then
				first = first or z
				last = z
			elseif first then
				break
			end
		end
		if first == nil or last == nil then
			return nil, 0
		end
		return (first + last) / 2, math.abs(last - first)
	end

	local bridges = 0
	-- Un pont : tablier, parapets, piles. Rend les deux extremites.
	local function bridge(x: number, zCenter: number, span: number)
		local m = O.model(folder, "Pont")
		local half = span / 2 + 16
		local zA, zB = zCenter - half, zCenter + half
		local yA, yB = K.ground(x, zA), K.ground(x, zB)
		local deckY = math.max(yA, yB) + 1.2
		local a, b = Vector3.new(x, deckY, zA), Vector3.new(x, deckY, zB)
		local cf = CFrame.lookAt((a + b) / 2, b)
		local len = (b - a).Magnitude
		P(
			m,
			"Tablier",
			Vector3.new(ROAD_WIDTH + 2, 1.6, len),
			cf,
			Enum.Material.Concrete,
			C.concrete
		)
		P(
			m,
			"Chaussee",
			Vector3.new(ROAD_WIDTH, 0.3, len),
			cf * CFrame.new(0, 0.95, 0),
			Enum.Material.Asphalt,
			C.asphalt
		)
		for _, sx in { -1, 1 } do
			-- Un parapet ebreche : des trous la ou un morceau est tombe.
			local pieces = math.floor(len / 6)
			for k = 0, pieces - 1 do
				if random:NextNumber() > 0.12 then
					P(
						m,
						"Parapet",
						Vector3.new(0.8, 2.6, 5.8),
						cf * CFrame.new(sx * (ROAD_WIDTH / 2 + 0.6), 2.1, -len / 2 + (k + 0.5) * 6),
						Enum.Material.Concrete,
						C.concreteDark
					)
				end
			end
		end
		-- Les piles, dans l'eau, et les culees sur les berges.
		for _, t in { -0.22, 0.22 } do
			local pz = zCenter + t * span
			local floorY = K.ground(x, pz)
			P(
				m,
				"Pile",
				Vector3.new(4, deckY - floorY + 2, 4),
				CFrame.new(x, (deckY + floorY) / 2 - 1, pz),
				Enum.Material.Concrete,
				C.concreteDark
			)
		end
		-- La cachette solide sous le tablier, contre la culee : a l'ombre du
		-- pont, l'Oeil ne voit pas.
		local spot = O.model(K.solid, "DessousDePont" .. (bridges + 1))
		local underZ = zCenter - span / 2 - 4
		local underY = K.ground(x, underZ)
		O.marker(spot, K.CONTRACT.inside, CFrame.new(x, underY + 2.5, underZ))
		O.marker(spot, K.CONTRACT.exit, CFrame.new(x + ROAD_WIDTH / 2 + 5, underY + 3, underZ))
		bridges += 1
		K.claim(x, zCenter, half)
		return Vector2.new(x, zA), Vector2.new(x, zB)
	end

	-- Une route de campagne qui traverse la riviere : on coupe la ligne la
	-- ou est l'eau, on pose le pont, on route les deux bouts.
	local function roadAcross(points: { Vector2 }, crossX: number, zFrom: number, zTo: number)
		local zc, span = riverAcross(crossX, zFrom, zTo)
		if zc == nil then
			-- Pas de riviere trouvee : la route passe tout droit.
			K.road(folder, K.spline(points, 14), ROAD_WIDTH, false)
			return
		end
		local a, b = bridge(crossX, zc, span)
		local before, after = {}, {}
		for _, p in points do
			local onNorth = p.Y > zc
			local isStartNorth = points[1].Y > zc
			if onNorth == isStartNorth then
				table.insert(before, p)
			else
				table.insert(after, p)
			end
		end
		local startNorth = points[1].Y > zc
		table.insert(before, if startNorth then b else a)
		table.insert(after, 1, if startNorth then a else b)
		K.road(folder, K.spline(before, 14), ROAD_WIDTH, false)
		K.road(folder, K.spline(after, 14), ROAD_WIDTH, false)
	end

	-- Du Port a l'entree ouest de la Banlieue, entre le Cratere et le Lycee.
	K.road(
		folder,
		K.spline({
			Vector2.new(-300, 300),
			Vector2.new(-200, 268),
			Vector2.new(-60, 300),
			Vector2.new(60, 255),
			Vector2.new(130, 120),
			Vector2.new(150, 40),
		}, 14),
		ROAD_WIDTH,
		false
	)
	-- Du Lycee a la Fete foraine, a flanc de pente.
	K.road(
		folder,
		K.spline({ Vector2.new(215, 520), Vector2.new(250, 500) }, 14),
		ROAD_WIDTH,
		false
	)
	-- De la Banlieue a l'Hypermarche, par le pont de l'est.
	roadAcross({
		Vector2.new(426, -250),
		Vector2.new(426, -290),
		Vector2.new(432, -330),
		Vector2.new(440, -360),
	}, 428, -250, -350)
	-- Du Cratere a la Gare, par le pont du milieu.
	roadAcross({
		Vector2.new(30, -240),
		Vector2.new(20, -275),
		Vector2.new(24, -320),
		Vector2.new(70, -420),
		Vector2.new(60, -520),
		Vector2.new(40, -600),
	}, 22, -240, -340)
	-- Du Port au Marais et a la Gare, par le pont de l'ouest.
	roadAcross({
		Vector2.new(-470, 0),
		Vector2.new(-455, -120),
		Vector2.new(-440, -220),
		Vector2.new(-438, -290),
		Vector2.new(-450, -420),
		Vector2.new(-420, -600),
	}, -440, -190, -330)
	-- La route du sud, le long de la Gare.
	K.road(
		folder,
		K.spline({
			Vector2.new(-600, -598),
			Vector2.new(-420, -600),
			Vector2.new(-150, -588),
			Vector2.new(40, -600),
			Vector2.new(260, -596),
			Vector2.new(600, -600),
		}, 14),
		ROAD_WIDTH,
		false
	)

	-- Des poteaux electriques le long des routes de campagne, penches.
	for _, route in folder:GetChildren() do
		if route.Name == "Route" then
			local parts = route:GetChildren()
			for i = 1, #parts, 7 do
				local seg = parts[i]
				if seg:IsA("BasePart") and seg.Name == "Chaussee" then
					local side = (seg.CFrame.RightVector * (ROAD_WIDTH / 2 + 3))
					local base = seg.Position + side
					local y = K.ground(base.X, base.Z)
					P(
						folder,
						"Poteau",
						Vector3.new(18, 0.9, 0.9),
						CFrame.new(base.X, y + 9, base.Z)
							* CFrame.Angles(
								math.rad(random:NextNumber(-4, 4)),
								0,
								math.rad(90 + random:NextNumber(-5, 5))
							),
						Enum.Material.Wood,
						C.woodGray,
						{ shape = Enum.PartType.Cylinder }
					)
				end
			end
		end
	end
	_ = V

	-- Des cones abandonnes au bord des routes et a l'entree des ponts : un
	-- chantier interrompu le jour de la Fissure.
	for _, route in folder:GetChildren() do
		if route.Name == "Route" then
			for _, seg in route:GetChildren() do
				if
					seg:IsA("BasePart")
					and seg.Name == "Chaussee"
					and random:NextNumber() < 0.06
				then
					for k = 0, random:NextInteger(1, 3) do
						local at = seg.CFrame * CFrame.new(ROAD_WIDTH / 2 - 1.5, 0.2, -6 + k * 4)
						local fallen = random:NextNumber() < 0.3
						K.prop(
							folder,
							"Cone",
							CFrame.new(at.Position)
								* CFrame.Angles(0, random:NextNumber(0, 6), 0)
								* (
									if fallen
										then CFrame.new(0, 0.8, 0) * CFrame.Angles(
											math.rad(85),
											0,
											0
										)
										else CFrame.identity
								)
						)
					end
				end
			end
		end
	end

	local function measure(problems: { string })
		if bridges < 3 then
			table.insert(
				problems,
				string.format(
					"Liaisons : %d pont(s) seulement, la riviere n'a pas ete trouvee partout",
					bridges
				)
			)
		end
	end

	return {
		measure = measure,
		summary = string.format("Liaisons : routes de campagne et %d ponts", bridges),
	}
end
