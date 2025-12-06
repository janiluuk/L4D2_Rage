#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

// Check if httpclient extension is available at compile time
#tryinclude <httpclient>

#if defined _httpclient_included
    #define HTTPCLIENT_AVAILABLE 1
#else
    #define HTTPCLIENT_AVAILABLE 0
#endif

#include <rage_survivor_ai>

// Overlay integration
native bool IsOverlayConnected();
native void RegisterActionHandler(const char[] ns, const char[] action, Function handler);
native void RegisterActionAnyHandler(const char[] ns, Function handler);
native int FindClientBySteamId2(const char[] steamid);

#define MAX_QUERY_LENGTH 256
#define MAX_RESPONSE_LENGTH 4096
#define MAX_REQUEST_BODY 2048

public Plugin myinfo = {
    name = "[RAGE] AI Chat",
    author = "original authors, integrated by Rage",
    description = "AI chat for L4D2 (requires httpclient extension)",
    version = "1.0.0",
    url = "https://github.com/janiluuk/L4D2_Rage"
};

ConVar g_hApiUrl;
ConVar g_hApiKey;
ConVar g_hModel;
ConVar g_hTimeout;
ConVar g_hMaxDistance;

char g_sApiUrl[256];
char g_sApiKey[256];
char g_sModel[64];
float g_fTimeout = 8.0;
float g_fMaxDistance = 750.0;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
#if !HTTPCLIENT_AVAILABLE
    strcopy(error, err_max, "This plugin requires the httpclient extension. Install it from https://github.com/alliedmodders/sourcemod/tree/master/extensions/httpclient");
    return APLRes_Failure;
#else
    // Check if HTTPRequest native is available at runtime
    if (GetFeatureStatus(FeatureType_Native, "HTTPRequest.HTTPRequest") != FeatureStatus_Available)
    {
        strcopy(error, err_max, "HTTPRequest native not found. Please ensure httpclient extension is loaded.");
        return APLRes_Failure;
    }
    return APLRes_Success;
#endif
}

public void OnPluginStart()
{
#if !HTTPCLIENT_AVAILABLE
    // Should not reach here if AskPluginLoad2 failed, but just in case
    SetFailState("This plugin requires the httpclient extension.");
    return;
#endif

    g_hApiUrl = CreateConVar("rage_survivor_ai_url", "http://127.0.0.1:11434/v1/chat/completions", "OpenAI-compatible chat completion endpoint.");
    g_hApiKey = CreateConVar("rage_survivor_ai_api_key", "", "Bearer token for the OpenAI-compatible server (blank to disable header).", FCVAR_PROTECTED);
    g_hModel = CreateConVar("rage_survivor_ai_model", "gpt-4o-mini", "Model name to request from the OpenAI-compatible server.");
    g_hTimeout = CreateConVar("rage_survivor_ai_timeout", "8.0", "HTTP timeout in seconds for AI calls.");
    g_hMaxDistance = CreateConVar("rage_survivor_ai_max_distance", "750.0", "Maximum range (in Hammer units) to pick a nearby survivor as the speaker.");

    RegConsoleCmd("sm_ai", Cmd_AI);

    RegPluginLibrary("rage_survivor_ai");

    HookConVarChange(g_hApiUrl, OnSettingsChanged);
    HookConVarChange(g_hApiKey, OnSettingsChanged);
    HookConVarChange(g_hModel, OnSettingsChanged);
    HookConVarChange(g_hTimeout, OnSettingsChanged);
    HookConVarChange(g_hMaxDistance, OnSettingsChanged);

    RefreshSettings();
}

public void OnConfigsExecuted()
{
    RefreshSettings();
}

public void OnSettingsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    RefreshSettings();
}

public Action Cmd_AI(int client, int args)
{
    if (client <= 0 || !IsClientInGame(client))
    {
        return Plugin_Handled;
    }

    if (args < 1)
    {
        PrintToChat(client, "\x04[AI]\x01 Usage: !ai <message>");
        return Plugin_Handled;
    }

    if (g_sApiUrl[0] == '\0')
    {
        PrintToChat(client, "\x04[AI]\x01 No AI endpoint configured. Set rage_survivor_ai_url.");
        return Plugin_Handled;
    }

    char query[MAX_QUERY_LENGTH];
    GetCmdArgString(query, sizeof(query));
    TrimString(query);

    if (query[0] == '\0')
    {
        PrintToChat(client, "\x04[AI]\x01 Please provide a question after !ai.");
        return Plugin_Handled;
    }

    int speaker = FindNearbySurvivor(client, g_fMaxDistance);
    if (speaker == 0)
    {
        speaker = client;
    }

    SendAIRequest(client, speaker, query);
    PrintToChat(client, "\x04[AI]\x01 Sending your request to the AI...");

    return Plugin_Handled;
}

