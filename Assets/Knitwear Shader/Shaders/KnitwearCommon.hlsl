#ifndef UNIVERSAL_KNITWEAR_COMMON_INCLUDED
#define UNIVERSAL_KNITWEAR_COMMON_INCLUDED

float2 GradientNoiseDir(float2 p)
{
    p = p % 289;
    float x = (34 * p.x + 1) * p.x % 289 + p.y;
    x = (34 * x + 1) * x % 289;
    x = frac(x / 41) * 2 - 1;
    return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
}

float GradientNoise(float2 p)
{
    float2 ip = floor(p);
    float2 fp = frac(p);
    float d00 = dot(GradientNoiseDir(ip), fp);
    float d01 = dot(GradientNoiseDir(ip + float2(0, 1)), fp - float2(0, 1));
    float d10 = dot(GradientNoiseDir(ip + float2(1, 0)), fp - float2(1, 0));
    float d11 = dot(GradientNoiseDir(ip + float2(1, 1)), fp - float2(1, 1));
    fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
    return lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x);
}

void ApplyDistortion(inout float2 uv, half division, half distortion)
{
    float noise = GradientNoise(uv * division * 0.005);
    noise *= distortion * 50 / division;

    float noiseDetail = GradientNoise(uv * division * 0.04);
    noiseDetail *= distortion * 6.25 / division;
    
    uv += noise + noiseDetail;
}

void KnitwearCoordinate(inout float2 uv, out float2 cell, half division, half shear, half distortion = 0)
{
#if defined(_KNITWEAR_DISTORTION_ON)
    ApplyDistortion(uv, division, distortion);
#endif

    float verticalOffset = distance(frac(uv.x), 0.5) * shear;
    uv.y += verticalOffset;

    cell = floor(uv * float2(2.0, 1.0));
    cell += float2(0.5, 0.5);
    cell *= float2(0.5, 1.0);
}

#endif // UNIVERSAL_KNITWEAR_COMMON_INCLUDED