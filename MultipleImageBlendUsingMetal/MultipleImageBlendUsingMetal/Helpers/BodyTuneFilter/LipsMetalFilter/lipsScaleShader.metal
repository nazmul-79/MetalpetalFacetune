//
//  lipsScaleShader.metal
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 14/8/25.
//

/*#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

// --- Helper for smooth lips scaling ---
float2 scaledUVForLips(float2 uv, float2 lipCenter, float2 lipRadiusXY, float lipScaleFactor) {
    float2 diff = uv - lipCenter;

    // avoid division by zero
    float2 invRadius = 1.0 / max(lipRadiusXY, float2(1e-5));
    float dist = length(diff * invRadius);

    // normalize slider: -100..100 -> -1..1
    float normalizedScale = clamp(lipScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.5);

    // Gaussian falloff
    float falloff = 1.2;
    float weight = exp(-pow(dist / falloff, 2.0) * 2.0);

    // scale smoothly from center
    float maxScaleFactor = 0.4;
    float2 s = 1.0 + normalizedScale * maxScaleFactor * weight;

    float2 newUV = lipCenter + diff / s;

    return clamp(mix(uv, newUV, weight), 0.0, 1.0);
}

fragment float4 lipsScaleShader(VertexOut vert [[stage_in]],
                                texture2d<float> inputTexture [[texture(0)]],
                                constant float &lipScaleFactor [[buffer(0)]],
                                constant float2 &lipCenter [[buffer(1)]],
                                constant float2 &lipRadiusXY [[buffer(2)]],
                                sampler textureSampler [[sampler(0)]]) {

    float2 uv = vert.textureCoordinate;

    // --- compute scaled UV for lips ---
    float2 uvLips = scaledUVForLips(uv, lipCenter, lipRadiusXY, lipScaleFactor);

    return inputTexture.sample(textureSampler, uvLips);
}
*/

/*#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

// --- Smooth scaling of a lip region ---
float2 scaleUVForLips(float2 uv, float2 lipCenter, float2 lipRadiusXY, float lipScaleFactor) {
    // Vector from center to current UV
    float2 diff = uv - lipCenter;

    // Normalize scale slider (-100..100 -> -1..1)
    float normalizedScale = clamp(lipScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.5); // optional smoothing

    // Gaussian falloff based on normalized ellipse distance
    float2 normDiff = diff / lipRadiusXY;
    float dist = length(normDiff);
    float falloff = 1.0; // controls how fast effect fades at edges
    float weight = exp(-pow(dist / falloff, 2.0) * 2.0);

    // --- Uniform scaling (no stretching) ---
    float scaleFactor = 1.0 + normalizedScale * 0.25 * weight;
    float2 newUV = lipCenter + diff * scaleFactor;

    // Clamp UVs to [0,1]
    return clamp(newUV, 0.0, 1.0);
}

fragment float4 lipsScaleShader(VertexOut vert [[stage_in]],
                                texture2d<float> inputTexture [[texture(0)]],
                                constant float &lipScaleFactor [[buffer(0)]],
                                constant float2 &lipCenter [[buffer(1)]],
                                constant float2 &lipRadiusXY [[buffer(2)]],
                                sampler textureSampler [[sampler(0)]]) {
    float2 uv = vert.textureCoordinate;
    float2 finalUV = scaleUVForLips(uv, lipCenter, lipRadiusXY, lipScaleFactor);
    return inputTexture.sample(textureSampler, finalUV);
}
*/

#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

