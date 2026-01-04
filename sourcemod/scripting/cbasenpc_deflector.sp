#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cbasenpc>
#include <tf2_stocks>
#include <tf2>

#define VERSION "1.4"

public Plugin myinfo =
{
	name = "[TF2] [CBaseNPC] Deflector Heavy",
	author = "Bloomstorm, HowToPlayMeow",
	description = "Allows to spawn NextBot Deflector Heavy",
	version = VERSION,
	url = "https://bloomstorm.su/"
};

#pragma semicolon 1

#define BASE_MODEL_SCALE "1.75"
#define BASE_MODEL_SCALE_F 1.75
#define BASE_HEALTH 5000
#define BASE_SPEED 230.0

#define FOOTSTEPS_COOLDOWN 0.4

#define NEXTBOT_CUSTOM_CLASS_NAME "nb_heavybot"

#define AC_STATE_IDLE 0
#define AC_STATE_STARTFIRING 1
#define AC_STATE_FIRING 2
#define AC_STATE_SPINNING 3
#define AC_STATE_DRYFIRE 4

#define TF_WEAPON_PRIMARY_MODE		0
#define TF_WEAPON_SECONDARY_MODE	1

#define TF_MINIGUN_SPINUP_TIME 0.75

#define MINIGUN_SND_LEVEL 95

#define PATTACH_POINT_FOLLOW 4

#define EXPERIMENT_CAMERA 0

ConVar g_CVar_aim;
ConVar g_CVar_killfeed;
ConVar g_CVar_fair_fight;
ConVar g_CVar_use_fov;
ConVar g_CVar_team_mode;
ConVar g_CVar_spy_cloak_visible;
ConVar g_CVar_spy_mechanics_ignore;

char g_szGibs[][] =
{
	"models/bots/gibs/heavybot_gib_boss_head.mdl",
	"models/bots/gibs/heavybot_gib_boss_arm.mdl",
	"models/bots/gibs/heavybot_gib_boss_arm2.mdl",
	"models/bots/gibs/heavybot_gib_boss_chest.mdl",
	"models/bots/gibs/heavybot_gib_boss_leg.mdl",
	"models/bots/gibs/heavybot_gib_boss_leg2.mdl",
	"models/bots/gibs/heavybot_gib_boss_pelvis.mdl"
};

char g_szFootstepSounds[][] =
{
	"mvm/giant_heavy/giant_heavy_step01.wav",
	"mvm/giant_heavy/giant_heavy_step02.wav",
	"mvm/giant_heavy/giant_heavy_step03.wav",
	"mvm/giant_heavy/giant_heavy_step04.wav",
};

char g_szPainSounds[][] =
{
	"vo/mvm/mght/heavy_mvm_m_PainSharp01.mp3",
	"vo/mvm/mght/heavy_mvm_m_PainSharp02.mp3",
	"vo/mvm/mght/heavy_mvm_m_PainSharp03.mp3",
};

char g_szDieSounds[][] =
{
	"vo/mvm/mght/heavy_mvm_m_PainSevere01.mp3",
	"vo/mvm/mght/heavy_mvm_m_PainSevere02.mp3",
	"vo/mvm/mght/heavy_mvm_m_PainSevere03.mp3",
};

char g_szSmallFootstepSounds[][] =
{
	"mvm/player/footsteps/robostep_01.wav",
	"mvm/player/footsteps/robostep_02.wav",
	"mvm/player/footsteps/robostep_03.wav",
	"mvm/player/footsteps/robostep_04.wav",
};

char g_szSmallPainSounds[][] =
{
	"vo/mvm/norm/heavy_mvm_PainSevere01.mp3",
	"vo/mvm/norm/heavy_mvm_PainSevere02.mp3",
	"vo/mvm/norm/heavy_mvm_PainSevere03.mp3",
};

char g_szSmallDieSounds[][] =
{
	"vo/mvm/norm/heavy_mvm_PainSevere01.mp3",
	"vo/mvm/norm/heavy_mvm_PainSevere02.mp3",
	"vo/mvm/norm/heavy_mvm_PainSevere03.mp3",
};

//Put on top because bot.sp relies on gamelinux define tags
#include "cbasenpc/nb_heavybot/gamelinux.sp"

#include "cbasenpc/nb_heavybot/bot.sp"

#include "cbasenpc/nb_heavybot/filters.sp"

#include "cbasenpc/selo.sp"

#include "cbasenpc/nb_heavybot/botbody.sp"

#include "cbasenpc/nb_heavybot/tfbotbody.sp"

#include "cbasenpc/nb_heavybot/tfbotintention.sp"

#include "cbasenpc/nb_heavybot/botvision.sp"

#include "cbasenpc/nb_heavybot/botpropsfactory.sp"

#include "cbasenpc/nb_heavybot.sp"

