// ===== ENEMY STATE ENUM =====
enum EnemyState {
    IDLE,
    WANDERING,
    CHASING,
    ATTACKING,
    COOLDOWN,
    HURT,
    DEAD,
    PAUSED
}

// Initialize state
current_state = EnemyState.WANDERING;
previous_state = EnemyState.WANDERING;

// ===== MOVEMENT VARIABLES =====
xspd = 0;
yspd = 0;
move_speed = 1;
chase_speed = 2;
max_speed = 1.5;

// ===== STEERING BEHAVIOR =====
desired_x = 0;
desired_y = 0;
steering_force = 0.1;

// ===== WANDER BEHAVIOR =====
target_dir = random(360);
wander_timer = 0;
wander_change_time = 60 + random(120);

// ===== DETECTION & TARGETING =====
detection_range = 150;
current_target = noone;
last_known_x = 0;
last_known_y = 0;
search_timer = 0;
max_search_time = 180; // 3 seconds to search for lost player

// ===== COMBAT VARIABLES =====
attack_range = 64;
attack_damage = 10;
attack_cooldown = 0;
attack_cooldown_max = 120;
hitbox_width = 32;
hitbox_height = 16;

// ===== HEALTH VARIABLES =====
enemy_health = 50;
max_enemy_health = 50;
enemy_invincible = 0;
max_enemy_invincible = 20;
hurt_knockback_speed = 5;
hurt_knockback_x = 0;
hurt_knockback_y = 0;

// ===== DEATH VARIABLES =====
death_timer = 0;
death_duration = 60;

// ===== SPRITE MANAGEMENT =====
sprite[RIGHT] = spr_enemy_idle_right;
sprite[UP] = spr_enemy_idle_up;
sprite[LEFT] = spr_enemy_idle_left;
sprite[DOWN] = spr_enemy_idle_down;
face = DOWN;

// ===== HELPER FUNCTIONS =====
function change_state(new_state) {
    // Don't change if already in this state
    if (current_state == new_state) return;
    
    // Store previous state
    previous_state = current_state;
    current_state = new_state;
    
    // State entry logic
    switch(new_state) {
        case EnemyState.IDLE:
            xspd = 0;
            yspd = 0;
            desired_x = 0;
            desired_y = 0;
            break;
            
        case EnemyState.WANDERING:
            wander_timer = 0;
            target_dir = random(360);
            current_target = noone;
            break;
            
        case EnemyState.CHASING:
            // Store target's last position
            if (current_target != noone) {
                last_known_x = current_target.x;
                last_known_y = current_target.y;
            }
            break;
            
        case EnemyState.ATTACKING:
            // Set attack sprite
            update_attack_sprite();
            image_index = 0;
            attack_cooldown = attack_cooldown_max;
            break;
            
        case EnemyState.HURT:
            // Calculate knockback direction
            if (current_target != noone) {
                var knock_dir = point_direction(current_target.x, current_target.y, x, y);
                hurt_knockback_x = lengthdir_x(hurt_knockback_speed, knock_dir);
                hurt_knockback_y = lengthdir_y(hurt_knockback_speed, knock_dir);
            }
            enemy_invincible = max_enemy_invincible;
            break;
            
        case EnemyState.DEAD:
            death_timer = 0;
            sprite_index = spr_player_death_down; // Use enemy death sprite
            image_index = 0;
            xspd = 0;
            yspd = 0;
            show_debug_message("Enemy died!");
            alarm[0] = death_duration;
            break;
            
        case EnemyState.PAUSED:
            xspd = 0;
            yspd = 0;
            desired_x = 0;
            desired_y = 0;
            break;
    }
}

function update_attack_sprite() {
    switch (face) {
        case RIGHT: sprite_index = spr_player_attack1_right; break;
        case LEFT: sprite_index = spr_player_attack1_left; break;
        case DOWN: sprite_index = spr_player_attack1_down; break;
        case UP: sprite_index = spr_player_attack1_up; break;
    }
}

function update_movement_sprite() {
    var moving = (abs(xspd) > 0.1 || abs(yspd) > 0.1);
    
    if (moving) {
        switch (face) {
            case RIGHT: sprite_index = spr_enemy_walk_right; break;
            case LEFT: sprite_index = spr_enemy_walk_left; break;
            case DOWN: sprite_index = spr_enemy_walk_down; break;
            case UP: sprite_index = spr_enemy_walk_up; break;
        }
    } else {
        switch (face) {
            case RIGHT: sprite_index = spr_enemy_idle_right; break;
            case LEFT: sprite_index = spr_enemy_idle_left; break;
            case DOWN: sprite_index = spr_enemy_idle_down; break;
            case UP: sprite_index = spr_enemy_idle_up; break;
        }
    }
}

function detect_player() {
    var player = instance_find(obj_player, 0);
    
    if (player != noone && player.current_state != PlayerState.DEAD) {
        var dist = point_distance(x, y, player.x, player.y);
        if (dist <= detection_range) {
            current_target = player;
            return true;
        }
    }
    
    return false;
}


function perform_attack() {
    if (current_target != noone && current_target.current_state != PlayerState.DEAD) {
        // Calculate hitbox dimensions based on facing direction
        var attack_left, attack_top, attack_right, attack_bottom;
        
        switch (face) {
            case RIGHT:
                attack_left = x - hitbox_height/2;
                attack_top = y - hitbox_width/2;
                attack_right = x + hitbox_height + hitbox_height;
                attack_bottom = y + hitbox_width/2;
                break;
            case LEFT:
                attack_left = x - hitbox_height - hitbox_height;
                attack_top = y - hitbox_width/2;
                attack_right = x + hitbox_height/2;
                attack_bottom = y + hitbox_width/2;
                break;
            case DOWN:
                attack_left = x - hitbox_width/2;
                attack_top = y - hitbox_height/2;
                attack_right = x + hitbox_width/2;
                attack_bottom = y + hitbox_height + hitbox_height;
                break;
            case UP:
                attack_left = x - hitbox_width/2;
                attack_top = y - hitbox_height - hitbox_height;
                attack_right = x + hitbox_width/2;
                attack_bottom = y + hitbox_height/2;
                break;
        }
        
        // Check if attack hitbox overlaps with player sprite bounds
        var player_left = current_target.bbox_left;
        var player_top = current_target.bbox_top;
        var player_right = current_target.bbox_right;
        var player_bottom = current_target.bbox_bottom;
        
        // Rectangle overlap check between attack hitbox and player sprite
        if (attack_right >= player_left && attack_left <= player_right &&
            attack_bottom >= player_top && attack_top <= player_bottom) {
            
            if (current_target.invincible <= 0) {
                current_target.player_health -= attack_damage;
                current_target.invincible = current_target.max_invincible;
                show_debug_message("Player health: " + string(current_target.player_health));
            }
        }
    }
}