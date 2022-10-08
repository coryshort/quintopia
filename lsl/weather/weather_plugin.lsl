// weather_plugin.lsl
// Version 1.1      3 October 2022
// Weather system controler driven by link messages
// Now also sends messages on farm chan to repeaters 
//   WR_SOUND,  WR_RAIN, WR_CLOUDS, WR_FXEND, WR_RESET, WR_DEBUG
// New text
string TXT_NO_RIGHTS = "Sorry, you do not have sufficient rights to change the environment";

integer DEBUGMODE = FALSE;

debug(string text)
{
    if ((DEBUGMODE == TRUE) || (debugMode == TRUE)) llOwnerSay("DEBUG:" + llToUpper(llGetScriptName()) + " " + text);
}

// Can be changed via config notecard
integer controlEnvironment = FALSE; // CONTROL_ENVIRONMENT=0     Set to 1 to change the enviroment values for parcel or region as per below setting
string  extent = "PARCEL";          // EXTENT=Parcel             Can be parcel or region, not case sensitive
integer transition = 30;            // TRANSITION=30             Not sure this is implemented in browsers yet?
integer doFog = FALSE;              // DO_FOG=0                  Set to 1 to have a foggy environment set every now and then
string  languageCode = "en-GB";     // LANG=en-GB
//
string SUFFIX = "W2";
//
float timerInterval = 20;
//
// List of links and priority levels for weather prims
list cloudLinks;
list cloudLevels;
list rainLinks;
list lightningLinks;
//
integer cloudCount;
string  cloudBaseName = "cloud-";
integer cloudTextureCount;
integer darkCloud1 = -1;
integer darkCloud2 = -1;
string  rainPrimName = "rain";
string  rainSound = "RAIN";
string  thunderBaseName = "thunder-";
integer maxThunderLevel;
string  lightningBaseName = "lightning-";
string  fogTexture = "fog";
string  fogPrimName = "fogger";
integer fogPrim = -1;
//
string ENV_FOG = "DayCycle_Fog";
string ENV_RAIN = "DayCycle_Rain";
string ENV_FINE = "DayCycle_Fine";
//
integer priority = 0;       // 0 is off, then levels 1, 2, 3, 4 (4 is max clouds)
integer index;
integer thunderLevel;
integer fxRadius;
float   volume = 0;
string  status = "";
integer rainState;
key     owner;
integer foggy = FALSE;
integer lastFog = 0;
integer FARM_CHANNEL = -911201;
string  PASSWORD = "*";
integer isMaster = FALSE;
integer busy = FALSE;
integer lastPriority = 0;
integer debugMode = 0;


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
                list tok = llParseStringKeepNulls(line, ["="], []);
                string cmd = llList2String(tok, 0);
                string val = llList2String(tok, 1);           
                     if (cmd == "CONTROL_ENVIRONMENT") controlEnvironment = (integer)val;
                else if (cmd == "EXTENT") extent = llToUpper(val);
                else if (cmd == "TRANSITION") transition = (integer)val;
                else if (cmd == "DO_FOG") doFog = (integer)val;
                else if (cmd == "LANG") languageCode = val;
            }
        }
    }
    loadLanguage(languageCode);
}

loadLanguage(string langCode)
{
    // optional language notecard
    string languageNC = langCode + "-lang" +SUFFIX;
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
                         if (cmd == "TXT_NO_RIGHTS")  TXT_NO_RIGHTS = val;
                }
            }
        }
    }
}