methodmap CTFMinigun < INextBot
{
    public CTFMinigun(INextBot bot)
    {
        return view_as<CTFMinigun>(bot);
    }

    public void AttackEnemyProjectiles()
    {
        float vecPos[3];
        CBaseAnimating(this.GetEntity()).WorldSpaceCenter(vecPos);

        float vecRocketPos[3];
        char szClassName[64];
        for (int i = MaxClients; i <= 2048; i++)
        {
            if (IsValidEntity(i))
            {
                GetEntityClassname(i, szClassName, sizeof(szClassName));
                //Only rockets, pipes, sticky bombs, jarate, milk and cleavers can be deflected. The other projectiles could lead to a server crash
                if (StrEqual(szClassName, "tf_projectile_rocket") || StrEqual(szClassName, "tf_projectile_pipe") || StrEqual(szClassName, "tf_projectile_jar") || StrEqual(szClassName, "tf_projectile_jar_milk") || StrEqual(szClassName, "tf_projectile_cleaver") ||
                StrEqual(szClassName, "tf_projectile_pipe_remote") || StrEqual(szClassName, "tf_projectile_energy_ball"))
                {
                    if (this.IsRocketBehindMe(i))
                    {
                        continue;
                    }
                    //TODO: Replace by something nice, TR_ or smth
                    GetEntPropVector(i, Prop_Send, "m_vecOrigin", vecRocketPos);
                    if (GetVectorDistance(vecRocketPos, vecPos) <= 150.0)
                    {
                        //weapons/fx/rics/ric1.wav - ric5.wav
                        EmitSoundToAll("weapons/halloween_boss/knight_axe_miss.wav", this.GetEntity(), SNDCHAN_AUTO, 150, _, 1.0, GetRandomInt(95,105));

                        this.CreateProjectile(i);

                        AcceptEntityInput(i, "Kill");
                    }
                }
            }
        }
    }

    //BreakModelRocketDud
    //src/game/shared/tf/tf_weaponbase_rocket.cpp L 641
    public void CreateProjectile(int ent)
    {
        float vecPos[3], angRot[3], vecForward[3];
        char szModel[256];

        GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecPos);
        GetEntPropVector(ent, Prop_Send, "m_angRotation", angRot);
        GetEntPropString(ent, Prop_Data, "m_ModelName", szModel, sizeof(szModel));

        //float angRot2[3];
        //GetEntPropVector(ent, Prop_Data, "m_angAbsRotation", angRot2);
        //PrintToChatAll("m_angRotation %.1f %.1f %.1f | m_angAbsRotation %.1f %.1f %.1f", angRot[0], angRot[1], angRot[2], angRot2[0], angRot2[1], angRot2[2]);

        GetAngleVectors(angRot, vecForward, NULL_VECTOR, NULL_VECTOR);

        float vecVelocity[3];

        vecVelocity[0] = vecForward[0];
        vecVelocity[1] = vecForward[1];
        vecVelocity[2] = vecForward[2] + 300.0;

        vecVelocity[0] *= -1.0;
        vecVelocity[1] *= -1.0;

        vecVelocity[0] *= 400.0;
        vecVelocity[1] *= 400.0;

        if (szModel[0] != '\0')
        {
            //Some rocket models can lead us to a server crash, because of lack of physics model or smth like that
            //I don't think server crashes because of not precaching every rocket model, because I think it's done already by a tf2
            //TODO: Check every physic model
            char szClassName[64];
            GetEntityClassname(ent, szClassName, sizeof(szClassName));
            if (StrEqual(szClassName, "tf_projectile_rocket"))
                szModel = "models/weapons/w_models/w_rocket.mdl";
            if (StrEqual(szClassName, "tf_projectile_energy_ball"))
                return;

            int iProp = CreateEntityByName("prop_physics_multiplayer");
            DispatchKeyValue(iProp, "model", szModel);
            DispatchKeyValue(iProp, "physicsmode", "2");

            TeleportEntity(iProp, vecPos, angRot, vecVelocity);

            DispatchSpawn(iProp);

            SetEntProp(iProp, Prop_Send, "m_CollisionGroup", 1); // 24
			SetEntProp(iProp, Prop_Send, "m_usSolidFlags", 0); // 8
			SetEntProp(iProp, Prop_Send, "m_nSolidType", 2); // 6
			SetEntProp(iProp, Prop_Send, "m_fEffects", 16|64);

			TeleportEntity(iProp, vecPos, angRot, vecVelocity);

			SetVariantString("OnUser1 !self:Kill::5.0:1");
			AcceptEntityInput(iProp, "AddOutput");
			AcceptEntityInput(iProp, "FireUser1");
        }

        //Handle hMsg = StartMessageAll("BreakModelRocketDud");
        //if (hMsg != null)
        //{
        //    PrintToChatAll("Msg");
        //    BfWriteShort(hMsg, GetEntProp(ent, Prop_Send, "m_nModelIndex"));
        //    BfWriteVecCoord(hMsg, vecPos);
        //    BfWriteAngles(hMsg, angRot);
        //    EndMessage();
        //}
    }

    public bool IsRocketBehindMe(int rocket)
    {
        CBaseEntity ent = CBaseEntity(this.GetEntity());

        float vecBotForward[3], angEyes[3];

        ent.GetPropVector(Prop_Data, "m_angCurrentAngles", angEyes);
        GetAngleVectors(angEyes, vecBotForward, NULL_VECTOR, NULL_VECTOR);
        vecBotForward[2] = 0.0;
        NormalizeVector(vecBotForward, vecBotForward);

        float vecBotPos[3], vecRocketPos[3], vecToBot[3];
        ent.WorldSpaceCenter(vecBotPos);
        CBaseEntity(rocket).WorldSpaceCenter(vecRocketPos);

        SubtractVectors(vecBotPos, vecRocketPos, vecToBot);
        vecToBot[2] = 0.0;
        NormalizeVector(vecToBot, vecToBot);

        float flDot = GetVectorDotProduct(vecBotForward, vecToBot);

        return flDot > -0.1;
    }

    public void WindUp()
    {
        HeavyRobotBot ent = HeavyRobotBot(this.GetEntity());

        ent.m_iWeaponState = AC_STATE_STARTFIRING;

        CBaseAnimatingOverlay(ent.index).AddGestureSequence(ent.GetProp(Prop_Data, "m_windUpGestureSequence"), 1.1, true);

        if (ent.m_bSmallHeavy)
        {
            EmitSoundToAll(")weapons/minigun_wind_up.wav", ent.index, SNDCHAN_WEAPON, 94, _, 1.0, 100);
            StopSound(ent.index, SNDCHAN_AUTO, ")weapons/minigun_shoot.wav");
            StopSound(ent.index, SNDCHAN_AUTO, ")weapons/minigun_spin.wav");
        }
        else
        {
            EmitSoundToAll(")mvm/giant_heavy/giant_heavy_gunwindup.wav", ent.index, SNDCHAN_WEAPON, MINIGUN_SND_LEVEL, _, 0.9, 100);
            StopSound(ent.index, SNDCHAN_AUTO, ")mvm/giant_heavy/giant_heavy_gunfire.wav");
            StopSound(ent.index, SNDCHAN_AUTO, ")mvm/giant_heavy/giant_heavy_gunspin.wav");
            StopSound(ent.index, SNDCHAN_AUTO, "mvm/giant_heavy/giant_heavy_gunfire.wav");
            StopSound(ent.index, SNDCHAN_AUTO, "mvm/giant_heavy/giant_heavy_gunspin.wav");
        }

        this.WeaponSoundUpdate();
    }

    public void WindDown()
    {
        HeavyRobotBot ent = HeavyRobotBot(this.GetEntity());

        if (ent.m_iWeaponState == AC_STATE_FIRING)
        {
            //this.PlayStopFiringSound();
        }

        ent.m_iWeaponState = AC_STATE_IDLE;

        ent.SetProp(Prop_Data, "m_runSequence", ent.GetProp(Prop_Data, "m_runPrimarySequence"));
        ent.SetProp(Prop_Data, "m_idleSequence", ent.GetProp(Prop_Data, "m_standPrimarySequence"));

        CBaseAnimatingOverlay(ent.index).AddGestureSequence(ent.GetProp(Prop_Data, "m_windDownGestureSequence"), 1.1, true);

        if (ent.m_bSmallHeavy)
        {
            EmitSoundToAll(")weapons/minigun_wind_down.wav", ent.index, SNDCHAN_WEAPON, 94, _, 1.0, 100);
            StopSound(ent.index, SNDCHAN_AUTO, ")weapons/minigun_shoot.wav");
            StopSound(ent.index, SNDCHAN_AUTO, ")weapons/minigun_spin.wav");
        }
        else
        {
            EmitSoundToAll(")mvm/giant_heavy/giant_heavy_gunwinddown.wav", ent.index, SNDCHAN_WEAPON, MINIGUN_SND_LEVEL, _, 0.9, 100);
            StopSound(ent.index, SNDCHAN_AUTO, "mvm/giant_heavy/giant_heavy_gunfire.wav");
            StopSound(ent.index, SNDCHAN_AUTO, "mvm/giant_heavy/giant_heavy_gunspin.wav");
            StopSound(ent.index, SNDCHAN_AUTO, ")mvm/giant_heavy/giant_heavy_gunfire.wav");
            StopSound(ent.index, SNDCHAN_AUTO, ")mvm/giant_heavy/giant_heavy_gunspin.wav");
        }

        this.WeaponSoundUpdate();

        ent.m_flWeaponIdleTime = GetGameTime() + 2.0;
    }

    public void WeaponIdle()
    {
        HeavyRobotBot ent = HeavyRobotBot(this.GetEntity());
        if (GetGameTime() < ent.m_flWeaponIdleTime)
            return;

        if (ent.m_iWeaponState != AC_STATE_IDLE)
        {
            this.WindDown();
            return;
        }

        ent.m_flWeaponIdleTime = GetGameTime() + 12.5;
    }

    public void Attack()
    {
        HeavyRobotBot ent = HeavyRobotBot(this.GetEntity());
        switch (ent.m_iWeaponState)
        {
            case AC_STATE_IDLE:
            {
                ent.SetProp(Prop_Data, "m_runSequence", ent.GetProp(Prop_Data, "m_runDeployedSequence"));
                ent.SetProp(Prop_Data, "m_idleSequence", ent.GetProp(Prop_Data, "m_standDeployedSequence"));

                this.WindUp();

                ent.m_flNextPrimaryAttack = GetGameTime() + TF_MINIGUN_SPINUP_TIME;
                ent.m_flNextSecondaryAttack = GetGameTime() + TF_MINIGUN_SPINUP_TIME;
                ent.m_flWeaponIdleTime = GetGameTime() + TF_MINIGUN_SPINUP_TIME;
            }
            case AC_STATE_STARTFIRING:
            {
                if (ent.m_flNextPrimaryAttack <= GetGameTime())
                {
                    if (ent.m_iWeaponMode == TF_WEAPON_SECONDARY_MODE)
                        ent.m_iWeaponState = AC_STATE_SPINNING;
                    else
                        ent.m_iWeaponState = AC_STATE_FIRING;

                    ent.m_flNextSecondaryAttack = ent.m_flNextPrimaryAttack = ent.m_flWeaponIdleTime = GetGameTime() + 0.1;
                }
            }
            case AC_STATE_FIRING:
            {
                if (ent.m_iWeaponMode == TF_WEAPON_SECONDARY_MODE)
                {
                    ent.m_iWeaponState = AC_STATE_SPINNING;
                }

                if (ent.m_iWeaponState == AC_STATE_SPINNING)
                {
                    ent.m_flNextSecondaryAttack = ent.m_flNextPrimaryAttack = ent.m_flWeaponIdleTime = GetGameTime() + 0.1;
                }
                else
                {
                    if (GetGameTime() >= ent.m_flNextPrimaryAttack)
                    {
                        float vecMuzzlePos[3], vecAngles[3], vecEndPos[3], vecEyePos[3];
                        int iAttachment = CBaseAnimating(ent.m_hMyWeapon.index).LookupAttachment("muzzle");
                        CBaseAnimating(ent.m_hMyWeapon.index).GetAttachment(iAttachment, vecMuzzlePos, vecAngles);

                        float angEyes[3];
                        ent.GetPropVector(Prop_Data, "m_angCurrentAngles", angEyes);

                        //ent.MyNextBotPointer().GetBodyInterface().GetEyePosition(vecEyePos);
                        CBotBody(ent.MyNextBotPointer().GetBodyInterface()).GetEyePositionEx(vecEyePos);

                        //https://github.com/mastercoms/configs/blob/master/games/tf2/custom/weapons/scripts/tf_weapon_minigun.txt
                        float flDamage = 9.0;
                        float flSpread = 0.08;

                        float x, y;

                        float vecForward[3], vecRight[3], vecUp[3], vecDir[3];
                        GetAngleVectors(angEyes, vecForward, vecRight, vecUp);

                        //tf_fx_shared.cpp
                        for (int i = 0; i < 4; i++)
                        {
                            x = GetRandomFloat(-0.5, 0.5) + GetRandomFloat(-0.5, 0.5);
                            y = GetRandomFloat(-0.5, 0.5) + GetRandomFloat(-0.5, 0.5);

                            vecDir[0] = vecForward[0] + (x * flSpread * vecRight[0]) + (y * flSpread * vecUp[0]);
                            vecDir[1] = vecForward[1] + (x * flSpread * vecRight[1]) + (y * flSpread * vecUp[1]);
                            vecDir[2] = vecForward[2] + (x * flSpread * vecRight[2]) + (y * flSpread * vecUp[2]);
                            NormalizeVector(vecDir, vecDir);
                            GetVectorAngles(vecDir, vecDir);

                            Handle hTrace = TR_TraceRayFilterEx(vecEyePos, vecDir, (MASK_SOLID|CONTENTS_HITBOX), RayType_Infinite, Filter_BulletTrace, ent.index);

                            if (TR_GetFraction(hTrace) < 1.0)
                            {
                                if (TR_GetEntityIndex(hTrace) == -1)
                                {
                                    delete hTrace;
                                    continue;
                                }
                            }

                            int iVictim = TR_GetEntityIndex(hTrace);
                            if (iVictim > 0)
                            {
                                SDKHooks_TakeDamage(iVictim, ent.index, ent.index, flDamage, DMG_BULLET, -1, _, _, true);
                            }

                            TR_GetEndPosition(vecEndPos, hTrace);

                            if (iVictim <= 0)
                            {
                                float vecNormal[3];
                                TR_GetPlaneNormal(hTrace, vecNormal);
                                GetVectorAngles(vecNormal, vecNormal);
                                CreateParticle("impact_concrete", vecEndPos, vecNormal);
                            }

                            delete hTrace;

                            ShootLaserEx(ent.m_hMyWeapon.index, "bullet_tracer02_blue", vecMuzzlePos, vecEndPos, false, PATTACH_POINT_FOLLOW, iAttachment);
                        }

                        CreateParticleEx("muzzle_minigun", vecMuzzlePos, vecAngles, ent.m_hMyWeapon.index, PATTACH_POINT_FOLLOW, iAttachment);

                        ent.m_flNextPrimaryAttack = GetGameTime() + 0.1;

                        this.AttackEnemyProjectiles();
                    }

                    ent.m_flWeaponIdleTime = GetGameTime() + 0.2;
                }

                this.WeaponSoundUpdate();
            }
            case AC_STATE_SPINNING:
            {
                if (ent.m_iWeaponMode == TF_WEAPON_PRIMARY_MODE)
                {
                    ent.m_iWeaponState = AC_STATE_FIRING;
                }

                this.WeaponSoundUpdate();
            }
        }
    }

    public void WeaponSoundUpdate()
    {
        HeavyRobotBot ent = HeavyRobotBot(this.GetEntity());

        int iSound = -1;
        switch (ent.m_iWeaponState)
        {
            case AC_STATE_FIRING: iSound = 1;
            case AC_STATE_SPINNING: iSound = 2;
        }

        if (ent.m_iMinigunSound == iSound)
            return;

        ent.m_iMinigunSound = iSound;

        if (iSound == 2)
        {
            if (ent.m_bSmallHeavy)
            {
                StopSound(ent.index, SNDCHAN_AUTO, ")weapons/minigun_shoot.wav");
                EmitSoundToAll(")weapons/minigun_spin.wav", ent.index, SNDCHAN_AUTO, 94, _, SNDVOL_NORMAL, 100);
            }
            else
            {
                StopSound(ent.index, SNDCHAN_AUTO, ")mvm/giant_heavy/giant_heavy_gunfire.wav");
                StopSound(ent.index, SNDCHAN_AUTO, "mvm/giant_heavy/giant_heavy_gunfire.wav");
                EmitSoundToAll(")mvm/giant_heavy/giant_heavy_gunspin.wav", ent.index, SNDCHAN_AUTO, MINIGUN_SND_LEVEL, _, SNDVOL_NORMAL, 100);
            }
        }
        else if (iSound == 1)
        {
            if (ent.m_bSmallHeavy)
            {
                StopSound(ent.index, SNDCHAN_AUTO, ")weapons/minigun_spin.wav");
                EmitSoundToAll(")weapons/minigun_shoot.wav", ent.index, SNDCHAN_AUTO, 94, _, SNDVOL_NORMAL, 100);
            }
            else
            {
                StopSound(ent.index, SNDCHAN_AUTO, ")mvm/giant_heavy/giant_heavy_gunspin.wav");
                StopSound(ent.index, SNDCHAN_AUTO, "mvm/giant_heavy/giant_heavy_gunspin.wav");
                EmitSoundToAll(")mvm/giant_heavy/giant_heavy_gunfire.wav", ent.index, SNDCHAN_AUTO, MINIGUN_SND_LEVEL, _, SNDVOL_NORMAL, 100);
            }
        }
    }
}

