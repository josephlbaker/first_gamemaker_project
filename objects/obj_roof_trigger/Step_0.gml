// Check if player is inside the house (trigger area)
var player_inside = place_meeting(x, y, obj_player);

if (player_inside && !fade_state) {
    // Player JUST Entered -> Remove Roof Tiles
    fade_state = true;
    
    var cols = ds_grid_width(stored_tiles);
    var rows = ds_grid_height(stored_tiles);
    
    for (var c = 0; c < cols; c++) {
        for (var r = 0; r < rows; r++) {
            // Set tile to 0 (Empty) to make it disappear
            tilemap_set(tilemap_id, 0, start_col + c, start_row + r);
        }
    }
}
else if (!player_inside && fade_state) {
    // Player JUST Left -> Restore Roof Tiles
    fade_state = false;
    
    var cols = ds_grid_width(stored_tiles);
    var rows = ds_grid_height(stored_tiles);
    
    for (var c = 0; c < cols; c++) {
        for (var r = 0; r < rows; r++) {
            // Retrieve original tile data and restore it
            var data = ds_grid_get(stored_tiles, c, r);
            tilemap_set(tilemap_id, data, start_col + c, start_row + r);
        }
    }
}