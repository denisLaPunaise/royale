--!strict
--[[
	Prefabs — les cachettes propres a Royale, en plus de celles de Survivor
	(abri, benne, caisses, buisson, tole, voiture) : le casier du Lycee, les
	roseaux du Marais, le carton, l'armoire (CONCEPT.md, Cachettes).

	Meme forme que celles de Survivor, que le jeu sait deja poser : un Model
	dont la `Socle` invisible se pose sur l'emplacement (sol a y = 0), avec un
	marqueur `Interieur` (ou l'on se tient cache) et une ou plusieurs
	`Sortie`.
]]

return function(O: any, CONTRACT: any)
	local C, P = O.C, O.P
	local random: Random = O.random

	local function root(parent: Instance, name: string, footprint: Vector3): Model
		local m = O.model(parent, name)
		local socle = P(
			m,
			"Socle",
			Vector3.new(footprint.X, 1, footprint.Z),
			CFrame.new(0, 0.5, 0),
			Enum.Material.SmoothPlastic,
			C.black,
			{
				transparency = 1,
				collide = false,
				query = false,
				shadow = false,
			}
		)
		m.PrimaryPart = socle
		return m
	end

	local function build(storage: Instance)
		-- Le casier : une rangee de trois portes de metal, celle du milieu
		-- assez large pour s'y glisser.
		do
			local m = root(storage, "Casier", Vector3.new(6, 1, 2.4))
			local color = Color3.fromRGB(70, 90, 104)
			P(
				m,
				"Caisson",
				Vector3.new(6.2, 7.4, 0.3),
				CFrame.new(0, 3.7, -1.1),
				Enum.Material.Metal,
				color
			)
			for _, sx in { -1, 1 } do
				P(
					m,
					"Cote",
					Vector3.new(0.3, 7.4, 2.4),
					CFrame.new(sx * 3.1, 3.7, 0),
					Enum.Material.Metal,
					color
				)
			end
			P(
				m,
				"Dessus",
				Vector3.new(6.2, 0.3, 2.4),
				CFrame.new(0, 7.4, 0),
				Enum.Material.Metal,
				color
			)
			for k = -1, 1 do
				local door = P(
					m,
					"Porte",
					Vector3.new(1.95, 7, 0.15),
					CFrame.new(k * 2.05, 3.6, 1.15),
					Enum.Material.Metal,
					color:Lerp(Color3.new(1, 1, 1), 0.08)
				)
				-- Les fentes d'aeration : on voit dehors a travers (CONCEPT.md :
				-- depuis un abri ferme, on voit par l'ouverture).
				for v = 0, 2 do
					P(
						m,
						"Fente",
						Vector3.new(1.2, 0.12, 0.05),
						door.CFrame * CFrame.new(0, 2.4 + v * 0.35, 0.1),
						Enum.Material.SmoothPlastic,
						C.black
					)
				end
			end
			O.marker(m, CONTRACT.inside, CFrame.new(0, 3, 0))
			O.marker(m, CONTRACT.exit, CFrame.new(0, 3, 3))
		end

		-- Les roseaux : un volume ou l'on bouge librement, qui couvre a moitie.
		do
			local m = root(storage, "Roseaux", Vector3.new(10, 1, 10))
			for _ = 1, 46 do
				local h = random:NextNumber(5, 8)
				local x, z = random:NextNumber(-4.6, 4.6), random:NextNumber(-4.6, 4.6)
				local reed = P(
					m,
					"Roseau",
					Vector3.new(0.25, h, 0.25),
					CFrame.new(x, h / 2, z)
						* CFrame.Angles(
							random:NextNumber(-0.15, 0.15),
							0,
							random:NextNumber(-0.15, 0.15)
						),
					Enum.Material.Grass,
					Color3.fromRGB(112, 110, 70),
					{ collide = false }
				)
				reed:SetAttribute(CONTRACT.cover, 0.5)
			end
			O.marker(m, CONTRACT.inside, CFrame.new(0, 2, 0))
			O.marker(m, CONTRACT.exit, CFrame.new(0, 2, 6))
		end

		-- Le carton : une grande boite de demenagement, fragile.
		do
			local m = root(storage, "Carton", Vector3.new(5, 1, 5))
			local kraft = Color3.fromRGB(150, 118, 82)
			P(
				m,
				"Boite",
				Vector3.new(4.6, 4.2, 4.6),
				CFrame.new(0, 2.1, 0),
				Enum.Material.Cardboard,
				kraft
			)
			P(
				m,
				"Rabat",
				Vector3.new(4.6, 0.1, 2.2),
				CFrame.new(0, 4.4, 2.6) * CFrame.Angles(math.rad(-50), 0, 0),
				Enum.Material.Cardboard,
				kraft
			)
			O.marker(m, CONTRACT.inside, CFrame.new(0, 1.6, 0))
			O.marker(m, CONTRACT.exit, CFrame.new(0, 2, 4))
		end

		-- L'armoire : protege meme sans toit, mais elle est dans une maison.
		do
			local m = root(storage, "Armoire", Vector3.new(5, 1, 2.6))
			P(
				m,
				"Corps",
				Vector3.new(5, 8, 0.3),
				CFrame.new(0, 4, -1.15),
				Enum.Material.WoodPlanks,
				C.wood
			)
			for _, sx in { -1, 1 } do
				P(
					m,
					"Cote",
					Vector3.new(0.3, 8, 2.6),
					CFrame.new(sx * 2.5, 4, 0),
					Enum.Material.WoodPlanks,
					C.wood
				)
				P(
					m,
					"Porte",
					Vector3.new(2.45, 7.6, 0.2),
					CFrame.new(sx * 1.25, 4, 1.2),
					Enum.Material.WoodPlanks,
					C.wood:Lerp(Color3.new(0, 0, 0), 0.1)
				)
			end
			P(
				m,
				"Dessus",
				Vector3.new(5.2, 0.4, 2.8),
				CFrame.new(0, 8.1, 0),
				Enum.Material.WoodPlanks,
				C.wood
			)
			O.marker(m, CONTRACT.inside, CFrame.new(0, 3, 0))
			O.marker(m, CONTRACT.exit, CFrame.new(0, 3, 3))
		end
	end

	return { build = build }
end
