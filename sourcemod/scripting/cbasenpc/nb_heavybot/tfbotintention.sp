#define TFBOT_INTENTION_VERSION "1.0"

//Define these in BeginDataMapDesc()
/*
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
*/

methodmap CTFBotIntention < IIntention
{
    public CTFBotIntention(IIntention intention)
    {
        return view_as<CTFBotIntention>(intention);
    }

    public static float GetMinRecognizeTime(int skill)
    {
        switch (skill)
        {
            case BOT_SKILL_EASY:
                return 1.0;
            case BOT_SKILL_NORMAL:
                return 0.5;
            case BOT_SKILL_HARD:
                return 0.3;
            case BOT_SKILL_EXPERT:
                return 0.2;
        }
        return 0.0;
    }

    public float GetTimeSinceVisible(int team = -1)
    {
        INextBot bot = this.GetBot();
        CBaseEntity ent = CBaseEntity(bot.GetEntity());

        if (!ent.HasProp(Prop_Data, "m_flTimeSinceVisibleThreats"))
            return 0.0;

        if (team < 0)
        {
            float flTime = 9999999999.9;
            for (int i = 0; i < 4; i++)
            {
                if (ent.GetPropFloat(Prop_Data, "m_flTimeSinceVisibleThreats", i) > 0.0)
                {
                    if (flTime > GetGameTime() - ent.GetPropFloat(Prop_Data, "m_flTimeSinceVisibleThreats", i))
                    {
                        flTime = GetGameTime() - ent.GetPropFloat(Prop_Data, "m_flTimeSinceVisibleThreats", i);
                    }
                }
            }
            return flTime;
        }

        if (team >= 0 && team < 4)
        {
            return GetGameTime() - ent.GetPropFloat(Prop_Data, "m_flTimeSinceVisibleThreats", team);
        }

        return 0.0;
    }

    public void SelectTargetPointRocketLauncher(CKnownEntity threat, float muzzlePos[3] = NULL_VECTOR, float rocketSpeed = 1100.0, float buffer[3])
    {
        INextBot me = this.GetBot();
        if (threat == NULL_KNOWN_ENTITY || threat.IsObsolete())
            return;

        float vecThreatPos[3], vecOrigThreatPos[3], vecMyPos[3], vecThreatEyePosition[3];
        GetEntPropVector(threat.GetEntity(), Prop_Send, "m_vecOrigin", vecThreatPos);
        GetEntPropVector(threat.GetEntity(), Prop_Send, "m_vecOrigin", vecOrigThreatPos);
        GetEntPropVector(me.GetEntity(), Prop_Send, "m_vecOrigin", vecMyPos);

        if (IsNullVector(muzzlePos))
            muzzlePos = vecMyPos;

        if (rocketSpeed <= 0.0)
            rocketSpeed = 1100.0;

        if (threat.GetEntity() <= MaxClients)
        {
            GetClientEyePosition(threat.GetEntity(), vecThreatEyePosition);
        }

        char szClassName[64];
        GetEntityClassname(threat.GetEntity(), szClassName, sizeof(szClassName));

        if (StrContains(szClassName, "obj") > -1)
        {
            vecThreatPos[2] += 15.0;
            buffer = vecThreatPos;
            return;
        }

        const float flAboveTolerance = 30.0;

        if (vecThreatPos[2] - flAboveTolerance > vecMyPos[2])
        {
            if (me.GetVisionInterface().IsAbleToSee(vecThreatPos, DISREGARD_FOV))
            {
                buffer = vecThreatPos;
                return;
            }

            CBaseAnimating(threat.GetEntity()).WorldSpaceCenter(vecThreatPos);

            if (me.GetVisionInterface().IsAbleToSee(vecThreatPos, DISREGARD_FOV))
            {
                buffer = vecThreatPos;
                return;
            }

            if (threat.GetEntity() <= MaxClients)
                GetClientEyePosition(threat.GetEntity(), vecThreatPos);

            buffer = vecThreatPos;
            return;
        }

        GetEntPropVector(threat.GetEntity(), Prop_Send, "m_vecOrigin", vecThreatPos);

        if (threat.GetEntity() <= MaxClients && GetEntPropEnt(threat.GetEntity(), Prop_Data, "m_hGroundEntity") == -1)
        {
            float vecUnderTargetFeet[3];
            vecUnderTargetFeet = vecThreatPos;
            vecUnderTargetFeet[2] = vecThreatPos[2] - 200.0;

            Handle hTrace = TR_TraceRayFilterEx(vecThreatPos, vecUnderTargetFeet, (MASK_SOLID|CONTENTS_HITBOX), RayType_EndPoint, Filter_WorldOnly, threat.GetEntity());
            if (TR_DidHit(hTrace))
            {
                TR_GetEndPosition(vecThreatPos, hTrace);
            }

            delete hTrace;

            buffer = vecThreatPos;
            return;
        }

        GetEntPropVector(threat.GetEntity(), Prop_Send, "m_vecOrigin", vecThreatPos);

        float vecAbsVelocity[3];
        float flDistance = GetVectorDistance(muzzlePos, vecThreatPos);
        const float flVeryCloseRange = 150.0;

        if (flDistance > flVeryCloseRange)
        {
            float flTimeToTravel = flDistance / rocketSpeed;

            CBaseEntity(threat.GetEntity()).GetAbsVelocity(vecAbsVelocity);

            vecThreatPos[0] += flTimeToTravel * vecAbsVelocity[0];
            vecThreatPos[1] += flTimeToTravel * vecAbsVelocity[1];
            vecThreatPos[2] += flTimeToTravel * vecAbsVelocity[2];

            if (me.GetVisionInterface().IsAbleToSee(vecThreatPos, DISREGARD_FOV))
            {
                buffer = vecThreatPos;
                return;
            }

            CBaseAnimating(threat.GetEntity()).WorldSpaceCenter(vecThreatPos);
            if (me.GetVisionInterface().IsAbleToSee(vecThreatPos, DISREGARD_FOV))
            {
                buffer = vecThreatPos;
                return;
            }

            if (threat.GetEntity() <= MaxClients)
                GetClientEyePosition(threat.GetEntity(), vecThreatPos);

            buffer = vecThreatPos;
            return;
        }
        buffer = vecOrigThreatPos;
    }

    public static bool IsActiveSentry(int ent)
    {
        return (HasEntProp(ent, Prop_Send, "m_bPlacing") && GetEntProp(ent, Prop_Send, "m_bPlacing")) || (HasEntProp(ent, Prop_Send, "m_bCarried") && GetEntProp(ent, Prop_Send, "m_bCarried")) || (HasEntProp(ent, Prop_Send, "m_bPlasmaDisable") && GetEntProp(ent, Prop_Send, "m_bPlasmaDisable")) || (HasEntProp(ent, Prop_Send, "m_bHasSapper") && GetEntProp(ent, Prop_Send, "m_bHasSapper"));
    }

    public static int GetHealingTarget(int client)
    {
        int iMedigun = GetPlayerWeaponSlot(client, 1);

        if (iMedigun > 0)
        {
            char szName[64];
            GetEntityClassname(iMedigun, szName, sizeof(szName));
            if (StrEqual(szName, "tf_weapon_medigun"))
            {
                if (GetEntProp(iMedigun, Prop_Send, "m_bHealing"))
                {
                    return GetEntPropEnt(iMedigun, Prop_Send, "m_hHealingTarget");
                }
            }
        }
        return -1;
    }

    public CKnownEntity GetHealerOfThreat(CKnownEntity threat)
    {
        INextBot me = this.GetBot();
        if (threat == NULL_KNOWN_ENTITY || !threat.GetEntity())
            return NULL_KNOWN_ENTITY;

        if (threat.GetEntity() > MaxClients)
            return NULL_KNOWN_ENTITY;

        if (GetEntProp(threat.GetEntity(), Prop_Send, "m_nNumHealers") == 0)
            return NULL_KNOWN_ENTITY;

        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && IsPlayerAlive(i) && TF2_GetPlayerClass(i) == TFClass_Medic)
            {
                if (CTFBotIntention.GetHealingTarget(i) == threat.GetEntity())
                    return me.GetVisionInterface().GetKnown(i);
            }
        }

        return NULL_KNOWN_ENTITY;
    }

    public CKnownEntity GetHealerHealingTarget(CKnownEntity threat)
    {
        INextBot me = this.GetBot();
        if (threat == NULL_KNOWN_ENTITY || !threat.GetEntity())
            return NULL_KNOWN_ENTITY;

        if (TF2_GetPlayerClass(threat.GetEntity()) != TFClass_Medic)
            return NULL_KNOWN_ENTITY;

        int iTarget = CTFBotIntention.GetHealingTarget(threat.GetEntity());

        if (iTarget > 0)
            return me.GetVisionInterface().GetKnown(iTarget);

        return NULL_KNOWN_ENTITY;
    }

    public bool IsThreatAimingTowardMe(int threat, float cosTolerance = 0.8)
    {
        INextBot bot = this.GetBot();
        CBaseEntity threatEnt = CBaseEntity(threat);

        float vecThreatPos[3], vecPos[3], vecTo[3];

        threatEnt.GetAbsOrigin(vecThreatPos);
        CBaseEntity(bot.GetEntity()).GetAbsOrigin(vecPos);

        SubtractVectors(vecPos, vecThreatPos, vecTo);
        NormalizeVector(vecTo, vecTo);

        //TODO: Sentry support, get GetTurretAngles() somehow
        if (threat > 0 && threat <= MaxClients)
        {
            float vecForward[3], angEye[3];
            GetClientEyeAngles(threat, angEye);
            GetAngleVectors(angEye, vecForward, NULL_VECTOR, NULL_VECTOR);

            if (GetVectorDotProduct(vecTo, vecForward) > cosTolerance)
                return true;
        }

        return false;
    }

    public bool IsThreatFiringAtMe(int threat)
    {
        if (threat > MaxClients)
        {
            if (threat > 2048 + 1)
                return false;

            float flTime = GetGameTime() - g_flSentryGunFired[threat];
            if (flTime < 0.0)
                return false;

            return flTime <= 1.0;
        }

        float flTime = GetGameTime() - g_flWeaponFired[threat];

        if (flTime < 0.0)
            return false;

        return flTime <= 1.0;
        //return flTime <= 1.0 && this.IsThreatAimingTowardMe(threat);
    }

    public bool IsImmediateThreat(CKnownEntity threat)
    {
        INextBot me = this.GetBot();
        //Looks like IsVisibleRecently is broken, sometimes it works and sometimes doesn't. Bot can't see sometimes his threat even
        //if his threat directly near him. UpdatePosition and UpdateVisibilityStatus in Think does nothing to fix this problem
        //if (!threat.IsVisibleRecently())
        //	return false;

        //Using IsAbleToSeeTarget instead of IsVisibleRecently, for now
        if (!me.GetVisionInterface().IsAbleToSeeTarget(threat.GetEntity(), DISREGARD_FOV))
            return false;

        int iThreatEnt = threat.GetEntity();
        bool bIsPlayer = iThreatEnt > 0 && iThreatEnt <= MaxClients;
        bool bNormalDiff = view_as<CBaseEntity>(me.GetEntity()).GetProp(Prop_Data, "m_iSkill") >= BOT_SKILL_NORMAL;

        float vecMyPos[3], vecLastKnownPos[3];

        //threat.GetLastKnownPosition(vecLastKnownPos);
        GetEntPropVector(threat.GetEntity(), Prop_Data, "m_vecOrigin", vecLastKnownPos);

        GetEntPropVector(me.GetEntity(), Prop_Send, "m_vecOrigin", vecMyPos);
        if (GetVectorDistance(vecMyPos, vecLastKnownPos) < 500.0)
        {
            return true;
        }

        if (this.IsThreatFiringAtMe(threat.GetEntity()))
        {
            return true;
        }

        //TODO: Add sniper check

        if (bNormalDiff && bIsPlayer && (TF2_GetPlayerClass(iThreatEnt) == TFClass_Engineer || TF2_GetPlayerClass(iThreatEnt) == TFClass_Medic))
        {
            return true;
        }

        return false;
    }

    //(NextBotAction action, INextBot bot, int subject, CKnownEntity threat1, CKnownEntity threat2)
    public static CKnownEntity SelectMoreDangerousThreatInternal(INextBot bot, CKnownEntity threat1, CKnownEntity threat2)
    {
        CTFBotIntention intention = CTFBotIntention(bot.GetIntentionInterface());
        float vecThreat1Pos[3], vecThreat2Pos[3], vecMyPos[3];
        if (threat1 == NULL_KNOWN_ENTITY || threat1.IsObsolete())
        {
            return threat2;
        }
        if (threat2 == NULL_KNOWN_ENTITY || threat2.IsObsolete())
        {
            return threat1;
        }
        char szThreat1Name[64], szThreat2Name[64];
        GetEntityClassname(threat1.GetEntity(), szThreat1Name, sizeof(szThreat1Name));
        GetEntityClassname(threat2.GetEntity(), szThreat2Name, sizeof(szThreat2Name));
        bool bIsSentry1 = StrEqual(szThreat1Name, "obj_sentrygun");
        bool bIsSentry2 = StrEqual(szThreat2Name, "obj_sentrygun");

        bool bShouldFearSentryGuns = true;

        if (CBaseEntity(bot.GetEntity()).HasProp(Prop_Data, "m_bDontFearSentries"))
            bShouldFearSentryGuns = !CBaseEntity(bot.GetEntity()).GetProp(Prop_Data, "m_bDontFearSentries");

        CKnownEntity closerThreat = NULL_KNOWN_ENTITY;

        GetEntPropVector(bot.GetEntity(), Prop_Send, "m_vecOrigin", vecMyPos);
        GetEntPropVector(threat1.GetEntity(), Prop_Send, "m_vecOrigin", vecThreat1Pos);
        GetEntPropVector(threat2.GetEntity(), Prop_Send, "m_vecOrigin", vecThreat2Pos);

        if (GetVectorDistance(vecMyPos, vecThreat1Pos) < GetVectorDistance(vecMyPos, vecThreat2Pos))
        {
            closerThreat = threat1;
        }
        else
        {
            closerThreat = threat2;
        }

        if (bShouldFearSentryGuns)
        {
            if (bIsSentry1 && GetVectorDistance(vecMyPos, vecThreat1Pos) <= 1100.0 && CTFBotIntention.IsActiveSentry(threat1.GetEntity()))
            {
                if (bIsSentry2 && GetVectorDistance(vecMyPos, vecThreat2Pos) <= 1100.0 && CTFBotIntention.IsActiveSentry(threat2.GetEntity()))
                {
                    return closerThreat;
                }
                return threat1;
            }

            if (bIsSentry2 && GetVectorDistance(vecMyPos, vecThreat2Pos) <= 1100.0)
            {
                return threat2;
            }
        }

        bool isImmediateThreat1 = intention.IsImmediateThreat(threat1);
        bool isImmediateThreat2 = intention.IsImmediateThreat(threat2);

        //PrintCenterTextAll("threat1 %i %b threat 2 %i %b", threat1.GetEntity(), isImmediateThreat1, threat2.GetEntity(), isImmediateThreat2);

        if (isImmediateThreat1 && !isImmediateThreat2)
            return threat1;
        else if (!isImmediateThreat1 && isImmediateThreat2)
            return threat2;
        else if (!isImmediateThreat1 && !isImmediateThreat2)
            return closerThreat;

        if (intention.IsThreatFiringAtMe(threat1))
        {
            if (intention.IsThreatFiringAtMe(threat2))
                return closerThreat;
            return threat1;
        }
        else if (intention.IsThreatFiringAtMe(threat2))
        {
            return threat2;
        }

        return closerThreat;
    }

    public void UpdateTimeSinceVisible()
    {
        INextBot bot = this.GetBot();
        CBaseEntity ent = CBaseEntity(bot.GetEntity());
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
    }

    public void OnWeaponFired(int whoFired, int weapon)
    {
        INextBot bot = this.GetBot();
        CBaseEntity ent = CBaseEntity(bot.GetEntity());

        float vecPlayerPos[3], vecPos[3];
        GetEntPropVector(bot.GetEntity(), Prop_Send, "m_vecOrigin", vecPos);
        GetEntPropVector(whoFired, Prop_Send, "m_vecOrigin", vecPlayerPos);
        if (GetVectorDistance(vecPos, vecPlayerPos) >= 3000.0)
            return;

        int iNoticeChance = 100;
        if (weapon > 0 && CTFBotIntention.IsQuietWeapon(weapon))
        {
            if (GetVectorDistance(vecPos, vecPlayerPos) >= 500.0)
                return;

            switch (ent.GetProp(Prop_Data, "m_iSkill"))
            {
                case BOT_SKILL_EASY:
                    iNoticeChance = 10;
                case BOT_SKILL_NORMAL:
                    iNoticeChance = 30;
                case BOT_SKILL_HARD:
                    iNoticeChance = 60;
                case BOT_SKILL_EXPERT:
                    iNoticeChance = 90;
            }

            if (ent.GetPropFloat(Prop_Data, "m_flNoisyTime") > GetGameTime())
                iNoticeChance /= 2;
        }
        else if (GetVectorDistance(vecPos, vecPlayerPos) <= 1000.0)
        {
            ent.SetPropFloat(Prop_Data, "m_flNoisyTime", GetGameTime() + 3.0);
        }

        if (GetRandomInt(1, 100) > iNoticeChance)
            return;

        ent.MyNextBotPointer().GetVisionInterface().AddKnownEntity(whoFired);
    }

    public static bool IsQuietWeapon(int weapon)
    {
        switch (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
        {
            case TF_WEAPON_KNIFE, TF_WEAPON_FISTS, TF_WEAPON_PDA, TF_WEAPON_PDA_ENGINEER_BUILD, TF_WEAPON_PDA_ENGINEER_DESTROY, TF_WEAPON_PDA_SPY, TF_WEAPON_BUILDER, TF_WEAPON_MEDIGUN, TF_WEAPON_DISPENSER, TF_WEAPON_INVIS, TF_WEAPON_FLAREGUN, TF_WEAPON_LUNCHBOX, TF_WEAPON_JAR, TF_WEAPON_COMPOUND_BOW, TF_WEAPON_SWORD, TF_WEAPON_CROSSBOW:
                return true;
        }
        return false;
    }

    public static void OnClientWeaponFired(int client, int weapon)
    {
        //If engineer hit wrench behind the sentry, nextbot who doesn't fear sentries, can change priority from sentry to engineer
        //TODO: Maybe ignore melee attacks completely?
        if (TF2_GetPlayerClass(client) == TFClass_Engineer)
        {
            if (weapon != GetPlayerWeaponSlot(client, 2))
                g_flWeaponFired[client] = GetGameTime();
        }
        else
        {
            g_flWeaponFired[client] = GetGameTime();
        }

        //Yes, if you want to use this sp file for your custom nextbot, you need to change this class name
        int iEnt = -1;
        while ((iEnt = FindEntityByClassname(iEnt, NEXTBOT_CUSTOM_CLASS_NAME)) != INVALID_ENT_REFERENCE)
        {
            CTFBotIntention(CBaseEntity(iEnt).MyNextBotPointer().GetIntentionInterface()).OnWeaponFired(client, GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"));
        }
    }

    public static void OnSentryGunFired(int sentry)
    {
        if (sentry > 2048 + 1)
            return;

        g_flSentryGunFired[sentry] = GetGameTime();
    }

    public static CKnownEntity SelectMoreDangerousThreat(INextBot bot, CKnownEntity threat1, CKnownEntity threat2)
    {
        CKnownEntity threat = CTFBotIntention.SelectMoreDangerousThreatInternal(bot, threat1, threat2);
        CBaseEntity ent = CBaseEntity(bot.GetEntity());

        if (!ent.HasProp(Prop_Data, "m_iSkill"))
            return threat;

        if (ent.GetProp(Prop_Data, "m_iSkill") == BOT_SKILL_EASY)
        {
            return threat;
        }

        if (ent.HasProp(Prop_Data, "m_flTCRandom") && ent.HasProp(Prop_Data, "m_flNextRandomTime") && GetGameTime() > ent.GetPropFloat(Prop_Data, "m_flTCRandom"))
        {
            ent.SetPropFloat(Prop_Data, "m_flTCRandom", GetURandomFloat());
            ent.SetPropFloat(Prop_Data, "m_flNextRandomTime", GetGameTime() + 10.0);
        }

        if (ent.GetProp(Prop_Data, "m_iSkill") == BOT_SKILL_NORMAL && ent.HasProp(Prop_Data, "m_flTCRandom") && ent.GetPropFloat(Prop_Data, "m_flTCRandom") < 0.5)
        {
            return threat;
        }

        CKnownEntity hHealer = CTFBotIntention(bot.GetIntentionInterface()).GetHealerOfThreat(threat);
        if (hHealer != NULL_KNOWN_ENTITY && bot.GetVisionInterface().IsAbleToSeeTarget(hHealer.GetEntity(), DISREGARD_FOV))
        {
            return hHealer;
        }

        return threat;
    }

    //If a threat standing on a static prop, then he is not on a navmesh, this is very bad
    //Fixed by adding GetNearestNavArea, but required a lot of testing
    public bool IsThreatOnNav(int threat)
    {
        //Doesn't check the ground?
        //CNavArea area = view_as<CNavMesh>(TheNavMesh).GetNavAreaEntity(threat, GETNAVAREA_CHECK_GROUND);

        //return area != NULL_AREA;

        //Threat is in air (falling down or rocket jumping), we need to check the ground under their feets to make sure they're still a valid target
        if (GetEntPropEnt(threat, Prop_Data, "m_hGroundEntity") == -1)
        {
            float vecThreatPos[3], vecUnderTargetFeet[3];
            GetEntPropVector(threat, Prop_Send, "m_vecOrigin", vecThreatPos);

            vecUnderTargetFeet[2] = vecThreatPos[2] - 9999999.0;
            Handle hTrace = TR_TraceRayFilterEx(vecThreatPos, vecUnderTargetFeet, (MASK_SOLID|CONTENTS_HITBOX), RayType_EndPoint, Filter_IgnoreEverything, threat);
            if (TR_DidHit(hTrace))
            {
                TR_GetEndPosition(vecThreatPos, hTrace);
            }
            delete hTrace;

            CNavArea area = view_as<CNavMesh>(TheNavMesh).GetNavArea(vecThreatPos, 120.0);

            //Player standing on a static prop (table, rock, etc)
            if (area == NULL_AREA)
            {
                //GetNearestNavArea(const float pos[3], bool anyZ = false, float maxDist = 10000.0, bool checkLOS = false, bool checkGround = true, int team = TEAM_ANY);

                area = view_as<CNavMesh>(TheNavMesh).GetNearestNavArea(vecThreatPos, true, 300.0, true, true);
            }
            return area != NULL_AREA;
        }
        else
        {
            CNavArea area = view_as<CNavMesh>(TheNavMesh).GetNavAreaEntity(threat, GETNAVAREA_CHECK_GROUND);

            if (area == NULL_AREA)
            {
                float vecThreatPos[3];
                GetEntPropVector(threat, Prop_Send, "m_vecOrigin", vecThreatPos);
                area = view_as<CNavMesh>(TheNavMesh).GetNearestNavArea(vecThreatPos, true, 300.0, true, true);
            }

            return area != NULL_AREA;
        }
    }

    //Used to skip expensive raycast,
    //TODO: Need more testing just in case
    public bool IsThreatPotentiallyVisibleNav(int threat)
    {
        //Using instead of GetLastKnownArea for sure
        CNavArea myArea = view_as<CNavMesh>(TheNavMesh).GetNavAreaEntity(this.GetBot().GetEntity(), GETNAVAREA_CHECK_GROUND);
        CNavArea subjectArea = view_as<CNavMesh>(TheNavMesh).GetNavAreaEntity(threat, GETNAVAREA_CHECK_GROUND);

        if (myArea && subjectArea)
        {
            if (!myArea.IsPotentiallyVisible(subjectArea))
                return false;
        }

        //Not on a navmesh, using raycast to prevent AI abuse (sitting on a building floor or a prop like big rock where is navmesh could not exist)
        return true;
    }
}
