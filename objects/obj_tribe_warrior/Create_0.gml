// ===================================================================================================
// TRIBE WARRIOR  -  Patrolling melee enemy for the Stranded game
// ===================================================================================================
// Behaviour: patrols (roams) until it gets line-of-sight to obj_player_stranded, then walks toward
// the player and attacks in melee. Has its own health pool and takes damage via take_hit().
//
// Sprites are one-per-animation with three art directions (down / up / lr). lr faces RIGHT by
// default and is flipped (image_xscale = -1) for LEFT. Sprites now use a center-middle origin, so
// x/y is the body centre and flipping mirrors in place.
//
// AVAILABLE ANIMATIONS (only these exist):
//   idle  : down / up / lr        walk : down / up / lr
//   attack: down / up / lr        death (single)
// ===================================================================================================

// ===== STATE ENUM =====
enum TribeState {
    PATROL,
    CHASING,
    ATTACKING,
    COOLDOWN,
    HURT,
    DEAD,
    PAUSED
}

current_state  = TribeState.PATROL;
previous_state = TribeState.PATROL;

// ===== MOVEMENT VARIABLES =====
xspd        = 0;
yspd        = 0;
patrol_speed = 0.8;          // slow roam
chase_speed  = 1.8;          // walk toward player
max_speed    = 2.0;
face         = DOWN;

// ===== STEERING (smooth acceleration, mirrors obj_enemy) =====
desired_x      = 0;
desired_y      = 0;
steering_force = 0.12;

// ===== PATROL BEHAVIOR =====
patrol_dir         = random(360);
patrol_timer       = 0;
patrol_change_time = 90 + random(120);
patrol_pause_timer = 0;       // occasional standing pauses while patrolling

// ===== DETECTION & TARGETING =====
detection_range = 200;        // how far it can notice the player
attack_range    = 40;         // how close before it swings
current_target  = noone;
last_known_x    = 0;
last_known_y    = 0;
search_timer    = 0;
max_search_time = 150;        // give up the chase after losing sight this long

// ===== COMBAT VARIABLES =====
attack_damage      = 12;
attack_cooldown    = 0;
attack_cooldown_max = 100;
hitbox_width       = 34;      // thickness perpendicular to facing
hitbox_height      = 16;
attack_reach       = 34;      // how far the hitbox extends in front
attack_landed      = false;   // ensures one connect per swing

// ===== HEALTH VARIABLES (own pool) =====
warrior_health     = 120;
max_warrior_health = 120;
warrior_invincible = 0;       // brief i-frames after being hit (also drives hurt flash)
max_warrior_invincible = 18;
hurt_knockback_speed = 5;
hurt_knockback_x   = 0;
hurt_knockback_y   = 0;

// ===== DEATH VARIABLES =====
death_timer    = 0;
death_duration = 45;          // frames to linger on the final death frame before vanishing

// ===== ANIMATION =====
image_speed = 1;              // use each sprite's own playback speed
mask_index  = spr_tribe_warrior_idle_down;   // stable collision mask across animations

// ===================================================================================================
// HELPER FUNCTIONS
// ===================================================================================================

/// Pick the walk/idle sprite for the current facing and apply the left/right flip.
function update_movement_sprite() {
    var moving = (abs(xspd) > 0.1 || abs(yspd) > 0.1);
    if (moving) {
        switch (face) {
            case UP:   sprite_index = spr_tribe_warrior_walk_up;   break;
            case DOWN: sprite_index = spr_tribe_warrior_walk_down; break;
            default:   sprite_index = spr_tribe_warrior_walk_lr;   break;
        }
    } else {
        switch (face) {
            case UP:   sprite_index = spr_tribe_warrior_idle_up;   break;
            case DOWN: sprite_index = spr_tribe_warrior_idle_down; break;
            default:   sprite_index = spr_tribe_warrior_idle_lr;   break;
        }
    }
    image_xscale = (face == LEFT) ? -1 : 1;
}

/// Pick the attack sprite for the current facing and apply the left/right flip.
function update_attack_sprite() {
    switch (face) {
        case UP:   sprite_index = spr_tribe_warrior_attack_up;   break;
        case DOWN: sprite_index = spr_tribe_warrior_attack_down; break;
        default:   sprite_index = spr_tribe_warrior_attack_lr;   break;
    }
    image_xscale = (face == LEFT) ? -1 : 1;
}

