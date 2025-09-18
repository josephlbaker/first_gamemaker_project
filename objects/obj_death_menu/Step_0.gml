// ===== obj_death_menu STEP EVENT =====
selected_option = -1;

// Get mouse position in GUI coordinates
var gui_mouse_x = device_mouse_x_to_gui(0);
var gui_mouse_y = device_mouse_y_to_gui(0);

// Check which option mouse is hovering over
for (var i = 0; i < op_length; i++) {
    var text_x = room_width/2 - 100;  // Match your draw positions
    var text_y = 180 + op_space * i;  // Match your draw positions
    var text_width = string_width(option[i]) * 1.5;
    var text_height = string_height(option[i]) * 1.5;
    
    if (gui_mouse_x >= text_x && gui_mouse_x <= text_x + text_width &&
        gui_mouse_y >= text_y && gui_mouse_y <= text_y + text_height) {
        selected_option = i;
        
        // Handle mouse click
        if (mouse_check_button_pressed(mb_left)) {
            switch (i) {
                case 0: // Yes
					game_restart();
                    break;
                case 1: // No
                    room_goto(rm_title);
                    break;
            }
        }
        break;
    }
}