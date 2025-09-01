//
//  transformBlend.metal
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 4/8/25.
//

#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

fragment float4 stickerOverlayShader(VertexOut vert [[stage_in]],
                                     texture2d<float> bgTexture [[texture(0)]],
                                     texture2d<float> stickerTexture [[texture(1)]],
                                     constant float2 &stickerPos [[buffer(0)]],
                                     constant float2 &stickerSize [[buffer(1)]],
                                     constant float &stickerRotation [[buffer(2)]])
{
    constexpr sampler s(address::clamp_to_edge, filter::linear);

    float2 uv = vert.textureCoordinate;

    // Convert uv to bg pixel space
    float2 bgCoord = uv * float2(bgTexture.get_width(), bgTexture.get_height());

    // Calculate sticker local UV: translate relative to stickerPos
    float2 stickerCoord = bgCoord - stickerPos;

    // Rotate stickerCoord around sticker center (stickerSize/2)
    float2 center = stickerSize * 0.5;
    float cosR = cos(-stickerRotation);
    float sinR = sin(-stickerRotation);
    float2 rotatedCoord = float2(
        cosR * (stickerCoord.x - center.x) - sinR * (stickerCoord.y - center.y),
        sinR * (stickerCoord.x - center.x) + cosR * (stickerCoord.y - center.y)
    ) + center;

    // Normalize to sticker UV (0..1)
    float2 stickerUV = rotatedCoord / stickerSize;

    // Sample background color
    float4 bgColor = bgTexture.sample(s, uv);

    // Sample sticker color if inside sticker bounds
    float4 stickerColor = float4(0,0,0,0);
    if (all(stickerUV >= 0) && all(stickerUV <= 1)) {
        stickerColor = stickerTexture.sample(s, stickerUV);
    }

    // Alpha blend: sticker over background
    float alpha = stickerColor.a;
    float4 outColor = mix(bgColor, stickerColor, alpha);

    return outColor;
}