ArrayList g_arTeleporters;

//New entity that spawns small heavy bots
//TODO: Create new entity nb_heavybot_spawner instead?
methodmap CTeleporterSpawner < CBaseEntity
{
    public CTeleporterSpawner(CBaseEntity ent)
    {
        return view_as<CTeleporterSpawner>(ent);
    }

    public void Update()
    {

    }

    public static int Create(float pos[3], float rot[3], int team)
    {
        int iEnt = CreateEntityByName("obj_teleporter");
        if (iEnt == -1)
            return -1;

        TeleportEntity(iEnt, pos, rot, NULL_VECTOR);
        SetEntProp(iEnt, Prop_Send, "m_iTeamNum", team);
        SetEntProp(iEnt, Prop_Data, "m_iTeleportType", 1);
        SetEntProp(iEnt, Prop_Send, "m_iObjectMode", 1);
        SetEntProp(iEnt, Prop_Send, "m_bBuilding", 1);
        SetEntProp(iEnt, Prop_Send, "m_nSkin", team == 2 ? 0 : 1);
        SetEntProp(iEnt, Prop_Send, "m_iHighestUpgradeLevel", 1);
        //DispatchKeyValue(iEnt, "defaultupgrade", "0");
        DispatchSpawn(iEnt);
        //ActivateEntity(iEnt);

        SetEntProp(iEnt, Prop_Send, "m_bBuilding", 1);

        SetEntProp(iEnt, Prop_Data, "m_iMaxHealth", 425);
        SetEntProp(iEnt, Prop_Send, "m_iHealth", 425);

        DataPack pack = new DataPack();
        pack.WriteCell(EntIndexToEntRef(iEnt));
        pack.WriteCell(-1);
        g_arTeleporters.Push(pack);

        EmitSoundToAll(")mvm/mvm_tele_activate.wav", iEnt, SNDCHAN_AUTO, 150, _, 1.0, 100);
        CTeleporterSpawner(CBaseEntity(iEnt)).AttachParticle();
        SDKHook(iEnt, SDKHook_SetTransmit, Hook_TeleporterSetTransmit);
        CreateTimer(5.0, Timer_TeleporterSpawnerSpawnLogic, EntIndexToEntRef(iEnt), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

        //Idk how to spawn a building in process teleporter
        /* DataPack pack = new DataPack();
        pack.WriteCell(EntIndexToEntRef(iEnt));
        pack.WriteCell(-1);
        g_arTeleporters.Push(pack);

        CreateTimer(0.2, Timer_TeleporterSpawnerBuildingLogic, EntIndexToEntRef(iEnt), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE); */

        return iEnt;
    }

    public void Kill()
    {
        for (int i = 0; i < g_arTeleporters.Length; i++)
        {
            DataPack pack = view_as<DataPack>(g_arTeleporters.Get(i));
            pack.Reset();
            int iEnt = EntRefToEntIndex(pack.ReadCell());
            int iTeleporterEffect = EntRefToEntIndex(pack.ReadCell());

            if (iEnt == this.index)
            {
                if (iTeleporterEffect > 0)
                {
                    AcceptEntityInput(iTeleporterEffect, "Kill");
                }
                delete pack;
                g_arTeleporters.Erase(i);
                break;
            }
            else if (iEnt == -1)
            {
                //How this could be happen? Let's remove just in case to avoid memory leaks
                delete pack;
                g_arTeleporters.Erase(i);
                i--;
            }
        }
    }

    public static void KillEverything(bool dontErase)
    {
        for (int i = 0; i < g_arTeleporters.Length; i++)
        {
            DataPack pack = view_as<DataPack>(g_arTeleporters.Get(i));
            pack.Reset();
            int iEnt = EntRefToEntIndex(pack.ReadCell());
            int iTeleporterEffect = EntRefToEntIndex(pack.ReadCell());

            if (iEnt > 0)
                AcceptEntityInput(iEnt, "Kill");
            if (iTeleporterEffect > 0)
                AcceptEntityInput(iEnt, "Kill");

            //If we call in it OnPluginEnd, it would call about invalid handle datapack
            if (!dontErase)
            {
                delete pack;
                g_arTeleporters.Erase(i);
            }
        }
    }

    public void AttachParticle()
    {
        int iParticle = CTeleporterSpawner.CreateParticle(this.index, "teleporter_mvm_bot_persist");
        if (iParticle == -1)
            return;

        //CheckArray();

        for (int i = 0; i < g_arTeleporters.Length; i++)
        {
            DataPack pack = view_as<DataPack>(g_arTeleporters.Get(i));
            pack.Reset();

            int iEnt = EntRefToEntIndex(pack.ReadCell());
            if (iEnt == this.index)
            {
                delete pack;
                g_arTeleporters.Erase(i);

                pack = new DataPack();
                pack.WriteCell(EntIndexToEntRef(iEnt));
                pack.WriteCell(EntIndexToEntRef(iParticle));

                g_arTeleporters.Push(pack);
                break;
            }
        }
    }

    public static int CreateParticle(int ent, const char[] part)
    {
        int iParticle = CreateEntityByName("info_particle_system");
        if (iParticle == -1)
            return -1;
        //char szTargetName[64];
        float vecOrigin[3];
        GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecOrigin);
        TeleportEntity(iParticle, vecOrigin, NULL_VECTOR, NULL_VECTOR);

        DispatchKeyValue(iParticle, "targetname", "tp_prtcl");
        //DispatchKeyValue(iParticle, "parentname", szTargetName);
        DispatchKeyValue(iParticle, "effect_name", part);
        DispatchSpawn(iParticle);

        //Do not parent particle to a teleporter, because somehow, it fuck up the SetTransmit hook? It switches m_iState slowy because of that
        //SetVariantString(szTargetName);
        //AcceptEntityInput(iParticle, "SetParent", iParticle, iParticle);
        SetEntPropEnt(iParticle, Prop_Send, "m_hOwnerEntity", ent);
        ActivateEntity(iParticle);
        AcceptEntityInput(iParticle, "Start");
        return iParticle;
    }

    //Just in case to avoid memory leaks
    public static void CheckArray()
    {
        for (int i = 0; i < g_arTeleporters.Length; i++)
        {
            DataPack pack = view_as<DataPack>(g_arTeleporters.Get(i));
            pack.Reset();

            int iEnt = EntRefToEntIndex(pack.ReadCell());
            if (iEnt == -1)
            {
                delete pack;
                g_arTeleporters.Erase(i);
            }
        }
    }
}

