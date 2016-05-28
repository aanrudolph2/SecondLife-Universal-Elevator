/* USAGE
 * 
 * Description of Lift must match names of Waypoints
 * If lift script must be reset, do not reset waypoints.
 *
 * Floor Call buttons must be named "button" (default)
 * Lift Cab Doors must be named "Door" (default)
 * Descriptions must be a numeral corresponding to the button's
 * respective waypoint
 *
 */

// USER SETTINGS

vector door_direction = <1, 0, 0>; // REQUIRED: local direction each door slides (default: +X axis)
string door_name = "door"; // REQUIRED: Name of each door (Reset script if the linkset changes or names change)
string btn_name = "button"; // REQUIRED: Name of each button (No reset required if names change)

string lift_start_snd = "e85eec78-74e9-e0d3-62a7-e609c37ef6b3"; // OPTIONAL: Sound to use when lift starts moving
string lift_stop_snd = "d1b034c2-c7a2-35a0-81db-6fffe03b6fe5"; // OPTIONAL: Sound to use when lift stops moving
string lift_move_snd = "9bd30961-fee3-a546-c786-222cc7c8cbde"; // OPTIONAL: Sound to loop as lift moves

integer numSteps = 20; // REQUIRED: Number of steps in door animation

// MAIN SCRIPT

list doors = [];
list waypoints = [];
list stop_queue = [];

integer is_moving = FALSE;
key target_id;
vector target_pos;

key http_url_req;
string call_req_url;

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

move_to_floor(vector pos)
{
    llTarget(pos, 1.0);
    
    vector target = pos - llGetPos();
    is_moving = TRUE;
    
    float frames = 45/llGetRegionFPS();
    float time = llVecMag(target)/2;
    
    if(time >= 0.1)
    {
        llSetKeyframedMotion([target, frames*time], [KFM_DATA, KFM_TRANSLATION]);
        if(lift_start_snd)
            llPlaySound(lift_start_snd, 0.5);
        llSleep(0.1);
        if(lift_move_snd)
            llLoopSound(lift_move_snd, 0.5);
    }
}

check_and_move()
{
    if(!is_moving && llGetListLength(stop_queue) > 0)
    {
        if(target_id != NULL_KEY)
        {
            llRegionSayTo(target_id, -25, "CLOSE");
        }
        target_id = (key)llList2String(stop_queue, 1);
        target_pos = llList2Vector(llGetObjectDetails(target_id, [OBJECT_POS]), 0);
        stop_queue = llDeleteSubList(stop_queue, 0, 1);
        
        doors_close();
        llSleep(0.5);
        
        move_to_floor(target_pos);
    }
}

string llGetLinkDesc(integer num)
{
    return llList2String(llGetLinkPrimitiveParams(num, [PRIM_DESC]), 0);
}

default
{
    state_entry()
    {
        llSetSoundQueueing(TRUE);
        http_url_req = llRequestURL();
        
        integer link = llGetNumberOfPrims() + 1;
        while(--link > 0)
        {
            if(llGetLinkName(link) == door_name)
            {
                vector localPos = llList2Vector(llGetLinkPrimitiveParams(link, [PRIM_POS_LOCAL]), 0);
                rotation localRot = llList2Rot(llGetLinkPrimitiveParams(link, [PRIM_ROT_LOCAL]), 0);
                vector localSize = llList2Vector(llGetLinkPrimitiveParams(link, [PRIM_SIZE]), 0);
                doors += [link, localPos, localRot, localSize];
            }
        }
        
        llSetKeyframedMotion([ZERO_VECTOR, 1], [KFM_DATA, KFM_TRANSLATION]);
    }
    
    changed(integer chg)
    {
        if(chg & CHANGED_REGION_START)
        {
            http_url_req = llRequestURL();
        }
    }
    
    http_request(key id, string method, string body)
    {
        if(id == http_url_req && method == URL_REQUEST_GRANTED)
        {
            call_req_url = body;
            
            llRegionSay(-25, llList2CSV(["WAYPOINT DETECT", llGetObjectDesc(), call_req_url]));
        }
        else
        {
            // Waypoint Registration
            if(method == "POST")
            {
                list identifier = llCSV2List(body);
                if(llListFindList(waypoints, identifier) < 0)
                {
                    waypoints += identifier;
                    llHTTPResponse(id, 200, "Success");
                }
                else
                {
                    llHTTPResponse(id, 200, "Failure");
                }
            }
            // Call to floor
            else if(method == "PUT")
            {
                integer floor_req = (integer)llList2String(llCSV2List(body), 0);
                // If last waypoint is not the same as this one (person didn't hit button more than once)
                if((integer)llList2String(stop_queue, -2) != floor_req)
                {
                    // Enqueue floor onto stop queue
                    stop_queue += llCSV2List(body);
                    llHTTPResponse(id, 200, "OK");
                    check_and_move();
                }
                else
                {
                    llHTTPResponse(id, 208, "Already Reported");
                }
            }
        }
    }
    touch_start(integer num)
    {
        if(llGetLinkName(llDetectedLinkNumber(0)) == btn_name)
        {
            string move_idx = llGetLinkDesc(llDetectedLinkNumber(0));
            integer waypoint_start_idx = llListFindList(waypoints, [move_idx]);
            stop_queue = llList2List(waypoints, waypoint_start_idx, waypoint_start_idx + 1) + stop_queue;
            check_and_move();
        }
    }
    at_target(integer target, vector targPos, vector myPos)
    {
        if(is_moving)
        {
            llTargetRemove(target);
            llStopSound();
            
            if(llVecDist(targPos, myPos) > 0.25)
            {
                llSetKeyframedMotion([targPos - llGetPos(), 0.5], [KFM_DATA, KFM_TRANSLATION]);
                llSleep(0.5);
            }
            llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_STOP]);
            
            llSetPos(targPos);
            llSleep(0.5);
            
            if(target_id != NULL_KEY)
                llRegionSayTo(target_id, -25, "OFF");
            
            doors_open();
            
            if(lift_stop_snd)
                llPlaySound(lift_stop_snd, 0.5);
            llSetTimerEvent(5.0);
        }
    }
    timer()
    {
        llSetTimerEvent(0.0);
        is_moving = FALSE;
        check_and_move();
    }
}
