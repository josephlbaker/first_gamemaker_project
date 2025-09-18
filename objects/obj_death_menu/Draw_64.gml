// ===== obj_death_menu DRAW EVENT =====
// Draw black overlay
draw_set_color(c_black);
draw_rectangle(0, 0, room_width, room_height, false);

// Set up text drawing (exactly like your working title menu)
draw_set_font(-1);
draw_set_valign(fa_top);
draw_set_halign(fa_center);

// Draw "You Died" message
draw_set_color(c_red);
var death_text = "YOU DIED";
draw_text_transformed(x + width/2, y + 80, death_text, 2, 2, 0); // Scale 3x for bigger text

// Draw "Continue?" text
draw_set_color(c_white);
var continue_text = "Continue?";
draw_text_transformed(x + width/2, y + 100, continue_text, 2, 2, 0);

// Draw menu options (exactly like your working title menu)
draw_set_halign(fa_left);
for (var i = 0; i < op_length; i++) {
    var text_x = x + width/2 - 100; // Center the menu horizontally
    var text_y = y + 180 + op_space * i; // Start menu lower on screen
    
    // Highlight selected option
    if (i == selected_option) {
        draw_set_color(c_yellow);
        draw_text_transformed(text_x - 30, text_y, "> ", 1.5, 1.5, 0);
        draw_text_transformed(text_x, text_y, option[i], 1.5, 1.5, 0);
    } else {
        draw_set_color(c_white);
        draw_text_transformed(text_x, text_y, option[i], 1.5, 1.5, 0);
    }
}

// Debug - draw collision boxes
//draw_set_alpha(0.3);
//draw_set_color(c_lime);
//for (var i = 0; i < op_length; i++) {
//    var text_x = room_width/2 - 100;
//    var text_y = 230 + op_space * i;
//    var text_width = string_width(option[i]) * 1.5;
//    var text_height = string_height(option[i]) * 1.5;
//    draw_rectangle(text_x, text_y, text_x + text_width, text_y + text_height, false);
//}
//draw_set_alpha(1);

//// Show mouse position
//draw_set_color(c_yellow);
//draw_text(10, 30, "Mouse: " + string(mouse_x) + ", " + string(mouse_y));

// Reset draw settings
draw_set_color(c_white);
draw_set_font(-1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_alpha(1);