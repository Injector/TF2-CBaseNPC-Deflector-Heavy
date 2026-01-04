
methodmap CNextBotFactory
{
    public static CEntityFactory DefineVisionProps(CEntityFactory factory)
    {
        factory
            .DefineFloatField("m_flFOV")
            .DefineFloatField("m_flCosHalfFOV")
        ;
        return factory;
    }

    public static CEntityFactory DefineBodyProps(CEntityFactory factory)
    {
        factory
            .DefineVectorField("m_angCurrentAngles")
            .DefineVectorField("m_angPriorAngles")
            .DefineFloatField("m_flHeadSteadyTimer")
            .DefineBoolField("m_bHasBeenSightedIn")
            .DefineFloatField("m_flAnchorRepositionTimer")
            .DefineFloatField("m_flLookAtExpireTimer")
            .DefineVectorField("m_vecAnchorForward")
            .DefineFloatField("m_flLookAtTrackingTimer")
            .DefineVectorField("m_vecLookAtPos")
            .DefineVectorField("m_vecLookAtVelocity")
            .DefineFloatField("m_flLookAtDurationTimer")
            .DefineBoolField("m_bIsSightedIn")
            .DefineIntField("m_iLookAtPriority")
            .DefineEntityField("m_hLookAtSubject")
            .DefineBoolField("m_bOverrideFaceTowards")
        ;
        return factory;
    }

    public static CEntityFactory DefineIntentionProps(CEntityFactory factory)
    {
        factory
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
            .DefineFloatField("m_flDelayedNoticeWhen", 32)
            .DefineEntityField("m_hDelayedNoticeWho", 32)
            .DefineFloatField("m_flAimAdjustTimer")
            .DefineFloatField("m_flAimErrorAngle")
            .DefineFloatField("m_flAimErrorRadius")
        ;
        return factory;
    }
}
