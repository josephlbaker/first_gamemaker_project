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