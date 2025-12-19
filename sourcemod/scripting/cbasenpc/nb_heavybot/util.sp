
char g_szDebugDataMapCheck[][] =
{
    "m_iSkill",
    "m_hTarget",
    "m_flTimeSinceVisibleThreats",
    "m_bDontFearSentries",
    "m_flNoisyTime",
    "m_flNextScanEnemies",
    "m_flTCRandom",
    "m_flNextRandomTime",
    "m_iNumOfFailedTraces",
    "m_flEyePosHeight",
    "m_flNoisyTime",

    "m_angCurrentAngles",
    "m_angPriorAngles",
    "m_flHeadSteadyTimer",
    "m_bHasBeenSightedIn",
    "m_flAnchorRepositionTimer",
    "m_flLookAtExpireTimer",
    "m_vecAnchorForward",
    "m_flLookAtTrackingTimer",
    "m_vecLookAtPos",
    "m_vecLookAtVelocity",
    "m_flLookAtDurationTimer",
    "m_bIsSightedIn",
    "m_iLookAtPriority",
    "m_hLookAtSubject"
}

methodmap CNextBot
{
    public static void CheckDataMap(int entity)
    {
        CBaseEntity ent = CBaseEntity(entity);
        int iNumOfFailed = 0;
        for (int i = 0; i < sizeof(g_szDebugDataMapCheck); i++)
        {
            if (!ent.HasProp(Prop_Data, g_szDebugDataMapCheck[i]))
            {
                LogError("Couldn't find prop '%s' on NextBot '%s', please check botbody.sp, tfbotbody.sp, tfbotintention.sp");
                iNumOfFailed++;
            }
        }
        if (iNumOfFailed > 0)
        {
            LogError("NextBot '%s', failed props count %i/%i");
        }
    }
}
