// ===== WALL STATE =====
wall_health = 3; // 3 hits to destroy (matches 3 frames)
max_health = 3;
is_solid = true; // Controls collision
animation_speed = 0.2; // Slow animation

// ===== SPRITE SETUP =====
sprite_index = spr_destructable_wall;
image_index = 0; // Start on first frame (intact)
image_speed = 0; // Don't animate initially

// ===== DEPTH SORTING =====
depth = -bbox_bottom;

// ===== DAMAGE FUNCTION =====
function take_damage() {
    if (wall_health > 0) {
        wall_health--;
        
        if (wall_health <= 0) {
            image_index = 2;
        } else {
            // Jump to damage frame immediately
            image_index = max_health - wall_health;
        }
    }
}
 