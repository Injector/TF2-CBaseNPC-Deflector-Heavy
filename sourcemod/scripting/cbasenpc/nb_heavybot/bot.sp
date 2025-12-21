#define BOT_SKILL_EASY 0
#define BOT_SKILL_NORMAL 1
#define BOT_SKILL_HARD	2
#define BOT_SKILL_EXPERT 3

#define BOT_VERSION "1.0"

//For FAKECLIENT_TEAM_MODE_ALL_TEAMS, please use HookEvent("player_team", ...) and return Plugin_Handled when client == GetClientOfUserId(g_iFakeClientUserId) to hide change client team notification in kill feed and chat
#define FAKECLIENT_TEAM_MODE_ONLY_WHITE 1
#define FAKECLIENT_TEAM_MODE_ALL_TEAMS 2


float g_flWeaponFired[MAXPLAYERS + 1];
float g_flSentryGunFired[2048 + 1];

char g_szFakeClientName[64];
int g_iFakeClientUserId;

int g_iAmountOfTriesToChangeTeam;
float g_flLastChangedTime;

int g_iFakeClientTeamMode;

//bool g_bDebugLookAt;

stock void ReqFrameCreateEvent(DataPack pack)
{
    pack.Reset();
    char szWeapon[64];
    int iRosguardClient = pack.ReadCell();
    int iAttackerUserId = pack.ReadCell();
    int iDeathFlags = pack.ReadCell();
    pack.ReadString(szWeapon, sizeof(szWeapon));
    delete pack;

    Event newEvent = CreateEvent("player_death");
    newEvent.SetInt("inflictor_entindex", iRosguardClient);

    newEvent.SetInt("userid", g_iFakeClientUserId);
    newEvent.SetInt("attacker", iAttackerUserId);
    newEvent.SetString("weapon", szWeapon);
    newEvent.SetInt("death_flags", iDeathFlags);
    newEvent.Fire();
}

stock void ReqFrameChangeTeam(int userid)
{
    int client = GetClientOfUserId(userid);

    if (!client)
        return;

    ChangeClientTeam(client, 0);
}

public Action FakeClient_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
    //Only the world can attack fake client
	if (attacker > 0)
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

