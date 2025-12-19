static NextBotActionFactory ActionFactory;

methodmap HeavyRobotBotMainAction < NextBotAction
{
	public static void Initialize()
	{
		ActionFactory = new NextBotActionFactory("HeavyRobotMainAction");
		ActionFactory.BeginDataMapDesc()
			.DefineIntField("m_PathFollower")
		.EndDataMapDesc();
		ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
		ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
		ActionFactory.SetCallback(NextBotActionCallbackType_OnEnd, OnEnd);
		ActionFactory.SetEventCallback(EventResponderType_OnInjured, OnInjured);
		ActionFactory.SetEventCallback(EventResponderType_OnKilled, OnKilled);
		ActionFactory.SetQueryCallback(ContextualQueryType_SelectMoreDangerousThreat, SelectMoreDangerousThreat);
	}

	public static NextBotActionFactory GetFactory()
	{
		return ActionFactory;
	}

	public HeavyRobotBotMainAction()
	{
		return view_as<HeavyRobotBotMainAction>(ActionFactory.Create());
	}

	property ChasePath m_PathFollower
	{
		public get()
		{
			return view_as<ChasePath>(this.GetData("m_PathFollower"));
		}

		public set(ChasePath value)
		{
			this.SetData("m_PathFollower", value);
		}
	}
}

static void OnStart(HeavyRobotBotMainAction action, HeavyRobotBot actor, NextBotAction prevAction)
{
	action.m_PathFollower = ChasePath(LEAD_SUBJECT, _, Path_FilterIgnoreActors, Path_FilterOnlyActors);
}

