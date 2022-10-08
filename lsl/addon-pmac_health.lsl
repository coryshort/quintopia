// addon-pmac_health.lsl
//  Plugin for PMAC devices to link them to Health mode
//  First add the notecard  sfp to the items inventory
//  then add this plugin.

float VERSION = 5.0;     // 29 March 2022

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG:" + llToUpper(llGetScriptName()) + " " + text);
}

// these can be overriden with config notecard
integer        hygiene_value = 50;
integer         energy_value = 50;
integer         health_value = 50;
integer        bladder_value = 50;
integer             duration = 180;
integer              autoEnd = 1;
string          languageCode = "en-GB"; // LANG=en-GB               Default language
integer             makeVerb = 0;       // MAKE_VERB=0              Use 1 for 'make' or 0 for 'do'
integer         sensorRadius = 5;       // SENSOR_DISTANCE=5        How far to search (radius) when searching for ingredients to add
//
// General variables
string  PASSWORD="*";
integer FARM_CHANNEL = -911201;
integer seated;
list    avatarIDs;
key     avatarID;
string  action = "";
//
// For 'recipe' functionality
list    ingredients;                // Comma separated list of items needed before you can 'sit'     Give as 'percent item'  e.g INGREDIENTS=10% Soap, 10% kWh
string  lookingFor;
integer lookingForPercent;
integer startOffset = 0;
integer ready = TRUE;               // Set to false it items are needed before you can sit and they haven't been supplied yet
integer listener = -1;
integer listenTs;
integer clickedButton;
integer ingLength;
string  status = "";

integer haveIngredients;
//
string  SUFFIX = "M1";              // we use the language cards for 'machines'
//
string TXT_CLOSE = "CLOSE";
string TXT_ABORT="ABORT";
string TXT_RESUME="RESUME";
string TXT_MAKE="Make...";
string TXT_DO="Do...";
string TXT_MENU="Menu";
string TXT_SELECT="Select";
string TXT_OK="OK";
string TXT_MISSING="Missing";
string TXT_FOUND="Found";
string TXT_EMPTYING="emptying";
string TXT_LOOKING_FOR="Looking for";
string TXT_OR="or";
string TXT_ADD="Add an ingredient";
string TXT_ADD_INGREDIENTS="Click to add ingredients";
string TXT_SELECTED="Selected";
string TXT_PREP="All set, preparing ...";
string TXT_SIT="Sit here to produce item";
string TXT_ERROR_NOT_FOUND = "Item not found";
string TXT_ERROR_GROUP="Error, we are not in the same group";
string TXT_NOT_FOUND_ITEM="not found nearby. You must bring it closer";
string TXT_NOT_FOUND_ENOUGH="with enough percent not found nearby. You must bring it closer";
string TXT_NOT_FOUND_ITEM100=" with 100% not found nearby";
string TXT_LANGUAGE="@";


loadConfig()
{
    //sfp notecard
    PASSWORD = osGetNotecardLine("sfp", 0);
    //config notecard
    if (llGetInventoryType("config") == INVENTORY_NOTECARD)
    {
        list lines = llParseString2List(osGetNotecard("config"), ["\n"], []);
        integer i;
        for (i=0; i < llGetListLength(lines); i++)
        {
            list tok = llParseString2List(llList2String(lines,i), ["="], []);
            if (llList2String(tok,1) != "")
            {
                string cmd=llStringTrim(llList2String(tok, 0), STRING_TRIM);
                string val=llStringTrim(llList2String(tok, 1), STRING_TRIM);
                     if (cmd == "HYGIENE") hygiene_value = (integer)val;
                else if (cmd == "HEALTH") health_value = (integer)val;
                else if (cmd == "ENERGY") energy_value = (integer)val;
                else if (cmd == "BLADDER") bladder_value = (integer)val;
                else if (cmd == "TIME") duration = (integer)val;
                else if (cmd == "AUTO_END") autoEnd = (integer)val;
                else if (cmd == "LANG") languageCode = val;
                else if (cmd == "INGREDIENTS")
                {
                    ingredients  = parseIngredients(val);
                    ready = FALSE;
                }
            }
        }
    }
    // Load config options stored in description
    list desc = llParseStringKeepNulls(llGetObjectDesc(), [";"], []);
    if (llList2String(desc, 0) == "M")
    {
        languageCode = llList2String(desc, 1);
    }
    else
    {
        saveToDesc();
    }
}

