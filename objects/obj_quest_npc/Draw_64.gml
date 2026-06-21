if (!dialog_active) exit;

var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

var box_x = gui_w / 2;
var box_y = gui_h - 100;
var box_width = 500;
var box_height = 90;

// Background
draw_set_color(c_black);
draw_set_alpha(0.85);
draw_rectangle(box_x - box_width/2, box_y - box_height/2,
               box_x + box_width/2, box_y + box_height/2, false);

// Border color based on hostility
if (is_hostile) {
    draw_set_color(c_red);
} else {
    draw_set_color(c_white);
}
draw_set_alpha(1);
draw_rectangle(box_x - box_width/2, box_y - box_height/2,
               box_x + box_width/2, box_y + box_height/2, true);

// NPC name
draw_set_halign(fa_left);
draw_set_valign(fa_top);
if (is_hostile) {
    draw_set_color(c_red);
} else {
    draw_set_color(c_yellow);
}
draw_text(box_x - box_width/2 + 10, box_y - box_height/2 + 6, "Quest NPC");

// Separator line under name
var sep_y = box_y - box_height/2 + 22;
draw_set_color(c_dkgray);
draw_line(box_x - box_width/2 + 8, sep_y, box_x + box_width/2 - 8, sep_y);

// Dialog text
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
if (dialog_index < array_length(dialog_lines)) {
    draw_text_ext(box_x - box_width/2 + 12, sep_y + 6,
                  dialog_lines[dialog_index], 18, box_width - 24);
}

// Prompt at bottom-right
draw_set_halign(fa_right);
draw_set_valign(fa_bottom);
draw_set_color(c_gray);

if (dialog_index < array_length(dialog_lines) - 1) {
    draw_text(box_x + box_width/2 - 10, box_y + box_height/2 - 6, "E  >>>");
} else {
    draw_text(box_x + box_width/2 - 10, box_y + box_height/2 - 6, "E  [close]");
}

// Reset
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
