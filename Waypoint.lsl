/* USAGE
 * 
 * Name of Waypoint must match Description of Lift
 * Description of Waypoint must be a unique numeral matching the floor number
 * Ideally, numbered waypoints would be placed in ascending order from "ground level"
 * 
 * If Waypoint script must be reset, reset the Lift script.
 * 
 */

key parent = NULL_KEY;

list doors;

list call_buttons;

integer doorSteps = 5;

doors_open()
{
    integer i;
    
    integer x;
    
    for(x = 0; x <= 5; x ++)
    {
        for(i = 0; i < llGetListLength(doors); i ++)
        {
            integer currDoor = llList2Integer(doors, 2*i);
            vector currDoorPos = llList2Vector(doors, 2*i + 1);
            
            rotation currDoorRot = llList2Rot(llGetLinkPrimitiveParams(currDoor, [PRIM_ROT_LOCAL]), 0);
            vector currDoorSize = llList2Vector(llGetLinkPrimitiveParams(currDoor, [PRIM_SIZE]), 0);
            
            llSetLinkPrimitiveParamsFast(currDoor, [PRIM_POS_LOCAL, currDoorPos + <0, 0, x * (currDoorSize.z / (float)doorSteps)>*currDoorRot]);
            llSleep(0.01);
        }
    }
}

doors_close()
{
    integer i;
    
    integer x;
    
    for(x = 5; x >= 0; x --)
    {
        for(i = 0; i < llGetListLength(doors); i ++)
        {
            integer currDoor = llList2Integer(doors, 2*i);
            vector currDoorPos = llList2Vector(doors, 2*i + 1);
            
            rotation currDoorRot = llList2Rot(llGetLinkPrimitiveParams(currDoor, [PRIM_ROT_LOCAL]), 0);
            vector currDoorSize = llList2Vector(llGetLinkPrimitiveParams(currDoor, [PRIM_SIZE]), 0);
            
            llSetLinkPrimitiveParamsFast(currDoor, [PRIM_POS_LOCAL, currDoorPos + <0, 0, x * (currDoorSize.z / (float)doorSteps)>*currDoorRot]);
            llSleep(0.01);
        }
    }
}

default
{
    state_entry()
    {
        integer link = llGetNumberOfPrims() + 1;
        
        while(--link > 1)
        {
            if(llGetLinkName(link) == "door")
            {
                doors += [link, llList2Vector(llGetLinkPrimitiveParams(link, [PRIM_POS_LOCAL]), 0)];
            }
            if(llGetLinkName(link) == "Call Button")
            {
                call_buttons += link;
            }
        }
        
        llListen(-25, "", "", "");
    }
    listen(integer chan, string name, key id, string msg)
    {
        list data = llCSV2List(msg);
        if(llList2String(data, 0) == "WAYPOINT DETECT" && llList2String(data, 1) == llGetObjectName())
        {
            llRegionSayTo(id, -25, llGetObjectDesc());
            parent = id;
            // Uncomment for debug
            //llOwnerSay("Parent ID: " + (string)parent);
        }
        else if(llList2String(data, 0) == "OFF")
        {
            integer i;
            for(i = 0; i < llGetListLength(call_buttons); i ++)
            {
                llSetLinkPrimitiveParamsFast(llList2Integer(call_buttons, i), [PRIM_COLOR, ALL_SIDES, <0.631, 0.820, 1.000>, 1.0]);
            }
            doors_open();
        }
        else if(llList2String(data, 0) == "CLOSE")
        {
            doors_close();
        }
    }
    touch_start(integer num)
    {
        if(parent != NULL_KEY && llListFindList(call_buttons, [llDetectedLinkNumber(0)]) > -1)
        {
            
            llRegionSayTo(parent, -20, llGetObjectDesc());
            integer i;
            for(i = 0; i < llGetListLength(call_buttons); i ++)
            {
                llSetLinkPrimitiveParamsFast(llList2Integer(call_buttons, i), [PRIM_COLOR, ALL_SIDES, <1.000, 0.631, 0.631>, 1.0]);
            }
        }
        else
        {
            // Uncomment for debug
            //llOwnerSay("No parent.");
        }
    }
}
