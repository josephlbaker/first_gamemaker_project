// Settings
target_layer = "DisappearingRoof"; // The name of your tile layer in the Room Editor
fade_state = false; // false = visible, true = hidden

// Get the tilemap ID from the layer
var lay_id = layer_get_id(target_layer);
tilemap_id = layer_tilemap_get_id(lay_id);

// Get tile dimensions
var cell_width = tilemap_get_tile_width(tilemap_id);
var cell_height = tilemap_get_tile_height(tilemap_id);

// Calculate the grid coordinates this trigger covers
start_col = floor(bbox_left / cell_width);
start_row = floor(bbox_top / cell_height);
end_col = floor(bbox_right / cell_width);
end_row = floor(bbox_bottom / cell_height);

var cols = end_col - start_col + 1;
var rows = end_row - start_row + 1;

// Create a grid to store the original roof tiles
stored_tiles = ds_grid_create(cols, rows);

// Save the roof tiles currently on the map
for (var c = 0; c < cols; c++) {
    for (var r = 0; r < rows; r++) {
        // Get tile data at this position
        var tile_data = tilemap_get(tilemap_id, start_col + c, start_row + r);
        // Store it
        ds_grid_set(stored_tiles, c, r, tile_data);
    }
}