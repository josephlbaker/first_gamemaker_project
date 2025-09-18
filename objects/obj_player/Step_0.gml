var right_key = keyboard_check(ord("D"));
var left_key = keyboard_check(ord("A"));
var down_key = keyboard_check(ord("S"));
var up_key = keyboard_check(ord("W"));
var toggle_walk = keyboard_check_pressed(ord("T"));
var dash_pressed = keyboard_check_pressed(vk_space);
var attack_pressed = mouse_check_button_pressed(mb_left);


// Handle invincibility frames
if (invincible > 0) {
    invincible--;
}


//handle death
if (player_health <= 0 && !is_dead) {
    is_dead = true;
    death_timer = 0; // Reset timer
    show_debug_message("Player died! Health: " + string(player_health));
    
    // Set death sprite based on facing direction
    switch (face) {
        case RIGHT: sprite_index = spr_player_death_down; break;
        case LEFT: sprite_index = spr_player_death_down; break;
        case DOWN: sprite_index = spr_player_death_down; break;
        case UP: sprite_index = spr_player_death_down; break;
    }
    
    image_index = 0;
    
    // Stop all movement
    xspd = 0;
    yspd = 0;
}


// Handle death state
if (is_dead) {
    death_timer++;
    xspd = 0;
    yspd = 0;
    
    // Show death menu when death animation finishes
    if (image_index >= image_number - 1 && death_timer >= 60) {
        // Create death menu if it doesn't exist (ONLY ONCE)
        if (!instance_exists(obj_death_menu)) {
            var menu = instance_create_layer(0, 0, "Instances", obj_death_menu);
        }
        // Stop the death animation from looping
        image_speed = 0;
        image_index = image_number - 1; // Keep on last frame
    }
    
    // Exit early to prevent other player actions
    exit;
}


// Handle dash trigger
if (dash_pressed && cooldown_timer <= 0 && !is_dashing && !is_attacking) {
    is_dashing = true;
    dash_timer = dash_duration;
    
    // Store dash direction based on input or current facing
    dash_dir_x = right_key - left_key;
    dash_dir_y = down_key - up_key;
    
    // If no input, dash in the direction player is facing
    if (dash_dir_x == 0 && dash_dir_y == 0) {
        switch (face) {
            case RIGHT: dash_dir_x = 1; break;
            case LEFT: dash_dir_x = -1; break;
            case DOWN: dash_dir_y = 1; break;
            case UP: dash_dir_y = -1; break;
        }
    }
}


// Toggle walk mode
if (toggle_walk) {
    is_walking = !is_walking;
}


//pause
if instance_exists(obj_pauser)
	{
		xspd = 0;
		yspd = 0;
	}


// Handle attack trigger
if (attack_pressed && !is_attacking && !is_dashing) { // Prevent attacking while dashing
    is_attacking = true;
    switch (face) {
        case RIGHT: sprite_index = spr_player_attack1_right; break;
        case LEFT: sprite_index = spr_player_attack1_left; break;
        case DOWN: sprite_index = spr_player_attack1_down; break;
        case UP: sprite_index = spr_player_attack1_up; break;
    }
    image_index = 0; // Start the attack animation from the beginning
    
    // Check for enemies in attack range when attack starts
    var attack_reach = 64; // Attack range
    var enemies = ds_list_create();
    
    // Find all enemies within attack range
    collision_circle_list(x, y, attack_reach, obj_enemy, false, true, enemies, false);
    
    // Damage all enemies in range
    for (var i = 0; i < ds_list_size(enemies); i++) {
        var enemy = ds_list_find_value(enemies, i);
        
        // Check if enemy is in the direction we're facing
        var enemy_dir = point_direction(x, y, enemy.x, enemy.y);
        var attack_dir = 0;
        
        switch (face) {
            case RIGHT: attack_dir = 0; break;
            case DOWN: attack_dir = 270; break;
            case LEFT: attack_dir = 180; break;
            case UP: attack_dir = 90; break;
        }
        
        // Check if enemy is roughly in the attack direction (within 90 degrees)
        var dir_diff = abs(angle_difference(enemy_dir, attack_dir));
        
        if (dir_diff <= 45 && enemy.enemy_invincible <= 0) { // 90 degree attack arc
            // Deal damage to enemy
            enemy.enemy_health -= 25; // Player attack damage
            enemy.enemy_invincible = enemy.max_enemy_invincible;
            
            show_debug_message("Hit enemy! Enemy health: " + string(enemy.enemy_health));
        }
    }
    
    ds_list_destroy(enemies);
}


