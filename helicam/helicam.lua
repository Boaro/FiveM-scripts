-- FiveM Heli Cam by mraes
-- Version 1.0 2017-06-08

-- config
local fov_max = 80.0
local fov_min = 10.0 -- max zoom level (smaller fov is more zoom)
local zoomspeed = 2.0 -- camera zoom speed
local speed_lr = 10.0 -- speed by which the camera pans left-right 
local speed_ud = 5.0 -- speed by which the camera pans up-down

-- Script starts here
local helicam = false
local polmav_hash = GetHashKey("polmav")
local fov = (fov_max+fov_min)*0.5
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
		if IsControlJustPressed(0, 51) and IsVehiclePolmavAndHighEnough(GetVehiclePedIsIn(GetPlayerPed(-1))) then -- Default for control 51, INPUT_CONTEXT is the E key
				PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
				helicam = true
		end
		
        if helicam then
            local scaleform = RequestScaleformMovie("HELI_CAM")
            while not HasScaleformMovieLoaded(scaleform) do
				Citizen.Wait(0)
            end
			local lPed = GetPlayerPed(-1)
			local heli = GetVehiclePedIsIn(lPed)
			local cam = CreateCam("DEFAULT_SCRIPTED_FLY_CAMERA", 2)
			AttachCamToEntity(cam, heli, 0.0,0.0,-1.5, true)
			SetCamRot(cam, 0.0,0.0,GetEntityHeading(heli))
			SetCamFov(cam, fov)
			RenderScriptCams(true, false, 0, 1, 0)
            PushScaleformMovieFunction(scaleform, "SET_CAM_LOGO")
            PushScaleformMovieFunctionParameterInt(1) -- 0 for nothing, 1 for LSPD logo
            PopScaleformMovieFunctionVoid()
			
            while helicam and not IsEntityDead(lPed) and IsVehiclePolmavAndHighEnough(heli) do
				if IsControlJustPressed(0, 51) then -- Default for control 51, INPUT_CONTEXT is the E key
					PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
					break
				end
				CheckInputRotation(cam)
				HandleZoom(cam)
				local zoomvalue = (1.0/(fov_max-fov_min))*(fov-fov_min)
                HideHUDThisFrame()
                PushScaleformMovieFunction(scaleform, "SET_ALT_FOV_HEADING")
                PushScaleformMovieFunctionParameterFloat(GetEntityCoords(heli).z)
                PushScaleformMovieFunctionParameterFloat(zoomvalue)
                PushScaleformMovieFunctionParameterFloat(GetCamRot(cam, 2).z)
                PopScaleformMovieFunctionVoid()
                DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
                Citizen.Wait(0)
			end
			helicam = false
			fov = (fov_max+fov_min)*0.5 -- reset to starting zoom level
			RenderScriptCams(false, false, 0, 1, 0) -- Return to gameplay camera
			SetScaleformMovieAsNoLongerNeeded(scaleform) -- Cleanly release the scaleform
			DestroyCam(cam, false)
		end
	end
end)

function IsVehiclePolmavAndHighEnough(vehicle)
	local height = GetEntityHeightAboveGround(vehicle)
	return IsVehicleModel(vehicle, polmav_hash) and height > 1.5
end


function HideHUDThisFrame()
	HideHelpTextThisFrame()
	HideHudAndRadarThisFrame()
	HideHudComponentThisFrame(19) -- weapon wheel
	HideHudComponentThisFrame(1) -- Wanted Stars
	HideHudComponentThisFrame(2) -- Weapon icon
	HideHudComponentThisFrame(3) -- Cash
	HideHudComponentThisFrame(4) -- MP CASH
	HideHudComponentThisFrame(13) -- Cash Change
	HideHudComponentThisFrame(11) -- Floating Help Text
	HideHudComponentThisFrame(12) -- more floating help text
	HideHudComponentThisFrame(15) -- Subtitle Text
	HideHudComponentThisFrame(18) -- Game Stream
end

function CheckInputRotation(cam)
	local rightAxisX = GetDisabledControlNormal(0, 220)
	local rightAxisY = GetDisabledControlNormal(0, 221)
	local rotation = GetCamRot(cam, 2)
	if rightAxisX ~= 0.0 or rightAxisY ~= 0.0 then
		new_z = rotation.z + rightAxisX*-1.0*(speed_ud)
		new_x = math.max(math.min(20.0, rotation.x + rightAxisY*-1.0*(speed_lr)), -89.5) -- Clamping at top (cant see top of heli) and at bottom (doesn't glitch out in -90deg)
		Citizen.Trace(new_x)
		SetCamRot(cam, new_x, 0.0, new_z, 2)
	end
end

function HandleZoom(cam)
	if IsControlJustPressed(0,241) then -- Scrollup
		fov = math.max(fov - zoomspeed, fov_min)
		SetCamFov(cam, fov)
	end
	if IsControlJustPressed(0,242) then
		fov = math.min(fov + zoomspeed, fov_max) -- ScrollDown
		SetCamFov(cam, fov)			
	end
end