// Movement variables
xspd = 0;
yspd = 0;
move_speed = 1; // Slower than player
max_speed = 1.5;

// Direction and facing
face = DOWN;
target_dir = random(360);
wander_timer = 0;
wander_change_time = 60 + random(120); // Change direction every 1-3 seconds

// AI States
enum ENEMY_STATE {
    WANDERING,
    CHASING,
    ATTACKING,
    COOLDOWN
}

state = ENEMY_STATE.WANDERING;

// Detection and combat
detection_range = 150;
attack_range = 64;
chase_speed = 2;
attack_damage = 10;

// Enemy Health System
enemy_health = 50;
max_enemy_health = 50;
enemy_invincible = 0;
max_enemy_invincible = 20; // Brief invincibility after being hit
is_enemy_dead = false;

// Animation and timing
is_attacking = false;
attack_cooldown = 0;
attack_cooldown_max = 120; // 2 seconds at 60fps

// Steering behavior variables
desired_x = 0;
desired_y = 0;
steering_force = 0.1;

// Define direction constants (should match player's)
sprite[RIGHT] = spr_enemy_idle_right;
sprite[UP] = spr_enemy_idle_up;
sprite[LEFT] = spr_enemy_idle_left;
sprite[DOWN] = spr_enemy_idle_down;