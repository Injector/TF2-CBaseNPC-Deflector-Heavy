#include "nb_heavybot/behaviour.sp"

static CEntityFactory EntityFactory

methodmap HeavyRobotBot < CBaseCombatCharacter
{
    public HeavyRobotBot(int ent)
    {
        return view_as<HeavyRobotBot>(ent);
    }

    public static void Initialize()
    {
        InitBehaviours();

        EntityFactory = new CEntityFactory("nb_heavybot", OnCreate, OnRemove);
        EntityFactory.DeriveFromNPC();
        EntityFactory.SetInitialActionFactory(HeavyRobotBotMainAction.GetFactory());
        EntityFactory.BeginDataMapDesc()
            .DefineIntField("m_idleSequence")
            .DefineIntField("m_runSequence")
            .DefineFloatField("m_flNextPrimaryAttack")
            .DefineFloatField("m_flNextSecondaryAttack")
            .DefineFloatField("m_flWeaponIdleTime")
            .DefineIntField("m_iWeaponState")
            .DefineIntField("m_iMinigunSound")
            .DefineIntField("m_iWeaponMode")
            .DefineEntityField("m_hMuzzleEffect")
            .DefineEntityField("m_hMyWeapon")
            .DefineFloatField("m_flNextWalkTime")
            .DefineFloatField("m_flFireRate")
            .DefineFloatField("m_flNextPainSound")
            .DefineIntField("m_iWeaponDamage")
            .DefineIntField("m_runPrimarySequence")
            .DefineIntField("m_standPrimarySequence")
            .DefineIntField("m_runDeployedSequence")
            .DefineIntField("m_standDeployedSequence")
            .DefineIntField("m_windUpGestureSequence")
            .DefineIntField("m_windDownGestureSequence")
            .DefineIntField("m_moveXPoseParameter")
            .DefineIntField("m_moveYPoseParameter")
            .DefineEntityField("m_hForcedTarget")

			.DefineIntField("m_iSkill")
            .DefineEntityField("m_hTarget")
			.DefineFloatField("m_flTimeSinceVisibleThreats", 4)
			.DefineBoolField("m_bDontFearSentries", 1, "dontfearsentries")
			.DefineFloatField("m_flNoisyTime")
			.DefineFloatField("m_flNextScanEnemies")
			.DefineFloatField("m_flTCRandom")
			.DefineFloatField("m_flNextRandomTime")
			.DefineIntField("m_iNumOfFailedTraces")
			.DefineFloatField("m_flEyePosHeight")

			.DefineFloatField("m_flFOV")
			.DefineFloatField("m_flCosHalfFOV")

			.DefineVectorField("m_angCurrentAngles")
			.DefineVectorField("m_angPriorAngles")
			.DefineFloatField("m_flHeadSteadyTimer")
			.DefineBoolField("m_bHasBeenSightedIn")
			.DefineFloatField("m_flAnchorRepositionTimer")
			.DefineFloatField("m_flLookAtExpireTimer")
			.DefineVectorField("m_vecAnchorForward")
			.DefineFloatField("m_flLookAtTrackingTimer")
			.DefineVectorField("m_vecLookAtPos")
			.DefineVectorField("m_vecLookAtVelocity")
			.DefineFloatField("m_flLookAtDurationTimer")
			.DefineBoolField("m_bIsSightedIn")
			.DefineIntField("m_iLookAtPriority")
			.DefineEntityField("m_hLookAtSubject")

			.DefineInputFunc("JoinSquad", InputFuncValueType_Integer, InputJoinSquad)

			.DefineEntityField("m_hSquadLeader")
			.DefineEntityField("m_hSquadRoster", 32)
			.DefineBoolField("m_bSquadHasBrokenFormation")
			.DefineFloatField("m_flSquadFormationError")
        .EndDataMapDesc();

        EntityFactory.Install();
    }

	property CBaseEntity m_hMyWeapon
	{
		public get()
		{
			return CBaseEntity(this.GetPropEnt(Prop_Data, "m_hMyWeapon"));
		}

		public set(CBaseEntity ent)
		{
			this.SetPropEnt(Prop_Data, "m_hMyWeapon", ent.index);
		}
	}

	property int m_iSkill
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iSkill");
		}

		public set(int val)
		{
			this.SetProp(Prop_Data, "m_iSkill", val);
		}
	}

	property float m_flNextWalkTime
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flNextWalkTime");
		}

		public set(float val)
		{
			this.SetPropFloat(Prop_Data, "m_flNextWalkTime", val);
		}
	}

	property float m_flNextPrimaryAttack
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flNextPrimaryAttack");
		}

		public set(float val)
		{
			this.SetPropFloat(Prop_Data, "m_flNextPrimaryAttack", val);
		}
	}

	property float m_flNextSecondaryAttack
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flNextSecondaryAttack");
		}

		public set(float val)
		{
			this.SetPropFloat(Prop_Data, "m_flNextSecondaryAttack", val);
		}
	}

	property int m_iWeaponState
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iWeaponState");
		}

		public set(int val)
		{
			this.SetProp(Prop_Data, "m_iWeaponState", val);
		}
	}

	property int m_iWeaponMode
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iWeaponMode");
		}

		public set(int val)
		{
			this.SetProp(Prop_Data, "m_iWeaponMode", val);
		}
	}

	property int m_iMinigunSound
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iMinigunSound");
		}

		public set(int val)
		{
			this.SetProp(Prop_Data, "m_iMinigunSound", val);
		}
	}

	property CBaseEntity m_hMuzzleEffect
	{
		public get()
		{
			return CBaseEntity(this.GetPropEnt(Prop_Data, "m_hMuzzleEffect"));
		}

		public set(CBaseEntity ent)
		{
			this.SetPropEnt(Prop_Data, "m_hMuzzleEffect", ent.index);
		}
	}

	property int m_iWeaponDamage
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iWeaponDamage");
		}

		public set(int val)
		{
			this.SetProp(Prop_Data, "m_iWeaponDamage", val);
		}
	}

	property float m_flFireRate
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flFireRate");
		}

		public set(float val)
		{
			this.SetPropFloat(Prop_Data, "m_flFireRate", val);
		}
	}

	property float m_flWeaponIdleTime
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flWeaponIdleTime");
		}

		public set(float val)
		{
			this.SetPropFloat(Prop_Data, "m_flWeaponIdleTime", val);
		}
	}
}

