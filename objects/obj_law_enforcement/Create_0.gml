// ===== LAW ENFORCEMENT STATE ENUM =====
enum LawState {
    CHASING,
    ATTACKING,
    COOLDOWN,
    HURT,
    DEAD,
    PAUSED
}

current_state = LawState.CHASING;
previous_state = LawState.CHASING;

// ===== MOVEMENT VARIABLES =====
xspd = 0;
yspd = 0;
chase_speed = 2.2;
max_speed = 2.2;

// ===== STEERING BEHAVIOR =====
desired_x = 0;
desired_y = 0;
steering_force = 0.12;

// ===== TARGETING =====
current_target = noone;
wall_stuck_timer = 0;
wall_unstick_dir = 0;

// ===== COMBAT VARIABLES =====
attack_range = 48;
attack_damage = 20;
attack_cooldown = 0;
attack_cooldown_max = 60;
hitbox_width = 42;
hitbox_height = 16;

// Combo attack system (mirrors the player)
combo_stage = 1;
combo_max = 3;
combo_timer = 0;
combo_window = 25;
attack_anim_timer = 0;
attack_anim_duration = 12;
damage_dealt_this_swing = false;

// ===== HEALTH VARIABLES =====
law_health = 60;
max_law_health = 60;
law_invincible = 0;
max_law_invincible = 20;
hurt_knockback_speed = 5;
hurt_knockback_x = 0;
hurt_knockback_y = 0;

// ===== DEATH VARIABLES =====
death_timer = 0;
death_duration = 60;

// ===== SPRITE MANAGEMENT =====
face = DOWN;
image_speed = 0.15;

// ===== ACQUIRE TARGET ON SPAWN =====
current_target = instance_find(obj_player, 0);

// ===== HELPER FUNCTIONS =====
function law_change_state(new_state) {
    if (current_state == new_state) return;

    previous_state = current_state;
    current_state = new_state;

    switch(new_state) {
        case LawState.CHASING:
            break;

        case LawState.ATTACKING:
            attack_anim_timer = 0;
            damage_dealt_this_swing = false;
            xspd = 0;
            yspd = 0;
            break;

        case LawState.COOLDOWN:
            attack_cooldown = attack_cooldown_max;
            break;

        case LawState.HURT:
            if (current_target != noone) {
                var knock_dir = point_direction(current_target.x, current_target.y, x, y);
                hurt_knockback_x = lengthdir_x(hurt_knockback_speed, knock_dir);
                hurt_knockback_y = lengthdir_y(hurt_knockback_speed, knock_dir);
            }
            law_invincible = max_law_invincible;
            break;

        case LawState.DEAD:
            death_timer = 0;
            image_index = 0;
            xspd = 0;
            yspd = 0;
            alarm[0] = death_duration;
            break;

        case LawState.PAUSED:
            xspd = 0;
            yspd = 0;
            desired_x = 0;
            desired_y = 0;
            break;
    }
}

function law_perform_attack() {
    if (current_target == noone || current_target.current_state == PlayerState.DEAD) return;

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

    var player_left = current_target.bbox_left;
    var player_top = current_target.bbox_top;
    var player_right = current_target.bbox_right;
    var player_bottom = current_target.bbox_bottom;

    if (attack_right >= player_left && attack_left <= player_right &&
        attack_bottom >= player_top && attack_top <= player_bottom) {

        if (current_target.invincible <= 0) {
            var dmg = attack_damage;
            if (combo_stage == 3) dmg = floor(attack_damage * 1.5);
            current_target.player_health -= dmg;
            current_target.invincible = current_target.max_invincible;
        }
    }
}