/*float2 scaleUVForLips(float2 uv, float2 lipCenter, float2 lipRadiusXY, float lipScaleFactor) {
    float2 diff = uv - lipCenter;

    // normalize and invert scale
    float normalizedScale = clamp(lipScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = -tanh(normalizedScale * 1.5); // invert

    // Gaussian falloff
    float2 normDiff = diff / lipRadiusXY;
    float dist = length(normDiff);
    float falloff = 1.2;
    float weight = exp(-pow(dist / falloff, 2.0) * 2.0);

    // uniform scaling
    float scaleFactor = 1.0 + normalizedScale * 0.25 * weight;
    float2 newUV = lipCenter + diff * scaleFactor;

    return clamp(newUV, 0.0, 1.0);
}*/
//finall trail 1st pahase
/*float2 scaleUVForLips(float2 uv, float2 lipCenter, float2 lipRadiusXY, float lipScaleFactor) {
    float2 diff = uv - lipCenter;

    // normalize slider -100..100 → -1..1
    float normalizedScale = clamp(lipScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.5);

    // Gaussian falloff
    float2 normDiff = diff / lipRadiusXY;
    float dist = length(normDiff);
    float falloff = 1.2;
    float weight = exp(-pow(dist / falloff, 2.0) * 2.0);

    // compute zoom factor (smaller than eyes, lips need subtle)
    float maxScale = 0.20; // 15% max
    float scale = 1.0 + normalizedScale * maxScale * weight;

    // *** zoom = divide ***
    float2 newUV = lipCenter + diff / scale;

    return clamp(newUV, 0.0, 1.0);
}*/

/*float2 scaleUVForLips(float2 uv, float2 lipCenter, float2 lipRadiusXY, float lipScaleFactor) {
    float2 diff = uv - lipCenter;

    // normalize slider -100..100 → -1..1
    float normalizedScale = clamp(lipScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.5);

    // elliptical normalized coordinates (শুধুমাত্র falloff গণনার জন্য)
    float2 normDiff = diff / max(lipRadiusXY, float2(1e-5, 1e-5));

    // elliptical distance for falloff
    float dist = length(normDiff);

    // falloff: inner fully affected, outer smooth
    float inner = 0.0;     // fully plump at center
    float outer = 1.3;     // fade toward edges
    float t = smoothstep(inner, outer, dist);

    // max scale factor for lips
    float maxScale = 0.20;

    // zoom factor: inner points move most, outer points less
    float zoom = 1.0 - normalizedScale * (1.0 - t) * maxScale;

    // The FIX IS HERE: Apply zoom to the ORIGINAL diff vector
    // এটি মূল আকৃতি (aspect ratio) বজায় রাখে।
    float2 newUV = lipCenter + diff * zoom;

    return clamp(newUV, 0.001, 0.999);
}*/

/*float2 scaleUVForLips(float2 uv, float2 lipCenter, float2 lipRadiusXY, float lipScaleFactor) {
    float2 diff = uv - lipCenter;

    // normalize slider -100..100 → -1..1
    float normalizedScale = clamp(lipScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.5);

    // elliptical normalized coordinates
    float2 normDiff = diff / max(lipRadiusXY, float2(1e-5, 1e-5));

    // elliptical distance for falloff
    float dist = length(normDiff);

    // falloff: inner fully affected, outer smooth
    float inner = 0.0;     // fully plump at center
    float outer = 1.3;     // fade toward edges
    float t = smoothstep(inner, outer, dist);

    // max scale factor for lips
    float maxScale = 0.20;

    // ----- [নতুন সংযোজন] Horizontal falloff for corners -----
    // ঠোঁটের কেন্দ্র থেকে x-অক্ষের দূরত্ব (0 থেকে 1 পর্যন্ত)
    float horizontalDist = abs(normDiff.x);
    
    // Falloff শুরু এবং শেষ হওয়ার সীমা (এই মানগুলো পরিবর্তন করে ইফেক্ট ফাইন-টিউন করা যাবে)
    float cornerFalloffStart = 0.5; // মাঝখানের 50% পর্যন্ত সম্পূর্ণ ইফেক্ট থাকবে
    float cornerFalloffEnd = 0.9;   // 90% দূরত্বে গিয়ে ইফেক্ট পুরোপুরি বন্ধ হয়ে যাবে

    // smoothstep ব্যবহার করে একটি মসৃণ falloff তৈরি করা
    float cornerT = smoothstep(cornerFalloffStart, cornerFalloffEnd, horizontalDist);

    // ওজন (weight) গণনা করা, যা মাঝখানে 1.0 এবং কোণায় 0.0 হবে
    float cornerWeight = 1.0 - cornerT;
    // ----------------------------------------------------------------

    // ইফেক্টের মোট শক্তি
    float effectMagnitude = normalizedScale * (1.0 - t) * maxScale;
    
    // zoom factor: কোণার দিকে যেতে যেতে ইফেক্টের শক্তি কমানো হচ্ছে
    float zoom = 1.0 - effectMagnitude * cornerWeight; // এখানে cornerWeight দিয়ে গুণ করা হয়েছে

    // Apply zoom to the ORIGINAL diff vector
    float2 newUV = lipCenter + diff * zoom;

    return clamp(newUV, 0.001, 0.999);
}*/

