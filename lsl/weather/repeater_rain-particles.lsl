// Weather repeater - particle rain
//  Version 1.0   26 September 2022

//b75fc9da-7ed2-4af6-89dd-454999df1b10 rain v1
//ca58635c-ad5a-43f3-ae85-741b9ed9ec21 rain v2

integer raining;

doFX()
{
    llParticleSystem([
    PSYS_PART_FLAGS,( 0 
    |PSYS_PART_WIND_MASK
    |PSYS_PART_FOLLOW_VELOCITY_MASK ), 
    PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE ,
    PSYS_PART_START_ALPHA,0.5,
    PSYS_PART_END_ALPHA,0.7,
    PSYS_PART_START_COLOR,<1,1,1> ,
    PSYS_PART_END_COLOR,<1,1,1> ,
    PSYS_PART_START_SCALE,<4,4,0>,
    PSYS_PART_END_SCALE,<4,4,0>,
    PSYS_PART_MAX_AGE,5,
    PSYS_SRC_MAX_AGE,0,
    PSYS_SRC_ACCEL,<0,0,-5>,
    PSYS_SRC_BURST_PART_COUNT,25,
    PSYS_SRC_BURST_RADIUS,25,
    PSYS_SRC_BURST_RATE,0.01,
    PSYS_SRC_BURST_SPEED_MIN,0,
    PSYS_SRC_BURST_SPEED_MAX,0,
    PSYS_SRC_ANGLE_BEGIN,1,
    PSYS_SRC_ANGLE_END,1,
    PSYS_SRC_OMEGA,<0,0,0>,
    PSYS_SRC_TEXTURE, (key)"ca58635c-ad5a-43f3-ae85-741b9ed9ec21",
    // PSYS_SRC_TEXTURE, (key)"b75fc9da-7ed2-4af6-89dd-454999df1b10",
    PSYS_SRC_TARGET_KEY, (key)"00000000-0000-0000-0000-000000000000"
    ]);
}

turnOff()
{
    llStopSound();
    llParticleSystem([]);
    raining = FALSE;
}


default
{
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
                    doFX();
                }
            }
            else
            {
                turnOff();
            }
            
        }
        else if (message == "RESET")
        {
            turnOff();
        }
    }
}


