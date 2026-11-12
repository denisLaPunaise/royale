--!strict
--[[
	Plan — ou est chaque zone. La seule source des positions : le socle, les
	zones et la mesure de fin lisent tous ce plan.

	Repere (vu du ciel) : X vers l'est, Z vers le nord, comme Survivor. La
	carte jouable fait 1600 x 1600 studs, centree sur le Cratere, juste sous
	l'Oeil (docs/CONCEPT.md, La carte).

	Chaque zone est un rectangle [minX, maxX] x [minZ, maxZ] : c'est la ou elle
	construit et ou le socle aplanit le sol, a SA hauteur. Les bords se fondent
	dans la campagne entre les zones (`BLEND`), pour qu'aucune limite ne se
	voie. Le relief n'est pas symetrique (Josh, 12 novembre 2026 : « pas un
	amphitheatre ») : les zones sont a des hauteurs differentes, une riviere
	traverse la carte, les montagnes du bord sont inegales.
]]

export type Zone = {
	name: string,
	minX: number,
	maxX: number,
	minZ: number,
	maxZ: number,
	-- 0 = le sol garde tout son relief ; 1 = parfaitement plat (une ville).
	flat: number,
	-- La hauteur du sol de la zone.
	ground: number,
}

local Plan = {}

-- La moitie du cote de la carte jouable.
Plan.HALF = 800

-- Ce que le terrain couvre autour du centre : au-dela de la carte, les
-- montagnes au nord, a l'est et au sud, la mer a l'ouest, ferment l'horizon.
Plan.OUTER = 2000

-- La cote : la mer commence a l'ouest de cette ligne (elle forme des anses).
Plan.COAST_X = -700
-- Le niveau de la mer, de la riviere et des mares du Marais.
Plan.SEA_LEVEL = -2

-- Le Cratere, au centre, sous la Fissure.
Plan.CRATER = { x = 0, z = 0, radius = 170, depth = 18 }

-- Sur combien de studs le bord d'une zone se fond dans la campagne : assez
-- pour que les pentes entre deux zones de hauteurs differentes soient douces.
Plan.BLEND = 140

-- Les hauteurs racontent le lieu : la Fete foraine sur sa colline, le Lycee
-- sur un plateau, la Banlieue a flanc de pente, l'Hypermarche et la Gare dans
-- la plaine, le Marais en contrebas, le Port au niveau de la mer.
Plan.zones = {
	{ name = "PortEchoue", minX = -690, maxX = -280, minZ = 0, maxZ = 600, flat = 0.9, ground = 2 },
	{ name = "Lycee", minX = -250, maxX = 220, minZ = 330, maxZ = 760, flat = 1, ground = 22 },
	{
		name = "FeteForaine",
		minX = 250,
		maxX = 760,
		minZ = 350,
		maxZ = 760,
		flat = 0.8,
		ground = 34,
	},
	{
		name = "Banlieue",
		minX = 200,
		maxX = 760,
		minZ = -260,
		maxZ = 300,
		flat = 0.85,
		ground = 12,
	},
	{
		name = "Hypermarche",
		minX = 210,
		maxX = 760,
		minZ = -580,
		maxZ = -350,
		flat = 1,
		ground = 3,
	},
	{
		name = "Marais",
		minX = -640,
		maxX = -200,
		minZ = -560,
		maxZ = -20,
		flat = 0.4,
		ground = -2.5,
	},
	{
		name = "GareDeTriage",
		minX = -650,
		maxX = 760,
		minZ = -780,
		maxZ = -610,
		flat = 1,
		ground = 1,
	},
} :: { Zone }

-- La riviere : elle descend des montagnes de l'est, passe entre la Banlieue
-- et l'Hypermarche, au sud du Cratere, traverse le Marais et se jette dans
-- la mer. Ses ponts seront des cachettes (« dessous de pont »).
Plan.RIVER = {
	width = 22,
	depth = 4,
	points = {
		{ 1450, -330 },
		{ 760, -310 },
		{ 420, -300 },
		{ 180, -280 },
		{ 0, -290 },
		{ -200, -300 },
		{ -420, -255 },
		{ -600, -300 },
		{ -950, -290 },
	},
}

-- Les collines de la campagne, entre les zones. Chacune a sa forme
-- (`stretch` l'allonge du nord au sud) : pas deux bosses pareilles.
Plan.HILLS = {
	-- Au nord-ouest, au-dessus du Port : elle tombe en falaise dans la mer.
	{ x = -470, z = 760, radius = 200, height = 55, stretch = 1.3 },
	-- Au nord, derriere le Lycee : la ville est adossee a une butte.
	{ x = -80, z = 880, radius = 220, height = 60, stretch = 0.6 },
	-- Entre le Cratere et le Lycee.
	{ x = -120, z = 230, radius = 130, height = 24, stretch = 0.7 },
	-- Au sud du Cratere, entre le Marais et l'Hypermarche.
	{ x = 60, z = -470, radius = 150, height = 26, stretch = 1.3 },
	-- Au sud-ouest, un cap rocheux sur la mer, au bout de la Gare.
	{ x = -780, z = -640, radius = 160, height = 40, stretch = 1 },
}

-- Les chaines de montagnes et de collines autour de la vallee, comme sur une
-- vraie cote (une vallee qui s'ouvre sur la mer) : un massif haut au
-- nord-est, une crete a l'est coupee par la gorge de la riviere, des
-- hauteurs au sud-est, de simples collines au sud qui finissent en falaise
-- sur la mer. Elles restent hors des zones et laissent passer la riviere.
Plan.RIDGES = {
	-- Le massif du nord-est, le plus haut.
	{
		width = 460,
		height = 230,
		points = { { -250, 1300 }, { 350, 1150 }, { 900, 1200 }, { 1350, 1000 }, { 1600, 550 } },
	},
	-- Un eperon du massif qui descend vers la butte du Lycee.
	{ width = 220, height = 55, points = { { 350, 1150 }, { 120, 980 }, { -60, 940 } } },
	-- La crete de l'est, jusqu'a la gorge de la riviere.
	{ width = 340, height = 150, points = { { 1350, 800 }, { 1200, 300 }, { 1280, -170 } } },
	-- Les hauteurs du sud-est, de l'autre cote de la gorge.
	{ width = 300, height = 95, points = { { 1250, -520 }, { 1080, -900 }, { 700, -1250 } } },
	-- Les collines du sud, basses : la plaine ou sort la voie ferree.
	{
		width = 260,
		height = 38,
		points = { { 500, -1200 }, { -100, -1120 }, { -600, -1230 }, { -900, -1050 } },
	},
}

-- Le Quartier suspendu flotte au-dessus du nord de la Banlieue : il n'a pas
-- de sol a lui.
Plan.SUSPENDED = { minX = 290, maxX = 760, minZ = 80, maxZ = 270, height = 55 }

return Plan