/*
    এই ফাংশনটি একটি Zoom Lens বা Magnifying Glass ইফেক্ট তৈরি করে।
    এটি ঠোঁটের পিক্সেলকে নাড়িয়ে ঠোঁটকে ফোলানো বা চিকন করে না।
    বরং, এটি ঠোঁটের উপরের স্ক্রিনের অংশকে জুম করে, যার ফলে ঠোঁটকে বড় বা ছোট দেখায়।
    এটিই Peachy বা অন্যান্য অ্যাপের standard পদ্ধতি।
*/


/*//upgarde from AI Studio
float2 scaleUVForLips(float2 uv, float2 lipCenter, float2 lipRadiusXY, float lipScaleFactor) {
    // uv = স্ক্রিনের বর্তমান পিক্সেলের কো-অর্ডিনেট
    // finalUV = টেক্সচারের কোন জায়গা থেকে কালার আনতে হবে, সেই কো-অর্ডিনেট

    // ধাপ ১: স্ক্রিনের পিক্সেলটি কেন্দ্র থেকে কত দূরে আছে, তা বের করা
    float2 diff = uv - lipCenter;

    // ধাপ ২: উপবৃত্তাকার (Elliptical) এলাকাকে একটি নিখুঁত বৃত্তাকার (Circular) স্পেসে রূপান্তর করা
    // এটি সবচেয়ে গুরুত্বপূর্ণ ধাপ। diff-কে lipRadiusXY দিয়ে ভাগ করার ফলে,
    // আপনার উপবৃত্তাকার ঠোঁটের এলাকাটি গাণিতিকভাবে একটি নিখুঁত বৃত্তে পরিণত হয়।
    // এর ফলে stretching ছাড়াই আনুপাতিকভাবে জুম করা সম্ভব হয়।
    float2 normDiff = diff / lipRadiusXY;
    float dist = length(normDiff); // এই বৃত্তাকার স্পেসে কেন্দ্র থেকে দূরত্ব

    // ধাপ ৩: কতটা জুম করতে হবে, তা নির্ধারণ করা
    float normalizedScale = clamp(lipScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.5);

    float inner = 0.0; // কেন্দ্রের ভেতরের অংশে ইফেক্টের তীব্রতা
    float outer = 1.2; // কত দূর পর্যন্ত ইফেক্টটি মিলিয়ে যাবে
    float t = smoothstep(inner, outer, dist);

    float maxScale = 0.25;
    float effectStrength = normalizedScale * (1.0 - t) * maxScale;
    float zoom = 1.0 - effectStrength;

    // ধাপ ৪: বৃত্তাকার স্পেসে জুম প্রয়োগ করা
    // normDiff ভেক্টরকে zoom ফ্যাক্টর দিয়ে গুণ করার মানে হলো, আমরা স্যাম্পল করার জন্য
    // বৃত্তের কেন্দ্রের কাছাকাছি বা দূরের কোনো বিন্দুকে টার্গেট করছি।
    // যেমন, জুম ইন করার জন্য (zoom < 1), আমরা কেন্দ্রের কাছাকাছি থেকে স্যাম্পল নেব।
    float2 newNorm = normDiff * zoom;

    // ধাপ ৫: জুম করা বৃত্তাকার স্পেসকে আবার মূল উপবৃত্তাকার স্ক্রিন স্পেসে ফিরিয়ে আনা
    // newNorm-কে lipRadiusXY দিয়ে গুণ করে আমরা আগের উপবৃত্তাকার আকৃতিতে ফিরে যাই।
    // এর ফলেই ঠোঁটের আকৃতি বিকৃত না হয়ে আনুপাতিকভাবে জুম হয়।
    float2 finalUV = lipCenter + newNorm * lipRadiusXY;

    return clamp(finalUV, 0.0, 1.0);
}*/