static void InitBehaviours()
{
    HeavyRobotBotMainAction.Initialize();
    HeavyRobotBotDeathAction.Initialize();
}

static void OnCreate(HeavyRobotBot ent)
{
	ent.SetModel("models/bots/heavy_boss/bot_heavy_boss.mdl");

	ent.SetProp(Prop_Data, "m_iHealth", BASE_HEALTH);
	ent.SetProp(Prop_Data, "m_idleSequence", -1);
	ent.SetProp(Prop_Data, "m_runSequence", -1);
	ent.SetPropFloat(Prop_Data, "m_flNextPainSound", GetGameTime());
	ent.SetProp(Prop_Data, "m_iWeaponDamage", 8);
	ent.SetPropFloat(Prop_Data, "m_flFireRate", 0.1);
	ent.SetProp(Prop_Data, "m_bloodColor", 3);

	CBaseNPC npc = TheNPCs.FindNPCByEntIndex(ent.index);

	npc.flStepSize = 18.0;
	npc.flGravity = 800.0;
	npc.flAcceleration = 2000.0;
	npc.flJumpHeight = 85.0;
	npc.flWalkSpeed = BASE_SPEED;
	npc.flRunSpeed = BASE_SPEED;
	npc.flDeathDropHeight = 2000.0;
	npc.flMaxYawRate = 250.0;

	SDKHook(ent.index, SDKHook_SpawnPost, SpawnPost);
	SDKHook(ent.index, SDKHook_Think, Think);
	SDKHook(ent.index, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(ent.index, SDKHook_OnTakeDamageAlivePost, OnTakeDamageAlivePost);

	CBaseNPC_Locomotion loco = npc.GetLocomotion();
	loco.SetCallback(LocomotionCallback_ClimbUpToLedge, LocomotionClimbUpToLedge);
	loco.SetCallback(LocomotionCallback_ShouldCollideWith, LocomotionShouldCollideWith);
	loco.SetCallback(LocomotionCallback_IsEntityTraversable, LocomotionIsEntityTraversable);
}

static bool LocomotionClimbUpToLedge(CBaseNPC_Locomotion loco, const float goal[3], const float fwd[3], int entity)
{
	float feet[3];
	loco.GetFeet(feet);

	if (GetVectorDistance(feet, goal) > loco.GetDesiredSpeed())
	{
		//return false;
	}

	return loco.CallBaseFunction(goal, fwd, entity);
}

static bool LocomotionShouldCollideWith(CBaseNPC_Locomotion loco, CBaseEntity other)
{
	if (other.index > 0 && other.index <= MaxClients)
	{
		return true;
	}

	if (CEntityFactory.GetFactoryOfEntity(other.index) == EntityFactory)
	{
		//return true;
	}

	return loco.CallBaseFunction(other);
}

static bool LocomotionIsEntityTraversable(CBaseNPC_Locomotion loco, CBaseEntity obstacle, TraverseWhenType when)
{
	if (CEntityFactory.GetFactoryOfEntity(obstacle.index) == EntityFactory)
	{
		//return false;
	}

	return loco.CallBaseFunction(obstacle, when);
}

static void OnRemove(HeavyRobotBot ent)
{
	StopSound(ent.index, SNDCHAN_AUTO, "mvm/giant_heavy/giant_heavy_gunfire.wav");
	StopSound(ent.index, SNDCHAN_AUTO, "mvm/giant_heavy/giant_heavy_gunspin.wav");
	StopSound(ent.index, SNDCHAN_AUTO, ")mvm/giant_heavy/giant_heavy_gunfire.wav");
	StopSound(ent.index, SNDCHAN_AUTO, ")mvm/giant_heavy/giant_heavy_gunspin.wav");
	StopSound(ent.index, SNDCHAN_AUTO, "mvm/giant_heavy/giant_heavy_loop.wav");
}

static void SpawnPost(int entIndex)
{
	HeavyRobotBot ent = HeavyRobotBot(entIndex);

	ent.SetPropFloat(Prop_Data, "m_flModelScale", StringToFloat(BASE_MODEL_SCALE));

	ent.SetProp(Prop_Data, "m_runPrimarySequence", CBaseAnimating(ent.index).LookupSequence("Run_PRIMARY"));
	ent.SetProp(Prop_Data, "m_standPrimarySequence", CBaseAnimating(ent.index).LookupSequence("Stand_PRIMARY"));
	ent.SetProp(Prop_Data, "m_runDeployedSequence", CBaseAnimating(ent.index).LookupSequence("PRIMARY_Deployed_Movement"));
	ent.SetProp(Prop_Data, "m_standDeployedSequence", CBaseAnimating(ent.index).LookupSequence("Stand_Deployed_PRIMARY"));
	ent.SetProp(Prop_Data, "m_windUpGestureSequence", CBaseAnimating(ent.index).LookupSequence("layer_attackstand_primary_spoolup"));
	ent.SetProp(Prop_Data, "m_windDownGestureSequence", CBaseAnimating(ent.index).LookupSequence("layer_attackStand_PRIMARY_spooldown"));

	ent.SetProp(Prop_Data, "m_idleSequence", ent.GetProp(Prop_Data, "m_standPrimarySequence"));
	ent.SetProp(Prop_Data, "m_runSequence", ent.GetProp(Prop_Data, "m_runPrimarySequence"));
	ent.SetProp(Prop_Data, "m_moveXPoseParameter", ent.LookupPoseParameter("move_x"));
	ent.SetProp(Prop_Data, "m_moveYPoseParameter", ent.LookupPoseParameter("move_y"));

	ent.m_hMyWeapon = CBaseEntity(CreateWeapon(ent.index, "models/weapons/w_models/w_minigun.mdl", "head", 8, BASE_MODEL_SCALE_F));

	ent.SetProp(Prop_Send, "m_nSkin", ent.GetProp(Prop_Send, "m_iTeamNum") == 2 ? 0 : 1);

	CreateWeapon(ent.index, "models/player/items/mvm_loot/heavy/robo_ushanka.mdl", "head", ent.GetProp(Prop_Send, "m_nSkin"), 1.0);

	ent.SetPropFloat(Prop_Data, "m_flEyePosHeight", 72.0);

	float vecEyeColor[3] = { 0.0, 240.0, 255.0 };
	if (ent.GetProp(Prop_Data, "m_iSkill") > BOT_SKILL_NORMAL)
		vecEyeColor = { 255.0, 180.0, 36.0 };
	SpawnRobotEye(ent.index, vecEyeColor, false);
	SpawnRobotEye(ent.index, vecEyeColor, true);

	INextBot nextBot = ent.MyNextBotPointer();

	//game/shared/tf/tf_gamerules.h - DefaultFOV()
	CBotVision(nextBot.GetVisionInterface()).SetFieldOfViewEx(75.0);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && nextBot.GetVisionInterface().IsAbleToSeeTarget(i, DISREGARD_FOV) && !IsClientFriendlyKostyl(i) && GetClientTeam(i) != ent.GetProp(Prop_Send, "m_iTeamNum"))
		{
			nextBot.GetVisionInterface().AddKnownEntity(i);
		}
	}

	EmitSoundToAll("mvm/giant_heavy/giant_heavy_loop.wav", ent.index, SNDCHAN_AUTO, 83, _, 0.8);

	float vecMins[3], vecMaxs[3];
	ent.GetPropVector(Prop_Send, "m_vecMins", vecMins);
	ent.GetPropVector(Prop_Send, "m_vecMaxs", vecMaxs);
	ScaleVector(vecMins, BASE_MODEL_SCALE_F);
	ScaleVector(vecMaxs, BASE_MODEL_SCALE_F);
	ent.SetPropVector(Prop_Send, "m_vecMins", vecMins);
	ent.SetPropVector(Prop_Send, "m_vecMaxs", vecMaxs);
}

