//  farm-updater.lsl
/**
This script is used to upgrade SatyrFarm items.
It scans for upgradeable items nearby (default range 96m), asks for it's version and a list of items in its inventory, decides what and if to upgrade and initiates the update.

#Configuration Notecards:
 sfp            = SatyrFarm Password
 setup          = This version of the new farm item(s), range etc
 upgradeables   = List of objects that will be upgraded, one per line
 additions      = List of additional items to add ( item1:item2:item3: ...)   NOTE: this is for things like textures, notecards etc. No need to add in scripts to this list
**/

// Version 2.1     24 September 2022

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG:" + llToUpper(llGetScriptName()) + "\n " + text);
}

integer VERSION;
integer MIN_VERSION = 0;
string  VER_DATE;
string  PASSWORD;
string  TYPE = "-";
list    UPGRADEABLES = [];
list    ADDITIONS = [];
list    myItems;
integer range = 96;

integer scan;
list    clients;
integer counter;
integer counter_none;
integer counter_scan;


integer checkNcExists(string name)
{
    integer result = FALSE;
    if (llGetInventoryType(name) == INVENTORY_NOTECARD) result = TRUE;
    return result;
}

integer loadConfig()
{
    integer i;
    string name;
    list lines = [];
    list tok = [];
    string cmd;
    string  val;
    string tmpName;
    integer count;
    integer retVal = FALSE;

    //config notecards
    if (llGetInventoryType("sfp") == INVENTORY_NONE || llGetInventoryType("setup") == INVENTORY_NONE)
    {
        llOwnerSay("No setup or password notecard in inventory! Can't work like that.");
    }
    else
    {
        PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);

        if (llGetInventoryType("setup") != INVENTORY_NONE)
        {
            lines = llParseString2List(osGetNotecard("setup"), ["\n"], []);
            for (i=0; i < llGetListLength(lines); i++)
            {
                string line = llStringTrim(llList2String(lines, i), STRING_TRIM);
                if (llGetSubString(line, 0, 0) != "#")
                {
                    tok = llParseStringKeepNulls(line, ["="], []);
                    cmd = llList2String(tok, 0);
                    val = llList2String(tok, 1);
                    if      (cmd == "VER")      VERSION = (integer)val;
                    else if (cmd == "MIN-VER")  MIN_VERSION = (integer)val;
                    else if (cmd == "DATE")     VER_DATE = val;
                    else if (cmd == "RANGE")    range = (integer)val;
                }
            }
        }
        if (llGetInventoryType("upgradeables") != INVENTORY_NONE)
        {
            UPGRADEABLES = llParseString2List(osGetNotecard("upgradeables"), ["\n"], []);
        }

        if (llGetInventoryType("additions") != INVENTORY_NONE)
        {
            ADDITIONS = [];
            list addnc = llParseString2List(osGetNotecard("additions"), ["\n"], []);
            integer c = llGetListLength(addnc);
            while (c--)
            {
                ADDITIONS += llParseStringKeepNulls(llList2String(addnc, c), [":"], []);
            }
        }
        //own items
        myItems = [];
        integer len = llGetInventoryNumber(INVENTORY_ALL);
        while (len--)
        {
            myItems += [llGetInventoryName(INVENTORY_ALL, len)];
        }
        list    InventoryList;
        count = llGetInventoryNumber(INVENTORY_ALL);  // Count of all items in prim's contents
        while ((count--) || (TYPE == "-"))
        {
            tmpName = llGetInventoryName(INVENTORY_ALL, count);
            if ((tmpName != llGetScriptName()) && (llGetInventoryType(tmpName) == INVENTORY_SCRIPT))
            {
                if (llListFindList(ADDITIONS, tmpName) == -1) TYPE = llToUpper(tmpName);
            }
        }
        retVal = TRUE;
    }
    return retVal;
}


setText(string msg, vector colour)
{
    llSetLinkPrimitiveParamsFast(2, [PRIM_TEXT, msg, colour, 1.0]);
}

scanNext()
{
    string target = llList2String(UPGRADEABLES, scan);
    if (target == "")
    {
        string tmpStr = "Update finished.\nScanned for " + (string)counter_scan + " objects.\nUpdated " + (string)counter + " items.\n";
        if (counter_none !=0 ) tmpStr += "Update not neccessary on " + (string)counter_none + " objects.\n" ;
        llRegionSayTo(llGetOwner(), 0, tmpStr);
        llResetScript();
        return;
    }
    llOwnerSay("Scanning for " + target);
    setText("Talking to " + target + "...", <1.0,0.0,0.8>);
    ++scan;
    llSensor(target, "", SCRIPTED, range, PI);
}

string itemsToReplace(string sItems, key kObject)
{
    list lReplace = [];
    integer found_add = llListFindList(ADDITIONS, [llKey2Name(kObject)]) + 1;
    if (found_add)
    {
        lReplace += llParseString2List(llList2String(ADDITIONS, found_add), [","], []);
    }
    list lItems = llParseString2List(sItems, [","], []);
    integer i = llGetListLength(lItems);
    integer c;
    for (c = 0; c < i;  c++)
    {
        string item = llList2String(lItems, c);
        if (llListFindList(myItems, [item]) != -1 && llListFindList(lReplace, [item]) == -1)
        {
            lReplace += [item];
        }
    }
    return llDumpList2String(lReplace, ",");
}

