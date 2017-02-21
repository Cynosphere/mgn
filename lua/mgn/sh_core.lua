mgn = mgn or {Stage = {}}

if SERVER then
	include("sv_core.lua")
else
	include("cl_core.lua")
end

mgn.OverloadStage = mgn.Stage.Idle
mgn.OverloadStart = 0

function mgn.GetOverloadStage()
	return mgn.OverloadStage
end

function mgn.GetOverloadStart()
	return mgn.OverloadStart
end

function mgn.IsOverloading()
	return mgn.GetOverloadStage() ~= mgn.Stage.Idle
end

hook.Add("PlayerNoClip", "mgn.PlayerNoClip", function(ply)
	if mgn.IsOverloading() and ply:GetMoveType() ~= MOVETYPE_NOCLIP then
		return false
	end
end)

hook.Add("Think", "mgn.StageLogic", function()
	local stage = mgn.GetOverloadStage()
	-- This stage is permanent since it can't tell us when it ends
	if not stage.Think then
		return
	end

	local curtime = CurTime()
	if not stage.Started then
		stage.StartTime = curtime

		if stage.Start then
			stage:Start(curtime)
		end

		stage.Started = true
	end

	if not stage:Think(curtime - stage.StartTime) then
		if stage.End then
			stage:End(curtime)
		end

		mgn.OverloadStage = stage.Next
	end
end)