static void UpdateTarget(HeavyRobotBot ent)
{
	if (ent.GetPropFloat(Prop_Data, "m_flNextScanEnemies") > GetGameTime())
		return;

	INextBot nextBot = ent.MyNextBotPointer();

	for (int i = 1; i <= MaxClients; i++)
	{
        if (GetClientOfUserId(g_iFakeClientUserId) > 0 && GetClientOfUserId(g_iFakeClientUserId) == i)
            continue;
		if (IsClientInGame(i) && IsPlayerAlive(i) && nextBot.GetVisionInterface().IsAbleToSeeTarget(i, DISREGARD_FOV) && !IsClientFriendlyKostyl(i) && GetClientTeam(i) != ent.GetProp(Prop_Send, "m_iTeamNum"))
		{
			//If you a hiding on a building floor, come down and fight like a man!
			//There is AI flawn that I don't know how to fix: AI will try to reach and kill threat even if threat is not reachable
			//Since our threat is close (< 500 hammer units) and because of IsImmediateThreat, nextbot will only target that hiding player, instead of killing another players, if both hiding threat and a reachable threat will shoot our nextbot, nextbot will stand like an idiot
			if (g_CVar_fair_fight.BoolValue && CTFBotIntention(nextBot.GetIntentionInterface()).IsThreatOnNav(i) || !g_CVar_fair_fight.BoolValue)
			{
				if (g_CVar_use_fov.BoolValue && CBotVision(nextBot.GetVisionInterface()).IsInFieldOfViewTargetEx(i) || !g_CVar_use_fov.BoolValue)
					nextBot.GetVisionInterface().AddKnownEntity(i);
			}
			//IsClientInGame(i) && IsPlayerAlive(i) && nextBot.GetVisionInterface().IsAbleToSeeTarget(i, DISREGARD_FOV) && !IsClientFriendlyKostyl(i) && GetClientTeam(i) != ent.GetProp(Prop_Send, "m_iTeamNum") && (g_CVar_fair_fight.BoolValue && CTFBotIntention(nextBot.GetIntentionInterface()).IsThreatOnNav(i) || !g_CVar_fair_fight.BoolValue) && (g_CVar_use_fov.BoolValue && CBotVision(nextBot.GetVisionInterface()).IsInFieldOfViewEx(i) || !g_CVar_use_fov.BoolValue)
		}
	}

	int iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt, "obj_sentrygun")) != INVALID_ENT_REFERENCE)
	{
		if (nextBot.GetVisionInterface().IsAbleToSeeTarget(iEnt, DISREGARD_FOV))
			nextBot.GetVisionInterface().AddKnownEntity(iEnt);
	}

	//For some reason, it automatictly add some known entities that we don't want to know (friendly players)
	//I don't know why and how, I double checked everything
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && (IsClientFriendlyKostyl(i) || g_CVar_fair_fight.BoolValue && !CTFBotIntention(nextBot.GetIntentionInterface()).IsThreatOnNav(i)))
		{
			nextBot.GetVisionInterface().ForgetEntity(i);
		}
	}

	ent.SetPropFloat(Prop_Data, "m_flNextScanEnemies", GetGameTime() + 0.2);
}

