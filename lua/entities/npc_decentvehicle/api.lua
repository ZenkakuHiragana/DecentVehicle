
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

function ENT:GetMaxSteeringAngle()
    local v = self.v
    if v.IsScar then ---@cast v dv.SCAR
        return v.MaxSteerForce * 3 -- Obviously this is not actually steering angle
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys
        return v.VehicleData.steerangle
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

function ENT:GetRunningLights()
    local v = self.v
    if v.IsScar then ---@cast v dv.SCAR
        return v:GetNWBool "HeadlightsOn"
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys
        return self.SimfphysRunningLights
    elseif vcmod_main ---@cast v Vehicle
    and isfunction(v.VC_getStates) then
        local states = v:VC_getStates()
        return istable(states) and states.RunningLights
    end
end

function ENT:GetFogLights()
    local v = self.v
    if v.IsScar then ---@cast v dv.SCAR
        return v:GetNWBool "HeadlightsOn"
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys
        return self.SimfphysFogLights
    elseif vcmod_main ---@cast v Vehicle
    and isfunction(v.VC_getStates) then
        local states = v:VC_getStates()
        return istable(states) and states.FogLights
    end
end

function ENT:GetLights(highbeams)
    local v = self.v
    if v.IsScar then ---@cast v dv.SCAR
        return v:GetNWBool "HeadlightsOn"
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys
        return Either(highbeams, v.LampsActivated, v.LightsActivated)
    elseif vcmod_main ---@cast v Vehicle
    and isfunction(v.VC_getStates) then
        local states = v:VC_getStates()
        return istable(states) and Either(highbeams, states.HighBeams, states.LowBeams)
    elseif Photon ---@cast v Vehicle
    and isfunction(v.ELS_Illuminate) then
        return v:ELS_Illuminate()
    end
end

function ENT:GetTurnLight(left)
    local v = self.v
    if v.IsScar then -- Does SCAR have turn lights?
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys
        return Either(left, self.TurnLightLeft, self.TurnLightRight)
    elseif vcmod_main ---@cast v Vehicle
    and isfunction(v.VC_getStates) then
        local states = v:VC_getStates()
        return istable(states) and Either(left, states.TurnLightLeft, states.TurnLightRight)
    elseif Photon ---@cast v Vehicle
    and isfunction(v.CAR_TurnLeft)
    and isfunction(v.CAR_TurnRight) then
        return Either(left, v:CAR_TurnLeft(), v:CAR_TurnRight())
    end
end

function ENT:GetHazardLights()
    local v = self.v
    if v.IsScar then ---@cast v dv.SCAR
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys
        return self.HazardLights
    elseif vcmod_main ---@cast v Vehicle
    and isfunction(v.VC_getStates) then
        local states = v:VC_getStates()
        return istable(states) and states.HazardLights
    elseif Photon ---@cast v Vehicle
    and isfunction(v.CAR_Hazards) then
        return v:CAR_Hazards()
    end
end

function ENT:GetELS(v)
    local vehicle = v or self.v
    if not (IsValid(vehicle) and vehicle:IsVehicle()) then return end
    if vehicle.IsScar then ---@cast vehicle dv.SCAR
        return vehicle.SirenIsOn
    elseif vehicle.IsSimfphyscar then ---@cast vehicle dv.Simfphys
        return vehicle:GetEMSEnabled()
    elseif vcmod_main and vcmod_els ---@cast vehicle Vehicle
    and isfunction(vehicle.VC_getELSLightsOn) then
        return vehicle:VC_getELSLightsOn()
    elseif Photon ---@cast vehicle Vehicle
    and isfunction(vehicle.ELS_Siren)
    and isfunction(vehicle.ELS_Lights) then
        return vehicle:ELS_Siren() and vehicle:ELS_Lights()
    end
end

