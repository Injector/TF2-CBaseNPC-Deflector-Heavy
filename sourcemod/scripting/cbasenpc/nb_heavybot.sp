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

        //I know how bad it looks
        EntityFactory.BeginDataMapDesc();
        CNextBotFactory.DefineVisionProps(EntityFactory)
		CNextBotFactory.DefineBodyProps(EntityFactory)
		CNextBotFactory.DefineIntentionProps(EntityFactory)

		EntityFactory
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
            .DefineFloatField("m_flPathTime")
            .DefineBoolField("m_bSmallHeavy")
            .DefineFloatField("m_flUberTimer")
            .DefineEntityField("m_hFollowTarget")

            .DefineEntityField("m_hCamera")
		.EndDataMapDesc();

        /* EntityFactory = new CEntityFactory("nb_heavybot", OnCreate, OnRemove);
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
            .DefineFloatField("m_flPathTime")

            .DefineEntityField("m_hCamera")

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

			.DefineBoolField("m_bOverrideFaceTowards")

			.DefineInputFunc("JoinSquad", InputFuncValueType_Integer, InputJoinSquad)

			.DefineEntityField("m_hSquadLeader")
			.DefineEntityField("m_hSquadRoster", 32)
			.DefineBoolField("m_bSquadHasBrokenFormation")
			.DefineFloatField("m_flSquadFormationError")
        .EndDataMapDesc(); */

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

	property float m_flPathTime
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flPathTime");
		}

		public set(float val)
		{
			this.SetPropFloat(Prop_Data, "m_flPathTime", val);
		}
	}

	property bool m_bSmallHeavy
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_bSmallHeavy");
		}

		public set(bool val)
		{
			this.SetProp(Prop_Data, "m_bSmallHeavy", val);
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
	SDKHook(ent.index, SDKHook_ThinkPost, ThinkPost);

	CBaseNPC_Locomotion loco = npc.GetLocomotion();
	loco.SetCallback(LocomotionCallback_ClimbUpToLedge, LocomotionClimbUpToLedge);
	loco.SetCallback(LocomotionCallback_ShouldCollideWith, LocomotionShouldCollideWith);
	loco.SetCallback(LocomotionCallback_IsEntityTraversable, LocomotionIsEntityTraversable);

	if (ent.m_bSmallHeavy)
	{
		ent.SetModel("models/bots/heavy/bot_heavy.mdl");
		ent.SetProp(Prop_Data, "m_iHealth", 300);
	}
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
		if (CBaseEntity(loco.GetBot().GetEntity()).GetProp(Prop_Send, "m_iTeamNum") == other.GetProp(Prop_Send, "m_iTeamNum"))
			return false;
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

	char szClassName[64];
	obstacle.GetClassname(szClassName, sizeof(szClassName))
	if (StrEqual(szClassName, "func_respawnroomvisualizer") && obstacle.GetProp(Prop_Data, "m_iTeamNum") != CBaseEntity(loco.GetBot().GetEntity()).GetProp(Prop_Data, "m_iTeamNum"))
	{
		return false;
	}

	if (StrEqual(szClassName, "func_door") || StrEqual(szClassName, "func_door_rotating") || StrEqual(szClassName, "func_brush"))
	{
		//Allow go throguh doors and brushes, because it will stuck nextbot otherwise
		return true;
	}

	if (StrEqual(szClassName, "prop_dynamic"))
	{
		//Also allow because he's stupid and getting stuck
		return true;
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

	StopSound(ent.index, SNDCHAN_AUTO, ")weapons/minigun_shoot.wav");
	StopSound(ent.index, SNDCHAN_AUTO, ")weapons/minigun_spin.wav");
}

static void SpawnPost(int entIndex)
{
	HeavyRobotBot ent = HeavyRobotBot(entIndex);

	if (!ent.m_bSmallHeavy)
		ent.SetPropFloat(Prop_Data, "m_flModelScale", StringToFloat(BASE_MODEL_SCALE));

	if (ent.m_bSmallHeavy)
	{
		ent.SetModel("models/bots/heavy/bot_heavy.mdl");
		ent.SetProp(Prop_Data, "m_iHealth", 300);
	}

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

	float flModelScale = BASE_MODEL_SCALE_F;
	if (ent.m_bSmallHeavy)
		flModelScale = 1.0;

	ent.m_hMyWeapon = CBaseEntity(CreateWeapon(ent.index, "models/weapons/w_models/w_minigun.mdl", "head", 8, flModelScale));

	ent.SetProp(Prop_Send, "m_nSkin", ent.GetProp(Prop_Send, "m_iTeamNum") == 2 ? 0 : 1);

	CreateWeapon(ent.index, "models/player/items/mvm_loot/heavy/robo_ushanka.mdl", "head", ent.GetProp(Prop_Send, "m_nSkin"), 1.0);

	ent.SetPropFloat(Prop_Data, "m_flEyePosHeight", 72.0);

	if (ent.m_bSmallHeavy)
		ent.SetPropFloat(Prop_Data, "m_flEyePosHeight", 25.0);

	float vecEyeColor[3] = { 0.0, 240.0, 255.0 };
	if (ent.GetProp(Prop_Send, "m_iTeamNum") == 2)
		vecEyeColor = { 255.0, 0.0, 0.0 };
	if (ent.GetProp(Prop_Data, "m_iSkill") > BOT_SKILL_NORMAL)
		vecEyeColor = { 255.0, 180.0, 36.0 };
	SpawnRobotEye(ent.index, vecEyeColor, false);
	SpawnRobotEye(ent.index, vecEyeColor, true);

	INextBot nextBot = ent.MyNextBotPointer();

	//game/shared/tf/tf_gamerules.h - DefaultFOV()
	CBotVision(nextBot.GetVisionInterface()).SetFieldOfViewEx(75.0);

	if (!ent.m_bSmallHeavy)
		EmitSoundToAll("mvm/giant_heavy/giant_heavy_loop.wav", ent.index, SNDCHAN_AUTO, 83, _, 0.8);

	//float vecMins[3], vecMaxs[3];
	//ent.GetPropVector(Prop_Send, "m_vecMins", vecMins);
	//ent.GetPropVector(Prop_Send, "m_vecMaxs", vecMaxs);
	//ScaleVector(vecMins, BASE_MODEL_SCALE_F);
	//ScaleVector(vecMaxs, BASE_MODEL_SCALE_F);
	//ent.SetPropVector(Prop_Send, "m_vecMins", vecMins);
	//ent.SetPropVector(Prop_Send, "m_vecMaxs", vecMaxs);

	//It doesn't work here... why?
	//Works only if we use SDKHook OnSpawnPost
	//float vecMins[3] = {-40.0, -40.0, 0.0};
	//float vecMaxs[3] = {40.0, 40.0, 155.0};

    //ent.SetPropVector(Prop_Send, "m_vecMins", vecMins);
    //ent.SetPropVector(Prop_Send, "m_vecMaxs", vecMaxs);

    //TeleportEntity(entIndex, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR);
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

		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;

		bool bAddThreat = nextBot.GetVisionInterface().IsAbleToSeeTarget(i, DISREGARD_FOV) && !IsClientFriendlyKostyl(i) && GetClientTeam(i) != ent.GetProp(Prop_Send, "m_iTeamNum");

		if (bAddThreat)
		{
			if (g_CVar_fair_fight.BoolValue && !CTFBotIntention(nextBot.GetIntentionInterface()).IsThreatOnNav(i))
				bAddThreat = false;
			if (g_CVar_use_fov.BoolValue && !CBotVision(nextBot.GetVisionInterface()).IsInFieldOfViewTargetEx(i))
				bAddThreat = false;
			if (!g_CVar_spy_cloak_visible.BoolValue && TF2_IsPlayerInCondition(i, TFCond_Cloaked))
				bAddThreat = false;
			if (!g_CVar_spy_mechanics_ignore.BoolValue && CBot.IgnoreSpy(ent.index, i))
				bAddThreat = false;
		}

		if (bAddThreat)
		{
			nextBot.GetVisionInterface().AddKnownEntity(i);
		}
	}

	//TODO: Replace with * to include the other nextbots as enemies
	int iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt, "obj_sentrygun")) != INVALID_ENT_REFERENCE)
	{
		if (nextBot.GetVisionInterface().IsAbleToSeeTarget(iEnt, DISREGARD_FOV))
			nextBot.GetVisionInterface().AddKnownEntity(iEnt);
	}

	//OnContact doens't work for some reason...
	iEnt = -1;
	char szClassName[64];
	float vecMyPos[3], vecEntPos[3];
	ent.GetPropVector(Prop_Send, "m_vecOrigin", vecMyPos);
	while ((iEnt = FindEntityByClassname(iEnt, "obj_*")) != INVALID_ENT_REFERENCE)
	{
		GetEntityClassname(iEnt, szClassName, sizeof(szClassName));
		if ((StrEqual(szClassName, "obj_teleporter") || StrEqual(szClassName, "obj_dispenser") || StrEqual(szClassName, "obj_sentrygun") && GetEntProp(iEnt, Prop_Send, "m_bMiniBuilding") == 1) && ent.GetProp(Prop_Send, "m_iTeamNum") != GetEntProp(iEnt, Prop_Send, "m_iTeamNum"))
		{
			GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", vecEntPos);
			if (GetVectorDistance(vecMyPos, vecEntPos) <= 150)
			{
				int iHealth = GetEntProp(iEnt, Prop_Send, "m_iHealth");
				int iMaxHealth = GetEntProp(iEnt, Prop_Data, "m_iMaxHealth");

				if (iHealth > iMaxHealth)
					iMaxHealth = iHealth;

				iMaxHealth *= 2;

				SetVariantInt(iMaxHealth);
				AcceptEntityInput(iEnt, "RemoveHealth");
			}
		}
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
	{
		CTFBotBody(bot.GetBodyInterface()).Upkeep();
		if (ent.HasProp(Prop_Data, "m_bOverrideFaceTowards"))
        {
            ent.SetProp(Prop_Data, "m_bOverrideFaceTowards", 1);
        }
	}
	else if (g_CVar_aim.IntValue == 1)
	{
		CBotBody(bot.GetBodyInterface()).Upkeep();
		if (ent.HasProp(Prop_Data, "m_bOverrideFaceTowards"))
        {
            ent.SetProp(Prop_Data, "m_bOverrideFaceTowards", 0);
        }
	}

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

	CTFBotIntention(bot.GetIntentionInterface()).UpdateDelayedThreatNotices();

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;

		bool bForget = false;
		if (g_CVar_fair_fight.BoolValue && !CTFBotIntention(bot.GetIntentionInterface()).IsThreatOnNav(i))
		{
			bForget = true;
		}
		if (!g_CVar_spy_mechanics_ignore.BoolValue && CBot.IgnoreSpy(ent.index, i))
		{
			bForget = true;
		}

		if (bForget)
			bot.GetVisionInterface().ForgetEntity(i);

		/* if (IsClientInGame(i) && IsPlayerAlive(i) && g_CVar_fair_fight.BoolValue && !CTFBotIntention(bot.GetIntentionInterface()).IsThreatOnNav(i))
		{
			bot.GetVisionInterface().ForgetEntity(i);
		} */
	}

	if (!g_CVar_spy_cloak_visible.BoolValue)
		CBot.HandleSpyMemoryLogic(entIndex);

	if (ent.GetPropFloat(Prop_Data, "m_flUberTimer") > GetGameTime())
	{
		ent.SetProp(Prop_Send, "m_nSkin", ent.GetProp(Prop_Send, "m_iTeamNum") == 2 ? 2 : 3);
	}
	else
	{
		ent.SetProp(Prop_Send, "m_nSkin", ent.GetProp(Prop_Send, "m_iTeamNum") == 2 ? 0 : 1);
	}

	//if (EntRefToEntIndex(g_iBossHealthbarRef) == entIndex)
	//{
	//	CBotBossHealthbar.UpdateBossHealth();
	//}

	#if EXPERIMENT_CAMERA
	if (ent.HasProp(Prop_Data, "m_hCamera"))
	{
		int iCamera = ent.GetPropEnt(Prop_Data, "m_hCamera");
		if (iCamera > 0)
		{
			float vecPos[3], angEye[3];
			CBotBody(bot.GetBodyInterface()).GetEyePositionEx(vecPos);
			ent.GetPropVector(Prop_Data, "m_angCurrentAngles", angEye);
			TeleportEntity(iCamera, vecPos, angEye, NULL_VECTOR);
		}
	}
	#endif

	//CBotDebug(bot).DebugLookAt();
}

