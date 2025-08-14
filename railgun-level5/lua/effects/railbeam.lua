if SERVER then
    AddCSLuaFile()
end

EFFECT.Mat = Material("effects/tracer_middle")
EFFECT.HelixMat = Material("sprites/tp_beam001")
EFFECT.Refract = Material("particle/particle_glow_03_additive")
EFFECT.Particles = Material("sprites/magic")

-- Precache all smoke materials once
EFFECT.SmokeMats = {}
for i = 1, 16 do
    local id = (i < 10 and "0" .. i or i)
    EFFECT.SmokeMats[i] = Material("particle/smokesprites_00" .. id)
end

EFFECT.MaxLife = 2
if CLIENT and not PEmitterRockets then
    PEmitterRockets = ParticleEmitter(Vector(0, 0, 0))
end

function EFFECT:Init(data)
    self.StartPos = data:GetStart()
    self.EndPos = data:GetOrigin()
    self.Angles = data:GetAngles()
    self.Scale = data:GetScale()
    self.LifeTime = CurTime() + self.MaxLife

    -- Position & orientation
    local norm = (self.EndPos - self.StartPos)
    self.Entity:SetAngles(norm:Angle())
    self.Entity:SetPos(self.EndPos - norm / 2)

    -- Play sounds (spread slightly to avoid overlap distortion)
    local soundDelays = {
        { snd = "ambient/energy/weld1.wav", delay = 0 },
        { snd = "ambient/explosions/citadel_end_explosion2.wav", delay = 0.05 },
        { snd = "ambient/explosions/explode_6.wav", delay = 0.1 },
        { snd = "ambient/energy/weld2.wav", delay = 0.15 },
    }
    for _, s in ipairs(soundDelays) do
        timer.Simple(s.delay, function()
            if IsValid(self) then
                sound.Play(s.snd, self.StartPos, 100, 220)
            end
        end)
    end

    -- Fewer particles, more random spread
    local particleCount = 50 -- was 150
    for i = 1, particleCount do
        local mat = self.SmokeMats[math.random(#self.SmokeMats)]
        local part = PEmitterRockets:Add(
            mat,
            self.EndPos
                - self.Entity:GetForward() * math.random(200, 700)
                + VectorRand() * math.random(1, 200)
        )
        if part then
            part:SetColor(155, 155, 155)
            part:SetVelocity(
                VectorRand() * math.random(10, 50)
                    + self.Entity:GetForward() * math.random(500, 1000)
            )
            part:SetDieTime(3) -- shorter lifetime
            part:SetStartSize(math.random(40, 80)) -- slightly smaller
            part:SetEndSize(0)
            part:SetStartAlpha(150)
            part:SetEndAlpha(0)
        end
    end
end

function EFFECT:Think()
    return CurTime() <= self.LifeTime
end

function EFFECT:Render()
    local StartPos, EndPos = self.StartPos, self.EndPos
    local Ang = (EndPos - StartPos):GetNormal():Angle()
    local Forward, Right, Up = Ang:Forward(), Ang:Right(), Ang:Up()
    local Distance = StartPos:Distance(EndPos)
    local StepSize = 4
    local fadeOut = ((self.LifeTime - CurTime()) / self.MaxLife + 0.5) ^ 2
    local RingRadius = self.Scale * 0.35
    local RingTightness = 18
    local mainColor = Color(240, 250, 255, 255)
    local outlineColor = Color(120, 180, 255, 60 * fadeOut)
    local helixColor = Color(180, 220, 255, 220)
    local sparkColor = Color(200, 240, 255, 220)
    local glowColor1 = Color(200, 240, 255, 255 * fadeOut)
    local glowColor2 = Color(120, 180, 255, 120 * fadeOut)
    local flashColor = Color(255, 255, 255, 255 * math.min(1, fadeOut * 2))

    -- Very bright flash at the start point
    render.SetMaterial(self.Refract)
    render.DrawSprite(StartPos, 120 * fadeOut, 120 * fadeOut, flashColor)

    -- Glow sprites (smaller, more focused)
    render.DrawSprite(EndPos + Forward, 32 * fadeOut, 32 * fadeOut, glowColor1)
    render.DrawSprite((StartPos + EndPos) / 2, 36 * fadeOut, 36 * fadeOut, glowColor2)

    -- Thin, bright outline
    render.SetMaterial(self.Mat)
    render.DrawBeam(StartPos, EndPos, 2.5 * RingRadius * fadeOut, 0, 0, outlineColor)

    -- Fast, tight helix
    render.SetMaterial(self.HelixMat)
    local LastPos
    local radMult = math.rad(RingTightness * fadeOut * 2)
    for i = 1, Distance, StepSize do
        local sin, cos = math.sin(i * radMult), math.cos(i * radMult)
        local Pos = StartPos
            + Forward * i
            + Up * sin * RingRadius * fadeOut
            + Right * cos * RingRadius * fadeOut
        if LastPos then
            render.DrawBeam(LastPos, Pos, 1.2 * fadeOut * RingRadius, 0, 0, helixColor)
        end
        LastPos = Pos
    end

    -- Main beam (extremely thin, very bright)
    render.SetMaterial(self.Mat)
    render.DrawBeam(StartPos, EndPos, 1.1 * RingRadius * fadeOut, 0, 0, mainColor)

    -- Long, bright electric sparks/arcs in segments
    render.SetMaterial(self.Mat)
    for i = 1, 10 do
        local t = math.Rand(0.05, 0.95)
        local base = LerpVector(t, StartPos, EndPos)
        local arcDir = (Right * math.Rand(-1, 1) + Up * math.Rand(-1, 1)):GetNormalized()
        local arcLen = math.Rand(24, 48)
        local arcEnd = base + arcDir * arcLen
        -- Segmented sparks
        local segs = math.random(2, 4)
        local prev = base
        for s = 1, segs do
            local segT = s / segs
            local segPos = LerpVector(segT, base, arcEnd) + VectorRand() * 2
            render.DrawBeam(prev, segPos, math.Rand(0.7, 1.2), 0, 1, sparkColor)
            prev = segPos
        end
    end
end
