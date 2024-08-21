#version 430

#define BLOB_COUNT 256
// #define BLOB_COUNT 4

#define EPS 0.000001f
#define INT_MAX 0x7FFFFFFF
#define UINT_MAX 0xFFFFFFFFu
#define FLT_MAX 3.402823466e+38
#define FLT_MIN 1.175494351e-38
#define DBL_MAX 1.7976931348623158e+308
#define DBL_MIN 2.2250738585072014e-308
#define PI 3.1415f
#define TWOPI 6.2831f
#define OCTAVES 8
#define STRENGH 1

layout (local_size_x = BLOB_COUNT, local_size_y = 1, local_size_z = 1) in;

layout(std430, binding = 1) buffer blobsPosLayout {
    vec2 src[BLOB_COUNT];
};

layout(std430, binding = 2) buffer blobsRotLayout {
    float rots[BLOB_COUNT];
};

uniform int iFrame;
uniform ivec2 iResolution;
uniform float iTime;

uint hash(uint state)
{
    state ^= 2747636419u;
    state *= 2654435769u;
    state ^= state >> 16;
    state *= 2654435769u;
    state ^= state >> 16;
    state *= 2654435769u;
    return state;
}

float randf(uvec3 p)
{
    return float(hash(
        p.y * uint(iResolution.x) + p.x + 
        hash(int(float(p.z) + iTime * 100000.0))
    )) / float(UINT_MAX);
}

float randf(uint id) 
{
    float r = randf(uvec3(src[id].xy, uint(id)));
    r = isnan(r) ? 0.0 : isinf(r) ? 1.0 : r;
    return r;
}

float fmodf(float a, float b)
{
    return mod((mod(a, b) + b), b);
}

void main()
{
    vec2 iRes = vec2(iResolution);
    vec2 fRes = vec2(iResolution);

    uint i = gl_GlobalInvocationID.x;
    float r = rots[i];
    float a = fmodf(r * TWOPI, TWOPI);
    
    float x = src[i].x;
    float y = src[i].y;

    float ca = cos(a);
    float sa = sin(a);

    x += ca;
    y += sa;

    if (x <= 0.0 || y <= 0.0 || x >= fRes.x - 1.0 || y >= fRes.y - 1.0 ||
        x == src[i].x || y == src[i].y) {
        x = min(iRes.x - 1, max(0, x));
        y = min(iRes.y - 1, max(0, y));

        rots[i] = randf(i);
        // rots[i] = 1.0 - r;
    }

    src[i] = vec2(x, y);
}
