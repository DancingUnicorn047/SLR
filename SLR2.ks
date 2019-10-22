clearscreen.
set radarOffset to 6.5.	 				// The value of alt:radar when landed (on gear)
lock trueRadar to alt:radar - radarOffset.			// Offset radar to get distance from gear to ground
lock g to constant:g * body:mass / body:radius^2.		// Gravity (m/s^2)
lock maxDecel to (ship:availablethrust / ship:mass) - g.	// Maximum deceleration possible (m/s^2)
lock stopDist to ship:verticalspeed^2 / (2 * maxDecel).		// The distance the burn will require
lock idealThrottle to stopDist / trueRadar.			// Throttle required for perfect hoverslam
lock impactTime to trueRadar / abs(ship:verticalspeed).		// Time until impact, used for landing gear
set ship:control:pilotmainthrottle to 0.
set padpos to SHIP:GEOPOSITION.
set maxtilt to 10. //max tilting degrees
//lock tgtvel to SHIP:GEOPOSITION - padpos.
//lock steeringoffset to tgtvel.
//set tv:startupdater to { return SHIP:GEOPOSITION. }.
//set tv:vecupdater to { return tgtvel. }.
WAIT UNTIL ship:verticalspeed < -1.
	//print SHIP:GEOPOSITION + ",	" + padpos.
	//print "Preparing for hoverslam...".
	rcs on.
	brakes on.
	lock steering to LATLNG(padpos:lat,padpos:lng):ALTITUDEPOSITION(287).
	when impactTime < 3 then {gear on.}

WAIT UNTIL SHIP:ALTITUDE < 400.
	STAGE.

WAIT UNTIL trueRadar < stopDist.
	//print "Performing hoverslam".
	lock throttle to idealThrottle.
	
WAIT UNTIL trueRadar < 20.
	lock steering to (-1) * SHIP:VELOCITY:SURFACE.

WAIT UNTIL trueRadar < 0.5.
	//print "Hoverslam completed".
	set ship:control:pilotmainthrottle to 0.
	rcs off.
