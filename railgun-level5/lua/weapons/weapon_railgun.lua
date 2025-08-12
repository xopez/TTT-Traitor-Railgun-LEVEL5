AddCSLuaFile()

SWEP.Base = "weapon_tttbase"
SWEP.Author = "Rising Darkness"
SWEP.PrintName = "Railgun LEVEL5"
SWEP.ClassName = "Railgun"
SWEP.Spawnable = false
SWEP.AdminSpawnable = true
SWEP.Folder = "weapons/weapon_railgun"
SWEP.CanBuy = { ROLE_TRAITOR }

SWEP.Primary.Reload = Sound("Weapon_Pistol.Reload")
SWEP.Primary.Empty = Sound("Weapon_Pistol.Empty")
SWEP.Primary.Sound = Sound("ambient/machines/catapult_throw.wav")
SWEP.Primary.Delay = 5
SWEP.Primary.DefaultClip = 1
SWEP.Primary.ClipSize = 1
SWEP.Primary.Automatic = false
SWEP.Primary.CoinStart = Sound("weapons/coin/coin_tossstart.mp3")
SWEP.Primary.Coin = Sound("weapons/coin/coin_toss.mp3")
SWEP.Primary.CoinDrop = Sound("ambient/energy/zap9.wav")

SWEP.LimitedStock = true
SWEP.Kind = WEAPON_EQUIP2
SWEP.AllowDrop = true
SWEP.AutoSpawnable = false
SWEP.Icon = "vgui/entities/weapon_railgun"

SWEP.EquipMenuData = {
    type = "Weapon",
    desc = [[Fires a powerful Railgun.]],
}

if CLIENT then
    killicon.Add("weapon_railgun", "VGUI/entities/railkill", Color(255, 255, 255, 255))
end

SWEP.Weight = 5

SWEP.Slot = 9
SWEP.SlotPos = 2
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.Aim = false
SWEP.HoldType = "pistol"
SWEP.ViewModel = "models/weapons/c_coin.mdl"
SWEP.WorldModel = "models/weapons/w_coin.mdl"
SWEP.UseHands = true

-----------------------
function SWEP:PrimaryAttack()
    if not self:CanPrimaryAttack() then
        return
    end
    self.Weapon:EmitSound(self.Primary.CoinStart)
    timer.Simple(1.5, function()
        self.Weapon:EmitSound(self.Primary.Coin)
        self:ThrowCoin()
    end)
    return
end

function SWEP:SecondaryAttack()
    return
end

--------------------
function SWEP:ThrowCoin()
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self.Timer = CurTime() + self.Weapon:SequenceDuration() - 0.15
    return
end

function SWEP:ShouldDropOnDie()
    return false
end

function SWEP:Think()
    if self.Timer < CurTime() and self.Timer ~= 0 then
        self:FireCoin()
        self.Timer = 0
        timer.Simple(1, function()
            if not IsValid(self.Entity) then
                return
            end
            self:SendWeaponAnim(ACT_VM_DRAW)
        end)
    end
end

SWEP.BlockList = {
    ["prop_dynamic"] = true,
    ["prop_ragdoll"] = true,
    ["physgun_beam"] = true,
    ["player_manager"] = true,
    ["predicted_viewmodel"] = true,
    ["bullseye"] = true,
    ["util_buddyfinder"] = true,
    ["manipulate_flex"] = true,
    ["trigger_hurt"] = true,
    ["ambient_generic"] = true,
    ["trigger_teleport"] = true,
    ["info_teleport_destination"] = true,
    ["func_brush"] = true,
    ["info_ladder_dismount"] = true,
    ["env_soundscape_triggerable"] = true,
    ["manipulate_bone"] = true,
    ["gmod_tool"] = true,
    ["gmod_camera"] = true,
}
local ents1
function SWEP:findInLine(trace)
    local ents1 = {}
    local startPos = self.hand.Pos
    local endPos = trace.HitPos
    local dir = (endPos - startPos):GetNormalized()
    local dist = startPos:Distance(endPos)
    for i = 200, dist, 100 do
        local spherePos = startPos - dir * i
        local ents2 = ents.FindInSphere(spherePos, 150)
        if ents2 then
            for _, v in ipairs(ents2) do
                if
                    v ~= self.Owner
                    and not self.BlockList[v:GetClass()]
                    and not string.find(v:GetClass(), "weapon")
                    and not string.find(v:GetClass(), "npc")
                    and not string.find(v:GetClass(), "sword")
                    and not string.find(v:GetClass(), "m9k")
                    and not string.find(v:GetClass(), "info")
                    and not string.find(v:GetClass(), "func")
                    and not string.find(v:GetClass(), "env")
                then
                    if util.DistanceToLine(startPos, endPos, v:GetPos()) <= 200 then
                        table.insert(ents1, v)
                    end
                end
            end
        end
    end
