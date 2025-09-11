var right_key = keyboard_check(ord("D"));
var left_key = keyboard_check(ord("A"));
var down_key = keyboard_check(ord("S"));
var up_key = keyboard_check(ord("W"));

var custom_colliders_x = [obj_wall, obj_wall_top, obj_wall_bottom];
var custom_colliders_y = [obj_wall, obj_wall_top, obj_wall_bottom];
var collide_x = false;
var collide_y = false;

//get player speed
var xspd = (right_key - left_key) * move_speed;
var yspd = (down_key - up_key) * move_speed;


// Add this variable in Create event if not already
//var facing = "down"; // initial facing
// In Step event, after calculating xspd and yspd, before x += xspd;
//if (xspd != 0 || yspd != 0) {
//	if (xspd > 0) {
//	sprite_index = spr_player_run_right;
//	facing = "right";
//	} else if (xspd < 0) {
//	sprite_index = spr_player_run_left;
//	facing = "left";
//	} else if (yspd > 0) {
//	sprite_index = spr_player_run_down;
//	facing = "down";
//	} else if (yspd < 0) {
//	sprite_index = spr_player_run_up;
//	facing = "up";
//	}
//}

//else {
//	if (facing == "down")
//		sprite_index = spr_player_idle_down;
//		else if (facing == "left") sprite_index = spr_player_idle_left;
//		else if (facing == "right") sprite_index = spr_player_idle_right;
//		else if (facing == "up") sprite_index = spr_player_idle_up;
//	}

//tutorial collisions
//if place_meeting(x + xspd, y, custom_colliders) == true
//	{
//		xspd = 0;
//	}
//if place_meeting(x, y + yspd, custom_colliders) == true
//	{
//		yspd = 0;
//	}

//set sprite
mask_index = sprite[DOWN];

if yspd == 0 {
	if xspd > 0 {face = RIGHT};
	if xspd < 0 {face = LEFT};
}

if xspd > 0 && face == LEFT {face = RIGHT}
if xspd < 0 && face == RIGHT {face = LEFT}

if xspd = 0 {
	if yspd > 0 {face = DOWN};
	if yspd < 0 {face = UP};
}

if yspd > 0 && face == UP {face = DOWN}
if yspd < 0 && face == DOWN {face = UP}

sprite_index = sprite[face];

//my collisions implementation
for (var i = 0; i < array_length(custom_colliders_x); i++) {
	if (place_meeting(x + xspd, y, custom_colliders_x[i])) {
		collide_x = true;
	}
}

for (var i = 0; i < array_length(custom_colliders_y); i++) {
	if (place_meeting(x, y + yspd, custom_colliders_y[i])) {
		collide_y = true;
	}
}

if (collide_x) xspd = 0;
if (collide_y) yspd = 0;


//move the player
x += xspd;
y += yspd;


//animate
if xspd == 0 && yspd == 0 {
	image_index = 0;
}


//feel free to comment out
depth = -y;