/* public Action Timer_TeleporterSpawnerBuildingLogic(Handle timer, int entRef)
{
    int iEnt = EntRefToEntIndex(entRef);
	if (iEnt <= 0)
		return Plugin_Stop;
	if (!HasEntProp(iEnt, Prop_Send, "m_iState"))
		return Plugin_Stop;
	if (!HasEntProp(iEnt, Prop_Send, "m_flPercentageConstructed"))
		return Plugin_Stop;
	float flProgress = GetEntPropFloat(iEnt, Prop_Send, "m_flPercentageConstructed");
	//PrintToChatAll("m_flPercentageConstructed %.1f", flProgress);
	if (flProgress >= 1.0)
	{
		if (GetEntProp(iEnt, Prop_Send, "m_iHighestUpgradeLevel") != 3)
		{
			SetEntProp(iEnt, Prop_Data, "m_iMaxHealth", 432);
			SetVariantInt(432);
			AcceptEntityInput(iEnt, "SetHealth");
			SetEntProp(iEnt, Prop_Send, "m_iHighestUpgradeLevel", 3);
		}

		//Built
		EmitSoundToAll(")mvm/mvm_tele_activate.wav", iEnt, SNDCHAN_AUTO, 150, _, 1.0, 100);
        CTeleporterSpawner(CBaseEntity(iEnt)).AttachParticle();
        SDKHook(iEnt, SDKHook_SetTransmit, Hook_TeleporterSetTransmit);
        CreateTimer(5.0, Timer_TeleporterSpawnerSpawnLogic, EntIndexToEntRef(iEnt), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Stop;
	}
	return Plugin_Continue;
} */

public Action Timer_TeleporterSpawnerSpawnLogic(Handle timer, int entRef)
{
    int iEnt = EntRefToEntIndex(entRef);
    if (iEnt <= 0)
        return Plugin_Stop;

    int iNumOfBots = 0;

    int iBot = -1;
    char szName[64];
    //TODO: individual max bots number by a teleporter? Something like teleported:entindex ?
    while ((iBot = FindEntityByClassname(iBot, "nb_heavybot")) != INVALID_ENT_REFERENCE)
    {
        GetEntPropString(iBot, Prop_Data, "m_iName", szName, sizeof(szName));
        if (StrEqual(szName, "teleported"))
            iNumOfBots++;
    }

    //If a teleporter in red or blue team, the sapper would deactive it. But if the teleporter in a unassigned team, then it would do nothing, because there is no engineers in unassigned team to remove the sapper
    if (GetEntProp(iEnt, Prop_Send, "m_iTeamNum") > 2 && GetEntProp(iEnt, Prop_Send, "m_bSapped"))
        return Plugin_Continue;

    if (iNumOfBots >= 22)
        return Plugin_Continue;

    float vecPos[3];
    GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", vecPos);

    HeavyRobotBot bot = view_as<HeavyRobotBot>(CreateEntityByName("nb_heavybot"));
	if (bot.index != -1)
	{
        int iSkill = GetRandomInt(1, 3);

        bot.Teleport(vecPos);
		bot.SetProp(Prop_Data, "m_iSkill", iSkill);
		bot.SetProp(Prop_Data, "m_iTeamNum", GetEntProp(iEnt, Prop_Send, "m_iTeamNum"));
		bot.SetProp(Prop_Data, "m_bDontFearSentries", true);
		bot.SetProp(Prop_Data, "m_bSmallHeavy", true);
		bot.SetPropString(Prop_Data, "m_iName", "teleported");
		bot.SetPropFloat(Prop_Data, "m_flUberTimer", GetGameTime() + 5.0);

		bot.Spawn();
	}

	CreateParticle(GetEntProp(iEnt, Prop_Send, "m_iTeamNum") == 2 ? "teleported_red" : "teleported_blue", vecPos, NULL_VECTOR);
	CreateParticle(GetEntProp(iEnt, Prop_Send, "m_iTeamNum") == 2 ? "player_sparkles_red" : "player_sparkles_blue", vecPos, NULL_VECTOR);

    EmitSoundToAll(")mvm/mvm_tele_deliver.wav", iEnt, SNDCHAN_AUTO, 150, _, SNDVOL_NORMAL, 100);
    return Plugin_Continue;
}

