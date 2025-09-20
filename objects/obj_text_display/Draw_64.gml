// Draw text box background
var text_x = display_get_gui_width() / 2;
var text_y = display_get_gui_height() - 100;
var box_width = 400;
var box_height = 80;

// Draw background box
draw_set_color(c_black);
draw_set_alpha(0.8);
draw_rectangle(text_x - box_width/2, text_y - box_height/2, 
               text_x + box_width/2, text_y + box_height/2, false);

// Draw border
draw_set_color(c_white);
draw_set_alpha(1);
draw_rectangle(text_x - box_width/2, text_y - box_height/2, 
               text_x + box_width/2, text_y + box_height/2, true);

// Draw text
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_text_ext(text_x, text_y, text_to_show, 20, box_width - 20);

// Draw instruction
draw_set_color(c_gray);
draw_text(text_x, text_y + 30, "Press E to close");

// Reset draw settings
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);