loadLanguage(string langCode)
{
    // optional language notecard
    string languageNC = langCode + "-lang" + SUFFIX;
    if (llGetInventoryType(languageNC) == INVENTORY_NOTECARD)
    {
        list lines = llParseStringKeepNulls(osGetNotecard(languageNC), ["\n"], []);
        integer i;
        for (i=0; i < llGetListLength(lines); i++)
        {
            string line = llList2String(lines, i);
            if (llGetSubString(line, 0, 0) != "#")
            {
                list tok = llParseString2List(line, ["="], []);
                if (llList2String(tok,1) != "")
                {
                    string cmd=llStringTrim(llList2String(tok, 0), STRING_TRIM);
                    string val=llStringTrim(llList2String(tok, 1), STRING_TRIM);
                    // Remove start and end " marks
                    val = llGetSubString(val, 1, -2);
                    // Now check for language translations
                         if (cmd == "TXT_CLOSE") TXT_CLOSE = val;
                    else if (cmd == "TXT_ABORT") TXT_ABORT = val;
                    else if (cmd == "TXT_RESUME") TXT_RESUME = val;
                    else if (cmd == "TXT_MAKE") TXT_MAKE = val;
                    else if (cmd == "TXT_DO") TXT_DO = val;
                    else if (cmd == "TXT_MENU") TXT_MENU = val;
                    else if (cmd == "TXT_SELECT") TXT_SELECT = val;
                    else if (cmd == "TXT_OK") TXT_OK = val;
                    else if (cmd == "TXT_MISSING") TXT_MISSING = val;
                    else if (cmd == "TXT_FOUND") TXT_FOUND = val;
                    else if (cmd == "TXT_EMPTYING") TXT_EMPTYING = val;
                    else if (cmd == "TXT_LOOKING_FOR") TXT_LOOKING_FOR = val;
                    else if (cmd == "TXT_OR") TXT_OR = val;
                    else if (cmd == "TXT_ADD") TXT_ADD = val;
                    else if (cmd == "TXT_ADD_INGREDIENTS") TXT_ADD_INGREDIENTS = val;
                    else if (cmd == "TXT_SELECTED") TXT_SELECTED = val;
                    else if (cmd == "TXT_PREP") TXT_PREP = val;
                    else if (cmd == "TXT_SIT") TXT_SIT = val;
                    else if (cmd == "TXT_ERROR_NOT_FOUND") TXT_ERROR_NOT_FOUND = val;
                    else if (cmd == "TXT_ERROR_GROUP") TXT_ERROR_GROUP = val;
                    else if (cmd == "TXT_NOT_FOUND_ITEM") TXT_NOT_FOUND_ITEM = val;
                    else if (cmd == "TXT_NOT_FOUND_ITEM100") TXT_NOT_FOUND_ITEM100 = val;
                    else if (cmd == "TXT_NOT_FOUND_ENOUGH") TXT_NOT_FOUND_ENOUGH = val;
                    else if (cmd == "TXT_LANGUAGE") TXT_LANGUAGE = val;
                }
            }
        }
    }
}

saveToDesc()
{
    if (ready == FALSE) llSetObjectDesc("M;" +languageCode);
}

list parseIngredients(string stringred)
{
    clickedButton = 0;
    haveIngredients = 0;
    list ing  = llParseString2List(stringred, [","], []);
    list ret = [];
    ingLength = llGetListLength(ing);
    integer i = ingLength;
    while (i--)
    {
        list possible = llParseString2List(llList2String(ing, i), [" or "], []);
        integer c = llGetListLength(possible);
        while (c--)
        {
            list itemper = llParseString2List(llList2String(possible, c), ["%"], []);
            integer perc;
            string item;
            if (llGetListLength(itemper) == 1)
            {
                perc = 100;
                item = llStringTrim(llList2String(possible, c), STRING_TRIM);
            }
            else
            {
                perc = llList2Integer(itemper, 0);
                item = llStringTrim(llList2String(itemper, 1), STRING_TRIM);
            }
            ret += [i, item, perc];
        }
    }
    debug("parseIngredients:"+llDumpList2String(ret, "|"));
    return ret;
}

integer ingredientsListFindString(list hay, string needle)
{
    integer found_pro = llGetListLength(hay) / 3;
    //just a fancy way of llListFindList that isn't case sensitive
    while (found_pro--)
    {
        if (llToUpper(llList2String(hay, found_pro * 3 + 1)) == needle)
        {
            return found_pro * 3;
        }
    }
    return -1;
}

