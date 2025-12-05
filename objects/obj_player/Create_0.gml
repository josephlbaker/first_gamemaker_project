// ===================================================================================================
// PLAYER ANIMATION & EQUIPMENT SYSTEM
// ===================================================================================================
// This player object uses a unified sprite sheet (spr_new_player) with 501 frames
// organized into rows of 9 frames per row. Each row represents a different animation state.
//
// ANIMATION SYSTEM:
// - All animations are defined in the 'anim' struct with start_frame and frame_count
// - Use set_animation(anim.animation_name) to change animations
// - Animation frames automatically advance based on anim_speed
// - Current frame is calculated as: start_frame + floor(anim_frame)
//
// AVAILABLE ANIMATIONS (9 frames per row):
// More animations will be added later
// 
// BASIC MOVEMENT:
// - Idle (4 directions) - 6 frames each
// - Running (4 directions) - 6 frames each
// - Rolling (4 directions) - 8 frames each
//
// COMBAT:
// - Slash 1/2/3 (3-stage combo, 4 directions) - 4 frames each
// - Death - 4 frames
//
// MOUNT:
// - Horse Idle (4 directions) - 2 frames each
// - Horse Run (4 directions) - 6 frames each
//
// SPRITE MIRRORING:
// - LEFT animations mirror RIGHT animations (flip_h: true)
// - Only 3 unique directions stored per animation: down, up, right
// - Left direction reuses right frames with horizontal flipping
// - This reduces sprite sheet size by ~25% and ensures perfect symmetry
//
// ATTACK COMBO SYSTEM:
// - Three-stage melee combo (attack1, attack2, attack3)
// - Window of 0.5 seconds (30 frames) to input next attack in combo
// - Combo resets after stage 3 or if window expires
// - Each stage has 4 frames for snappy, responsive combat feel
//
// EQUIPMENT/CLOTHING SYSTEM:
// - Equipment is layered on top of the base player sprite
// - Each layer (chest, head, legs, etc.) should use the SAME frame layout as the base sprite
// - To equip an item: equipment.chest = spr_royal_shirt;
// - To remove an item: equipment.chest = noone;
// - Draw order (bottom to top): feet -> legs -> chest -> hands -> head -> accessories -> tools -> weapons -> mount
//
// ADDING NEW EQUIPMENT:
// 1. Import your sprite with 501 frames (same dimensions: 64x64, 9 frames per row)
// 2. Match the frame layout of spr_new_player
// 3. Set the equipment slot in the equipment struct
//
// ANIMATION SPEED:
// - Adjust anim_speed to change how fast animations play (default: 0.15)
// - Higher values = faster animations
//
// USING ANIMATIONS IN GAMEPLAY:
// - Basic: set_animation(anim.run_down) or set_animation(anim.idle_right)
// - Combat: set_animation(anim.slash_1_down) for slash combo (slash_1, slash_2, slash_3)
// - Tools: set_animation(anim.chop_right) or set_animation(anim.fish_down)
// - Items: set_animation(anim.hold_run_up) for carrying objects
// - Jumping: set_animation(anim.jump_start) -> jump_air -> jump_land
// - Switch tools/weapons by changing equipment.tools or equipment.weapons sprite
//
// EXAMPLE USAGE:
// // Fishing action
// if (keyboard_check_pressed(ord("F"))) {
//     set_animation(anim.fish_down);
// }
//
// // Picking up item
// if (near_item && keyboard_check_pressed(ord("E"))) {
//     set_animation(anim.pickup_down);
// }
//
// // Holding lantern while moving
// if (is_dark && moving) {
//     equipment.tools = spr_lantern;
//     set_animation(anim.hold_run_down);
// }
// ===================================================================================================

// ===== PLAYER STATE ENUM =====
enum PlayerState {
    IDLE,
    MOVING,
    ATTACKING,
    DASHING,
    DEAD,
    PAUSED
}

// Initialize state
current_state = PlayerState.IDLE;
previous_state = PlayerState.IDLE;

// ===== MOVEMENT VARIABLES =====
xspd = 0;
yspd = 0;
move_speed = 2;
horse_speed = 4;  // Speed when mounted on horse
is_walking = false;

