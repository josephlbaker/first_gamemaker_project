// ===================================================================================================
// STRANDED PLAYER  -  Souls-like combat controller (top-down, 2D pixel art)
// ===================================================================================================
// Unlike obj_player (single 501-frame sprite sheet), this character uses ONE SPRITE RESOURCE PER
// ANIMATION. Only three art directions exist per action:
//     - down  : facing camera
//     - up    : facing away
//     - lr     : facing RIGHT by default; facing LEFT is the same sprite flipped (image_xscale = -1)
// heal and death are single, direction-less sprites.
//
// ANIMATION SYSTEM:
// - Animations live in the 'anim' struct. Each entry stores its three direction sprites + a loop flag.
// - set_animation(anim.run) picks the correct sprite for the current 'face'.
// - We drive frames manually (anim_frame / anim_timer) so non-looping actions (slash, chop, roll,
//   heal, death) can reliably report completion via anim_is_finished().
// - Every step we push the resolved sprite into sprite_index / image_index / image_xscale, set
//   image_speed = 0, and let the Draw event render it (with damage flash + roll i-frame tint).
//
// CONTROLS  (mirrors obj_player; combat is mouse-driven for snappy souls feel):
// - WASD ............. move            - Space ............ dodge roll (i-frames, costs stamina)
// - Left Mouse ....... slash (light)   - Right Mouse ...... chop (heavy)
// - Q ............... heal (flask)     - T ............... walk toggle      - Esc ... pause
// - On attack the character snaps to face the mouse cursor so swings go where you aim.
//
// SOULS-LIKE FEATURES INCLUDED (see notes in summary):
// - Stamina governs roll / slash / chop and regenerates after a short delay.
// - Dodge roll grants invincibility frames.
// - Light-attack combo: rapid clicks chain slashes within a combo window for ramped damage.
// - Heavy chop: slower, higher damage & stamina, light knockback emphasis.
// - Estus-style heal flasks: limited charges, heals over the animation, locks movement.
// - Input buffering so the next attack/roll fires the instant the current action ends (fluid feel).
// ===================================================================================================

// ===== STATE ENUM =====
enum StrandedState {
    IDLE,
    MOVING,
    ROLLING,
    SLASHING,
    CHOPPING,
    HEALING,
    DEAD,
    PAUSED
}

current_state  = StrandedState.IDLE;
previous_state = StrandedState.IDLE;

// ===== MOVEMENT VARIABLES =====
xspd        = 0;
yspd        = 0;
move_speed  = 2.2;          // snappy base speed
is_walking  = false;        // T toggles a slow walk

// ===== FACING =====
face = DOWN;                // RIGHT / UP / LEFT / DOWN (from scr_macros)

// ===== ROLL / DODGE VARIABLES =====
roll_speed        = 6.5;            // burst speed while rolling
roll_dir_x        = 0;
roll_dir_y        = 0;
roll_iframes      = 18;             // invincibility frames granted on roll start
roll_stamina_cost = 25;
cooldown_timer    = 0;              // small recovery after a roll
cooldown_duration = 0.08 * game_get_speed(gamespeed_fps);

// ===== HEALTH VARIABLES =====
player_health  = 100;
max_health     = 100;
invincible     = 0;                 // i-frame / hurt-flash counter
max_invincible = 30;                // i-frames granted when taking a hit

// ===== STAMINA VARIABLES =====
stamina            = 100;
max_stamina        = 100;
stamina_regen      = 0.75;          // per step once regen begins
stamina_regen_delay = 30;           // steps to wait after spending before regen
stamina_regen_timer = 0;

// ===== DEATH VARIABLES =====
death_timer = 0;

// ===== COMBAT VARIABLES =====
// Light attack (slash, left mouse)
slash_damage       = 15;
slash_stamina_cost = 18;
// Heavy attack (chop, right mouse)
chop_damage        = 32;
chop_stamina_cost  = 32;

attack_damage = slash_damage;       // damage applied by the CURRENT swing (set on entry)
attack_reach  = 28;                 // how far the hitbox extends past the body
hitbox_width  = 30;                 // hitbox thickness (perpendicular to facing)
hitbox_height = 14;
attack_has_hit = false;             // ensures each swing only damages a target once

// Light-attack combo
combo_stage  = 0;                   // 0 = none, increments per chained slash
combo_max    = 3;
combo_timer  = 0;
combo_window = 24;                  // frames to chain the next slash

// ===== HEAL / FLASK VARIABLES =====
flask_charges     = 3;
flask_max_charges = 3;
heal_amount       = 45;
heal_applied      = false;          // restore health once, partway through the anim

