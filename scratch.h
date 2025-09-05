#include <metal_stdlib>
using namespace metal;

// cubmap facing direction for each slice
float3 facing(uint2 gid, int slice, int size) {
    float x = float(gid.x) / float(size)) * 2.0 - 1.0;
    float y = float(gid.y) / float(size)) * 2.0 - 1.0;

    switch (slice) {
    case 0: return float3( 1,  y, -x); // +X
    case 1: return float3(-1,  y,  x); // -X
    case 2: return float3( x,  1, -y); // +Y
    case 3: return float3( x, -1,  y); // -Y
    case 4: return float3( x,  y,  1); // +Z
    case 5: return float3(-x,  y, -1); // -Z
    default: return float3(0);
    }
}

kernel void process_cube_face_kernel
(
 texturecube<float, access::sample> cubeTex [[texture(0)]],
 texture2d  <float, access::write>  outTex  [[texture(1)]],
 const device int& slice [[buffer(0)]],
 uint2 gid [[thread_position_in_grid]]
 ) {
    int width = outTex.get_width();
    int height = outTex.get_height();

    if (gid.x >= width || gid.y >= height) {
        return;
    }

    sampler s(address::clamp_to_edge, filter::linear);
    float3 directionVector = facing(gid, slice, width);
    float4 color = cubeTex.sample(s, directionVector);

    outTex.write(color, gid);
}
