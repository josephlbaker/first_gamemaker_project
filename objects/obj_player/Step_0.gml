var right_key = keyboard_check(ord("D"));
var left_key = keyboard_check(ord("A"));
var down_key = keyboard_check(ord("S"));
var up_key = keyboard_check(ord("W"));
var shift_key = keyboard_check(vk_shift);
var attack_pressed = mouse_check_button_pressed(mb_left);

//var collide_x = false;
//var collide_y = false;


//get player speed
//var current_speed = shift_key ? move_speed / 2 : move_speed;
//xspd = (right_key - left_key) * current_speed;
//yspd = (down_key - up_key) * current_speed;


//pause
if instance_exists(obj_pauser)
	{
		xspd = 0;
		yspd = 0;
	}


// Handle attack trigger
if (attack_pressed && !is_attacking) {
    is_attacking = true;
    switch (face) {
        case RIGHT: sprite_index = spr_player_attack1_right; break;
        case LEFT: sprite_index = spr_player_attack1_left; break;
        case DOWN: sprite_index = spr_player_attack1_down; break;
        case UP: sprite_index = spr_player_attack1_up; break;
    }
    image_index = 0; // Start the attack animation from the beginning
}


//get player speed
var speed_modifier = is_attacking ? 0.5 : 1; // Half speed during attack
var current_speed = (shift_key ? move_speed / 2 : move_speed) * speed_modifier;
xspd = (right_key - left_key) * current_speed;
yspd = (down_key - up_key) * current_speed;


//set player facing down to start
mask_index = sprite[DOWN];


//detect if player hit wall
if place_meeting(x + xspd, y, obj_wall) == true
	{
		xspd = 0;
	}
if place_meeting(x, y + yspd, obj_wall) == true
	{
		yspd = 0;
	}


//calculate player movements (only if not attacking; during attack, keep attack sprite)
if (!is_attacking) {
    if (xspd != 0 || yspd != 0) {
        if (xspd > 0) {
            sprite_index = shift_key ? spr_player_walk_right : spr_player_run_right;
            face = RIGHT;
        } else if (xspd < 0) {
            sprite_index = shift_key ? spr_player_walk_left : spr_player_run_left;
            face = LEFT;
        } else if (yspd > 0) {
            sprite_index = shift_key ? spr_player_walk_down : spr_player_run_down;
            face = DOWN;
        } else if (yspd < 0) {
            sprite_index = shift_key ? spr_player_walk_up : spr_player_run_up;
            face = UP;
        }
    } else {
        if (face == DOWN)
            sprite_index = spr_player_idle_down;
        else if (face == LEFT) sprite_index = spr_player_idle_left;
        else if (face == RIGHT) sprite_index = spr_player_idle_right;
        else if (face == UP) sprite_index = spr_player_idle_up;
    }
} else {
    // During attack, check if animation is done
    if (image_index >= image_number - 1) {
        is_attacking = false;
        // Reset to idle sprite based on face (or movement if moving)
        if (xspd == 0 && yspd == 0) {
            switch (face) {
                case RIGHT: sprite_index = spr_player_idle_right; break;
                case LEFT: sprite_index = spr_player_idle_left; break;
                case DOWN: sprite_index = spr_player_idle_down; break;
                case UP: sprite_index = spr_player_idle_up; break;
            }
            image_index = 0;
        } else {
            // If moving after attack, switch to appropriate movement sprite
            if (xspd > 0) {
                sprite_index = shift_key ? spr_player_walk_right : spr_player_run_right;
            } else if (xspd < 0) {
                sprite_index = shift_key ? spr_player_walk_left : spr_player_run_left;
            } else if (yspd > 0) {
                sprite_index = shift_key ? spr_player_walk_down : spr_player_run_down;
            } else if (yspd < 0) {
                sprite_index = shift_key ? spr_player_walk_up : spr_player_run_up;
            }
        }
    }
}


//stop player if they hit wall
//if (collide_x) xspd = 0;
//if (collide_y) yspd = 0;


//move the player
x += xspd;
y += yspd;


//animate
if xspd == 0 && yspd == 0 && !is_attacking {
	image_index = 0;
}


//depth
depth = -bbox_bottom;
