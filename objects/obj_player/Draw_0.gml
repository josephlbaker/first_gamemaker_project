// Draw shadow at player's feet
draw_sprite(spr_shadow, 0, x, bbox_bottom);

// Flash white when taking damage (without custom shader)
if (invincible > 0 && invincible % 6 < 3) {
    // Draw white flash by blending
    gpu_set_fog(true, c_white, 0, 1);
    draw_self();
    gpu_set_fog(false, c_white, 0, 1);
} else {
    draw_self();
}