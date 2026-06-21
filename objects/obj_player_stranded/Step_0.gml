// ===== INPUT =====
var right_key      = keyboard_check(ord("D"));
var left_key       = keyboard_check(ord("A"));
var down_key       = keyboard_check(ord("S"));
var up_key         = keyboard_check(ord("W"));
var toggle_walk    = keyboard_check_pressed(ord("T"));
var roll_pressed   = keyboard_check_pressed(vk_space);
var slash_pressed  = mouse_check_button_pressed(mb_left);
var chop_pressed   = mouse_check_button_pressed(mb_right);
var heal_pressed   = keyboard_check_pressed(ord("Q"));
var pause_pressed  = keyboard_check_pressed(vk_escape);

// ===== PAUSE TOGGLE =====
if (pause_pressed) {
    if (instance_exists(obj_pauser)) {
        instance_destroy(obj_pauser);
    } else {
        instance_create_layer(0, 0, "Instances", obj_pauser);
    }
}

// ===== TIMERS =====
if (invincible > 0)          invincible--;
if (cooldown_timer > 0)      cooldown_timer--;
if (buffer_timer > 0)        buffer_timer--; else buffered_action = "";
if (combo_timer > 0)         combo_timer--; else combo_stage = 0;

// ===== STAMINA REGEN =====
if (stamina_regen_timer > 0) {
    stamina_regen_timer--;
} else if (stamina < max_stamina) {
    stamina = min(max_stamina, stamina + stamina_regen);
}

// ===== TOGGLE WALK =====
if (toggle_walk) is_walking = !is_walking;

// ===== DEATH CHECK (from any living state) =====
if (player_health <= 0 && current_state != StrandedState.DEAD) {
    change_state(StrandedState.DEAD);
}

// ===== BUFFER ACTION INPUTS =====
// Capture attack/roll presses even mid-action so they fire the instant we recover.
if (current_state != StrandedState.DEAD && current_state != StrandedState.PAUSED) {
    // Precedence on the same step: roll > chop > slash.
    if (roll_pressed)       buffer_action("roll");
    else if (chop_pressed)  buffer_action("chop");
    else if (slash_pressed) buffer_action("slash");
}

