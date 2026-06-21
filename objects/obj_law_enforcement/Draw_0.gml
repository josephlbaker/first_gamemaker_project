// ===== FLASH WHEN TAKING DAMAGE =====
if (law_invincible > 0 && law_invincible % 4 < 2) {
    gpu_set_fog(true, c_white, 0, 1);
    draw_self();
    gpu_set_fog(false, c_white, 0, 1);
} else {
    draw_self();
}

// ===== DRAW HEALTH BAR =====
if (law_health < max_law_health && law_health > 0) {
    draw_set_color(c_red);
    draw_rectangle(x - 20, y - sprite_height - 10, x - 20 + (law_health/max_law_health) * 40, y - sprite_height - 5, false);
    draw_set_color(c_white);
    draw_rectangle(x - 20, y - sprite_height - 10, x + 20, y - sprite_height - 5, true);
}

// ===== DRAW WARNING INDICATOR =====
if (current_state != LawState.DEAD) {
    draw_set_color(c_red);
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);
    draw_set_font(-1);
    draw_text(x, y - sprite_height - 12, "GUARD");
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