/*float2 scaleUVForLips(float2 uv, float2 lipCenter, float2 lipRadiusXY, float lipScaleFactor) {
    // offset
    float2 diff = uv - lipCenter;

    // scaleFactor normalize করা
    float normalizedScale = clamp(lipScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.2);

    // radius-কে scaleFactor দিয়ে বাড়ানো/কমানো
    float2 scaledRadius = lipRadiusXY * (1.0 + normalizedScale);

    // নতুন ellipse space-এ normalize করা
    float2 normDiff = diff / scaledRadius;
    float dist = length(normDiff);

    // smooth falloff, যাতে বাইরে transition হয়
    float t = smoothstep(1.0, 1.0, dist);

    // জুম effect strength (dist==0 এ max, boundary তে 0)
    float effectStrength = (1.0 - t) * normalizedScale * 0.15;

    // জুম প্রয়োগ
    float2 newNorm = normDiff * (1.0 - effectStrength);

    // ellipse space থেকে screen space-এ ফেরত
    float2 finalUV = lipCenter + newNorm * scaledRadius;

    return clamp(finalUV, 0.0, 1.0);
}*/

/*float2 scaleUVForLips(float2 uv, float2 lipCenter, float2 lipRadiusXY, float lipScaleFactor) {
    float2 diff = uv - lipCenter;

    // normalize slider -100..100 → -1..1
    float normalizedScale = clamp(lipScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.2);

    // elliptical normalized coordinates
    float2 normDiff = diff / lipRadiusXY;

    // elliptical distance
    float ellipseDist = length(normDiff);

    // falloff: inside fully affected, outside smoothly 0
    float t = smoothstep(1.0, 1.3, ellipseDist);

    // zoom strength (ellipse center max, edge none)
    float effectStrength = (1.0 - t) * normalizedScale * 0.25;

    // apply scale **inside elliptical space**
    float2 newNormDiff = normDiff * (1.0 - effectStrength);

    // back to screen space
    float2 finalUV = lipCenter + newNormDiff * lipRadiusXY;

    return clamp(finalUV, 0.0, 1.0);
}*/

/*float2 scaleUVForLips(float2 uv, float2 lipCenter, float2 lipRadiusXY, float lipScaleFactor) {
    float2 diff = uv - lipCenter;

    // slider normalize: -100..100 → -1..1
    float normalizedScale = clamp(lipScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.2);

    // ellipse normalized coords
    float2 normDiff = diff / lipRadiusXY;
    float ellipseDist = length(normDiff);

    // smooth falloff (wider = smoother pixels)
    float t = smoothstep(1.0, 1.2, ellipseDist);

    // cubic easing → smoother transition
    float effectStrength = (1.0 - t);
    effectStrength = effectStrength * effectStrength * (3.0 - 2.0 * effectStrength);
    effectStrength *= normalizedScale * 0.15;

    // anisotropic scaling → vertical less than horizontal
    float2 anisotropy = float2(1.0, 0.6);   // y-axis weaker
    float2 newNormDiff = normDiff * (1.0 - effectStrength * anisotropy);

    // back to uv space
    float2 finalUV = lipCenter + newNormDiff * lipRadiusXY;

    return clamp(finalUV, 0.0, 1.0);
}*/

