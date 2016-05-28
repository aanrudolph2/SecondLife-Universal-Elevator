/* USAGE
 * 
 * Name of Waypoint must match Description of Lift
 * Description of Waypoint must be a unique numeral matching the floor number
 * Ideally, numbered waypoints would be placed in ascending order from "ground level"
 * 
 * If Waypoint script must be reset, reset the Lift script.
 * 
 */

// USER SETTINGS

vector door_direction = <1, 0, 0>; // REQUIRED: local direction each door slides (default: +X axis)
string door_name = "door"; // REQUIRED: Name of each door (Reset script if the linkset changes)
string call_btn_name = "call"; // REQUIRED: Name of each call button (Reset script if the linkset changes)

vector idle_color = <0.631, 0.820, 1.000>; // REQUIRED: Color of call buttons in idle state
vector call_color = <1.000, 0.631, 0.631>; // REQUIRED: Color of call buttons in calling state

integer numSteps = 20; // REQUIRED: Number of steps in door animation

// MAIN SCRIPT


string parent_url = "";
key register_req;
key call_req;

list doors;

list call_buttons;

integer idle = TRUE;

doors_open()
{
    integer step;
    for(step = 0; step < numSteps; step ++)
    {
        list tmp;
        integer i;
        for(i = 0; i < llGetListLength(doors) / 4; i ++)
        {
            integer currLink = llList2Integer(doors, i * 4);
            
            vector pos = llList2Vector(doors, i * 4 + 1);
            rotation rot = llList2Rot(doors, i * 4 + 2);
            vector size = llList2Vector(doors, i * 4 + 3);
            
            tmp += [PRIM_LINK_TARGET, currLink, PRIM_POS_LOCAL, (llFabs(size * door_direction) * step) / (float)numSteps * door_direction*rot + pos];
        }
        llSetLinkPrimitiveParamsFast(0, tmp);
        llSleep(0.05);
    }
}

doors_close()
{
    integer step;
    for(step = numSteps - 1; step >= 0; step --)
    {
        list tmp;
        integer i;
        for(i = 0; i < llGetListLength(doors) / 4; i ++)
        {
            integer currLink = llList2Integer(doors, i * 4);
            
            vector pos = llList2Vector(doors, i * 4 + 1);
            rotation rot = llList2Rot(doors, i * 4 + 2);
            vector size = llList2Vector(doors, i * 4 + 3);
            
            tmp += [PRIM_LINK_TARGET, currLink, PRIM_POS_LOCAL, (llFabs(size * door_direction) * step) / (float)numSteps * door_direction*rot + pos];
        }
        llSetLinkPrimitiveParamsFast(0, tmp);
        llSleep(0.05);
    }
}

default
{
    state_entry()
    {
        integer link = llGetNumberOfPrims() + 1;
        
        while(--link > 1)
        {
            if(llGetLinkName(link) == door_name)
            {
                vector localPos = llList2Vector(llGetLinkPrimitiveParams(link, [PRIM_POS_LOCAL]), 0);
                rotation localRot = llList2Rot(llGetLinkPrimitiveParams(link, [PRIM_ROT_LOCAL]), 0);
                vector localSize = llList2Vector(llGetLinkPrimitiveParams(link, [PRIM_SIZE]), 0);
                doors += [link, localPos, localRot, localSize];
            }
            if(llGetLinkName(link) == call_btn_name)
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
            parent_url = llList2String(data, 2);
            
            register_req = llHTTPRequest(parent_url, [HTTP_METHOD, "POST"], llList2CSV([llGetObjectDesc(), llGetKey()]));
            
            // Uncomment for debug
            //llOwnerSay("Parent URL: " + (string)parent_url);
        }
        else if(llList2String(data, 0) == "OFF")
        {
            integer i;
            for(i = 0; i < llGetListLength(call_buttons); i ++)
            {
                llSetLinkPrimitiveParamsFast(llList2Integer(call_buttons, i), [PRIM_COLOR, ALL_SIDES, idle_color, 1.0]);
                idle = TRUE;
            }
            doors_open();
        }
        else if(llList2String(data, 0) == "CLOSE")
        {
            doors_close();
        }
    }
    http_response(key id, integer status, list meta, string body)
    {
        if(id == register_req)
        {
            if(status == 200)
            {
                if(body == "Success")
                {
                    // Uncomment for debug
                    //llOwnerSay("Waypoint " + llGetObjectDesc() + " is registered");
                }
                else
                {
                    //llOwnerSay("Registration error.");
                }
            }
            else
            {
                //llOwnerSay("Registration error. Does your lift exist yet?");
            }
        }
        else if(id == call_req)
        {
            if(status == 200)
            {
                integer i;
                for(i = 0; i < llGetListLength(call_buttons); i ++)
                {
                    llSetLinkPrimitiveParamsFast(llList2Integer(call_buttons, i), [PRIM_COLOR, ALL_SIDES, call_color, 1.0]);
                    idle = FALSE;
                }
            }
        }
    }
    touch_start(integer num)
    {
        if(idle)
        {
            if(parent_url != "" && llListFindList(call_buttons, [llDetectedLinkNumber(0)]) > -1)
            {
                call_req = llHTTPRequest(parent_url, [HTTP_METHOD, "PUT"], llList2CSV([llGetObjectDesc(), llGetKey()]));
            }
            else
            {
                // Uncomment for debug
                //llOwnerSay("No parent.");
            }
        }
    }
}