// ===== DASH VARIABLES =====
dash_speed = 25;
dash_timer = 0;
cooldown_timer = 0;
dash_duration = .25 * game_get_speed(gamespeed_fps);
cooldown_duration = .1 * game_get_speed(gamespeed_fps);
dash_dir_x = 0;
dash_dir_y = 0;

// ===== HEALTH VARIABLES =====
player_health = 100;
max_health = 100;
invincible = 0;
max_invincible = 30;

// ===== DEATH VARIABLES =====
death_timer = 0;

// ===== COMBAT VARIABLES =====
attack_damage = 25;
attack_reach = 64;
hitbox_width = 42;
hitbox_height = 16;

// Attack combo system
attack_combo_stage = 1;        // Current combo stage (1, 2, or 3)
attack_combo_timer = 0;        // Timer for combo window
attack_combo_window = 30;      // Frames to input next attack in combo (0.5 seconds at 60fps)

// ===== SPRITE MANAGEMENT =====
face = DOWN;

// Base sprite (will be used for all animations)
base_sprite = spr_new_player;

// ===== CLOTHING/EQUIPMENT LAYERS =====
// Each equipment slot can be set to a sprite or undefined
// To add equipment: equipment.chest = spr_your_sprite;
// To remove equipment: equipment.chest = undefined;
equipment = {
    accessories: spr_farmer_hat,    // Accessories like belts, bags, etc
    chest: spr_farmer_shirt_red,          // Chest armor/clothing
    feet: spr_brown_boots,           // Boots/shoes
    hands: spr_hands_bare,          // Gloves/gauntlets
    head: spr_hair_1_brown,           // Helmets/hats
    legs: spr_farmer_pants,           // Pants/leg armor
    tools: undefined,          // Tools held (pickaxe, shovel, etc)
    weapons: undefined,        // Weapons held
    player_mount: undefined    // Mount/vehicle
};

// ===== ANIMATION FRAME MAPPING =====
// Each animation has a start_frame, frame_count, and flip_h (for mirroring)
// Based on sprite sheet with 9 frames per row
// LEFT animations mirror RIGHT animations (flip_h: true)
// More animations will be added later
anim = {
    // ===== IDLE =====
    idle_down:      { start_frame: 0,   frame_count: 6, flip_h: false },
    idle_right:     { start_frame: 9,   frame_count: 6, flip_h: false },
    idle_left:      { start_frame: 9,   frame_count: 6, flip_h: true },
    idle_up:        { start_frame: 18,  frame_count: 6, flip_h: false },
    
    // ===== RUNNING =====
    run_down:       { start_frame: 27,  frame_count: 6, flip_h: false },
    run_right:      { start_frame: 36,  frame_count: 6, flip_h: false },
    run_left:       { start_frame: 36,  frame_count: 6, flip_h: true },
    run_up:         { start_frame: 45,  frame_count: 6, flip_h: false },
    
    // ===== SLASH (3-Stage Combo) =====
    // Down Direction
    slash_1_down:   { start_frame: 54,  frame_count: 4, flip_h: false },
    slash_2_down:   { start_frame: 63,  frame_count: 4, flip_h: false },
    slash_3_down:   { start_frame: 72,  frame_count: 4, flip_h: false },
    // Right Direction
    slash_1_right:  { start_frame: 81,  frame_count: 4, flip_h: false },
    slash_2_right:  { start_frame: 90,  frame_count: 4, flip_h: false },
    slash_3_right:  { start_frame: 99,  frame_count: 4, flip_h: false },
    // Left Direction (mirrors Right)
    slash_1_left:   { start_frame: 81,  frame_count: 4, flip_h: true },
    slash_2_left:   { start_frame: 90,  frame_count: 4, flip_h: true },
    slash_3_left:   { start_frame: 99,  frame_count: 4, flip_h: true },
    // Up Direction
    slash_1_up:     { start_frame: 108, frame_count: 4, flip_h: false },
    slash_2_up:     { start_frame: 117, frame_count: 4, flip_h: false },
    slash_3_up:     { start_frame: 126, frame_count: 4, flip_h: false },
    
    // ===== DEATH =====
    death:          { start_frame: 135, frame_count: 4, flip_h: false },
    
    // ===== ROLLING =====
    roll_down:      { start_frame: 153, frame_count: 8, flip_h: false },
    roll_right:     { start_frame: 162, frame_count: 8, flip_h: false },
    roll_left:      { start_frame: 162, frame_count: 8, flip_h: true },
    roll_up:        { start_frame: 171, frame_count: 8, flip_h: false },
    
    // ===== HORSE IDLE =====
    horse_idle_down:  { start_frame: 450, frame_count: 2, flip_h: false },
    horse_idle_right: { start_frame: 459, frame_count: 2, flip_h: false },
    horse_idle_left:  { start_frame: 459, frame_count: 2, flip_h: true },
    horse_idle_up:    { start_frame: 468, frame_count: 2, flip_h: false },
    
    // ===== HORSE RUN =====
    horse_run_down:   { start_frame: 477, frame_count: 6, flip_h: false },
    horse_run_right:  { start_frame: 486, frame_count: 6, flip_h: false },
    horse_run_left:   { start_frame: 486, frame_count: 6, flip_h: true },
    horse_run_up:     { start_frame: 495, frame_count: 6, flip_h: false }
};

