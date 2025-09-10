right_key = keyboard_check(ord("D"));
left_key = keyboard_check(ord("A"));
down_key = keyboard_check(ord("S"));
up_key = keyboard_check(ord("W"));


xspd = (right_key - left_key) * move_speed;
yspd = (down_key - up_key) * move_speed;


// Add this variable in Create event if not already
facing = "down"; // initial facing
// In Step event, after calculating xspd and yspd, before x += xspd;
if (xspd != 0 || yspd != 0) {
	if (xspd > 0) {
	sprite_index = spr_player_run_right;
	facing = "right";
	} else if (xspd < 0) {
	sprite_index = spr_player_run_left;
	facing = "left";
	} else if (yspd > 0) {
	sprite_index = spr_player_run_down;
	facing = "down";
	} else if (yspd < 0) {
	sprite_index = spr_player_run_up;
	facing = "up";
	}
}

else {
if (facing == "down")
	sprite_index = spr_player_idle_down;
	else if (facing == "left") sprite_index = spr_player_idle_left;
	else if (facing == "right") sprite_index = spr_player_idle_right;
	else if (facing == "up") sprite_index = spr_player_idle_up;
}

//collisions
if place_meeting(x + xspd, y, obj_wall) == true
	{
		xspd = 0;
	}
if place_meeting(x, y + yspd, obj_wall) == true
	{
		yspd = 0;
	}


x += xspd;
y += yspd;