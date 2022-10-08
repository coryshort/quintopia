// Weather repeater - prim lightning
//  Version 1.0   26 September 2022

float   glow = 0.30;
string  thunderFx = "thunderfx";
//
vector  fullSizeA = <26.18600, 33.48831, 34.13793>;   // Main lightning prim
vector  fullSizeB = <19.73479, 19.73479, 25.28120>;   // Secondary lightning prim
vector  fullSize;
integer fxActive = FALSE;



stopFx()
{
    llSetPrimitiveParams([PRIM_GLOW, ALL_SIDES, 0.0]);
    llStopSound();
    llSetScale(<0.01, 0.01, 0.01>);
    fxActive = FALSE;
}

doFX()
{
    llSetScale(fullSize);
    llSetPrimitiveParams([PRIM_GLOW, ALL_SIDES, glow]);
    llStopSound();
    llLoopSound(thunderFx, 1.0);
    fxActive = TRUE;
    llSetTimerEvent(1);
}

tryLightning()
{
    if (llFrand(5.0)>3)
    {
        doFX();
    }
    else
    {
        stopFx();
        llSetTimerEvent(10);
    }
}


default
{
    state_entry()
    {
        if (llGetObjectDesc() == "lightning-a") fullSize = fullSizeA; else fullSize = fullSizeB;
        stopFx();
        llSetTimerEvent(0);
    }

    on_rez(integer num)
    {
        llResetScript();
    }

    link_message(integer sender_num, integer num, string message, key id)
    {       
        if (message == "RAIN")
        {
            if (num == 1)
            {
                tryLightning();
            }
            else
            {
                stopFx();
            }
        }
        else if (message == "RESET")
        {
            llResetScript();
        }
        else if (message == "DEBUG")
        {
            if (num == 1)
            {
                llSetScale(fullSize);
                llSetAlpha(0.5, ALL_SIDES);
            }
            else
            {
                llSetScale(<0.01, 0.01, 0.01>);
                llSetAlpha(0.0, ALL_SIDES);
            }
        }
    }

    timer()
    {
        if (fxActive == TRUE)
        {
            llSetPrimitiveParams([PRIM_GLOW, ALL_SIDES, 0.0]);
            llStopSound();
            llSetScale(<0.01, 0.01, 0.01>);
            fxActive = FALSE;
        }
        else tryLightning();
    }


}
