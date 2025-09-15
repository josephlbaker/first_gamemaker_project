xspd = 0;
yspd = 0;
move_speed = 2;
dash_speed = 15;


player_health = 30;
max_health = 100;
invincible = 0;
max_invincible = 30; // Half second of invincibility
is_dead = false;
death_timer = 0;


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
dash_duration = .25 * game_get_speed(gamespeed_fps); // Duration of dash (.5)
cooldown_duration = .1 * game_get_speed(gamespeed_fps); // Cooldown between dashes (3)

// Dash direction storage for smooth movement
dash_dir_x = 0;
dash_dir_y = 0;