// ===================================================================================================
// STATE MACHINE
// ===================================================================================================
switch (current_state) {

    case StrandedState.IDLE:
    case StrandedState.MOVING:
        // Pause takes over.
        if (instance_exists(obj_pauser)) { change_state(StrandedState.PAUSED); break; }

        // --- Action priority: roll > heal > chop > slash ---
        if ((buffered_action == "roll") && stamina >= roll_stamina_cost && cooldown_timer <= 0) {
            buffered_action = ""; change_state(StrandedState.ROLLING); break;
        }
        if (heal_pressed && flask_charges > 0) {
            change_state(StrandedState.HEALING); break;
        }
        if ((buffered_action == "chop") && stamina >= chop_stamina_cost) {
            buffered_action = ""; change_state(StrandedState.CHOPPING); break;
        }
        if ((buffered_action == "slash") && stamina >= slash_stamina_cost) {
            buffered_action = "";
            // Chain the light combo if we slashed recently.
            if (combo_timer > 0 && combo_stage < combo_max) combo_stage++; else combo_stage = 1;
            change_state(StrandedState.SLASHING);
            break;
        }

        // --- Movement ---
        var base_speed = is_walking ? move_speed * 0.5 : move_speed;
        xspd = (right_key - left_key) * base_speed;
        yspd = (down_key - up_key)   * base_speed;

        // Normalize diagonals.
        if (xspd != 0 && yspd != 0) {
            xspd *= 1 / sqrt(2);
            yspd *= 1 / sqrt(2);
        }

        // Update facing + state from movement.
        if (xspd != 0 || yspd != 0) {
            if (current_state != StrandedState.MOVING) change_state(StrandedState.MOVING);
            if (xspd > 0)      face = RIGHT;
            else if (xspd < 0) face = LEFT;
            else if (yspd > 0) face = DOWN;
            else if (yspd < 0) face = UP;
            set_animation(anim.run);
            anim_speed = 0.22;
        } else {
            if (current_state != StrandedState.IDLE) change_state(StrandedState.IDLE);
            set_animation(anim.idle);
            anim_speed = 0.15;
        }
        break;

    case StrandedState.SLASHING:
    case StrandedState.CHOPPING:
        // Drift to a stop during a swing; keep a little momentum for fluidity.
        xspd *= 0.6;
        yspd *= 0.6;

        // Connect the hitbox in the active middle of the swing.
        var fc = current_frame_count();
        if (floor(anim_frame) >= floor(fc * 0.25)) perform_attack();

        if (anim_is_finished()) {
            // Buffered follow-ups make combat feel responsive.
            if (buffered_action == "roll" && stamina >= roll_stamina_cost) {
                buffered_action = ""; change_state(StrandedState.ROLLING); break;
            }
            if (buffered_action == "chop" && stamina >= chop_stamina_cost) {
                buffered_action = ""; change_state(StrandedState.CHOPPING); break;
            }
            if (buffered_action == "slash" && stamina >= slash_stamina_cost) {
                buffered_action = "";
                if (combo_timer > 0 && combo_stage < combo_max) combo_stage++; else combo_stage = 1;
                change_state(StrandedState.SLASHING); break;
            }
            change_state((abs(xspd) > 0.1 || abs(yspd) > 0.1) ? StrandedState.MOVING : StrandedState.IDLE);
        }
        break;

    case StrandedState.ROLLING:
        // Constant-speed burst in the roll direction.
        var nx = roll_dir_x;
        var ny = roll_dir_y;
        if (nx != 0 && ny != 0) { nx *= 1 / sqrt(2); ny *= 1 / sqrt(2); }
        xspd = nx * roll_speed;
        yspd = ny * roll_speed;

        if (anim_is_finished()) {
            cooldown_timer = cooldown_duration;
            // Allow buffered attack straight out of a roll.
            if (buffered_action == "slash" && stamina >= slash_stamina_cost) {
                buffered_action = ""; combo_stage = 1; change_state(StrandedState.SLASHING); break;
            }
            if (buffered_action == "chop" && stamina >= chop_stamina_cost) {
                buffered_action = ""; change_state(StrandedState.CHOPPING); break;
            }
            change_state(StrandedState.IDLE);
        }
        break;

    case StrandedState.HEALING:
        xspd = 0;
        yspd = 0;

        // Apply the heal partway through, consuming a charge once.
        if (!heal_applied && floor(anim_frame) >= floor(current_frame_count() * 0.5)) {
            heal_applied = true;
            flask_charges--;
            player_health = min(max_health, player_health + heal_amount);
        }

        if (anim_is_finished()) {
            change_state(StrandedState.IDLE);
        }
        break;

    case StrandedState.DEAD:
        death_timer++;
        xspd = 0;
        yspd = 0;

        if (anim_is_finished()) {
            anim_frame = current_frame_count() - 1;   // hold final frame
            if (death_timer >= 60 && object_exists(obj_death_menu) && !instance_exists(obj_death_menu)) {
                instance_create_layer(0, 0, "Instances", obj_death_menu);
            }
        }
        // No movement / collision while dead.
        // (still advance animation below)
        break;

    case StrandedState.PAUSED:
        xspd = 0;
        yspd = 0;
        if (!instance_exists(obj_pauser)) change_state(previous_state);
        break;
}

// ===================================================================================================
// ANIMATION ADVANCE
// ===================================================================================================
if (current_state != StrandedState.PAUSED) {
    var fcount = current_frame_count();
    var hold_dead_frame = (current_state == StrandedState.DEAD && floor(anim_frame) >= fcount - 1);

    if (!hold_dead_frame) {
        anim_timer += anim_speed;
        while (anim_timer >= 1) {
            anim_timer -= 1;
            anim_frame += 1;
            if (anim_frame >= fcount) {
                if (current_anim.loop) anim_frame -= fcount;
                else                   anim_frame = fcount - 1;
            }
        }
    }
}

// Push resolved animation into the instance for drawing / depth / mask.
sprite_index = resolve_sprite(current_anim);
image_index  = floor(anim_frame);
image_xscale = resolve_flip();
image_speed  = 0;

// ===================================================================================================
// COLLISION + MOVEMENT  (skip entirely while dead)
// ===================================================================================================
if (current_state != StrandedState.DEAD && current_state != StrandedState.PAUSED) {
    if (check_solid_collision(x + xspd, y)) {
        xspd = 0;
        if (current_state == StrandedState.ROLLING) { cooldown_timer = cooldown_duration; change_state(StrandedState.IDLE); }
    }
    if (check_solid_collision(x, y + yspd)) {
        yspd = 0;
        if (current_state == StrandedState.ROLLING) { cooldown_timer = cooldown_duration; change_state(StrandedState.IDLE); }
    }

    x += xspd;
    y += yspd;
}

// ===== DEPTH (y-sorting) =====
depth = -bbox_bottom;
