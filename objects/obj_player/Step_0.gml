// ===== INPUT =====
var right_key = keyboard_check(ord("D"));
var left_key = keyboard_check(ord("A"));
var down_key = keyboard_check(ord("S"));
var up_key = keyboard_check(ord("W"));
var toggle_walk = keyboard_check_pressed(ord("T"));
var dash_pressed = keyboard_check_pressed(vk_space);
var attack_pressed = mouse_check_button_pressed(mb_left);

// ===== UPDATE INVINCIBILITY =====
if (invincible > 0) {
    invincible--;
}

// ===== UPDATE COOLDOWNS =====
if (cooldown_timer > 0) {
    cooldown_timer--;
}

// ===== TOGGLE WALK MODE =====
if (toggle_walk) {
    is_walking = !is_walking;
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
        var base_speed = is_walking ? move_speed / 2 : move_speed;
        var current_speed = base_speed * speed_modifier;
        
        xspd = (right_key - left_key) * current_speed;
        yspd = (down_key - up_key) * current_speed;
        
        // Diagonal correction
        if (abs(xspd) > 0 && abs(yspd) > 0) {
            xspd *= 1/sqrt(2);
            yspd *= 1/sqrt(2);
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
        
        // Update sprite based on state and direction
        if (current_state == PlayerState.MOVING) {
            switch(face) {
                case RIGHT: sprite_index = is_walking ? spr_player_walk_right : spr_player_run_right; break;
                case LEFT: sprite_index = is_walking ? spr_player_walk_left : spr_player_run_left; break;
                case DOWN: sprite_index = is_walking ? spr_player_walk_down : spr_player_run_down; break;
                case UP: sprite_index = is_walking ? spr_player_walk_up : spr_player_run_up; break;
            }
        } else {
            switch(face) {
                case RIGHT: sprite_index = spr_player_idle_right; break;
                case LEFT: sprite_index = spr_player_idle_left; break;
                case DOWN: sprite_index = spr_player_idle_down; break;
                case UP: sprite_index = spr_player_idle_up; break;
            }
        }
        break;
        
    case PlayerState.ATTACKING:
        // Slow movement during attack
        xspd *= 0.5;
        yspd *= 0.5;
        
        // Check if attack animation finished
        if (image_index >= image_number - 1) {
            // Return to previous state
            if (xspd != 0 || yspd != 0) {
                change_state(PlayerState.MOVING);
            } else {
                change_state(PlayerState.IDLE);
            }
        }
        break;
        
    case PlayerState.DASHING:
        // Calculate dash progress
        var progress = 1 - (dash_timer / dash_duration);
        var ease_factor = 1 - power(1 - progress, 3);
        var current_dash_speed = dash_speed * (1 - ease_factor * 0.6);
        
        xspd = dash_dir_x * current_dash_speed;
        yspd = dash_dir_y * current_dash_speed;
		
		// Normalize diagonal dashing
	    var normalized_x = dash_dir_x;
	    var normalized_y = dash_dir_y;
    
	    if (abs(dash_dir_x) > 0 && abs(dash_dir_y) > 0) {
	        normalized_x *= 1/sqrt(2); // 1/sqrt(2)
	        normalized_y *= 1/sqrt(2);
	    }
    
	    xspd = normalized_x * current_dash_speed;
	    yspd = normalized_y * current_dash_speed;
        
        // Update dash sprite
        switch(face) {
            case RIGHT: sprite_index = spr_player_dash_right; break;
            case LEFT: sprite_index = spr_player_dash_left; break;
            case DOWN: sprite_index = spr_player_dash_down; break;
            case UP: sprite_index = spr_player_dash_up; break;
        }
        
        dash_timer--;
        if (dash_timer <= 0) {
            cooldown_timer = cooldown_duration;
            // Keep some momentum
            xspd *= 0.3;
            yspd *= 0.3;
            change_state(PlayerState.MOVING);
        }
        break;
        
    case PlayerState.DEAD:
        death_timer++;
        xspd = 0;
        yspd = 0;
        
        // Show death menu when animation finishes
        if (image_index >= image_number - 1 && death_timer >= 60) {
            if (!instance_exists(obj_death_menu)) {
                instance_create_layer(0, 0, "Instances", obj_death_menu);
            }
            image_speed = 0;
            image_index = image_number - 1;
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
        break;
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