static void Think(int entIndex)
{
	HeavyRobotBot ent = HeavyRobotBot(entIndex);
	INextBot bot = ent.MyNextBotPointer();

	UpdateTarget(ent);

	if (g_CVar_aim.IntValue == 0)
		CTFBotBody(bot.GetBodyInterface()).Upkeep();
	else if (g_CVar_aim.IntValue == 1)
		CBotBody(bot.GetBodyInterface()).Upkeep();

	CBotBody(bot.GetBodyInterface()).UpdateBodyPitchYaw();
	CBotBody(bot.GetBodyInterface()).UpdateAnimationXY();

	if (ent.HasProp(Prop_Data, "m_flTimeSinceVisibleThreats"))
	{
		CKnownEntity hKnownEntity = bot.GetVisionInterface().GetPrimaryKnownThreat(false);
		if (hKnownEntity != NULL_KNOWN_ENTITY && !hKnownEntity.IsObsolete() && bot.GetVisionInterface().IsAbleToSeeTarget(hKnownEntity.GetEntity(), DISREGARD_FOV))
		{
			int iTeamNum = GetEntProp(hKnownEntity.GetEntity(), Prop_Data, "m_iTeamNum");
			if (iTeamNum < 4)
			{
				ent.SetPropFloat(Prop_Data, "m_flTimeSinceVisibleThreats", GetGameTime(), iTeamNum);
			}
		}
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && g_CVar_fair_fight.BoolValue && !CTFBotIntention(bot.GetIntentionInterface()).IsThreatOnNav(i))
		{
			bot.GetVisionInterface().ForgetEntity(i);
		}
		if (IsClientInGame(i) && IsPlayerAlive(i) && CheckCommandAccess(i, "sm_rcon", ADMFLAG_RCON))
		{
			//CBotVision(bot.GetVisionInterface()).IsInFieldOfViewTargetEx(i);
		}
	}

	//CBotDebug(bot).DebugLookAt();
}

