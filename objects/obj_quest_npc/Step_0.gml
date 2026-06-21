// ===== UPDATE TIMERS =====
if (npc_invincible > 0) {
    npc_invincible--;
}

if (attack_cooldown > 0) {
    attack_cooldown--;
}

// ===== FACE TOWARD PLAYER WHEN FRIENDLY =====
if (!is_hostile && current_state == NpcState.IDLE) {
    var player = instance_find(obj_player, 0);
    if (player != noone) {
        var dist = point_distance(x, y, player.x, player.y);
        if (dist <= interact_radius * 2) {
            var dir = point_direction(x, y, player.x, player.y);
            if (abs(lengthdir_x(1, dir)) > abs(lengthdir_y(1, dir))) {
                face = (lengthdir_x(1, dir) > 0) ? RIGHT : LEFT;
            } else {
                face = (lengthdir_y(1, dir) > 0) ? DOWN : UP;
            }
        }
    }
}

// ===== STATE MACHINE =====
switch(current_state) {
    case NpcState.IDLE:
        if (instance_exists(obj_pauser)) {
            npc_change_state(NpcState.PAUSED);
            break;
        }

        if (npc_health <= 0) {
            npc_change_state(NpcState.DEAD);
            break;
        }

        xspd = 0;
        yspd = 0;
        break;

    case NpcState.TALKING:
        if (instance_exists(obj_pauser)) {
            npc_change_state(NpcState.PAUSED);
            break;
        }

        xspd = 0;
        yspd = 0;
        break;

    case NpcState.HOSTILE_IDLE:
        if (instance_exists(obj_pauser)) {
            npc_change_state(NpcState.PAUSED);
            break;
        }

        if (npc_health <= 0) {
            npc_change_state(NpcState.DEAD);
            break;
        }

        if (npc_detect_player()) {
            npc_change_state(NpcState.CHASING);
        } else {
            if (++wander_timer > 90) {
                wander_timer = 0;
                if (npc_detect_player()) {
                    npc_change_state(NpcState.CHASING);
                }
            }
        }
        break;

    case NpcState.CHASING:
        if (instance_exists(obj_pauser)) {
            npc_change_state(NpcState.PAUSED);
            break;
        }

        if (npc_health <= 0) {
            npc_change_state(NpcState.DEAD);
            break;
        }

        if (current_target == noone || current_target.current_state == PlayerState.DEAD) {
            npc_change_state(NpcState.HOSTILE_IDLE);
            break;
        }

        var dist_to_target = point_distance(x, y, current_target.x, current_target.y);

        if (dist_to_target > detection_range * 2) {
            search_timer++;
            if (search_timer > max_search_time) {
                npc_change_state(NpcState.HOSTILE_IDLE);
                search_timer = 0;
                break;
            }
            var dir_to_last = point_direction(x, y, last_known_x, last_known_y);
            desired_x = lengthdir_x(chase_speed, dir_to_last);
            desired_y = lengthdir_y(chase_speed, dir_to_last);
        } else {
            search_timer = 0;
            last_known_x = current_target.x;
            last_known_y = current_target.y;

            if (dist_to_target <= attack_range && attack_cooldown <= 0) {
                npc_change_state(NpcState.ATTACKING);
            } else {
                var dir_to_target = point_direction(x, y, current_target.x, current_target.y);
                desired_x = lengthdir_x(chase_speed, dir_to_target);
                desired_y = lengthdir_y(chase_speed, dir_to_target);
            }
        }
        break;

    case NpcState.ATTACKING:
        desired_x = 0;
        desired_y = 0;
        xspd = 0;
        yspd = 0;

        if (current_target == noone || current_target.current_state == PlayerState.DEAD) {
            npc_change_state(NpcState.HOSTILE_IDLE);
            break;
        }

        if (image_index >= image_number - 1) {
            npc_perform_attack();
            npc_change_state(NpcState.COOLDOWN);
        }
        break;

    case NpcState.COOLDOWN:
        desired_x = 0;
        desired_y = 0;

        if (current_target == noone || current_target.current_state == PlayerState.DEAD) {
            npc_change_state(NpcState.HOSTILE_IDLE);
            break;
        }

        if (attack_cooldown <= attack_cooldown_max - 30) {
            var dist = point_distance(x, y, current_target.x, current_target.y);

            if (dist <= detection_range) {
                npc_change_state(NpcState.CHASING);
            } else {
                npc_change_state(NpcState.HOSTILE_IDLE);
            }
        }
        break;

    case NpcState.HURT:
        xspd = hurt_knockback_x;
        yspd = hurt_knockback_y;

        hurt_knockback_x *= 0.8;
        hurt_knockback_y *= 0.8;

        if (abs(hurt_knockback_x) < 0.1 && abs(hurt_knockback_y) < 0.1) {
            if (npc_health <= 0) {
                npc_change_state(NpcState.DEAD);
            } else if (current_target != noone && current_target.current_state != PlayerState.DEAD) {
                npc_change_state(NpcState.CHASING);
            } else {
                npc_change_state(NpcState.HOSTILE_IDLE);
            }
        }
        break;

    case NpcState.DEAD:
        death_timer++;
        xspd = 0;
        yspd = 0;

        if (image_index >= image_number - 1) {
            image_speed = 0;
            image_index = image_number - 1;
        }
        exit;

    case NpcState.PAUSED:
        xspd = 0;
        yspd = 0;

        if (!instance_exists(obj_pauser)) {
            npc_change_state(previous_state);
        }
        break;
}

// ===== APPLY STEERING =====
if (current_state == NpcState.CHASING) {
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

// ===== UPDATE FACING DIRECTION (when hostile and moving) =====
if (is_hostile && (abs(xspd) > 0.1 || abs(yspd) > 0.1)) {
    if (abs(xspd) > abs(yspd)) {
        if (xspd > 0) face = RIGHT;
        else if (xspd < 0) face = LEFT;
    } else {
        if (yspd > 0) face = DOWN;
        else face = UP;
    }
}

// ===== COLLISION DETECTION =====
if (place_meeting(x + xspd, y, obj_wall)) {
    xspd = 0;
}
if (place_meeting(x, y + yspd, obj_wall)) {
    yspd = 0;
}

// ===== APPLY MOVEMENT =====
x += xspd;
y += yspd;

// ===== UPDATE DEPTH =====
depth = -bbox_bottom;
