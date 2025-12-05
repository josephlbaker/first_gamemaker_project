// ===== INPUT =====
var right_key = keyboard_check(ord("D"));
var left_key = keyboard_check(ord("A"));
var down_key = keyboard_check(ord("S"));
var up_key = keyboard_check(ord("W"));
var toggle_walk = keyboard_check_pressed(ord("T"));
var dash_pressed = keyboard_check_pressed(vk_space);
var attack_pressed = mouse_check_button_pressed(mb_left);
var pause_pressed = keyboard_check_pressed(vk_escape);
var interact_pressed = keyboard_check_pressed(ord("E"));


// ===== INTERACTION CHECK =====
if (interact_pressed) {
    // Check if text display is already showing
    if (instance_exists(obj_text_display)) {
        // Close existing text
        instance_destroy(obj_text_display);
    } 
    // Horse mounting/dismounting
    else if (is_mounted) {
        // Dismount horse - create static horse at player position
        instance_create_layer(x, y, "Instances", obj_horse_static);
        is_mounted = false;
    }
    else {
        // Check for horse to mount
        var horse = instance_nearest(x, y, obj_horse_static);
        if (horse != noone && distance_to_object(horse) <= 32) {
            // Mount the horse
            instance_destroy(horse);
            is_mounted = true;
        }
        // Look for signpost within interaction radius
        else {
            var signpost = instance_nearest(x, y, obj_signpost);
            if (signpost != noone && distance_to_object(signpost) <= 32) {
                // Create text display
                var text_obj = instance_create_layer(0, 0, "Instances", obj_text_display);
                text_obj.text_to_show = signpost.sign_text;
            }
        }
    }
}

// ===== UPDATE INVINCIBILITY =====
if (invincible > 0) {
    invincible--;
}

// ===== UPDATE COOLDOWNS =====
if (cooldown_timer > 0) {
    cooldown_timer--;
}

// ===== UPDATE ATTACK COMBO TIMER =====
if (attack_combo_timer > 0) {
    attack_combo_timer--;
} else {
    // Reset combo if timer runs out
    attack_combo_stage = 1;
}

// ===== TOGGLE WALK MODE =====
if (toggle_walk) {
    is_walking = !is_walking;
}

// ===== PAUSE TOGGLE =====
if (pause_pressed) {
    if (instance_exists(obj_pauser)) {
        instance_destroy(obj_pauser);
    } else {
        instance_create_layer(0, 0, "Instances", obj_pauser);
    }
}

