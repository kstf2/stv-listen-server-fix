#include <sourcemod>
#include <dhooks>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = {
	name = "[STV] Fix UTIL functions for listen servers",
	author = "Kingstripes",
	description = "Detour UTIL_GetListenServerHost and UTIL_IsCommandIssuedByServerAdmin to fix multiple bugs when tv_enable is 1",
	version = PLUGIN_VERSION,
	url = "https://github.com/kstf2/stv-listen-server-fix"
};

ConVar g_ToggleCVar = null;
GameData g_GameData = null;

DynamicDetour g_GetListenServerHost_Detour = null;
DynamicDetour g_IsCommandIssuedByServerAdmin_Detour = null;

Handle g_GetCommandClientIndex_Call = null;

public void OnPluginStart()
{
	g_ToggleCVar = CreateConVar("sm_listenserver_util_fix", "1", "Control whether UTIL_GetListenServerHost and UTIL_IsCommandIssuedByServerAdmin are detoured or not\n0 - Disabled\n1 - Enabled", 0, true, 0.0, true, 1.0);
	g_ToggleCVar.AddChangeHook(OnConVarChanged);

	g_GameData = new GameData("listen.server.host.fix");
	if (!g_GameData)
		SetFailState("Failed to find gamedata/listen.server.host.fix.txt");

	g_GetListenServerHost_Detour = DynamicDetour.FromConf(g_GameData, "UTIL_GetListenServerHost");
	if (!g_GetListenServerHost_Detour)
		SetFailState("Failed to find signature for UTIL_GetListenServerHost");

	g_IsCommandIssuedByServerAdmin_Detour = DynamicDetour.FromConf(g_GameData, "UTIL_IsCommandIssuedByServerAdmin");
	if (!g_IsCommandIssuedByServerAdmin_Detour)
		SetFailState("Failed to find signature for UTIL_IsCommandIssuedByServerAdmin");

	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(g_GameData, SDKConf_Signature, "UTIL_GetCommandClientIndex"))
		SetFailState("Failed to prepare UTIL_GetCommandClientIndex call");

	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);

	g_GetCommandClientIndex_Call = EndPrepSDKCall();
	if (g_GetCommandClientIndex_Call == INVALID_HANDLE)
		SetFailState("Failed end preparation for UTIL_GetCommandClientIndex call");

	g_GetListenServerHost_Detour.Enable(Hook_Pre, UTIL_GetListenServerHost_Pre);
	g_IsCommandIssuedByServerAdmin_Detour.Enable(Hook_Pre, UTIL_IsCommandIssuedByServerAdmin_Pre);
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (g_ToggleCVar.BoolValue)
	{
		g_GetListenServerHost_Detour.Enable(Hook_Pre, UTIL_GetListenServerHost_Pre);
		g_IsCommandIssuedByServerAdmin_Detour.Enable(Hook_Pre, UTIL_IsCommandIssuedByServerAdmin_Pre);
	}
	else
	{
		g_GetListenServerHost_Detour.Disable(Hook_Pre, UTIL_GetListenServerHost_Pre);
		g_IsCommandIssuedByServerAdmin_Detour.Disable(Hook_Pre, UTIL_IsCommandIssuedByServerAdmin_Pre);
	}
}

// Not the most efficient way of doing this but eh
int GetFirstRealClient()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i)) continue;
	
		return i;
	}

	return -1;
}

MRESReturn UTIL_GetListenServerHost_Pre(DHookReturn hReturn)
{
	if (IsDedicatedServer())
	{
		// To keep original warning message
		return MRES_Ignored;
	}

	hReturn.Value = GetFirstRealClient();

	return MRES_Supercede;
}

MRESReturn UTIL_IsCommandIssuedByServerAdmin_Pre(DHookReturn hReturn)
{
	if (IsDedicatedServer())
	{
		return MRES_Ignored;
	}

	int CmdPlayerIdx = SDKCall(g_GetCommandClientIndex_Call);
	int AdminClient = GetFirstRealClient();

	if (CmdPlayerIdx == AdminClient)
	{
		hReturn.Value = true;
	}
	else
	{
		hReturn.Value = false;
	}

	return MRES_Supercede;
}