/*float2 scaleUVForLips(float2 uv, float2 lipCenter, float2 lipRadiusXY, float lipScaleFactor) {
    // ধাপ ১: কেন্দ্র থেকে পিক্সেলের অফসেট
    float2 diff = uv - lipCenter;

    // ধাপ ২: স্লাইডার মান নরম্যালাইজ করা (-1..1)
    float normalizedScale = clamp(lipScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.3);

    // ধাপ ৩: উপবৃত্তাকার নরম্যালাইজড কো-অর্ডিনেট
    float2 normDiff = diff / max(lipRadiusXY, float2(1e-5, 1e-5));
    float ellipseDist = length(normDiff);

    // ----- [নতুন পরিবর্তন এখানে] -----
    // ধাপ ৪: এলাকার বাইরেও মসৃণ falloff তৈরি করা
    float innerRadius = 0.5; // এই ব্যাসার্ধের ভেতরে ইফেক্ট সম্পূর্ণ শক্তিশালী থাকবে
    float outerRadius = 1.2; // এই ব্যাসার্ধের বাইরে ইফেক্ট পুরোপুরি শূন্য হয়ে যাবে
    
    // innerRadius এবং outerRadius এর মধ্যে একটি মসৃণ রূপান্তর (transition)
    float t = smoothstep(innerRadius, outerRadius, ellipseDist);

    // ধাপ ৫: Cubic easing ব্যবহার করে রূপান্তরকে আরও মসৃণ করা
    float w = (1.0 - t);
    w = w * w * (3.0 - 2.0 * w);

    // ধাপ ৬: জুম ইফেক্টের শক্তি গণনা করা
    float effectStrength = w * normalizedScale * 0.15; // সর্বোচ্চ জুমের জন্য 0.25 পরিবর্তন করুন

    // ধাপ ৭: Anisotropic scaling (উল্লম্বভাবে দুর্বল)
    float2 anisotropy = float2(1.0, 0.55);

    // ধাপ ৮: উপবৃত্তাকার স্পেসে জুম প্রয়োগ করা
    float2 newNormDiff = normDiff * (1.0 - effectStrength * anisotropy);

    // ধাপ ৯: মূল UV স্পেসে ফিরিয়ে আনা
    float2 finalUV = lipCenter + newNormDiff * lipRadiusXY;

    // ধাপ ১০: UV রেঞ্জের মধ্যে রাখা
    return clamp(finalUV, 0.0, 1.0);
}*/

//ulta effect
/*float2 scaleUVForLips(float2 uv, float2 lipCenter, float2 lipRadiusXY, float lipScaleFactor) {
    float2 diff = uv - lipCenter;

    // Normalize slider: -100..100 -> -1..1
    float normalizedScale = clamp(lipScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.5);

    // Compute ellipse normalized coordinates
    float2 normDiff = diff / lipRadiusXY;

    // Horizontal distance from left/right edges
    float leftDist = (normDiff.x + 1.0);  // left edge at -1 → 0
    float rightDist = (1.0 - normDiff.x); // right edge at +1 → 0

    // Compute weight for horizontal falloff
    float weight = min(leftDist, rightDist);
    weight = clamp(weight, 0.0, 1.0);

    // Smooth cubic easing
    weight = weight * weight * (3.0 - 2.0 * weight);

    // Max scale factor
    float maxScale = 0.2;

    // Apply zoom toward horizontal edges
    float scaleX = 1.0 - normalizedScale * weight * maxScale;
    float scaleY = 1.0 - normalizedScale * weight * maxScale * 0.6; // vertical weaker

    float2 newNormDiff = normDiff * float2(scaleX, scaleY);

    // Map back to UV
    float2 finalUV = lipCenter + newNormDiff * lipRadiusXY;

    return clamp(finalUV, 0.0, 1.0);
}*/
/*float2 scaleUVForLips(float2 uv, float2 lipCenter, float2 lipRadiusXY, float lipScaleFactor) {
    float2 diff = uv - lipCenter;

    // slider normalize
    float normalizedScale = clamp(lipScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.5);

    // ellipse coordinates
    float2 normDiff = diff / lipRadiusXY;
    float ellipseDist = length(normDiff);

    // Gaussian falloff for smooth edges
    float falloff = 0.8; // 1 = at edge
    float weight = exp(-pow(ellipseDist / falloff, 2.0));

    // cubic easing
    weight = weight * weight * (3.0 - 2.0 * weight);

    // zoom strength with vertical anisotropy
    float maxZoom = 0.15;
    float2 anisotropy = float2(1.0, 0.55);
    float2 newNorm = normDiff * (1.0 - weight * normalizedScale * maxZoom * anisotropy);

    // back to UV space
    float2 finalUV = lipCenter + newNorm * lipRadiusXY;

    return clamp(finalUV, 0.0, 1.0);
}*/

