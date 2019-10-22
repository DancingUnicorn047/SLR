clearscreen.
lock steering to up + r(0,0,180).
set seekAlt to 500.
set done to false.
on ag9 { set done to true. }.


set ship:control:pilotmainthrottle to 0.

// hit "stage" until there's an active engine:
until ship:availablethrust > 0 {
  wait 0.5.
  stage.
}.

// hover against gravity:
lock Fg to ship:mass * body:mu /((ship:altitude + body:radius)^2).
lock am to vang(up:vector, ship:facing:vector).
lock alt_radar to alt:radar.
set T_star to 0.
lock throttle to T_star / ship:availablethrust.

// calculate initial hover PID gains
set wn to 1.
set zeta to 1.
set Kp to wn^2 * ship:mass.
set Kd to 2 * ship:mass * zeta * wn.
set Ki to 0.

Set SeekP to 0. // desired value for P (will get set later).
set P to 0.     // phenomenon P being affected.
set I to 0.     // crude approximation of Integral of P.
set D to 0.     // crude approximation of Derivative of P.
set oldT to -1. // (old time) start value flags the fact that it hasn't been calculated
set oldInput to 0. // previous return value of PID controller.
set cMin to -Fg.
set cMax to Fg.
set PID_array to list(Kp, Ki, Kd, cMin, cMax, SeekP, P, I, D, oldT, oldInput).	
set hoverPID to PID_array. // Kp, Ki, Kd vals.

gear on.  gear off. // on then off because of the weird KSP 'have to hit g twice' bug.

until gear {

	// update hover pid and thrust
	set Kp to wn^2 * ship:mass.
	set Kd to 2 * ship:mass * zeta * wn.
	set PID_array[0] to Kp.
	set PID_array[1] to Ki.
	set PID_array[2] to Kd.
	set PID_array[3] to cMin.
	set PID_array[4] to cMax.
	set Kp   to PID_array[0].
	set Ki   to PID_array[1].
	set Kd   to PID_array[2].
	set cMin to PID_array[3].
	set cMax to PID_array[4].
	set oldS   to PID_array[5].
	set oldP   to PID_array[6].
	set oldI   to PID_array[7].
	set oldD   to PID_array[8].
	set oldT   to PID_array[9]. // Old Time
	set oldInput to PID_array[10]. // prev return value, just in case we have to do nothing and return it again.

	set P to seekAlt - alt_radar.
	set D to oldD. // default if we do no work this time.
	set I to oldI. // default if we do no work this time.
	set newInput to oldInput. // default if we do no work this time.

	set t to time:seconds.
	set dT to t - oldT.

	if oldT < 0 {
		// I have never been called yet - so don't trust any
		// of the settings yet.
 	 } else {
	if dT > 0 { // Do nothing if no physics tick has passed from prev call to now.
	set D to (P - oldP)/dT. // crude fake derivative of P
	set onlyPD to Kp*P + Kd*D.
	if (oldI > 0 or onlyPD > cMin) and (oldI < 0 or onlyPD < cMax) { // only do the I turm when within the control range
	set I to oldI + P*dT. // crude fake integral of P
	}.
	set newInput to onlyPD + Ki*I.
	}.
}.

  set newInput to max(cMin,min(cMax,newInput)).

  // remember old values for next time.
  set PID_array[5] to seekAlt.
  set PID_array[6] to P.
  set PID_array[7] to I.
  set PID_array[8] to D.
  set PID_array[9] to t.
  set PID_array[10] to newInput.
	set T_star to (newInput + Fg)/ cos(am).
	wait 0.001.
}.


set throttle to 0.
set radarOffset to 2.	 				// The value of alt:radar when landed (on gear)
lock trueRadar to alt:radar - radarOffset.			// Offset radar to get distance from gear to ground
lock g to constant:g * body:mass / body:radius^2.		// Gravity (m/s^2)
lock maxDecel to (ship:availablethrust / ship:mass) - g.	// Maximum deceleration possible (m/s^2)
lock stopDist to ship:verticalspeed^2 / (2 * maxDecel).		// The distance the burn will require
lock idealThrottle to stopDist / trueRadar.			// Throttle required for perfect hoverslam
lock impactTime to trueRadar / abs(ship:verticalspeed).		// Time until impact, used for landing gear
set ship:control:pilotmainthrottle to 0.


WAIT UNTIL ship:verticalspeed < -1.
	//print "Preparing for hoverslam...".
	rcs on.
	brakes on.
	lock steering to up + r(0,0,180).
	when impactTime < 3 then {gear on.}

WAIT UNTIL trueRadar < stopDist.
	//print "Performing hoverslam".
	lock throttle to idealThrottle.

WAIT UNTIL ship:verticalspeed > -0.01.
	//print "Hoverslam completed".
	set ship:control:pilotmainthrottle to 0.
	rcs off.
