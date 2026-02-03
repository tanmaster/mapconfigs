#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.8-final-attempt"
#define CONFIG_DIR "sourcemod/map-cfg/"

public Plugin myinfo = {
    name = "Map configs (Fixed Logic)",
    author = "Berni / Gemini Fixed",
    description = "Fixed pre.cfg execution",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net/showthread.php?p=607079"
}

public void OnPluginStart() {
    CreateConVar("mc_version", PLUGIN_VERSION, "Map Configs version", FCVAR_DONTRECORD|FCVAR_NOTIFY);
}

// Map just started - Try to catch the pre-configs here
public void OnMapStart() {
    LogMessage("[MapConfigs] Map Start detected. Searching for pre.cfg...");
    ExecuteMapSpecificConfigs("pre.cfg");
}

// Standard configs (after server.cfg)
public void OnAutoConfigsBuffered() {
    LogMessage("[MapConfigs] AutoConfigs Buffered. Searching for .cfg...");
    ExecuteMapSpecificConfigs("cfg");
}

void ExecuteMapSpecificConfigs(const char[] cfgSuffix) {
    char currentMap[PLATFORM_MAX_PATH];
    GetCurrentMap(currentMap, sizeof(currentMap));

    int mapSepPos = FindCharInString(currentMap, '/', true);
    if (mapSepPos != -1) {
        strcopy(currentMap, sizeof(currentMap), currentMap[mapSepPos+1]);
    }

    ArrayList adt_configs = new ArrayList(PLATFORM_MAX_PATH);
    char cfgdir[PLATFORM_MAX_PATH];
    Format(cfgdir, sizeof(cfgdir), "cfg/%s", CONFIG_DIR);

    DirectoryListing dir = OpenDirectory(cfgdir);
    if (dir == null) {
        return;
    }

    char configFile[PLATFORM_MAX_PATH];
    FileType fileType;
    
    char dotSuffix[32];
    Format(dotSuffix, sizeof(dotSuffix), ".%s", cfgSuffix);

    while (dir.GetNext(configFile, sizeof(configFile), fileType)) {
        if (fileType == FileType_File) {
            int suffixPos = StrContains(configFile, dotSuffix, false);
            // Ensure it ends with the suffix
            if (suffixPos != -1 && (suffixPos + strlen(dotSuffix)) == strlen(configFile)) {
                
                char prefix[PLATFORM_MAX_PATH];
                strcopy(prefix, suffixPos + 1, configFile);
                
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
