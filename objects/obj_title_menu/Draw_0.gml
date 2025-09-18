//obj_title_menu draw event

//draw_sprite_ext(sprite_index, image_index, x, y, width/sprite_width/height, sprite_height, 0, c_white, 1);

//draw_set_font(global.font_main);
//draw_set_valign(fa_top);
//draw_set_halign(fa_left);

//for (var i = 0; i < op_length; i++) {
//	draw_text(x + op_border, y + op_border + op_space*i, option[i]);
//}


// ===== obj_title_menu DRAW EVENT =====
// Draw background sprite if you have one
// FIXED: Corrected the sprite scaling calculation
if (sprite_exists(sprite_index)) {
    var scale_x = width / sprite_get_width(sprite_index);
    var scale_y = height / sprite_get_height(sprite_index);
    draw_sprite_ext(sprite_index, image_index, x, y, scale_x, scale_y, 0, c_white, 1);
}

// Set up text drawing
draw_set_font(-1);
draw_set_valign(fa_top);
draw_set_halign(fa_center);

// Draw title
draw_set_color(c_white);
var title_text = "MY GAME";
draw_text_transformed(x + width/2, y + 80, title_text, 2, 2, 0); // Scale 2x for bigger text

// Draw menu options
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

// Reset draw settings
draw_set_color(c_white);
draw_set_font(-1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);