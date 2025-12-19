public bool Filter_WorldOnly(int entity, int contentsMask, any iExclude)
{
	char class[64];
	GetEntityClassname(entity, class, sizeof(class));

	if(StrEqual(class, "func_respawnroomvisualizer"))
	{
		return false;
	}
	else if(StrContains(class, "tf_projectile_", false) != -1)
	{
		return false;
	}
	else if(StrContains(class, "rosguard", false) != -1)
	{
		return false;
	}
	else if(StrContains(class, NEXTBOT_CUSTOM_CLASS_NAME, false) != -1)
	{
		return false;
	}

	return !(entity == iExclude);
}

public bool Filter_WorldOnlyEx(int entity, int contentsMask, any iExclude)
{
	char class[64];
	GetEntityClassname(entity, class, sizeof(class));

	if(StrEqual(class, "func_respawnroomvisualizer"))
	{
		return false;
	}
	else if(StrContains(class, "tf_projectile_", false) != -1)
	{
		return false;
	}
	else if(StrContains(class, "rosguard", false) != -1)
	{
		return false;
	}
	else if(StrContains(class, "obj_", false) != -1)
	{
		return false;
	}
	else if(StrContains(class, NEXTBOT_CUSTOM_CLASS_NAME, false) != -1)
	{
		return false;
	}

	return !(entity == iExclude);
}

public bool Filter_IgnoreEverything(int entity, int contentsMask, any iExclude)
{
	return false;
}