// ===== SEPARATE HORSE SPRITE ANIMATION MAPPING (spr_horse_riding) =====
// This is for the actual horse sprite drawn behind the player when mounted
horse_anim = {
    // Horse Idle
    horse_idle_down:  { start_frame: 0,  frame_count: 2, flip_h: false },
    horse_idle_right: { start_frame: 6,  frame_count: 2, flip_h: false },
    horse_idle_left:  { start_frame: 6,  frame_count: 2, flip_h: true },
    horse_idle_up:    { start_frame: 12, frame_count: 2, flip_h: false },
    
    // Horse Run
    horse_run_down:   { start_frame: 18, frame_count: 6, flip_h: false },
    horse_run_right:  { start_frame: 24, frame_count: 6, flip_h: false },
    horse_run_left:   { start_frame: 24, frame_count: 6, flip_h: true },
    horse_run_up:     { start_frame: 30, frame_count: 6, flip_h: false }
};

// Horse mounting state
is_mounted = false;
horse_sprite = spr_horse_riding;  // The separate horse sprite sheet
current_horse_anim = horse_anim.horse_idle_down;

// ===== SEPARATE SWORD SPRITE ANIMATION MAPPING (spr_sword) =====
// This is for the sword sprite drawn during attacks
sword_anim = {
    // Slash 1 (First Swing)
    slash_1_down:   { start_frame: 0,  frame_count: 3, flip_h: false },
    slash_1_right:  { start_frame: 9,  frame_count: 3, flip_h: false },
    slash_1_left:   { start_frame: 9,  frame_count: 3, flip_h: true },
    slash_1_up:     { start_frame: 18, frame_count: 3, flip_h: false },
    
    // Slash 2 (Second Swing)
    slash_2_down:   { start_frame: 3,  frame_count: 3, flip_h: false },
    slash_2_right:  { start_frame: 12, frame_count: 3, flip_h: false },
    slash_2_left:   { start_frame: 12, frame_count: 3, flip_h: true },
    slash_2_up:     { start_frame: 21, frame_count: 3, flip_h: false },
    
    // Slash 3 (Combo Finisher)
    slash_3_down:   { start_frame: 6,  frame_count: 3, flip_h: false },
    slash_3_right:  { start_frame: 15, frame_count: 3, flip_h: false },
    slash_3_left:   { start_frame: 15, frame_count: 3, flip_h: true },
    slash_3_up:     { start_frame: 24, frame_count: 3, flip_h: false }
};

// Sword state
sword_sprite = spr_sword;  // The separate sword sprite sheet
current_sword_anim = sword_anim.slash_1_down;
is_attacking = false;  // Track if currently in attack animation

// Current animation state
current_anim = anim.idle_down;
anim_frame = 0;          // Current frame within the animation (0-based)
anim_speed = 0.15;       // Animation speed (frames per step)
anim_timer = 0;          // Timer for animation

// ===== COLLISION MASK =====
// Set collision mask to base sprite
mask_index = base_sprite;

