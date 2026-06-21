// ===== DRAW STRANDED PLAYER =====
// sprite_index / image_index / image_xscale are set each Step, so we draw from those.

var spr   = sprite_index;
var frame = image_index;

// White hit-flash when recently damaged (skipped during a dodge roll so i-frames read as a dodge).
var is_rolling   = (current_state == StrandedState.ROLLING);
var should_flash = (invincible > 0 && !is_rolling && (invincible mod 6 < 3));

if (should_flash) {
    gpu_set_fog(true, c_white, 0, 1);
    draw_sprite_ext(spr, frame, x, y, image_xscale, image_yscale, image_angle, c_white, image_alpha);
    gpu_set_fog(false, c_white, 0, 1);
} else if (is_rolling) {
    // Subtle translucent streak while dodging to telegraph the i-frame window.
    draw_sprite_ext(spr, frame, x, y, image_xscale, image_yscale, image_angle, c_white, 0.8);
} else {
    draw_sprite_ext(spr, frame, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
}

// ---- DEBUG: visualize the attack hitbox (uncomment while tuning combat) ----
//if (current_state == StrandedState.SLASHING || current_state == StrandedState.CHOPPING) {
//    var dl, dt, dr, db;
//    switch (face) {
//        case RIGHT: dl = x - hitbox_height/2; dt = y - hitbox_width/2; dr = x + attack_reach;     db = y + hitbox_width/2; break;
//        case LEFT:  dl = x - attack_reach;    dt = y - hitbox_width/2; dr = x + hitbox_height/2;  db = y + hitbox_width/2; break;
//        case DOWN:  dl = x - hitbox_width/2;  dt = y - hitbox_height/2; dr = x + hitbox_width/2;  db = y + attack_reach;   break;
//        case UP:    dl = x - hitbox_width/2;  dt = y - attack_reach;    dr = x + hitbox_width/2;  db = y + hitbox_height/2; break;
//    }
//    draw_set_alpha(0.3); draw_set_color(c_red);
//    draw_rectangle(dl, dt, dr, db, false);
//    draw_set_alpha(1); draw_set_color(c_white);
//}
