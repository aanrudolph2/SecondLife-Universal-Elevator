/* USAGE
 * 
 * Description of Lift must match names of Waypoints
 * If lift script must be reset, do not reset waypoints.
 *
 * Floor Call buttons must be named "button"
 * Descriptions must be a numeral corresponding to the button's
 * respective waypoint
 *
 */

integer waypoint_detect_listener;
integer call_listener;

list waypoints = [];

list stop_queue = [];

integer SORT_LIST = TRUE;

integer is_moving = FALSE;

key target_id;

vector target_pos;

move_to_floor(vector pos)
{
    // llOwnerSay("Moving to position: " + (string)pos);
    llTarget(pos, 1.0);
    
    vector target = pos - llGetPos();
    is_moving = TRUE;
    
    float frames = 45/llGetRegionFPS();
    float time = llVecMag(target)/2;
    
    if(time >= 0.1)
    {
        llSetKeyframedMotion([target, frames*time], [KFM_DATA, KFM_TRANSLATION]);
        llPlaySound("e85eec78-74e9-e0d3-62a7-e609c37ef6b3", 0.5);
        llSleep(0.1);
        llLoopSound("9bd30961-fee3-a546-c786-222cc7c8cbde", 0.5);
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
        integer move_idx = llList2Integer(stop_queue, 0);
        target_id = llList2Key(stop_queue, 1);
        target_pos = llList2Vector(llGetObjectDetails(target_id, [OBJECT_POS]), 0);
        stop_queue = llDeleteSubList(stop_queue, 0, 1);
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
        waypoint_detect_listener = llListen(-25, "", "", "");
        call_listener = llListen(-20, "", "", "");
        llRegionSay(-25, llList2CSV(["WAYPOINT DETECT", llGetObjectDesc()]));
        
        llSetKeyframedMotion([ZERO_VECTOR, 1], [KFM_DATA, KFM_TRANSLATION]);
        llSetTimerEvent(2.0);
    }
    listen(integer chan, string name, key id, string msg)
    {
        if(chan == -25 && name == llGetObjectDesc())
        {
            // Waypoint response. Msg is the floor identifier
            list identifier = [(integer)msg, id];
            if(llListFindList(waypoints, identifier) < 0)
            {
                waypoints += identifier;
            }
        }
        if(chan == -20)
        {
            // Call request. Msg is floor identifier. Must correspond to existing registered waypoint.
            integer index = llListFindList(waypoints, [(integer)msg]);
            if(index >= 0)
            {
                // Uncomment for debug
                // llOwnerSay("Request for floor: " + msg);
                
                // If last waypoint is not the same as this one (person didn't hit button more than once)
                if(llList2Integer(stop_queue, -1) != (integer)msg)
                {
                    // Enqueue floor onto stop queue
                    stop_queue += [(integer)msg - 1, id];
                }
                check_and_move();
            }
            else
            {
                // Uncomment for debug
                // llOwnerSay("Request for unknown floor: " + msg);
            }
        }
    }
    touch_start(integer num)
    {
        if(llGetLinkName(llDetectedLinkNumber(0)) == "button")
        {
            integer move_idx = (integer)llGetLinkDesc(llDetectedLinkNumber(0)) - 1;
            stop_queue = [move_idx, llList2Key(waypoints, 2*(move_idx) + 1)] + stop_queue;
            check_and_move();
        }
    }
    at_target(integer target, vector targPos, vector myPos)
    {
        if(is_moving)
        {
            is_moving = FALSE;
            if(target_id != NULL_KEY)
                llRegionSayTo(target_id, -25, "OFF");
            llTargetRemove(target);
            llStopSound();
            
            if(llVecDist(targPos, myPos) > 0.25)
            {
                llSetKeyframedMotion([targPos - llGetPos(), 0.5], [KFM_DATA, KFM_TRANSLATION]);
                llSleep(0.5);
            }
            llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_STOP]);
            
            llSetPos(targPos);
            llPlaySound("d1b034c2-c7a2-35a0-81db-6fffe03b6fe5", 0.5);
            llSleep(5.0);
            check_and_move();
        }
    }
    timer()
    {
        if(SORT_LIST)
        {
            waypoints = llListSort(waypoints, 2, TRUE);
            // llOwnerSay("Waypoints: " + llList2CSV(waypoints));
            SORT_LIST = FALSE;
            llSetTimerEvent(0);
        }
    }
}
