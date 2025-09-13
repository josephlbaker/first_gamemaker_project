xspd = 0;
yspd = 0;
move_speed = 2;
dash_speed = 25;

sprite[RIGHT] = spr_player_idle_right;
sprite[UP] = spr_player_idle_up;
sprite[LEFT] = spr_player_idle_left;
sprite[DOWN] = spr_player_idle_down;
face = DOWN;


is_attacking = false;
is_walking = false;
is_dashing = false;


dash_timer = 0;
cooldown_timer = 0;
dash_duration = .1 * game_get_speed(gamespeed_fps); // Adjust duration as needed (0.5 seconds)
cooldown_duration = .5 * game_get_speed(gamespeed_fps); // 3 seconds cooldown