static void OnTakeDamageAlivePost(int entIndex,
	int attacker,
	int inflictor,
	float damage,
	int damagetype,
	int weapon,
	const float damageForce[3],
	const float damagePosition[3], int damageCustom)
{
    if (attacker > MaxClients)
	{
        char szClassName[64];
        GetEntityClassname(attacker, szClassName, sizeof(szClassName));
        //No friendly fire
        if (StrEqual(szClassName, "nb_heavybot"))
            return;
	}
	HeavyRobotBot ent = HeavyRobotBot(entIndex);
	int health = ent.GetProp(Prop_Data, "m_iHealth");

	Event event = CreateEvent("npc_hurt");
	if (event)
	{
		event.SetInt("entindex", entIndex);
		event.SetInt("health", health > 0 ? health : 0);
		event.SetInt("damageamount", RoundToFloor(damage));
		event.SetBool("crit", ( damagetype & DMG_ACID ) ? true : false);

		if (attacker > 0 && attacker <= MaxClients)
		{
			event.SetInt("attacker_player", GetClientUserId(attacker));
			event.SetInt("weaponid", 0);
		}
		else
		{
			event.SetInt("attacker_player", 0);
			event.SetInt("weaponid", 0);
		}

		event.Fire();
	}

	if (health > 0)
	{
		if (GetGameTime() >= ent.GetPropFloat(Prop_Data, "m_flNextPainSound"))
		{
			ent.SetPropFloat(Prop_Data, "m_flNextPainSound", GetGameTime() + 1.0);

			EmitSoundToAll(g_szPainSounds[GetRandomInt(0, sizeof(g_szPainSounds) - 1)], entIndex, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
		}

		CTFBotIntention.OnSentryGunFired(attacker);

		float vecPos[3]; GetEntPropVector(entIndex, Prop_Data, "m_vecAbsOrigin", vecPos);
		float angRot[3]; GetEntPropVector(entIndex, Prop_Data, "m_angRotation", angRot);
		CreateParticle("bot_impact_heavy", vecPos, angRot);
	}
}

static Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (attacker > 0 && GetEntProp(attacker, Prop_Send, "m_iTeamNum") == GetEntProp(victim, Prop_Send, "m_iTeamNum"))
		return Plugin_Stop;
	if (attacker > 0 && attacker <= MaxClients)
	{
		if (IsClientFriendlyKostyl(attacker))
			return Plugin_Stop;
	}

	//Come down and fight like a man!
	if (g_CVar_fair_fight.BoolValue && !CTFBotIntention(CBaseEntity(victim).MyNextBotPointer().GetIntentionInterface()).IsThreatOnNav(attacker))
		return Plugin_Stop;

	if (attacker > MaxClients)
	{
        char szClassName[64];
        GetEntityClassname(attacker, szClassName, sizeof(szClassName));
        //No friendly fire
        if (StrEqual(szClassName, "nb_heavybot"))
            return Plugin_Stop;
	}
	return Plugin_Continue;
}

static void InputJoinSquad(HeavyRobotBot ent, CBaseEntity activator, CBaseEntity caller, int value)
{

}