void SendAIRequest(int requester, int speaker, const char[] query)
{
#if !HTTPCLIENT_AVAILABLE
    PrintToChat(requester, "\x04[AI]\x01 httpclient extension is not available.");
    return;
#else
    HTTPRequest request = new HTTPRequest(g_sApiUrl);
    if (request == null)
    {
        PrintToChat(requester, "\x04[AI]\x01 Failed to build HTTP request.");
        return;
    }

    request.Timeout = g_fTimeout;
    request.SetHeader("Content-Type", "application/json");

    if (g_sApiKey[0] != '\0')
    {
        char auth[320];
        Format(auth, sizeof(auth), "Bearer %s", g_sApiKey);
        request.SetHeader("Authorization", auth);
    }

    char escapedQuery[MAX_QUERY_LENGTH * 2];
    EscapeJsonString(query, escapedQuery, sizeof(escapedQuery));

    char speakerName[MAX_NAME_LENGTH];
    GetClientName(speaker, speakerName, sizeof(speakerName));

    char requesterName[MAX_NAME_LENGTH];
    GetClientName(requester, requesterName, sizeof(requesterName));

    char body[MAX_REQUEST_BODY];
    Format(body, sizeof(body),
        "{\"model\":\"%s\",\"messages\":[{\"role\":\"system\",\"content\":\"You are roleplaying as survivor %s replying in one or two sentences.\"},{\"role\":\"user\",\"content\":\"%s asks: %s\"}],\"temperature\":0.7}",
        g_sModel, speakerName, requesterName, escapedQuery);

    DataPack pack = new DataPack();
    pack.WriteCell(GetClientUserId(requester));
    pack.WriteCell(GetClientUserId(speaker));

    request.Post(body, OnAIResponse, pack);
#endif
}

public void OnAIResponse(HTTPResponse response, any data)
{
#if !HTTPCLIENT_AVAILABLE
    return;
#else
    DataPack pack = view_as<DataPack>(data);
    pack.Reset();
    int requesterUserId = pack.ReadCell();
    int speakerUserId = pack.ReadCell();
    delete pack;

    int requester = GetClientOfUserId(requesterUserId);
    int speaker = GetClientOfUserId(speakerUserId);

    if (requester <= 0 || !IsClientInGame(requester))
    {
        return;
    }

    if (response.Status == HTTPStatus_Invalid)
    {
        PrintToChat(requester, "\x04[AI]\x01 Failed to reach AI server.");
        return;
    }

    if (response.Status != HTTPStatus_OK)
    {
        PrintToChat(requester, "\x04[AI]\x01 AI server returned status %d.", view_as<int>(response.Status));
        return;
    }

    char body[MAX_RESPONSE_LENGTH];
    response.Body.ReadString(body, sizeof(body));

    char content[MAX_RESPONSE_LENGTH];
    if (!ExtractContentFromResponse(body, content, sizeof(content)))
    {
        PrintToChat(requester, "\x04[AI]\x01 Could not parse AI response.");
        return;
    }

    // Send response through overlay if available, otherwise use chat
    bool sentViaOverlay = false;
    if (LibraryExists("rage_overlay") && GetFeatureStatus(FeatureType_Native, "IsOverlayConnected") == FeatureStatus_Available)
    {
        if (IsOverlayConnected())
        {
            sentViaOverlay = SendAIResponseViaOverlay(requester, speaker, content);
        }
    }
    
    if (!sentViaOverlay)
    {
        // Fallback to chat
    // Send response through overlay if available, otherwise use chat
    bool sentViaOverlay = false;
    if (LibraryExists("rage_overlay") && GetFeatureStatus(FeatureType_Native, "IsOverlayConnected") == FeatureStatus_Available)
    {
        if (IsOverlayConnected())
        {
            sentViaOverlay = SendAIResponseViaOverlay(requester, speaker, content);
        }
    }
    
    if (!sentViaOverlay)
    {
        // Fallback to chat
        if (speaker > 0 && IsClientInGame(speaker) && IsPlayerAlive(speaker))
        {
            PrintToChatAll("\x04[AI]\x01 %N replies: %s", speaker, content);
        }
        else
        {
            PrintToChat(requester, "\x04[AI]\x01 %s", content);
        }
    }
    }
#endif
}

void RefreshSettings()
{
    g_hApiUrl.GetString(g_sApiUrl, sizeof(g_sApiUrl));
    g_hApiKey.GetString(g_sApiKey, sizeof(g_sApiKey));
    g_hModel.GetString(g_sModel, sizeof(g_sModel));
    g_fTimeout = g_hTimeout.FloatValue;
    g_fMaxDistance = g_hMaxDistance.FloatValue;
}

