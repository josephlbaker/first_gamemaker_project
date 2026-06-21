// ===== STRANDED PLAYER HUD =====
draw_set_font(-1);

var bar_x   = 16;
var bar_y   = 16;
var bar_w   = 220;
var hp_h    = 16;
var stam_h  = 10;
var pad     = 6;

// ---- HEALTH BAR ----
var hp_ratio = clamp(player_health / max_health, 0, 1);
// Background / empty
draw_set_color(c_black);
draw_rectangle(bar_x - 2, bar_y - 2, bar_x + bar_w + 2, bar_y + hp_h + 2, false);
draw_set_color(make_color_rgb(60, 0, 0));
draw_rectangle(bar_x, bar_y, bar_x + bar_w, bar_y + hp_h, false);
// Fill
draw_set_color(make_color_rgb(190, 30, 30));
draw_rectangle(bar_x, bar_y, bar_x + bar_w * hp_ratio, bar_y + hp_h, false);
// Border
draw_set_color(c_white);
draw_rectangle(bar_x, bar_y, bar_x + bar_w, bar_y + hp_h, true);
draw_text(bar_x + 4, bar_y + 1, string(ceil(player_health)) + " / " + string(max_health));

// ---- STAMINA BAR ----
var st_y = bar_y + hp_h + pad;
var st_ratio = clamp(stamina / max_stamina, 0, 1);
draw_set_color(c_black);
draw_rectangle(bar_x - 2, st_y - 2, bar_x + bar_w + 2, st_y + stam_h + 2, false);
draw_set_color(make_color_rgb(20, 50, 20));
draw_rectangle(bar_x, st_y, bar_x + bar_w, st_y + stam_h, false);
draw_set_color(make_color_rgb(90, 200, 90));
draw_rectangle(bar_x, st_y, bar_x + bar_w * st_ratio, st_y + stam_h, false);
draw_set_color(c_white);
draw_rectangle(bar_x, st_y, bar_x + bar_w, st_y + stam_h, true);

// ---- FLASK CHARGES ----
var fl_y = st_y + stam_h + pad + 2;
var pip  = 14;
var gap  = 4;
for (var i = 0; i < flask_max_charges; i++) {
    var px = bar_x + i * (pip + gap);
    if (i < flask_charges) draw_set_color(make_color_rgb(80, 180, 230)); // filled flask
    else                   draw_set_color(make_color_rgb(40, 40, 50));   // used flask
    draw_rectangle(px, fl_y, px + pip, fl_y + pip, false);
    draw_set_color(c_white);
    draw_rectangle(px, fl_y, px + pip, fl_y + pip, true);
}

draw_set_color(c_white);