// ===== STATE MACHINE =====
switch(current_state) {
    case PlayerState.IDLE:
    case PlayerState.MOVING:
        // Check for death
        if (player_health <= 0) {
            change_state(PlayerState.DEAD);
            break;
        }
        
        // Check for pause
        if (instance_exists(obj_pauser)) {
            change_state(PlayerState.PAUSED);
            break;
        }
        
        // Check for attack
        if (attack_pressed && cooldown_timer <= 0) {
            // Advance combo stage if within combo window, otherwise start fresh
            if (attack_combo_timer > 0 && attack_combo_stage < 3) {
                attack_combo_stage++;
            } else {
                attack_combo_stage = 1;
            }
            change_state(PlayerState.ATTACKING);
            break;
        }
        
        // Check for dash
        if (dash_pressed && cooldown_timer <= 0) {
            change_state(PlayerState.DASHING);
            break;
        }
        
        // Handle normal movement
        var speed_modifier = 1;
        var base_speed;
        if (is_mounted) {
            base_speed = horse_speed;  // Use horse speed when mounted
        } else {
            base_speed = is_walking ? move_speed / 2 : move_speed;
        }
        var current_speed = base_speed * speed_modifier;
        
        xspd = (right_key - left_key) * current_speed;
        yspd = (down_key - up_key) * current_speed;
        
        // Diagonal correction
        if (abs(xspd) > 0 && abs(yspd) > 0) {
            xspd *= 1/sqrt(2);
            yspd *= 1/sqrt(2);
        }
        
        // ===== STAIR MOVEMENT LOGIC =====
        // Check if player is colliding with stair objects and add vertical movement based on horizontal movement
        if (place_meeting(x, y, obj_stair_right)) {
            // On right stairs: moving right = go up, moving left = go down
            if (xspd > 0) {
                yspd -= abs(xspd) * 0.25; // Move up when going right
            } else if (xspd < 0) {
                yspd += abs(xspd) * 0.25; // Move down when going left
            }
        } else if (place_meeting(x, y, obj_stair_left)) {
            // On left stairs: moving left = go up, moving right = go down
            if (xspd < 0) {
                yspd -= abs(xspd) * 0.25; // Move up when going left
            } else if (xspd > 0) {
                yspd += abs(xspd) * 0.25; // Move down when going right
            }
        }
        
        // Update state based on movement
        if (xspd != 0 || yspd != 0) {
            if (current_state != PlayerState.MOVING) {
                change_state(PlayerState.MOVING);
            }
            // Update facing direction
            if (xspd > 0) face = RIGHT;
            else if (xspd < 0) face = LEFT;
            else if (yspd > 0) face = DOWN;
            else if (yspd < 0) face = UP;
        } else {
            if (current_state != PlayerState.IDLE) {
                change_state(PlayerState.IDLE);
            }
        }
        
        // Update animation based on state, direction, and mount status
        if (current_state == PlayerState.MOVING) {
            if (is_mounted) {
                // Use horse run animations when mounted
                switch(face) {
                    case RIGHT: set_animation(anim.horse_run_right); break;
                    case LEFT: set_animation(anim.horse_run_left); break;
                    case DOWN: set_animation(anim.horse_run_down); break;
                    case UP: set_animation(anim.horse_run_up); break;
                }
            } else {
                // Use normal run animations
                switch(face) {
                    case RIGHT: set_animation(anim.run_right); break;
                    case LEFT: set_animation(anim.run_left); break;
                    case DOWN: set_animation(anim.run_down); break;
                    case UP: set_animation(anim.run_up); break;
                }
            }
        } else {
            if (is_mounted) {
                // Use horse idle animations when mounted
                switch(face) {
                    case RIGHT: set_animation(anim.horse_idle_right); break;
                    case LEFT: set_animation(anim.horse_idle_left); break;
                    case DOWN: set_animation(anim.horse_idle_down); break;
                    case UP: set_animation(anim.horse_idle_up); break;
                }
            } else {
                // Use normal idle animations
                switch(face) {
                    case RIGHT: set_animation(anim.idle_right); break;
                    case LEFT: set_animation(anim.idle_left); break;
                    case DOWN: set_animation(anim.idle_down); break;
                    case UP: set_animation(anim.idle_up); break;
                }
            }
        }
        break;
        
    case PlayerState.ATTACKING:
        // Slow movement during attack
        xspd *= 0.5;
        yspd *= 0.5;
        
        // Check if attack animation finished
        if (anim_frame >= current_anim.frame_count - 1) {
            // Reset animation speed
            anim_speed = 0.10;
            
            // If combo reached stage 3, reset it
            if (attack_combo_stage >= 3) {
                attack_combo_stage = 1;
                attack_combo_timer = 0;
            }
            
            // Return to previous state
            if (xspd != 0 || yspd != 0) {
                change_state(PlayerState.MOVING);
            } else {
                change_state(PlayerState.IDLE);
            }
        }
        break;
        
    case PlayerState.DASHING:
        // Faster animation during roll
        anim_speed = 0.5;
        
        // Normalize diagonal dashing
        var normalized_x = dash_dir_x;
        var normalized_y = dash_dir_y;
        if (abs(dash_dir_x) > 0 && abs(dash_dir_y) > 0) {
            normalized_x *= 1/sqrt(2);
            normalized_y *= 1/sqrt(2);
        }
        
        // Consistent dash speed throughout animation
        xspd = normalized_x * dash_speed;
        yspd = normalized_y * dash_speed;
        
        // Check for crate collisions during dash
        var crates = ds_list_create();
        collision_rectangle_list(
            x - sprite_width/2, y - sprite_height/2, 
            x + sprite_width/2, y + sprite_height/2,
            obj_crate, false, true, crates, false
        );
        
        for (var i = 0; i < ds_list_size(crates); i++) {
            var crate = ds_list_find_value(crates, i);
            // Only damage if crate is not already destroyed/animating
            if (crate.crate_health > 0 && !crate.is_animating) {
                crate.take_damage();
                show_debug_message("Dash broke crate!");
            }
        }
        
        ds_list_destroy(crates);
        
        // End dash when animation is complete
        if (anim_frame >= current_anim.frame_count - 1) {
            cooldown_timer = cooldown_duration;
            anim_speed = 0.15;  // Restore normal animation speed
            change_state(PlayerState.MOVING);
        }
        break;
        
    case PlayerState.DEAD:
        death_timer++;
        xspd = 0;
        yspd = 0;
        
        // Show death menu when animation finishes
        if (anim_frame >= current_anim.frame_count - 1 && death_timer >= 60) {
            if (!instance_exists(obj_death_menu)) {
                instance_create_layer(0, 0, "Instances", obj_death_menu);
            }
            anim_speed = 0;
            anim_frame = current_anim.frame_count - 1;
        }
        // Exit early - no movement or other actions
        exit;
        
    case PlayerState.PAUSED:
        xspd = 0;
        yspd = 0;
        
        // Check if unpause
        if (!instance_exists(obj_pauser)) {
            change_state(previous_state);
        }
        // Don't advance animation while paused
        break;
}