/*
    এই ফাংশনটি একটি horizontally-driven plump ইফেক্ট তৈরি করে, যা ঠোঁটের
    দুই কোণার দিকে মসৃণভাবে মিলিয়ে যায়। এটি AirBrush-এর মতো অ্যাপের
    প্রাকৃতিক ঠোঁট ফোলানো ইফেক্টের অনুকরণ করে।
*/
/*float2 scaleUVForLips_Airbrush(float2 uv, float2 lipCenter, float2 lipRadiusXY, float lipScaleFactor) {
    float normalizedScale = clamp(lipScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.3);

    float2 diff = uv - lipCenter;
    float2 normDiff = diff / max(lipRadiusXY, float2(1e-5));
    float ellipseDist = length(normDiff);

    if (ellipseDist > 1.6) {
        return uv;
    }

    // ------------------- Airbrush style logic -------------------

    // Horizontal weight = বেশি left/right এ, center এ কম
    float edgeStrength = pow(abs(normDiff.x), 1.5);
    float horizontalWeight = smoothstep(0.0, 1.0, edgeStrength);

    // Vertical falloff (top-bottom এ কম)
    float verticalWeight = 1.0 - pow(abs(normDiff.y), 1.2);

    // Final weight (edges থেকে inward fade-in)
    float totalWeight = horizontalWeight * verticalWeight;

    // Effect strength
    float maxScale = 0.3; // একটু বেশি জুম allow করলাম
    float effectStrength = totalWeight * normalizedScale * maxScale;

    // Horizontal dominance (airbrush = side pull)
    float2 anisotropy = float2(1.0, 0.4);

    // Apply scaling
    float2 newNormDiff = normDiff * (1.0 - effectStrength * anisotropy);

    return clamp(lipCenter + newNormDiff * lipRadiusXY, 0.0, 1.0);
}*/

