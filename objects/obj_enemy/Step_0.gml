// Don't do anything if game is paused
if (instance_exists(obj_pauser)) {
    exit;
}

// Find player
var player = instance_find(obj_player, 0);
var player_detected = false;
var dist_to_player = 9999;

// CRITICAL: Don't attack dead players!
if (player != noone && !player.is_dead) {
    dist_to_player = point_distance(x, y, player.x, player.y);
    player_detected = (dist_to_player <= detection_range);
} else {
    // Player is dead or doesn't exist - stop everything
    state = ENEMY_STATE.WANDERING;
    is_attacking = false;
    player_detected = false;
}

// Update attack cooldown
if (attack_cooldown > 0) {
    attack_cooldown--;
}

// State machine
switch (state) {
    case ENEMY_STATE.WANDERING:
        // Wandering behavior
        wander_timer++;
        
        if (wander_timer >= wander_change_time) {
            target_dir = random(360);
            wander_timer = 0;
            wander_change_time = 60 + random(120);
        }
        
        // Calculate desired movement
        desired_x = lengthdir_x(move_speed, target_dir);
        desired_y = lengthdir_y(move_speed, target_dir);
        
        // Check if player detected (and alive)
        if (player_detected && player != noone && !player.is_dead) {
            state = ENEMY_STATE.CHASING;
        }
        break;
        
    case ENEMY_STATE.CHASING:
        if (player != noone && player_detected && !player.is_dead) {
            // Check if close enough to attack
            if (dist_to_player <= attack_range && attack_cooldown <= 0) {
                state = ENEMY_STATE.ATTACKING;
                is_attacking = true;
                attack_cooldown = attack_cooldown_max;
            } else {
                // Chase the player
                var dir_to_player = point_direction(x, y, player.x, player.y);
                desired_x = lengthdir_x(chase_speed, dir_to_player);
                desired_y = lengthdir_y(chase_speed, dir_to_player);
            }
        } else {
            // Lost player or player is dead, go back to wandering
            state = ENEMY_STATE.WANDERING;
            wander_timer = 0;
        }
        break;
        
    case ENEMY_STATE.ATTACKING:
        // Stop moving during attack
        desired_x = 0;
        desired_y = 0;
        xspd = 0;
        yspd = 0;
        
        // CRITICAL: Stop attacking if player is dead
        if (player == noone || player.is_dead) {
            is_attacking = false;
            state = ENEMY_STATE.WANDERING;
            break;
        }
        
        // Check if attack animation is done
        if (image_index >= image_number - 1) {
            is_attacking = false;
            
            // Deal damage if player is still in range AND ALIVE
            if (player != noone && !player.is_dead && point_distance(x, y, player.x, player.y) <= attack_range) {
                // Check if player has invincibility frames
                if (player.invincible <= 0) {
                    player.player_health -= attack_damage;
                    
                    // Give player brief invincibility
                    player.invincible = player.max_invincible;
                    
                    // Debug: show damage dealt
                    show_debug_message("Player health: " + string(player.player_health));
                }
            }
            
            state = ENEMY_STATE.COOLDOWN;
        }
        break;
        
    case ENEMY_STATE.COOLDOWN:
        // Brief pause after attacking
        desired_x = 0;
        desired_y = 0;
        
        // CRITICAL: Stop cooldown if player is dead
        if (player == noone || player.is_dead) {
            state = ENEMY_STATE.WANDERING;
            break;
        }
        
        if (attack_cooldown <= attack_cooldown_max - 30) { // 0.5 second cooldown
            if (player_detected && dist_to_player > attack_range) {
                state = ENEMY_STATE.CHASING;
            } else if (!player_detected) {
                state = ENEMY_STATE.WANDERING;
            } else {
                state = ENEMY_STATE.CHASING;
            }
        }
        break;
}

// Apply steering behavior (smooth movement)
if (!is_attacking) {
    var steer_x = desired_x - xspd;
    var steer_y = desired_y - yspd;
    
    xspd += steer_x * steering_force;
    yspd += steer_y * steering_force;
    
    // Limit speed
    var current_speed = sqrt(xspd * xspd + yspd * yspd);
    if (current_speed > max_speed) {
        xspd = (xspd / current_speed) * max_speed;
        yspd = (yspd / current_speed) * max_speed;
    }
}

// Wall collision
if (place_meeting(x + xspd, y, obj_wall)) {
    xspd = 0;
    // Change direction when hitting wall during wandering
    if (state == ENEMY_STATE.WANDERING) {
        target_dir = random(360);
    }
}
if (place_meeting(x, y + yspd, obj_wall)) {
    yspd = 0;
    // Change direction when hitting wall during wandering  
    if (state == ENEMY_STATE.WANDERING) {
        target_dir = random(360);
    }
}

// Update facing direction and sprites
if (!is_attacking) {
    if (abs(xspd) > abs(yspd)) {
        if (xspd > 0) {
            face = RIGHT;
            sprite_index = spr_enemy_walk_right; // Replace with your enemy sprites
        } else if (xspd < 0) {
            face = LEFT;
            sprite_index = spr_enemy_walk_left;
        }
    } else if (abs(yspd) > 0.1) {
        if (yspd > 0) {
            face = DOWN;
            sprite_index = spr_enemy_walk_down;
        } else {
            face = UP;
            sprite_index = spr_enemy_walk_up;
        }
    } else {
        // Idle sprites
        switch (face) {
            case RIGHT: sprite_index = spr_enemy_idle_right; break;
            case LEFT: sprite_index = spr_enemy_idle_left; break;
            case DOWN: sprite_index = spr_enemy_idle_down; break;
            case UP: sprite_index = spr_enemy_idle_up; break;
        }
    }
} else {
    // Attack sprites - but only if player is alive
    if (player != noone && !player.is_dead) {
        switch (face) {
            case RIGHT: sprite_index = spr_player_attack1_right; break;
            case LEFT: sprite_index = spr_player_attack1_left; break;
            case DOWN: sprite_index = spr_player_attack1_down; break;
            case UP: sprite_index = spr_player_attack1_up; break;
        }
    } else {
        // Player is dead, switch to idle
        switch (face) {
            case RIGHT: sprite_index = spr_enemy_idle_right; break;
            case LEFT: sprite_index = spr_enemy_idle_left; break;
            case DOWN: sprite_index = spr_enemy_idle_down; break;
            case UP: sprite_index = spr_enemy_idle_up; break;
        }
    }
}

// Move the enemy
x += xspd;
y += yspd;

// Depth sorting
depth = -bbox_bottom;