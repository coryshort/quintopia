
// umbrella.lsl
//
float version = 1.0;    // 27 September 2022
//
integer DEBUGMODE = FALSE;
//
integer FARM_CHANNEL = -911201;
string  PASSWORD = "*";
vector fullSize = <1.87529, 1.64430, 1.87529>;

debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG_" + llToUpper(llGetScriptName()) + " " + text);
}


default
{

    on_rez(integer start_param)
    {
        llResetScript();
    }

    state_entry()
    {
        PASSWORD = osGetNotecardLine("sfp", 0);
        llListen(FARM_CHANNEL, "", "", "");
        llSetAlpha(0.0, ALL_SIDES);
        llSetScale(<0.01, 0.01, 0.01>);
    }

    listen(integer channel, string name, key id, string message)
    {
        if (channel == FARM_CHANNEL)
        {
            list tk = llParseString2List(message, ["|"], []);
            string cmd = llList2String(tk, 0);
            // password is (tk, 1)
            if (cmd == "WR_RAIN")
            {
                llSetScale(fullSize);
                llSetAlpha(1.0, ALL_SIDES);
            }
            else if ((cmd == "WR_FXEND") || (cmd == "WR_RESET"))
            {
                llSetAlpha(0.0, ALL_SIDES);
                llSetScale(<0.01, 0.01, 0.01>);
            }
            else if(cmd == "WR_RESET")
            {
                llResetScript();
            }
        }
    }

    changed(integer change)
    {
        if ((change & CHANGED_REGION) || (change & CHANGED_TELEPORT))
        {
            llResetScript();
        }
    }

}
