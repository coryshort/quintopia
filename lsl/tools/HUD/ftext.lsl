// ----------------------------------------
//  QUINTONIA FARM HUD - Float text anchor
// ----------------------------------------
//
// INFO
// Generates float text so as to be positioned nicely over background screen prim
//

float version = 5.0;   //  10 September 2022

default
{

    state_entry()
    {
        //
    }

    link_message(integer sender_num, integer num, string msg, key id)
    {
        list tk = llParseStringKeepNulls(msg , ["|"], []);
        string cmd = llList2String(tk, 0);

        if (cmd == "SHOWTEXT")
        {
            // SHOWTEXT|message|<color>
            llSetText(llList2String(tk, 1), llList2Vector(tk, 2), 1.0);
        }
        else if (cmd == "SCREENOFF")
        {
            llSetText("", ZERO_VECTOR, 0.0);
        }
    }

}