//From my robot engineer simulator plugin, will publish soon
//We use SetTransmit hook to force moving animation by setting state to 2
public Action Hook_TeleporterSetTransmit(int entity, int client)
{
	//if (GetEntPropFloat(entity, Prop_Send, "m_flPercentageConstructed") >= 1.0)
	//{
		int iPreviousState = GetEntProp(entity, Prop_Send, "m_iState");
		if (iPreviousState == 1)
			SetEntProp(entity, Prop_Send, "m_iState", 2);

		SetVariantString("running");
		AcceptEntityInput(entity, "SetAnimation");
		SetVariantString("running");
		AcceptEntityInput(entity, "SetDefaultAnimation");
	//}
	return Plugin_Continue;
}

public void OnPluginStart()
{
    HeavyRobotBot.Initialize();

    CreateConVar("sm_nextbot_deflector_version", VERSION, "Plugin version", FCVAR_NOTIFY);
    g_CVar_aim = CreateConVar("sm_nextbot_deflector_aim", "1", "0 - Use TFBot aim system. 1 - Use same system as TFBot, but a little different");
    g_CVar_killfeed = CreateConVar("sm_nextbot_deflector_killfeed", "1", "Should the Deflector's kills/deaths be listed in the killfeed?");
    g_CVar_fair_fight = CreateConVar("sm_nextbot_deflector_fair_fight", "0", "If set, AI will ignore players who are in places where there is no navmesh to prevent AI abuse, and these players cant damage the Deflector nextbot, more info on a plugin page");
    g_CVar_use_fov = CreateConVar("sm_nextbot_deflector_use_fov", "1", "If set, NextBot will use FOV system to detect his threats");
    g_CVar_team_mode = CreateConVar("sm_nextbot_deflector_team_mode", "0", "For sm_nextbot_deflector_killfeed, 0 - fake client spawned in unassigned team and can be switched to another team; 1 - fake client always will be in unassigned team; 2 - fake client will change team depends on nextbot team");
    g_CVar_spy_cloak_visible = CreateConVar("sm_nextbot_deflector_spy_cloak_visible", "0", "If set, NextBot will always target invisible spies");
    g_CVar_spy_mechanics_ignore = CreateConVar("sm_nextbot_deflector_spy_mechanics_ignore", "0", "If set, NextBot will ignore spy mechanics (disguise and invisiblity)");

    HookConVarChange(g_CVar_team_mode, OnCVarChanged_team_mode);
    HookConVarChange(g_CVar_aim, OnCVarChanged_aim);

    char szValue[8];
    g_CVar_team_mode.GetString(szValue, sizeof(szValue));
    OnCVarChanged_team_mode(g_CVar_team_mode, szValue, szValue);
    g_CVar_aim.GetString(szValue, sizeof(szValue));
    OnCVarChanged_aim(g_CVar_aim, szValue, szValue);

    RegAdminCmd("sm_deflectorbot", Cmd_Test, ADMFLAG_RCON, "Spawn a nextbot deflector heavy");
    RegAdminCmd("sm_smalldeflectorbot", Cmd_Test2, ADMFLAG_RCON, "Spawn a nextbot deflector heavy junior");
    RegAdminCmd("sm_deflectorbot_spawner", Cmd_Test3, ADMFLAG_RCON, "Spawn a deflector spawner");

    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
    HookEvent("post_inventory_application", Event_PlayerSpawn);
    HookEvent("npc_hurt", Event_NpcHurt);
    HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);

#if EXPERIMENT_CAMERA
    RegAdminCmd("sm_deflectorbot_camera", Cmd_Test2, ADMFLAG_RCON);
#endif

    g_szFakeClientName = "Giant Deflector Heavy";

    CBotConfig.AddSpyMemorySupport();
    g_bSpyDisguiseEnabled = true;
    CBotConfig.AddSpyBackstabSupport();

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
            OnClientPostAdminCheck(i);
    }

    g_arTeleporters = new ArrayList();
}

public void OnMapStart()
{
    PrecacheModel("models/bots/heavy_boss/bot_heavy_boss.mdl");
    PrecacheModel("models/player/items/mvm_loot/heavy/robo_ushanka.mdl");
    PrecacheModel("models/weapons/w_models/w_minigun.mdl");

	PrecacheSound("mvm/giant_heavy/giant_heavy_gunwindup.wav");
	PrecacheSound("mvm/giant_heavy/giant_heavy_gunwinddown.wav");
	PrecacheSound("mvm/giant_heavy/giant_heavy_gunfire.wav");
	PrecacheSound("mvm/giant_heavy/giant_heavy_gunspin.wav");
	PrecacheSound("mvm/giant_heavy/giant_heavy_loop.wav");
	PrecacheSound("mvm/sentrybuster/mvm_sentrybuster_explode.wav");
	PrecacheSound("weapons/halloween_boss/knight_axe_miss.wav");

	PrecacheModel("models/bots/heavy/bot_heavy.mdl");
	PrecacheSound(")weapons/minigun_shoot.wav");
	PrecacheSound(")weapons/minigun_spin.wav");
	PrecacheSound(")weapons/minigun_wind_down.wav");
	PrecacheSound(")weapons/minigun_wind_up.wav");

	PrecacheSound(")mvm/mvm_tele_deliver.wav");
	PrecacheSound(")mvm/mvm_tele_activate.wav");

	for (int i = 0; i < sizeof(g_szGibs); i++)
	{
		PrecacheModel(g_szGibs[i]);
	}

	for (int i = 0; i < sizeof(g_szPainSounds); i++)
	{
		PrecacheSound(g_szPainSounds[i]);
	}
	for (int i = 0; i < sizeof(g_szFootstepSounds); i++)
	{
		PrecacheSound(g_szFootstepSounds[i]);
	}
	for (int i = 0; i < sizeof(g_szDieSounds); i++)
	{
		PrecacheSound(g_szDieSounds[i]);
	}

	for (int i = 0; i < sizeof(g_szPainSounds); i++)
	{
		PrecacheSound(g_szSmallPainSounds[i]);
	}
	for (int i = 0; i < sizeof(g_szFootstepSounds); i++)
	{
		PrecacheSound(g_szSmallFootstepSounds[i]);
	}
	for (int i = 0; i < sizeof(g_szDieSounds); i++)
	{
		PrecacheSound(g_szSmallDieSounds[i]);
	}
}

public void OnEntityCreated(int entity, const char[] className)
{
	if (StrEqual(className, "nb_heavybot"))
	{
        if (g_CVar_killfeed.BoolValue)
            CBot.AddFakeClient();

        CBot.FixHitbox(entity);
		CBot.AddHookSniperHeadshot(entity);
		CBot.AddHookSpyBackstab(entity);
	}
}

