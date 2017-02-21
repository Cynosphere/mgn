include("cl_vox.lua")
include("cl_explosion.lua")

file.CreateDir("mgn/sound")

surface.CreateFont("MGN_Alert", {
	font = "Arial Black",
	size = ScreenScale(12),
	outline = false,
	weight = 0,
	antialias = true
})

surface.CreateFont("MGN_Countdown", {
	font = "Roboto Bk",
	size = ScreenScale(42),
	outline = false,
	antialias = true
})

mgn.MusicDownload = "https://files.metaman.xyz/mgn/sound/countdown_music.mp3"
mgn.IntroMusicDownload = "https://tenrys.montoyo.net/ShareX/2017/Feb/intro_countdown_music.mp3"
mgn.MusicPath = "mgn/sound/countdown_music.dat"
mgn.IntroMusicPath = "mgn/sound/intro_countdown_music.dat"
mgn.ETagPath = "mgn/sound/countdown_music.txt"
mgn.ETagPath2 = "mgn/sound/intro_countdown_music.txt"

do
	local etag = file.Read(mgn.ETagPath, "DATA")
	if etag == "" or not file.Exists(mgn.MusicPath, "DATA") then
		etag = nil
	end
	local etag2 = file.Read(mgn.ETagPath2, "DATA")
	if etag2 == "" or not file.Exists(mgn.IntroMusicPath, "DATA") then
		etag2 = nil
	end

	HTTP({
		method = "get",
		url = mgn.MusicDownload,
		headers = {["If-None-Match"] = etag},
		success = function(code, body, headers)
			if code == 200 then
				file.Write(mgn.MusicPath, body)
				file.Write(mgn.ETagPath, headers.ETag)
				print("[MGN] Finished downloading music!", #body)
			elseif code == 304 then
				print("[MGN] Music ETag is good!")
			end
		end,
		failed = function(reason)
			print("[MGN] Failed downloading music!", reason)
		end
	})

	HTTP({
		method = "get",
		url = mgn.IntroMusicDownload,
		headers = {["If-None-Match"] = etag2},
		success = function(code, body, headers)
			if code == 200 then
				file.Write(mgn.IntroMusicPath, body)
				file.Write(mgn.ETagPath2, headers.ETag)
				print("[MGN] Finished downloading intro music!", #body)
			elseif code == 304 then
				print("[MGN] Intro Music ETag is good!")
			end
		end,
		failed = function(reason)
			print("[MGN] Failed downloading intro music!", reason)
		end
	})
end

local function FormatTime(time)
	local seconds = time
	local minutes = math.floor((seconds / 60) % 60)
	local millisecs = math.floor((seconds - math.floor(seconds)) * 100)
	millisecs = millisecs > 99 and 99 or millisecs
	seconds = math.floor(seconds % 60)
	return string.format("%02d:%02d:%02d", minutes, seconds, millisecs)
end

local white = Color(255, 255, 255, 255)
local red = Color(255, 0, 0, 255)
hook.Add("HUDPaint", "mgn.HUDPaint", function()
	if not mgn.IsAlertActive() then
		return
	end

	local time_left = mgn.AlertLength - (CurTime() - mgn.GetAlertStart())
	if time_left <= 0 then
		return
	end

	draw.SimpleTextOutlined("████ ████████ IMMINENT! PLEASE EVACUATE THROUGH THE NEAREST EXIT!", "MGN_Alert", ScrW() * 0.5, ScrH() * 0.009, red, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 3, Color(0, 0, 0, 127))

	local color = white
	if time_left <= 30 then
		color = red
	end

	draw.SimpleTextOutlined(FormatTime(time_left), "MGN_Countdown", ScrW() * 0.5, ScrH() * 0.028, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 4, Color(0, 0, 0, 127))
end)

local goingToOverload = false
local introVolume = 0
local introLoading = false
local core
hook.Add("Think", "mgn.Think", function()
	-- CLIENTSIDE HACK TIME

	if IsValid(mgn.ControlComputer) then
		local alert_active = mgn.ControlComputer:IsAlertActive()
		local system_active = mgn.IsAlertActive()
		if not alert_active and system_active then
			mgn.SetAlertActive(false)
		elseif alert_active and not system_active then
			mgn.SetAlertActive(true, mgn.ControlComputer:GetAlertStart())
		end
	end

	-- END CLIENTSIDE HACK TIME

	core = core or ents.FindByClass("lua_core_effect")[1]
	introVolume = Lerp(FrameTime(), introVolume, goingToOverload and 0.7 or 0)
	if mgn.ControlComputer and mgn.ControlComputer:GetBoostLevel() >= 0.9 and not mgn.IsAlertActive() and not core:GetDTBool(3) then
		if not mgn.IntroMusic then
			if not introLoading then
				introLoading = true
				sound.PlayFile("data/" .. mgn.IntroMusicPath, "", function(channel, errID, errStr)
					if channel then
						mgn.IntroMusic = channel
						mgn.IntroMusic:SetTime(mgn.IntroMusic:GetLength() - 60)
						introLoading = false
					end
				end)
			end
		else
			introLoading = false
		end
		if LocalPlayer():IsInZone("reactor") and not goingToOverload then
			goingToOverload = true
		elseif not LocalPlayer():IsInZone("reactor") then
			goingToOverload = false
		end
	else
		if mgn.IntroMusic then
			mgn.IntroMusic:Stop()
			mgn.IntroMusic = nil
		end
		goingToOverload = false
	end
	if mgn.IntroMusic then
		if mgn.IntroMusic:GetTime() >= mgn.IntroMusic:GetLength() then
			mgn.IntroMusic:Stop()
			mgn.IntroMusic = nil
		else
			mgn.IntroMusic:SetVolume(introVolume)
		end
	end

	if not mgn.IsAlertActive() or not mgn.Music then
		return
	end

	local time_passed = CurTime() - mgn.GetAlertStart()
	if time_passed < mgn.AlertLength and math.abs(time_passed - mgn.Music:GetTime()) >= 1 then
		mgn.Music:SetTime(time_passed)
	end
end)

function mgn.SetAlertActive(activate, start)
	assert(IsValid(mgn.ControlComputer), "Attempting to set activation status when the control computer was not found.")
	assert(type(activate) == "boolean", "Attempting to set activation status with a non-boolean.")

	if (activate and mgn.IsAlertActive()) or (not activate and not mgn.IsAlertActive()) then
		return
	end

	local alert_start = start or CurTime()
	if activate and not mgn.IsAlertActive() then
		sound.PlayFile("data/" .. mgn.MusicPath, "", function(channel, errID, errStr)
			if channel then
				mgn.Music = channel
				mgn.Music:SetTime(CurTime() - alert_start)
			end
		end)
	elseif not activate and mgn.IsAlertActive() then
		if mgn.Music then
			mgn.Music:Stop()
			mgn.Music = nil
		end
	end

	mgn.ExplosionReset = true

	if activate then
		mgn.VOX("emergency announcement, please evacuate through the nearest exit")
	end

	mgn.AlertActive = activate
	mgn.AlertStart = activate and alert_start or 0
end
