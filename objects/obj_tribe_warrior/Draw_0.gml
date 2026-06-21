// ===== DRAW TRIBE WARRIOR =====
// sprite_index / image_index / image_xscale are maintained in the Step event.

// White hit-flash while in i-frames after being struck.
if (warrior_invincible > 0 && warrior_invincible mod 4 < 2) {
    gpu_set_fog(true, c_white, 0, 1);
    draw_self();
    gpu_set_fog(false, c_white, 0, 1);
} else {
    draw_self();
}

// Floating health bar above the head (only once damaged and still alive).
if (warrior_health < max_warrior_health && warrior_health > 0) {
    var bar_w = 40;
    var bar_h = 5;
    var bx = x - bar_w / 2;
    var by = y - sprite_height * 0.6 - 6;
    var ratio = clamp(warrior_health / max_warrior_health, 0, 1);

    draw_set_color(c_black);
    draw_rectangle(bx - 1, by - 1, bx + bar_w + 1, by + bar_h + 1, false);
    draw_set_color(c_red);
    draw_rectangle(bx, by, bx + bar_w * ratio, by + bar_h, false);
    draw_set_color(c_white);
    draw_rectangle(bx, by, bx + bar_w, by + bar_h, true);
    draw_set_color(c_white);
}

// ---- DEBUG: attack hitbox (uncomment while tuning) ----
//if (current_state == TribeState.ATTACKING) {
//    var dl, dt, dr, db;
//    switch (face) {
//        case RIGHT: dl = x - hitbox_height/2; dt = y - hitbox_width/2; dr = x + attack_reach;    db = y + hitbox_width/2; break;
//        case LEFT:  dl = x - attack_reach;    dt = y - hitbox_width/2; dr = x + hitbox_height/2; db = y + hitbox_width/2; break;
//        case DOWN:  dl = x - hitbox_width/2;  dt = y - hitbox_height/2; dr = x + hitbox_width/2; db = y + attack_reach;   break;
//        case UP:    dl = x - hitbox_width/2;  dt = y - attack_reach;    dr = x + hitbox_width/2; db = y + hitbox_height/2; break;
//    }
//    draw_set_alpha(0.3); draw_set_color(c_red);
//    draw_rectangle(dl, dt, dr, db, false);
//    draw_set_alpha(1); draw_set_color(c_white);
//}
