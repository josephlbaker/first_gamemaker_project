// Flash white when taking damage
if (enemy_invincible > 0 && enemy_invincible % 4 < 2) {
    // Flash effect during invincibility
    gpu_set_fog(true, c_white, 0, 1);
    draw_self();
    gpu_set_fog(false, c_white, 0, 1);
} else {
    draw_self();
}

// Optional: Draw enemy health bar above enemy
if (enemy_health < max_enemy_health && enemy_health > 0) {
    draw_set_color(c_red);
    draw_rectangle(x - 20, y - sprite_height - 10, x - 20 + (enemy_health/max_enemy_health) * 40, y - sprite_height - 5, false);
    draw_set_color(c_white);
    draw_rectangle(x - 20, y - sprite_height - 10, x + 20, y - sprite_height - 5, true);
}

// DEBUG: Draw attack hitbox when attacking (remove in final game)
//if (current_state == EnemyState.ATTACKING) {
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