//https://github.com/TF2-DMB/CBaseNPC/blob/f2af3f7b74af2d20cf5f673565cb31a887835fb8/extension/cbasenpc_internal.cpp#L157

//CBaseNPC thinks every 0.06 second, this screws CTFBotBody aim speed a lot (nextbots with easy/normal/hard tracking is awful and slow because of that). So we set to think every 0.01 second
//TODO: This affects weapon firerate and fl timers because of that. Dunno if it good or bad
//TODO: Affects a nextbot moving speed? I think he's moving a little bit faster
//TODO: Affects a jump height, he's jumping very high now if he's stuck
//TODO: Check server performance with a lot of nextbots because of changed think frequency rate
//TODO: Instead of changing think update rate, we can create timer that runs 0.01 and loop through all nextbots to call Upkeep()
//TODO: Or we can create seperate entity that thinks every 0.01 seconds and loop through all nextbots and call Upkeep()? (dummy base_boss in 0,0,0 for example)
static void ThinkPost(int entIndex)
{
	CBaseEntity(entIndex).SetNextThink(GetGameTime() + 0.01);
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

	//Projectile still hooks OnTakeDamage, even in same teams
	if (GetEntProp(attacker, Prop_Send, "m_iTeamNum") == GetEntProp(victim, Prop_Send, "m_iTeamNum"))
		return Plugin_Stop;

	if (GetEntPropEnt(victim, Prop_Data, "m_hForcedTarget") != -1 && GetEntPropEnt(victim, Prop_Data, "m_hForcedTarget") != attacker)
		return Plugin_Stop;

	if (GetEntPropFloat(victim, Prop_Data, "m_flUberTimer") > GetGameTime())
		return Plugin_Stop;

	if (damagecustom == TF_CUSTOM_BACKSTAB)
	{
		CTFBotIntention(CBaseEntity(victim).MyNextBotPointer().GetIntentionInterface()).DelayedThreatNotice(attacker, 0.5);
	}
	else if (damagetype & DMG_CRIT && damagetype & DMG_BURN)
	{
		if (CBaseEntity(victim).MyNextBotPointer().GetRangeTo(attacker) < 750)
			CTFBotIntention(CBaseEntity(victim).MyNextBotPointer().GetIntentionInterface()).DelayedThreatNotice(attacker, 0.5);
	}
	else
	{
		if (CBaseEntity(victim).MyNextBotPointer().GetVisionInterface().GetKnown(attacker) == NULL_KNOWN_ENTITY)
			CBaseEntity(victim).MyNextBotPointer().GetVisionInterface().AddKnownEntity(attacker);
	}

	//float flMinRange = 100.0;
	//float flMaxRange = 750.0;
	//float flDeltaRange = flMaxRange - flMinRange;

	//int iNoticeChance = 25;

	return Plugin_Continue;
}

static void InputJoinSquad(HeavyRobotBot ent, CBaseEntity activator, CBaseEntity caller, int value)
{

}
