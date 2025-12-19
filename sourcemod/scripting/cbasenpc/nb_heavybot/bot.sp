#define BOT_SKILL_EASY 0
#define BOT_SKILL_NORMAL 1
#define BOT_SKILL_HARD	2
#define BOT_SKILL_EXPERT 3

#define BOT_VERSION "1.0"

float g_flWeaponFired[MAXPLAYERS + 1];
float g_flSentryGunFired[2048 + 1];

char g_szFakeClientName[64];
int g_iFakeClientUserId;

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
		}
    }

    public static void RemoveFakeClient()
    {
        if (GetClientOfUserId(g_iFakeClientUserId) > 0)
            KickClient(GetClientOfUserId(g_iFakeClientUserId));
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
