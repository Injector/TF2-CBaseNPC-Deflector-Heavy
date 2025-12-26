#define BOT_SKILL_EASY 0
#define BOT_SKILL_NORMAL 1
#define BOT_SKILL_HARD	2
#define BOT_SKILL_EXPERT 3

#define LOOKAT_BORING 0
#define LOOKAT_INTERESTING 1
#define LOOKAT_IMPORTANT 2
#define LOOKAT_CRITICAL 3

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

//int g_iBossHealthbarRef;
int g_iBossHealthbarTargetRef;

bool g_bBossHealthbarDisplayHp = true;
bool g_bBossHealthbarDisplayPercent = true;
char g_szBossHealthbarName[64];

Handle g_hBosshealthbarHud;
Handle g_hBossHealthbarUpdate;

bool g_bBackstabEnabled = false;
float g_flBackstabDamage = 450.0;
float g_flBackstabDelay = 1.5;

//bool g_bDebugLookAt;

//TODO: Refactor code

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

//Credit: titantf & HowToPlayMeow Any Headshot
public Action NextBot_TraceAttackHeadshot(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
    if (attacker > MaxClients)
        return Plugin_Continue;

    if (hitgroup != 1)
        return Plugin_Continue;

    if (TF2_GetPlayerClass(attacker) != TFClass_Sniper && TF2_GetPlayerClass(attacker) != TFClass_Spy)
        return Plugin_Continue;

    int iWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
    if (iWeapon == -1)
        return Plugin_Continue;

    int iItemDefIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");

    if (iItemDefIndex == 230) // Sydney Sleeper
        return Plugin_Continue;

    //61 and 1006 are Ambassador
    if ((iItemDefIndex == 61 || iItemDefIndex == 1006) || TF2_IsPlayerInCondition(attacker, TFCond_Zoomed))
    {
        damagetype |= DMG_CRIT;
        return Plugin_Changed;
    }
    return Plugin_Continue;
}

//Credit: Scags TF2-Backstab-Bosses
public Action NextBot_OnTakeDamageBackstab(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
    //PrintToChatAll("NextBot_OnTakeDamageBackstab prepare");
    if (!IsValidEntity(weapon) || !HasEntProp(weapon, Prop_Send, "m_bReadyToBackstab") || !GetEntProp(weapon, Prop_Send, "m_bReadyToBackstab"))
        return Plugin_Continue;

    //PrintToChatAll("Test");

    EmitSoundToAll("player/spy_shield_break.wav", attacker, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, true, 0.0);
	EmitSoundToAll("player/crit_received3.wav", attacker, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, true, 0.0);

    int iViewModel = GetEntPropEnt(attacker, Prop_Send, "m_hViewModel");
    int iItemDefIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
    int iSequence;

    if (g_flBackstabDelay > 0.0)
    {
        if (iViewModel != -1)
        {
            iSequence = 15;
            switch (iItemDefIndex)
            {
                case 727: iSequence = 41;
                case 4, 194, 665, 794, 803, 883, 892, 901, 910: iSequence = 10;
                case 638: iSequence = 31;
            }
            SetEntProp(iViewModel, Prop_Send, "m_nSequence", iSequence);
        }

        SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + g_flBackstabDelay);
        SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + g_flBackstabDelay);
    }
    else if (iViewModel != -1)
    {
        iSequence = 38;
        switch (iItemDefIndex)
        {
            case 225, 356, 461, 574, 649: iSequence = 12;
            case 638: iSequence = 28;
            case 423: iSequence = 22;
        }
        SetEntProp(iViewModel, Prop_Send, "m_nSequence", iSequence);
    }

    damage = g_flBackstabDamage;
    //damage /= 3.0;
    return Plugin_Changed;
}