// ===== HELPER FUNCTIONS =====
// Function to set the current animation
function set_animation(animation_data) {
    if (current_anim != animation_data) {
        current_anim = animation_data;
        anim_frame = 0;
        anim_timer = 0;
    }
}

// Function to get the current sprite frame index
function get_current_frame() {
    return current_anim.start_frame + floor(anim_frame);
}

// Function to get the current horse sprite frame index
function get_current_horse_frame() {
    return current_horse_anim.start_frame + floor(anim_frame);
}

// Function to set the horse animation based on player state and direction
function update_horse_animation() {
    if (!is_mounted) return;
    
    var is_moving = (current_state == PlayerState.MOVING);
    
    if (is_moving) {
        switch (face) {
            case DOWN:  current_horse_anim = horse_anim.horse_run_down; break;
            case RIGHT: current_horse_anim = horse_anim.horse_run_right; break;
            case LEFT:  current_horse_anim = horse_anim.horse_run_left; break;
            case UP:    current_horse_anim = horse_anim.horse_run_up; break;
        }
    } else {
        switch (face) {
            case DOWN:  current_horse_anim = horse_anim.horse_idle_down; break;
            case RIGHT: current_horse_anim = horse_anim.horse_idle_right; break;
            case LEFT:  current_horse_anim = horse_anim.horse_idle_left; break;
            case UP:    current_horse_anim = horse_anim.horse_idle_up; break;
        }
    }
}

// Function to get the current sword sprite frame index
function get_current_sword_frame() {
    // Clamp to sword animation's frame count so it doesn't loop
    var sword_frame = min(floor(anim_frame), current_sword_anim.frame_count - 1);
    return current_sword_anim.start_frame + sword_frame;
}

// Function to set the sword animation based on combo stage and direction
function update_sword_animation() {
    if (current_state != PlayerState.ATTACKING) {
        is_attacking = false;
        return;
    }
    
    is_attacking = true;
    
    if (attack_combo_stage == 1) {
        switch (face) {
            case DOWN:  current_sword_anim = sword_anim.slash_1_down; break;
            case RIGHT: current_sword_anim = sword_anim.slash_1_right; break;
            case LEFT:  current_sword_anim = sword_anim.slash_1_left; break;
            case UP:    current_sword_anim = sword_anim.slash_1_up; break;
        }
    } else if (attack_combo_stage == 2) {
        switch (face) {
            case DOWN:  current_sword_anim = sword_anim.slash_2_down; break;
            case RIGHT: current_sword_anim = sword_anim.slash_2_right; break;
            case LEFT:  current_sword_anim = sword_anim.slash_2_left; break;
            case UP:    current_sword_anim = sword_anim.slash_2_up; break;
        }
    } else if (attack_combo_stage == 3) {
        switch (face) {
            case DOWN:  current_sword_anim = sword_anim.slash_3_down; break;
            case RIGHT: current_sword_anim = sword_anim.slash_3_right; break;
            case LEFT:  current_sword_anim = sword_anim.slash_3_left; break;
            case UP:    current_sword_anim = sword_anim.slash_3_up; break;
        }
    }
}

