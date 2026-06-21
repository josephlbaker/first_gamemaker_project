// ===== NPC STATE ENUM =====
enum NpcState {
    IDLE,
    TALKING,
    HOSTILE_IDLE,
    CHASING,
    ATTACKING,
    COOLDOWN,
    HURT,
    DEAD,
    PAUSED
}

current_state = NpcState.IDLE;
previous_state = NpcState.IDLE;

// ===== DIALOG SYSTEM =====
dialog_active = false;
dialog_index = 0;
dialog_lines = [
    "Greetings, traveler. You look weary.",
    "I've been waiting for someone brave enough to help.",
    "There are monsters lurking in the dungeon nearby...",
    "Clear them out, and I'll reward you handsomely.",
    "Good luck. You'll need it."
];

provoked_lines = [
    "You dare raise your blade against me?!",
    "Then you choose death!"
];
provoked_line_index = 0;
interact_radius = 32;

// ===== HOSTILE FLAG =====
is_hostile = false;
warning_given = false;

// ===== MOVEMENT VARIABLES =====
xspd = 0;
yspd = 0;
move_speed = 1;
chase_speed = 2.5;
max_speed = 2;

// ===== STEERING BEHAVIOR =====
desired_x = 0;
desired_y = 0;
steering_force = 0.15;

// ===== WANDER BEHAVIOR =====
target_dir = random(360);
wander_timer = 0;
wander_change_time = 120 + random(180);

// ===== DETECTION & TARGETING =====
detection_range = 180;
current_target = noone;
last_known_x = 0;
last_known_y = 0;
search_timer = 0;
max_search_time = 180;

// ===== COMBAT VARIABLES =====
attack_range = 48;
attack_damage = 15;
attack_cooldown = 0;
attack_cooldown_max = 90;
hitbox_width = 32;
hitbox_height = 16;

// ===== HEALTH VARIABLES =====
npc_health = 80;
max_npc_health = 80;
npc_invincible = 0;
max_npc_invincible = 20;
hurt_knockback_speed = 4;
hurt_knockback_x = 0;
hurt_knockback_y = 0;

// ===== DEATH VARIABLES =====
death_timer = 0;
death_duration = 60;

// ===== SPRITE MANAGEMENT =====
face = DOWN;
image_speed = 0.15;

// ===== HELPER FUNCTIONS =====
function npc_change_state(new_state) {
    if (current_state == new_state) return;

    previous_state = current_state;
    current_state = new_state;

    switch(new_state) {
        case NpcState.IDLE:
            xspd = 0;
            yspd = 0;
            desired_x = 0;
            desired_y = 0;
            break;

        case NpcState.TALKING:
            xspd = 0;
            yspd = 0;
            dialog_active = true;
            dialog_index = 0;
            break;

        case NpcState.HOSTILE_IDLE:
            xspd = 0;
            yspd = 0;
            desired_x = 0;
            desired_y = 0;
            is_hostile = true;
            break;

        case NpcState.CHASING:
            if (current_target != noone) {
                last_known_x = current_target.x;
                last_known_y = current_target.y;
            }
            break;

        case NpcState.ATTACKING:
            image_index = 0;
            attack_cooldown = attack_cooldown_max;
            xspd = 0;
            yspd = 0;
            break;

        case NpcState.HURT:
            if (current_target != noone) {
                var knock_dir = point_direction(current_target.x, current_target.y, x, y);
                hurt_knockback_x = lengthdir_x(hurt_knockback_speed, knock_dir);
                hurt_knockback_y = lengthdir_y(hurt_knockback_speed, knock_dir);
            }
            npc_invincible = max_npc_invincible;
            break;

        case NpcState.DEAD:
            death_timer = 0;
            image_index = 0;
            xspd = 0;
            yspd = 0;
            alarm[0] = death_duration;
            break;

        case NpcState.PAUSED:
            xspd = 0;
            yspd = 0;
            desired_x = 0;
            desired_y = 0;
            break;
    }
}

function start_dialog() {
    if (is_hostile || current_state == NpcState.DEAD) return;
    npc_change_state(NpcState.TALKING);
}

function advance_dialog() {
    if (!dialog_active) return;

    dialog_index++;

    if (dialog_index >= array_length(dialog_lines)) {
        dialog_active = false;
        dialog_index = 0;
        npc_change_state(NpcState.IDLE);
    }
}

function become_hostile() {
    if (is_hostile) return;

    is_hostile = true;
    dialog_active = true;
    dialog_lines = provoked_lines;
    dialog_index = 0;
    warning_given = true;
    current_target = instance_find(obj_player, 0);
    npc_change_state(NpcState.TALKING);
}

function finish_provoked_dialog() {
    dialog_active = false;
    npc_change_state(NpcState.CHASING);
}

function npc_detect_player() {
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

function npc_perform_attack() {
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
            current_target.player_health -= attack_damage;
            current_target.invincible = current_target.max_invincible;
        }
    }
}
