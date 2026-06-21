// Killing a quest NPC is a crime -- raise wanted level
var player = instance_find(obj_player, 0);
if (player != noone) {
    player.wanted_level = max(player.wanted_level, 1);
    player.law_spawn_timer = 0;
    player.spawn_law_enforcer();
}

instance_destroy();