// ===== HELPER FUNCTIONS IN CREATE EVENT =====
function change_state(new_state) {
    // Store previous state before changing
    previous_state = current_state;
    current_state = new_state;
    
    // State entry logic
    switch(new_state) {
        case PlayerState.DEAD:
            death_timer = 0;
            // Set death animation
            set_animation(anim.death);
            xspd = 0;
            yspd = 0;
            show_debug_message("Player died! Health: " + string(player_health));
            break;
            
        case PlayerState.ATTACKING:
            // Set attack animation based on combo stage and facing direction
            var attack_anim = anim.slash_1_down;
            
            // 3-stage slash combo
            if (attack_combo_stage == 1) {
                switch (face) {
                    case RIGHT: attack_anim = anim.slash_1_right; break;
                    case LEFT: attack_anim = anim.slash_1_left; break;
                    case DOWN: attack_anim = anim.slash_1_down; break;
                    case UP: attack_anim = anim.slash_1_up; break;
                }
            } else if (attack_combo_stage == 2) {
                switch (face) {
                    case RIGHT: attack_anim = anim.slash_2_right; break;
                    case LEFT: attack_anim = anim.slash_2_left; break;
                    case DOWN: attack_anim = anim.slash_2_down; break;
                    case UP: attack_anim = anim.slash_2_up; break;
                }
            } else if (attack_combo_stage == 3) {
                switch (face) {
                    case RIGHT: attack_anim = anim.slash_3_right; break;
                    case LEFT: attack_anim = anim.slash_3_left; break;
                    case DOWN: attack_anim = anim.slash_3_down; break;
                    case UP: attack_anim = anim.slash_3_up; break;
                }
            }
            
            set_animation(attack_anim);
            attack_combo_timer = attack_combo_window;
            perform_attack();
            break;
            
        case PlayerState.DASHING:
            dash_timer = dash_duration;
            
            // Get current input for dash direction
            var right = keyboard_check(ord("D"));
            var left = keyboard_check(ord("A"));
            var down = keyboard_check(ord("S"));
            var up = keyboard_check(ord("W"));
            
            // Store dash direction
            dash_dir_x = right - left;
            dash_dir_y = down - up;
            
            // If no input, dash in facing direction
            if (dash_dir_x == 0 && dash_dir_y == 0) {
                switch (face) {
                    case RIGHT: dash_dir_x = 1; break;
                    case LEFT: dash_dir_x = -1; break;
                    case DOWN: dash_dir_y = 1; break;
                    case UP: dash_dir_y = -1; break;
                }
            }
            
            // Set roll animation (dash uses roll animation)
            switch (face) {
                case RIGHT: set_animation(anim.roll_right); break;
                case LEFT: set_animation(anim.roll_left); break;
                case DOWN: set_animation(anim.roll_down); break;
                case UP: set_animation(anim.roll_up); break;
            }
            break;
    }
}

function perform_attack() {
    var enemies = ds_list_create();
    var crates = ds_list_create();
    var walls = ds_list_create();
    
    // Calculate hitbox dimensions based on facing direction
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
    
    // Check for enemies
    collision_rectangle_list(
        attack_left, attack_top, attack_right, attack_bottom,
        obj_enemy, false, true, enemies, false
    );
    
    // Check for crates
    collision_rectangle_list(
        attack_left, attack_top, attack_right, attack_bottom,
        obj_crate, false, true, crates, false
    );
    
    // Check for destructible walls
    collision_rectangle_list(
        attack_left, attack_top, attack_right, attack_bottom,
        obj_destructable_wall, false, true, walls, false
    );
    
    // Damage enemies
    for (var i = 0; i < ds_list_size(enemies); i++) {
        var enemy = ds_list_find_value(enemies, i);
        
        if (enemy.enemy_invincible <= 0) {
            enemy.enemy_health -= attack_damage;
            enemy.enemy_invincible = enemy.max_enemy_invincible;
            // Add knockback
            enemy.change_state(EnemyState.HURT);
            show_debug_message("Hit enemy! Enemy health: " + string(enemy.enemy_health));
        }
    }
    
    // Damage crates
    for (var i = 0; i < ds_list_size(crates); i++) {
        var crate = ds_list_find_value(crates, i);
        crate.take_damage();
        show_debug_message("Hit crate! Crate health: " + string(crate.crate_health));
    }
    
    // Damage destructible walls
    for (var i = 0; i < ds_list_size(walls); i++) {
        var wall = ds_list_find_value(walls, i);
        wall.take_damage();
        show_debug_message("Hit destructible wall!");
    }
    
    ds_list_destroy(enemies);
    ds_list_destroy(crates);
    ds_list_destroy(walls);
}

// ===== CUSTOM COLLISION FUNCTION =====
function check_solid_collision(check_x, check_y) {
    // Check regular walls
    if (place_meeting(check_x, check_y, obj_wall)) {
        // Get list of all wall objects at this position
        var walls = ds_list_create();
        collision_point_list(check_x, check_y, obj_wall, false, true, walls, false);
        
        for (var i = 0; i < ds_list_size(walls); i++) {
            var wall = ds_list_find_value(walls, i);
            // If it's a basic wall OR a solid destructible object
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