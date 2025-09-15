draw_text(10, 10, "Health: " + string(player_health));


// Flash white when taking damage (without custom shader)
if (invincible > 0 && invincible % 6 < 3) {
    // Draw white flash by blending
    gpu_set_fog(true, c_white, 0, 1);
    draw_self();
    gpu_set_fog(false, c_white, 0, 1);
} else {
    draw_self();
}