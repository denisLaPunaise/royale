--!strict
--[[
	Le salon avec les vrais reglages : les groupes (inviter, quitter, le chef
	qui part), le mode qui suit la taille du groupe, qui part au compte a
	rebours.
]]

local Config = require("../../src/shared/Config")
local Lobby = require("../../src/shared/Lobby")

local harness = require("../harness")

return function(t: harness.Harness)
	local LB = Config.lobby
	local sizes = Config.squads.sizes

	t.section("Les groupes")
	local s = Lobby.new()
	for _, id in { "josh", "ami", "autre", "x", "y" } do
		Lobby.add(s, id, "solo")
	end
	t.check("chacun seul au depart", s.groupOf.josh == "josh" and s.groupOf.ami == "ami")
	t.check("ami accepte l'invitation de josh", Lobby.join(s, "josh", "ami", LB.maxGroup))
	t.check("ils sont ensemble, josh chef", s.groupOf.ami == "josh" and #s.groups.josh.members == 2)
	t.check("pas deux fois", not Lobby.join(s, "josh", "ami", LB.maxGroup))
	Lobby.join(s, "josh", "autre", LB.maxGroup)
	Lobby.join(s, "josh", "x", LB.maxGroup)
	t.check("4 au plus", not Lobby.join(s, "josh", "y", LB.maxGroup))
	Lobby.leave(s, "josh", true)
	t.check(
		"le chef part : le suivant devient chef",
		s.groupOf.ami == "ami" and #s.groups.ami.members == 3
	)
	t.check("et lui est seul de nouveau", s.groupOf.josh == "josh")

	t.section("Le mode")
	Lobby.cycleMode(s, "ami", LB.modes, sizes)
	t.equal("un groupe de 3 saute solo et duo : escouade", s.groups.ami.mode, "squad")
	Lobby.cycleMode(s, "josh", LB.modes, sizes)
	t.equal("seul, solo puis duo", s.groups.josh.mode, "duo")
	Lobby.setReady(s, "autre", true, sizes)
	t.check("seul le chef se dit pret", not s.groups.ami.ready)
	Lobby.setReady(s, "ami", true, sizes)
	t.check("le chef, oui", s.groups.ami.ready)
	t.equal("les groupes prets de l'escouade", #Lobby.readyGroups(s, "squad"), 1)
	t.equal("personne en solo", #Lobby.readyGroups(s, "solo"), 0)
	Lobby.join(s, "ami", "josh", LB.maxGroup)
	t.check("quelqu'un arrive : le groupe n'est plus pret", not s.groups.ami.ready)

	t.section("Les reglages")
	t.check(
		"les modes du salon existent tous",
		sizes[LB.modes[1]] and sizes[LB.modes[2]] and sizes[LB.modes[3]] and true or false
	)
	t.check("un groupe tient dans l'escouade", LB.maxGroup == sizes.squad)
	t.check(
		"le compte a rebours laisse le temps de se joindre (10 s au moins)",
		LB.countdownSeconds >= 10
	)
end