function ENT:GetELSSound(v)
    local vehicle = v or self.v
    if not (IsValid(vehicle) and vehicle:IsVehicle()) then return end
    if vehicle.IsScar then ---@cast vehicle dv.SCAR
        return vehicle.SirenIsOn
    elseif vehicle.IsSimfphyscar then ---@cast vehicle dv.Simfphys
        return vehicle.ems and vehicle.ems:IsPlaying()
    elseif vcmod_main and vcmod_els ---@cast vehicle Vehicle
    and isfunction(vehicle.VC_getELSSoundOn)
    and isfunction(vehicle.VC_getStates) then
        local states = vehicle:VC_getStates()
        return vehicle:VC_getELSSoundOn() or istable(states) and states.ELS_ManualOn
    elseif Photon ---@cast vehicle Vehicle
    and isfunction(vehicle.ELS_Siren) then
        return vehicle:ELS_Siren()
    end
end

function ENT:GetHorn(v)
    local vehicle = v or self.v
    if not (IsValid(vehicle) and vehicle:IsVehicle()) then return end
    if vehicle.IsScar then ---@cast vehicle dv.SCAR
        return vehicle.Horn:IsPlaying()
    elseif vehicle.IsSimfphyscar then ---@cast vehicle dv.Simfphys
        return vehicle.HornKeyIsDown
    elseif vcmod_main ---@cast vehicle Vehicle
    and isfunction(vehicle.VC_getStates) then
        local states = vehicle:VC_getStates()
        return istable(states) and states.HornOn
    elseif Photon ---@cast vehicle Vehicle
    and isnumber(EMV_HORN)
    and isfunction(vehicle.ELS_Horn) then
        return vehicle:GetDTBool(EMV_HORN)
    end
end

function ENT:GetLocked(v)
    local vehicle = v or self.v
    if not (IsValid(vehicle) and vehicle:IsVehicle()) then return end
    if vehicle.IsScar then ---@cast vehicle dv.SCAR
        return vehicle:IsLocked()
    elseif vehicle.IsSimfphyscar then ---@cast vehicle dv.Simfphys
        return vehicle.VehicleLocked
    elseif vcmod_main ---@cast vehicle Vehicle
    and isfunction(vehicle.VC_isLocked) then
        return vehicle:VC_isLocked()
    else ---@cast vehicle Vehicle
        return tonumber(vehicle:GetKeyValues().VehicleLocked) ~= 0
    end
end

function ENT:GetEngineStarted(v)
    local vehicle = v or self.v
    if not (IsValid(vehicle) and vehicle:IsVehicle()) then return end
    if vehicle.IsScar then ---@cast vehicle dv.SCAR
        return vehicle.IsOn
    elseif vehicle.IsSimfphyscar then ---@cast vehicle dv.Simfphys
        return vehicle:EngineActive()
    else ---@cast vehicle Vehicle
        return vehicle:IsEngineStarted()
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
    elseif vcmod_main ---@cast v Vehicle
    and isfunction(v.VC_setRunningLights) then
        v:VC_setRunningLights(on)
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
    elseif vcmod_main ---@cast v Vehicle
    and isfunction(v.VC_setFogLights) then
        v:VC_setFogLights(on)
    end
