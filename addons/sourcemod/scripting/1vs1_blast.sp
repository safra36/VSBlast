#include <sourcemod>
#include <sdktools>

#define PLUGIN_AUTHOR "noBrain"
#define PLUGIN_VERSION "0.0.0 (Build 1)"


// Global Variables
char g_szWeaponKitPath[PLATFORM_MAX_PATH];
char g_szCurrentKit[64] = "KIT_M4A4";




public Plugin myinfo = 
{
	name = "VSBlast",
	author = PLUGIN_AUTHOR,
	description = "This plugin should manage these kinds of tournamnets.",
	version = PLUGIN_VERSION,
};


public void OnPluginStart(){

    BuildPath(Path_SM, g_szWeaponKitPath, sizeof(g_szWeaponKitPath), "configs/wkits/kits.cfg");
    HookEvent("round_start", OnNewRound, EventHookMode_Post);
}




public Action OnNewRound(Event event, const char[] name, bool dontBroadcast) 
{
	for(int i=1;i<=MaxClients;i++){
        if(isValidClient(i)){
            GiveWeaponKit(i, g_szCurrentKit);
        }
    }
    return Plugin_Continue;
}






















































//////////////////////////////////////////////////////
//                     Functions
//////////////////////////////////////////////////////


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


stock bool GiveWeaponKit(int client, char[] kit){

    Handle kv = CreateKeyValues("weapons");
    FileToKeyValues(kv, g_szWeaponKitPath);

    if(KvJumpToKey(kv, kit, false)){

        char WeaponClass[32];
        KvGetString(kv, "weapon", WeaponClass, sizeof(WeaponClass));


        RemoveAllWeapons(i);
        GivePlayerItem(client, WeaponClass);
        GivePlayerItem(client, "weapon_knife");


        CloseHandle(kv);
        return true;
    }else{
        CloseHandle(kv);
        return false;
    }

    return false;
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
