// Utility: compute UV inside lips with elliptical airbrush-style zoom
// Utility: compute UV inside lips with elliptical airbrush-style zoom
// Utility: compute UV inside lips with elliptical airbrush-style zoom
/*float2 zoomUVInsideLips(float2 uv,
                        float2 lipCenter,
                        float2 lipRadiusXY,
                        float lipScaleFactor,
                        float2 paddingUV) {
    
    // 1. Pixel offset from lip center
    float2 diff = uv - lipCenter;

    // 2. Add small padding to radius (airbrush beyond lips)
    float2 regionRadius = lipRadiusXY + paddingUV;

    // 3. Elliptical distance (preserve ellipse ratio)
    float dx = diff.x / regionRadius.x;
    float dy = diff.y / regionRadius.y;
    float ellipseDist = sqrt(dx*dx + dy*dy);

    // 4. Normalize slider (-100..100 -> -1..1) and smooth curve
    float normalizedScale = clamp(lipScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.3);

    // 5. Smooth falloff (airbrush feather)
    float feather = 0.15; // 0=no feather, 0.2=slightly outside
    float mask = 1.0 - smoothstep(1.0 - feather, 1.0, ellipseDist);

    // 6. Compute zoom effect inside ellipse
    float2 newDiff = diff * (1.0 - normalizedScale * mask);

    // 7. Map back to UV space
    float2 finalUV = lipCenter + newDiff;

    return clamp(finalUV, 0.0, 1.0);
}

// -----------------------------------------
// Fragment shader
fragment float4 lipsScaleShader(VertexOut vert [[stage_in]],
                                texture2d<float> inputTexture [[texture(0)]],
                                constant float &lipScaleFactor [[buffer(0)]],
                                constant float2 &lipCenter [[buffer(1)]],
                                constant float2 &lipRadiusXY [[buffer(2)]]) {

    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);

    float2 uv = vert.textureCoordinate;

    // Optional: 5px padding in normalized UV (adjust based on image size)
    float2 paddingUV = float2(0.00, 0.00);

    // Compute zoomed UV inside lips
    float2 finalUV = zoomUVInsideLips(uv, lipCenter, lipRadiusXY, lipScaleFactor, paddingUV);

    return inputTexture.sample(textureSampler, finalUV);
}

/* -----------------------------------------
// Fragment shader
fragment float4 lipsScaleShader(VertexOut vert [[stage_in]],
                                texture2d<float> inputTexture [[texture(0)]],
                                constant float &lipScaleFactor [[buffer(0)]],
                                constant float2 &lipCenter [[buffer(1)]],
                                constant float2 &lipRadiusXY [[buffer(2)]]) {

    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);

    float2 uv = vert.textureCoordinate;

    // Optional: 5px padding in normalized UV (adjust based on image size)
    float2 paddingUV = float2(0.015, 0.015);

    // Compute zoomed UV inside lips
    float2 finalUV = zoomUVInsideLips(uv, lipCenter, lipRadiusXY, lipScaleFactor, paddingUV);

    return inputTexture.sample(textureSampler, finalUV);
}

// -----------------------------------------
// Fragment shader
fragment float4 lipsScaleShader(VertexOut vert [[stage_in]],
                                texture2d<float> inputTexture [[texture(0)]],
                                constant float &lipScaleFactor [[buffer(0)]],
                                constant float2 &lipCenter [[buffer(1)]],
                                constant float2 &lipRadiusXY [[buffer(2)]]) {

    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);

    float2 uv = vert.textureCoordinate;

    // Optional: 5px padding in normalized UV (adjust based on image size)
    float2 paddingUV = float2(0.015, 0.015);

    // Compute zoomed UV inside lips
    float2 finalUV = zoomUVInsideLips(uv, lipCenter, lipRadiusXY, lipScaleFactor, paddingUV);

    return inputTexture.sample(textureSampler, finalUV);
}


fragment float4 lipsScaleShader(VertexOut vert [[stage_in]],
                                texture2d<float> inputTexture [[texture(0)]],
                                constant float &lipScaleFactor [[buffer(0)]],
                                constant float2 &lipCenter [[buffer(1)]],
                                constant float2 &lipRadiusXY [[buffer(2)]]) {
    
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
   
    float2 uv = vert.textureCoordinate;
    float2 finalUV = zoomUVInsideLips(uv, lipCenter, lipRadiusXY, lipScaleFactor);
    
    return inputTexture.sample(textureSampler, finalUV);
}
*/

/*fragment float4 lipsScaleShader(VertexOut vert [[stage_in]],
                                texture2d<float> inputTexture [[texture(0)]],
                                texture2d<float> maskTexture [[texture(1)]],
                                constant float &lipScaleFactor [[buffer(0)]],
                                constant float2 &lipCenter [[buffer(1)]],
                                constant float2 &lipRadiusXY [[buffer(2)]])
{
    constexpr sampler s (mag_filter::linear, min_filter::linear);

    float2 uv = vert.textureCoordinate;

    // Sample mask: 1 = inside lips, 0 = outside
    float maskValue = maskTexture.sample(s, uv).r;
    if (maskValue <= 0.0) return inputTexture.sample(s, uv);

    // Normalize slider (-100..100 → -1..1)
    float normalizedScale = clamp(lipScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.3);

    // Elliptical distance for feathering
    float2 diff = uv - lipCenter;
    float dx = diff.x / lipRadiusXY.x;
    float dy = diff.y / lipRadiusXY.y;
    float ellipseDist = sqrt(dx*dx + dy*dy);

    // Feather: 0 at center, 1 at border
    float feather = 1.0; // outer boundary influence
    float maskFeather = smoothstep(0.0, 1.0, ellipseDist);

    // Apply zoom towards center
    float scale = 1.0 - normalizedScale * (1.0 - maskFeather) * maskValue;
    float2 newUV = lipCenter + diff * scale;

    return inputTexture.sample(s, newUV);
}
*/