// Update dash with smooth easing
if (is_dashing) {
    // Calculate progress (0 to 1)
    var progress = 1 - (dash_timer / dash_duration);
    
    // Ease out formula (starts fast, slows down smoothly)
    var ease_factor = 1 - power(1 - progress, 3);
    
    // Apply eased speed - starts at full speed, reduces to 20% by end
    var current_dash_speed = dash_speed * (1 - ease_factor * 0.6);
    
    xspd = dash_dir_x * current_dash_speed;
    yspd = dash_dir_y * current_dash_speed;
    
    dash_timer--;
    if (dash_timer <= 0) {
        is_dashing = false;
        cooldown_timer = cooldown_duration;
        
        // Smooth transition - keep some momentum
        xspd *= 0.3;
        yspd *= 0.3;
    }
}

// Update cooldown timer
if (cooldown_timer > 0) {
    cooldown_timer--;
}


// Get player speed (only if not dashing or paused)
if (!is_dashing && !instance_exists(obj_pauser)) {
    var speed_modifier = is_attacking ? 0.5 : 1;
    var base_speed = is_walking ? move_speed / 2 : move_speed;
    var current_speed = base_speed * speed_modifier;
    
    xspd = (right_key - left_key) * current_speed;
    yspd = (down_key - up_key) * current_speed;
    
    // Simple diagonal correction - only when both inputs are pressed
    if (abs(xspd) > 0 && abs(yspd) > 0) {
        xspd *= 1/sqrt(2); // 1/sqrt(2) as a constant
        yspd *= 1/sqrt(2);
    }
}


//set player facing down to start
mask_index = sprite[DOWN];


//detect if player hit wall
if place_meeting(x + xspd, y, obj_wall) == true
	{
		xspd = 0;
	}
if place_meeting(x, y + yspd, obj_wall) == true
	{
		yspd = 0;
	}


//calculate player movements (only if not attacking; during attack, keep attack sprite)
if (!is_attacking) {
    if (xspd != 0 || yspd != 0) {
        if (xspd > 0) {
            sprite_index = is_dashing ? spr_player_dash_right : (is_walking ? spr_player_walk_right : spr_player_run_right);
            face = RIGHT;
        } else if (xspd < 0) {
            sprite_index = is_dashing ? spr_player_dash_left : (is_walking ? spr_player_walk_left : spr_player_run_left);
            face = LEFT;
        } else if (yspd > 0) {
            sprite_index = is_dashing ? spr_player_dash_down : (is_walking ? spr_player_walk_down : spr_player_run_down);
            face = DOWN;
        } else if (yspd < 0) {
            sprite_index = is_dashing ? spr_player_dash_up : (is_walking ? spr_player_walk_up : spr_player_run_up);
            face = UP;
        }
    } else {
        if (face == DOWN)
            sprite_index = spr_player_idle_down;
        else if (face == LEFT) sprite_index = spr_player_idle_left;
        else if (face == RIGHT) sprite_index = spr_player_idle_right;
        else if (face == UP) sprite_index = spr_player_idle_up;
    }
} else {
    // During attack, check if animation is done
    if (image_index >= image_number - 1) {
        is_attacking = false;
        // Reset to idle sprite based on face (or movement if moving)
        if (xspd == 0 && yspd == 0) {
            switch (face) {
                case RIGHT: sprite_index = spr_player_idle_right; break;
                case LEFT: sprite_index = spr_player_idle_left; break;
                case DOWN: sprite_index = spr_player_idle_down; break;
                case UP: sprite_index = spr_player_idle_up; break;
            }
            image_index = 0;
        } else {
            // If moving after attack, switch to appropriate movement sprite
            if (xspd > 0) {
                sprite_index = is_dashing ? spr_player_dash_right : (is_walking ? spr_player_walk_right : spr_player_run_right);
            } else if (xspd < 0) {
                sprite_index = is_dashing ? spr_player_dash_left : (is_walking ? spr_player_walk_left : spr_player_run_left);
            } else if (yspd > 0) {
                sprite_index = is_dashing ? spr_player_dash_down : (is_walking ? spr_player_walk_down : spr_player_run_down);
            } else if (yspd < 0) {
                sprite_index = is_dashing ? spr_player_dash_up : (is_walking ? spr_player_walk_up : spr_player_run_up);
            }
        }
    }
}


//move the player
x += xspd;
y += yspd;


//animate
//if xspd == 0 && yspd == 0 && !is_attacking {
//	image_index = 0;
//}


//depth
depth = -bbox_bottom;