// ===== INPUT BUFFER (snappy queued actions) =====
buffered_action = "";               // "slash" | "chop" | "roll" | ""
buffer_timer    = 0;
buffer_window   = 8;                // frames a buffered input stays valid

// ===== ANIMATION SYSTEM =====
// Each action stores its three directional sprites and whether it loops.
anim = {
    idle:  { down: spr_stranded_idle_down,  up: spr_stranded_idle_up,  lr: spr_stranded_idle_lr,  loop: true  },
    run:   { down: spr_stranded_run_down,   up: spr_stranded_run_up,   lr: spr_stranded_run_lr,   loop: true  },
    roll:  { down: spr_stranded_roll_down,  up: spr_stranded_roll_up,  lr: spr_stranded_roll_lr,  loop: false },
    slash: { down: spr_stranded_slash_down, up: spr_stranded_slash_up, lr: spr_stranded_slash_lr, loop: false },
    chop:  { down: spr_stranded_chop_down,  up: spr_stranded_chop_up,  lr: spr_stranded_chop_lr,  loop: false },
    heal:  { down: spr_stranded_heal,       up: spr_stranded_heal,     lr: spr_stranded_heal,     loop: false },
    death: { down: spr_stranded_death,      up: spr_stranded_death,    lr: spr_stranded_death,    loop: false },
};

current_anim = anim.idle;
anim_frame   = 0;       // current frame (float)
anim_timer   = 0;       // sub-frame accumulator
anim_speed   = 0.15;    // sprite-frames advanced per game step

// ===== COLLISION MASK =====
// Keep a stable mask so movement collision doesn't change shape between animations.
mask_index = spr_stranded_idle_down;

// ===================================================================================================
// HELPER FUNCTIONS
// ===================================================================================================

/// Resolve which sprite to draw for the current facing direction.
function resolve_sprite(_def) {
    switch (face) {
        case UP:   return _def.up;
        case DOWN: return _def.down;
        default:   return _def.lr;   // LEFT or RIGHT share the lr sprite
    }
}

/// Horizontal flip for the current facing (LEFT mirrors the lr sprite).
function resolve_flip() {
    return (face == LEFT) ? -1 : 1;
}

/// Number of frames in the currently resolved sprite.
function current_frame_count() {
    return sprite_get_number(resolve_sprite(current_anim));
}

/// Switch animation, restarting frames only when the action actually changes.
function set_animation(_def) {
    if (current_anim != _def) {
        current_anim = _def;
        anim_frame = 0;
        anim_timer = 0;
    }
}

/// True once a non-looping animation has reached its final frame.
function anim_is_finished() {
    if (current_anim.loop) return false;
    return (floor(anim_frame) >= current_frame_count() - 1);
}

/// Snap 'face' to one of four directions pointing at the mouse cursor.
function face_toward_mouse() {
    var dir = point_direction(x, y, mouse_x, mouse_y);
    // 45..135 = up, 135..225 = left, 225..315 = down, else right
    if (dir > 45 && dir <= 135)       face = UP;
    else if (dir > 135 && dir <= 225) face = LEFT;
    else if (dir > 225 && dir <= 315) face = DOWN;
    else                              face = RIGHT;
}

/// Spend stamina and (re)start the regen delay.
function spend_stamina(_amount) {
    stamina = max(0, stamina - _amount);
    stamina_regen_timer = stamina_regen_delay;
}

/// Queue an action so it fires the instant the current action ends.
function buffer_action(_name) {
    buffered_action = _name;
    buffer_timer = buffer_window;
}

/// State entry logic.
function change_state(new_state) {
    previous_state = current_state;
    current_state  = new_state;

    switch (new_state) {
        case StrandedState.SLASHING:
            face_toward_mouse();
            anim_speed     = 0.5;                 // snappy light swing
            attack_damage  = slash_damage + combo_stage * 4;  // ramp damage through the combo
            attack_has_hit = false;
            combo_timer    = combo_window;
            spend_stamina(slash_stamina_cost);
            set_animation(anim.slash);
            break;

        case StrandedState.CHOPPING:
            face_toward_mouse();
            anim_speed     = 0.32;                // heavier, weightier swing
            attack_damage  = chop_damage;
            attack_has_hit = false;
            combo_stage    = 0;                   // heavy attack breaks the light combo
            spend_stamina(chop_stamina_cost);
            set_animation(anim.chop);
            break;

        case StrandedState.ROLLING:
            anim_speed = 0.4;
            spend_stamina(roll_stamina_cost);
            invincible = max(invincible, roll_iframes);  // grant dodge i-frames

            // Roll toward movement input, else toward current facing.
            var ix = keyboard_check(ord("D")) - keyboard_check(ord("A"));
            var iy = keyboard_check(ord("S")) - keyboard_check(ord("W"));
            if (ix == 0 && iy == 0) {
                switch (face) {
                    case RIGHT: ix = 1;  break;
                    case LEFT:  ix = -1; break;
                    case DOWN:  iy = 1;  break;
                    case UP:    iy = -1; break;
                }
            } else {
                // Update facing to match the roll direction.
                if (abs(ix) >= abs(iy)) face = (ix > 0) ? RIGHT : LEFT;
                else                    face = (iy > 0) ? DOWN : UP;
            }
            roll_dir_x = ix;
            roll_dir_y = iy;
            set_animation(anim.roll);
            break;

        case StrandedState.HEALING:
            anim_speed   = 0.4;
            heal_applied = false;
            xspd = 0;
            yspd = 0;
            set_animation(anim.heal);
            break;

        case StrandedState.DEAD:
            anim_speed  = 0.4;
            death_timer = 0;
            xspd = 0;
            yspd = 0;
            set_animation(anim.death);
            show_debug_message("Stranded player died.");
            break;
    }
}