stock int Backstab_DoSwingTrace(int client)
{
	static float vecSwingMins[3] = { -18.0, -18.0, -18.0 };
	static float vecSwingMaxs[3] = { 18.0, 18.0, 18.0 };

	// Setup the swing range.
	float vecForward[3];
	float vecEyes[3];
	GetClientEyeAngles(client, vecEyes);
	GetAngleVectors(vecEyes, vecForward, NULL_VECTOR, NULL_VECTOR);
	float vecSwingStart[3]; GetClientEyePosition(client, vecSwingStart);

	ScaleVector(vecForward, 48.0);
	float vecSwingEnd[3];
	AddVectors(vecSwingStart, vecForward, vecSwingEnd);

	// See if we hit anything.

	Handle hTrace = TR_TraceRayFilterEx(vecSwingStart, vecSwingEnd, MASK_SOLID, RayType_EndPoint, Filter_BackstabBoss, client);

	float flFraction = TR_GetFraction(hTrace);
	delete hTrace;

	//PrintToChatAll("fraction 1 %.1f %b", flFraction, flFraction >= 1.0);

	//if (flFraction >= 1.0)
	if (flFraction >= 0.9)
	{
        hTrace = TR_TraceHullFilterEx(vecSwingStart, vecSwingEnd, vecSwingMins, vecSwingMaxs, MASK_SOLID, Filter_BackstabBoss, client);
        flFraction = TR_GetFraction(hTrace);
        int iTarget = TR_GetEntityIndex(hTrace);
        delete hTrace;

        //PrintToChatAll("fraction 2 %.1f %b", flFraction, flFraction < 1.0);
        if (flFraction < 1.0)
        {
            return iTarget;
        }
	}
	return -1;
}

stock bool Backstab_IsBehindMe(int client, int target)
{
    CBaseEntity ent = CBaseEntity(target);

    float vecBotForward[3], angEyes[3];

    ent.GetPropVector(Prop_Data, "m_angRotation", angEyes);
    GetAngleVectors(angEyes, vecBotForward, NULL_VECTOR, NULL_VECTOR);
    vecBotForward[2] = 0.0;
    NormalizeVector(vecBotForward, vecBotForward);

    float vecBotPos[3], vecRocketPos[3], vecToBot[3];
    ent.WorldSpaceCenter(vecBotPos);
    CBaseEntity(client).WorldSpaceCenter(vecRocketPos);

    SubtractVectors(vecBotPos, vecRocketPos, vecToBot);
    vecToBot[2] = 0.0;
    NormalizeVector(vecToBot, vecToBot);

    float flDot = GetVectorDotProduct(vecBotForward, vecToBot);

    //PrintToChatAll("%.2f %b", flDot, flDot > -0.1);

    return flDot > -0.1;
}

public bool Filter_BackstabBoss(int ent, int mask, any data)
{
	char classname[32]; GetEntityClassname(ent, classname, 32);
	if (!StrEqual(classname, NEXTBOT_CUSTOM_CLASS_NAME))
        return false;

	//if (!strcmp(classname, NEXTBOT_CUSTOM_CLASS_NAME, false))
		//return true;

	return ent != data;
}

//TODO: Create g_vecMinsBuffer and g_vecMaxsBuffer for CBot.FixHitbox
//Credit: HowToPlayMeow
public void NextBot_SpawnPostFixHitbox(int entity)
{
    float vecMins[3] = { -40.0, -40.0, 0.0 };
    float vecMaxs[3] = { 40.0, 40.0, 155.0 };

    SetEntPropVector(entity, Prop_Send, "m_vecMins", vecMins);
    SetEntPropVector(entity, Prop_Send, "m_vecMaxs", vecMaxs);

    TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR);
}

//Credit: HowToPlayMeow
public Action Timer_BossHealthbarHUD(Handle timer)
{
    if (g_hBosshealthbarHud == null)
    {
        g_hBosshealthbarHud = CreateHudSynchronizer();
    }

    int iEnt = EntRefToEntIndex(g_iBossHealthbarTargetRef);
    if (iEnt == -1)
    {
        g_hBossHealthbarUpdate = null;
        return Plugin_Stop;
    }

    int iHealth = GetEntProp(iEnt, Prop_Data, "m_iHealth");
    int iMaxHealth = GetEntProp(iEnt, Prop_Data, "m_iMaxHealth");

    if (iHealth < 0 || iMaxHealth < 0)
    {
        g_hBossHealthbarUpdate = null;
        return Plugin_Stop;
    }

    float flPercent = float(iHealth) / float(iMaxHealth) * 100.0;

    char szHealthbar[64];
    HealthBarFill(flPercent, szHealthbar, sizeof(szHealthbar));

    int r = 0, g = 255, b = 0;
    if (flPercent <= 30.0)
    {
        r = 255;
        g = 0;
        b = 0;
    }
    else if (flPercent <= 60.0)
    {
        r = 255;
        g = 120;
        b = 0;
    }

    bool bDisplayHealth = g_bBossHealthbarDisplayHp;
    bool bDisplayPercent = g_bBossHealthbarDisplayPercent;

    char szHealthbarRes[128];

    Format(szHealthbarRes, sizeof(szHealthbarRes), "[%s]\n%s", g_szBossHealthbarName, szHealthbar);

    if (bDisplayHealth)
    {
        Format(szHealthbarRes, sizeof(szHealthbarRes), "%s\n%d / %d", szHealthbarRes, iHealth, iMaxHealth);
    }
    if (bDisplayPercent)
    {
        //Symbol % is missing for some reason...
        //Format(szHealthbarRes, sizeof(szHealthbarRes), "%s (%.0f%%)", szHealthbarRes, flPercent);
        Format(szHealthbarRes, sizeof(szHealthbarRes), "%s (%.0f%%%%)", szHealthbarRes, flPercent);
    }

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i))
            continue;

        SetHudTextParams(-1.0, 0.12, 0.25, r, g, b, 255);
        ShowSyncHudText(i, g_hBosshealthbarHud, szHealthbarRes);
    }
    return Plugin_Continue;
}

