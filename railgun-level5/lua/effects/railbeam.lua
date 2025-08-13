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
    local StepSize = 10
    local fadeOut = ((self.LifeTime - CurTime()) / self.MaxLife + 0.5) ^ 2
    local RingRadius = self.Scale
    local RingTightness = 5

    -- Glow sprites
    render.SetMaterial(self.Refract)
    render.DrawSprite(
        EndPos + Forward,
        56 * fadeOut,
        56 * fadeOut,
        Color(255, 255, 255, 255 * fadeOut)
    )
    render.DrawSprite(StartPos, 128 * fadeOut, 128 * fadeOut, Color(255, 255, 255, 255 * fadeOut))

    -- Helix
    render.SetMaterial(self.HelixMat)
    local LastPos
    local radMult = math.rad(RingTightness * fadeOut)
    for i = 1, Distance, StepSize do
        local sin, cos = math.sin(i * radMult), math.cos(i * radMult)
        local Pos = StartPos
            + Forward * i
            + Up * sin * RingRadius * fadeOut
            + Right * cos * RingRadius * fadeOut
        if LastPos then
            render.DrawBeam(LastPos, Pos, 3 * fadeOut * RingRadius, 0, 0, Color(155, 155, 255, 255))
        end
        LastPos = Pos
    end

    -- Main beam
    render.SetMaterial(self.Mat)
    render.DrawBeam(StartPos, EndPos, 4 * RingRadius * fadeOut, 0, 0, Color(155, 155, 255, 255))
end
