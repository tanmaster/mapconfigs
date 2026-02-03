#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.7-robust"
#define CONFIG_DIR "sourcemod/map-cfg/"

public Plugin myinfo = {
    name = "Map configs (Robust Fixed)",
    author = "Berni / Gemini Fixed",
    description = "Map specific configs with fixed multi-dot suffix support",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net/showthread.php?p=607079"
}

public void OnPluginStart() {
    CreateConVar("mc_version", PLUGIN_VERSION, "Map Configs version", FCVAR_DONTRECORD|FCVAR_NOTIFY);
}

// Fired when the map is literally just starting to load
public Action OnLevelInit(const char[] name, char[] entities) {
    ExecuteMapSpecificConfigs("pre.cfg");
    return Plugin_Continue;
}

// Fired after the map is loaded and standard configs (server.cfg) have run
public void OnAutoConfigsBuffered() {
    ExecuteMapSpecificConfigs("cfg");
}

void ExecuteMapSpecificConfigs(const char[] cfgSuffix) {
    char currentMap[PLATFORM_MAX_PATH];
    GetCurrentMap(currentMap, sizeof(currentMap));

    // Handle workshop/folder maps (strip path)
    int mapSepPos = FindCharInString(currentMap, '/', true);
    if (mapSepPos != -1) {
        strcopy(currentMap, sizeof(currentMap), currentMap[mapSepPos+1]);
    }

    ArrayList adt_configs = new ArrayList(PLATFORM_MAX_PATH);
    char cfgdir[PLATFORM_MAX_PATH];
    Format(cfgdir, sizeof(cfgdir), "cfg/%s", CONFIG_DIR);

    DirectoryListing dir = OpenDirectory(cfgdir);
    if (dir == null) {
        LogMessage("Error: Folder %s doesn't exist!", cfgdir);
        return;
    }

    char configFile[PLATFORM_MAX_PATH];
    FileType fileType;
    
    // We look for exactly ".pre.cfg" or ".cfg"
    char dotSuffix[32];
    Format(dotSuffix, sizeof(dotSuffix), ".%s", cfgSuffix);

    while (dir.GetNext(configFile, sizeof(configFile), fileType)) {
        if (fileType == FileType_File) {
            // 1. Check if the file ends with the correct suffix
            int suffixPos = StrContains(configFile, dotSuffix, false);
            if (suffixPos != -1 && (suffixPos + strlen(dotSuffix)) == strlen(configFile)) {
                
                // 2. Extract the prefix (the part before the .pre.cfg or .cfg)
                char prefix[PLATFORM_MAX_PATH];
                strcopy(prefix, suffixPos + 1, configFile);
                
                // 3. Check if the current map starts with this prefix
                if (StrContains(currentMap, prefix, false) == 0) {
                    adt_configs.PushString(configFile);
                }
            }
        }
    }

    adt_configs.Sort(Sort_Ascending, Sort_String);

    for (int i = 0; i < adt_configs.Length; i++) {
        adt_configs.GetString(i, configFile, sizeof(configFile));
        LogMessage("[MapConfigs] Executing: %s%s", CONFIG_DIR, configFile);
        ServerCommand("exec \"%s%s\"", CONFIG_DIR, configFile);
    }

    delete dir;
    delete adt_configs;
}
