// ===== obj_title_menu STEP EVENT =====
selected_option = -1;

// Check which option mouse is hovering over
for (var i = 0; i < op_length; i++) {
    var text_x = x + width/2 - 100;
    var text_y = y + 180 + op_space * i;
    var text_width = string_width(option[i]) * 1.5; // Account for scaling
    var text_height = string_height(option[i]) * 1.5;
    
    if (mouse_x >= text_x && mouse_x <= text_x + text_width &&
        mouse_y >= text_y && mouse_y <= text_y + text_height) {
        selected_option = i;
        
        // Handle mouse click
        if (mouse_check_button_pressed(mb_left)) {
            switch (i) {
                case 0: // Continue
                    // Add your continue game logic here
                    //room_goto(rm_game_continue);
					room_goto(rm_outdoors);
                    break;
                case 1: // New Game
                    // Add your new game logic here
					room_goto(rm_outdoors);
                    break;
                case 2: // Settings
                    show_message("Settings clicked!");
                    // Add your settings logic here
                    // room_goto(rm_settings);
                    break;
                case 3: // Exit Game
                    game_end();
                    break;
            }
        }
        break; // Exit loop once we found the hovered option
    }
}