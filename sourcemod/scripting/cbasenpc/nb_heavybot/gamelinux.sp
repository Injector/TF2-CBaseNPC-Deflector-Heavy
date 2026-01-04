
#define GAME_LINUX_LOADED 1

bool g_bIsLinuxPlayer[MAXPLAYERS + 1];

stock void QCvar_PlayerLinux(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any value)
{
    g_bIsLinuxPlayer[client] = result == ConVarQuery_Okay;
}

methodmap CGameLinux
{
    public static void ClearPlayer(int client)
    {
        g_bIsLinuxPlayer[client] = false;
    }

    public static void CheckPlayerPlatform(int client)
    {
        //QueryClientConVar(int client, const char[] cvarName, ConVarQueryFinished callback, any value)
        QueryClientConVar(client, "sdl_double_click_size", QCvar_PlayerLinux, _);
    }

    public static bool IsLinuxPlayer(int client)
    {
        return g_bIsLinuxPlayer[client];
    }
}
