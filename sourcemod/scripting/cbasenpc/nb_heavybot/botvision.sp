#define BOT_VISION_VERSION "1.0"

//Define these in BeginDataMapDesc()
/*
    .DefineFloatField("m_flFOV")
    .DefineFloatField("m_flCosHalfFOV")
*/

methodmap CBotVision < IVision
{
    public CBotVision(IVision vision)
    {
        return view_as<CBotVision>(vision);
    }
    //TODO: Move IsAbleToSeeTarget IsLineOfSightClearToEntity

    public void GetViewVectorEx(float dir[3])
    {
        float angEyes[3], vecForward[3];
        CBaseEntity ent = CBaseEntity(this.GetBot().GetEntity());
        ent.GetPropVector(Prop_Data, "m_angCurrentAngles", angEyes);
        GetAngleVectors(angEyes, vecForward, NULL_VECTOR, NULL_VECTOR);

        dir = vecForward;
    }

    public bool IsInFieldOfViewEx(float pos[3])
    {
        INextBot bot = this.GetBot();
        CBaseEntity ent = CBaseEntity(bot.GetEntity());

        float vecEyePos[3], vecViewDir[3];
        CBotBody(bot.GetBodyInterface()).GetEyePositionEx(vecEyePos);
        this.GetViewVectorEx(vecViewDir);

        return PointWithinViewAngle(vecEyePos, pos, vecViewDir, ent.GetPropFloat(Prop_Data, "m_flCosHalfFOV"));
    }

    public bool IsInFieldOfViewTargetEx(int subject)
    {
        float vecCenter[3];
        CBaseAnimating(subject).WorldSpaceCenter(vecCenter);
        if (this.IsInFieldOfViewEx(vecCenter))
            return true;

        if (subject > 0 && subject <= MaxClients)
        {
            GetClientEyePosition(subject, vecCenter);
            return this.IsInFieldOfViewEx(vecCenter);
        }

        return false;
    }

    //Even if IVision doens't contain SetFieldOfView (vision.inc) for now, I'll call with Ex to avoid code break
    public void SetFieldOfViewEx(float fov)
    {
        CBaseEntity ent = CBaseEntity(this.GetBot().GetEntity());
        ent.SetPropFloat(Prop_Data, "m_flFOV", fov);
        ent.SetPropFloat(Prop_Data, "m_flCosHalfFOV", Cosine(0.5 * fov * FLOAT_PI / 180.0));
    }
}
