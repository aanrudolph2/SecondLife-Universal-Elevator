# SecondLife-Universal-Elevator
Versatile elevator system based on HTTP for use in Second Life

Features:

* Keyframed
* Unlimited floors/waypoints
* Door support
* HTTP communication (no region chat after initial setup)
* Single-script design

Basic Setup:

The elevator must use the Prim Equivalence system. For more information, please refer to the Second Life Wiki

Links within the elevator object must be named accordingly:

* Any floor call button prim must be named "button" with its description corresponding to the corresponding floor
* The root prim of the elevator must have a unique description corresponding to its set of waypoints (e.g. TowerOne)
* If any changes are made to the above names or descriptions, or if any links are added/removed, the elevator script *must* be reset

Links within each waypoint must be set up as follows:

* The root prim must have the name matching the elevator's description (e.g. TowerOne, in the previous example)
* The root prim's description must be a unique floor number, ideally starting from 1 and going upwards
* Any call buttons must be linked to the waypoint. More than one call button is supported. They must all be named "Call Button"
* Any doors must be named "door." Doors open along the local positive Z axis. To determine a prim's local orientation, edit it using local coordinates, and rotate it accordingly.

Suggestions regarding this document's clarity may be directed to Aryn Gellner in Second Life.