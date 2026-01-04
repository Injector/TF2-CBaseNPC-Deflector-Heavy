#define nb_head_aim_settle_duration 0.3

#define nb_head_aim_resettle_angle 100.0
#define nb_head_aim_resettle_time 0.3
#define nb_head_aim_steady_max_rate 100.0

#define DEBBUGING 1

#define TFBOT_BODY_VERSION "1.3"

methodmap CTFBotBody < IBody
{
    property float m_flHeadSteadyTimer
    {
        public get()
        {
            return CBaseEntity(this.GetBot().GetEntity()).GetPropFloat(Prop_Data, "m_flHeadSteadyTimer");
        }

        public set(float value)
        {
            CBaseEntity(this.GetBot().GetEntity()).SetPropFloat(Prop_Data, "m_flHeadSteadyTimer", value);
        }
    }

    property float m_flAnchorRepositionTimer
    {
        public get()
        {
            return CBaseEntity(this.GetBot().GetEntity()).GetPropFloat(Prop_Data, "m_flAnchorRepositionTimer");
        }

        public set(float value)
        {
            CBaseEntity(this.GetBot().GetEntity()).SetPropFloat(Prop_Data, "m_flAnchorRepositionTimer", value);
        }
    }

    property float m_flLookAtExpireTimer
    {
        public get()
        {
            return CBaseEntity(this.GetBot().GetEntity()).GetPropFloat(Prop_Data, "m_flLookAtExpireTimer");
        }

        public set(float value)
        {
            CBaseEntity(this.GetBot().GetEntity()).SetPropFloat(Prop_Data, "m_flLookAtExpireTimer", value);
        }
    }

    property float m_flLookAtTrackingTimer
    {
        public get()
        {
            return CBaseEntity(this.GetBot().GetEntity()).GetPropFloat(Prop_Data, "m_flLookAtTrackingTimer");
        }

        public set(float value)
        {
            CBaseEntity(this.GetBot().GetEntity()).SetPropFloat(Prop_Data, "m_flLookAtTrackingTimer", value);
        }
    }

    property float m_flLookAtDurationTimer
    {
        public get()
        {
            return CBaseEntity(this.GetBot().GetEntity()).GetPropFloat(Prop_Data, "m_flLookAtDurationTimer");
        }

        public set(float value)
        {
            CBaseEntity(this.GetBot().GetEntity()).SetPropFloat(Prop_Data, "m_flLookAtDurationTimer", value);
        }
    }

    property bool m_bHasBeenSightedIn
    {
        public get()
        {
            return CBaseEntity(this.GetBot().GetEntity()).GetProp(Prop_Data, "m_bHasBeenSightedIn");
        }

        public set(bool value)
        {
            CBaseEntity(this.GetBot().GetEntity()).SetProp(Prop_Data, "m_bHasBeenSightedIn", value);
        }
    }

    property bool m_bIsSightedIn
    {
        public get()
        {
            return CBaseEntity(this.GetBot().GetEntity()).GetProp(Prop_Data, "m_bIsSightedIn");
        }

        public set(bool value)
        {
            CBaseEntity(this.GetBot().GetEntity()).SetProp(Prop_Data, "m_bIsSightedIn", value);
        }
    }

    property int m_iLookAtPriority
    {
        public get()
        {
            return CBaseEntity(this.GetBot().GetEntity()).GetProp(Prop_Data, "m_iLookAtPriority");
        }

        public set(int value)
        {
            CBaseEntity(this.GetBot().GetEntity()).SetProp(Prop_Data, "m_iLookAtPriority", value);
        }
    }

    property CBaseEntity m_hLookAtSubject
    {
        public get()
        {
            return CBaseEntity(CBaseEntity(this.GetBot().GetEntity()).GetPropEnt(Prop_Data, "m_hLookAtSubject"));
        }

        public set(CBaseEntity value)
        {
            CBaseEntity(this.GetBot().GetEntity()).SetPropEnt(Prop_Data, "m_hLookAtSubject", value.index);
        }
    }

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

    public void AimHeadTowards(float pos[3], int priority, float duration, const char[] reason = "")
    {
        INextBot bot = this.GetBot();
        if (duration <= 0.0)
            duration = 0.1;
        CBaseEntity ent = CBaseEntity(bot.GetEntity());
        if (ent.GetProp(Prop_Data, "m_iLookAtPriority") == priority)
        {
            if (!this.IsHeadSteady() || this.GetHeadSteadyDuration() < nb_head_aim_settle_duration)
            {
                //Looks like I finnaly found the culprit behid the poorly aim, the culprit is... steady checks... (if a target moving a little, then ai whill stop shooting)
                //return;
            }
        }

        if (ent.GetProp(Prop_Data, "m_iLookAtPriority") > priority && ent.GetPropFloat(Prop_Data, "m_flLookAtExpireTimer") > GetGameTime())
        {
            return;
        }

        ent.SetPropFloat(Prop_Data, "m_flLookAtExpireTimer", GetGameTime() + duration);

        ent.SetPropEnt(Prop_Data, "m_hLookAtSubject", -1);
        ent.SetPropVector(Prop_Data, "m_vecLookAtPos", pos);
        ent.SetProp(Prop_Data, "m_iLookAtPriority", priority);
        ent.SetPropFloat(Prop_Data, "m_flLookAtDurationTimer", GetGameTime());
        ent.SetProp(Prop_Data, "m_bHasBeenSightedIn", false);

        //To get rid off warning because I'm too lazy get rid of reason variable
        if (priority == 9999)
        {
            PrintToServer("Reason %s", reason);
        }
    }

    //TODO: Rewrite AimHeadTowards too?
    public void AimHeadTowardsTarget(int target, int priority, float duration, const char[] reason = "")
    {
        if (duration <= 0.0)
        {
            duration = 0.1;
        }

        if (priority > this.m_iLookAtPriority || this.m_flLookAtExpireTimer <= GetGameTime())
        {
            this.m_flLookAtExpireTimer = GetGameTime() + duration;
            this.m_iLookAtPriority = priority;

            CBaseEntity prevTarget = this.m_hLookAtSubject;
            if (prevTarget.index == -1 || target != prevTarget.index)
            {
                this.m_hLookAtSubject = CBaseEntity(target);
                this.m_flLookAtDurationTimer = GetGameTime();
                this.m_bIsSightedIn = false;
            }
        }

        if (priority == 9999)
        {
            PrintToServer("Reason %s", reason);
        }

        /* INextBot bot = this.GetBot();
        if (duration <= 0.0)
            duration = 0.1;
        CBaseEntity ent = CBaseEntity(bot.GetEntity());
        if (ent.GetProp(Prop_Data, "m_iLookAtPriority") == priority)
        {
            //We need to wait before we can call AimHeadTowards again. If we call AimHeadTowards too often, nextbots with skills lower than export, will move their aim very slowly
            if (ent.GetPropFloat(Prop_Data, "m_flLookAtExpireTimer") > GetGameTime())
            {
                return;
            }
            if (!this.IsHeadSteady() || this.GetHeadSteadyDuration() < nb_head_aim_settle_duration)
            {
                //Looks like I finnaly found the culprit behid the poorly aim, the culprit is... steady checks... (if a target moving a little, then ai whill stop shooting)
                //return;
            }
        }

        if (ent.GetProp(Prop_Data, "m_iLookAtPriority") > priority && ent.GetPropFloat(Prop_Data, "m_flLookAtExpireTimer") > GetGameTime())
        {
            return;
        }

        if (priority > ent.GetProp(Prop_Data, "m_iLookAtPriority") || ent.GetPropFloat(Prop_Data, "m_flLookAtExpireTimer") <= GetGameTime())
        {
            ent.SetPropFloat(Prop_Data, "m_flLookAtExpireTimer", GetGameTime() + duration);

            ent.SetPropEnt(Prop_Data, "m_hLookAtSubject", target);
            ent.SetProp(Prop_Data, "m_iLookAtPriority", priority);
            ent.SetPropFloat(Prop_Data, "m_flLookAtDurationTimer", GetGameTime());
            ent.SetProp(Prop_Data, "m_bHasBeenSightedIn", false);
        }
        //To get rid off warning because I'm too lazy get rid of reason variable
        if (priority == 9999)
        {
            PrintToServer("Reason %s", reason);
        } */
    }

    public bool IsHeadAimingOnTarget()
    {
        INextBot bot = this.GetBot();
        CBaseEntity ent = CBaseEntity(bot.GetEntity());
        return ent.HasProp(Prop_Data, "m_bIsSightedIn") && ent.GetProp(Prop_Data, "m_bIsSightedIn");
    }

    public static float GetMaxHeadAngularVelocity()
    {
        return 1000.0;
    }

    public void Upkeep()
    {
        float flDeltaT = GetGameFrameTime();

        if (flDeltaT < (1.0 * 10.0 ^ -5.0))
            return;

        INextBot bot = this.GetBot();
        CBaseEntity ent = CBaseEntity(bot.GetEntity());

        float angCurrentAngles[3];
        ent.GetPropVector(Prop_Data, "m_angCurrentAngles", angCurrentAngles);

        float angPriorAngles[3];
        ent.GetPropVector(Prop_Data, "m_angPriorAngles", angPriorAngles);

        if (FloatAbs(float(RoundToFloor(AngleDiff(angCurrentAngles[0], angPriorAngles[0])))) > (flDeltaT * nb_head_aim_steady_max_rate) || FloatAbs(float(RoundToFloor(AngleDiff(angCurrentAngles[1], angPriorAngles[1])))) > (flDeltaT * nb_head_aim_steady_max_rate))
        {
            this.m_flHeadSteadyTimer = -1.0;
        }
        else
        {
            if (this.m_flHeadSteadyTimer == -1.0)
            {
                this.m_flHeadSteadyTimer = GetGameTime();
            }
        }

        ent.SetPropVector(Prop_Data, "m_angPriorAngles", angCurrentAngles);

        if (this.m_bHasBeenSightedIn && this.m_flLookAtExpireTimer <= GetGameTime())
            return;

        float vecForward[3];
        GetAngleVectors(angCurrentAngles, vecForward, NULL_VECTOR, NULL_VECTOR);

        float vecAnchorForward[3];
        ent.GetPropVector(Prop_Data, "m_vecAnchorForward", vecAnchorForward);

        //TODO: ArcCosine always return 90, what the point of this?
        if (ArcCosine(GetVectorDotProduct(vecAnchorForward, vecForward)) * (180.0 / FLOAT_PI) > nb_head_aim_resettle_angle)
        {
            this.m_flAnchorRepositionTimer = GetGameTime() + nb_head_aim_resettle_time * GetRandomFloat(0.9, 1.1);
            ent.SetPropVector(Prop_Data, "m_vecAnchorForward", vecForward);
        }
        else if (this.m_flAnchorRepositionTimer == -1.0 || this.m_flAnchorRepositionTimer <= GetGameTime())
        {
            this.m_flAnchorRepositionTimer = -1.0;

            CBaseEntity subject = this.m_hLookAtSubject;
            if (subject.index > 0 && subject.IsValid())
            {
                float vecDesiredLookAtPos[3];
                //TODO: Make CTFBotBody inherits CBotBody
                CBotBody(bot.GetBodyInterface()).IsAbleToSeeTarget(subject.index, vecDesiredLookAtPos);

                if (IsNullVector(vecDesiredLookAtPos))
                    CBaseAnimating(subject.index).WorldSpaceCenter(vecDesiredLookAtPos);

                float vecAbsVelocity[3];
                subject.GetAbsVelocity(vecAbsVelocity);

                float vecLookAtPos[3];
                ent.GetPropVector(Prop_Data, "m_vecLookAtPos", vecLookAtPos);

                if (this.m_flLookAtTrackingTimer <= GetGameTime())
                {
                    float vecErrorVector[3];
                    SubtractVectors(vecDesiredLookAtPos, vecLookAtPos, vecErrorVector);

                    float flLead = 0.0;

                    vecErrorVector[0] += (flLead * vecAbsVelocity[0]);
                    vecErrorVector[1] += (flLead * vecAbsVelocity[1]);
                    vecErrorVector[2] += (flLead * vecAbsVelocity[2]);

                    float flTrackInterval = Max(flDeltaT, CTFBotBody.GetHeadAimTrackingInterval(ent.GetProp(Prop_Data, "m_iSkill")));

                    float flScale = GetVectorLength(vecErrorVector) / flTrackInterval;
                    NormalizeVector(vecErrorVector, vecErrorVector);

                    float vecLookAtVelocity[3];
                    vecLookAtVelocity[0] = (flScale * vecErrorVector[0]) + vecAbsVelocity[0];
                    vecLookAtVelocity[1] = (flScale * vecErrorVector[1]) + vecAbsVelocity[1];
                    vecLookAtVelocity[2] = (flScale * vecErrorVector[2]) + vecAbsVelocity[2];
                    ent.SetPropVector(Prop_Data, "m_vecLookAtVelocity", vecLookAtVelocity);

                    this.m_flLookAtTrackingTimer = GetGameTime() + (flTrackInterval * GetRandomFloat(0.8, 1.2));
                }

                float vecLookAtVelocity[3];
                ent.GetPropVector(Prop_Data, "m_vecLookAtVelocity", vecLookAtVelocity);

                vecLookAtPos[0] += flDeltaT * vecLookAtVelocity[0];
                vecLookAtPos[1] += flDeltaT * vecLookAtVelocity[1]
                vecLookAtPos[2] += flDeltaT * vecLookAtVelocity[2];

                ent.SetPropVector(Prop_Data, "m_vecLookAtPos", vecLookAtPos);
            }
        }

        float vecEyePos[3], vecTo[3];
        CBotBody(bot.GetBodyInterface()).GetEyePositionEx(vecEyePos);

        float vecLookAtPos[3];
        ent.GetPropVector(Prop_Data, "m_vecLookAtPos", vecLookAtPos);
        SubtractVectors(vecLookAtPos, vecEyePos, vecTo);
        NormalizeVector(vecTo, vecTo);

        float angTo[3];
        GetVectorAngles(vecTo, angTo);

        float flDot = GetVectorDotProduct(vecTo, vecForward);

        if (flDot <= 0.98)
        {
            this.m_bIsSightedIn = false;
        }
        else
        {
            this.m_bIsSightedIn = true;

            if (!this.m_bHasBeenSightedIn)
            {
                this.m_bHasBeenSightedIn = true;
            }
        }

        float flMax = CTFBotBody.GetMaxHeadAngularVelocity();

        if (flDot > 0.7)
        {
            flMax *= Sine((3.14 / 2.0) * (1.0 + ((-49.0 / 15.0) * (flDot - 0.7))));
        }

        if (this.m_flLookAtDurationTimer != -1.0 && (GetGameTime() - this.m_flLookAtDurationTimer < 0.25))
        {
            flMax *= 4.0 * (GetGameTime() - this.m_flLookAtDurationTimer);
        }

        float angAngles[3];
        angAngles[0] = ApproachAngle(angTo[0], angCurrentAngles[0], (flMax * flDeltaT) * 0.5);
        angAngles[1] = ApproachAngle(angTo[1], angCurrentAngles[1], (flMax * flDeltaT));
        angAngles[2] = 0.0;

        angAngles[0] = AngleNormalize(angAngles[0]);
        angAngles[1] = AngleNormalize(angAngles[1]);

        ent.SetPropVector(Prop_Data, "m_angCurrentAngles", angAngles);

        if (ent.HasProp(Prop_Data, "m_bOverrideFaceTowards") && ent.GetProp(Prop_Data, "m_bOverrideFaceTowards"))
        {
            bot.GetLocomotionInterface().FaceTowards(vecLookAtPos);
        }
    }

    public void UpkeepLegacy()
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
        CBotBody(bot.GetBodyInterface()).GetEyePositionEx(vecEyePos);

        float vecTo[3];
        SubtractVectors(vecLookAtPos, vecEyePos, vecTo);
        NormalizeVector(vecTo, vecTo);

        float angDesiredAngles[3];
        GetVectorAngles(vecTo, angDesiredAngles);

        #if DEBBUGING
            float vecDbgEyePos[3];
            CBotBody(bot.GetBodyInterface()).GetEyePositionEx(vecDbgEyePos);
            float vecDbgDir[3];
            vecDbgDir[0] = vecDbgEyePos[0] + (100.0 * vecForward[0]);
            vecDbgDir[1] = vecDbgEyePos[1] + (100.0 * vecForward[1]);
            vecDbgDir[2] = vecDbgEyePos[2] + (100.0 * vecForward[2]);

            int iColour2[4];
            iColour2[0] = 255;
            iColour2[1] = 255;
            iColour2[2] = 0;
            iColour2[3] = 255;

            TE_SetupBeamPoints(vecDbgEyePos, vecDbgDir, PrecacheModel("materials/sprites/physbeam.vmt"), PrecacheModel("materials/sprites/halo01.vmt"), 0, 15, 0.1, 1.0, 1.0, 1, 0.0, iColour2, 10);
            TE_SendToAll();

            float flThickness = 1.0;
            //float flThickness = bIsSteady ? 2.0 : 3.0;
            //iColour2[0] = ent.GetProp(Prop_Data, "m_bIsSightedIn") ? 255 : 0;
            //iColour2[1] = iSubject != -1 ? 255 : 0;
            iColour2[0] = 255;
            iColour2[1] = 255;
            iColour2[2] = 255;

            TE_SetupBeamPoints(vecDbgEyePos, vecLookAtPos, PrecacheModel("materials/sprites/physbeam.vmt"), PrecacheModel("materials/sprites/halo01.vmt"), 0, 15, 0.1, 1.0, flThickness, 1, 0.0, iColour2, 10);
            TE_SendToAll();

            Handle hTrace = TR_TraceRayFilterEx(vecDbgEyePos, angCurrentAngles, (MASK_SOLID|CONTENTS_HITBOX), RayType_Infinite, Filter_WorldOnly, bot.GetEntity());

            float vecDbgEnd[3];
            TR_GetEndPosition(vecDbgEnd, hTrace);
            delete hTrace;

            iColour2[0] = 255;
            iColour2[1] = 0;
            iColour2[2] = 0;

            TE_SetupBeamPoints(vecDbgEyePos, vecDbgEnd, PrecacheModel("materials/sprites/physbeam.vmt"), PrecacheModel("materials/sprites/halo01.vmt"), 0, 15, 0.1, 1.0, 1.25, 1, 0.0, iColour2, 10);
            TE_SendToAll();

            if (iSubject != -1)
            {
                iColour2[0] = 0;
                iColour2[1] = 0;
                iColour2[2] = 255;

                float vecDbgLook[3];
                CBaseAnimating(iSubject).WorldSpaceCenter(vecDbgLook);

                TE_SetupBeamPoints(vecDbgEyePos, vecDbgLook, PrecacheModel("materials/sprites/physbeam.vmt"), PrecacheModel("materials/sprites/halo01.vmt"), 0, 15, 0.1, 1.0, flThickness, 1, 0.0, iColour2, 10);
                TE_SendToAll();
            }
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
            //flApporachRate *= 4.0 * GetGameTime() - ent.GetPropFloat(Prop_Data, "m_flLookAtDurationTimer");
            flApporachRate *= GetGameTime() - ent.GetPropFloat(Prop_Data, "m_flLookAtDurationTimer") / 0.25;
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
