var right_key = keyboard_check(ord("D"));
var left_key = keyboard_check(ord("A"));
var down_key = keyboard_check(ord("S"));
var up_key = keyboard_check(ord("W"));
var collide_x = false;
var collide_y = false;


//get player speed
xspd = (right_key - left_key) * move_speed;
yspd = (down_key - up_key) * move_speed;


//calculate player movements
if (xspd != 0 || yspd != 0) {
	if (xspd > 0) {
	sprite_index = spr_player_run_right;
	face = RIGHT;
	} else if (xspd < 0) {
	sprite_index = spr_player_run_left;
	face = LEFT;
	} else if (yspd > 0) {
	sprite_index = spr_player_run_down;
	face = DOWN;
	} else if (yspd < 0) {
	sprite_index = spr_player_run_up;
	face = UP;
	}
} else {
	if (face == DOWN)
		sprite_index = spr_player_idle_down;
		else if (face == LEFT) sprite_index = spr_player_idle_left;
		else if (face == RIGHT) sprite_index = spr_player_idle_right;
		else if (face == UP) sprite_index = spr_player_idle_up;
	}


//collisions
if place_meeting(x + xspd, y, obj_invisible_wall) == true
	{
		xspd = 0;
	}
if place_meeting(x, y + yspd, obj_invisible_wall) == true
	{
		yspd = 0;
	}


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

if (collide_x) xspd = 0;
if (collide_y) yspd = 0;


//move the player
x += xspd;
y += yspd;


//animate
if xspd == 0 && yspd == 0 {
	image_index = 0;
}

