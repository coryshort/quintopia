// Weather repeater - overhead clouds
//  Version 1.0     7 October 2022

integer cloudType = 0;
string cloudBase = "cloud";
integer isRaining = FALSE;


lightClouds()
{
    if (cloudType != 1)
    {
        integer tmp = llRound(llFrand(2));
        tmp++;
        string cloudTex = cloudBase +"-" +(string)tmp;
        cloudType = 1;
        llParticleSystem(
        [
            PSYS_SRC_PATTERN,  PSYS_SRC_PATTERN_EXPLODE,
            PSYS_PART_FLAGS, 4
            | PSYS_PART_BOUNCE_MASK //Bounce.
            //| PSYS_PART_WIND_MASK  //Effected by wind.
            | PSYS_PART_INTERP_COLOR_MASK //Color transition.
            | PSYS_PART_INTERP_SCALE_MASK // Scale transition.
            ,PSYS_SRC_TEXTURE, cloudTex,
            PSYS_PART_START_ALPHA,0.7,
            PSYS_PART_END_ALPHA,0.0,
            PSYS_PART_START_COLOR, <1.0,1.0,1.0>,
            PSYS_PART_END_COLOR, <1.0,1.0,1.0>,
            PSYS_PART_START_SCALE,<2.0,2.0, 1>,
            PSYS_PART_END_SCALE,<6.0, 6.0, 1>,
            PSYS_SRC_BURST_PART_COUNT,4,
            PSYS_SRC_BURST_RATE,0.05,
            PSYS_PART_MAX_AGE,120,
            PSYS_SRC_MAX_AGE,0.0,
            PSYS_SRC_ANGLE_BEGIN, 0,//min:0.0 /max:3.14
            PSYS_SRC_ANGLE_END, 3.14, //min:0.0 /max:3.14
            PSYS_SRC_BURST_RADIUS, 1.0,
            PSYS_SRC_ACCEL, <0.00, 0.00, -0.0800>,
            PSYS_SRC_BURST_SPEED_MIN, 0.05,
            PSYS_SRC_BURST_SPEED_MAX, 0.30,
            PSYS_SRC_OMEGA, <-0.0, 0.0, 0.00>
        ]);
    }
}

darkClouds()
{
    if (cloudType != 2)
    {
        cloudType = 2;
        vector endColor = <0.2, 0.2, 0.2>;
        llParticleSystem(
        [ 
            PSYS_SRC_PATTERN, 
            PSYS_SRC_PATTERN_ANGLE,                // Particles go in a flat circular formation

            PSYS_SRC_BURST_RATE, 0.01 ,              // How long before the next particle is emmited (in seconds)
            PSYS_SRC_BURST_RADIUS, 1.0 ,            // How far from the source to start emmiting particles
            PSYS_SRC_BURST_PART_COUNT, 100 ,         // How many particles to emit per BURST 
            PSYS_SRC_OUTERANGLE, 3.14 ,             // The area that will be filled with particles
            PSYS_SRC_INNERANGLE, 0.00 ,             // A slice of the circle (hole) where particles will not be created
            PSYS_SRC_MAX_AGE, 0.0 ,                 //How long in seconds the system will make particles, 0 means no time limit.
            PSYS_PART_MAX_AGE, 20.0 ,                // How long each particle will last before dying
            PSYS_SRC_BURST_SPEED_MAX, 1.0 ,         // Max speed each particle can travel at   **See End Note 2
            PSYS_SRC_BURST_SPEED_MIN, 1.0 ,         // Min speed each particle can travel at
            PSYS_SRC_TEXTURE, "5b9295d0-791f-4fa2-ba37-f16a73f3b2c6",                   // Texture used as a particle.  For no texture use null string ""
            PSYS_PART_START_ALPHA, 1.0 ,            // Alpha (transparency) value at birth
            PSYS_PART_END_ALPHA, 0.0 ,              // Alpha (transparency) value at death
            PSYS_PART_START_SCALE, <15.0, 15.0,15>,  // Start size of particles    **See End Note 3
            PSYS_PART_END_SCALE, <15.0, 15.0,15>,    
            PSYS_PART_START_COLOR, <0.5, 0.5, 0.5>,   
            PSYS_PART_END_COLOR, endColor,        
            PSYS_PART_FLAGS,
            PSYS_PART_EMISSIVE_MASK                 // Make the particles glow
            | PSYS_PART_BOUNCE_MASK                 // Make particles bounce on Z plan of object
            | PSYS_PART_INTERP_SCALE_MASK           // Change from starting size to end size
            | PSYS_PART_INTERP_COLOR_MASK           // Change from starting color to end color
        ]);
    }
}


default
{
    
    state_entry()
    {
        llParticleSystem([]);
        cloudType = 0;
        isRaining = FALSE;
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        list tk = llParseString2List(str, ["|"], []);
        string cmd = llList2String(tk, 0);

        if (cmd == "CLOUDS")
        {
            if (isRaining == FALSE)
            {
                if (num == -1)
                {
                    darkClouds();
                }
                else if (num == 1)
                {
                    lightClouds();
                }
                else
                {
                    if (cloudType != 0)
                    {
                        cloudType = 0;
                        llParticleSystem([]);
                    }
                }
            }
        }
        else if (cmd == "RAIN")
        {
            isRaining = TRUE;
            darkClouds();
        }
        else if (cmd == "SOUND")
        {
            cloudType = 0;
            darkClouds();
        }
        else if (cmd == "RESET")
        {
            llParticleSystem([]);
            cloudType = 0;
            isRaining = FALSE;
        }
    }
        
} 