end

function SWEP:DropCoin()
    local coin = ents.Create("prop_physics")
    if not IsValid(coin) then
        return
    end
    coin:SetModel("models/weapons/w_coin.mdl")
    coin:SetPos(self.hand.Pos)
    coin:SetOwner(self.Owner)
    coin:Spawn()
    SafeRemoveEntityDelayed(coin, 5)
    local phys = coin:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetVelocityInstantaneous(self.Owner:GetAimVector() * 500 + Vector(0, 0, 100))
        phys:EnableCollisions(true)
        phys:EnableDrag(true)
    end
end

function SWEP:FireCoin()
    self.Owner:SetAnimation(PLAYER_ATTACK1)
    self.hand = self.Owner:GetAttachment(self.Owner:LookupAttachment("anim_attachment_rh"))
    if self.hand == nil then
        self.hand = self.Owner
        self.hand.Pos = self.Owner:GetPos() + Vector(0, 0, 40)
    end
    local trace = util.TraceLine({
        start = self.hand.Pos,
        endpos = self.hand.Pos + self.Owner:GetAimVector() * 10000,
        filter = function(ent)
            if ent:GetClass() == "123" then
                return true
            end
        end,
    })
    if self.hand.Pos:Distance(trace.HitPos) < 100 then
        self:SetNextPrimaryFire(CurTime() + 5)
        if SERVER then
            self:DropCoin()
        end
        self.Weapon:EmitSound(self.Primary.CoinDrop)
        return
    end
    local effectdata = EffectData()
    effectdata:SetStart(trace.HitPos)
    effectdata:SetOrigin(self.hand.Pos)
    effectdata:SetAngles(self.Owner:GetAimVector():Angle())
    effectdata:SetScale(6)
    util.Effect("railbeam", effectdata)

    if SERVER then
        self:findInLine(trace)
        for i = 50, self.hand.Pos:Distance(trace.HitPos), 60 do
            util.BlastDamage(
                self.Owner,
                self.Owner,
                self.hand.Pos + self.Owner:GetAimVector() * i,
                55,
                60
            )
            util.BlastDamage(
                self.Owner,
                self.Owner,
                self.hand.Pos + self.Owner:GetAimVector() * (i - 10),
                55,
                60
            )
            util.BlastDamage(
                self.Owner,
                self.Owner,
                self.hand.Pos + self.Owner:GetAimVector() * (i + 10),
                55,
                60
            )
        end
    end
    self:TakePrimaryAmmo(1)
end

if CLIENT then
    function SWEP:DrawHUD()
        local x, y = ScrW() / 2.0, ScrH() / 2.0 -- Center of screen
        local gap = 80
        local length = 40
        if self.Timer > CurTime() then
            surface.SetTexture(surface.GetTextureID("particle/particle_ring_wave_addnofog"))
            surface.SetDrawColor(100, 100, 255, 255)
            local gg = (self.Timer - CurTime()) * 200
            surface.DrawTexturedRect(x - gg / 2, y - gg / 2, gg, gg)
        end
        surface.SetDrawColor(self.NoCoin and 250 or 5, self.NoCoin and 5 or 250, 0, 155) -- Sets the color of the lines we're drawing
        surface.DrawLine(x - length, y, x - gap, y) -- Left
        surface.DrawLine(x + length, y, x + gap, y) -- Right
        surface.DrawLine(x, y - length, x, y - gap) -- Top
        surface.DrawLine(x, y + length, x, y + gap) -- Bottom
    end
end

function SWEP:Initialize()
    self:SetWeaponHoldType(self.HoldType)
    self.Timer = 0
    if CLIENT then
        self.ViewModel = "models/weapons/c_coin.mdl"
        self.WorldModel = "models/weapons/w_coin.mdl"
    end
end

function SWEP:Holster(wep)
    if not IsFirstTimePredicted() then
        return
    end
    self.Timer = 0
    return true
end
