// ===== ANIMATION HANDLING =====
if (is_animating) {
    // Check if animation finished
    if (image_index >= image_number - 1) {
        // Stay on last frame (destroyed state)
        image_index = image_number - 1; // Frame 2
        image_speed = 0;
        is_animating = false; // Animation complete
        
        // Disable collision
        is_solid = false;
        // Or alternatively, you could destroy the instance:
        // instance_destroy();
    }
}

