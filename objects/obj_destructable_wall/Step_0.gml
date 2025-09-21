// ===== ANIMATION HANDLING =====
if (image_index >= image_number - 1) {
    // Stay on last frame (destroyed state)
    image_index = image_number - 1;
    image_speed = 0;
    is_solid = false;
    // Could add destruction effects here or destroy the instance
}

