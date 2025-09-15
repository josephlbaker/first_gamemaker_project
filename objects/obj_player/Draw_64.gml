// Draw health UI
draw_set_color(c_white);
draw_set_font(-1);
draw_text(10, 10, "Health: " + string(player_health));

// Optional: Draw health bar
draw_set_color(c_red);
draw_rectangle(10, 30, 10 + (player_health/max_health) * 200, 45, false);
draw_set_color(c_white);
draw_rectangle(10, 30, 210, 45, true);