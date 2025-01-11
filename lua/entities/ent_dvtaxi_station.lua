
-- Copyright © 2018-2030 Decent Vehicle
-- written by ∩(≡＾ω＾≡)∩ (https://steamcommunity.com/id/greatzenkakuman/)
-- and DangerKiddy(DK) (https://steamcommunity.com/profiles/76561198132964487/).

AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Taxi station"
ENT.Author = "DangerKiddy(DK)"
ENT.Category = "Decent Vehicle"
ENT.Spawnable = true
ENT.Editable = true
ENT.IsDVTaxiStation = true

local dvd = DecentVehicleDestination
function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "StationName", {
        KeyName = "stationname",
        Edit = {type = "Name", order = 4}
    })
end

if CLIENT then
    ENT.TextWidth = 0
    ENT.TextPosition = 75
    ENT.LastTimeScrollChanged = CurTime()
    local CAM_SCALE = 1 / 8
    local MAX_WIDTH = 24 / CAM_SCALE
    local SCROLL_PIXELS_PER_SECOND = 75
    local MAX_DISTANCE = 2000^2
    function ENT:Draw()
        self:DrawModel()
        if self:GetForward():Dot(EyePos() - self:WorldSpaceCenter()) > 0 then return end
        if EyePos():DistToSqr(self:WorldSpaceCenter()) > MAX_DISTANCE then return end

        -- Set up text position
        local origin = self:LocalToWorld(Vector(-1.0, 12.0, 36.5))
        local cliporigin = origin + self:GetRight() * 24
        local angles = self:GetAngles()
        local x = math.Clamp(self.TextPosition, MAX_WIDTH - self.TextWidth, 0)
        angles:RotateAroundAxis(self:GetUp(), -90)
        angles:RotateAroundAxis(self:GetRight(), 90)

        -- Make sure to draw the text on the model
        render.PushCustomClipPlane(self:GetRight(), self:GetRight():Dot(origin))
        render.PushCustomClipPlane(-self:GetRight(), -self:GetRight():Dot(cliporigin))

        -- Draw station name
        cam.Start3D2D(origin, angles, CAM_SCALE)
        local width, _ = draw.SimpleText(self:GetStationName(), "DermaLarge", x, 0)
        cam.End3D2D()

        -- Back to normal state
        render.PopCustomClipPlane()
        render.PopCustomClipPlane()

        -- Scroll the text if it's too long
        self.TextWidth = width
        self.TextPosition = self.TextPosition - RealFrameTime() * SCROLL_PIXELS_PER_SECOND

        -- Reset scroll position if the name fits in the model or it finished scrolling
        if width < MAX_WIDTH or self.TextPosition < MAX_WIDTH - width - SCROLL_PIXELS_PER_SECOND then
            self.TextPosition = SCROLL_PIXELS_PER_SECOND
        end
    end

    return
end

-- creikey/top-1000-nouns.txt - GitHub Gist
local NounsURL = "https://gist.githubusercontent.com/creikey/"
              .. "42d23d1eec6d764e8a1d9fe7e56915c6/raw/"
              .. "b07de0068850166378bc3b008f9b655ef169d354/top-1000-nouns.txt"
-- hugsy/english-adjectives.txt - GitHub Gist
local AdjectivesURL = "https://gist.githubusercontent.com/hugsy/"
              .. "8910dc78d208e40de42deb29e62df913/raw/"
              .. "eec99c5597a73f6a9240cab26965a8609fa0f6ea/english-adjectives.txt"
local nouns = {
    "party", "information", "school", "fact", "money", "point", "example",
    "state", "business", "night", "area", "water", "thing", "family", "head",
    "hand", "order", "john", "side", "home", "development", "week", "power",
    "country", "council", "use", "service", "room", "market", "problem",
}
-- List of adjectives - PaperRater
-- https://www.paperrater.com/page/lists-of-adjectives
local adjectives = {
    "attractive", "bald", "beautiful", "chubby", "clean", "dazzling",
    "drab", "elegant", "fancy", "fit", "flabby", "glamorous", "gorgeous",
    "handsome", "long", "magnificent", "muscular", "plain", "plump",
    "quaint", "shapely", "short", "skinny", "stocky", "ugly",

    "ashy", "black", "blue", "gray", "green", "icy", "lemon", "mango",
    "orange", "purple", "red", "salmon", "white", "yellow",

    "alive", "better", "careful", "clever", "easy", "famous", "gifted",
    "hallowed", "helpful", "important", "inexpensive", "mealy",
    "mushy", "powerful", "shy", "tender", "vast",
}
-- Fetch more words if available
http.Fetch(NounsURL, function(body, _, _, _)
    nouns = body:Trim():Split "\n"
end)
http.Fetch(AdjectivesURL, function(body, _, _, _)
    adjectives = body:Trim():Split "\n"
end)

local function GetRandomName()
    return string.format("%s-%s",
        adjectives[math.random(#adjectives)],
        nouns[math.random(#nouns)])
end

function ENT:Initialize()
    self:SetModel "models/decentvehicle/ent_dvtaxi_station.mdl"

    self:PhysicsInitShadow()
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self:DrawShadow(false)
    dvd.TaxiStations[self] = true
end

function ENT:OnRemove()
    dvd.TaxiStations[self] = nil
end

function ENT:Use(activator, caller)
    if not caller:IsPlayer() then return end

    net.Start "Decent Vehicle: Open a taxi menu"
    net.WriteEntity(self)
    net.Send(caller)
end

function ENT:SpawnFunction(ply, tr, ClassName)
    if not tr.Hit then return end
    local pos = tr.HitPos + tr.HitNormal
    local ang = dvd.GetDir(tr.StartPos, tr.HitPos):Angle()
    local ent = ents.Create(ClassName)
    ent:SetAngles(Angle(0, ang.yaw, 0))
    ent:SetPos(pos)
    ent:Spawn()
    ent:SetStationName(GetRandomName())

    return ent
end
