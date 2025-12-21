stock float AngleNormalize(float angle)
{
	angle = fmodf(angle, 360.0);
	if (angle > 180)
		angle -= 360;

	if (angle < -180)
		angle += 360;

	return angle;
}

stock float Max(float one, float two)
{
	if(one > two)
		return one;
	else if(two > one)
		return two;

	return two;
}

stock float fmodf(const float number, const float denom)
{
	return number - RoundToFloor(number / denom) * denom;
}

stock float AngleDiff(const float destAngle, const float srcAngle)
{
	return AngleNormalize(destAngle - srcAngle);
}

stock float ApproachAngle(const float target, float value, float speed)
{
	float delta = AngleDiff(target, value);

	if (speed < 0.0)
		speed = -speed;

	if (delta > speed)
		value += speed;
	else if (delta < -speed)
		value -= speed;
	else
		value = target;

	return AngleNormalize(value);
}

#define RAD2DEG(%1) ((%1) * (180.0 / FLOAT_PI))

stock float RemapVal(float val, float A, float B, float C, float D)
{
    if (A == B)
        return val >= B ? D : C;
    return C + (D - C) * (val - A) / (B - A);
}

public float clamp(float a, float b, float c) { return (a > c ? c : (a < b ? b : a)); }

stock float VecToYaw(const float vec[3])
{
	if (vec[1] == 0 && vec[0] == 0)
		return 0.0;

	float yaw = ArcTangent2(vec[1], vec[0]);
	yaw = RadToDeg(yaw);

	if (yaw < 0)
		yaw += 360;

	return yaw;
}

stock float VecAxis(float vector[3], int axis)
{
	return vector[axis];
}

stock float AngleNormalize2(float angle)
{
	angle = fmodf(angle, 360.0);
	if (angle > 180.0) angle -= 360.0;
	if (angle < -180.0) angle += 360.0;
	return angle;
}

stock float AngleDiff2(float firstAngle, float secondAngle)
{
	float diff = fmodf(firstAngle - secondAngle, 360.0);
	if ( firstAngle > secondAngle )
	{
		if ( diff >= 180 )
			diff -= 360;
	}
	else
	{
		if ( diff <= -180 )
			diff += 360;
	}
	return diff;
}

stock float ApproachAngle2( float target, float value, float speed )
{
	float delta = AngleDiff2(target, value);

	// Speed is assumed to be positive
	if ( speed < 0 )
		speed = -speed;

	if ( delta < -180 )
		delta += 360;
	else if ( delta > 180 )
		delta -= 360;

	if ( delta > speed )
		value += speed;
	else if ( delta < -speed )
		value -= speed;
	else
		value = target;

	return value;
}

stock float FloatClamp(float f1, float f2, float f3)
{
	return (f1 > f3 ? f3 : (f1 < f2 ? f2 : f1));
}

stock float LengthSqr(float pos[3])
{
	return (pos[0]*pos[0] + pos[1]*pos[1] + pos[2]*pos[2]);
}

stock bool PointWithinViewAngle(const float srcPos[3], const float targetPos[3], const float lookDir[3], float cosHalfFOV)
{
    float vecDelta[3];
    SubtractVectors(targetPos, srcPos, vecDelta);
    float flCosDiff = GetVectorDotProduct(lookDir, vecDelta);

    if (flCosDiff < 0.0)
        return false;

    float flLen = LengthSqr(vecDelta);

    //PrintCenterTextAll("%.2f > %.2f | %b", flCosDiff * flCosDiff, flLen * cosHalfFOV * cosHalfFOV, (flCosDiff * flCosDiff > flLen * cosHalfFOV * cosHalfFOV));

    return (flCosDiff * flCosDiff > flLen * cosHalfFOV * cosHalfFOV);
}