/// Face toward a point (used when locking on to the player).
function face_point(_tx, _ty) {
    var dir = point_direction(x, y, _tx, _ty);
    if (dir > 45 && dir <= 135)       face = UP;
    else if (dir > 135 && dir <= 225) face = LEFT;
    else if (dir > 225 && dir <= 315) face = DOWN;
    else                              face = RIGHT;
}

/// Return the player instance if it is alive, in range, and in clear line of sight; else noone.
function acquire_target() {
    var player = instance_find(obj_player_stranded, 0);
    if (player == noone) return noone;
    if (player.current_state == StrandedState.DEAD) return noone;
    if (point_distance(x, y, player.x, player.y) > detection_range) return noone;
    // Line of sight: a wall between us blocks detection.
    if (collision_line(x, y, player.x, player.y, obj_wall, false, true) != noone) return noone;
    return player;
}

/// State entry logic.
function change_state(new_state) {
    if (current_state == new_state) return;
    previous_state = current_state;
    current_state  = new_state;

    switch (new_state) {
        case TribeState.PATROL:
            current_target = noone;
            patrol_timer = 0;
            patrol_dir = random(360);
            break;

        case TribeState.CHASING:
            if (current_target != noone) {
                last_known_x = current_target.x;
                last_known_y = current_target.y;
            }
            break;

        case TribeState.ATTACKING:
            xspd = 0;
            yspd = 0;
            desired_x = 0;
            desired_y = 0;
            attack_landed = false;
            attack_cooldown = attack_cooldown_max;
            if (current_target != noone) face_point(current_target.x, current_target.y);
            update_attack_sprite();
            image_index = 0;
            break;

        case TribeState.HURT:
            warrior_invincible = max_warrior_invincible;
            break;

        case TribeState.DEAD:
            xspd = 0;
            yspd = 0;
            death_timer = 0;
            sprite_index = spr_tribe_warrior_death;
            image_xscale = (face == LEFT) ? -1 : 1;
            image_index = 0;
            image_speed = 1;
            show_debug_message("Tribe warrior died.");
            break;
    }
}

/// Apply this swing's damage to the player if inside the directional hitbox (one connect per swing).
function perform_attack() {
    if (attack_landed) return;
    var player = current_target;
    if (player == noone || player.current_state == StrandedState.DEAD) return;

    var atk_l, atk_t, atk_r, atk_b;
    switch (face) {
        case RIGHT:
            atk_l = x - hitbox_height / 2; atk_t = y - hitbox_width / 2;
            atk_r = x + attack_reach;      atk_b = y + hitbox_width / 2;
            break;
        case LEFT:
            atk_l = x - attack_reach;      atk_t = y - hitbox_width / 2;
            atk_r = x + hitbox_height / 2; atk_b = y + hitbox_width / 2;
            break;
        case DOWN:
            atk_l = x - hitbox_width / 2;  atk_t = y - hitbox_height / 2;
            atk_r = x + hitbox_width / 2;  atk_b = y + attack_reach;
            break;
        case UP:
            atk_l = x - hitbox_width / 2;  atk_t = y - attack_reach;
            atk_r = x + hitbox_width / 2;  atk_b = y + hitbox_height / 2;
            break;
    }

    if (atk_r >= player.bbox_left && atk_l <= player.bbox_right &&
        atk_b >= player.bbox_top  && atk_t <= player.bbox_bottom) {
        if (player.invincible <= 0) {
            player.player_health -= attack_damage;
            player.invincible = player.max_invincible;
        }
        attack_landed = true;
    }
}

/// Public damage entry point, called by the player's attack code.
function take_hit(_damage) {
    if (current_state == TribeState.DEAD) return;
    if (warrior_invincible > 0) return;

    warrior_health -= _damage;

    if (warrior_health <= 0) {
        warrior_health = 0;
        change_state(TribeState.DEAD);
        return;
    }

    // Knockback away from the attacker, then enter HURT.
    var attacker = instance_nearest(x, y, obj_player_stranded);
    if (attacker != noone) {
        var kd = point_direction(attacker.x, attacker.y, x, y);
        hurt_knockback_x = lengthdir_x(hurt_knockback_speed, kd);
        hurt_knockback_y = lengthdir_y(hurt_knockback_speed, kd);
    }
    // Aggro the attacker on hit even without prior line of sight.
    current_target = attacker;
    if (current_target != noone) { last_known_x = current_target.x; last_known_y = current_target.y; }
    change_state(TribeState.HURT);
}
