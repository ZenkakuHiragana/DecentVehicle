
-- Copyright © 2018-2030 Decent Vehicle
-- written by ∩(≡＾ω＾≡)∩ (https://steamcommunity.com/id/greatzenkakuman/)
-- and DangerKiddy(DK) (https://steamcommunity.com/profiles/76561198132964487/).

local ENT = ENT ---@class ENT.DecentVehicle
local dvd = DecentVehicleDestination
local TurnOnLights = dvd.CVars.TurnOnLights
local LIGHTLEVEL = {
    NONE = 0,
    RUNNING = 1,
    HEADLIGHTS = 2,
    ALL = 3,
}

---@param self ENT.DecentVehicle
---@param key string
---@param state integer
---@param func fun(self: dv.SCAR, ...)
---@param ... any
local function SCAREmulateKey(self, key, state, func, ...)
    local v = self.v ---@cast v dv.SCAR
    local dummy = player.GetByID(1) ---@cast dummy -?
    local dummyinput = dummy.ScarSpecialKeyInput
    local controller = v.AIController
    v.AIController = dummy
    dummy.ScarSpecialKeyInput = {[key] = state}
    if isfunction(func) then func(v, ...) end
    v.AIController = controller
    dummy.ScarSpecialKeyInput = dummyinput
end

function ENT:GetMaxSteeringAngle()
    local v = self.v
    if v.IsScar then ---@cast v dv.SCAR
        return v.MaxSteerForce * 3 -- Obviously this is not actually steering angle
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys
        return v.VehicleData.steerangle
    elseif v.LVS or v.LVS_GUNNER then ---@cast v dv.LVS
        if not isfunction(v.GetMaxSteerAngle) then return 0 end
        if not isfunction(v.SetNWMaxSteer) then return 0 end -- For lvs_base_wheeldrive_trailer
        return v:GetMaxSteerAngle()
    elseif v.IsGlideVehicle then ---@cast v dv.Glide
        return v:GetMaxSteerAngle()
    else ---@cast v Vehicle
        local mph = v:GetSpeed()
        if mph < self.SteeringSpeedFast then
            return Lerp((mph - self.SteeringSpeedSlow)
            / (self.SteeringSpeedFast - self.SteeringSpeedSlow),
            self.SteeringAngleSlow, self.SteeringAngleFast)
        else
            return Lerp((mph - self.SteeringSpeedFast)
            / (self.BoostSpeed - self.SteeringSpeedFast),
            self.SteeringAngleFast, self.SteeringAngleBoost)
        end
    end
end

function ENT:GetTraceFilter()
    local v = self.v
    local filter = table.Add({self, v}, constraint.GetAllConstrainedEntities(v))
    if v.IsScar then ---@cast v dv.SCAR
        table.Add(filter, v.Seats or {})
        table.Add(filter, v.Wheels)
        table.Add(filter, v.StabilizerProp)
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys
        table.Add(filter, v.VehicleData.filter)
    else ---@cast v Vehicle
        table.Add(filter, v:GetChildren())
    end

    return filter
end

function ENT:GetEngineStarted(vehicle)
    local v = vehicle or self.v
    if not (IsValid(v) and v:IsVehicle()) then return end
    if v.IsScar then ---@cast v dv.SCAR
        return v.IsOn
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys
        return v:EngineActive()
    elseif v.LVS or v.LVS_GUNNER then ---@cast v dv.LVS
        return v:GetEngineActive()
    elseif v.IsGlideVehicle then ---@cast v dv.Glide
        -- Returns true when the engine is starting or running
        return v:GetEngineState() == 1 or v:GetEngineState() == 2
    else ---@cast v Vehicle
        return v:IsEngineStarted()
    end
end

function ENT:GetLocked(vehicle)
    local v = vehicle or self.v
    if not (IsValid(v) and v:IsVehicle()) then return end
    if v.IsScar then ---@cast v dv.SCAR
        return v:IsLocked()
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys
        return v.VehicleLocked
    elseif v.LVS or v.LVS_GUNNER then ---@cast v dv.LVS
        return v:GetlvsLockedStatus()
    elseif v.IsGlideVehicle then ---@cast v dv.Glide
        return v:GetIsLocked()
    elseif vcmod_main ---@cast v Vehicle
    and isfunction(v.VC_isLocked) then
        return v:VC_isLocked()
    else ---@cast v Vehicle
        return tonumber(v:GetKeyValues().VehicleLocked) ~= 0
    end
end

function ENT:GetRunningLights()
    local v = self.v
    if v.IsScar then ---@cast v dv.SCAR
        return v:GetNWBool "HeadlightsOn"
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys
        return self.SimfphysRunningLights
    elseif v.LVS or v.LVS_GUNNER then ---@cast v dv.LVS
        local lh = isfunction(v.GetLightsHandler) and v:GetLightsHandler()
        return isfunction(v.HasFogLights) and v:HasFogLights()
           and IsValid(lh) and lh:GetFogActive()
    elseif v.IsGlideVehicle then ---@cast v dv.Glide
        return false -- v:GetHeadlightState() == 1
    elseif vcmod_main ---@cast v Vehicle
    and isfunction(v.VC_getStates) then
        local states = v:VC_getStates()
        return istable(states) and states.RunningLights
    elseif Photon2 ---@cast v Vehicle
    and isfunction(v.GetPhotonControllerFromAncestor) then
        local pc = v:GetPhotonControllerFromAncestor()
        if IsValid(pc) then
            return pc:GetChannelMode("Vehicle.Lights") ~= "AUTO"
        end
    end
end

function ENT:GetFogLights()
    local v = self.v
    if v.IsScar then ---@cast v dv.SCAR
        return v:GetNWBool "HeadlightsOn"
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys
        return self.SimfphysFogLights
    elseif v.LVS or v.LVS_GUNNER then ---@cast v dv.LVS
        local lh = isfunction(v.GetLightsHandler) and v:GetLightsHandler()
        return isfunction(v.HasFogLights) and v:HasFogLights()
           and IsValid(lh) and lh:GetFogActive()
    elseif v.IsGlideVehicle then ---@cast v dv.Glide
        return false -- v:GetHeadlightState() == 1
    elseif vcmod_main ---@cast v Vehicle
    and isfunction(v.VC_getStates) then
        local states = v:VC_getStates()
        return istable(states) and states.FogLights
    elseif Photon2 ---@cast v Vehicle
    and isfunction(v.GetPhotonControllerFromAncestor) then
        local pc = v:GetPhotonControllerFromAncestor()
        if IsValid(pc) then
            return pc:GetChannelMode("Vehicle.Lights") ~= "AUTO"
        end
    end
end

function ENT:GetLights(highbeams)
    local v = self.v
    if v.IsScar then ---@cast v dv.SCAR
        return v:GetNWBool "HeadlightsOn"
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys
        return Either(highbeams, v.LampsActivated, v.LightsActivated)
    elseif v.LVS or v.LVS_GUNNER then ---@cast v dv.LVS
        local lh = isfunction(v.GetLightsHandler) and v:GetLightsHandler()
        if not (IsValid(lh) and lh:GetActive()) then return false end
        if highbeams then
            return isfunction(v.HasHighBeams) and v:HasHighBeams() and lh:GetHighActive()
        else
            return lh:GetActive()
        end
    elseif v.IsGlideVehicle then ---@cast v dv.Glide
        return v:GetHeadlightState() == (highbeams and 2 or 1)
    elseif vcmod_main ---@cast v Vehicle
    and isfunction(v.VC_getStates) then
        local states = v:VC_getStates()
        return istable(states) and Either(highbeams, states.HighBeams, states.LowBeams)
    elseif Photon2 ---@cast v Vehicle
    and isfunction(v.GetPhotonControllerFromAncestor) then
        local pc = v:GetPhotonControllerFromAncestor()
        if IsValid(pc) then
            return pc:GetChannelMode("Vehicle.Lights") ~= "HEADLIGHTS"
        end
    elseif Photon ---@cast v Vehicle
    and isfunction(v.ELS_Illuminate) then
        return v:ELS_Illuminate()
    end
end

function ENT:GetTurnLight(left)
    local v = self.v
    if v.IsScar then -- Does SCAR have turn lights?
        return false
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys
        return Either(left, self.TurnLightLeft, self.TurnLightRight)
    elseif v.LVS or v.LVS_GUNNER then ---@cast v dv.LVS
        if not (isfunction(v.HasTurnSignals) and v:HasTurnSignals()) then return false end
        return isfunction(v.GetTurnMode) and v:GetTurnMode() == (left and 1 or 2)
    elseif v.IsGlideVehicle then ---@cast v dv.Glide
        return v:GetTurnSignalState() == (left and 1 or 2)
    elseif vcmod_main ---@cast v Vehicle
    and isfunction(v.VC_getStates) then
        local states = v:VC_getStates()
        return istable(states) and Either(left, states.TurnLightLeft, states.TurnLightRight)
    elseif Photon2 ---@cast v Vehicle
    and isfunction(v.GetPhotonControllerFromAncestor) then
        local pc = v:GetPhotonControllerFromAncestor()
        if IsValid(pc) then
            return pc:GetChannelMode("Vehicle.Signal") == (left and "LEFT" or "RIGHT")
        end
    elseif Photon ---@cast v Vehicle
    and isfunction(v.CAR_TurnLeft)
    and isfunction(v.CAR_TurnRight) then
        return Either(left, v:CAR_TurnLeft(), v:CAR_TurnRight())
    end
end

function ENT:GetHazardLights()
    local v = self.v
    if v.IsScar then ---@cast v dv.SCAR
        return false
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys
        return self.HazardLights
    elseif v.LVS or v.LVS_GUNNER then ---@cast v dv.LVS
        if not (isfunction(v.HasTurnSignals) and v:HasTurnSignals()) then return false end
        return isfunction(v.GetTurnMode) and v:GetTurnMode() == 3
    elseif v.IsGlideVehicle then ---@cast v dv.Glide
        return v:GetTurnSignalState() == 3
    elseif vcmod_main ---@cast v Vehicle
    and isfunction(v.VC_getStates) then
        local states = v:VC_getStates()
        return istable(states) and states.HazardLights
    elseif Photon2 ---@cast v Vehicle
    and isfunction(v.GetPhotonControllerFromAncestor) then
        local pc = v:GetPhotonControllerFromAncestor()
        if IsValid(pc) then
            return pc:GetChannelMode("Vehicle.Signal") == "HAZARD"
        end
    elseif Photon ---@cast v Vehicle
    and isfunction(v.CAR_Hazards) then
        return v:CAR_Hazards()
    end
end

function ENT:GetELS(vehicle)
    local v = vehicle or self.v
    if not (IsValid(v) and v:IsVehicle()) then return end
    if v.IsScar then ---@cast v dv.SCAR
        return v.SirenIsOn
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys
        return v:GetEMSEnabled()
    elseif v.LVS or v.LVS_GUNNER then ---@cast v dv.LVS
        return isfunction(v.GetSirenMode) and v:GetSirenMode() >= 0
    elseif v.IsGlideVehicle then ---@cast v dv.Glide
        return v:GetSirenState() == 2
    elseif vcmod_main and vcmod_els ---@cast v Vehicle
    and isfunction(v.VC_getELSLightsOn) then
        return v:VC_getELSLightsOn()
    elseif Photon2 ---@cast v Vehicle
    and isfunction(v.GetPhotonControllerFromAncestor) then
        local pc = v:GetPhotonControllerFromAncestor()
        if IsValid(pc) then
            return pc:GetChannelMode("Emergency.Warning") ~= "OFF"
        end
    elseif Photon ---@cast v Vehicle
    and isfunction(v.ELS_Siren)
    and isfunction(v.ELS_Lights) then
        return v:ELS_Siren() and v:ELS_Lights()
    end
end

function ENT:GetELSSound(vehicle)
    local v = vehicle or self.v
    if not (IsValid(v) and v:IsVehicle()) then return end
    if v.IsScar then ---@cast v dv.SCAR
        return v.SirenIsOn
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys
        return v.ems and v.ems:IsPlaying()
    elseif v.LVS or v.LVS_GUNNER then ---@cast v dv.LVS
        return isfunction(v.GetSirenMode) and v:GetSirenMode() >= 0
    elseif v.IsGlideVehicle then ---@cast v dv.Glide
        return v:GetSirenState() == 2
    elseif vcmod_main and vcmod_els ---@cast v Vehicle
    and isfunction(v.VC_getELSSoundOn)
    and isfunction(v.VC_getStates) then
        local states = v:VC_getStates()
        return v:VC_getELSSoundOn() or istable(states) and states.ELS_ManualOn
    elseif Photon2 ---@cast v Vehicle
    and isfunction(v.GetPhotonControllerFromAncestor) then
        local pc = v:GetPhotonControllerFromAncestor()
        if IsValid(pc) then
            return pc:GetChannelMode("Emergency.Siren") ~= "OFF"
        end
    elseif Photon ---@cast v Vehicle
    and isfunction(v.ELS_Siren) then
        return v:ELS_Siren()
    end
end

function ENT:GetHorn(vehicle)
    local v = vehicle or self.v
    if not (IsValid(v) and v:IsVehicle()) then return end
    if v.IsScar then ---@cast v dv.SCAR
        return v.Horn:IsPlaying()
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys
        return v.HornKeyIsDown
    elseif v.LVS or v.LVS_GUNNER then ---@cast v dv.LVS
        return IsValid(v.HornSound) and v.HornSound:IsPlaying()
    elseif v.IsGlideVehicle then ---@cast v dv.Glide
        return v:GetIsHonking()
    elseif vcmod_main ---@cast v Vehicle
    and isfunction(v.VC_getStates) then
        local states = v:VC_getStates()
        return istable(states) and states.HornOn
    elseif Photon2 ---@cast v Vehicle
    and isfunction(v.GetPhotonControllerFromAncestor) then
        local pc = v:GetPhotonControllerFromAncestor()
        if IsValid(pc) then
            return pc:GetChannelMode("Emergency.SirenOverride") == "AIR"
        end
    elseif Photon ---@cast v Vehicle
    and isnumber(EMV_HORN)
    and isfunction(v.ELS_Horn) then
        return v:GetDTBool(EMV_HORN)
    end
end

function ENT:SetRunningLights(on)
    local lightlevel = TurnOnLights:GetInt()
    on = on and lightlevel ~= LIGHTLEVEL.NONE
    if on == self:GetRunningLights() then return end
    local v = self.v
    if v.IsScar then ---@cast v dv.SCAR
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys
        self.SimfphysRunningLights = on
        v:SetFogLightsEnabled(not on)
        numpad.Activate(self --[[@as Player]], KEY_V, false)
    elseif v.LVS or v.LVS_GUNNER then ---@cast v dv.LVS
        local lh = isfunction(v.GetLightsHandler) and v:GetLightsHandler()
        if IsValid(lh) and isfunction(v.HasFogLights) and v:HasFogLights() then
            lh:SetFogActive(on)
        end
    elseif v.IsGlideVehicle then ---@cast v dv.Glide
        -- local state = on and 1 or 0
        -- if v:GetHeadlightState() ~= state then
        --     v:ChangeHeadlightState(state)
        -- end
    elseif vcmod_main ---@cast v Vehicle
    and isfunction(v.VC_setRunningLights) then
        v:VC_setRunningLights(on)
    elseif Photon2 ---@cast v Vehicle
    and isfunction(v.GetPhotonControllerFromAncestor) then
        local pc = v:GetPhotonControllerFromAncestor()
        if IsValid(pc) and on then
            pc:SetChannelMode("Vehicle.Lights", "AUTO")
        end
    end
end

function ENT:SetFogLights(on)
    local lightlevel = TurnOnLights:GetInt()
    on = on and lightlevel == LIGHTLEVEL.ALL
    if on == self:GetFogLights() then return end
    local v = self.v
    if v.IsScar then ---@cast v dv.SCAR
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys
        self.SimfphysFogLights = on
        v:SetFogLightsEnabled(not on)
        numpad.Activate(self --[[@as Player]], KEY_V, false)
    elseif v.LVS or v.LVS_GUNNER then ---@cast v dv.LVS
        local lh = isfunction(v.GetLightsHandler) and v:GetLightsHandler()
        if IsValid(lh) and isfunction(v.HasFogLights) and v:HasFogLights() then
            lh:SetFogActive(on)
        end
    elseif v.IsGlideVehicle then ---@cast v dv.Glide
        -- local state = on and 1 or 0
        -- if v:GetHeadlightState() ~= state then
        --     v:ChangeHeadlightState(state)
        -- end
    elseif vcmod_main ---@cast v Vehicle
    and isfunction(v.VC_setFogLights) then
        v:VC_setFogLights(on)
    elseif Photon2 ---@cast v Vehicle
    and isfunction(v.GetPhotonControllerFromAncestor) then
        local pc = v:GetPhotonControllerFromAncestor()
        if IsValid(pc) and on then
            pc:SetChannelMode("Vehicle.Lights", "AUTO")
        end
    end
end

function ENT:SetLights(on, highbeams)
    local v = self.v
    local lightlevel = TurnOnLights:GetInt()
    on = on and lightlevel >= LIGHTLEVEL.HEADLIGHTS
    if v.IsScar then ---@cast v dv.SCAR
        if on == self:GetLights() then return end
        v.IncreaseFrontLightCol = not on
        SCAREmulateKey(self, "ToggleHeadlights", 3, v.UpdateLights)
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys
        local LightsActivated = self:GetLights()
        if on ~= LightsActivated then
            v.LightsActivated = not on
            v.KeyPressedTime = CurTime() - .23
            numpad.Deactivate(self --[[@as Player]], KEY_F, false)
        end

        if on and highbeams ~= self:GetLights(true) then
            v.LampsActivated = not highbeams
            v.KeyPressedTime = CurTime()
            if LightsActivated then
                numpad.Deactivate(self --[[@as Player]], KEY_F, false)
            else
                timer.Simple(.05, function()
                    if not (IsValid(self) and IsValid(v)) then return end
                    numpad.Deactivate(self --[[@as Player]], KEY_F, false)
                end)
            end
        end
    elseif v.LVS or v.LVS_GUNNER then ---@cast v dv.LVS
        local lh = isfunction(v.GetLightsHandler) and v:GetLightsHandler()
        if not IsValid(lh) then return end
        lh:SetActive(on)
        if highbeams and isfunction(v.HasHighBeams) and v:HasHighBeams() then
            lh:SetHighActive(on)
        end
    elseif v.IsGlideVehicle then ---@cast v dv.Glide
        local state = on and (highbeams and 2 or 1) or 0
        if v:GetHeadlightState() ~= state then
            v:ChangeHeadlightState(state)
        end
    elseif vcmod_main ---@cast v Vehicle
    and isfunction(v.VC_setHighBeams)
    and isfunction(v.VC_setLowBeams) then
        if on == self:GetLights(highbeams) then return end
        if highbeams then
            v:VC_setHighBeams(on)
        else
            v:VC_setLowBeams(on)
        end
    elseif Photon2 ---@cast v Vehicle
    and isfunction(v.GetPhotonControllerFromAncestor) then
        local pc = v:GetPhotonControllerFromAncestor()
        if IsValid(pc) then
            pc:SetChannelMode("Vehicle.Lights", on and "HEADLIGHTS" or "OFF")
        end
    elseif Photon ---@cast v Vehicle
    and isfunction(v.ELS_IllumOn)
    and isfunction(v.ELS_IllumOff)
    and isfunction(v.ELS_Illuminate)
    and isfunction(v.IsEMV) and v:IsEMV() then
        if on == self:GetLights(highbeams) then return end
        if on then
            v:ELS_IllumOn()
        else
            v:ELS_IllumOff()
        end
    end
end

local SIMFPHYS = {OFF = 0, HAZARD = 1, LEFT = 2, RIGHT = 3}
function ENT:SetTurnLight(on, left)
    if on == self:GetTurnLight(left) then return end
    local v = self.v
    if v.IsScar then ---@cast v dv.SCAR
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys
        if player.GetCount() > 0 then
            net.Start "simfphys_turnsignal"
            net.WriteEntity(v)
            net.WriteInt(on and (left and SIMFPHYS.LEFT or SIMFPHYS.RIGHT) or SIMFPHYS.OFF, 32)
            net.Broadcast()
        end

        self.TurnLightLeft = on and left
        self.TurnLightRight = on and not left
        self.HazardLights = false
    elseif v.LVS or v.LVS_GUNNER then ---@cast v dv.LVS
        if not (isfunction(v.SetTurnMode)
           and isfunction(v.HasTurnSignals)
           and v:HasTurnSignals()) then return end
        if on then
            v:SetTurnMode(left and 1 or 2)
        else
            v:SetTurnMode(0)
        end
    elseif v.IsGlideVehicle then ---@cast v dv.Glide
        local state = on and (left and 1 or 2) or 0
        if v:GetTurnSignalState() ~= state then
            v:ChangeTurnSignalState(state)
        end
    elseif vcmod_main ---@cast v Vehicle
    and isfunction(v.VC_setTurnLightLeft)
    and isfunction(v.VC_setTurnLightRight) then
        v:VC_setTurnLightLeft(on and left)
        v:VC_setTurnLightRight(on and not left)
    elseif Photon2 ---@cast v Vehicle
    and isfunction(v.GetPhotonControllerFromAncestor) then
        local pc = v:GetPhotonControllerFromAncestor()
        if IsValid(pc) then
            if on then
                pc:SetChannelMode("Vehicle.Signal", left and "LEFT" or "RIGHT")
            else
                pc:SetChannelMode("Vehicle.Signal", "OFF")
            end
        end
    elseif Photon ---@cast v Vehicle
    and isfunction(v.CAR_TurnLeft)
    and isfunction(v.CAR_TurnRight)
    and isfunction(v.CAR_StopSignals) then
        if on then
            if left then
                v:CAR_TurnLeft(true)
            else
                v:CAR_TurnRight(true)
            end
        else
            v:CAR_StopSignals()
        end
    end
end

function ENT:SetHazardLights(on)
    if on == self:GetHazardLights() then return end
    local v = self.v
    if v.IsScar then ---@cast v dv.SCAR
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys
        if player.GetCount() > 0 then
            net.Start "simfphys_turnsignal"
            net.WriteEntity(v)
            net.WriteInt(on and SIMFPHYS.HAZARD or SIMFPHYS.OFF, 32)
            net.Broadcast()
        end

        self.TurnLightLeft = false
        self.TurnLightRight = false
        self.HazardLights = true
    elseif v.LVS or v.LVS_GUNNER then ---@cast v dv.LVS
        if not (isfunction(v.SetTurnMode)
           and isfunction(v.HasTurnSignals)
           and v:HasTurnSignals()) then return end
        v:SetTurnMode(on and 3 or 0)
    elseif v.IsGlideVehicle then ---@cast v dv.Glide
        local state = on and 3 or 0
        if v:GetTurnSignalState() ~= state then
            v:ChangeTurnSignalState(state)
        end
    elseif vcmod_main ---@cast v Vehicle
    and isfunction(v.VC_setHazardLights) then
        v:VC_setHazardLights(on)
    elseif Photon2 ---@cast v Vehicle
    and isfunction(v.GetPhotonControllerFromAncestor) then
        local pc = v:GetPhotonControllerFromAncestor()
        if IsValid(pc) then
            pc:SetChannelMode("Vehicle.Signal", on and "HAZARD" or "OFF")
        end
    elseif Photon ---@cast v Vehicle
    and isfunction(v.CAR_Hazards)
    and isfunction(v.CAR_StopSignals) then
        if on then
            v:CAR_Hazards(true)
        else
            v:CAR_StopSignals()
        end
    end
end

function ENT:SetELS(on)
    if on == self:GetELS() then return end
    local v = self.v
    if v.IsScar then ---@cast v dv.SCAR
        if v.SirenIsOn == nil then return end
        if not v.SirenSound then return end
        if on then self:SetHorn(false) end
        v.SirenIsOn = on
        v:SetNWBool("SirenIsOn", on)
        if on then
            v.SirenSound:Play()
        else
            v.SirenSound:Stop()
        end
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys
        local dt = on and 0 or .5
        v.emson = not on
        v.KeyPressedTime = CurTime() - dt
        numpad.Deactivate(self --[[@as Player]], KEY_H, false)
    elseif v.LVS or v.LVS_GUNNER then ---@cast v dv.LVS
        if on then
            if isfunction(v.StartSiren) then
                v:StartSiren(false, true)
            end
        elseif isfunction(v.SetSirenMode) and isfunction(v.StopSiren) then
            v:SetSirenMode(-1)
            v:StopSiren()
        end
    elseif v.IsGlideVehicle then ---@cast v dv.Glide
        local state = on and 2 or 0
        if v:GetSirenState() ~= state then
            v:ChangeSirenState(state)
        end
    elseif vcmod_main and vcmod_els ---@cast v Vehicle
    and isfunction(v.VC_setELSLights)
    and isfunction(v.VC_setELSSound) then
        v:VC_setELSLights(on)
        v:VC_setELSSound(on)
    elseif Photon2 ---@cast v Vehicle
    and isfunction(v.GetPhotonControllerFromAncestor) then
        local pc = v:GetPhotonControllerFromAncestor()
        if IsValid(pc) then
            pc:SetChannelMode("Emergency.Warning", on and "MODE3" or "OFF")
            pc:SetChannelMode("Emergency.Siren", on and "T1" or "OFF")
        end
    elseif Photon ---@cast v Vehicle
    and isfunction(v.ELS_SirenOn)
    and isfunction(v.ELS_SirenOff)
    and isfunction(v.ELS_LightsOff)
    and isfunction(v.IsEMV) and v:IsEMV() then
        if on then
            v:ELS_SirenOn()
        else
            v:ELS_SirenOff()
            v:ELS_LightsOff()
        end
    end
end

function ENT:SetELSSound(on)
    if on == self:GetELSSound() then return end
    local v = self.v
    if v.IsScar then ---@cast v dv.SCAR
        if not v.SirenSound then return end
        if on then
            v.SirenSound:Play()
        else
            v.SirenSound:Stop()
        end
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys
        if v.ems then
            if on and not v.ems:IsPlaying() then
                v.ems:Play()
            elseif not on and v.ems:IsPlaying() then
                v.ems:Stop()
            end
        end
    elseif v.LVS or v.LVS_GUNNER then ---@cast v dv.LVS
        if on then
            if isfunction(v.StartSiren) then
                v:StartSiren(false, true)
            end
        elseif isfunction(v.SetSirenMode) and isfunction(v.StopSiren) then
            v:SetSirenMode(-1)
            v:StopSiren()
        end
    elseif v.IsGlideVehicle then ---@cast v dv.Glide
        local state = on and 2 or 0
        if v:GetSirenState() ~= state then
            v:ChangeSirenState(state)
        end
    elseif vcmod_main and vcmod_els ---@cast v Vehicle
    and isfunction(v.VC_setELSSound) then
        v:VC_setELSSound(on)
    elseif Photon2 ---@cast v Vehicle
    and isfunction(v.GetPhotonControllerFromAncestor) then
        local pc = v:GetPhotonControllerFromAncestor()
        if IsValid(pc) then
            pc:SetChannelMode("Emergency.Siren", on and "T1" or "OFF")
        end
    elseif Photon ---@cast v Vehicle
    and isfunction(v.ELS_SirenOn)
    and isfunction(v.ELS_SirenOff)
    and isfunction(v.ELS_LightsOff)
    and isfunction(v.IsEMV) and v:IsEMV() then
        if on then
            v:ELS_SirenOn()
        else
            v:ELS_SirenOff()
        end

        v:ELS_LightsOff()
    end
end

function ENT:SetHorn(on)
    if on == self:GetHorn() then return end
    local v = self.v
    if v.IsScar then ---@cast v dv.SCAR
        if on then
            v:HornOn()
        else
            v:HornOff()
        end
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys
        if on then
            numpad.Activate(self --[[@as Player]], KEY_H, false)
        else
            v.HornKeyIsDown = false
        end
    elseif v.LVS or v.LVS_GUNNER then ---@cast v dv.LVS
        if IsValid(v.HornSound) then
            if on then
                v.HornSound:Play()
            else
                v.HornSound:Stop()
            end
        end
    elseif v.IsGlideVehicle then ---@cast v dv.Glide
        v:SetIsHonking(on)
    elseif vcmod_main ---@cast v Vehicle
    and isfunction(v.VC_getStates)
    and isfunction(v.VC_setStates) then
        local states = v:VC_getStates()
        if not istable(states) then return end
        states.HornOn = true
        v:VC_setStates(states)
    elseif Photon2 ---@cast v Vehicle
    and isfunction(v.GetPhotonControllerFromAncestor) then
        local pc = v:GetPhotonControllerFromAncestor()
        if IsValid(pc) then
            pc:SetChannelMode("Emergency.SirenOverride", on and "AIR" or "OFF")
        end
    elseif Photon ---@cast v Vehicle
    and isfunction(v.ELS_Horn) then
        v:ELS_Horn(on)
    end
end

function ENT:SetLocked(locked)
    if locked == self:GetLocked() then return end
    local v = self.v
    if v.IsScar then ---@cast v dv.SCAR
        if locked then
            v:Lock()
        else
            v:UnLock()
        end
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys
        if locked then
            v:Lock()
        else
            v:UnLock()
        end
    elseif v.LVS or v.LVS_GUNNER then ---@cast v dv.LVS
        if locked then
            v:Lock()
        else
            v:UnLock()
        end
    elseif v.IsGlideVehicle then ---@cast v dv.Glide
        v:SetLocked(locked)
    else ---@cast v Vehicle
        for _, seat in pairs(v:GetChildren()) do ---@cast seat Vehicle
            if not (seat:IsVehicle() and seat.__SW_Vars) then continue end
            seat:Fire(locked and "Lock" or "Unlock") -- For Sligwolf's vehicles
        end

        if vcmod_main
        and isfunction(v.VC_lock)
        and isfunction(v.VC_unLock) then
            if locked then
                v:VC_lock()
            else
                v:VC_unLock()
            end
        else
            v:Fire(locked and "Lock" or "Unlock")
        end
    end
end

function ENT:SetEngineStarted(on)
    if on == self:GetEngineStarted() then return end
    local v = self.v
    if v.IsScar then ---@cast v dv.SCAR SCAR automatically starts the engine.
        self:SetLocked(not on)
        v.AIController = on and self or nil
        if not on then v:TurnOffCar() end
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys
        v:SetActive(on)
        if on then
            v:StartEngine()
        else
            v:StopEngine()
        end
    elseif v.LVS or v.LVS_GUNNER then ---@cast v dv.LVS
        if on then
            v:StartEngine()
        else
            v:StopEngine()
        end
    elseif v.IsGlideVehicle then ---@cast v dv.Glide
        if on then
            v:TurnOn()
        else
            v:TurnOff()
        end
    elseif isfunction(v.StartEngine) then ---@cast v Vehicle
        v:StartEngine(on)
    end
end

function ENT:SetHandbrake(brake)
    if self.HandBrake == brake then return end
    self.HandBrake = brake
    local v = self.v
    if v.IsScar then ---@cast v dv.SCAR
        if brake then
            v:HandBrakeOn()
        else
            v:HandBrakeOff()
        end
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys
        v.PressedKeys.Space = brake
    elseif v.LVS or v.LVS_GUNNER then ---@cast v dv.LVS
        if brake then
            if isfunction(v.EnableHandbrake) then v:EnableHandbrake() end
        else
            if isfunction(v.ReleaseHandbrake) then v:ReleaseHandbrake() end
        end
    elseif v.IsGlideVehicle then ---@cast v dv.Glide
        v:SetInputBool(1, "handbrake", brake)
    elseif isfunction(v.SetHandbrake) then ---@cast v Vehicle
        v:SetHandbrake(brake)
        if Photon2 and isfunction(v.GetPhotonControllerFromAncestor) then
            local pc = v:GetPhotonControllerFromAncestor()
            if IsValid(pc) then
                pc:SetChannelMode("Vehicle.Brake", brake and "BRAKE" or "OFF")
            end
        end
    end
end

function ENT:SetThrottle(throttle)
    self.Throttle = throttle
    local v = self.v
    if v.IsScar then ---@cast v dv.SCAR
        if throttle > 0 then
            v:GoForward(throttle)
        elseif throttle < 0 then
            v:GoBack(-throttle)
        else
            v:GoNeutral()
        end
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys
        v.PressedKeys.W = throttle > .01
        v.PressedKeys.S = throttle < -.01
    elseif v.LVS or v.LVS_GUNNER then ---@cast v dv.LVS
        if not (isfunction(v.LerpThrottle)
            and isfunction(v.SetThrottle)
            and isfunction(v.LerpBrake)
            and isfunction(v.SetBrake)) then return end
        local dot = self:GetVehicleForward():Dot(v:GetVelocity())
        if math.abs(dot) < self.AutoReverseVelocity then
            v:LerpBrake(0)
            v:LerpThrottle(math.abs(throttle))
            if math.abs(throttle) > 0.5 then
                v:SetReverse(throttle < 0)
            end
        elseif dot * throttle > 0 then
            v:LerpBrake(0)
            v:LerpThrottle(math.abs(throttle))
        else
            v:LerpBrake(math.abs(throttle))
            v:LerpThrottle(0)
        end
    elseif v.IsGlideVehicle then ---@cast v dv.Glide
        v:SetInputFloat(1, "accelerate", math.max(throttle, 0))
        v:SetInputFloat(1, "brake", math.max(-throttle, 0))
    elseif isfunction(v.SetThrottle) then ---@cast v Vehicle
        v:SetThrottle(throttle)
        if Photon2 and isfunction(v.GetPhotonControllerFromAncestor) then
            local pc = v:GetPhotonControllerFromAncestor()
            if IsValid(pc) then
                pc:SetChannelMode("Vehicle.Transmission", throttle < 0 and "REVERSE" or "DRIVE")
            end
        end
    end
end

function ENT:SetSteering(steering)
    steering = math.Clamp(steering, -1, 1)
    self.Steering = steering
    local v = self.v
    if v.IsScar then ---@cast v dv.SCAR
        if steering > 0 then
            v:TurnRight(steering)
        elseif steering < 0 then
            v:TurnLeft(-steering)
        else
            v:NotTurning()
        end
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys
        local s = v:GetVehicleSteer()
        v:PlayerSteerVehicle(self --[[@as Player]], -math.min(steering, 0), math.max(steering, 0))
        v.PressedKeys.A = steering < -.01 and steering < s and s < 0
        v.PressedKeys.D = steering > .01 and 0 < s and s < steering
    elseif v.LVS or v.LVS_GUNNER then ---@cast v dv.LVS
        if not (isfunction(v.SteerTo)
        and isfunction(v.SetSteer)
        and isfunction(v.GetMaxSteerAngle)
        and isfunction(v.SetPivotSteer)) then return end
        v:SteerTo(steering, v:GetMaxSteerAngle())
        v:SetPivotSteer(0)
    elseif v.IsGlideVehicle then ---@cast v dv.Glide
        v:SetInputFloat(1, "steer", steering)
    elseif isfunction(v.SetSteering) then ---@cast v Vehicle
        v:SetSteering(steering, 0)
    end

    local pose = self:GetPoseParameter "vehicle_steer" or 0
    self:SetPoseParameter("vehicle_steer", pose + (steering - pose) / 10)
end

local VCModFixedAroundNPCDriver = false -- This is a stupid solution.
if not VCModFixedAroundNPCDriver then -- WORKAROUND!!!
    hook.Add("CanPlayerEnterVehicle",
    "Decent Vehicle: VCMod is not compatible with npc_vehicledriver",
    function(ply, vehicle, role)
        if isfunction(vehicle.VC_getStates) and vehicle.DecentVehicle then return false end
    end)
end

---@param vehicle dv.Vehicle
function ENT:InitializeVehicle(vehicle)
    if vehicle.IsScar ---@cast vehicle dv.SCAR
    and not vehicle:HasDriver() then
        self.v = vehicle
        self.v.DecentVehicle = self
        self.v.AIController = self

        -- Tanks or something sometimes make errors so disable thinking.
        self.OldSpecialThink = self.v.SpecialThink
        self.v.SpecialThink = nil
    elseif vehicle.IsSimfphyscar ---@cast vehicle dv.Simfphys
    and vehicle:IsInitialized() and not IsValid(vehicle:GetDriver()) then
        self.v = vehicle
        self.v.DecentVehicle = self
        self.v.RemoteDriver = self
        self.HeadLightsID = numpad.OnUp  (self --[[@as Player]], KEY_F, "k_lgts",  self.v, false)
        self.FogLightsID  = numpad.OnDown(self --[[@as Player]], KEY_V, "k_flgts", self.v, true)
        self.ELSID        = numpad.OnUp  (self --[[@as Player]], KEY_H, "k_hrn",   self.v, false)
        self.HornID       = numpad.OnDown(self --[[@as Player]], KEY_H, "k_hrn",   self.v, true)

        self.OldPhysicsCollide = self.v.PhysicsCollide
        self.v.PhysicsCollide = function(...)
            self.CarCollide(...)
            return self.OldPhysicsCollide(...)
        end
    elseif vehicle.LVS or vehicle.LVS_GUNNER ---@cast vehicle dv.LVS
    and not IsValid(vehicle:GetDriver()) then ---@cast vehicle dv.LVS
        self.OldRunAI = vehicle.RunAI
        vehicle.RunAI = function() end
        vehicle:SetAI(true)
        vehicle:StartEngine()
        if isfunction(vehicle.ReleaseHandbrake) then vehicle:ReleaseHandbrake() end
        if isfunction(vehicle.SetActive) then vehicle:SetActive(true) end
        if isfunction(vehicle.SetReverse) then vehicle:SetReverse(false) end
        if isfunction(vehicle.DisableManualTransmission) then vehicle:DisableManualTransmission() end

        self.v = vehicle
        self.v.DecentVehicle = self
    elseif vehicle.IsGlideVehicle then ---@cast vehicle dv.Glide
        self.v = vehicle
        self.v.DecentVehicle = self
        if self.v.seats and IsValid(self.v.seats[1]) then
            self.v.seats[1].DecentVehicle = self
        end
    elseif ---@cast vehicle Vehicle
    isfunction(vehicle.GetWheelCount) and vehicle:GetWheelCount() -- Not a chair
    and isfunction(vehicle.IsEngineEnabled) and vehicle:IsEngineEnabled() -- Engine is not locked
    and not IsValid(vehicle:GetDriver()) then
        self.v = vehicle
        self.v.DecentVehicle = self
        self.OnCollideCallback = self.v:AddCallback("PhysicsCollide", self.CarCollide)
        if not isfunction(self.v.VC_getStates) or VCModFixedAroundNPCDriver then
            self:CreateNPCDriver()
        end
    end
end

function ENT:OnRemoveVehicle()
    local v = self.v
    v.DecentVehicle = nil
    if v.IsScar then ---@cast v dv.SCAR If the vehicle is SCAR.
        v.AIController = nil
        v.SpecialThink, self.OldSpecialThink = self.OldSpecialThink, nil
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys The vehicle is Simfphys Vehicle.
        v.PhysicsCollide, self.OldPhysicsCollide = self.OldPhysicsCollide, nil
        v.RemoteDriver = nil
        v.PressedKeys.W = false
        v.PressedKeys.A = false
        v.PressedKeys.S = false
        v.PressedKeys.D = false
        v.PressedKeys.Space = false

        numpad.Remove(self.HeadLightsID)
        numpad.Remove(self.FogLightsID)
        numpad.Remove(self.ELSID)
        numpad.Remove(self.HornID)
    elseif v.LVS or v.LVS_GUNNER then ---@cast v dv.LVS
        v:SetAI(false)
        v:StopEngine()
        v.RunAI, self.OldRunAI = self.OldRunAI, nil
        if isfunction(v.EnableHandbrake) then v:EnableHandbrake() end
        if isfunction(v.SetActive)       then v:SetActive(false)  end
        if isfunction(v.SetThrottle)     then v:SetThrottle(0)    end
        if isfunction(v.SetSteer)        then v:SetSteer(0)       end
    elseif v.IsGlideVehicle then ---@cast v dv.Glide
        if self.v.seats and IsValid(self.v.seats[1]) then
            self.v.seats[1].DecentVehicle = nil
        end
    else ---@cast v Vehicle
        v:RemoveCallback("PhysicsCollide", self.OnCollideCallback)
        v:SetSaveValue("m_nSpeed", 0)
    end

    if IsValid(self.NPCDriver) then
        self.NPCDriver:Fire "Stop"
        SafeRemoveEntity(self.NPCDriver)
    end
end

---@return boolean
function ENT:IsDestroyed()
    local v = self.v
    if v:IsFlagSet(FL_DISSOLVING) then return true end
    if v.IsScar then ---@cast v dv.SCAR
        return v:IsDestroyed()
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys
        return v:GetCurHealth() <= 0
    elseif v.LVS or v.LVS_GUNNER then ---@cast v dv.LVS
        return v:IsDestroyed()
    elseif v.IsGlideVehicle then ---@cast v dv.Glide
        return v:GetChassisHealth() < 1
    elseif isfunction(v.VC_getHealth) then ---@cast v Vehicle
        local health = v:VC_getHealth(false)
        return isnumber(health) and health <= 0
    end
    return false
end

---@return boolean?
function ENT:ShouldRefuel()
    local v = self.v
    if v.IsScar then ---@cast v dv.SCAR
        return v:GetFuelPercent() < self.RefuelThreshold
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys
        return v:GetFuel() / v:GetMaxFuel() < self.RefuelThreshold
    elseif v.LVS or v.LVS_GUNNER then ---@cast v dv.LVS
        local fueltank = v:GetFuelTank()
        if not IsValid(fueltank) then return false end
        return fueltank:GetFuel() < self.RefuelThreshold
    elseif v.IsGlideVehicle then ---@cast v dv.Glide
        return false
    elseif isfunction(v.VC_fuelGet) ---@cast v Vehicle
    and isfunction(v.VC_fuelGetMax) then
        return v:VC_fuelGet(false) / v:VC_fuelGetMax() < self.RefuelThreshold
    end
end

function ENT:Refuel()
    local v = self.v
    hook.Run("Decent Vehicle: OnRefuel", self)
    if v.IsScar then ---@cast v dv.SCAR
        v:Refuel()
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys
        v:SetFuel(v:GetMaxFuel())
    elseif v.LVS or v.LVS_GUNNER then ---@cast v dv.LVS
        local fueltank = v:GetFuelTank()
        if not IsValid(fueltank) then return end
        fueltank:SetFuel(1)
        if isfunction(v.OnRefueled) then
            v:OnRefueled()
        end
    elseif v.IsGlideVehicle then ---@cast v dv.Glide
        return
    elseif isfunction(v.VC_fuelSet) ---@cast v Vehicle
    and isfunction(v.VC_fuelGetMax) then
        v:VC_fuelSet(v:VC_fuelGetMax())
    end
end