methodmap CBot
{
    public static void AddFakeClient()
    {
        if (GetClientOfUserId(g_iFakeClientUserId) <= 0)
		{
            if (g_szFakeClientName[0] == '\0')
                g_szFakeClientName = "Bot";
			int iBot = CreateFakeClient(g_szFakeClientName);
			if (iBot > 0)
			{
				g_iFakeClientUserId = GetClientUserId(iBot);
				SDKHook(iBot, SDKHook_OnTakeDamage, FakeClient_OnTakeDamage);
            }
            g_flLastChangedTime = 0.0;
            g_iAmountOfTriesToChangeTeam = 0;
		}
    }

    public static void RemoveFakeClient()
    {
        if (GetClientOfUserId(g_iFakeClientUserId) > 0)
        {
            KickClient(GetClientOfUserId(g_iFakeClientUserId));
            g_flLastChangedTime = 0.0;
            g_iAmountOfTriesToChangeTeam = 0;
        }
    }

    public static void ClearFakeClientLoadout(int client)
    {
        SetEntProp(client, Prop_Send, "m_fEffects", 32);

        for (int i = 0; i < 7; i++)
        {
            //Using m_hMyWeapons to remove special item (grappling hook, etc)
            int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
            if (iWeapon > 0)
            {
                int iWearable = GetEntPropEnt(iWeapon, Prop_Send, "m_hExtraWearable");
                if (iWearable != -1)
                {
                    TF2_RemoveWearable(client, iWearable);
                }
                iWearable = GetEntPropEnt(iWeapon, Prop_Send, "m_hExtraWearableViewModel");
                if (iWearable != -1)
                {
                    TF2_RemoveWearable(client, iWearable);
                }
                RemovePlayerItem(client, iWeapon);
                AcceptEntityInput(iWeapon, "Kill");
            }
        }
    }

    //If a fake client changed his team (usually unassigned) to a different one and g_iFakeClientTeamMode == FAKECLIENT_TEAM_MODE_ONLY_WHITE, switch back to unassigned team
    public static void EventPlayerTeam(int client, int team)
    {
        if (GetClientOfUserId(g_iFakeClientUserId) != client)
            return;

        if (g_iFakeClientTeamMode != FAKECLIENT_TEAM_MODE_ONLY_WHITE)
            return;

        int iCurrentTeam = GetClientTeam(client);
        int iNewTeam = team;

        //Reset num of tries since we joined unassigned team back
        if (iNewTeam < 2)
        {
            g_iAmountOfTriesToChangeTeam = 0;
        }

        //We are in unassigned team and some plugin tries to change our team
        if (iCurrentTeam < 2)
        {
            if (team > 1)
            {
                float flTime = GetGameTime() - g_flLastChangedTime;
                if (g_iAmountOfTriesToChangeTeam != 0)
                {
                    //Added check to make sure to prevent infinite loop somehow (by third plugins)
                    if (flTime == 0.0 || flTime > 0.0 && flTime <= 0.2)
                        return;
                }

                RequestFrame(ReqFrameChangeTeam, g_iFakeClientUserId);
                g_iAmountOfTriesToChangeTeam++;
                g_flLastChangedTime = GetGameTime();
            }
        }
    }

    //I think you would like to create your custom Event_ hook and just call it from CBot.Event_NPCHurt()
    //If when you need multiple names for same nextbot class, you can do like this
    //
    //Format(g_szFakeClientName, sizeof(g_szFakeClientName), "%s", "my new nextbot name");
    //CBot.Event_NPCHurt(event);
    //
    //
    //(Event event, const char[] name, bool dontBroadcast)
    public static void EventNPCHurt(Event event)
    {
        char szWeapon[64];
        int iEnt = event.GetInt("entindex");
        int iHealth = event.GetInt("health");
        int iAttacker = GetClientOfUserId(event.GetInt("attacker_player"));
        int iDeathFlags = event.GetInt("death_flags");
        event.GetString("weapon", szWeapon, sizeof(szWeapon));

        if (iEnt > 0 && iHealth == 0)
        {
            char szClassName[64];
            GetEntityClassname(iEnt, szClassName, sizeof(szClassName));

            if (StrEqual(szClassName, NEXTBOT_CUSTOM_CLASS_NAME) && iAttacker > 0 && iAttacker <= MaxClients)
            {
                int iRosguardClient = GetClientOfUserId(g_iFakeClientUserId);

                if (g_szFakeClientName[0] != '\0' && iRosguardClient > 0)
                {
                    //Use m_szNetname and info to bypass sv_namechange_cooldown_seconds I think
                    SetEntPropString(iRosguardClient, Prop_Data, "m_szNetname", g_szFakeClientName);
                    SetClientInfo(iRosguardClient, "name", g_szFakeClientName);

                    //Wait 1 frame to make sure that our name is correctly changed
                    DataPack pack = new DataPack();
                    pack.WriteCell(iRosguardClient);
                    pack.WriteCell(GetClientUserId(iAttacker));
                    pack.WriteCell(iDeathFlags);
                    pack.WriteString(szWeapon);
                    RequestFrame(ReqFrameCreateEvent, pack);
                }
            }
        }
    }

    public static void EventPlayerDeath(Event event, const char[] weapon, int deathFlags)
    {
        int iInflictor = event.GetInt("inflictor_entindex");

        if (iInflictor > 0)
        {
            int iEnt = -1;
            while ((iEnt = FindEntityByClassname(iEnt, NEXTBOT_CUSTOM_CLASS_NAME)) != INVALID_ENT_REFERENCE)
            {
                if (iEnt == iInflictor)
                {
                    int iTarget = GetClientOfUserId(g_iFakeClientUserId);
                    if (iTarget > 0)
                    {
                        if (g_szFakeClientName[0] != '\0')
                        {
                            //Use m_szNetname and info to bypass sv_namechange_cooldown_seconds I think
                            SetEntPropString(iTarget, Prop_Data, "m_szNetname", g_szFakeClientName);
                            SetClientInfo(iTarget, "name", g_szFakeClientName);
                        }

                        if (g_iFakeClientTeamMode == FAKECLIENT_TEAM_MODE_ALL_TEAMS && GetEntProp(iEnt, Prop_Send, "m_iTeamNum") <= 3)
                        {
                            //Switch our class to unassigned, so we don't receive 'bid farewell, cruel world!' and prevent us from spawning to avoid break custom gamemodes which relies on alive players?
                            SetEntProp(iTarget, Prop_Send, "m_iDesiredPlayerClass", 0);
                            SetEntProp(iTarget, Prop_Send, "m_iClass", 0);
                            ChangeClientTeam(iTarget, GetEntProp(iEnt, Prop_Send, "m_iTeamNum"));
                        }

                        event.SetString("assister_fallback", "");
                        event.SetInt("attacker", GetClientUserId(iTarget));
                        event.SetString("weapon", weapon);
                        event.SetString("weapon_logclassname", weapon);
                        event.SetInt("death_flags", deathFlags);
                    }
                }
            }
        }
    }
}

methodmap CBotDebug < INextBot
{
    public CBotDebug(INextBot bot)
    {
        return view_as<CBotDebug>(bot);
    }

    public void DebugLookAt()
    {
        float vecEyePos[3], angEyes[3];
        CBaseEntity ent = CBaseEntity(this.GetEntity());
        ent.GetPropVector(Prop_Data, "m_angCurrentAngles", angEyes);
        CBotBody(this.GetBodyInterface()).GetEyePositionEx(vecEyePos);

        float vecForward[3], vecDir[3];
        GetAngleVectors(angEyes, vecForward, NULL_VECTOR, NULL_VECTOR);

        vecDir[0] = vecEyePos[0] + (500.0 * vecForward[0]);
        vecDir[1] = vecEyePos[1] + (500.0 * vecForward[1]);
        vecDir[2] = vecEyePos[2] + (500.0 * vecForward[2]);

        int iColour2[4];
        iColour2[0] = 0;
        iColour2[1] = 0;
        iColour2[2] = 255;
        iColour2[3] = 255;

        TE_SetupBeamPoints(vecEyePos, vecDir, PrecacheModel("materials/sprites/physbeam.vmt"), PrecacheModel("materials/sprites/halo01.vmt"), 0, 15, 0.1, 1.0, 1.0, 1, 0.0, iColour2, 10);
        TE_SendToAll();
    }
}
