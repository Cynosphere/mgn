include("sv_locations.lua")
include("sv_emergency.lua")

mgn.AlarmEntities = mgn.AlarmEntities or {}

mgn.LightEntities = mgn.LightEntities or {}

hook.Add("PopulateLuaScreens", "MGN", function()
	if game.GetMap() == "gm_construct_m_222" and LuaScreen then
		LuaScreen.AddConfig({
			place = "mgn_control_computer",
			pos = Vector(-13692, 2998, 14346),
			ang = Angle(-45, 0, 0)
		})

		LuaScreen.Precache("elev_mgn") -- must be loaded in both sides to prevent ID desync
	end
end)

function mgn.Initialize()
	for i = 1, math.max(#mgn.AlarmLocations, #mgn.AlarmEntities) do
		if not mgn.AlarmLocations[i] then
			local pair = mgn.AlarmEntities[i]
			if IsValid(pair.Light) then
				pair.Light:Remove()
			end

			if IsValid(pair.Siren) then
				pair.Siren:Remove()
			end

			mgn.AlarmEntities[i] = nil
		else
			local position = mgn.AlarmLocations[i].Position
			local normal = mgn.AlarmLocations[i].Normal

			local pair = mgn.AlarmEntities[i]
			if not pair then
				pair = {}
				mgn.AlarmEntities[i] = pair
			end

			if IsValid(pair.Light) then
				pair.Light:SetPos(position + normal)
				pair.Light:SetAngles(normal:Angle())
			else
				local light = ents.Create("mgn_rotating_light")
				light:SetPos(position + normal)
				light:SetAngles(normal:Angle())
				light:Spawn()

				pair.Light = light
			end

			if IsValid(pair.Siren) then
				pair.Siren:SetPos(position + Vector(0, 0, 30) + normal * 10)
				pair.Siren:SetAngles(normal:Angle())
			else
				local siren = ents.Create("mgn_siren")
				siren:SetPos(position + Vector(0, 0, 30) + normal * 10)
				siren:SetAngles(normal:Angle())
				siren:Spawn()

				pair.Siren = siren
			end
		end
	end

	for i = 1, math.max(#mgn.LightLocations, #mgn.LightEntities) do
		if not mgn.LightLocations[i] then
			local light = mgn.LightEntities[i]
			if IsValid(light) then
				light:Remove()
			end

			mgn.LightEntities[i] = nil
		else
			local position, angles, dstriped, width, depth, ssize, lcount, light =
				mgn.LightLocations[i].Position,
				mgn.LightLocations[i].Angles,
				mgn.LightLocations[i].DoubleStriped,
				mgn.LightLocations[i].Width,
				mgn.LightLocations[i].Depth,
				mgn.LightLocations[i].SpriteSize,
				mgn.LightLocations[i].LightCount,
				mgn.LightEntities[i]

			if IsValid(light) then
				light:SetPos(position)
				light:SetAngles(angles)
				light:SetDoubleStriped(dstriped)
				light:SetWidth(width)
				light:SetDepth(depth)
				light:SetSpriteSize(ssize)
				light:SetLightCount(lcount)
			else
				light = ents.Create("mgn_floor_lights")
				light:SetPos(position)
				light:SetAngles(angles)
				light:SetDoubleStriped(dstriped)
				light:SetWidth(width)
				light:SetDepth(depth)
				light:SetSpriteSize(ssize)
				light:SetLightCount(lcount)
				light:Spawn()

				mgn.LightEntities[i] = light
			end
		end
	end

	SetGlobalBool("MGN_AlertActive", false)
end
hook.Add("Initialize", "MGN", mgn.Initialize)

function mgn.ActivateAlert()
	for i = 1, #mgn.AlarmEntities do
		local pair = mgn.AlarmEntities[i]
		pair.Light:SetEnabled(true)
		pair.Siren:SetEnabled(true)
	end

	for i = 1, #mgn.LightEntities do
		mgn.LightEntities[i]:SetEnabled(true)
	end

	local lua_screens = ents.FindByClass("lua_screen")
	for i = 1, #lua_screens do
		local lua_screen = lua_screens[i]
		if lua_screen:GetPlace() == "elev" then
			lua_screen:SetEmergency(false)
		end
	end

	SetGlobalBool("MGN_AlertActive", true)
end

function mgn.DisableAlert()
	for i = 1, #mgn.AlarmEntities do
		local pair = mgn.AlarmEntities[i]
		pair.Light:SetEnabled(false)
		pair.Siren:SetEnabled(false)
	end

	for i = 1, #mgn.LightEntities do
		mgn.LightEntities[i]:SetEnabled(false)
	end

	local lua_screens = ents.FindByClass("lua_screen")
	for i = 1, #lua_screens do
		local lua_screen = lua_screens[i]
		if lua_screen:GetPlace() == "elev" then
			lua_screen:SetEmergency(false)
		end
	end

	SetGlobalBool("MGN_AlertActive", false)
end
