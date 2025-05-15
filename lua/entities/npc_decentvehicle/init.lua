
-- Copyright © 2018-2030 Decent Vehicle
-- written by ∩(≡＾ω＾≡)∩ (https://steamcommunity.com/id/greatzenkakuman/)
-- and DangerKiddy(DK) (https://steamcommunity.com/profiles/76561198132964487/).

AddCSLuaFile "cl_init.lua"
AddCSLuaFile "shared.lua"
AddCSLuaFile "playermeta.lua"
include "shared.lua"
include "playermeta.lua"
include "api.lua"

local ENT = ENT ---@class ENT.DecentVehicle

-- https://steamcommunity.com/sharedfiles/filedetails/?id=531849338
-- ^ THIS overrides ents.FindInSphere() and breaks the original behavior.
-- Because of this, I have to do some workaround.
local CorrectFindInSphere = ents.FindInSphere
local HasFixedOnLocalizedPhysics = false
if not HasFixedOnLocalizedPhysics then
    for _, a in ipairs(engine.GetAddons()) do
        if tonumber(a.wsid) == 531849338 then
            CorrectFindInSphere = ENT.RealFindInSphere or CorrectFindInSphere
            if not ENT.RealFindInSphere then -- Just to make sure
                timer.Simple(1, function()
                    CorrectFindInSphere = ENT.RealFindInSphere or CorrectFindInSphere
                end)
            end
        end
    end
end

ENT.sPID                = Vector(1, 0, 0) -- PID parameters for steering
ENT.tPID                = Vector(1, 0, 0) -- PID parameters for throttle
ENT.Throttle            = 0
ENT.Steering            = 0
ENT.HandBrake           = false
ENT.Waypoint            = nil ---@type dv.Waypoint?
ENT.NextWaypoint        = nil ---@type dv.Waypoint?
ENT.PrevWaypoint        = nil ---@type dv.Waypoint?
ENT.WaypointList        = {}  ---@type dv.Waypoint[] -- For navigation
ENT.WaypointOffset      = 0               -- For giving way
ENT.SteeringInt         = 0               -- Steering integration
ENT.SteeringOld         = 0               -- Steering difference = (diff - self.SteeringOld) / FrameTime()
ENT.ThrottleInt         = 0               -- Throttle integration
ENT.ThrottleOld         = 0               -- Throttle difference = (diff - self.ThrottleOld) / FrameTime()
ENT.Prependicular       = 0               -- If the next waypoint needs to turn quickly, this is close to 1.
ENT.RelativeSpeed       = 0               -- Current speed / maximum speed
ENT.WaitUntilNext       = CurTime()
ENT.RefuelThreshold     = .25             -- If the fuel is less than this fraction, the vehicle finds a fuel station.
ENT.MaxSpeedCoefficient = 1               -- Multiplying this on the maximum speed of the vehicle.
ENT.UseLeftTurnLight    = false           -- Which turn light the vehicle should turn on.
ENT.DontUseSpawnEffect  = false           -- Whether or not spawn effect should be performed on spawning the driver.
ENT.Emergency           = CurTime()
ENT.IsGivingWay         = CurTime()       -- Giving way if CurTime() < ENT.IsGivingWay
ENT.NextDoLights        = CurTime()
ENT.NextGiveWay         = CurTime()
ENT.NextTrace           = CurTime()
ENT.StopByTrace         = CurTime()

ENT.Preference = { -- Some preferences for Decent Vehicle here
    DoTrace                            = true,  -- Whether or not it does some traces
    GiveWay                            = true,  -- Whether or not it gives way for vehicles with ELS
    GiveWayTime                        = 5,     -- Time to reset the offset for giving way
    GobackDuration                     = 0.7,   -- Duration of going back on stuck
    GobackTime                         = 10,    -- Time to start going back on stuck
    LockVehicle                        = false, -- Whether or not it allows other players to get in
    LockVehicleDependsOnCVar           = true,  -- Whether or not LockVehicle depends on CVar
    ShouldGoback                       = true,  -- Whether or not it should go backward on stuck
    StopAtTL                           = true,  -- Whether or not it stops at traffic lights with red sign
    StopEmergency                      = true,  -- Whether or not it stops on crash
    StopEmergencyDuration              = 5,     -- Duration of stopping on crash
    StopEmergencyDurationDependsOnCVar = true,  -- Same as LockVehicle, but for StopEmergencyDuration
    StopInfrontofPerson                = true,  -- Whether or not it stops when it sees something in front of it
    StopInfrontofPersonDependsOnCVar   = true,  -- Same as LockVehicle, but for StopInfrontofPerson
    TraceMaxBound                      = 64,    -- Maximum hull size of trace: max = Vector(1, 1, 1) * this value, min = -max
    TraceMinLength                     = 200,   -- Minimum trace length in hammer units
    WaitUntilNext                      = true,  -- Whether or not it waits on WaitUntilNext
}

ENT.Interval = { -- The interval of execution.
    DoLights = 1 / 10, -- Checking lights
    GiveWay  = 1 / 20, -- Checking for giving way
    Trace    = 1 / 15, -- The time between doing a trace and next time.
}

-- Constant values used in Atmos
local TIME_NOON       = 12   -- 12:00 pm
local TIME_MIDNIGHT   = 0    -- 12:00 am
local TIME_DAWN_START = 4    -- 4:00 am
local TIME_DAWN_END   = 6.5  -- 6:30 am
local TIME_DUSK_START = 19   -- 7:00 pm
local TIME_DUSK_END   = 20.5 -- 8:30 pm

local dvd = DecentVehicleDestination
local vector_one = Vector(1, 1, 1)
local TraceMax = 64
local TraceMinLength = 200
local TraceHeightGap = math.sqrt(3) -- The multiplier between ground and the bottom of the trace
local GiveWayTime = 5 -- Time to reset the offset for giving way
local GobackTime = 10 -- The time to start to go backward by the trace.
local GobackDuration = 0.7 -- The duration of going backward by the trace.
local TimeToStopEmergency = dvd.CVars.TimeToStopEmergency
local ShouldGoToRefuel = dvd.CVars.ShouldGoToRefuel
local DetectionRange = dvd.CVars.DetectionRange
local DetectionRangeELS = dvd.CVars.DetectionRangeELS
local DriveSide = dvd.CVars.DriveSide
local LockVehicle = dvd.CVars.LockVehicle
local StopInfrontofPerson = dvd.CVars.StopInfrontofPerson
local Interval = {
    DoLights = 1 / 10,
    GiveWay = 1 / 20,
    Trace = 1 / 20, -- DV will trace 20 times per second by default
}
local NightSkyTextureList = {
    sky_borealis01 = true,
    sky_day01_09 = true,
    sky_day02_09 = true,
}

---@param tr Structure.TraceResult
---@return boolean?
local function IsObstacle(tr)
    return tr and (IsValid(tr.Entity) or tr.HitWorld and tr.HitNormal:Dot(vector_up) < .7)
end

---A filter function of selecting a next waypoint.
---@param self ENT.DecentVehicle
---@param waypoint dv.Waypoint
---@param n integer
---@return boolean
local function FilterUTurnAndGroup(self, waypoint, n)
    if not dvd.WaypointAvailable(n, self.Group) then return false end
    local pos = self.v:GetPos()
    local w = dvd.Waypoints[n]
    if waypoint.Target:DistToSqr(pos) < 1e4 then return true end
    return (waypoint.Target - pos):Dot(w.Target - waypoint.Target) > 0
end

---@return boolean
local function GetNight()
    if dvd.CVars.ForceHeadlights:GetBool() then return true end
    if istable(StormFox) then return StormFox.IsNight() end
    if istable(AtmosGlobal) and isnumber(AtmosGlobal.m_Time) then
        local t = AtmosGlobal.m_Time
        return t > TIME_DUSK_END or t < TIME_DAWN_END
    end

    local skyname = GetConVar "sv_skyname" :GetString()
    return NightSkyTextureList[skyname] or tobool(skyname:lower():find "night")
end

---@return boolean
---@return number
local function GetFogInfo()
    local FogEditors = ents.FindByClass "edit_fog"
    ---@class Entity.FogEditor : Entity
    ---@field GetFogEnd fun(self: Entity.FogEditor): number
    local fogEditor
    for _, f in ipairs(FogEditors) do ---@cast f Entity.FogEditor
        if not fogEditor or fogEditor:EntIndex() < f:EntIndex() then
            fogEditor = f
        end
    end

    if IsValid(fogEditor) and isfunction(fogEditor.GetFogEnd) then
        return true, fogEditor:GetFogEnd()
    end

    if not StormFox then
        local FogTable = ents.FindByClass "env_fog_controller"
        local FogController ---@type Entity
        for i = 1, #FogTable do
            local f = FogTable[i]
            if not IsValid(f) then continue end
            if IsValid(FogController) and FogController:EntIndex() > f:EntIndex() then continue end
            FogController = f
        end

        if not IsValid(FogController) then return false, 0 end
        local keyvalues = FogController:GetKeyValues()
        return keyvalues.fogenable > 0, keyvalues.fogend
    end

    local enabled = GetConVar "sf_enablefog"
    return enabled and enabled:GetBool()
    and StormFox.GetWeather() == "Fog", StormFox.GetData "Fogend"
end

function ENT:CarCollide(data)
    self = self.v and self or self.DecentVehicle
    if not self then return end
    if self.Preference.StopEmergency and data.Speed > 200 and not data.HitEntity:IsPlayer() then
        local duration = self.Preference.StopEmergencyDuration
        if not duration or self.Preference.StopEmergencyDurationDependsOnCVar then
            duration = TimeToStopEmergency:GetFloat()
        end

        self.Emergency = CurTime() + duration
    end

    hook.Run("Decent Vehicle: OnCollide", self, data)
end

---@return number
function ENT:EstimateAccel()
    local accel = 0
    local v = self.v
    if v.IsScar then ---@cast v dv.SCAR
        local phys = v:GetPhysicsObject()
        local velVec = phys:GetVelocity()
        local vel = velVec:Length()
        local dir = velVec:Dot(self:GetForward())
        local force = 1
        if v.DriveStatus == 1 then -- Brake or forward
            if dir < 0 and vel > 40 then -- BRAKE
                force = v.BreakForce
            elseif v.IsOn and vel < v.MaxSpeed and v:HasFuel() then -- FORWARD
                force = v.Acceleration
            end
        else -- Brake or reverse
            if dir > vel * .9 and vel > 10 then -- BRAKE
                force = v.BreakForce * 1.5
            elseif v.IsOn and vel < v.ReverseMaxSpeed and v:HasFuel() then -- REVERSE
                force = v.ReverseForce
            end
        end

        accel = math.max(force * v.WheelTorqTraction, 1)
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys
        accel = v:GetMaxTorque() * 2 - math.Clamp(v.ForwardSpeed, -v.Brake, v.Brake)
    else ---@cast v Vehicle
        local forward = v:GetForward()
        local gearratio = self.GearRatio[v:GetOperatingParams().gear + 1]
        local numwheels = v:GetWheelCount()
        local wheelangvelocity = 0.0
        local wheeldirvelocity = 0.0
        local damping, rotdamping = 0.0, 0.0
        for i = 0, numwheels - 1 do
            local w = v:GetWheel(i)
            wheelangvelocity = wheelangvelocity + math.rad(math.abs(w:GetAngleVelocity().x)) / numwheels ---@type number
            wheeldirvelocity = wheeldirvelocity + w:GetVelocity():Dot(forward) / numwheels ---@type number
        end

        for i, a in ipairs(v:GetVehicleParams().axles) do
            damping = damping + a.wheels_damping * wheeldirvelocity / a.wheels_mass ---@type number
            rotdamping = rotdamping + a.wheels_rotdamping * wheelangvelocity ---@type number
        end

        accel = 552 * (self.HorsePower * self.AxleRatio * gearratio - rotdamping * math.sqrt(2))
        * self.WheelCoefficient / self.Mass - damping * math.sqrt(2) + physenv.GetGravity():Dot(forward)
    end

    return hook.Run("Decent Vehicle: EstimateAccel", self, accel) or accel
end

function ENT:GetVehicleParams()
    local v = self.v
    if v.IsScar then ---@cast v dv.SCAR
        self.BrakePower = v.BreakForce / 1000
        self.Mass = v.CarMass
        self.MaxSpeed = v.MaxSpeed
        self.MaxRevSpeed = v.ReverseMaxSpeed
    elseif v.IsSimfphyscar then ---@cast v dv.Simfphys
        self.BrakePower = v:GetBrakePower()
        self.Mass = v.Mass
        self.MaxSpeed = self.Mass * v.Efficiency * v.PeakTorque / v.MaxGrip
        self.MaxRevSpeed = self.MaxSpeed * math.abs(math.min(unpack(v.Gears)) / math.max(unpack(v.Gears)))
        local positive_offset, num_positive, negative_offset, num_negative = 0, 0, 0, 0
        for _, w in ipairs(v.Wheels) do
            local pos = v:WorldToLocal(w:GetPos()).y
            if pos > 0 then
                positive_offset, num_positive = positive_offset + pos, num_positive + 1
            else
                negative_offset, num_negative = negative_offset + pos, num_negative + 1
            end
        end

        self.WheelBase = positive_offset / math.max(num_positive, 1) - negative_offset / math.max(num_negative, 1)
    elseif isfunction(v.GetVehicleParams) then ---@cast v Vehicle
        local params = v:GetVehicleParams()
        local axles = params.axles
        local body = params.body
        local engine = params.engine
        local steering = params.steering
        self.BrakePower = 0
        self.AxleFactor = 0
        self.Mass = body.massOverride
        self.WheelRadius = 0
        local minr, maxr = math.huge, -math.huge
        for _, axle in ipairs(axles) do
            self.BrakePower = self.BrakePower + axle.brakeFactor
            self.AxleFactor = self.AxleFactor + axle.torqueFactor / axle.wheels_radius
            self.Mass = self.Mass + axle.wheels_mass * params.wheelsPerAxle
            self.WheelRadius = self.WheelRadius + axle.wheels_radius / #axles
            minr, maxr = math.min(minr, axle.wheels_radius), math.max(maxr, axle.wheels_radius)
        end

        self.WheelBase = #axles > 1 and axles[1].offset:Distance(axles[2].offset) or 1
        self.WheelRatio = minr / maxr
        self.WheelCoefficient = 1 / math.sqrt(self.WheelRadius * self.WheelRatio)
        self.BoostSpeed = engine.boostMaxSpeed
        self.MaxSpeed = engine.maxSpeed
        self.MaxRevSpeed = engine.maxRevSpeed
        self.HorsePower = engine.horsepower
        self.GearCount = engine.gearCount
        self.GearRatio = engine.gearRatio
        self.AxleRatio = engine.axleRatio

        self.SteeringParams = steering
        self.SteeringExponent = steering.steeringExponent
        self.SteeringSpeedFast = steering.speedFast
        self.SteeringSpeedSlow = steering.speedSlow
        self.SteeringAngleBoost = steering.degreesBoost
        self.SteeringAngleFast = steering.degreesFast
        self.SteeringAngleSlow = steering.degreesSlow
        self.SteeringRateFast = steering.steeringRateFast
        self.SteeringRateSlow = steering.steeringRateSlow
        self.SteeringRestRateFast = steering.steeringRestRateFast
        self.SteeringRestRateSlow = steering.steeringRestRateSlow
    end
end

function ENT:GetVehiclePrefix()
    if self.v.IsScar then
        return "SCAR_"
    elseif self.v.IsSimfphyscar then
        return "Simfphys_"
    else
        return "Source_"
    end
end

function ENT:GetVehicleIdentifier()
    local id = ""
    if self.v.IsScar then
        id = self.v:GetClass()
    elseif self.v.IsSimfphyscar then
        id = self.v:GetModel() or "INVALID_MODEL"
    else
        id = self.v:GetModel() or "INVALID_MODEL"
    end

    return self:GetVehiclePrefix() .. id
end

function ENT:AttachModel()
    local v = self.v
    local seat = v ---@type Entity
    if v.IsScar then ---@cast v dv.SCAR
        seat = v.Seats and v.Seats[1]
    elseif self.v.IsSimfphyscar then ---@cast v dv.Simfphys
        seat = v.DriverSeat
    end

    if not IsValid(seat) then return end
    local anim = dvd.DriverAnimation[self:GetVehicleIdentifier()]
              or dvd.DriverAnimation[self:GetVehiclePrefix()] or "drive_jeep"
    local model = dvd.DefaultDriverModel[math.random(#dvd.DefaultDriverModel)]
    if istable(self.Model) then
        model = self.Model[math.random(#self.Model)]
    elseif isstring(self.Model) then
        model = self.Model --[[@as string]]
    end
    self:SetModel(model)
    self:SetNWEntity("Seat", seat)
    self:SetNWEntity("Vehicle", self.v)
    self:SetNWInt("Sequence", self:LookupSequence(anim))
    self:SetParent(seat)
    seat:SetSequence(0) -- Resets the sequence first to correct the seat position

    timer.Simple(.1, function() -- Entity:Sequence() will not work properly if it is
        if not IsValid(seat) then return end -- called directly after calling Entity:SetModel().
        if not IsValid(self) then return end
        if not IsValid(self.v) then return end
        local a = seat:GetAttachment(assert(seat:LookupAttachment "vehicle_driver_eyes", dvd.Texts.Errors.AttachmentNotFound))
        local d = dvd.SeatPos[self:GetVehicleIdentifier()] or dvd.SeatPos[self:GetVehiclePrefix()] or Vector(-8, 0, -32)
        local seatang = seat:WorldToLocalAngles(a.Ang)
        local seatpos = seat:WorldToLocal(a.Pos + a.Ang:Forward() * d.x + a.Ang:Right() * d.y + a.Ang:Up() * d.z)
        self:SetNWVector("Pos", seatpos)
        self:SetNWAngle("Ang", seatang)
        self:SetSequence(anim)

        for i = 0, self:GetFlexNum() - 1 do
            self:SetFlexWeight(i, self:GetFlexBounds(i))
        end
    end)
end

---@return number
function ENT:GetCurrentMaxSpeed()
    local destlength = self.Waypoint.Target:Distance(self.v:WorldSpaceCenter())
    local maxspeed = math.Clamp(self.Waypoint.SpeedLimit, 1, self.MaxSpeed)
    if self.PrevWaypoint then
        local total = self.Waypoint.Target:Distance(self.PrevWaypoint.Target)
        local frac = (1 - destlength / total)^2
        if self.NextWaypoint then -- The speed limit is affected by connected waypoints
            maxspeed = Lerp(frac, maxspeed, math.Clamp(self.NextWaypoint.SpeedLimit, 1, self.MaxSpeed))
        end

        -- If the waypoint has a sharp corner, slow down
        maxspeed = maxspeed * Lerp(frac, 1, 1 - self.Prependicular * .9)
        if self.Waypoint.TrafficLight and self.Waypoint.TrafficLight:GetNWInt "DVTL_LightColor" == 3 then
            maxspeed = maxspeed * (1 - frac) ---@type number
        end
    end

    maxspeed = maxspeed * math.max(1 - self.v:GetPhysicsObject():GetAngleVelocity():Dot(self:GetVehicleUp()) / 60, 0)
    maxspeed = maxspeed * math.Clamp(self.MaxSpeedCoefficient, 0, 1)
    return hook.Run("Decent Vehicle: GetCurrentMaxSpeed", self, maxspeed) or maxspeed
end

---@return boolean?
function ENT:IsValidVehicle()
    if not IsValid(self.v) then return end -- The tied vehicle goes NULL.
    if not self.v:IsVehicle() then return end -- Somehow it becomes non-vehicle entity.
    if not self.v.DecentVehicle then return end -- Somehow it's a normal vehicle.
    if not IsValid(self:GetNWEntity "Seat") then return end -- It couldn't find the driver seat.
    if self ~= self.v.DecentVehicle then return end -- It has a different driver.
    if self.v:WaterLevel() > 1 then return end -- It falls into water.
    if self:IsDestroyed() then return end -- It is destroyed.
    return true
end

---@return boolean?
function ENT:AtTrafficLight()
    if self.FormLine then return true end
    if not self.PrevWaypoint then return end
    if not self.PrevWaypoint.TrafficLight then return end
    if self:GetVehicleForward():Dot(self.PrevWaypoint.Target - self.v:WorldSpaceCenter()) < 0
    and self.PrevWaypoint.Target:Distance(self.v:WorldSpaceCenter()) > self.v:BoundingRadius() then return end
    if self.PrevWaypoint.TrafficLight:GetNWInt "DVTL_LightColor" == 3 then return true end
end

---@return boolean?
function ENT:ShouldStopGoingback()
    if self.FormLine then return end
    if not self.Preference.ShouldGoback then return true end
    if IsValid(self.TraceBack.Entity) or self.TraceBack.HitWorld
    and self.TraceBack.HitNormal:Dot(vector_up) < .7 then
        self.StopByTrace = CurTime() + FrameTime() -- Reset going back timer
        return true
    end

    local ent = self.Trace.Entity
    if not IsValid(ent) then return end

    local dv = ent.DecentVehicle
    if not dv then return end
    if dv:GetELS() then return true end
    if CurTime() > dv.WaitUntilNext then return end
    if CurTime() > dv.Emergency then return end
    return true
end

---@return boolean?
function ENT:ShouldStop()
    if not self.Waypoint then return true end
    if CurTime() < self.WaitUntilNext then return true end
    if CurTime() < self.Emergency then return true end
    if self.Preference.StopInfrontofPerson and CurTime() > self.StopByTrace
    and CurTime() < self.StopByTrace + GobackTime then return true end
    if self.Preference.StopAtTL and self:AtTrafficLight() then return true end
end

function ENT:FindFuelStation()
    local routes = select(2, dvd.GetFuelStations()) ---@type integer[]
    local destinations = {} ---@type table<integer, true>
    for _, id in ipairs(routes) do
        destinations[id] = true
    end

    local route = dvd.GetRoute(select(2, dvd.GetNearestWaypoint(self.Waypoint.Target)), destinations, self.Group)
    if not route then return end

    self.WaypointList = route
    return true
end

function ENT:FindRoute(routetype)
    if #self.WaypointList > 0 then return end
    if not isfunction(self["Find" .. routetype]) then return end
    if not self["Find" .. routetype](self) then return end
    self.NextWaypoint = table.remove(self.WaypointList)
end

function ENT:StopDriving()
    hook.Run("Decent Vehicle: StopDriving", self)
    self:SetHandbrake(true)
    self:SetThrottle(0)
    self:SetSteering(0)
    self.SteeringInt, self.SteeringOld = 0, 0
    self.ThrottleInt, self.ThrottleOld = 0, 0
    if IsValid(self.NPCDriver) then
        self.NPCDriver:SetSaveValue("m_vecDesiredPosition", vector_origin)
        self.NPCDriver:SetSaveValue("m_vecDesiredPosition", vector_origin)
    end
end

---Drive the vehicle toward ENT.Waypoint.Target.
---@return boolean? arrived Has the vehicle arrived at the current destination.
function ENT:DriveToWaypoint()
    if not self.Waypoint then return end
    local sPID = dvd.PID.Steering[self:GetVehicleIdentifier()] or self.sPID
    local tPID = dvd.PID.Throttle[self:GetVehicleIdentifier()] or self.tPID
    local throttle = 1 -- The output throttle
    local steering = 0 -- The output steering
    local handbrake = false -- The output handbrake
    local vehiclepos = self.v:WorldSpaceCenter()
    local waypointpos = self.Waypoint.Target
    local startpos = self.PrevWaypoint and self.PrevWaypoint.Target
    local bound = self.v:BoundingRadius()
    local forward = self:GetVehicleForward()
    local up = self:GetVehicleUp()
    local velocity = self.v:GetVelocity()
    local velocitydot = velocity:Dot(forward)
    local currentspeed = math.abs(velocitydot)
    local maxspeed = self:GetCurrentMaxSpeed()
    local relspeed = currentspeed / maxspeed
    local targetpos = waypointpos
    if startpos and not self.Waypoint.TrafficLight then
        local way_length = startpos:Distance(waypointpos)
        local start_to_vehicle = vehiclepos - startpos
        if not start_to_vehicle:IsEqualTol(vector_origin, 1) and way_length > 0 then
            local way_direction = dvd.GetDir(startpos, waypointpos)
            local offset = self.WaypointOffset * vector_up:Cross(way_direction)
            start_to_vehicle = start_to_vehicle - offset
            local distance = way_direction:Cross(start_to_vehicle):Dot(up)
            local length = way_direction:Dot(start_to_vehicle) + bound * 1.5
            local speed_dependant = bound * 1.5 - distance
            local frac = math.max(length, length - speed_dependant * relspeed) / way_length
            local p1, p2 = startpos + offset, waypointpos + offset
            if frac > 1 and self.NextWaypoint then
                local nextpos = self.NextWaypoint.Target
                frac, p1, p2 = math.max(frac - 1, 0), p2, nextpos + offset
            end

            targetpos = LerpVector(math.Clamp(frac, 0, 1), p1, p2)
        end
    end
    debugoverlay.Cross(targetpos, 30, .1, Color(0, 255, 0), true)

    local dest = targetpos - vehiclepos
    local todestination = dest:GetNormalized()
    local cross = todestination:Cross(forward)
    local steering_angle = math.deg(math.asin(math.Clamp(cross:Dot(up), -1, 1))) / math.abs(self:GetMaxSteeringAngle())
    local steering_differece = (steering_angle - self.SteeringOld) / FrameTime()
    self.SteeringInt = self.SteeringInt + steering_angle * FrameTime()
    self.SteeringOld = steering_angle
    steering = sPID.x * steering_angle + sPID.y * self.SteeringInt + sPID.z * steering_differece
    if steering ~= steering then steering = 0 end

    local estimateaccel = math.abs(self:EstimateAccel())
    local speed_difference = maxspeed - currentspeed
    local throttle_difference = (speed_difference - self.ThrottleOld) / FrameTime()
    self.ThrottleInt = self.ThrottleInt + speed_difference * FrameTime()
    self.ThrottleOld = speed_difference
    throttle = tPID.x * speed_difference + tPID.y * self.ThrottleInt + tPID.z * throttle_difference
    if throttle ~= throttle then throttle = 0 end

    -- Prevents from going backward
    local goback = forward:Dot(todestination)
    local approaching = velocity:Dot(todestination) / velocity:Length()
    -- Handbrake when intending to go backward and actually moving forward or vise-versa
    goback = Either(velocitydot > 0, goback < -.5, goback < .5) and -1 or 1
    handbrake = currentspeed > 10 and goback * velocitydot < 0
    or currentspeed > math.max(100, maxspeed * .2) and math.abs(approaching) < .5

    if goback < 0 then
        steering = steering > 0 and -1 or 1
    elseif handbrake and not (self.v.IsScar or self.v.IsSimfphyscar) then
        steering = -steering
    end

    local gobacktime = self.Preference.GobackTime or GobackTime
    local duration = self.Preference.GobackDuration or GobackDuration
    local GobackByTrace = CurTime() - self.StopByTrace - gobacktime
    if not self:ShouldStopGoingback() and 0 < GobackByTrace and GobackByTrace < duration then
        goback = -1
        handbrake = false
    else
        if GobackByTrace > duration then
            self.StopByTrace = CurTime() + FrameTime() -- Reset going back timer
        end

        if not (self.v.IsScar or self.v.IsSimfphyscar)
        and velocitydot * goback * throttle < 0
        and dvd.GetAng(physenv.GetGravity(), forward) < .1 then -- Exception #1: DV is going down
            throttle = 0 -- The solution of the brake issue.
        end
    end

    if IsValid(self.NPCDriver) then
        local desiredvelocity = todestination * maxspeed
        self.NPCDriver:SetSaveValue("m_vecDesiredPosition", targetpos)
        self.NPCDriver:SetSaveValue("m_vecDesiredVelocity", desiredvelocity)
    end

    self.RelativeSpeed = relspeed
    self:SetHandbrake(handbrake)
    self:SetThrottle(math.Clamp(throttle / estimateaccel, -1, 1) * goback)
    self:SetSteering(steering)

    hook.Run("Decent Vehicle: Drive", self)
    local rest_length = dvd.GetDir(startpos or vehiclepos, waypointpos):Dot(waypointpos - vehiclepos)
    local threshold = math.max(bound, math.max(0, velocitydot) * self.Prependicular)
    return rest_length < threshold and not IsObstacle(self.TraceNextWaypoint)
end

function ENT:GetNPCDriver()
  return self.NPCDriver
end

function ENT:DoLights()
    if CurTime() < self.NextDoLights then return end
    local fogenabled, fogend = GetFogInfo()
    local fog = fogenabled and fogend < 5000
    self:SetRunningLights(self:GetEngineStarted())
    self:SetLights(GetNight() or fog, fog)
    self:SetFogLights(fog)
    self:SetTurnLight(self.Waypoint and self.Waypoint.UseTurnLights or false, self.UseLeftTurnLight)
    self:SetHazardLights(CurTime() < self.Emergency)
    self.NextDoLights = CurTime() + (self.Interval.DoLights or Interval.DoLights)
end

function ENT:DoTrace()
    if not self.Preference.DoTrace then return end
    if not self.Waypoint then return end
    if CurTime() < self.NextTrace then return end
    local boundradius = self.v:BoundingRadius() / 2
    local filter = self:GetTraceFilter()
    local forward = self:GetVehicleForward()
    local right = self:GetVehicleRight()
    local up = self:GetVehicleUp()
    local vehiclepos = self.v:WorldSpaceCenter()
    local velocity = self.v:GetVelocity()
    local tracedir = Vector(velocity)
    local tracemin = self.Preference.TraceMinLength or TraceMinLength
    if velocity:LengthSqr() > tracemin^2 then
        tracedir:Normalize()
    else
        tracedir = forward
    end

    local velocitydot = velocity:Dot(tracedir)
    local currentspeed = math.abs(velocitydot)
    local trlength = math.max(tracemin, currentspeed * .8)
    self.TraceLength = Lerp((CurTime() - self.StopByTrace) / GobackTime, trlength, self.TraceLength or trlength)
    local kph = currentspeed / dvd.KphToHUps
    local groundpos = util.QuickTrace(vehiclepos, -vector_up * 32768, filter).HitPos
    local height = (vehiclepos.z - groundpos.z) / math.sqrt(2)
    local bound = math.min(self.Preference.TraceMaxBound or TraceMax, height)
    / Lerp(math.abs(math.sin(math.rad(self.v:GetAngles().yaw * 2))), 1, math.sqrt(2))
    local maxs = vector_one * bound
    local mins = -maxs
    local heightoffset = up * height * TraceHeightGap
    local start = groundpos + heightoffset
    local prevpos = self.PrevWaypoint and self.PrevWaypoint.Target or groundpos
    local waypointpos = self.Waypoint.Target + heightoffset
    local waypointdir = dvd.GetDir(start, waypointpos)
    local pathdir = dvd.GetDir(prevpos, self.Waypoint.Target)
    local sideoffset = pathdir:Cross(up) * bound * 2.5
    local startonpath = prevpos + pathdir * pathdir:Dot(start - prevpos) + heightoffset
    local trwaypoint_isvalid = dvd.GetAng(waypointpos - start, tracedir) > .7

    local boundsqr = bound^2
    local tr = {
        start = start,
        endpos = start + tracedir * self.TraceLength,
        maxs = maxs, mins = mins,
        filter = filter,
    }
    local trback = {
        start = start,
        endpos = start - tracedir * self.TraceLength / 2,
        maxs = maxs, mins = mins,
        filter = filter,
    }
    local trwaypoint = {
        start = start,
        endpos = waypointpos,
        maxs = maxs, mins = mins,
        filter = filter,
    }
    local trleft = {
        start = startonpath - sideoffset,
        endpos = startonpath - sideoffset + pathdir * self.TraceLength,
        maxs = maxs, mins = mins,
        filter = filter,
    }
    local trright = {
        start = startonpath + sideoffset,
        endpos = startonpath + sideoffset + pathdir * self.TraceLength,
        maxs = maxs, mins = mins,
        filter = filter,
    }
    if self.NextWaypoint then
        local trnext = {
            start = start,
            endpos = self.NextWaypoint.Target + heightoffset,
            maxs = maxs, mins = mins,
            filter = filter,
        }
        self.TraceNextWaypoint = util.TraceHull(trnext)
        debugoverlay.SweptBox(trnext.start, trnext.endpos, trnext.mins, trnext.maxs, angle_zero, self.Interval.Trace, Color(0, 255, 255))
    end

    self.Trace = util.TraceHull(tr)
    self.TraceBack = util.TraceHull(trback)
    self.TraceWaypoint = util.TraceHull(trwaypoint)
    self.TraceLeft = util.TraceHull(trleft)
    self.TraceRight = util.TraceHull(trright)
    self.NextTrace = CurTime() + (self.Interval.Trace or Interval.Trace)
    trwaypoint_isvalid = trwaypoint_isvalid and self.Trace.HitPos:Distance(tr.start) > self.TraceWaypoint.HitPos:Distance(tr.start)
    debugoverlay.SweptBox(tr.start, tr.endpos, tr.mins, tr.maxs, angle_zero, self.Interval.Trace, Color(0, 255, 0))
    debugoverlay.SweptBox(trback.start, trback.endpos, trback.mins, trback.maxs, angle_zero, self.Interval.Trace, Color(255, 255, 0))
    debugoverlay.SweptBox(trwaypoint.start, trwaypoint.endpos, trwaypoint.mins, trwaypoint.maxs, angle_zero, self.Interval.Trace, Color(0, 255, 0))
    debugoverlay.SweptBox(trleft.start, trleft.endpos, trleft.mins, trleft.maxs, angle_zero, self.Interval.Trace, Color(255, 255, 0))
    debugoverlay.SweptBox(trright.start, trright.endpos, trright.mins, trright.maxs, angle_zero, self.Interval.Trace, Color(255, 255, 0))
    debugoverlay.SweptBox(tr.start, self.Trace.HitPos, tr.mins, tr.maxs, angle_zero, self.Interval.Trace)

    if self.TraceLeft.StartSolid then
        trleft.start, trleft.endpos = startonpath, start - sideoffset
        self.TraceLeft = util.TraceHull(trleft)
    end

    if self.TraceRight.StartSolid then
        trright.start, trright.endpos = startonpath, start + sideoffset
        self.TraceRight = util.TraceHull(trright)
    end

    local ent = self.Trace.Entity
    local hitforward = IsObstacle(self.Trace)
    local hitleft = IsObstacle(self.TraceLeft)
    local hitright = IsObstacle(self.TraceRight)
    local hitwaypoint = trwaypoint_isvalid and IsObstacle(self.TraceWaypoint)
    if hitforward and not hitwaypoint and tracedir:Dot(waypointdir) > 0 then
        local trhit = {
            start = LerpVector(.8, start, self.Trace.HitPos),
            endpos = trwaypoint.endpos,
            maxs = maxs, mins = mins,
            filter = filter,
        }

        debugoverlay.SweptBox(trhit.start, trhit.endpos, trhit.mins, trhit.maxs, angle_zero, self.Interval.Trace, Color(0, 255, 0))
        if tracedir:Dot(trhit.endpos - trhit.start) > 0 then
            local tr = util.TraceHull(trhit)
            hitforward = IsObstacle(tr)
        end
    end

    if trwaypoint_isvalid and not IsValid(ent) and IsValid(self.TraceWaypoint.Entity) then
        ent = self.TraceWaypoint.Entity
    end

    if not (hitforward or hitwaypoint) then
        if CurTime() < self.StopByTrace + GobackTime then
            self.StopByTrace = CurTime() + .1
        end

        self.FormLine = false
    elseif IsValid(ent) then
        local dv = ent.DecentVehicle
        local dvTrace = dv and dv.Trace and dv.Trace.Entity
        local dvTraceW = dv and dv.TraceWaypoint and dv.TraceWaypoint.Entity
        self.FormLine = dv and dv:AtTrafficLight()

        if dv then
            if dvTrace == self.v or dvTraceW == self.v
            or (self:GetELSSound() and (hitleft or hitright)
            and self.TraceLength * self.Trace.Fraction / boundradius > 1) then
                self.StopByTrace = CurTime() + .1
            end
        end
    end

    if CurTime() > self.IsGivingWay then
        if hitleft and not hitright then
            self.WaypointOffset = -boundradius
        elseif hitright and not hitleft then
            self.WaypointOffset = boundradius
        else
            self.WaypointOffset = 0
        end
    end

    hook.Run("Decent Vehicle: Trace", self, ent)
end

function ENT:DoGiveWay()
    if not self.Preference.GiveWay then return end
    if CurTime() < self.IsGivingWay then return end
    if CurTime() < self.NextGiveWay then return end
    self.NextGiveWay = CurTime() + (self.Interval.GiveWay or Interval.GiveWay)
    self.MaxSpeedCoefficient = 1
    for k, ent in pairs(CorrectFindInSphere(self:GetPos(), DetectionRangeELS:GetInt())) do
        if not ent:IsVehicle() then continue end
        if ent == self.v then continue end
        if self:GetVehicleForward(ent):Dot(dvd.GetDir(ent:WorldSpaceCenter(), self.v:WorldSpaceCenter())) < -.7 then continue end
        if not self:GetELSSound(ent) then continue end

        local left = IsObstacle(self.TraceLeft)
        local right = IsObstacle(self.TraceRight)
        local time = self.Preference.GiveWayTime or GiveWayTime
        if (dvd.DriveSide == dvd.DRIVESIDE_LEFT or right) and not left then
            self.IsGivingWay = CurTime() + time
            self.WaypointOffset = self.v:BoundingRadius() / 3
            self.MaxSpeedCoefficient = .5
        elseif (dvd.DriveSide == dvd.DRIVESIDE_RIGHT or left) and not right then
            self.IsGivingWay = CurTime() + time
            self.WaypointOffset = -self.v:BoundingRadius() / 3
            self.MaxSpeedCoefficient = .5
        end

        return
    end
end

function ENT:FindFirstWaypoint()
    if self.Waypoint then return end
    if #self.WaypointList > 0 then
        self.Waypoint = table.remove(self.WaypointList)
        self.NextWaypoint = table.remove(self.WaypointList)
        return
    end

    local pos = self.v:GetPos()
    self.Waypoint = dvd.GetNearestWaypoint(pos,
    function(testID, currentID, mindistance)
        local w = dvd.Waypoints[testID]
        return dvd.WaypointAvailable(testID, self.Group)
        and dvd.GetDir(pos, w.Target):Dot(self:GetVehicleForward()) > 0
    end)

    if not self.Waypoint then return end

    self.NextWaypoint = dvd.GetRandomNeighbor(self.Waypoint, function(...) return FilterUTurnAndGroup(self, ...) end)
    if not self.NextWaypoint and self.Waypoint.Target:Distance(pos) < self.v:BoundingRadius() then
        self.Waypoint = nil
    end
end

function ENT:SetupNextWaypoint()
    if self.Preference.WaitUntilNext then
        self.WaitUntilNext = CurTime() + (self.Waypoint.WaitUntilNext or 0)
    end

    if self.NextWaypoint and self.NextWaypoint.UseTurnLights then
        local prevpos = self.v:WorldSpaceCenter()
        if self.PrevWaypoint then prevpos = self.PrevWaypoint.Target end
        self.UseLeftTurnLight = (self.Waypoint.Target - prevpos):Cross(
        self.NextWaypoint.Target - self.Waypoint.Target):Dot(self:GetVehicleUp()) > 0
    end

    self.PrevWaypoint, self.Waypoint = self.Waypoint, self.NextWaypoint
    if not self.Waypoint then return end
    self.NextWaypoint = table.remove(self.WaypointList) or
    dvd.GetRandomNeighbor(self.Waypoint, function(...) return FilterUTurnAndGroup(self, ...) end)

    self.Prependicular = 0
    if self.NextWaypoint and self.PrevWaypoint then
        self.Prependicular = 1 - dvd.GetAng3(self.PrevWaypoint.Target, self.Waypoint.Target, self.NextWaypoint.Target)
    end
end

function ENT:Think()
    if not self:IsValidVehicle() then SafeRemoveEntity(self) return end
    if self:ShouldStop() then
        self:StopDriving()
        self:FindFirstWaypoint()
    elseif self:DriveToWaypoint() then -- When it arrives at the current waypoint.
        hook.Run("Decent Vehicle: OnReachedWaypoint", self)
        if self.Waypoint.FuelStation then self:Refuel() end

        self:SetupNextWaypoint()
    elseif self:ShouldRefuel() then
        if ShouldGoToRefuel:GetBool() then
            self:FindRoute "FuelStation"
        else
            self:Refuel()
        end
    end

    self:DoGiveWay()
    self:DoTrace()
    self:DoLights()
    self:NextThink(CurTime())
    self:SetDriverPosition()
    return true
end

function ENT:Initialize()
    -- Pick up a vehicle in the given sphere.
    local mindistance, vehicle = math.huge, nil ---@type number, dv.Vehicle
    for k, v in pairs(CorrectFindInSphere(self:GetPos(), DetectionRange:GetFloat())) do
        if not v:IsVehicle() then continue end
        if IsValid(v:GetParent()) and v:GetParent():IsVehicle() then continue end
        local d = self:GetPos():DistToSqr(v:GetPos())
        if d > mindistance then continue end
        ---@cast v dv.Vehicle
        mindistance, vehicle = d, v
    end

    if not IsValid(vehicle) or self:GetLocked(vehicle) then
        SafeRemoveEntity(self)
        return
    end

    if vehicle.DecentVehicle then
        SafeRemoveEntity(self)
        SafeRemoveEntity(vehicle.DecentVehicle)
        vehicle.DecentVehicle = nil
        return
    end

    self:InitializeVehicle(vehicle)
    if not IsValid(self.v) then SafeRemoveEntity(self) return end

    local e = EffectData()
    e:SetEntity(self.v)
    if not self.DontUseSpawnEffect then
        util.Effect("propspawn", e) -- Perform a spawn effect.
    end
    self:AttachModel()
    self:DrawShadow(false)
    self:GetVehicleParams()
    self:PhysicsInitShadow()
    self:SetEngineStarted(true)
    self.v:DeleteOnRemove(self)
    self.WaypointList = {}
    ---@diagnostic disable: missing-fields
    self.Trace = {}
    self.TraceBack = {}
    self.TraceWaypoint = {}
    self.TraceLeft = {}
    self.TraceRight = {}
    self.TraceNextWaypoint = {}
    ---@diagnostic enable: missing-fields

    self.Preference = table.Copy(self.Preference)
    if self.Preference.LockVehicleDependsOnCVar then
        self.Preference.LockVehicle = LockVehicle:GetBool()
    end

    if self.Preference.StopInfrontofPersonDependsOnCVar then
        self.Preference.StopInfrontofPerson = StopInfrontofPerson:GetBool()
    end

    if self.Preference.LockVehicle then
        self:SetLocked(true)
    end

    if Photon and istable(self.v.VehicleTable) and self.v.VehicleTable.Photon then
        self.v.PhotonUnitIDRequestTime = math.huge
        if isfunction(self.v.IsBraking) then
            self.OldPhotonIsBraking = self.v.IsBraking
            self.v.IsBraking = self.IsBraking
        end

        if isfunction(self.v.IsReversing) then
            self.OldPhotonIsReversing = self.v.IsReversing
            self.v.IsReversing = self.IsReversing
        end
    end
end

function ENT:OnRemove()
    local v = self.v
    if not IsValid(v) then return end
    v:DontDeleteOnRemove(self)
    v.DecentVehicle = nil
    self:SetHandbrake(false)
    self:SetSteering(0)
    self:SetThrottle(0)
    self:SetRunningLights(false)
    self:SetFogLights(false)
    self:SetLights(false, false)
    self:SetLights(false, true)
    self:SetHazardLights(false)
    self:SetTurnLight(false, false)
    self:SetTurnLight(false, true)
    self:SetELS(false)
    self:SetELSSound(false)
    self:SetHorn(false)
    self:SetEngineStarted(false)
    self:SetLocked(false)
    self:OnRemoveVehicle()

    if Photon and istable(v.VehicleTable) and v.VehicleTable.Photon then
        v.PhotonUnitIDRequestTime = nil
        v.IsBraking = self.OldPhotonIsBraking
        v.IsReversing = self.OldPhotonIsReversing
    end

    local e = EffectData()
    e:SetEntity(v)
    if not self.DontUseSpawnEffect then
        util.Effect("propspawn", e) -- Perform a spawn effect.
    end
end
