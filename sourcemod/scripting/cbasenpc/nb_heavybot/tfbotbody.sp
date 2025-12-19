#define nb_head_aim_settle_duration 0.3

#define nb_head_aim_resettle_angle 100.0
#define nb_head_aim_resettle_time 0.3
#define nb_head_aim_steady_max_rate 100.0

#define DEBBUGING 0

methodmap CTFBotBody < IBody
{
    public CTFBotBody(IBody body)
    {
        return view_as<CTFBotBody>(body);
    }

    public static float GetHeadAimTrackingInterval(int skill)
    {
        switch (skill)
        {
            case BOT_SKILL_EASY:
                return 1.0;
            case BOT_SKILL_NORMAL:
                return 0.25;
            case BOT_SKILL_HARD:
                return 0.1;
            case BOT_SKILL_EXPERT:
                return 0.05;
        }
        return 0.05;
    }

    public bool IsHeadSteady()
    {
        INextBot bot = this.GetBot();
        CBaseEntity ent = CBaseEntity(bot.GetEntity());
        return ent.HasProp(Prop_Data, "m_flHeadSteadyTimer") && ent.GetPropFloat(Prop_Data, "m_flHeadSteadyTimer") > 0.0;
    }

    public float GetHeadSteadyDuration()
    {
        INextBot bot = this.GetBot();
        CBaseEntity ent = CBaseEntity(bot.GetEntity());
        if (ent.HasProp(Prop_Data, "m_flHeadSteadyTimer") && ent.GetPropFloat(Prop_Data, "m_flHeadSteadyTimer") > 0.0)
            return GetGameTime() - ent.GetPropFloat(Prop_Data, "m_flHeadSteadyTimer");
    }

    public void AimHeadTowards(int target, int priority, float duration, const char[] reason = "")
    {
        INextBot bot = this.GetBot();
        if (duration <= 0.0)
            duration = 0.1;
        CBaseEntity ent = CBaseEntity(bot.GetEntity());
        if (ent.GetProp(Prop_Data, "m_iLookAtPriority") == priority)
        {
            if (!this.IsHeadSteady() || this.GetHeadSteadyDuration() < nb_head_aim_settle_duration)
            {
                return;
            }
        }

        if (ent.GetProp(Prop_Data, "m_iLookAtPriority") > priority && ent.GetPropFloat(Prop_Data, "m_flLookAtExpireTimer") > GetGameTime())
        {
            return;
        }

        ent.SetPropFloat(Prop_Data, "m_flLookAtExpireTimer", GetGameTime() + duration);

        ent.SetPropEnt(Prop_Data, "m_hLookAtSubject", target);
        ent.SetProp(Prop_Data, "m_iLookAtPriority", priority);
        ent.SetPropFloat(Prop_Data, "m_flLookAtDurationTimer", GetGameTime());
        ent.SetProp(Prop_Data, "m_bHasBeenSightedIn", false);

        //To get rid off warning because I'm too lazy get rid of reason variable
        if (priority == 9999)
        {
            PrintToServer("Reason %s", reason);
        }
    }

    public bool IsHeadAimingOnTarget()
    {
        INextBot bot = this.GetBot();
        CBaseEntity ent = CBaseEntity(bot.GetEntity());
        return ent.HasProp(Prop_Data, "m_bIsSightedIn") && ent.GetProp(Prop_Data, "m_bIsSightedIn");
    }

    public static float GetMaxHeadAngularVelocity()
    {
        return 3000.0;
    }

    public void Upkeep()
    {
        INextBot bot = this.GetBot();
        CBaseEntity ent = CBaseEntity(bot.GetEntity());

        float flDeltaT = GetGameFrameTime();
        if (flDeltaT < 0.00001)
            return;

        float angCurrentAngles[3];
        ent.GetPropVector(Prop_Data, "m_angCurrentAngles", angCurrentAngles);

        bool bIsSteady = true;
        float angPriorAngles[3];
        ent.GetPropVector(Prop_Data, "m_angPriorAngles", angPriorAngles);

        float flActualPitchRate = AngleDiff(angCurrentAngles[0], angPriorAngles[0]);
        if (FloatAbs(flActualPitchRate) > nb_head_aim_steady_max_rate * flDeltaT)
        {
            bIsSteady = false;
        }
        else
        {
            float flActualYawRate = AngleDiff(angCurrentAngles[1], angPriorAngles[1]);

            if (FloatAbs(flActualYawRate) > nb_head_aim_steady_max_rate * flDeltaT)
                bIsSteady = false;
        }

        if (bIsSteady)
        {
            if (ent.GetPropFloat(Prop_Data, "m_flHeadSteadyTimer") <= 0.0)
            {
                ent.SetPropFloat(Prop_Data, "m_flHeadSteadyTimer", GetGameTime());
            }
        }
        else
        {
            ent.SetPropFloat(Prop_Data, "m_flHeadSteadyTimer", -1.0);
        }

        ent.SetPropVector(Prop_Data, "m_angPriorAngles", angCurrentAngles);

        if (ent.GetProp(Prop_Data, "m_bHasBeenSightedIn") && GetGameTime() > ent.GetPropFloat(Prop_Data, "m_flLookAtExpireTimer"))
            return;

        float vecForward[3];
        GetAngleVectors(angCurrentAngles, vecForward, NULL_VECTOR, NULL_VECTOR);

        float vecAnchorForward[3];
        ent.GetPropVector(Prop_Data, "m_vecAnchorForward", vecAnchorForward);
        float flDeltaAngle = RAD2DEG(ArcCosine(GetVectorDotProduct(vecForward, vecAnchorForward)));
        if (flDeltaAngle > nb_head_aim_resettle_angle)
        {
            ent.SetPropFloat(Prop_Data, "m_flAnchorRepositionTimer", GetGameTime() + (GetRandomFloat(0.9, 1.1) * nb_head_aim_resettle_time));
            ent.SetPropVector(Prop_Data, "m_vecAnchorForward", vecForward);
            return;
        }

        if (ent.GetPropFloat(Prop_Data, "m_flAnchorRepositionTimer") != -1.0 && ent.GetPropFloat(Prop_Data, "m_flAnchorRepositionTimer") > GetGameTime())
            return;
        ent.SetPropFloat(Prop_Data, "m_flAnchorRepositionTimer", -1.0);

        int iSubject = ent.GetPropEnt(Prop_Data, "m_hLookAtSubject");
        if (iSubject != -1 && IsValidEntity(iSubject))
        {
            if (GetGameTime() > ent.GetPropFloat(Prop_Data, "m_flLookAtTrackingTimer"))
            {
                float vecDesiredLookAtPos[3], vecAbsVelocity[3];
                CBaseAnimating(iSubject).WorldSpaceCenter(vecDesiredLookAtPos);

                CBaseEntity(iSubject).GetAbsVelocity(vecAbsVelocity);

                vecDesiredLookAtPos[0] += 0.0 * vecAbsVelocity[0];
                vecDesiredLookAtPos[1] += 0.0 * vecAbsVelocity[1];
                vecDesiredLookAtPos[2] += 0.0 * vecAbsVelocity[2];

                float vecErrorVector[3];
                float vecLookAtPos[3];
                ent.GetPropVector(Prop_Data, "m_vecLookAtPos", vecLookAtPos);
                SubtractVectors(vecDesiredLookAtPos, vecLookAtPos, vecErrorVector);
                float flError = NormalizeVector(vecErrorVector, vecErrorVector);

                float flTrackInterval = Max(CTFBotBody.GetHeadAimTrackingInterval(ent.GetProp(Prop_Data, "m_iSkill")), flDeltaT);

                float flErrorVel = flError / flTrackInterval;

                float vecLookAtVelocity[3];
                vecLookAtVelocity[0] = (flErrorVel * vecErrorVector[0]) + vecAbsVelocity[0];
                vecLookAtVelocity[1] = (flErrorVel * vecErrorVector[1]) + vecAbsVelocity[1];
                vecLookAtVelocity[2] = (flErrorVel * vecErrorVector[2]) + vecAbsVelocity[2];

                ent.SetPropFloat(Prop_Data, "m_flLookAtTrackingTimer", GetGameTime() + (GetRandomFloat(0.8, 1.2) * flTrackInterval));

                ent.SetPropVector(Prop_Data, "m_vecLookAtVelocity", vecLookAtVelocity);
            }

            float vecLookAtPos[3];
            ent.GetPropVector(Prop_Data, "m_vecLookAtPos", vecLookAtPos);
            float vecLookAtVelocity[3];
            ent.GetPropVector(Prop_Data, "m_vecLookAtVelocity", vecLookAtVelocity);

            vecLookAtPos[0] += flDeltaT * vecLookAtVelocity[0];
            vecLookAtPos[1] += flDeltaT * vecLookAtVelocity[1];
            vecLookAtPos[2] += flDeltaT * vecLookAtVelocity[2];
            ent.SetPropVector(Prop_Data, "m_vecLookAtPos", vecLookAtPos);
        }

        float vecLookAtPos[3];
        ent.GetPropVector(Prop_Data, "m_vecLookAtPos", vecLookAtPos);

        float vecEyePos[3];
        bot.GetBodyInterface().GetEyePosition(vecEyePos);

        float vecTo[3];
        SubtractVectors(vecLookAtPos, vecEyePos, vecTo);
        NormalizeVector(vecTo, vecTo);

        float angDesiredAngles[3];
        GetVectorAngles(vecTo, angDesiredAngles);

        #if DEBBUGING
            float vecTemp4[3];
            bot.GetBodyInterface().GetEyePosition(vecTemp4);
            float vecTemp3[3];
            vecTemp3[0] = vecTemp4[0] + (100.0 * vecForward[0]);
            vecTemp3[1] = vecTemp4[1] + (100.0 * vecForward[1]);
            vecTemp3[2] = vecTemp4[2] + (100.0 * vecForward[2]);

            int iColour2[4];
            iColour2[0] = 255;
            iColour2[1] = 255;
            iColour2[2] = 0;
            iColour2[3] = 255;

            TE_SetupBeamPoints(vecTemp4, vecTemp3, PrecacheModel("materials/sprites/physbeam.vmt"), PrecacheModel("materials/sprites/halo01.vmt"), 0, 15, 0.1, 1.0, 1.0, 1, 0.0, iColour2, 10);
            TE_SendToAll();

            float flThickness = bIsSteady ? 2.0 : 3.0;
            iColour2[0] = ent.GetProp(Prop_Data, "m_bIsSightedIn") ? 255 : 0;
            iColour2[1] = iSubject != -1 ? 255 : 0;
            iColour2[2] = 255;

            TE_SetupBeamPoints(vecTemp4, vecLookAtPos, PrecacheModel("materials/sprites/physbeam.vmt"), PrecacheModel("materials/sprites/halo01.vmt"), 0, 15, 0.1, 1.0, flThickness, 1, 0.0, iColour2, 10);
            TE_SendToAll();
        #endif

        float flDot = GetVectorDotProduct(vecForward, vecTo);
        if (flDot > 0.98)
        {
            ent.SetProp(Prop_Data, "m_bIsSightedIn", true);
            ent.SetProp(Prop_Data, "m_bHasBeenSightedIn", true);
        }
        else
        {
            ent.SetProp(Prop_Data, "m_bIsSightedIn", false);
        }

        float flApporachRate = CTFBotBody.GetMaxHeadAngularVelocity();

        if (flDot > 0.7)
        {
            float flT = RemapVal(flDot, 0.7, 1.0, 1.0, 0.02);
            flApporachRate *= Sine(1.57 * flT);
        }

        if (GetGameTime() - ent.GetPropFloat(Prop_Data, "m_flLookAtDurationTimer") < 0.25)
        {
            flApporachRate *= 4.0 * GetGameTime() - ent.GetPropFloat(Prop_Data, "m_flLookAtDurationTimer");
            //flApporachRate *= GetGameTime() - ent.GetPropFloat(Prop_Data, "m_flLookAtDurationTimer") / 0.25;
        }

        float angAngles[3];
        angAngles[1] = ApproachAngle(angDesiredAngles[1], angCurrentAngles[1], flApporachRate * flDeltaT);
        angAngles[0] = ApproachAngle(angDesiredAngles[0], angCurrentAngles[0], 0.5 * flApporachRate * flDeltaT);
        angAngles[2] = 0.0;

        angAngles[0] = AngleNormalize(angAngles[0]);
        angAngles[1] = AngleNormalize(angAngles[1]);

        ent.SetPropVector(Prop_Data, "m_angCurrentAngles", angAngles);
    }
}