messageObj(key objId, string msg)
{
    list check = llGetObjectDetails(objId, [OBJECT_NAME]);
    if (llList2String(check, 0) != "") osMessageObject(objId, msg);
}

integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}

startListen()
{
    if (listener<0)
    {
        listener = llListen(chan(llGetKey()), "", "", "");
    }
    listenTs = llGetUnixTime();
}

checkListen(integer force)
{
    if ((listener > 0 && llGetUnixTime() - listenTs > 300) || force)
    {
        llListenRemove(listener);
        listener = -1;
    }
}

multiPageMenu(key id, string message, list buttons)
{
    integer l = llGetListLength(buttons);
    integer ch = chan(llGetKey());
    if (l < 12)
    {
        llDialog(id, message, [TXT_CLOSE, TXT_LANGUAGE]+buttons, ch);
    }
    else
    {
        if (startOffset >= l) startOffset = 0;
        list its = llList2List(buttons, startOffset, startOffset + 9);
        startListen();
        llDialog(id, message, [TXT_CLOSE, TXT_LANGUAGE]+its+[">>"], ch);
    }
}

dlgIngredients(key u)
{
    avatarID = u;
    list opts = [];
    list opts = [TXT_ABORT];
    string t = TXT_ADD;
    integer i = llGetListLength(ingredients) / 3;
    while (i--)
    {
        integer num = llList2Integer(ingredients, i*3);
        if ((~haveIngredients & (0x01 << num)) && (~clickedButton & (0x01 << num)))
        {
            opts +=  llList2String(ingredients, i*3 + 1);
            debug(llList2String(ingredients, i*3 + 1));
        }
    }
    if (llGetListLength(opts) > 1) multiPageMenu(u, t, opts); else checkListen(TRUE);
}

particles()
{
    integer flags = 0;
    flags = flags | PSYS_PART_EMISSIVE_MASK;
    flags = flags | PSYS_PART_INTERP_COLOR_MASK;
    flags = flags | PSYS_PART_INTERP_SCALE_MASK;
    flags = flags | PSYS_PART_FOLLOW_VELOCITY_MASK;

    llParticleSystem([  PSYS_PART_MAX_AGE,2,
                        PSYS_PART_FLAGS,flags,
                        PSYS_PART_START_COLOR, <1.000, 0.800, 0.900>,
                        PSYS_PART_END_COLOR, <0.318, 0.000, 0.633>,
                        PSYS_PART_START_SCALE,<0.25, 0.25, 1>,
                        PSYS_PART_END_SCALE,<1.5, 1.5, 1>,
                        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,
                        PSYS_SRC_BURST_RATE,0.1,
                        PSYS_SRC_ACCEL, <0.0, 0.0, -0.5>,
                        PSYS_SRC_BURST_PART_COUNT,2,
                        PSYS_SRC_BURST_RADIUS,1.0,
                        PSYS_SRC_BURST_SPEED_MIN,0.0,
                        PSYS_SRC_BURST_SPEED_MAX,0.05,
                        PSYS_SRC_TARGET_KEY,llGetOwner(),
                        PSYS_SRC_INNERANGLE,0.65,
                        PSYS_SRC_OUTERANGLE,0.1,
                        PSYS_SRC_OMEGA, <0,0,0>,
                        PSYS_SRC_MAX_AGE, 2,
                        PSYS_SRC_TEXTURE, "",
                        PSYS_PART_START_ALPHA, 0.5,
                        PSYS_PART_END_ALPHA, 0.0
                    ]);
}

refresh()
{
    integer i;
    string str = "";
    if (status == "Adding")
    {
        //str += TXT_RECIPE + ":\t"+recipeName+"\n";
        integer missing=0;
        for (i=0; i < ingLength;i++)
        {
            integer length = llGetListLength(ingredients) / 3;
            list ingsep = [];
            while (length--)
            {
                if(llList2Integer(ingredients, length*3) == i)
                {
                    ingsep += [llList2String(ingredients, length*3 + 1)];
                }
            }
            str += llDumpList2String(ingsep, " "+TXT_OR+" ");
            if (haveIngredients & (0x01 << i))
            {
                str += ":\t" +TXT_OK + "\n";
            }
            else
            {
                str += ":\t" + TXT_MISSING +"\n";
                missing++;
            }
        }
        if (missing==0)
        {
            status = "Cooking";
            ready = TRUE;
            llRegionSayTo(avatarID, 0, TXT_PREP);
            str = TXT_SIT;
            checkListen(FALSE);
        }
        else
        {
            str += TXT_ADD_INGREDIENTS +"\n";
        }
    }
    else
    {
        if (listener<0) llSetTimerEvent(0.0); else llSetTimerEvent(300);
    }
    llSetText(str , <1,1,1>, 1.0);
}


