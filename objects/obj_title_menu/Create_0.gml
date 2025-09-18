// ===== obj_title_menu CREATE EVENT =====
width = 640;
height = 360;
op_border = 8;
op_space = 32; // Increased spacing for better visibility
option[0] = "Continue";
option[1] = "New Game";
option[2] = "Settings";
option[3] = "Exit Game"; // Added exit option
op_length = array_length(option);
selected_option = -1; // Track which option is selected

// Position the menu object at (0,0) or center of room
x = 0;
y = 0;

// ===== VIEWPORT/CAMERA SETUP =====
// Set up viewport for 2560x1440 screen with 640x360 game size
camera_set_view_size(view_camera[0], 640, 360);
view_set_wport(0, 2560);
view_set_hport(0, 1440);
view_enabled = true;
view_visible[0] = true;