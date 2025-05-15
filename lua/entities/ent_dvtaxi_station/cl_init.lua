
local ENT = ENT ---@class ENT.TaxiStation
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