public void OnEntityDestroyed(int entity)
{
	if (entity <= 0) return;

	char szName[64];
	GetEntityClassname(entity, szName, sizeof(szName));

    StopSound(entity, SNDCHAN_AUTO, "mvm/giant_heavy/giant_heavy_gunfire.wav");
    StopSound(entity, SNDCHAN_AUTO, "mvm/giant_heavy/giant_heavy_gunspin.wav");
    StopSound(entity, SNDCHAN_AUTO, "mvm/giant_heavy/giant_heavy_loop.wav");

	if (StrEqual(szName, "nb_heavybot"))
	{
        StopSound(entity, SNDCHAN_AUTO, "mvm/giant_heavy/giant_heavy_gunfire.wav");
        StopSound(entity, SNDCHAN_AUTO, "mvm/giant_heavy/giant_heavy_gunspin.wav");

        StopSound(entity, SNDCHAN_STATIC, "mvm/giant_heavy/giant_heavy_gunfire.wav");
        StopSound(entity, SNDCHAN_STATIC, "mvm/giant_heavy/giant_heavy_gunspin.wav");

        StopSound(entity, SNDCHAN_AUTO, ")weapons/minigun_shoot.wav");
        StopSound(entity, SNDCHAN_AUTO, ")weapons/minigun_spin.wav");

		int iNum = 0;
		int iEnt = -1;
		while ((iEnt = FindEntityByClassname(iEnt, "nb_heavybot")) != INVALID_ENT_REFERENCE)
		{
			iNum++;
		}
		if (iNum <= 0)
		{
            CBot.RemoveFakeClient();
		}
		CreateTimer(0.1, Timer_CheckForSure, _, TIMER_FLAG_NO_MAPCHANGE);

		//if (EntRefToEntIndex(g_iBossHealthbarRef) == entity)
		//{
        //    CBotBossHealthbar.UpdateBossHealth();
		//}
	}

	if (StrEqual(szName, "obj_teleporter"))
	{
        CTeleporterSpawner(CBaseEntity(entity)).Kill();
	}
}

//Sometimes, if we kill every nextbot via input Kill in single frame, there is a chance that out fake client wouldn't disconnect
public Action Timer_CheckForSure(Handle timer, int fignya)
{
	int iNum = 0;
	int iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt, "nb_heavybot")) != INVALID_ENT_REFERENCE)
	{
		iNum++;
	}
	if (iNum <= 0)
	{
		CBot.RemoveFakeClient();
	}
	return Plugin_Stop;
}

public void OnMapEnd()
{
	CBot.RemoveFakeClient();

	CTeleporterSpawner.KillEverything(false);
}

public void OnPluginEnd()
{
	CBot.RemoveFakeClient();

	CTeleporterSpawner.KillEverything(true);
}

public void OnClientPostAdminCheck(int client)
{
    #if defined GAME_LINUX_LOADED
    CGameLinux.ClearPlayer(client);
    CGameLinux.CheckPlayerPlatform(client);
    #endif
}

public void OnCVarChanged_team_mode(ConVar convar, const char[] oldValue, const char[] newValue)
{
    g_iFakeClientTeamMode = StringToInt(newValue);
}

public void OnCVarChanged_aim(ConVar convar, const char[] oldValue, const char[] newValue)
{

}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_CVar_killfeed.BoolValue)
        return;

	int iInflictor = event.GetInt("inflictor_entindex");

	if (iInflictor > 0)
	{
		int iEnt = -1;
		while ((iEnt = FindEntityByClassname(iEnt, NEXTBOT_CUSTOM_CLASS_NAME)) != INVALID_ENT_REFERENCE)
		{
			if (iEnt == iInflictor)
			{
                g_szFakeClientName = "Giant Deflector Heavy";

                HeavyRobotBot bot = HeavyRobotBot(iEnt);

                if (bot.m_bSmallHeavy)
                    g_szFakeClientName = "Deflector Heavy";

                int iDeathFlags = 0;
                if (bot.m_hMyWeapon.index != -1 && bot.m_hMyWeapon.GetProp(Prop_Send, "m_nSkin") == 8)
                    iDeathFlags |= TF_DEATHFLAG_AUSTRALIUM;

                if (!bot.m_bSmallHeavy)
                    iDeathFlags |= TF_DEATHFLAG_MINIBOSS;

                int iCrit = 0;
                if (EntRefToEntIndex(g_iBossHealthbarTargetRef) == iEnt)
                    iCrit = 2;

                CBot.EventPlayerDeath(event, "minigun", iDeathFlags, iCrit);
			}
		}
	}
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (GetClientOfUserId(g_iFakeClientUserId) > 0 && client == GetClientOfUserId(g_iFakeClientUserId))
    {
        //Our fake client somehow spawned (most likely by a plugin who force moves spectators to red/blu for idle/afk servers)
        //To avoid infinite loop (we moving to spectator again and some plugin move this client back to red/blue)
        //We will grant him a god mode and invisiblity
        //This client is ignored by a nextbot just in case (spawn location on the open map etc)
        //UPD: changed my mind, added cooldown check in bot.sp
        CBot.ClearFakeClientLoadout(client);
    }
}

public void Event_NpcHurt(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_CVar_killfeed.BoolValue)
        return;

    int iEnt = event.GetInt("entindex");
    int iHealth = event.GetInt("health");
    int iAttacker = GetClientOfUserId(event.GetInt("attacker_player"));

    if (iEnt > 0 && iHealth == 0)
    {
        char szClassName[64];
        GetEntityClassname(iEnt, szClassName, sizeof(szClassName));

        if (StrEqual(szClassName, NEXTBOT_CUSTOM_CLASS_NAME) && iAttacker > 0 && iAttacker <= MaxClients)
        {
            g_szFakeClientName = "Giant Deflector Heavy";

            if (GetEntProp(iEnt, Prop_Data, "m_bSmallHeavy"))
                g_szFakeClientName = "Deflector Heavy";

            CBot.EventNPCHurt(event);
        }
    }
}

public Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    int iTeam = event.GetInt("team");
    bool bDisconnect = event.GetBool("disconnect");
    if (bDisconnect)
        return Plugin_Continue;
    if (client == GetClientOfUserId(g_iFakeClientUserId))
    {
        CBot.EventPlayerTeam(client, iTeam);
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

//Using this to detect player firing his weapon for soldier's AI IsImmediate
public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool& result)
{
	CTFBotIntention.OnClientWeaponFired(client, weapon);

	CBot.HandleBackstabLogic(client, weapon);
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
    CBot.HandleOnConditionAdded(client, condition);
}

bool IsClientFriendlyKostyl(int client)
{
	return GetEntProp(client, Prop_Data, "m_takedamage") != 2;
}

int CreateWeapon(int holder, const char[] model, const char[] attachment, int skin = 0, float scale = 1.0)
{
	int iEnt = CreateEntityByName("prop_dynamic");

	DispatchKeyValue(iEnt, "model", model);
	DispatchKeyValueFloat(iEnt, "modelscale", scale);
	DispatchSpawn(iEnt);

    SetEntProp(iEnt, Prop_Send, "m_nSkin", skin);
	SetEntProp(iEnt, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_PARENT_ANIMATES);

	SetVariantString("!activator");
	AcceptEntityInput(iEnt, "SetParent", holder);

	SetVariantString(attachment);
	AcceptEntityInput(iEnt, "SetParentAttachmentMaintainOffset");

	return iEnt;
}

stock void ShootLaser(int weapon, const char[] strParticle, float flStartPos[3], float flEndPos[3], bool bResetParticles = false)
{
	int tblidx = FindStringTable("ParticleEffectNames");
	if (tblidx == INVALID_STRING_TABLE)
	{
		LogError("Could not find string table: ParticleEffectNames");
		return;
	}
	char tmp[256];
	int count = GetStringTableNumStrings(tblidx);
	int stridx = INVALID_STRING_INDEX;
	for (int i = 0; i < count; i++)
	{
		ReadStringTable(tblidx, i, tmp, sizeof(tmp));
		if (StrEqual(tmp, strParticle, false))
		{
			stridx = i;
			break;
		}
	}
	if (stridx == INVALID_STRING_INDEX)
	{
		LogError("Could not find particle: %s", strParticle);
		return;
	}

	TE_Start("TFParticleEffect");
	TE_WriteFloat("m_vecOrigin[0]", flStartPos[0]);
	TE_WriteFloat("m_vecOrigin[1]", flStartPos[1]);
	TE_WriteFloat("m_vecOrigin[2]", flStartPos[2]);
	TE_WriteNum("m_iParticleSystemIndex", stridx);
	TE_WriteNum("entindex", weapon);
	TE_WriteNum("m_iAttachType", 2);
	TE_WriteNum("m_iAttachmentPointIndex", 0);
	TE_WriteNum("m_bResetParticles", bResetParticles);
	TE_WriteNum("m_bControlPoint1", 1);
	TE_WriteNum("m_ControlPoint1.m_eParticleAttachment", 5);
	TE_WriteFloat("m_ControlPoint1.m_vecOffset[0]", flEndPos[0]);
	TE_WriteFloat("m_ControlPoint1.m_vecOffset[1]", flEndPos[1]);
	TE_WriteFloat("m_ControlPoint1.m_vecOffset[2]", flEndPos[2]);
	TE_SendToAll();
}