int FindNearbySurvivor(int client, float maxDistance)
{
    if (client <= 0 || !IsClientInGame(client))
    {
        return 0;
    }

    float origin[3];
    GetClientAbsOrigin(client, origin);

    float maxDistanceSq = maxDistance * maxDistance;
    float bestDistSq = maxDistanceSq;
    int bestClient = 0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (i == client)
        {
            continue;
        }

        if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != 2)
        {
            continue;
        }

        float other[3];
        GetClientAbsOrigin(i, other);
        float distanceSq = GetVectorDistance(origin, other, true);

        if (distanceSq <= bestDistSq)
        {
            bestDistSq = distanceSq;
            bestClient = i;
        }
    }

    return bestClient;
}

void EscapeJsonString(const char[] input, char[] output, int maxLen)
{
    int outPos = 0;
    for (int i = 0; input[i] != '\0' && outPos < maxLen - 1; i++)
    {
        char c = input[i];
        if (c == '\\' || c == '"')
        {
            if (outPos + 2 >= maxLen)
            {
                break;
            }
            output[outPos++] = '\\';
            output[outPos++] = c;
        }
        else if (c == '\n')
        {
            if (outPos + 2 >= maxLen)
            {
                break;
            }
            output[outPos++] = '\\';
            output[outPos++] = 'n';
        }
        else
        {
            output[outPos++] = c;
        }
    }

    output[outPos] = '\0';
}

bool ExtractContentFromResponse(const char[] body, char[] content, int maxLen)
{
    int start = StrContains(body, "\"content\":\"");
    if (start == -1)
    {
        return false;
    }

    start += 11; // length of "content":"
    int end = start;
    int bodyLen = strlen(body);
    bool escape = false;

    for (int i = start; i < bodyLen && end < bodyLen; i++)
    {
        char c = body[i];
        if (escape)
        {
            escape = false;
            end++;
            continue;
        }

        if (c == '\\')
        {
            escape = true;
            end++;
            continue;
        }

        if (c == '"')
        {
            break;
        }

        end++;
    }

    int length = end - start;
    if (length <= 0)
    {
        return false;
    }

    int copyLen = (length < maxLen - 1) ? length : maxLen - 1;
    for (int i = 0; i < copyLen; i++)
    {
        content[i] = body[start + i];
    }
    content[copyLen] = '\0';

    DecodeJsonString(content, content, maxLen);
    TrimString(content);
    return (content[0] != '\0');
}

void DecodeJsonString(const char[] input, char[] output, int maxLen)
{
    int outPos = 0;
    bool escape = false;

    for (int i = 0; input[i] != '\0' && outPos < maxLen - 1; i++)
    {
        char c = input[i];
        if (!escape)
        {
            if (c == '\\')
            {
                escape = true;
                continue;
            }

            output[outPos++] = c;
            continue;
        }

        switch (c)
        {
            case '"':
            {
                output[outPos++] = '"';
                break;
            }
            case '\\':
            {
                output[outPos++] = '\\';
                break;
            }
            case '/':
            {
                output[outPos++] = '/';
                break;
            }
            case 'n':
            {
                output[outPos++] = '\n';
                break;
            }
            case 'r':
            {
                output[outPos++] = '\r';
                break;
            }
            case 't':
            {
                output[outPos++] = '\t';
                break;
            }
            default:
            {
                output[outPos++] = c;
                break;
            }
        }

        escape = false;
    }

    output[outPos] = '\0';
}

// Overlay integration handlers
public void OnOverlayAIChat(int client, Handle data)
{
    if (client <= 0 || !IsClientInGame(client))
    {
        return;
    }
    
    // Extract input from overlay message
    // TODO: Parse JSON data when JSON library is available
    // For now, we'll use a simple string extraction
    char input[MAX_QUERY_LENGTH];
    // data.GetString("input", input, sizeof(input));
    
    // If we can't get input from overlay, skip
    if (input[0] == '\0')
    {
        return;
    }
    
    int speaker = FindNearbySurvivor(client, g_fMaxDistance);
    if (speaker == 0)
    {
        speaker = client;
    }
    
    SendAIRequest(client, speaker, input);
}

public void OnOverlayAIAny(int client, Handle data)
{
    // Handle any AI-related actions from overlay
    // This is a fallback handler for unhandled actions
    OnOverlayAIChat(client, data);
}

bool SendAIResponseViaOverlay(int requester, int speaker, const char[] content)
{
    // TODO: Send AI response through overlay WebSocket when JSON library is available
    // This would send a message like:
    // {
    //   "type": "ai_response",
    //   "requester_steamid": "...",
    //   "speaker_steamid": "...",
    //   "content": "..."
    // }
    
    // For now, return false to use chat fallback
    return false;
}