makeDarkClouds(integer lnkNum)
{
    debug("--makeDarkClouds--");
    string cloudTex = "5b9295d0-791f-4fa2-ba37-f16a73f3b2c6";
    llLinkParticleSystem(lnkNum,
    [
        PSYS_SRC_PATTERN,
        PSYS_SRC_PATTERN_ANGLE,
        PSYS_SRC_BURST_RATE, 0.01,                  // How long before the next particle is emited (in seconds)
        PSYS_SRC_BURST_RADIUS, 0.1,                 // How far from the source to start emiting particles
        PSYS_SRC_BURST_PART_COUNT, 100,             // How many particles to emit per BURST
        PSYS_SRC_OUTERANGLE, 3.14,                  // The area that will be filled with particles
        PSYS_SRC_INNERANGLE, 0.00,                  // A slice of the circle (hole) where particles will not be created
        PSYS_SRC_MAX_AGE, 0.0,                      // How long in seconds the system will make particles, 0 means no time limit.
        PSYS_PART_MAX_AGE, 120.0,                   // How long each particle will last before dying
        PSYS_SRC_BURST_SPEED_MAX, 2.0,              // Max speed each particle can travel at
        PSYS_SRC_BURST_SPEED_MIN, 0.5,              // Min speed each particle can travel at
        PSYS_SRC_TEXTURE, cloudTex,                 // Texture used as a particle.  For no texture use null string ""
        PSYS_PART_START_ALPHA, 1.0,                 // Alpha (transparency) value at birth
        PSYS_PART_END_ALPHA, 0.0,                   // Alpha (transparency) value at death
        PSYS_PART_START_SCALE, <15.0, 15.0, 1>,     // Start size of particles
        PSYS_PART_END_SCALE, <25.0, 25.0, 1>,       // End size (--requires PSYS_PART_INTERP_SCALE_MASK)
        PSYS_PART_START_COLOR, <0.6, 0.6, 0.6>,      // Start color of particles <R,G,B>
        PSYS_PART_END_COLOR, <1.0, 1.0, 1.0>,        // End color <R,G,B> (--requires PSYS_PART_INTERP_COLOR_MASK)
        PSYS_PART_FLAGS,
        PSYS_PART_EMISSIVE_MASK                     // Make the particles glow
        | PSYS_PART_BOUNCE_MASK                     // Make particles bounce on Z plan of object
        | PSYS_PART_INTERP_SCALE_MASK               // Change from starting size to end size
        | PSYS_PART_INTERP_COLOR_MASK               // Change from starting color to end color
        //| PSYS_PART_WIND_MASK                     // Particles effected by wind
    ]);
    if (isMaster == TRUE) llRegionSay(FARM_CHANNEL, "WR_CLOUDS|" +PASSWORD +"|" +(string)owner +"|-1");
    busy = TRUE;
}

