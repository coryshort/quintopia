//  Weather system repeater - listens on the farm channel for weather related messages
//   WR_SOUND,  WR_RAIN, WR_CLOUDS, WR_FXEND, WR_RESET, WR_DEBUG
//
// Version 1.0      7 October 2022

// Can be changed via config notecard, false for particle rain, true for using prims
integer primRain = FALSE;

//float timerInterval = 20;
//
float   volume = 0;
float   lastVol = 0;
string  rainSound = "RAIN";
integer raining = FALSE;
integer debugMode = 0;
integer FARM_CHANNEL = -911201;
string  PASSWORD = "*";
string  status;
key     owner;


loadConfig()
{
    integer i;
    //config Notecard
    if (llGetInventoryType("config") == INVENTORY_NOTECARD)
    {
        list lines = llParseString2List(osGetNotecard("config"), ["\n"], []);
        for (i=0; i < llGetListLength(lines); i++)
        {
            string line = llStringTrim(llList2String(lines, i), STRING_TRIM);
            if (llGetSubString(line, 0, 0) != "#")
            {
                list   tok = llParseStringKeepNulls(line, ["="], []);
                string cmd = llList2String(tok, 0);
                string val = llList2String(tok, 1);
                if (cmd == "PRIM_RAIN")
                {
                    primRain = (integer)val; 
                    llOwnerSay("PRIM_RAIN="+(string)primRain);
                } 
            }
        }
    }
}

makeRain()
{
    if (raining == FALSE)
    {
        raining == TRUE;
        if (debugMode == TRUE)
        {
            llSetText("makeRain  Vol="+(string)volume, <1,1,1>, 1.0);
            llOwnerSay("making rain...");
        }
        llStopSound();
        llLoopSound(rainSound, volume);
        llSetColor(<0,0,1>, ALL_SIDES);
        if (primRain == FALSE)
        {
            llParticleSystem( [
            PSYS_SRC_TEXTURE,
            NULL_KEY,
            PSYS_PART_START_SCALE, <0.1,0.5, 0>,
            PSYS_PART_END_SCALE, <0.05,1.5, 0>,
            PSYS_PART_START_COLOR, <1,1,1>,
            PSYS_PART_END_COLOR, <1,1,1>,
            PSYS_PART_START_ALPHA, 0.8,
            PSYS_PART_END_ALPHA, 0.6,
            PSYS_SRC_BURST_PART_COUNT, 15,
            PSYS_SRC_BURST_RATE, 0.00,
            PSYS_PART_MAX_AGE, 10.00,
            PSYS_SRC_MAX_AGE, 0.0,
            PSYS_SRC_PATTERN, 8,
            PSYS_SRC_ACCEL, <0.0,0.0, -7.2>,
            PSYS_SRC_BURST_RADIUS, 20.0,
            PSYS_SRC_BURST_SPEED_MIN, 0.0,
            PSYS_SRC_BURST_SPEED_MAX, 0.0,
            PSYS_SRC_ANGLE_BEGIN, 0*DEG_TO_RAD,
            PSYS_SRC_ANGLE_END, 180*DEG_TO_RAD,
            PSYS_SRC_OMEGA, <0,0,0>,
            PSYS_PART_FLAGS, ( 0
                | PSYS_PART_INTERP_COLOR_MASK
                | PSYS_PART_INTERP_SCALE_MASK
                | PSYS_PART_WIND_MASK
            ) ] );
        }
        else
        {
            // PRIM RAIN
            llMessageLinked(LINK_SET, 1, "RAIN", "");
        }
    }
}

fxOff()
{
    llSetColor(<0,1,0>, ALL_SIDES);
    if (debugMode == TRUE) llSetText("fxOff", <1,1,1>, 1.0);    
    llLinkParticleSystem(LINK_SET, []);
    llStopSound();
    raining = FALSE;
    llMessageLinked(LINK_SET, 0, "RESET", "");
}

init()
{
    fxOff();
    llSetText("", ZERO_VECTOR, 0.0);
    llSetColor(<1,1,1>, ALL_SIDES);
    PASSWORD = osGetNotecardLine("sfp", 0);
    loadConfig();
    owner = llGetOwner();
    if (primRain == TRUE) llSetText("Prim rain\n-- READY --", <1,1,1>, 1.0); else llSetText("Particle rain\n-- READY --", <1,1,1>, 1.0);
    raining = FALSE;
}


default
{
    on_rez(integer p)
    {
        llResetScript();
    }

    state_entry()
    {
        init();
        llListen(FARM_CHANNEL, "", "", "");
        llSetColor(<0,1,0>, ALL_SIDES);
        llSetAlpha(1.0, ALL_SIDES);     
    }

    touch_end(integer num)
    {
        llSetAlpha(0.1, ALL_SIDES);
    }

    listen(integer channel, string name, key id, string message)
    {
        if (channel == FARM_CHANNEL)
        {
            list tk = llParseString2List(message, ["|"], []);
            string cmd = llList2String(tk, 0);
            //  0     1        2     3 ...
            // CMD|PASSWORD|OwnerID|data...
            if ((llList2String(tk, 1) == PASSWORD) && (llList2Key(tk, 2) == owner ))
            {
                if (cmd == "WR_SOUND")
                {
                    string tmpStr =llList2String(tk, 3);
                    if (llGetInventoryType(tmpStr) == INVENTORY_SOUND)
                    {
                        llStopSound();
                        llLoopSound(tmpStr, 1.0);
                    }
                    if (debugMode == TRUE) llSetText("play_sound: "+tmpStr, <1,1,1>, 1.0);
                    llMessageLinked(LINK_SET, 1, "SOUND", "");
                }
                else if (cmd == "WR_RAIN")
                {
                    llStopSound();
                    volume = llList2Float(tk,3);
                    makeRain();
                }
                else if (cmd == "WR_CLOUDS")
                {
                    llMessageLinked(LINK_SET, llList2Integer(tk,3), "CLOUDS", "");
                }
                else if (cmd == "WR_FOG")
                {
                    llMessageLinked(LINK_SET, llList2Integer(tk,3), "FOG", "");
                }
                if (cmd == "WR_FXEND")
                {
                    // use timer to slowly fade out rain sound
                    status = "turnOff";
                    lastVol = volume;
                    llSetTimerEvent(0.5);
                }
                else if (cmd == "WR_RESET")
                {
                    init();
                }
                else if (cmd == "WR_DEBUG")
                {
                    integer val = llList2Integer(tk, 3);
                    if (val == 1)
                    {
                        debugMode = TRUE;
                        llSetAlpha(1.0, ALL_SIDES);
                    }
                    else
                    {
                        debugMode = FALSE;
                        llSetAlpha(0.0, ALL_SIDES);
                        llSetText("", ZERO_VECTOR, 0.0);
                    }
                    llMessageLinked(LINK_SET, val, "DEBUG", "");
                    llSetText("DEBUG:"+(string)val, <1,1,1>, 1.0);
                }
            }
        }
    }

    timer()
    {
        if (status == "turnOff")
        {
            lastVol = lastVol - 0.1;
            if (lastVol > 0)
            {
                llLoopSound(rainSound, lastVol);
            }
            else
            {
                status = "";
                llSetTimerEvent(0);
                fxOff();
            }
        }        
    }

    changed(integer change)
    {
        if (change & CHANGED_OWNER)
        {
            llResetScript();
        }
        else if (change & CHANGED_INVENTORY)
        {
            init();
        }
    }

}
