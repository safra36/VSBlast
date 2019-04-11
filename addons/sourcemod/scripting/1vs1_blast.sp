#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define PLUGIN_AUTHOR "noBrain"
#define PLUGIN_VERSION "0.0.5 (Build 27)"

#define MAX_TEAMS 4
#define MAX_TEAMS_TR 2
#define MAX_TEAMS_CT 3

#define CT_WIN 8
#define TR_WIN 9


// Global Variables

char g_szWeaponKitPath[PLATFORM_MAX_PATH];
char g_szWeaponCfgPrePath[PLATFORM_MAX_PATH];
char g_szCurrentKit[64] = "";

ConVar g_cMaxWinRounds = null;
ConVar g_cRoundRestart = null;

bool g_bIsWarmupStarted = false;
bool g_bOnFirstRound = false;

int g_iRoundNumber[MAX_TEAMS] = 0;

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
    RegAdminCmd("sm_vblive", VSBlast_EndWarmup, ADMFLAG_BAN, "Ends warmup to begin the match");


    BuildPath(Path_SM, g_szWeaponKitPath, sizeof(g_szWeaponKitPath), "configs/wkits/kits.cfg");
    Format(g_szWeaponCfgPrePath, sizeof(g_szWeaponCfgPrePath), "VSBlast/");

    HookEvent("round_start", OnNewRound, EventHookMode_Pre);
    HookEvent("round_end", OnRoundEnd, EventHookMode_Pre);

    g_arKitList = new ArrayList(128);

    g_cMaxWinRounds = CreateConVar("vb_maxwin", "10", "Max number of rounds a team must win to finish the game");
    g_cRoundRestart = FindConVar("mp_restartgame");
    HookConVarChange(g_cRoundRestart, ConVar_RoundRestart);
}

public void ConVar_RoundRestart(ConVar convar, const char[] oldValue, const char[] newValue){
    OnRoundRestart();
}



public Action OnNewRound(Event event, const char[] name, bool dontBroadcast) 
{
    // Check for warmup
    if (GameRules_GetProp("m_bWarmupPeriod") == 1) {
            g_bIsWarmupStarted = true;
            OnWarmupStarted();
     }else{
            if(g_bIsWarmupStarted){
                OnWarmupEnded();
                g_bIsWarmupStarted = false;
            }
    }

    PrintHintTextToAll("<font color='#9900cc'>1 VS 1 Blast</font> Pro Series\n<font color='#33ccff'>CT: </font> %d | <font color='#ff3300'>T: </font> %d ", 
            g_iRoundNumber[MAX_TEAMS_CT], g_iRoundNumber[MAX_TEAMS_TR]);

    if(g_bOnFirstRound){
        RestartRoundCounter();
        g_bOnFirstRound = false;
    }

    return Plugin_Continue;
}


public Action OnRoundEnd(Event event, const char[] name, bool dontBroadcast) {

    int RoundEndReason = event.GetInt("reason");
    if(RoundEndReason == TR_WIN){
        //int winner = event.GetInt("winner");
        g_iRoundNumber[MAX_TEAMS_TR]++;
        PrintToChatAll(" \x02[VSBlast] \x01 Terrorists has won this round!");

        if(g_iRoundNumber[MAX_TEAMS_TR] >= GetConVarInt(g_cMaxWinRounds)){
            EndGame();
            Format(g_szCurrentKit, sizeof(g_szCurrentKit), "");

            PrintToChatAll(" \x02[VSBlast] \x01 Terrorists has won the match.");
            PrintToChatAll(" \x02[VSBlast] \x01 Restarting match in 5 seconds.");
        }

    }else if(RoundEndReason == CT_WIN){
        //int winner = event.GetInt("winner");
        g_iRoundNumber[MAX_TEAMS_CT]++;
        PrintToChatAll(" \x02[VSBlast] \x01 Counter-Terrorists has won this round!");

        if(g_iRoundNumber[MAX_TEAMS_CT] >= GetConVarInt(g_cMaxWinRounds)){
            EndGame();
            Format(g_szCurrentKit, sizeof(g_szCurrentKit), "")

            PrintToChatAll(" \x02[VSBlast] \x01 Counter-Terrorists has won the match.");
            PrintToChatAll(" \x02[VSBlast] \x01 Restarting match in 5 seconds.");
        }

    }else{
        RestartRoundCounter();
    }

}

public Action VSBlast(int client, int args){

    ShowMenu(client);
    return Plugin_Handled;
}

public Action VSBlast_EndWarmup(int client, int args){
    EndWarmup();
    return Plugin_Handled;
}


//////////////////////////////////////////////////////
//                     Forwards
//////////////////////////////////////////////////////

public void OnWarmupStarted(){

    //Your code in here
    PrintToChatAll(" \x02[VSBlast] \x01 Type !vb to see available kits.");


    RestartRoundCounter();

    ServerCommand("mp_warmuptime 900");
    ServerCommand("mp_warmup_pausetimer 1");
}

public void OnWarmupEnded(){

    //Your code in here
    char CurrentConfig[256], ExecuteConfig[256];
    
    GetWeaponConfig(g_szCurrentKit, CurrentConfig, sizeof(CurrentConfig));
    if(!StrEqual(CurrentConfig, "", false)){
        Format(ExecuteConfig, sizeof(ExecuteConfig), "%s%s", g_szWeaponCfgPrePath, CurrentConfig);
        ExecuteCfg(ExecuteConfig);

        RestartGame(10);
        PrintToChatAll(" \x02[VSBlast] \x01 Match will be live in 10 seconds.");
    }else{
        PrintToChatAll(" \x02[VSBlast] \x01 Unable to load weapon config.");
    }
    g_arKitList.Clear();
    RestartRoundCounter();
    g_bOnFirstRound = true;
}

public void OnRoundRestart(){

    //Your code in here
    PrintToChatAll(" \x02[VSBlast] \x01 Round has been restarted.");
    RestartRoundCounter();
    g_bOnFirstRound = true;
}



//////////////////////////////////////////////////////
//                     Functions
//////////////////////////////////////////////////////


stock void EndWarmup(){
    ServerCommand("mp_warmup_end");
}

stock void RestartGame(int sec){
    ServerCommand("mp_restartgame %d", sec);
    RestartRoundCounter();
}

stock void RestartRoundCounter(){
    g_iRoundNumber[MAX_TEAMS_TR] = 0;
    g_iRoundNumber[MAX_TEAMS_CT] = 0;
}

stock void EndGame(){

    ServerCommand("mp_maxrounds 0");
    CreateTimer(5.0, Timer_RestartGame);
}

public Action Timer_RestartGame(Handle timer){
    ServerCommand("mp_warmup_start");
}

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
    GetModeList();

    for(int i=0;i<g_arKitList.Length;i++){

        char VoteMenuItem[64];
        g_arKitList.GetString(i, VoteMenuItem, sizeof(VoteMenuItem));
        AddMenuItem(menu, VoteMenuItem, VoteMenuItem);
    }

    SetMenuExitButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);

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
















