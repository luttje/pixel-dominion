uniform mediump float current_time;
uniform mediump vec2 world_coordinates;

// Higher scale = more/smaller visible fog 'clouds'
const mediump float FOG_SCALE = 8;
const mediump float FOG_DENSITY = 0.6;
const mediump float FOG_SPEED = 0.25;

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    // Draw noise over everything that isn't translucent
    vec4 mask = Texel(tex, texture_coords);

    // Add the texture coords to the world coordinates to get the local coordinates
    vec2 local_coordinates = world_coordinates + texture_coords;

    // Calculate the fog density based on the world coordinates and time
    float fog = noise(local_coordinates * FOG_SCALE + current_time * FOG_SPEED);

    // Apply the fog to the mask
    return vec4(0.0, 0.0, 0.0, mask.a * (1.0 - fog * (1.0 - FOG_DENSITY)));
}