string FormatDecimal(float number, integer precision)
{
    float roundingValue = llPow(10, -precision)*0.5;
    float rounded;
    if (number < 0) rounded = number - roundingValue;
    else            rounded = number + roundingValue;

    if (precision < 1) // Rounding integer value
    {
        integer intRounding = (integer)llPow(10, -precision);
        rounded = (integer)rounded/intRounding*intRounding;
        precision = -1; // Don't truncate integer value
    }

    string strNumber = (string)rounded;
    return llGetSubString(strNumber, 0, llSubStringIndex(strNumber, ".") + precision);
}


default
{
    state_entry()
    {
        llSetColor(<1.0, 1.0, 1.0>, 4);
        llSetColor(<0.0, 0.0, 0.0>, 0);
        llSetTextureAnim(FALSE, ALL_SIDES, 0, 0, 0.0, 0.0, 1.0);
        if (loadConfig() == FALSE)
        {
            llOwnerSay("ERROR with configuration!");
            setText("ERROR!\nPlease check configuration", <1,0,0>);
        }
        else
        {
            string verText;
            if (VERSION != -1) verText = FormatDecimal((float)VERSION/10, 2); else verText = "ALL";
            string minVerText;
            if (MIN_VERSION != 0) minVerText = " (Min:"+FormatDecimal((float)MIN_VERSION/10, 2)+")";
            setText("UPDATE SCRIPT TYPE: " +TYPE +"\n \nUpdate to version: " +verText +minVerText +"\n" +VER_DATE+"\n" +"\nRange:" +(string)range+"m" , <0.9,1.0,0.9>);
        }
    }

    touch_start(integer n)
    {
        if (llDetectedKey(0) != llGetOwner())
        {
            llSay(0, "Sorry, you are not my owner");
            return;
        }
        state update;
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            llResetScript();
        }
    }
}


state update
{
    state_entry()
    {
        setText("Update Running...", <0.0,1.0,0.2>);
        llSetColor(<0.0, 1.0, 0.75>, 4);
        llSetColor(<1.0, 1.0, 1.0>, 0);
        llSetTextureAnim(ANIM_ON | LOOP, 0, 8, 6, 0.0, 48.0, 10.0);
        counter = 0;
        counter_none = 0;
        counter_scan = 0;
        scan = 0;       
        scanNext();
    }

    sensor(integer n)
    {
        clients = [];
        key owner = llGetOwner();
        while (n--)
        {
            key det = llDetectedKey(n);
            if (owner == llGetOwnerKey(det))
            {
                clients += [det];
            }
        }
        llSetTimerEvent(1.0);
    }

    timer()
    {
        llSetTimerEvent(0.0);
        if (clients == [])
        {
            scanNext();
            return;
        }
        key target = llList2Key(clients, 0);
        clients = llDeleteSubList(clients, 0, 0);
        llOwnerSay(" \n-------------\nChecking " + llKey2Name(target) + "\n" + (string)target + " (from: " + (string)llGetKey() +")");
        llSetTimerEvent(3.0);
        ++counter_scan;
        // Request version info for script
        osMessageObject(target, "VERSION-CHECK|" + PASSWORD + "|" + (string)llGetKey());
        // Request version info for lang notecards
        //osMessageObject(target, "LANGUAGE-CHECK|" + PASSWORD + "|" + (string)llGetKey() +"|" + SUFFIX);
    }

    no_sensor()
    {
        llOwnerSay("No item found");
        scanNext();
    }

    dataserver(key k, string m)
    {
        debug("dataserver: " + m);
        list tk = llParseString2List(m, ["|"], []);
        string command = llList2String(tk, 0);

        if (llList2String(tk,1) == PASSWORD)
        {
            if (command == "VERSION-REPLY")
            {
                integer iVersion = llList2Integer(tk,3);
                if ((iVersion != VERSION) || (VERSION == -1))
                {
                    if (iVersion >= MIN_VERSION)
                    {
                        string repstr = itemsToReplace(llList2String(tk,4), llList2Key(tk, 2));
                        if (repstr != "")
                        {
                            llSay(0, "Update possible - trying to update item...");
                            osMessageObject(llList2Key(tk, 2), "DO-UPDATE|"+PASSWORD+"|"+(string)llGetKey()+"|"+repstr);
                            llSetTimerEvent(20.0);
                            return;
                        }
                    }
                }
                ++counter_none;
                llSetTimerEvent(0.5);
            }
            else if (command == "DO-UPDATE-REPLY")
            {
                llSleep(2.0);
                key kobject = llList2Key(tk, 2);
                integer ipin = llList2Integer(tk, 3);
                list litems = llParseString2List(llList2String(tk, 4), [","], []);
                integer type;
                string sitem;
                integer d = llGetListLength(litems);
                integer c;
                for (c = 0; c < d; c++)
                {
                    sitem = llList2String(litems, c);
                    type = llGetInventoryType(sitem);
                    if (type == INVENTORY_SCRIPT)
                    {
                        llRemoteLoadScriptPin(kobject, sitem, ipin, TRUE, 0);
                    }
                    else if (type != INVENTORY_NONE)
                    {
                        llGiveInventory(kobject, sitem);
                    }
                }

                d = llGetListLength(ADDITIONS);
                if (d >0)
                {
                    for (c = 0; c < d; c++)
                    {
                        sitem = llList2String(ADDITIONS, c);
                        type = llGetInventoryType(sitem);
                        if (type == INVENTORY_SCRIPT)
                        {
                            llRemoteLoadScriptPin(kobject, sitem, ipin, TRUE, 0);
                        }
                        else if (type != INVENTORY_NONE)
                        {
                            llGiveInventory(kobject, sitem);
                        }
                    }
                }
                ++counter;
                llSetTimerEvent(1.0);
            }
        }
        else
        {
            llOwnerSay("password match error!");
        }
    }
}