makeClouds(integer lnkNum, string cloudTex)
{
    debug("--makeClouds:" +(string)lnkNum +"  priority="+(string)priority);
    llLinkParticleSystem(lnkNum,
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
    if (isMaster == TRUE)
    {
        if (lastPriority != priority)
        {
            lastPriority = priority;
            llRegionSay(FARM_CHANNEL, "WR_CLOUDS|" +PASSWORD +"|" +(string)owner +"|" +(string)priority);
        }
    }
    busy = TRUE;
}

makeRain(integer radius)
{
    debug("--makeRain--");
    llStopSound();
    rainState = TRUE;
    llLoopSound(rainSound, volume);
    setEnvironment(ENV_RAIN);
    llParticleSystem( [
      PSYS_SRC_TEXTURE,
      NULL_KEY,
      PSYS_PART_START_SCALE, <0.1,0.5, 0>,
      PSYS_PART_END_SCALE, <0.05,1.5, 0>,
      PSYS_PART_START_COLOR, <1,1,1>,
      PSYS_PART_END_COLOR, <1,1,1>,
      PSYS_PART_START_ALPHA, 0.7,
      PSYS_PART_END_ALPHA, 0.5,
      PSYS_SRC_BURST_PART_COUNT, 5,
      PSYS_SRC_BURST_RATE, 0.00,
      PSYS_PART_MAX_AGE, 10.00,
      PSYS_SRC_MAX_AGE, 0.0,
      PSYS_SRC_PATTERN, 8,
      PSYS_SRC_ACCEL, <0.0,0.0, -7.2>,
      PSYS_SRC_BURST_RADIUS, 20.0,          // falling the rain 20m * 20m now
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
    if (isMaster == TRUE) llRegionSay(FARM_CHANNEL, "WR_RAIN|" +PASSWORD +"|" +(string)owner +"|" +(string)radius);
    busy = TRUE;
}

makeFog()
{
    setEnvironment(ENV_FOG);
    // Mask Flags - set to TRUE to enable
    integer glow = TRUE;                // Make the particles glow
    integer bounce = TRUE;              // Make particles bounce on Z plan of object
    integer interpColor = TRUE;         // Go from start to end color
    integer interpSize = TRUE;          // Go from start to end size
    integer wind = TRUE;                // Particles effected by wind
    integer followSource = TRUE;        // Particles follow the source
    integer followVel = TRUE;           // Particles turn to velocity direction
    integer pattern = PSYS_SRC_PATTERN_ANGLE_CONE;
    key target = llGetKey();
    // Particle params
    float age = 180;                    // Life of each particle <-- invrease that value for larger fog
    float maxSpeed = 1;                 // Max speed each particle is spit out at
    float minSpeed = 1;                 // Min speed each particle is spit out at
    string texture = "fog";             // Texture used for particles, default used if blank
    float startAlpha = 0.05;             // Start alpha (transparency) value
    float endAlpha = 0.01;              // End alpha (transparency) value
    vector startColor = <0.8, 0.8, 0.8>;// Start color of particles <R,G,B>
    vector endColor = <0.7, 0.7, 0.7>;  // End color of particles <R,G,B> (if interpColor == TRUE)
    vector startSize = <3.5, 3.5, 1>;   // Start size of particles
    vector endSize = <4.0, 4.0, 1>;     // End size of particles (if interpSize == TRUE)
    vector push = <0,0,0>;              // Force pushed on particles
    // System paramaters
    float rate = 0.01;                   // How fast (rate) to emit particles
    float radius = 3;                   // Radius to emit particles for BURST pattern
    integer count = 10;                 // How many particles to emit per BURST <-- increase that value for more tense fog
    float outerAngle = 1.57;            // Outer angle for all ANGLE patterns
    float innerAngle = 1.58;            // Inner angle for all ANGLE patterns
    vector omega = <0,0,1>;             // Rotation of ANGLE patterns around the source
    float life = 0;                     // Life in seconds for the system to make particles
    // Script variables
    integer flags;

    if (glow) flags = flags | PSYS_PART_EMISSIVE_MASK;
    if (bounce) flags = flags | PSYS_PART_BOUNCE_MASK;
    if (interpColor) flags = flags | PSYS_PART_INTERP_COLOR_MASK;
    if (interpSize) flags = flags | PSYS_PART_INTERP_SCALE_MASK;
    if (wind) flags = flags | PSYS_PART_WIND_MASK;
    if (followSource) flags = flags | PSYS_PART_FOLLOW_SRC_MASK;
    if (followVel) flags = flags | PSYS_PART_FOLLOW_VELOCITY_MASK;
    if (target != "") flags = flags | PSYS_PART_TARGET_POS_MASK;

    llLinkParticleSystem(fogPrim, 
    [   PSYS_PART_MAX_AGE,age,
        PSYS_PART_FLAGS,flags,
        PSYS_PART_START_COLOR, startColor,
        PSYS_PART_END_COLOR, endColor,
        PSYS_PART_START_SCALE,startSize,
        PSYS_PART_END_SCALE,endSize,
        PSYS_SRC_PATTERN, pattern,
        PSYS_SRC_BURST_RATE,rate,
        PSYS_SRC_ACCEL, push,
        PSYS_SRC_BURST_PART_COUNT,count,
        PSYS_SRC_BURST_RADIUS,radius,
        PSYS_SRC_BURST_SPEED_MIN,minSpeed,
        PSYS_SRC_BURST_SPEED_MAX,maxSpeed,
        PSYS_SRC_TARGET_KEY,target,
        PSYS_SRC_ANGLE_BEGIN,innerAngle,
        PSYS_SRC_ANGLE_END,outerAngle,
        PSYS_SRC_OMEGA, omega,
        PSYS_SRC_MAX_AGE, life,
        PSYS_SRC_TEXTURE, texture,
        PSYS_PART_START_ALPHA, startAlpha,
        PSYS_PART_END_ALPHA, endAlpha
    ]);
    if (isMaster == TRUE) llRegionSay(FARM_CHANNEL, "WR_FOG|" +PASSWORD +"|" +(string)owner +"|1|");
    busy = TRUE;
}

doLightning(integer active)
{
    if (llFrand(10) > 6 )
    {
        integer index;
        integer count = llGetListLength(lightningLinks);
        for (index = 0; index < count; index++)
        {
            llMessageLinked(llList2Integer(lightningLinks, index), active, "STRIKE", "");
            llSleep(2.0);
        }
    }
}

setEnvironment(string dayCycle)
{   
    if (controlEnvironment == TRUE)
    {     
        integer result;

        if (extent == "PARCEL")
        {
            if (llGetInventoryType(dayCycle) == INVENTORY_SETTING)
            {
                result = osReplaceParcelEnvironment(transition, dayCycle);
                if ((result == -1) ||(result == -3)) llOwnerSay(TXT_NO_RIGHTS);
                // -1 : "Parcel Owners May Override Environment" isn't checked
                // -3 : no rights to edit parcel
            }
        }
        else if (extent == "REGION") 
        {
            result = osReplaceRegionEnvironment(transition, dayCycle, 0.0, 99, 0, 0, 0);
            if (result == -3) llOwnerSay(TXT_NO_RIGHTS);
        }
        debug("setEnvironment (" +extent +") :" +(string)result +"  " +dayCycle);
        if ((dayCycle == ENV_FINE) && (isMaster == TRUE)) llRegionSay(FARM_CHANNEL, "WR_FXEND|" +PASSWORD +"|" +(string)owner);
    }
}

fxOff()
{
    debug("--fxOff--");
    status = "";
    llLinkParticleSystem(LINK_SET, []);
    llStopSound();
    rainState = FALSE;
    if ((isMaster == TRUE) && (busy == TRUE))
    {
        busy = FALSE;
        llRegionSay(FARM_CHANNEL, "WR_FXEND|" +PASSWORD +"|" +(string)owner);
        setEnvironment(ENV_FINE);
    }
}

darkCloudsOff()
{
    llLinkParticleSystem(darkCloud1, []);
    llSleep(1);
    llLinkParticleSystem(darkCloud2, []);
}

fogCheck()
{
    if (foggy == TRUE)
    {
        if ((llGetUnixTime() - lastFog) > 300)
        {
            setEnvironment(ENV_FINE);
            llLinkParticleSystem(LINK_SET, []);
            foggy = FALSE;
            lastFog = llGetUnixTime(); 
        }
    }
}

init()
{
    owner = llGetOwner();
    loadConfig();
    PASSWORD = osGetNotecardLine("sfp", 0);
    llSetLinkAlpha(LINK_ALL_CHILDREN, 0.0, ALL_SIDES);
    llSetLinkPrimitiveParamsFast(LINK_ALL_CHILDREN, [PRIM_TEXT, "", ZERO_VECTOR, 0.0]);
    llLinkParticleSystem(LINK_SET, []);
    llStopSound();
    rainState = FALSE;
    busy = FALSE;
    integer numPrims = llGetNumberOfPrims();
    //
    // Check how many cloud textures we have
    integer length = llGetInventoryNumber(INVENTORY_TEXTURE);
    integer strLength = llStringLength(cloudBaseName)-1;
    string name;
    cloudTextureCount = 0;
    for (index = 0 ; index < length; index++)
    {
        name = llGetInventoryName(INVENTORY_TEXTURE, index);
        if (llGetSubString(name, 0, strLength) == cloudBaseName)
        {
            cloudTextureCount++;
        }
    }
    //
    // Build list of cloud prims
    cloudLinks = [];
    cloudLevels = [];
    length = llStringLength(cloudBaseName) -1;
    for (index = 1; index <= numPrims; index++)
    {
       name = llGetLinkName(index);
            if (name == "darkCloud-1") darkCloud1 = index;
       else if (name == "darkCloud-2") darkCloud2 = index;
       else if (llGetSubString(name, 0, length) == cloudBaseName)
       {
           cloudLinks += index;
           cloudLevels += llGetSubString(name, length+1, -1);
       }
    }
    cloudCount = llGetListLength(cloudLinks);
    //
    // Build list of rain prims
    rainLinks = [];
    for (index = 1; index <= numPrims; index++)
    {
       if (llGetLinkName(index) == rainPrimName) rainLinks += index;
    }
    //
    // Build list of lightning prims
    lightningLinks = [];
    length = llStringLength(lightningBaseName) -1;
    for (index = 1; index <= numPrims; index++)
    {
        name = llGetLinkName(index);
        if (llGetSubString(name, 0, length) == lightningBaseName)
        {
           lightningLinks += index;
        }
    }
    //
    // Count how many thunder sounds we have
    length = llGetInventoryNumber(INVENTORY_SOUND);
    strLength = llStringLength(thunderBaseName)-1;
    maxThunderLevel = 0;
    for (index = 0 ; index < length; index++)
    {
        name = llGetInventoryName(INVENTORY_SOUND, index);
        if (llGetSubString(name, 0, strLength) == thunderBaseName)
        {
            maxThunderLevel++;
        }
    }
    // Find the fogger prim
    for (index = 1; index <= numPrims; index++)
    {
        name = llGetLinkName(index);
        if (name == fogPrimName) fogPrim = index;
    }
    // Check if we are master controller or not
    llRegionSay(FARM_CHANNEL, "WC_PING|" +PASSWORD +"|" +(string)owner);
    status = "waitPong";
    llListen(FARM_CHANNEL, "", "", "");
    llSetTimerEvent(3);
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
    }

    timer()
    {
        debug("timer:status="+status +"  priority="+(string)priority +"  thunderLevel="+(string)thunderLevel);
        if (status == "waitPong")
        {
            // Not had a pong back so assume we are the master weather control
            isMaster = TRUE;
            llRegionSay(FARM_CHANNEL, "WR_RESET|" +PASSWORD +"|" +(string)owner +"|1" );
            status = "";
            llSetText("Master", <0.008, 0.278, 0.992>, 1.0);
            llOwnerSay("I am master controller");
            llSetTimerEvent(30);
        }
        else if (status == "rainStart")
        {
            if (maxThunderLevel > 0) llSetTimerEvent(30/maxThunderLevel); else llSetTimerEvent(10);
            thunderLevel++;
            if (thunderLevel > maxThunderLevel)
            {
                status = "buildRainSound";
                volume += 0.1;
                makeRain(fxRadius);

            }
            else
            {
                string tmpStr = thunderBaseName + (string)thunderLevel;
                debug("playSound:"+ tmpStr);
                llPlaySound(tmpStr, 1.0);
                llRegionSay(FARM_CHANNEL, "WR_SOUND|" +PASSWORD +"|" +(string)owner +"|" +tmpStr);
            }
        }
        else if (status == "buildRainSound")
        {
            volume += 0.2;
            if (volume < 1.0)
            {
                makeRain(fxRadius);
            }
            else
            {
                volume = 1.0;
                status = "";
                makeRain(fxRadius);
                llSetTimerEvent(timerInterval);
            }
            llRegionSay(FARM_CHANNEL, "WR_RAIN|" +PASSWORD +"|" +(string)owner +"|" +(string)volume);
        }
        else if (status == "startClouds")
        {
            fogCheck();
            if (cloudTextureCount > 0)
            {
                string cloudToUse = cloudBaseName + (string)((integer)llFrand(cloudTextureCount));
                for (index = 1; index < cloudCount; index++)
                {
                    if (priority <= llList2Integer(cloudLevels, index)) makeClouds(llList2Integer(cloudLinks, index), cloudToUse);
                }
            }
            if (priority <4)
            {
                doLightning(0);
                darkCloudsOff();
            }
            else
            {
                doLightning(1);
            }
        }

        if (busy == FALSE)
        {
            llSetTimerEvent(timerInterval);
            fxOff();
            if (doFog == TRUE)
            {
                // Need at least 2 hours between fogs
                if ((llGetUnixTime() - lastFog) > 7200)
                {
                    if ((llFrand(100) >75) && (foggy == FALSE))
                    {
                        foggy = TRUE;
                        lastFog = llGetUnixTime();
                        llSetTimerEvent(300);
                        makeFog();
                    }
                }
                else 
                {
                    fogCheck();
                }
            }
        }
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        debug("link_message:"+str +"  num=" +(string)num +"  Status="+status);
        if (status != "waitPong")
        {
            list tk = llParseString2List(str, ["|"], []);
            string cmd = llList2String(tk, 0);

            if (cmd == "START_CLOUDS")
            {
                priority = num;
                status = "startClouds";
                llSetTimerEvent(0.1);
            }
            else if (cmd == "END_CLOUDS")
            {
                fxOff();
            }
            else if (cmd == "START_RAIN")
            {
                fxRadius = num;
                thunderLevel = 0;
                status = "rainStart";
                priority = 4;
                makeDarkClouds(darkCloud1);
                makeDarkClouds(darkCloud2);
                llSetTimerEvent(0.1);
            }
            else if (cmd == "RESET")
            {
                init();
            }
            else if (cmd == "DEBUG")
            {
                if (num == 1)
                {
                    debugMode = TRUE;
                    string primText;
                    llSetLinkAlpha(LINK_ALL_CHILDREN, 1.0, ALL_SIDES);
                    integer primNum;
                    for (index = 0; index < cloudCount; index++)
                    {
                        primNum = llList2Integer(cloudLinks, index);
                        primText = llList2String(llGetLinkPrimitiveParams(primNum, [PRIM_DESC]), 0);
                        llSetLinkPrimitiveParamsFast(primNum, [PRIM_TEXT, primText, <0, 0, 1>, 1.0]);
                    }
                    llOwnerSay("cloudCount="+(string)cloudCount +"  cloudTextureCount="+(string)cloudTextureCount   +"  maxThunderLevel="+(string)maxThunderLevel +"  priority="+(string)priority);
                }
                else
                {
                    debugMode = FALSE;
                    llSetLinkAlpha(LINK_ALL_CHILDREN, 0.0, ALL_SIDES);
                    llSetLinkPrimitiveParamsFast(LINK_ALL_CHILDREN, [PRIM_TEXT, "", ZERO_VECTOR, 0.0]);
                }
                llRegionSay(FARM_CHANNEL, "WR_DEBUG|" +PASSWORD +"|" +(string)owner +"|" +(string)num);
            }
        }
    }

    listen(integer channel, string name, key id, string message)
    {
        if (channel == FARM_CHANNEL)
        {        
            list tk = llParseString2List(message, ["|"], []);
            string cmd = llList2String(tk, 0);
            if (llList2String(tk, 1) == PASSWORD)
            {
                if (cmd == "WC_PONG")
                {
                    //if ((llList2Key(tk, 2) == owner) || (extent == "REGION"))
                     if (llList2Key(tk, 2) == owner)
                    {
                        isMaster = FALSE;
                        status = "";
                        llOwnerSay("Already a controller set, not controlling enviroment");
                        llSetText("Not master", <0.000, 1.000, 1.000>, 1.0);
                    }
                }
                else if (cmd == "WC_PING")
                {
                    if (isMaster == TRUE) llRegionSay(FARM_CHANNEL, "WC_PONG|" +PASSWORD +"|" +(string)owner);
                }
            }
        }
    }

    changed(integer change)
    {
        if (change & CHANGED_OWNER)
        {
            llResetScript();
        }
    }

}

