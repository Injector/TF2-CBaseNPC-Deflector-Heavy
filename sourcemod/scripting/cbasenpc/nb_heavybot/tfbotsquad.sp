
methodmap CTFBotSquad < INextBot
{
    public CTFBotSquad(INextBot bot)
    {
        return view_as<CTFBotSquad>(bot);
    }

    public bool ShouldSquadLeaderWaitForFormation()
    {
        CBaseEntity ent = CBaseEntity(this.GetEntity());
        for (int i = 1; i < 32; i++)
        {
            if (ent.GetPropEnt(Prop_Data, "m_hSquadRoster", i) != -1)
            {
                if (ent.GetPropFloat(Prop_Data, "m_flSquadFormationError") >= 1.0 && !ent.GetProp(Prop_Data, "m_bSquadHasBrokenFormation") && !ent.MyNextBotPointer().GetLocomotionInterface().IsStuck())
                {
                    return true;
                }
            }
        }
        return false;
    }

    public bool IsInFormation()
    {
        CBaseEntity ent = CBaseEntity(this.GetEntity());
        for (int i = 1; i < 32; i++)
        {
            if (ent.GetPropEnt(Prop_Data, "m_hSquadRoster", i) != -1)
            {
                if (ent.GetProp(Prop_Data, "m_bSquadHasBrokenFormation") || ent.MyNextBotPointer().GetLocomotionInterface().IsStuck())
                    continue;

                if (ent.GetPropFloat(Prop_Data, "m_flSquadFormationError") > 0.75)
                    return false;
            }
        }
        return true;
    }

    public void SetSquadFormationError(float error)
    {
        CBaseEntity(this.GetBot().GetEntity()).SetPropFloat(Prop_Data, "m_flSquadFormationError", error);
    }

    public void SetBrokenFormation(bool flag)
    {
        CBaseEntity(this.GetBot().GetEntity()).SetProp(Prop_Data, "m_bSquadHasBrokenFormation")
    }
}
