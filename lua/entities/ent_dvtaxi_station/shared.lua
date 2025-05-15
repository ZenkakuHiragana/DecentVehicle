
-- Copyright © 2018-2030 Decent Vehicle
-- written by ∩(≡＾ω＾≡)∩ (https://steamcommunity.com/id/greatzenkakuman/)
-- and DangerKiddy(DK) (https://steamcommunity.com/profiles/76561198132964487/).

---@class ENT.TaxiStation : Structure.ENT, Entity, ENTITY
---@field GetStationName fun(self: ENT.TaxiStation): string
---@field SetStationName fun(self: ENT.TaxiStation, value: string)
local ENT = ENT
ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Taxi station"
ENT.Author = "DangerKiddy(DK)"
ENT.Category = "Decent Vehicle"
ENT.Spawnable = true
ENT.Editable = true
ENT.IsDVTaxiStation = true

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "StationName", {
        KeyName = "stationname",
        Edit = {type = "Name", order = 4}
    })
end