end

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
    elseif vcmod_main ---@cast v Vehicle
    and isfunction(v.VC_setHighBeams)
    and isfunction(v.VC_setLowBeams) then
        if on == self:GetLights(highbeams) then return end
        if highbeams then
            v:VC_setHighBeams(on)
        else
            v:VC_setLowBeams(on)
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
    elseif vcmod_main ---@cast v Vehicle
    and isfunction(v.VC_setTurnLightLeft)
    and isfunction(v.VC_setTurnLightRight) then
        v:VC_setTurnLightLeft(on and left)
        v:VC_setTurnLightRight(on and not left)
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
    elseif vcmod_main ---@cast v Vehicle
    and isfunction(v.VC_setHazardLights) then
        v:VC_setHazardLights(on)
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
    elseif vcmod_main and vcmod_els ---@cast v Vehicle
    and isfunction(v.VC_setELSLights)
    and isfunction(v.VC_setELSSound) then
        v:VC_setELSLights(on)
        v:VC_setELSSound(on)
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
    elseif vcmod_main and vcmod_els ---@cast v Vehicle
    and isfunction(v.VC_setELSSound) then
        v:VC_setELSSound(on)
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
    elseif vcmod_main ---@cast v Vehicle
    and isfunction(v.VC_getStates)
    and isfunction(v.VC_setStates) then
        local states = v:VC_getStates()
        if not istable(states) then return end
        states.HornOn = true
        v:VC_setStates(states)
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
    else ---@cast v Vehicle
        for _, seat in pairs(v:GetChildren()) do ---@cast seat Vehicle For Sligwolf's vehicles
            if not (seat:IsVehicle() and seat.__SW_Vars) then continue end
            seat:Fire(locked and "Lock" or "Unlock")
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
    elseif isfunction(v.StartEngine) then ---@cast v Vehicle
        v:StartEngine(on)
    end
end

function ENT:SetHandbrake(brake)
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
    elseif isfunction(v.SetHandbrake) then ---@cast v Vehicle
        v:SetHandbrake(brake)
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
    elseif isfunction(v.SetThrottle) then ---@cast v Vehicle
        v:SetThrottle(throttle)
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
        self.OldSpecialThink, self.v.SpecialThink = self.v.SpecialThink, nil
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
    elseif ---@cast vehicle Vehicle
    isfunction(vehicle.GetWheelCount) and vehicle:GetWheelCount() -- Not a chair
    and isfunction(vehicle.IsEngineEnabled) and vehicle:IsEngineEnabled() -- Engine is not locked
    and not IsValid(vehicle:GetDriver()) then
        self.v = vehicle
        self.v.DecentVehicle = self
        self.OnCollideCallback = self.v:AddCallback("PhysicsCollide", self.CarCollide)

        if not isfunction(self.v.VC_getStates) or VCModFixedAroundNPCDriver then
            local oldname = self.v:GetName()
            self.v:SetName "decentvehicle"
            self.NPCDriver = ents.Create "npc_vehicledriver"
            self.NPCDriver:Spawn()
            self.NPCDriver:SetKeyValue("Vehicle", "decentvehicle")
            self.NPCDriver:Activate()
            self.NPCDriver:Fire "StartForward"
            self.NPCDriver:Fire("SetDriversMaxSpeed", "100")
            self.NPCDriver:Fire("SetDriversMinSpeed", "0")
            self.NPCDriver.InVehicle = self.InVehicle
            self.NPCDriver.GetViewPunchAngles = self.GetViewPunchAngles -- For Seat Weaponizer 2
            self.NPCDriver.SetViewPunchAngles = self.SetViewPunchAngles -- Just to be sure
            self.NPCDriver:SetHealth(0) -- This makes other NPCs think the driver is dead
            self.NPCDriver:SetSaveValue("m_lifeState", -1) -- so that they don't attack it.
            self.NPCDriver.KeyDown = function(_, key)
                return key == IN_FORWARD and self.Throttle > 0
                or key == IN_BACK and self.Throttle < 0
                or key == IN_MOVELEFT and self.Steering < 0
                or key == IN_MOVERIGHT and self.Steering > 0
                or key == IN_JUMP and self.HandBrake
                or false
            end
            self.v:SetName(oldname or "")
        end
    end
end

function ENT:OnRemoveVehicle()
    local v = self.v
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
    else ---@cast v Vehicle
        v:RemoveCallback("PhysicsCollide", self.OnCollideCallback)
        v:SetSaveValue("m_nSpeed", 0)
        if IsValid(self.NPCDriver) then
            self.NPCDriver:Fire "Stop"
            SafeRemoveEntity(self.NPCDriver)
        end
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
    elseif isfunction(v.VC_fuelSet) ---@cast v Vehicle
    and isfunction(v.VC_fuelGetMax) then
        v:VC_fuelSet(v:VC_fuelGetMax())
    end
end
