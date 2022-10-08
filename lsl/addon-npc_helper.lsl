// addon-npc_helper.lsl
//  Version 1.1  20 September 2022

// config notecard can override these
string firstName = "Betsy";         // FIRST_NAME=Freda
string lastName  = "Horse";         // LAST_NAME=Horse

//
key    npc = NULL_KEY;
string animStand = "horse-stop";
vector rezPos = <1.0, -2.5, 1.3>;

clearUp()
{
    llSetTimerEvent(0.0);
    osNpcStand(npc);
    osNpcRemove(npc);
    npc = NULL_KEY;
    llMessageLinked(LINK_SET, 0, "REM_MENU_OPTION|" +"+" +firstName, NULL_KEY);
    llMessageLinked(LINK_SET, 0, "REM_MENU_OPTION|" +"-" +firstName, NULL_KEY);
}

rezNPC()
{
    if (npc == NULL_KEY)
    {
        vector npcPos = llGetPos() + rezPos;
        npc = osNpcCreate(firstName, lastName, npcPos, "appearance");
        osNpcPlayAnimation(npc, animStand);     
        osNpcSetRot(npc,<0.000000, 0.000000, -0.989016, 0.147809>);
    }
}

loadConfig()
{
    if (llGetInventoryType("config") == INVENTORY_NOTECARD)
    {
        list lines = llParseString2List(osGetNotecard("config"), ["\n"], []);
        integer i;
        for (i=0; i < llGetListLength(lines); i++)
        {
            string line = llStringTrim(llList2String(lines, i), STRING_TRIM);
            if (llGetSubString(line, 0, 0) != "#")
            {
                list tok = llParseStringKeepNulls(line, ["="], []);
                string cmd = llList2String(tok, 0);
                string val = llList2String(tok, 1);
                     if (cmd == "FIRST_NAME") firstName = val;
                else if (cmd == "LAST_NAME")  lastName = val;
            }
        }
    }
}


default
{
    state_entry()
    {
        loadConfig();
        // Tell machine to add a button so user can rez/unrez NPC
        llMessageLinked(LINK_SET, 0, "ADD_MENU_OPTION|" +"+" +firstName, NULL_KEY);
    }

    link_message(integer l, integer n, string m, key id)
    {
        list tok = llParseString2List(m, ["|"], []);
        string cmd = llList2String(tok, 0);
        if (cmd == "STARTCOOKING")
        {
            rezNPC();
            state hasNPC;
        }
        else if (cmd == "ENDCOOKING")
        {
              if (npc != NULL_KEY) clearUp();
        }
        else if (cmd == "MENU_OPTION")
        {
            if (npc == NULL_KEY)
            {
                llMessageLinked(LINK_SET, 0, "REM_MENU_OPTION|" +"+" +firstName, NULL_KEY);
                llMessageLinked(LINK_SET, 0, "ADD_MENU_OPTION|" +"-" +firstName, NULL_KEY);
                rezNPC();
            }
            else
            {
                llMessageLinked(LINK_SET, 0, "REM_MENU_OPTION|" +"-" +firstName, NULL_KEY);
                llMessageLinked(LINK_SET, 0, "ADD_MENU_OPTION|" +"+" +firstName, NULL_KEY);
                clearUp();
            }
        }
        else if (cmd == "RESET")
        {
            llResetScript();
        }
    }

    
    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            clearUp();
            llResetScript();
        }
    }
}

//

state hasNPC
{
    state_entry()
    {
        llSetTimerEvent(5.0);
    }

    timer()
    {
        llSetTimerEvent(0.0);
        osNpcSit(npc, llGetKey(), OS_NPC_SIT_NOW);
        osNpcSay(npc, "Neigh!");
    }

    link_message(integer l, integer n, string m, key id)
    {
        list tok = llParseString2List(m, ["|"], []);
        string cmd = llList2String(tok, 0);

        if (cmd == "ENDCOOKING")
        {
            clearUp();
            state default;
        }
        else if (cmd == "RESET")
        {
            if (npc != NULL_KEY)
            {
                clearUp();
                state default;
            }
        }
    }
}
