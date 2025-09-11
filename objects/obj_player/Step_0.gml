var right_key = keyboard_check(ord("D"));
var left_key = keyboard_check(ord("A"));
var down_key = keyboard_check(ord("S"));
var up_key = keyboard_check(ord("W"));
var shift_key = keyboard_check(vk_shift);


var collide_x = false;
var collide_y = false;


//get player speed
var current_speed = shift_key ? move_speed * 2 : move_speed;
xspd = (right_key - left_key) * current_speed;
yspd = (down_key - up_key) * current_speed;


//set player facing down to start
mask_index = sprite[DOWN];


//detect if player hit wall
if place_meeting(x + xspd, y, obj_invisible_wall) == true
	{
		xspd = 0;
	}
if place_meeting(x, y + yspd, obj_invisible_wall) == true
	{
		yspd = 0;
	}


//calculate player movements
if (xspd != 0 || yspd != 0) {
	if (xspd > 0) {
        sprite_index = shift_key ? spr_player_run_right : spr_player_walk_right;
        face = RIGHT;
    } else if (xspd < 0) {
        sprite_index = shift_key ? spr_player_run_left : spr_player_walk_left;
        face = LEFT;
    } else if (yspd > 0) {
        sprite_index = shift_key ? spr_player_run_down : spr_player_walk_down;
        face = DOWN;
    } else if (yspd < 0) {
        sprite_index = shift_key ? spr_player_run_up : spr_player_walk_up;
        face = UP;
    }
} else {
	if (face == DOWN)
		sprite_index = spr_player_idle_down;
		else if (face == LEFT) sprite_index = spr_player_idle_left;
		else if (face == RIGHT) sprite_index = spr_player_idle_right;
		else if (face == UP) sprite_index = spr_player_idle_up;
	}


//stop player if they hit wall
if (collide_x) xspd = 0;
if (collide_y) yspd = 0;


//move the player
x += xspd;
y += yspd;


//animate
if xspd == 0 && yspd == 0 {
	image_index = 0;
}

