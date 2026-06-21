// ===== FLASH WHEN TAKING DAMAGE =====
if (npc_invincible > 0 && npc_invincible % 4 < 2) {
    gpu_set_fog(true, c_white, 0, 1);
    draw_self();
    gpu_set_fog(false, c_white, 0, 1);
} else {
    draw_self();
}

// ===== DRAW HEALTH BAR WHEN HOSTILE AND DAMAGED =====
if (is_hostile && npc_health < max_npc_health && npc_health > 0) {
    draw_set_color(c_red);
    draw_rectangle(x - 20, y - sprite_height - 10, x - 20 + (npc_health/max_npc_health) * 40, y - sprite_height - 5, false);
    draw_set_color(c_white);
    draw_rectangle(x - 20, y - sprite_height - 10, x + 20, y - sprite_height - 5, true);
}

// ===== DRAW INTERACTION INDICATOR =====
if (!is_hostile && current_state != NpcState.DEAD && current_state != NpcState.TALKING) {
    var player = instance_find(obj_player, 0);
    if (player != noone) {
        var dist = point_distance(x, y, player.x, player.y);
        if (dist <= interact_radius * 1.5) {
            draw_set_color(c_yellow);
            draw_set_halign(fa_center);
            draw_set_valign(fa_bottom);
            draw_set_font(-1);
            draw_text(x, y - sprite_height - 4, "[E]");
            draw_set_color(c_white);
            draw_set_halign(fa_left);
            draw_set_valign(fa_top);
        }
    }
}

// ===== HOSTILE INDICATOR =====
if (is_hostile && current_state != NpcState.DEAD && !dialog_active) {
    draw_set_color(c_red);
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);
    draw_set_font(-1);
    draw_text(x, y - sprite_height - 4, "!");
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
