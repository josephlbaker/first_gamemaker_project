// Get current frame from animation system
var current_frame = get_current_frame();

// Check if current animation should be flipped horizontally
var flip_horizontal = current_anim.flip_h;
var x_scale = flip_horizontal ? -1 : 1;

// Flash white when taking damage
var should_flash = (invincible > 0 && invincible % 6 < 3);

if (should_flash) {
    gpu_set_fog(true, c_white, 0, 1);
}

// Draw base player sprite
draw_sprite_ext(base_sprite, current_frame, x, y, x_scale, 1, 0, c_white, 1);

// Draw equipment layers (in order from bottom to top)
// Feet layer (boots/shoes)
if (equipment.feet != undefined) {
    draw_sprite_ext(equipment.feet, current_frame, x, y, x_scale, 1, 0, c_white, 1);
}

// Legs layer (pants/leg armor)
if (equipment.legs != undefined) {
    draw_sprite_ext(equipment.legs, current_frame, x, y, x_scale, 1, 0, c_white, 1);
}

// Chest layer (shirts/chest armor)
if (equipment.chest != undefined) {
    draw_sprite_ext(equipment.chest, current_frame, x, y, x_scale, 1, 0, c_white, 1);
}

// Hands layer (gloves/gauntlets)
if (equipment.hands != undefined) {
    draw_sprite_ext(equipment.hands, current_frame, x, y, x_scale, 1, 0, c_white, 1);
}

// Head layer (helmets/hats)
if (equipment.head != undefined) {
    draw_sprite_ext(equipment.head, current_frame, x, y, x_scale, 1, 0, c_white, 1);
}

// Accessories layer (capes, belts, bags)
if (equipment.accessories != undefined) {
    draw_sprite_ext(equipment.accessories, current_frame, x, y, x_scale, 1, 0, c_white, 1);
}

// Tools layer (held items like pickaxe, shovel)
if (equipment.tools != undefined) {
    draw_sprite_ext(equipment.tools, current_frame, x, y, x_scale, 1, 0, c_white, 1);
}

// Weapons layer (swords, bows, etc)
if (equipment.weapons != undefined) {
    draw_sprite_ext(equipment.weapons, current_frame, x, y, x_scale, 1, 0, c_white, 1);
}

// Player mount layer (riding animals/vehicles)
if (equipment.player_mount != undefined) {
    draw_sprite_ext(equipment.player_mount, current_frame, x, y, x_scale, 1, 0, c_white, 1);
}

if (should_flash) {
    gpu_set_fog(false, c_white, 0, 1);
}

// DEBUG: Draw attack hitbox when attacking (remove in final game)
//if (current_state == PlayerState.ATTACKING) {
//    // Calculate hitbox dimensions based on facing direction
//    var attack_left, attack_top, attack_right, attack_bottom;
    
//    switch (face) {
//        case RIGHT:
//            attack_left = x - hitbox_height/2;
//            attack_top = y - hitbox_width/2;
//            attack_right = x + hitbox_height + hitbox_height;
//            attack_bottom = y + hitbox_width/2;
//            break;
//        case LEFT:
//            attack_left = x - hitbox_height - hitbox_height;
//            attack_top = y - hitbox_width/2;
//            attack_right = x + hitbox_height/2;
//            attack_bottom = y + hitbox_width/2;
//            break;
//        case DOWN:
//            attack_left = x - hitbox_width/2;
//            attack_top = y - hitbox_height/2;
//            attack_right = x + hitbox_width/2;
//            attack_bottom = y + hitbox_height + hitbox_height;
//            break;
//        case UP:
//            attack_left = x - hitbox_width/2;
//            attack_top = y - hitbox_height - hitbox_height;
//            attack_right = x + hitbox_width/2;
//            attack_bottom = y + hitbox_height/2;
//            break;
//    }
    
//    draw_set_alpha(0.3);
//    draw_set_color(c_red);
//    draw_rectangle(attack_left, attack_top, attack_right, attack_bottom, false);
//    draw_set_alpha(1);
//    draw_set_color(c_white);
//}