#include <sourcemod>
#include <sdktools>

#define PLUGIN_AUTHOR "noBrain"
#define PLUGIN_VERSION "0.0.1 (Build 2)"


// Global Variables

char g_szWeaponKitPath[PLATFORM_MAX_PATH];
char g_szWeaponCfgPrePath[PLATFORM_MAX_PATH];
char g_szCurrentKit[64] = "";

bool g_bIsWarmupStarted = false;

ArrayList g_arKitList;



public Plugin myinfo = 
{
	name = "VSBlast",
	author = PLUGIN_AUTHOR,
	description = "This plugin should manage these kinds of tournamnets.",
	version = PLUGIN_VERSION,
};


public void OnPluginStart(){

    RegAdminCmd("sm_vb", VSBlast, ADMFLAG_BAN, "Open blast menu.");


    BuildPath(Path_SM, g_szWeaponKitPath, sizeof(g_szWeaponKitPath), "configs/wkits/kits.cfg");
    Format(g_szWeaponCfgPrePath, sizeof(g_szWeaponCfgPrePath), "VSBlast/");
    HookEvent("round_start", OnNewRound, EventHookMode_Pre);

    g_arKitList = new ArrayList(128);
}




public Action OnNewRound(Event event, const char[] name, bool dontBroadcast) 
{
    // Check for warmup
    if(!g_bIsWarmupStarted){
        if (GameRules_GetProp("m_bWarmupPeriod") == 1) {
            g_bIsWarmupStarted = true;
            OnWarmupStarted();
        }else{
            OnWarmupEnded();
            g_bIsWarmupStarted = false;
        }
    }
    return Plugin_Continue;
}

public Action VSBlast(int client, int args){

    ShowMenu(client);
    return Plugin_Handled;
}



//////////////////////////////////////////////////////
//                     Forwards
//////////////////////////////////////////////////////

public void OnWarmupStarted(){

    //Your code in here
    PrintToChatAll(" \x02[VSBlast] \x01 Type !vb to see available kits.");
}

public void OnWarmupEnded(){

    //Your code in here
    char CurrentConfig[256], ExecuteConfig[256];
    
    GetWeaponConfig(g_szCurrentKit, CurrentConfig, sizeof(CurrentConfig));
    if(!StrEqual(CurrentConfig, "", false)){
        Format(ExecuteConfig, sizeof(ExecuteConfig), "%s/%s", g_szWeaponCfgPrePath, CurrentConfig);
        ExecuteCfg(ExecuteConfig);

    }else{
        PrintToChatAll(" \x02[VSBlast] \x01 Unable to load weapon config.");
    }
    g_arKitList.Clear();
}



//////////////////////////////////////////////////////
//                     Functions
//////////////////////////////////////////////////////

stock void GetModeList(){

    Handle kv = CreateKeyValues("weapons");
    FileToKeyValues(kv, g_szWeaponKitPath);

    KvGotoFirstSubKey(kv, true);
    do{

        char KitName[64];
        KvGetSectionName(kv, KitName, sizeof(KitName));
        g_arKitList.PushString(KitName);

    }while(KvGotoNextKey(kv, true))
    CloseHandle(kv);
}

stock void ShowMenu(int client){

    Handle menu = CreateMenu(ModeVoteMenu);
    SetMenuTitle(menu, "Choose your desire mode: ");
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
    SetMenuExitButton(menu, true);

    for(int i=0;i<g_arKitList.Length;i++){

        char VoteMenuItem[64];
        g_arKitList.GetString(i, VoteMenuItem, sizeof(VoteMenuItem));
        AddMenuItem(menu, VoteMenuItem, VoteMenuItem);
    }

    g_arKitList.Clear();
}


public int ModeVoteMenu(Handle menu, MenuAction action, int param1, int param2) {
    
	switch (action) {

		case MenuAction_Select: {

			char item[64];
			GetMenuItem(menu, param2, item, sizeof(item));
            SetCurrentKit(item);
            
        }
        case MenuAction_End: {
            CloseHandle(menu);
		}
    }
}

stock void SetCurrentKit(char[] kit){

    Format(g_szCurrentKit, sizeof(g_szCurrentKit), "%s", kit);
}



stock void RemoveC4All(){

    // Loop through clients
    for(int i =1 ; i <= MaxClients ; i++){

        // Check if the user is a valid client.
        if(isValidClient(i)){
            // Loop through weapon slots and check for C4
            int weapon;
            for(int x=0;x < 4; x++){

                if((weapon = GetPlayerWeaponSlot(i, x)) != -1){

                    char WeaponClassname[32];
                    GetEdictClassname(weapon, WeaponClassname, sizeof(WeaponClassname));

                    // If C4 found then remove it.

                    if(StrEqual(WeaponClassname, "weapon_c4", false)){

                        RemovePlayerItem(i, weapon);
                        AcceptEntityInput(weapon, "Kill");
                    }

                }

            }

        }

    }

}



stock bool isValidClient(int client){

    if(0 > client > MaxClients && !IsFakeClient(client) && IsClientInGame(client)){
        return true;
    }else{
        return false;
    }

}

stock void GetWeaponConfig(char[] kit, char[] kitStore, int maxlen){

    Handle kv = CreateKeyValues("weapons");
    FileToKeyValues(kv, g_szWeaponKitPath);

    if(KvJumpToKey(kv, kit, false)){

        KvGetString(kv, "config", kitStore, maxlen, "");
        CloseHandle(kv);
    }else{
        CloseHandle(kv);
    }
}

stock void ExecuteCfg(char[] configPath){

    ServerCommand("exec %s", configPath);
    return;
}



stock void RemoveAllWeapons(int client) {

	if (client < 1 || client > MaxClients || !IsClientInGame(client)) {

		return;
	}
	int weapon;
	for (int i; i < 4; i++) {
	
		if ((weapon = GetPlayerWeaponSlot(client, i)) != -1) {
		
			if (IsValidEntity(weapon)) {
			
				RemovePlayerItem(client, weapon);
				AcceptEntityInput(weapon, "Kill");
			}
			
		}
	}
}
















