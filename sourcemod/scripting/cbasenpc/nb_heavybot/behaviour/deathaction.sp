static NextBotActionFactory ActionFactory;

methodmap HeavyRobotBotDeathAction < NextBotAction
{
	public static void Initialize()
	{
		ActionFactory = new NextBotActionFactory("HeavyBotDeathAction");
		ActionFactory.BeginDataMapDesc()
			.DefineIntField("m_iDamageType")
			.DefineFloatField("m_flDieTime")
		.EndDataMapDesc();
		ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
		ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
	}
	
	property int m_iDamageType
	{
		public get()
		{
			return this.GetData("m_iDamageType");
		}

		public set(int value)
		{
			this.SetData("m_iDamageType", value);
		}
	}

	property float m_flDieTime
	{
		public get()
		{
			return this.GetDataFloat("m_flDieTime");
		}

		public set(float value)
		{
			this.SetDataFloat("m_flDieTime", value);
		}
	}
	
	public HeavyRobotBotDeathAction(int damageType)
	{
		HeavyRobotBotDeathAction action = view_as<HeavyRobotBotDeathAction>(ActionFactory.Create());
		
		action.m_iDamageType = damageType;
		
		return action;
	}
}

static int OnStart(HeavyRobotBotDeathAction action, HeavyRobotBot actor, NextBotAction prevAction)
{
	//EmitSoundToAll("vo/scout_paincrticialdeath01.mp3", actor.index, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);

	EmitSoundToAll(g_szDieSounds[GetRandomInt(0, sizeof(g_szDieSounds) - 1)], actor.index, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);

	float vecCenter[3];
	CBaseAnimating(actor.index).WorldSpaceCenter(vecCenter);
	float vecPos[3]; GetEntPropVector(actor.index, Prop_Data, "m_vecAbsOrigin", vecPos);
	float angRot[3]; GetEntPropVector(actor.index, Prop_Data, "m_angRotation", angRot);

	actor.AcceptInput("Kill");

	CreateParticle("bot_death", vecPos, angRot);
	EmitSoundToAll("mvm/sentrybuster/mvm_sentrybuster_explode.wav", SOUND_FROM_WORLD, SNDCHAN_STATIC, 125, _, _, _, _, vecPos);

	vecCenter[2] -= 100.0;

	float vecVel[3];
	vecVel[2] = 325.0;

	char szModel[256];
	strcopy(szModel, sizeof(szModel), g_szGibs[0]);

	if (szModel[0] != '\0')
	{
		int iEnt = CreateEntityByName("prop_physics_multiplayer");
		DispatchKeyValue(iEnt, "model", szModel);
		DispatchKeyValue(iEnt, "physicmode", "2");

		DispatchSpawn(iEnt);

		SetEntProp(iEnt, Prop_Send, "m_CollisionGroup", 1);
		SetEntProp(iEnt, Prop_Send, "m_usSolidFlags", 0);
		SetEntProp(iEnt, Prop_Send, "m_nSolidType", 2);
		SetEntProp(iEnt, Prop_Send, "m_nSkin", GetEntProp(actor.index, Prop_Send, "m_iTeamNum") == 2 ? 0 : 1);

		SetEntProp(iEnt, Prop_Send, "m_fEffects", 16|64);

		TeleportEntity(iEnt, vecPos, angRot, vecVel);

		SetVariantString("OnUser1 !self:Kill::10.0:1");
		AcceptEntityInput(iEnt, "AddOutput");
		AcceptEntityInput(iEnt, "FireUser1");
	}

	for(int numGibs = 1; numGibs < sizeof(g_szGibs) - 1; numGibs++)
	{
		for(int i = 0; i < 2; i++) vecPos[i] += GetRandomFloat(-42.0, 42.0);

		angRot[1] = GetRandomFloat(-180.0, 180.0);

		for(int i = 0; i < 2; i++) vecVel[i] += GetRandomFloat(-100.0, 100.0);
		vecVel[2] = 300.0;

		strcopy(szModel, sizeof(szModel), g_szGibs[numGibs]);

		if (szModel[0] != '\0')
		{
			int gib = CreateEntityByName("prop_physics_multiplayer");
			DispatchKeyValue(gib, "model", szModel);
			DispatchKeyValue(gib, "physicsmode", "2");

			DispatchSpawn(gib);

			SetEntProp(gib, Prop_Send, "m_CollisionGroup", 1); // 24
			SetEntProp(gib, Prop_Send, "m_usSolidFlags", 0); // 8
			SetEntProp(gib, Prop_Send, "m_nSolidType", 2); // 6
			SetEntProp(gib, Prop_Send, "m_nSkin", GetEntProp(actor.index, Prop_Send, "m_iTeamNum") == 2 ? 0 : 1);

			SetEntProp(gib, Prop_Send, "m_fEffects", 16|64);

			TeleportEntity(gib, vecPos, angRot, vecVel);

			SetVariantString("OnUser1 !self:Kill::10.0:1");
			AcceptEntityInput(gib, "AddOutput");
			AcceptEntityInput(gib, "FireUser1");
		}
	}

	return action.Done();
}

static int Update(HeavyRobotBotDeathAction action, HeavyRobotBot actor, float interval)
{
	if (GetGameTime() >= action.m_flDieTime)
	{
		actor.AcceptInput("Kill");
		return action.Done();
	}

	return action.Continue();
}