default
{
    state_entry()
    {
        loadConfig();
        loadLanguage(languageCode);
        seated = FALSE;
        avatarIDs = [];
        llSetText("", ZERO_VECTOR, 0.0);
        llMessageLinked(LINK_SET,0, "PROGRESS", "");
        llMessageLinked(LINK_SET,90, "ENDCOOKING", "");
        llSetClickAction(CLICK_ACTION_TOUCH);
    }

    link_message(integer lnk, integer num, string msg, key id)
    {
        debug("link_message: " + msg +"  Status:" +status);
        list tk = llParseStringKeepNulls(msg, ["|"], []);
        string cmd = llList2String(tk, 0);
        list ids = llParseStringKeepNulls(id, ["|"], []);
        integer i;
        integer j = llGetListLength(ids);

        if (cmd == "GLOBAL_START_USING")
        {
            //GLOBAL_START_USING  id:e9623cc3-4a82-4685-b5a5-1bd500fe2af9|00000000-0000-0000-0000-000000000000
            avatarID = llList2Key(ids, 0);
            action = llList2String(tk, 1);
            if (ready == TRUE)
            {
                llSetText("", ZERO_VECTOR, 0.0);
                avatarIDs = [avatarID, llGetUnixTime()];
                seated = TRUE;
                llMessageLinked(LINK_SET,90, "STARTCOOKING", "");
                llSetTimerEvent(2);
                llSay(FARM_CHANNEL, "PROGRESS|" +PASSWORD+"|" +(string)avatarID+"|" +action +"|0");
                llSetTimerEvent(duration/20);
            }
            else
            {
                // WE NEED INGREDIENTS
                llUnSit(avatarID); 
                seated = FALSE;
                status = "Adding";
                startListen();
                dlgIngredients(avatarID);
            }
        }
        else if (cmd == "GLOBAL_NEXT_AN")
        {
            for (i=0; i<j; i+=1)
            {
                if (llListFindList(avatarIDs, [llList2Key(ids,i)] ) == -1)
                {
                    if (llList2Key(ids, i) != NULL_KEY) avatarIDs += [llList2Key(ids, i), llGetUnixTime()];
                }
            }
        }
        else if (cmd == "GLOBAL_USER_STOOD")
        {
            // Someone stood up
            //  GLOBAL_USER_STOOD|1|e9623cc3-4a82-4685-b5a5-1bd500fe2af9
            i = llListFindList(avatarIDs, llList2Key(tk,2));

            i = llListFindList(avatarIDs,[id]);
            if (i != -1)
            {
                avatarIDs = llDeleteSubList(avatarIDs, i, i+1);
            }
        }
        else if (cmd == "GLOBAL_SYSTEM_GOING_DORMANT")
        {
            seated = FALSE;
            llMessageLinked(LINK_SET,90, "ENDCOOKING", "");
            avatarIDs = [];
            llSetTimerEvent(0);
        }
        else if (cmd == "SET-LANG")
        {
            languageCode = llList2String(tk, 1);
            loadLanguage(languageCode);
            saveToDesc();
            refresh();
        }
    }

    listen(integer c, string nm, key id, string m)
    {
        debug("listen:" + m +"  Status:"+status);
        if (m == TXT_CLOSE)
        {
            //refresh();
        }
        else if (m == TXT_ABORT)
        {
            status = "";
            llMessageLinked(LINK_SET,99, "ENDCOOKING", "");
            llUnSit(avatarID);
            llSetClickAction(CLICK_ACTION_TOUCH);
            llSetText("", ZERO_VECTOR, 0.0);
            ingredients = [];
            llResetScript();
        }
        else if (m == TXT_LANGUAGE)
        {
            llMessageLinked(LINK_THIS, 1, "MENU_LANGS|" + languageCode +"|" +SUFFIX, id);
        }
        else if (m == TXT_LANGUAGE)
        {
            llMessageLinked(LINK_THIS, 1, "MENU_LANGS|" + languageCode +"|" +SUFFIX, id);
        }
        else if (status == "Adding")
        {
            if (m == ">>")
            {
                startOffset += 10;
                dlgIngredients(id);
                return;
            }
            lookingFor = "SF "+m;
            lookingForPercent = llList2Integer(ingredients, llListFindList(ingredients, [m]) + 1);

            llRegionSayTo(avatarID, 0, TXT_LOOKING_FOR +": " + lookingFor);
            llSensor(lookingFor , "",SCRIPTED,  sensorRadius, PI);
            refresh();
            return;
        }
        else
        {
            llMessageLinked(LINK_SET, 93, "MENU_OPTION|"+m, id);
        }
        checkListen(TRUE);
    }

    sensor(integer n)
    {
        string name = llGetSubString(lookingFor, 3, -1);
        //get first product that has enough percent left
        integer c;
        key ready_obj = NULL_KEY;
        for (c = 0; ready_obj == NULL_KEY && c < n; c++)
        {
            key obj = llDetectedKey(c);
            list stats = llParseString2List(llList2String(llGetObjectDetails(obj,[OBJECT_DESC]),0), [";"], []);
            integer have_percent = llList2Integer(stats, 1);
            // have_percent == 0 for backwards compatibility with old items
            if (have_percent >= lookingForPercent || have_percent == 0)
            {
                ready_obj = llDetectedKey(c);
            }
        }
        //
        if (ready_obj == NULL_KEY)
        {
            llRegionSayTo(avatarID, 0, lookingFor+" " +TXT_NOT_FOUND_ENOUGH);
            dlgIngredients(avatarID);
            return;
        }
        messageObj( ready_obj,  "DIE|"+(string)llGetKey()+"|"+(string)lookingForPercent);
        //set button as pressed and launch menu again
        integer d = llList2Integer(ingredients, llListFindList(ingredients, [name]) - 1);
        clickedButton = clickedButton | (0x01 << d);
        startOffset = 0;
        dlgIngredients(avatarID);
    }

    no_sensor()
    {
        llRegionSayTo(avatarID, 0, lookingFor+" " +TXT_NOT_FOUND_ITEM100);
        dlgIngredients(avatarID);
    }

    dataserver(key k, string m)
    {
        debug("DATASERVER: " + m);
        list tk = llParseStringKeepNulls(m, ["|"] , []);
        if (llList2String(tk,1) != PASSWORD) return;

        string cmd = llList2Key(tk,0);
        //Add Ingredient
        integer found_pro = ingredientsListFindString(ingredients, cmd);
        integer i = llList2Integer(ingredients, found_pro);
        haveIngredients= haveIngredients | (0x01 << i);
        refresh();
    }

    timer()
    {
        if (seated == TRUE)
        {
            integer i;
            integer j = llGetListLength(avatarIDs);
            float prog;

            for (i=0; i<j; i+=2)
            {
                avatarID = llList2Key(avatarIDs, i);

                prog = ((llGetUnixTime()-llList2Float(avatarIDs, i+1))*100.0)/duration;
                if (prog >=100.0)
                {
                    avatarID = llList2Key(avatarIDs, i);
                    llSay(FARM_CHANNEL, "HEALTH|" +PASSWORD+"|" +(string)avatarID +"|Hygiene|" +(string)hygiene_value +"|Energy|" +(string)energy_value +"|Health|" +(string)health_value +"|Bladder|" +(string)bladder_value);

                    if (autoEnd == TRUE)
                    {
                        llUnSit(avatarID);
                    }
                    else
                    {
                        // Remove and then add back in so their timer starts again
                        i = llListFindList(avatarIDs,[avatarID]);
                        if (i != -1)
                        {
                            avatarIDs = llDeleteSubList(avatarIDs, i, i+1);
                            avatarIDs += [avatarID, llGetUnixTime()];
                        }
                    }
                    llResetScript();
                }
                else
                {
                    llSay(FARM_CHANNEL, "PROGRESS|" +PASSWORD+"|" +(string)avatarID+"|" +action +"|" +(string)llRound(prog));
                }
            }
            particles();
            llSetTimerEvent(duration/20);
        }
        else
        {
            llSetTimerEvent(0.0);
            avatarIDs = [];
            llResetScript();
        }
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            llResetScript();
        }
    }

}
