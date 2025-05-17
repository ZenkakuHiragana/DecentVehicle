
-- Copyright © 2018-2030 Decent Vehicle
-- written by ∩(≡＾ω＾≡)∩ (https://steamcommunity.com/id/greatzenkakuman/)
-- and DangerKiddy(DK) (https://steamcommunity.com/profiles/76561198132964487/).

---Decent Vehicle Injection
---@class Entity
---@field DecentVehicle ENT.DecentVehicle?
---@field GetViewPunchAngles fun(self: Entity): Angle
---@field InVehicle          fun(self: Entity): boolean
---@field KeyDown            fun(self: Entity, key: Enum.IN): boolean
---@field SetViewPunchAngles fun(self: Entity, value: Angle)

---VCMod Injection
---@class Vehicle
---@field VC_fuelGet           (fun(self: Vehicle, showInPercent: boolean): number)?
---@field VC_fuelGetMax        (fun(self: Vehicle): number)?
---@field VC_fuelSet           (fun(self: Vehicle, value: number))?
---@field VC_getELSLightsOn    (fun(self: Vehicle): boolean)?
---@field VC_getELSSoundOn     (fun(self: Vehicle): boolean)?
---@field VC_getHealth         (fun(self: Vehicle, showInPercent: boolean): number)?
---@field VC_getStates         (fun(self: Vehicle): table)?
---@field VC_isLocked          (fun(self: Vehicle): boolean)?
---@field VC_lock              (fun(self: Vehicle))?
---@field VC_setELSLights      (fun(self: Vehicle, value: boolean))?
---@field VC_setELSLightsCycle (fun(self: Vehicle))?
---@field VC_setELSSound       (fun(self: Vehicle, value: boolean))?
---@field VC_setFogLights      (fun(self: Vehicle, value: boolean))?
---@field VC_setHazardLights   (fun(self: Vehicle, value: boolean))?
---@field VC_setHighBeams      (fun(self: Vehicle, value: boolean))?
---@field VC_setLowBeams       (fun(self: Vehicle, value: boolean))?
---@field VC_setRunningLights  (fun(self: Vehicle, value: boolean))?
---@field VC_setStates         (fun(self: Vehicle, value: table))?
---@field VC_setTurnLightLeft  (fun(self: Vehicle, value: boolean))?
---@field VC_setTurnLightRight (fun(self: Vehicle, value: boolean))?
---@field VC_unLock            (fun(self: Vehicle))?
---@field ELSCycleChanged      boolean?

---Photon 1 Injection
---@class Vehicle
---@field CAR_Hazards     (fun(self: Vehicle, arg: any?): boolean)?
---@field CAR_StopSignals (fun(self: Vehicle))?
---@field CAR_TurnLeft    (fun(self: Vehicle, state: boolean?): boolean)?
---@field CAR_TurnRight   (fun(self: Vehicle, state: boolean?): boolean)?
---@field ELS_Horn        (fun(self: Vehicle, state: boolean?))?
---@field ELS_Illuminate  (fun(self: Vehicle, arg: any?): boolean)?
---@field ELS_IllumOff    (fun(self: Vehicle))?
---@field ELS_IllumOn     (fun(self: Vehicle))?
---@field ELS_Lights      (fun(self: Vehicle, arg: any?): boolean)?
---@field ELS_LightsOff   (fun(self: Vehicle))?
---@field ELS_Siren       (fun(self: Vehicle, arg: any?): boolean)?
---@field ELS_SirenOff    (fun(self: Vehicle))?
---@field ELS_SirenOn     (fun(self: Vehicle))?
---@field IsEMV           (fun(self: Vehicle): boolean)?
---@field IsBraking       (fun(self: Vehicle): boolean)?
---@field IsReversing     (fun(self: Vehicle): boolean)?
---@field PhotonUnitIDRequestTime number?
---@field VehicleTable   { Photon: boolean?, Name: string? }?

---Photon 2 Injection
---@class Vehicle
---@field GetPhotonControllerFromAncestor (fun(self: Vehicle): PhotonController?)?

---@class PhotonController : Entity
---@field GetChannelMode fun(self: PhotonController, channel: string): string
---@field SetChannelMode fun(self: PhotonController, channel: string, mode: string)

---SCAR Injection
---@class Player
---@field ScarSpecialKeyInput table<string, integer>
---@class Vehicle
---@field IsScarSeat boolean

---Sligwolf's Vehicles Injection
---@class Vehicle
---@field __SW_Vars table

---DarkRP Injection
---@class Player
---@field DarkRPVars { money: number }
---@field setDarkRPVar fun(self: Player, key: string, value: number)

---Type annotation for SCAR base
---@class dv.SCAR : Entity
---@field IsScar                boolean
---@field Acceleration          number
---@field AIController          Entity
---@field BreakForce            number
---@field CarMass               number
---@field DriveStatus           integer
---@field EntOwner              Entity
---@field Horn                  CSoundPatch
---@field IncreaseFrontLightCol boolean
---@field IsOn                  boolean
---@field MaxSpeed              number
---@field MaxSteerForce         number
---@field ReverseForce          number
---@field ReverseMaxSpeed       number
---@field Seats                 Entity[]
---@field SirenIsOn             boolean
---@field SirenSound            CSoundPatch?
---@field SpecialThink          function
---@field StabilizerProp        Entity[]
---@field Wheels                Entity[]
---@field WheelTorqTraction     number
---@field GetFuelPercent        fun(self: dv.SCAR): number
---@field GoBack                fun(self: dv.SCAR, throttle: number)
---@field GoForward             fun(self: dv.SCAR, throttle: number)
---@field GoNeutral             fun(self: dv.SCAR)
---@field HandBrakeOff          fun(self: dv.SCAR)
---@field HandBrakeOn           fun(self: dv.SCAR)
---@field HasDriver             fun(self: dv.SCAR): boolean
---@field HasFuel               fun(self: dv.SCAR): boolean
---@field HornOff               fun(self: dv.SCAR)
---@field HornOn                fun(self: dv.SCAR)
---@field IsDestroyed           fun(self: dv.SCAR): boolean
---@field IsLocked              fun(self: dv.SCAR): boolean
---@field Lock                  fun(self: dv.SCAR)
---@field NotTurning            fun(self: dv.SCAR)
---@field Refuel                fun(self: dv.SCAR)
---@field TurnLeft              fun(self: dv.SCAR, steer: number)
---@field TurnOffCar            fun(self: dv.SCAR)
---@field TurnRight             fun(self: dv.SCAR, steer: number)
---@field UnLock                fun(self: dv.SCAR)
---@field UpdateLights          fun(self: dv.SCAR, ...)

---Type annotation for Simfphys base
---@class dv.Simfphys : Vehicle
---@field IsSimfphyscar       boolean
---@field Brake               number
---@field CustomWheels        boolean
---@field DriverSeat          Entity
---@field Efficiency          number
---@field ems                 CSoundPatch
---@field emson               boolean
---@field ForwardSpeed        number
---@field Gears               number[]
---@field HornKeyIsDown       boolean
---@field KeyPressedTime      number
---@field LampsActivated      boolean
---@field LightsActivated     boolean
---@field Mass                number
---@field MaxGrip             number
---@field PeakTorque          number
---@field PressedKeys         table<string, boolean>
---@field RemoteDriver        Entity
---@field VehicleData         { steerangle: number, filter: Entity[], LocalAngForward: Angle }
---@field VehicleLocked       boolean
---@field Wheels              Entity[]
---@field EngineActive        fun(self: dv.Simfphys): boolean
---@field GetBrakePower       fun(self: dv.Simfphys): number
---@field GetCurHealth        fun(self: dv.Simfphys): number
---@field GetEMSEnabled       fun(self: dv.Simfphys): boolean
---@field GetFuel             fun(self: dv.Simfphys): number
---@field GetMaxFuel          fun(self: dv.Simfphys): number
---@field GetMaxTorque        fun(self: dv.Simfphys): number
---@field GetVehicleSteer     fun(self: dv.Simfphys): number
---@field IsInitialized       fun(self: dv.Simfphys): boolean
---@field Lock                fun(self: dv.Simfphys)
---@field PlayerSteerVehicle  fun(self: dv.Simfphys, ply: Player, left: number, right: number)
---@field SetActive           fun(self: dv.Simfphys, value: boolean)
---@field SetFogLightsEnabled fun(self: dv.Simfphys, value: boolean)
---@field SetFuel             fun(self: dv.Simfphys, value: number)
---@field StartEngine         fun(self: dv.Simfphys)
---@field StopEngine          fun(self: dv.Simfphys)
---@field UnLock              fun(self: dv.Simfphys)
---@field PhysicsCollide      function Overriden by Decent Vehicle

---@alias dv.Vehicle
---| Vehicle
---| dv.SCAR
---| dv.Simfphys

---@class ENT.DecentVehicle : Structure.ENT, Entity, ENTITY
---@field Group             integer
---@field Model             string|string[]?
---@field OldSpecialThink   function
---@field RealFindInSphere  function?
---@field Trace             Structure.TraceResult
---@field TraceBack         Structure.TraceResult
---@field TraceLeft         Structure.TraceResult
---@field TraceNextWaypoint Structure.TraceResult
---@field TraceRight        Structure.TraceResult
---@field TraceWaypoint     Structure.TraceResult
---@field v                 dv.Vehicle
local ENT = ENT
local dvd = DecentVehicleDestination
ENT.Base = "base_entity"
ENT.Type = "anim"
ENT.PrintName = dvd.Texts.npc_decentvehicle
ENT.Author = "GreatZenkakuMan"
ENT.Contact = ""
ENT.Purpose = ""
ENT.Instructions = ""
ENT.Spawnable = false

list.Set("NPC", "npc_decentvehicle", {
    Name = ENT.PrintName,
    Class = "npc_decentvehicle",
    Category = "GreatZenkakuMan's NPCs",
})

function ENT:SetDriverPosition()
    local seat = self:GetNWEntity "Seat"
    if not IsValid(seat) then return end
    local pos = seat:LocalToWorld(self:GetNWVector "Pos")
    self:SetPos(pos)
    self:SetNetworkOrigin(pos)
    self:SetAngles(seat:LocalToWorldAngles(self:GetNWAngle "Ang"))
end

function ENT:GetDrivingEntity()
    local vehicle = self:GetNWEntity "Vehicle"
    if not (IsValid(vehicle) and vehicle:IsVehicle()) then return vehicle end
end

function ENT:GetVehicleForward(v)
    local vehicle = v or self:GetNWEntity "Vehicle"
    if not (IsValid(vehicle) and vehicle:IsVehicle()) then return self:GetForward() end
    if vehicle.IsScar then
        return vehicle:GetForward()
    elseif vehicle.IsSimfphyscar then
        return vehicle:LocalToWorldAngles(vehicle.VehicleData.LocalAngForward or angle_zero):Forward()
    else
        return vehicle:GetForward()
    end
end

function ENT:GetVehicleRight(v)
    local vehicle = v or self:GetNWEntity "Vehicle"
    if not (IsValid(vehicle) and vehicle:IsVehicle()) then return self:GetRight() end
    if vehicle.IsScar then
        return vehicle:GetRight()
    elseif vehicle.IsSimfphyscar then
        return vehicle:LocalToWorldAngles(vehicle.VehicleData.LocalAngForward or angle_zero):Right()
    else
        return vehicle:GetRight()
    end
end

function ENT:GetVehicleUp(v)
    local vehicle = v or self:GetNWEntity "Vehicle"
    if not (IsValid(vehicle) and vehicle:IsVehicle()) then return self:GetUp() end
    if vehicle.IsScar then
        return vehicle:GetUp()
    elseif vehicle.IsSimfphyscar then
        return vehicle:LocalToWorldAngles(vehicle.VehicleData.LocalAngForward or angle_zero):Up()
    else
        return vehicle:GetUp()
    end
end