/// Apply the current swing's damage to anything inside the directional hitbox.
function perform_attack() {
    if (attack_has_hit) return;   // one connect per swing

    // Build a rectangular hitbox in front of the player based on facing.
    var atk_l, atk_t, atk_r, atk_b;
    switch (face) {
        case RIGHT:
            atk_l = x - hitbox_height / 2;
            atk_t = y - hitbox_width / 2;
            atk_r = x + attack_reach;
            atk_b = y + hitbox_width / 2;
            break;
        case LEFT:
            atk_l = x - attack_reach;
            atk_t = y - hitbox_width / 2;
            atk_r = x + hitbox_height / 2;
            atk_b = y + hitbox_width / 2;
            break;
        case DOWN:
            atk_l = x - hitbox_width / 2;
            atk_t = y - hitbox_height / 2;
            atk_r = x + hitbox_width / 2;
            atk_b = y + attack_reach;
            break;
        case UP:
            atk_l = x - hitbox_width / 2;
            atk_t = y - attack_reach;
            atk_r = x + hitbox_width / 2;
            atk_b = y + hitbox_height / 2;
            break;
    }

    var hit_something = false;

    // Damage enemies.
    var enemies = ds_list_create();
    collision_rectangle_list(atk_l, atk_t, atk_r, atk_b, obj_enemy, false, true, enemies, false);
    for (var i = 0; i < ds_list_size(enemies); i++) {
        var enemy = ds_list_find_value(enemies, i);
        if (enemy.enemy_invincible <= 0 && enemy.current_state != EnemyState.DEAD) {
            enemy.enemy_health -= attack_damage;
            enemy.enemy_invincible = enemy.max_enemy_invincible;
            enemy.change_state(EnemyState.HURT);
            hit_something = true;
        }
    }
    ds_list_destroy(enemies);

    // Damage tribe warriors (own health pool + i-frames handled in take_hit).
    var warriors = ds_list_create();
    collision_rectangle_list(atk_l, atk_t, atk_r, atk_b, obj_tribe_warrior, false, true, warriors, false);
    for (var i = 0; i < ds_list_size(warriors); i++) {
        var warrior = ds_list_find_value(warriors, i);
        if (warrior.warrior_invincible <= 0 && warrior.current_state != TribeState.DEAD) {
            warrior.take_hit(attack_damage);
            hit_something = true;
        }
    }
    ds_list_destroy(warriors);

    // Damage destructible props if present in the room.
    if (object_exists(obj_crate)) {
        var crates = ds_list_create();
        collision_rectangle_list(atk_l, atk_t, atk_r, atk_b, obj_crate, false, true, crates, false);
        for (var i = 0; i < ds_list_size(crates); i++) {
            ds_list_find_value(crates, i).take_damage();
            hit_something = true;
        }
        ds_list_destroy(crates);
    }

    if (hit_something) attack_has_hit = true;
}

/// Solid-collision test reused from obj_player (walls + solid destructibles).
function check_solid_collision(check_x, check_y) {
    if (place_meeting(check_x, check_y, obj_wall)) {
        var walls = ds_list_create();
        collision_point_list(check_x, check_y, obj_wall, false, true, walls, false);
        for (var i = 0; i < ds_list_size(walls); i++) {
            var wall = ds_list_find_value(walls, i);
            if (wall.object_index == obj_wall ||
                (variable_instance_exists(wall, "is_solid") && wall.is_solid)) {
                ds_list_destroy(walls);
                return true;
            }
        }
        ds_list_destroy(walls);
    }
    return false;
}
