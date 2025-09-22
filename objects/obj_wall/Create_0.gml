// ===== DEPTH SORTING =====
// Set depth based on position for proper layering
depth = -bbox_bottom;

// ===== LAYER VISIBILITY CHECK =====
// Hide the instance if layer is not visible
if (!layer_get_visible(layer)) {
    visible = false;
} else {
    visible = true;
}
