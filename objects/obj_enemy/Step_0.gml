// ===== UPDATE TIMERS =====
if (enemy_invincible > 0) {
    enemy_invincible--;
}

if (attack_cooldown > 0) {
    attack_cooldown--;
}

// ===== STATE MACHINE =====
switch(current_state) {
    case EnemyState.IDLE:
        // Check for pause
        if (instance_exists(obj_pauser)) {
            change_state(EnemyState.PAUSED);
            break;
        }
        
        // Check for death
        if (enemy_health <= 0) {
            change_state(EnemyState.DEAD);
            break;
        }
        
        // Look for player
        if (detect_player()) {
            change_state(EnemyState.CHASING);
        } else {
            // Start wandering after a moment
            if (++wander_timer > 60) {
                change_state(EnemyState.WANDERING);
            }
        }
        break;
        
    case EnemyState.WANDERING:
        // Check for pause
        if (instance_exists(obj_pauser)) {
            change_state(EnemyState.PAUSED);
            break;
        }
        
        // Check for death
        if (enemy_health <= 0) {
            change_state(EnemyState.DEAD);
            break;
        }
        
        // Look for player
        if (detect_player()) {
            change_state(EnemyState.CHASING);
            break;
        }
        
        // Wander behavior
        wander_timer++;
        if (wander_timer >= wander_change_time) {
            target_dir = random(360);
            wander_timer = 0;
            wander_change_time = 60 + random(120);
        }
        
        desired_x = lengthdir_x(move_speed, target_dir);
        desired_y = lengthdir_y(move_speed, target_dir);
        break;
        
    case EnemyState.CHASING:
        // Check for pause
        if (instance_exists(obj_pauser)) {
            change_state(EnemyState.PAUSED);
            break;
        }
        
        // Check for death
        if (enemy_health <= 0) {
            change_state(EnemyState.DEAD);
            break;
        }
        
        // Verify target is still valid
        if (current_target == noone || current_target.current_state == PlayerState.DEAD) {
            change_state(EnemyState.WANDERING);
            break;
        }
        
        var dist_to_target = point_distance(x, y, current_target.x, current_target.y);
        
        // Check if we lost the target
        if (dist_to_target > detection_range * 1.5) {
            search_timer++;
            if (search_timer > max_search_time) {
                change_state(EnemyState.WANDERING);
                search_timer = 0;
            }
            // Move to last known position
            var dir_to_last = point_direction(x, y, last_known_x, last_known_y);
            desired_x = lengthdir_x(chase_speed, dir_to_last);
            desired_y = lengthdir_y(chase_speed, dir_to_last);
        } else {
            search_timer = 0;
            last_known_x = current_target.x;
            last_known_y = current_target.y;
            
            // Check if close enough to attack
            if (dist_to_target <= attack_range && attack_cooldown <= 0) {
                change_state(EnemyState.ATTACKING);
            } else {
                // Chase the target
                var dir_to_target = point_direction(x, y, current_target.x, current_target.y);
                desired_x = lengthdir_x(chase_speed, dir_to_target);
                desired_y = lengthdir_y(chase_speed, dir_to_target);
            }
        }
        break;
        
    case EnemyState.ATTACKING:
        // Stop movement during attack
        desired_x = 0;
        desired_y = 0;
        xspd = 0;
        yspd = 0;
        
        // Check if target died or left
        if (current_target == noone || current_target.current_state == PlayerState.DEAD) {
            change_state(EnemyState.WANDERING);
            break;
        }
        
        // Check if attack animation is done
        if (image_index >= image_number - 1) {
            perform_attack();
            change_state(EnemyState.COOLDOWN);
        }
        break;
        
    case EnemyState.COOLDOWN:
        // Brief pause after attacking
        desired_x = 0;
        desired_y = 0;
        
        // Check if target died
        if (current_target == noone || current_target.current_state == PlayerState.DEAD) {
            change_state(EnemyState.WANDERING);
            break;
        }
        
        // Return to appropriate state after cooldown
        if (attack_cooldown <= attack_cooldown_max - 30) {
            var dist = point_distance(x, y, current_target.x, current_target.y);
            
            if (dist <= detection_range) {
                change_state(EnemyState.CHASING);
            } else {
                change_state(EnemyState.WANDERING);
            }
        }
        break;
        
    case EnemyState.HURT:
        // Apply knockback
        xspd = hurt_knockback_x;
        yspd = hurt_knockback_y;
        
        // Reduce knockback over time
        hurt_knockback_x *= 0.8;
        hurt_knockback_y *= 0.8;
        
        // Return to previous state when knockback is done
        if (abs(hurt_knockback_x) < 0.1 && abs(hurt_knockback_y) < 0.1) {
            if (current_target != noone && current_target.current_state != PlayerState.DEAD) {
                change_state(EnemyState.CHASING);
            } else {
                change_state(EnemyState.WANDERING);
            }
        }
        break;
        
    case EnemyState.DEAD:
        death_timer++;
        xspd = 0;
        yspd = 0;
        
        // Keep on last frame of death animation
        if (image_index >= image_number - 1) {
            image_speed = 0;
            image_index = image_number - 1;
        }
        exit; // No further processing when dead
        
    case EnemyState.PAUSED:
        xspd = 0;
        yspd = 0;
        
        // Check if unpaused
        if (!instance_exists(obj_pauser)) {
            change_state(previous_state);
        }
        break;
}

// ===== APPLY STEERING (for smooth movement) =====
if (current_state != EnemyState.ATTACKING && 
    current_state != EnemyState.DEAD && 
    current_state != EnemyState.HURT &&
    current_state != EnemyState.PAUSED) {
    
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

// ===== UPDATE FACING DIRECTION =====
if (abs(xspd) > abs(yspd)) {
    if (xspd > 0) face = RIGHT;
    else if (xspd < 0) face = LEFT;
} else if (abs(yspd) > 0.1) {
    if (yspd > 0) face = DOWN;
    else face = UP;
}

// ===== UPDATE SPRITE =====
if (current_state != EnemyState.ATTACKING && current_state != EnemyState.DEAD) {
    update_movement_sprite();
}

// ===== COLLISION DETECTION =====
if (place_meeting(x + xspd, y, obj_wall)) {
    xspd = 0;
    if (current_state == EnemyState.WANDERING) {
        target_dir = random(360);
    }
}
if (place_meeting(x, y + yspd, obj_wall)) {
    yspd = 0;
    if (current_state == EnemyState.WANDERING) {
        target_dir = random(360);
    }
}

// ===== APPLY MOVEMENT =====
x += xspd;
y += yspd;

// ===== UPDATE DEPTH =====
depth = -bbox_bottom;