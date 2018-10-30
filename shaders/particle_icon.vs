#version 140

// particle_icon.vs

#include "particle_common.vs"

out vec4 v_ColorPrimary;
out vec4 v_ColorSecondary;
out vec2 v_TexCoord;
out float v_SelectedState;

void main() 
{
    // To start with, sample the relevant data from the input stream. We need to know where in the buffer to read from.

    // The "stride" is 4, meaning we read 4 float-4s per particle.
    int stride = 4;
    int sampleBase = (gl_InstanceID * stride) + InstanceBufferParams.x;
    vec4 posAndScale = texelFetch(ParticleInstanceData, sampleBase);

    if (isIconOccluded(posAndScale.xyz))
    {
        gl_Position = vec4(0, 0, -1.0, 1.0);
        return;
    }

    vec4 vUVAndExtra = texelFetch(ParticleInstanceData, sampleBase + 1);

    v_ColorPrimary = texelFetch(ParticleInstanceData, sampleBase + 2);

    // here is where the magic happens,
    // since the outputed texture coords at the bottom down 
    v_ColorSecondary = vec4(a_TexCoord.xy, 0, 0);

    // Get the world position...
    vec4 worldPos = WorldViewProjTransform * vec4(posAndScale.xyz, 1.0);

    // divide by w to covert to normalized clip space
    worldPos /= worldPos.w;

    // multiply by half the screen res to get pixel offsets...
    vec2 halfScreenSize = screenSize.xy * 0.5;
    worldPos.xy = halfScreenSize + worldPos.xy * halfScreenSize;

    // offset by vert position and scale
    float scale = posAndScale.w;
    vec2 quadpos = a_Position.xy - 0.5;
    vec2 offset = quadpos * scale;
    worldPos.xy += offset;

    // Clamp to exact pixel offset.
    worldPos.xy = floor(worldPos.xy);

    // Put back into normalized clip space.
    worldPos.xy /= halfScreenSize;
    worldPos.xy -= 1.0;

    v_SelectedState = vUVAndExtra.z;

    // We're already in normalized clip space, so w is just 1.0.
    gl_Position = vec4(worldPos.x, worldPos.y, worldPos.z, 1.0);

    v_TexCoord = calculateAtlasUV(vUVAndExtra.xy);
}