stock void ShootLaserEx(int weapon, const char[] strParticle, float flStartPos[3], float flEndPos[3], bool bResetParticles = false, int attachType = 0, int attachment = 0)
{
	int tblidx = FindStringTable("ParticleEffectNames");
	if (tblidx == INVALID_STRING_TABLE)
	{
		LogError("Could not find string table: ParticleEffectNames");
		return;
	}
	char tmp[256];
	int count = GetStringTableNumStrings(tblidx);
	int stridx = INVALID_STRING_INDEX;
	for (int i = 0; i < count; i++)
	{
		ReadStringTable(tblidx, i, tmp, sizeof(tmp));
		if (StrEqual(tmp, strParticle, false))
		{
			stridx = i;
			break;
		}
	}
	if (stridx == INVALID_STRING_INDEX)
	{
		LogError("Could not find particle: %s", strParticle);
		return;
	}

	TE_Start("TFParticleEffect");
	TE_WriteFloat("m_vecOrigin[0]", flStartPos[0]);
	TE_WriteFloat("m_vecOrigin[1]", flStartPos[1]);
	TE_WriteFloat("m_vecOrigin[2]", flStartPos[2]);
	TE_WriteNum("m_iParticleSystemIndex", stridx);
	TE_WriteNum("entindex", weapon);
	TE_WriteNum("m_iAttachType", attachType);
	TE_WriteNum("m_iAttachmentPointIndex", attachment);
	TE_WriteNum("m_bResetParticles", bResetParticles);
	TE_WriteNum("m_bControlPoint1", 1);
	TE_WriteNum("m_ControlPoint1.m_eParticleAttachment", 5);
	TE_WriteFloat("m_ControlPoint1.m_vecOffset[0]", flEndPos[0]);
	TE_WriteFloat("m_ControlPoint1.m_vecOffset[1]", flEndPos[1]);
	TE_WriteFloat("m_ControlPoint1.m_vecOffset[2]", flEndPos[2]);
	TE_SendToAll();
}

stock void CreateParticle(char[] particle, float pos[3], float ang[3])
{
	int tblidx = FindStringTable("ParticleEffectNames");
	char tmp[256];
	int count = GetStringTableNumStrings(tblidx);
	int stridx = INVALID_STRING_INDEX;

	for(int i = 0; i < count; i++)
    {
        ReadStringTable(tblidx, i, tmp, sizeof(tmp));
        if(StrEqual(tmp, particle, false))
        {
            stridx = i;
            break;
        }
    }

	TE_Start("TFParticleEffect");
	TE_WriteFloat("m_vecOrigin[0]", pos[0]);
	TE_WriteFloat("m_vecOrigin[1]", pos[1]);
	TE_WriteFloat("m_vecOrigin[2]", pos[2]);
	TE_WriteVector("m_vecAngles", ang);
	TE_WriteNum("m_iParticleSystemIndex", stridx);
	TE_WriteNum("entindex", -1);
	TE_WriteNum("m_iAttachType", 5);	//Dont associate with any entity
	TE_SendToAll();
}

stock void CreateParticleEx(char[] particle, float pos[3], float ang[3], int ent, int attachType, int attachment)
{
	int tblidx = FindStringTable("ParticleEffectNames");
	char tmp[256];
	int count = GetStringTableNumStrings(tblidx);
	int stridx = INVALID_STRING_INDEX;

	for(int i = 0; i < count; i++)
    {
        ReadStringTable(tblidx, i, tmp, sizeof(tmp));
        if(StrEqual(tmp, particle, false))
        {
            stridx = i;
            break;
        }
    }

	TE_Start("TFParticleEffect");
	TE_WriteFloat("m_vecOrigin[0]", pos[0]);
	TE_WriteFloat("m_vecOrigin[1]", pos[1]);
	TE_WriteFloat("m_vecOrigin[2]", pos[2]);
	TE_WriteVector("m_vecAngles", ang);
	TE_WriteNum("m_iParticleSystemIndex", stridx);
	TE_WriteNum("entindex", ent);
	TE_WriteNum("m_iAttachType", attachType);
	TE_WriteNum("m_iAttachmentPointIndex", attachment);
	TE_SendToAll();
}

//From my plugin Robot Eye Glow
stock int SpawnRobotEye(int client, float eyeColor[3], bool isLeft)
{
	// Create dumb entity to control the RGB color
	char szGlowName[64];
	Format(szGlowName, sizeof(szGlowName), "rbeye_%i", client);
	int iColorEnt = CreateEntityByName("info_particle_system");
	DispatchKeyValue(iColorEnt, "targetname", szGlowName);
	DispatchKeyValueVector(iColorEnt, "origin", eyeColor);
	DispatchSpawn(iColorEnt);

	// Mark cpoint1 with our targetname rbeye_ to apply the RGB color
	int iGlow = CreateEntityByName("info_particle_system");
	DispatchKeyValue(iGlow, "effect_name", "bot_eye_glow");
	DispatchKeyValue(iGlow, "cpoint1", szGlowName);

	SetVariantString("!activator");
	AcceptEntityInput(iGlow, "SetParent", client);

	char szEye1[16], szEye2[16];
	szEye1 = "eye_boss_1";
	szEye2 = "eye_boss_2";

	char szModel[256];
	GetEntPropString(client, Prop_Data, "m_ModelName", szModel, sizeof(szModel));
	if (StrContains(szModel, "bot_heavy.mdl") != -1)
	{
        szEye1 = "eye_1";
        szEye2 = "eye_2";
	}

	SetVariantString(isLeft ? szEye1 : szEye2);
	AcceptEntityInput(iGlow, "SetParentAttachment");

	DispatchSpawn(iGlow);
	ActivateEntity(iGlow);
	AcceptEntityInput(iGlow, "Start");

	// We successfully set the color, we don't need this anymore
	SetVariantString("OnUser1 !self:kill::0.1:1");
	AcceptEntityInput(iColorEnt, "AddOutput");
	AcceptEntityInput(iColorEnt, "FireUser1");

	return iGlow;
}

