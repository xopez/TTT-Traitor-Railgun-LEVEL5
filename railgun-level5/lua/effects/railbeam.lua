if SERVER then
    AddCSLuaFile()
end
EFFECT.Mat = Material("effects/tracer_middle")
EFFECT.HelixMat = Material("sprites/tp_beam001")
EFFECT.Refract = Material("particle/particle_glow_03_additive")
EFFECT.MaxLife = 2
if CLIENT and not PEmitterRockets then
    PEmitterRockets = ParticleEmitter(Vector(0, 0, 0))
end

local sounds_start = {
    { "ambient/energy/weld1.wav", 100, 220 },
    { "ambient/explosions/citadel_end_explosion2.wav", 240, 220 },
    { "ambient/explosions/explode_6.wav", 140, 220 },
    { "ambient/energy/weld2.wav", 240, 220 },
}
local sounds_end = {
    { "ambient/explosions/citadel_end_explosion2.wav", 180, 220 },
    { "ambient/explosions/explode_6.wav", 70, 220 },
    { "ambient/energy/weld2.wav", 90, 220 },
}

function EFFECT:Init(data)
    self.StartPos = data:GetStart()
    self.EndPos = data:GetOrigin()
    self.Angles = data:GetAngles()
    self.Scale = data:GetScale()
    self.LifeTime = CurTime() + self.MaxLife

    local norm = self.EndPos - self.StartPos
    local ang = norm:Angle()
    self.Entity:SetAngles(ang)
    self.Entity:SetPos(self.EndPos - norm / 2)

    for _, snd in ipairs(sounds_start) do
        sound.Play(snd[1], self.StartPos, snd[2], snd[3])
    end
    for _, snd in ipairs(sounds_end) do
        sound.Play(snd[1], self.EndPos, snd[2], snd[3])
    end

    for i = 1, 150 do
        local rand = math.random(1, 16)
        local dustMat = Material("particle/smokesprites_00" .. string.format("%02d", rand))
        local part = PEmitterRockets:Add(
            dustMat,
            self.EndPos
                - self.Entity:GetForward() * math.random(200, 700)
                + VectorRand() * math.random(1, 200)
        )
        if part then
            part:SetColor(155, 155, 155)
            part:SetVelocity(
                Vector(math.random(-20, 20), math.random(-20, 20), math.random(-20, -50))
                    + self.Entity:GetForward() * math.random(500, 1000)
            )
            part:SetDieTime(5)
            part:SetStartSize(math.random(50, 100))
            part:SetEndSize(math.random(0, 30))
            part:SetAngles(Angle(30, 0, 0))
            part:SetRollDelta(math.Rand(-0.5, 0.5))
            part:SetStartAlpha(150)
            part:SetEndAlpha(0)
            part:SetBounce(0.5)
        end
    end
end

function EFFECT:Think()
    if CurTime() > self.LifeTime then
        return false
    end
    return true
end

function EFFECT:Render()
    local StartPos = self.StartPos
    local EndPos = self.EndPos
    local Ang = (EndPos - StartPos):GetNormal():Angle()
    local Forward = Ang:Forward()
    local Right = Ang:Right()
    local Up = Ang:Up()
    local Distance = StartPos:Distance(EndPos)
    local StepSize = 10
    local LastPos
    local fadeOut = ((self.LifeTime - CurTime()) / self.MaxLife + 0.5) ^ 2
    local RingTightness = 5
    local RingRadius = self.Scale

    render.SetMaterial(self.Refract)
    render.DrawSprite(
        EndPos + (EndPos - StartPos):GetNormal(),
        56 * fadeOut,
        56 * fadeOut,
        Color(255, 255, 255, math.Clamp(255 * fadeOut, 0, 255))
    )
    render.DrawSprite(
        StartPos,
        128 * fadeOut,
        128 * fadeOut,
        Color(255, 255, 255, math.Clamp(255 * fadeOut, 0, 255))
    )

    for i = 1, Distance, StepSize do
        local sin = math.sin(math.rad(i * RingTightness * fadeOut))
        local cos = math.cos(math.rad(i * RingTightness * fadeOut))
        local Pos = StartPos
            + (Forward * i)
            + (Up * sin * RingRadius * fadeOut)
            + (Right * cos * RingRadius * fadeOut)

        if LastPos ~= nil then
            render.SetMaterial(self.HelixMat)
            render.DrawBeam(
                LastPos,
                Pos,
                3 * fadeOut * RingRadius,
                0,
                math.sin(CurTime() * 15) * 5,
                Color(155, 155, 255, 255)
            )
        end
    end

    render.SetMaterial(self.Mat)
    render.DrawBeam(
        StartPos,
        EndPos,
        4 * RingRadius * fadeOut,
        0,
        0.3 * fadeOut,
        Color(155, 155, 255, 255)
    )

    render.SetMaterial(self.HelixMat)
    render.DrawBeam(
        StartPos,
        EndPos,
        5 * RingRadius * fadeOut,
        0,
        fadeOut,
        Color(155, 155, 255, 255)
    )

    local Last = nil
    local ang = self.Entity:GetForward():Angle()
    for i = 0, 360, 10 do
        local vec = math.sin(math.rad(i))
                * self.Scale
                * math.random(9, 11)
                * (2 - fadeOut)
                * ang:Up()
            + math.cos(math.rad(i)) * self.Scale * math.random(9, 11) * (2 - fadeOut) * ang:Right()
            + self.EndPos
            - ang:Forward() * 100
        if Last ~= nil then
            render.DrawBeam(
                vec,
                Last,
                5 * RingRadius * fadeOut,
                -fadeOut * 0.5,
                fadeOut * 0.5,
                Color(155, 155, 255, 150 * fadeOut)
            )
        end
        Last = vec
    end
end
