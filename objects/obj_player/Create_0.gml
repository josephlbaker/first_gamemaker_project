// ===== PLAYER STATE ENUM =====
enum PlayerState {
    IDLE,
    MOVING,
    ATTACKING,
    DASHING,
    DEAD,
    PAUSED
}

// Initialize state
current_state = PlayerState.IDLE;
previous_state = PlayerState.IDLE;

// ===== MOVEMENT VARIABLES =====
xspd = 0;
yspd = 0;
move_speed = 2;
is_walking = false;

// ===== DASH VARIABLES =====
dash_speed = 25;
dash_timer = 0;
cooldown_timer = 0;
dash_duration = .25 * game_get_speed(gamespeed_fps);
cooldown_duration = .1 * game_get_speed(gamespeed_fps);
dash_dir_x = 0;
dash_dir_y = 0;

// ===== HEALTH VARIABLES =====
player_health = 100;
max_health = 100;
invincible = 0;
max_invincible = 30;

// ===== DEATH VARIABLES =====
death_timer = 0;

// ===== COMBAT VARIABLES =====
attack_damage = 25;
attack_reach = 64;

// ===== SPRITE MANAGEMENT =====
sprite[RIGHT] = spr_player_idle_right;
sprite[UP] = spr_player_idle_up;
sprite[LEFT] = spr_player_idle_left;
sprite[DOWN] = spr_player_idle_down;
face = DOWN;

// ===== HELPER FUNCTIONS =====
// ===== HELPER FUNCTIONS IN CREATE EVENT =====
function change_state(new_state) {
    // Store previous state before changing
    previous_state = current_state;
    current_state = new_state;
    
    // State entry logic
    switch(new_state) {
        case PlayerState.DEAD:
            death_timer = 0;
            // Set death sprite
            sprite_index = spr_player_death_down;
            image_index = 0;
            xspd = 0;
            yspd = 0;
            show_debug_message("Player died! Health: " + string(player_health));
            break;
            
        case PlayerState.ATTACKING:
            // Set attack sprite based on facing
            switch (face) {
                case RIGHT: sprite_index = spr_player_attack1_right; break;
                case LEFT: sprite_index = spr_player_attack1_left; break;
                case DOWN: sprite_index = spr_player_attack1_down; break;
                case UP: sprite_index = spr_player_attack1_up; break;
            }
            image_index = 0;
            perform_attack();
            break;
            
        case PlayerState.DASHING:
            dash_timer = dash_duration;
            
            // Get current input for dash direction
            var right = keyboard_check(ord("D"));
            var left = keyboard_check(ord("A"));
            var down = keyboard_check(ord("S"));
            var up = keyboard_check(ord("W"));
            
            // Store dash direction
            dash_dir_x = right - left;
            dash_dir_y = down - up;
            
            // If no input, dash in facing direction
            if (dash_dir_x == 0 && dash_dir_y == 0) {
                switch (face) {
                    case RIGHT: dash_dir_x = 1; break;
                    case LEFT: dash_dir_x = -1; break;
                    case DOWN: dash_dir_y = 1; break;
                    case UP: dash_dir_y = -1; break;
                }
            }
            break;
    }
}

function perform_attack() {
    var enemies = ds_list_create();
    collision_circle_list(x, y, attack_reach, obj_enemy, false, true, enemies, false);
    
    for (var i = 0; i < ds_list_size(enemies); i++) {
        var enemy = ds_list_find_value(enemies, i);
        
        var enemy_dir = point_direction(x, y, enemy.x, enemy.y);
        var attack_dir = 0;
        
        switch (face) {
            case RIGHT: attack_dir = 0; break;
            case DOWN: attack_dir = 270; break;
            case LEFT: attack_dir = 180; break;
            case UP: attack_dir = 90; break;
        }
        
        var dir_diff = abs(angle_difference(enemy_dir, attack_dir));
        
        if (dir_diff <= 45 && enemy.enemy_invincible <= 0) {
            enemy.enemy_health -= attack_damage;
            enemy.enemy_invincible = enemy.max_enemy_invincible;
            show_debug_message("Hit enemy! Enemy health: " + string(enemy.enemy_health));
        }
    }
    
    ds_list_destroy(enemies);
}