public Action Cmd_Test(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "Usage: sm_deflectorbot <blue;blu/red/gray;grey;none;neutral> [health] [display health bar 1/0] [custom boss name]");
        return Plugin_Handled;
    }

    char szArg[64], szArg2[64], szArg3[8], szArg4[64];
	GetCmdArg(1, szArg, sizeof(szArg));
	GetCmdArg(2, szArg2, sizeof(szArg2));
	GetCmdArg(3, szArg3, sizeof(szArg3));
	GetCmdArg(4, szArg4, sizeof(szArg4));

	int iHealth = 0;
	int iTeamNum = 0;

    if (StrEqual(szArg, "red", false))
    {
        iTeamNum = 2;
    }
    else if (StrEqual(szArg, "blu", false) || StrEqual(szArg, "blue", false))
    {
        iTeamNum = 3;
    }
    else if (StrEqual(szArg, "gray", false) || StrEqual(szArg, "none", false) || StrEqual(szArg, "grey", false) || StrEqual(szArg, "neutral", false))
    {
        iTeamNum = 0;
    }
    else
    {
        ReplyToCommand(client, "Unknown team \"%s\"", szArg);
        return Plugin_Handled;
    }

    if (szArg2[0] != '\0')
        iHealth = StringToInt(szArg2);

	HeavyRobotBot bot = view_as<HeavyRobotBot>(CreateEntityByName("nb_heavybot"));
	if (bot.index != -1)
	{
        float vecPos[3], vecEyePos[3], angEyes[3];

        GetClientEyeAngles(client, angEyes);
        GetClientEyePosition(client, vecEyePos);

        Handle hTrace = TR_TraceRayFilterEx(vecEyePos, angEyes, MASK_ALL, RayType_Infinite, Filter_WorldOnly, client);
        if (TR_DidHit(hTrace))
        {
            TR_GetEndPosition(vecPos, hTrace);
        }
        delete hTrace;

        bot.Teleport(vecPos);
		bot.SetProp(Prop_Data, "m_iSkill", BOT_SKILL_EXPERT);
		bot.SetProp(Prop_Data, "m_iTeamNum", iTeamNum);
		bot.SetProp(Prop_Data, "m_bDontFearSentries", true);

		if (iHealth > 0)
		{
            bot.SetProp(Prop_Data, "m_iHealth", iHealth);
        }

		bot.Spawn();

		ReplyToCommand(client, "Spawned a Giant Deflector Heavy %i", bot.index);

		#if EXPERIMENT_CAMERA
        int iCamera = CreateEntityByName("prop_dynamic_override");

        if (iCamera > 0)
        {
            DispatchKeyValue(iCamera, "targetname", "gmod_prop2");
            DispatchKeyValue(iCamera, "DisableBoneFollowers", "1");
            //DispatchKeyValue(iCamera, "angles", anglesStr);

            SetEntProp(iCamera, Prop_Send, "m_nSolidType", 6);
            SetEntProp(iCamera, Prop_Data, "m_nSolidType", 6);

            PrecacheModel("models/weapons/c_models/c_bread/c_bread_crumpet.mdl");
            DispatchKeyValue(iCamera, "model", "models/weapons/c_models/c_bread/c_bread_crumpet.mdl");

            //TeleportEntity(iCamera, pos, NULL_VECTOR, NULL_VECTOR);

            DispatchSpawn(iCamera);
        }

        bot.SetPropEnt(Prop_Data, "m_hCamera", iCamera);
        ReplyToCommand(client, "m_hCamera %i", iCamera);
		#endif

		if (StringToInt(szArg3) > 0)
		{
            g_szFakeClientName = "Giant Deflector Heavy";

            if (szArg4[0] != '\0')
                Format(g_szFakeClientName, sizeof(g_szFakeClientName), "%s", szArg4);

            CBotBossHealthbar.SetBossName(g_szFakeClientName);
            CBotBossHealthbar.SetBoss(bot.index);
            //g_iBossHealthbarTargetRef = EntIndexToEntRef(bot.index);
            //CBotBossHealthbar.UpdateBossHealth();
		}
	}
	return Plugin_Handled;
}

public Action Cmd_Test2(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "Usage: sm_smalldeflectorbot <blue;blu/red/gray;grey;none;neutral> [health] [skill level:easy/normal/hard/expert]");
        return Plugin_Handled;
    }

    char szArg[64], szArg2[64], szArg3[8];
	GetCmdArg(1, szArg, sizeof(szArg));
	GetCmdArg(2, szArg2, sizeof(szArg2));
	GetCmdArg(3, szArg3, sizeof(szArg3));

	int iHealth = 0;
	int iTeamNum = 0;

    if (StrEqual(szArg, "red", false))
    {
        iTeamNum = 2;
    }
    else if (StrEqual(szArg, "blu", false) || StrEqual(szArg, "blue", false))
    {
        iTeamNum = 3;
    }
    else if (StrEqual(szArg, "gray", false) || StrEqual(szArg, "none", false) || StrEqual(szArg, "grey", false) || StrEqual(szArg, "neutral", false))
    {
        iTeamNum = 0;
    }
    else
    {
        ReplyToCommand(client, "Unknown team \"%s\"", szArg);
        return Plugin_Handled;
    }

    if (szArg2[0] != '\0')
        iHealth = StringToInt(szArg2);

	HeavyRobotBot bot = view_as<HeavyRobotBot>(CreateEntityByName("nb_heavybot"));
	if (bot.index != -1)
	{
        float vecPos[3], vecEyePos[3], angEyes[3];

        GetClientEyeAngles(client, angEyes);
        GetClientEyePosition(client, vecEyePos);

        Handle hTrace = TR_TraceRayFilterEx(vecEyePos, angEyes, MASK_ALL, RayType_Infinite, Filter_WorldOnly, client);
        if (TR_DidHit(hTrace))
        {
            TR_GetEndPosition(vecPos, hTrace);
        }
        delete hTrace;

        int iSkill = 1;
        if (szArg3[0] != '\0')
        {
            if (StrEqual(szArg3, "easy"))
                iSkill = 0;
            else if (StrEqual(szArg3, "normal"))
                iSkill = 1;
            else if (StrEqual(szArg3, "hard"))
                iSkill = 2;
            else if (StrEqual(szArg3, "expert"))
                iSkill = 3;
        }

        bot.Teleport(vecPos);
		bot.SetProp(Prop_Data, "m_iSkill", iSkill);
		bot.SetProp(Prop_Data, "m_iTeamNum", iTeamNum);
		bot.SetProp(Prop_Data, "m_bDontFearSentries", true);
		bot.SetProp(Prop_Data, "m_bSmallHeavy", true);

		if (iHealth > 0)
		{
            bot.SetProp(Prop_Data, "m_iHealth", iHealth);
        }

		bot.Spawn();

		ReplyToCommand(client, "Spawned a Deflector Heavy %i", bot.index);
	}
	return Plugin_Handled;
}

public Action Cmd_Test3(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "Usage: sm_deflectorbot_spawner <blue;blu/red/gray;grey;none;neutral> [health]");
        return Plugin_Handled;
    }

    char szArg[64], szArg2[64];
	GetCmdArg(1, szArg, sizeof(szArg));
	GetCmdArg(2, szArg2, sizeof(szArg2));

	int iHealth = 0;
	int iTeamNum = 0;

    if (StrEqual(szArg, "red", false))
    {
        iTeamNum = 2;
    }
    else if (StrEqual(szArg, "blu", false) || StrEqual(szArg, "blue", false))
    {
        iTeamNum = 3;
    }
    else if (StrEqual(szArg, "gray", false) || StrEqual(szArg, "none", false) || StrEqual(szArg, "grey", false) || StrEqual(szArg, "neutral", false))
    {
        iTeamNum = 0;
    }
    else
    {
        ReplyToCommand(client, "Unknown team \"%s\"", szArg);
        return Plugin_Handled;
    }

    if (szArg2[0] != '\0')
        iHealth = StringToInt(szArg2);

    float vecPos[3], vecEyePos[3], angEyes[3];

    GetClientEyeAngles(client, angEyes);
    GetClientEyePosition(client, vecEyePos);

    Handle hTrace = TR_TraceRayFilterEx(vecEyePos, angEyes, MASK_ALL, RayType_Infinite, Filter_WorldOnly, client);
    if (TR_DidHit(hTrace))
    {
        TR_GetEndPosition(vecPos, hTrace);
    }
    delete hTrace;

    int iEnt = CTeleporterSpawner.Create(vecPos, NULL_VECTOR, iTeamNum);

    if (iEnt != -1)
    {
        //SetEntProp()
    }

	ReplyToCommand(client, "Spawned a Deflector spawner %i", iEnt);
	return Plugin_Handled;
}

#if EXPERIMENT_CAMERA
public Action Cmd_Test2(int client, int args)
{
    char szArg[64];
	char szArg2[64];

	GetCmdArg(1, szArg, sizeof(szArg));
	GetCmdArg(2, szArg2, sizeof(szArg2));

	int iTargetEnt = StringToInt(szArg);

	SetClientViewEntity(client, iTargetEnt);

	ReplyToCommand(client, "Your client index %i. To restore your camera, use sm_deflectorbot_camera %i", client, client);

	//int iTarget = FindTarget(client, szArg);
	//if (iTarget > 0)
	//{
		//void SetClientViewEntity(int client, int entity)
	//	SetClientViewEntity(iTarget, StringToInt(szArg2));
	//	ReplyToCommand(client, "Set %i to %i", iTarget, StringToInt(szArg2));
	//	ReplyToCommand(client, "To ")
	//}
	return Plugin_Handled;
}
#endif

stock bool IsStringNumeric(const char[] str)
{
    for (int i = 0; i < strlen(str); i++)
    {
        if (!IsCharNumeric(str[i]))
        {
            return false;
        }
    }
    return true;
}