/*float2 scaleUVForLips(float2 uv, float2 lipCenter, float2 lipRadiusXY, float lipScaleFactor) {
    float2 diff = uv - lipCenter;

    // normalize slider -100..100 → -1..1
    float normalizedScale = clamp(lipScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.2); // slightly softer than 1.5

    // Gaussian-like falloff, smoother
    float2 normDiff = diff / lipRadiusXY;
    float dist = length(normDiff);
    float falloff = 1.0; // smaller = more central focus
    float weight = exp(-pow(dist / falloff, 2.0)); // remove extra *2 for smoother edges

    // subtle zoom factor
    float maxScale = 0.15; // smaller max, less stretching
    float scale = 1.0 + normalizedScale * maxScale * weight;

    // zoom
    float2 newUV = lipCenter + diff / scale;

    return clamp(newUV, 0.0, 1.0);
}
*/

/*float2 scaleUVForLips(float2 uv, float2 lipCenter, float2 lipRadiusXY, float lipScaleFactor) {
    float2 diff = uv - lipCenter;

    // normalize slider -100..100 → -1..1
    float normalizedScale = clamp(lipScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.2);

    // Gaussian-like falloff, smoother
    float2 normDiff = diff / lipRadiusXY;
    float dist = length(normDiff);
    float falloff = 1.2;
    float weight = exp(-pow(dist / falloff, 2.0));

    // directional weight for side zoom
    float sideFactor = smoothstep(-1.0, 1.0, diff.x / lipRadiusXY.x);
    // left side = 0, center = 0.5, right side = 1.0

    float maxScale = 0.20;
    float scale = 1.0 + normalizedScale * maxScale * weight * sideFactor;

    float2 newUV = lipCenter + diff / scale;

    return clamp(newUV, 0.0, 1.0);
}*/

float2 scaleUVForLips(float2 uv,
                      float2 lipCenter,
                      float2 lipRadiusXY,
                      float lipScaleFactor,
                      float sideBias) {
    
    float2 diff = uv - lipCenter;

    // normalize slider -100..100 → -1..1
    float normalizedScale = clamp(lipScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.2);

    // Gaussian-like falloff, smoother
    float2 normDiff = diff / lipRadiusXY;
    float dist = length(normDiff);
    float falloff = 1.0;
    float weight = exp(-pow(dist / falloff, 2.0));

    // directional side weighting
    float sideFactor = smoothstep(-1.0, 1.0, diff.x / lipRadiusXY.x); // left=0, right=1
    sideFactor = mix(1.0 - sideFactor, sideFactor, (sideBias + 1.0) * 0.5);
    // sideBias=-1 → left, 0 → both, 1 → right

    float maxScale = 0.25;
    float scale = 1.0 + normalizedScale * maxScale * weight * sideFactor;

    float2 newUV = lipCenter + diff / scale;

    return clamp(newUV, 0.0, 1.0);
}

fragment float4 lipsScaleShader(VertexOut vert [[stage_in]],
                                texture2d<float> inputTexture [[texture(0)]],
                                constant float &lipScaleFactor [[buffer(0)]],
                                constant float2 &lipCenter [[buffer(1)]],
                                constant float2 &lipRadiusXY [[buffer(2)]],
                                sampler textureSampler [[sampler(0)]]) {

    float2 uv = vert.textureCoordinate;
    // --- compute scaled UV for lips ---
    float2 uvLips = scaleUVForLips(uv, lipCenter, lipRadiusXY, lipScaleFactor,0.0);
    return inputTexture.sample(textureSampler, uvLips);
}