stock void HealthBarFill(float percent, char[] buffer, int maxlen)
{
    int iTotal = 20;
    int iFilled = RoundToFloor((percent / 100.0) * iTotal);

    buffer[0] = '\0';

    //TODO: missing symbol on linux, need to create linux.sp with stock CGameLinux.IsLinuxPlayer(int client) and g_bLinuxPlayer[MAXPLAYERS + 1]
    //QueryClientConVar
    //Linux: sdl_double_click_size
    //Windows: windows_speaker_config
    //For linux: "#" : "_"
    for (int i = 0; i < iTotal; i++)
        StrCat(buffer, maxlen, (i < iFilled) ? "█" : "░");
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

    /// Call it in OnEntityCreated
    //TODO: Add custom vecmins and vecmaxs in function
    public static void FixHitbox(int entity)
    {
        SDKHook(entity, SDKHook_SpawnPost, NextBot_SpawnPostFixHitbox);
    }

    public static void AddSniperHeadshotSupport(int entity)
    {
        SDKHook(entity, SDKHook_TraceAttack, NextBot_TraceAttackHeadshot);
    }

    public static void AddSpyBackstabSupport(int entity)
    {
        SDKHook(entity, SDKHook_OnTakeDamage, NextBot_OnTakeDamageBackstab);
        g_bBackstabEnabled = true;
    }

    //Call it in TF2_CalcIsAttackCritical
    public static void HandleBackstabLogic(int client, int weapon)
    {
        if (!g_bBackstabEnabled || !IsValidEntity(weapon) || !HasEntProp(weapon, Prop_Send, "m_bReadyToBackstab"))
            return;

        int iTarget = Backstab_DoSwingTrace(client);

        //PrintToChatAll("Target %i", iTarget);

        if (iTarget <= 0)
            return;

        if (GetEntProp(iTarget, Prop_Send, "m_iTeamNum") == GetClientTeam(client))
            return;

        if (!Backstab_IsBehindMe(client, iTarget))
            return;

        //PrintToChatAll("Backstab test");

        SetEntProp(weapon, Prop_Send, "m_bReadyToBackstab", 1);
    }
}

methodmap CBotBossHealthbarMonoculus
{
    //TODO:
}

methodmap CBotBossHealthbar
{
    public static void SetBoss(int ent)
    {
        if (g_hBossHealthbarUpdate != null)
        {
            delete g_hBossHealthbarUpdate;
        }

        g_iBossHealthbarTargetRef = EntIndexToEntRef(ent);

        //If we set TIMER_FLAG_NO_MAPCHANGE, then we need to clear g_hBossHealthbarUpdate = null, but what if a developer forgets to clear g_hBossHealthbarUpdate in OnMapEnd?
        g_hBossHealthbarUpdate = CreateTimer(0.2, Timer_BossHealthbarHUD, _, TIMER_REPEAT);
    }

    public static void Cleanup()
    {
        if (g_hBossHealthbarUpdate != null)
        {
            delete g_hBossHealthbarUpdate;
        }
    }

    public static void SetBossName(char[] name)
    {
        Format(g_szBossHealthbarName, sizeof(g_szBossHealthbarName), "%s", name);
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
