// Weather repeater - prim rain
//  Version 1.0   26 September 2022

list effects = [SMOOTH,LOOP];
integer movement = 0;
integer face = ALL_SIDES;   //Number representing the side to activate the animation on.
integer sideX = 1;          //Represents how many horizontal images (frames) are contained in your texture.
integer sideY = 1;          //Same as sideX, except represents vertical images (frames).
float start = 0.0;          //Frame to start animation on. (0 to start at the first frame of the texture)
float length = 0.0;         //Number of frames to animate, set to 0 to animate all frames.
float speed = 1.5;          //Frames per second to play.

vector fullSize = <30.0, 30.0, 35.0>;
integer fadeStart = 0;
integer fadeEnd = 100;
integer raining;

fade_up()
{
    float i;
    float v;
    for (i = fadeStart; i < fadeEnd; i++)
    {
        v = i * 0.01;
        // We set alpha using this function as it has a delay of 200mS each time we call it
        llSetPrimitiveParams([PRIM_COLOR, ALL_SIDES, <1,1,1>, v]);
    }
}

fade_down()
{
    float i;
    float v;
    for (i = fadeEnd; i > fadeStart; i--)
    {
        v = i * 0.01;
        // We set alpha using this function as it has a delay of 200mS each time we call it
        llSetPrimitiveParams([PRIM_COLOR, ALL_SIDES, <1,1,1>, v]);
    }   
}

doFX()
{
    if(fadeStart < fadeEnd)
    {
        fade_up();
    }
}

turnOff()
{   
    llSetTimerEvent(0);
    fade_down();
    llSetScale(<0.01, 0.01, 0.01>);
    raining = FALSE;   
}


initAnim(integer value)
{
    if(value == TRUE)
    {
        integer effectBits;
        integer i;
        for(i = 0; i < llGetListLength(effects); i++)
        {
            effectBits = (effectBits | llList2Integer(effects,i));
        }
        integer params = (effectBits|movement);
        llSetTextureAnim(ANIM_ON|params,face,sideX,sideY,start,length,speed);
    }
    else
    {
        llSetTextureAnim(0,face,sideX,sideY,start,length,speed);
    }
}


default
{
    on_rez(integer num)
    {
        llResetScript();
    }

    state_entry()
    {
       turnOff();
    }

    link_message(integer sender_num, integer num, string message, key id)
    {
        if (message == "RAIN")
        {
            if (num == 1)
            {
                if (raining == FALSE)
                {
                    raining = TRUE;
                    llSetScale(fullSize);
                    doFX();
                }
            }
            else
            {
                turnOff();
            }
            
        }
        else if (message == "DEBUG")
        {
            if (num == 1)
            {
                llSetScale(fullSize);
                llSetAlpha(1.0, ALL_SIDES);
            }
            else
            {
                llSetScale(<0.01, 0.01, 0.01>);
                llSetAlpha(0.0, ALL_SIDES);
            }
        }
        else if (message == "RESET")
        {
            turnOff();
        }
    }

}