// ===== UPDATE TIMERS =====
if (law_invincible > 0) {
    law_invincible--;
}

if (attack_cooldown > 0) {
    attack_cooldown--;
}

if (combo_timer > 0) {
    combo_timer--;
} else {
    combo_stage = 1;
}

// ===== STATE MACHINE =====
switch(current_state) {
    case LawState.CHASING:
        if (instance_exists(obj_pauser)) {
            law_change_state(LawState.PAUSED);
            break;
        }

        if (law_health <= 0) {
            law_change_state(LawState.DEAD);
            break;
        }

        if (current_target == noone || current_target.current_state == PlayerState.DEAD) {
            xspd = 0;
            yspd = 0;
            break;
        }

        var dist_to_target = point_distance(x, y, current_target.x, current_target.y);

        if (dist_to_target <= attack_range && attack_cooldown <= 0) {
            law_change_state(LawState.ATTACKING);
        } else {
            var dir_to_target = point_direction(x, y, current_target.x, current_target.y);
            desired_x = lengthdir_x(chase_speed, dir_to_target);
            desired_y = lengthdir_y(chase_speed, dir_to_target);
        }
        break;

    case LawState.ATTACKING:
        desired_x = 0;
        desired_y = 0;
        xspd = 0;
        yspd = 0;

        if (current_target == noone || current_target.current_state == PlayerState.DEAD) {
            law_change_state(LawState.CHASING);
            break;
        }

        attack_anim_timer++;

        // Deal damage at the midpoint of the swing
        if (attack_anim_timer >= floor(attack_anim_duration / 2) && !damage_dealt_this_swing) {
            law_perform_attack();
            damage_dealt_this_swing = true;
        }

        // When swing finishes, decide: continue combo or cooldown
        if (attack_anim_timer >= attack_anim_duration) {
            var dist = point_distance(x, y, current_target.x, current_target.y);

            if (dist <= attack_range * 1.2 && combo_stage < combo_max) {
                combo_stage++;
                combo_timer = combo_window;
                attack_anim_timer = 0;
                damage_dealt_this_swing = false;
            } else {
                combo_stage = 1;
                combo_timer = 0;
                law_change_state(LawState.COOLDOWN);
            }
        }
        break;

    case LawState.COOLDOWN:
        desired_x = 0;
        desired_y = 0;

        if (current_target == noone || current_target.current_state == PlayerState.DEAD) {
            law_change_state(LawState.CHASING);
            break;
        }

        if (attack_cooldown <= attack_cooldown_max - 20) {
            law_change_state(LawState.CHASING);
        }
        break;

    case LawState.HURT:
        xspd = hurt_knockback_x;
        yspd = hurt_knockback_y;

        hurt_knockback_x *= 0.8;
        hurt_knockback_y *= 0.8;

        if (abs(hurt_knockback_x) < 0.1 && abs(hurt_knockback_y) < 0.1) {
            if (law_health <= 0) {
                law_change_state(LawState.DEAD);
            } else {
                law_change_state(LawState.CHASING);
            }
        }
        break;

    case LawState.DEAD:
        death_timer++;
        xspd = 0;
        yspd = 0;

        if (image_index >= image_number - 1) {
            image_speed = 0;
            image_index = image_number - 1;
        }
        exit;

    case LawState.PAUSED:
        xspd = 0;
        yspd = 0;

        if (!instance_exists(obj_pauser)) {
            law_change_state(previous_state);
        }
        break;
}

// ===== APPLY STEERING =====
if (current_state == LawState.CHASING) {
    var steer_x = desired_x - xspd;
    var steer_y = desired_y - yspd;

    xspd += steer_x * steering_force;
    yspd += steer_y * steering_force;

    var current_speed = sqrt(xspd * xspd + yspd * yspd);
    if (current_speed > max_speed) {
        xspd = (xspd / current_speed) * max_speed;
        yspd = (yspd / current_speed) * max_speed;
    }
}

// ===== UPDATE FACING DIRECTION =====
if (abs(xspd) > 0.1 || abs(yspd) > 0.1) {
    if (abs(xspd) > abs(yspd)) {
        if (xspd > 0) face = RIGHT;
        else if (xspd < 0) face = LEFT;
    } else {
        if (yspd > 0) face = DOWN;
        else face = UP;
    }
}

// ===== WALL COLLISION WITH SLIDE =====
if (place_meeting(x + xspd, y, obj_wall)) {
    // Try sliding vertically when blocked horizontally
    if (current_target != noone && !place_meeting(x, y + sign(current_target.y - y) * chase_speed, obj_wall)) {
        yspd = sign(current_target.y - y) * chase_speed;
    }
    xspd = 0;
    wall_stuck_timer++;
} else {
    wall_stuck_timer = 0;
}

if (place_meeting(x, y + yspd, obj_wall)) {
    // Try sliding horizontally when blocked vertically
    if (current_target != noone && !place_meeting(x + sign(current_target.x - x) * chase_speed, y, obj_wall)) {
        xspd = sign(current_target.x - x) * chase_speed;
    }
    yspd = 0;
}

// If stuck on a wall for too long, try a random perpendicular direction
if (wall_stuck_timer > 30) {
    wall_stuck_timer = 0;
    wall_unstick_dir = choose(-1, 1);
    if (current_target != noone) {
        var dir_to_player = point_direction(x, y, current_target.x, current_target.y);
        var perp_dir = dir_to_player + (90 * wall_unstick_dir);
        xspd = lengthdir_x(chase_speed, perp_dir);
        yspd = lengthdir_y(chase_speed, perp_dir);
    }
}

// ===== APPLY MOVEMENT =====
x += xspd;
y += yspd;

// ===== UPDATE DEPTH =====
depth = -bbox_bottom;
