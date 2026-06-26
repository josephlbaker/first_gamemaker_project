// ===== TIMERS =====
if (beast_invincible > 0) beast_invincible--;
if (attack_cooldown > 0)  attack_cooldown--;

// ===================================================================================================
// STATE MACHINE
// ===================================================================================================
switch (current_state) {

    case BeastState.PATROL:
        if (instance_exists(obj_pauser)) { change_state(BeastState.PAUSED); break; }

        // Acquire the player via line of sight.
        var seen = acquire_target();
        if (seen != noone) {
            current_target = seen;
            change_state(BeastState.CHASING);
            break;
        }

        // Roam: occasionally pause, occasionally pick a new heading.
        if (patrol_pause_timer > 0) {
            patrol_pause_timer--;
            desired_x = 0;
            desired_y = 0;
        } else {
            patrol_timer++;
            if (patrol_timer >= patrol_change_time) {
                patrol_timer = 0;
                patrol_change_time = 90 + random(120);
                // 1-in-3 chance to stand still for a beat instead of turning.
                if (irandom(2) == 0) {
                    patrol_pause_timer = 30 + random(60);
                } else {
                    patrol_dir = random(360);
                }
            }
            desired_x = lengthdir_x(patrol_speed, patrol_dir);
            desired_y = lengthdir_y(patrol_speed, patrol_dir);
        }
        break;

    case BeastState.CHASING:
        if (instance_exists(obj_pauser)) { change_state(BeastState.PAUSED); break; }

        if (current_target == noone || current_target.current_state == StrandedState.DEAD) {
            change_state(BeastState.PATROL);
            break;
        }

        var dist = point_distance(x, y, current_target.x, current_target.y);
        var has_los = (collision_line(x, y, current_target.x, current_target.y, obj_wall, false, true) == noone);

        if (dist <= detection_range && has_los) {
            // Target in sight: refresh last-known position.
            search_timer = 0;
            last_known_x = current_target.x;
            last_known_y = current_target.y;

            if (dist <= attack_range && attack_cooldown <= 0) {
                change_state(BeastState.ATTACKING);
                break;
            }
            var dir_to = point_direction(x, y, current_target.x, current_target.y);
            desired_x = lengthdir_x(chase_speed, dir_to);
            desired_y = lengthdir_y(chase_speed, dir_to);
        } else {
            // Lost sight: head to last known spot, then give up after a while.
            search_timer++;
            if (search_timer > max_search_time) {
                change_state(BeastState.PATROL);
                search_timer = 0;
                break;
            }
            var dir_last = point_direction(x, y, last_known_x, last_known_y);
            desired_x = lengthdir_x(chase_speed, dir_last);
            desired_y = lengthdir_y(chase_speed, dir_last);
        }
        break;

    case BeastState.ATTACKING:
        desired_x = 0;
        desired_y = 0;
        xspd = 0;
        yspd = 0;

        if (current_target == noone || current_target.current_state == StrandedState.DEAD) {
            change_state(BeastState.PATROL);
            break;
        }

        // Land the hit during the middle of the swing so the player can dodge the wind-up.
        if (image_index >= image_number * 0.5) perform_attack();

        // End of swing -> brief recovery.
        if (image_index >= image_number - 1) {
            change_state(BeastState.COOLDOWN);
        }
        break;

    case BeastState.COOLDOWN:
        desired_x = 0;
        desired_y = 0;

        if (current_target == noone || current_target.current_state == StrandedState.DEAD) {
            change_state(BeastState.PATROL);
            break;
        }

        // Once recovered a little, decide whether to keep chasing.
        if (attack_cooldown <= attack_cooldown_max - 25) {
            change_state(BeastState.CHASING);
        }
        break;

    case BeastState.HURT:
        // Apply and decay knockback.
        xspd = hurt_knockback_x;
        yspd = hurt_knockback_y;
        hurt_knockback_x *= 0.8;
        hurt_knockback_y *= 0.8;

        if (abs(hurt_knockback_x) < 0.15 && abs(hurt_knockback_y) < 0.15) {
            if (current_target != noone && current_target.current_state != StrandedState.DEAD) {
                change_state(BeastState.CHASING);
            } else {
                change_state(BeastState.PATROL);
            }
        }
        break;

    case BeastState.DEAD:
        death_timer++;
        xspd = 0;
        yspd = 0;
        // Hold the final death frame, then remove the instance.
        if (image_index >= image_number - 1) {
            image_speed = 0;
            image_index = image_number - 1;
            if (death_timer >= death_duration) instance_destroy();
        }
        exit;   // no movement / collision once dead

    case BeastState.PAUSED:
        xspd = 0;
        yspd = 0;
        if (!instance_exists(obj_pauser)) change_state(previous_state);
        exit;    // freeze animation too
}

// ===== STEERING (smooth accel toward desired velocity) =====
if (current_state != BeastState.ATTACKING &&
    current_state != BeastState.HURT &&
    current_state != BeastState.DEAD &&
    current_state != BeastState.PAUSED) {

    xspd += (desired_x - xspd) * steering_force;
    yspd += (desired_y - yspd) * steering_force;

    var spd = sqrt(xspd * xspd + yspd * yspd);
    if (spd > max_speed) {
        xspd = (xspd / spd) * max_speed;
        yspd = (yspd / spd) * max_speed;
    }
}

// ===== FACING (from movement) =====
if (current_state != BeastState.ATTACKING) {
    if (abs(xspd) > abs(yspd)) {
        if (xspd > 0)      face = RIGHT;
        else if (xspd < 0) face = LEFT;
    } else if (abs(yspd) > 0.1) {
        if (yspd > 0) face = DOWN;
        else          face = UP;
    }
}

// ===== SPRITE (skip while attacking/dead so those animations are not overwritten) =====
if (current_state != BeastState.ATTACKING && current_state != BeastState.DEAD) {
    update_movement_sprite();
}

// ===== WALL COLLISION =====
if (place_meeting(x + xspd, y, obj_wall)) {
    xspd = 0;
    if (current_state == BeastState.PATROL) patrol_dir = random(360);
}
if (place_meeting(x, y + yspd, obj_wall)) {
    yspd = 0;
    if (current_state == BeastState.PATROL) patrol_dir = random(360);
}

// ===== APPLY MOVEMENT =====
x += xspd;
y += yspd;

// ===== DEPTH (y-sort) =====
depth = -bbox_bottom;