// ===== ANIMATE =====
// Advance animation frame (except when paused or dead and finished)
if (current_state != PlayerState.PAUSED) {
    if (current_state == PlayerState.DEAD && anim_frame >= current_anim.frame_count - 1) {
        // Keep on last frame
        anim_frame = current_anim.frame_count - 1;
    } else {
        // Normalize animation speed based on frame count
        // This keeps cycle time consistent regardless of frame count
        // Base: 6 frames at 0.15 speed = ~40 game frames per cycle
        var base_frames = 6;
        var normalized_speed = (current_anim.frame_count / base_frames) * anim_speed;
        
        anim_timer += normalized_speed;
        if (anim_timer >= 1) {
            anim_frame += floor(anim_timer);
            anim_timer = anim_timer % 1;
            
            // Loop animation if past the end (except for death)
            if (anim_frame >= current_anim.frame_count) {
                if (current_state == PlayerState.DEAD) {
                    anim_frame = current_anim.frame_count - 1;
                } else {
                    anim_frame = anim_frame % current_anim.frame_count;
                }
            }
        }
    }
}

// ===== COLLISION DETECTION =====
if (check_solid_collision(x + xspd, y)) {
    xspd = 0;
    // Stop dash if currently dashing
    if (current_state == PlayerState.DASHING) {
        cooldown_timer = cooldown_duration;
        change_state(PlayerState.IDLE);
    }
}
if (check_solid_collision(x, y + yspd)) {
    yspd = 0;
    // Stop dash if currently dashing
    if (current_state == PlayerState.DASHING) {
        cooldown_timer = cooldown_duration;
        change_state(PlayerState.IDLE);
    }
}


// ===== APPLY MOVEMENT =====
x += xspd;
y += yspd;

// ===== UPDATE DEPTH =====
depth = -bbox_bottom;

// ===== UPDATE HORSE ANIMATION =====
if (is_mounted) {
    update_horse_animation();
}

// ===== UPDATE SWORD ANIMATION =====
update_sword_animation();