static int Update(HeavyRobotBotMainAction action, HeavyRobotBot actor, float interval)
{
	float vecPos[3];
	actor.GetAbsOrigin(vecPos);

	CBaseNPC hNPC = TheNPCs.FindNPCByEntIndex(actor.index);

	// For some reason I get sometimes "Native called with INVALID_NPC index" error, how?
	if (hNPC == INVALID_NPC)
	{
		return action.Continue();
	}
	NextBotGroundLocomotion loco = hNPC.GetLocomotion();
	INextBot bot = hNPC.GetBot();

	CBaseEntity hTarget = CBaseEntity(-1);
	int iThreatEnt = -1;

	CKnownEntity hKnownEntity = hNPC.GetVision().GetPrimaryKnownThreat(false);
	if (hKnownEntity != NULL_KNOWN_ENTITY && !hKnownEntity.IsObsolete())
	{
		hTarget = CBaseEntity(hKnownEntity.GetEntity());
		iThreatEnt = hKnownEntity.GetEntity();
		CBotBody(bot.GetBodyInterface()).AimHeadTowards(hKnownEntity.GetEntity());
	}
	else
	{
		CBotBody(bot.GetBodyInterface()).AimHeadTowards(-1);
	}

	if (actor.GetPropEnt(Prop_Data, "m_hForcedTarget") > 0)
	{
		iThreatEnt = actor.GetPropEnt(Prop_Data, "m_hForcedTarget");
		hTarget = CBaseEntity(actor.GetPropEnt(Prop_Data, "m_hForcedTarget"));
		CBotBody(bot.GetBodyInterface()).AimHeadTowards(iThreatEnt);
	}

	if (hTarget.IsValid())
	{
		float vecTargetPos[3];
		hTarget.GetAbsOrigin(vecTargetPos);

		float flDist = GetVectorDistance(vecTargetPos, vecPos);

		loco.FaceTowards(vecTargetPos);

		//TODO: IsAbleToSeeTarget and IsLineOfSightClearToEntity doesn't take in account that we have large model
		bool bSeeTarget = bot.GetVisionInterface().IsAbleToSeeTarget(hTarget.index, DISREGARD_FOV) && bot.GetVisionInterface().IsLineOfSightClearToEntity(hTarget.index);
		bool bCanShoot = flDist < 1300.0;
		bool bShouldMoveToTarget = !bSeeTarget || flDist > 900.0;

		//PrintCenterTextAll("IsAbleToSeeTarget %b IsLineOfSightClearToEntity %b IsAbleToSee %b Aimed %b", bot.GetVisionInterface().IsAbleToSeeTarget(hTarget.index, DISREGARD_FOV), bot.GetVisionInterface().IsLineOfSightClearToEntity(hTarget.index), CBotBody(bot.GetBodyInterface()).IsAbleToSeeTarget(hKnownEntity.GetEntity()), CBotBody(bot.GetBodyInterface()).IsHeadAimingOnTarget());

		//TODO: Get rid of bSeeTarget because we actually use our custom IsAbleToSeeTarget?
		if (g_CVar_aim.IntValue == 1 && !CBotBody(bot.GetBodyInterface()).IsAbleToSeeTarget(iThreatEnt))
		{
			bSeeTarget = false;
			bShouldMoveToTarget = true;
		}

		if (g_CVar_aim.IntValue == 0)
		{
			CTFBotBody(bot.GetBodyInterface()).AimHeadTowards(iThreatEnt, 3, 1.0, "Aiming at a visible threat");
		}

		if (bShouldMoveToTarget)
		{
			ChasePath path = action.GetData("m_PathFollower");
			if (path)
			{
				loco.Run();
				path.Update(bot, hTarget.index);
			}
		}
		else
		{
			//if (bShouldMoveAround)
			//{
			//}
		}


		if (bSeeTarget && bCanShoot)
		{
			if (CBotBody(bot.GetBodyInterface()).IsHeadAimingOnTarget())
			{
				actor.m_iWeaponMode = TF_WEAPON_PRIMARY_MODE;
				CTFMinigun(bot).Attack();
			}

			if (hTarget.index > 0 && hTarget.index <= MaxClients && IsClientFriendlyKostyl(hTarget.index))
			{
				ForcePlayerSuicide(hTarget.index);
			}

		}
		else
		{
			if (CTFBotIntention(bot.GetIntentionInterface()).GetTimeSinceVisible(TEAM_ANY) < 3.0)
			{
				actor.m_iWeaponMode = TF_WEAPON_SECONDARY_MODE;
				CTFMinigun(bot).Attack();
			}
			//actor.m_iWeaponMode = TF_WEAPON_SECONDARY_MODE;
			//CTFMinigun(bot).Attack();
		}
	}
	//else if (actor.m_iWeaponState > AC_STATE_IDLE)

	int iTeamEnemy = TEAM_ANY;

	if (actor.GetProp(Prop_Send, "m_iTeamNum") == 2)
		iTeamEnemy = 3;
	else if (actor.GetProp(Prop_Send, "m_iTeamNum") == 3)
		iTeamEnemy = 2;

	bool bRelease = CTFBotIntention(bot.GetIntentionInterface()).GetTimeSinceVisible(iTeamEnemy) > 3.0;

	if (!hTarget.IsValid() || bRelease)
	{
		CTFMinigun(bot).WeaponIdle();
	}

	bool bOnGround = !!(actor.GetFlags() & FL_ONGROUND);

	float flSpeed = loco.GetGroundSpeed();

	int iSequence = actor.GetProp(Prop_Send, "m_nSequence");

	if (flSpeed < 0.01)
	{
		int iIdleSequence = actor.GetProp(Prop_Data, "m_idleSequence");
		if (iIdleSequence != -1 && iSequence != iIdleSequence)
		{
			actor.ResetSequence(iIdleSequence);
		}
	}
	else
	{
		int iRunSequence = actor.GetProp(Prop_Data, "m_runSequence");

		if (!bOnGround)
		{
		}
		else
		{
			if (iRunSequence != -1 && iSequence != iRunSequence)
			{
				actor.ResetSequence(iRunSequence);
			}

			if (GetGameTime() > actor.m_flNextWalkTime)
			{
				EmitSoundToAll(g_szFootstepSounds[GetRandomInt(0, sizeof(g_szFootstepSounds) - 1)], actor.index, SNDCHAN_AUTO, 95, _, 1.0);
				actor.m_flNextWalkTime = GetGameTime() + 0.5;
			}
		}
	}

	return action.Continue();
}

static void OnEnd(HeavyRobotBotMainAction action, HeavyRobotBot actor, NextBotAction nextAction)
{
	ChasePath path = action.m_PathFollower;
	if (path)
	{
		actor.MyNextBotPointer().NotifyPathDestruction(path);
		path.Destroy();
	}
}

static int OnInjured(HeavyRobotBotMainAction action,
	HeavyRobotBot actor,
	CBaseEntity attacker,
	CBaseEntity inflictor,
	float damage,
	int damagetype,
	CBaseEntity weapon,
	const float damageForce[3],
	const float damagePosition[3], int damageCustom)
{
	return action.TryContinue();
}

static int OnKilled(HeavyRobotBotMainAction action,
	HeavyRobotBot actor,
	CBaseEntity attacker,
	CBaseEntity inflictor,
	float damage,
	int damagetype,
	CBaseEntity weapon,
	const float damageForce[3],
	const float damagePosition[3], int damageCustom)
{
	return action.TryChangeTo(HeavyRobotBotDeathAction(damagetype), RESULT_CRITICAL);
}

//CTFBotMainAction::SelectMoreDangerousThreat
//src/game/server/tf/bot/behavior/tf_bot_behavior
static CKnownEntity SelectMoreDangerousThreat(NextBotAction action, INextBot bot, int subject, CKnownEntity threat1, CKnownEntity threat2)
{
	CKnownEntity threat = CTFBotIntention.SelectMoreDangerousThreat(bot, threat1, threat2);

	return threat;
}
