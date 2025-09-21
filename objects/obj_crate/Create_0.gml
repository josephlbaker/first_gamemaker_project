// ===== CRATE STATE =====
crate_health = 3; // 3 hits to destroy (matches 3 frames)
max_health = 3;
is_animating = false;
is_solid = true; // Controls collision
animation_speed = 0.2; // Slow animation

// ===== SPRITE SETUP =====
sprite_index = spr_crate;
image_index = 0; // Start on first frame (intact)
image_speed = 0; // Don't animate initially

// ===== DEPTH SORTING =====
depth = -bbox_bottom;

// ===== DAMAGE FUNCTION =====
function take_damage() {
    if (crate_health > 0 && !is_animating) {
        crate_health = 0; // Destroy in one hit
        
        // Start destruction animation
        is_animating = true;
        image_speed = animation_speed;
        image_index = 0; // Start animation from beginning
    }
}
