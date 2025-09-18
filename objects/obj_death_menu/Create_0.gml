// ===== obj_death_menu CREATE EVENT =====
width = 2560;
height = 1440;
op_border = 8;
op_space = 32;
option[0] = "Yes";
option[1] = "No";
op_length = array_length(option);
selected_option = -1; // Track which option is selected (-1 = none)

// Center the death menu on screen
x = 0;
y = 0;

// Make sure it draws on top
depth = -9999;

//show_debug_message("Death menu created successfully!");

// ===== VIEWPORT/CAMERA SETUP =====
// Set up viewport for 2560x1440 screen with 640x360 game size
//camera_set_view_size(view_camera[0], 640, 360);
//view_set_wport(0, 2560);
//view_set_hport(0, 1440);
//view_enabled = true;
//view_visible[0] = true;