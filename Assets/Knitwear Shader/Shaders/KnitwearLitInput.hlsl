#ifndef UNIVERSAL_KNITWEAR_LIT_INPUT_INCLUDED
#define UNIVERSAL_KNITWEAR_LIT_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

#include "KnitwearCommon.hlsl"

CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
half4 _BaseColor;
half4 _SpecColor;
half4 _EmissionColor;
half _Cutoff;
half _Smoothness;
half _Metallic;
half _BumpScale;
half _OcclusionStrength;
half _KnitwearDivision;
half _KnitwearAspect;
half _KnitwearShear;
half _KnitwearDistortionStrength;
CBUFFER_END

TEXTURE2D(_KnitwearMap);        SAMPLER(sampler_KnitwearMap);
TEXTURE2D(_OcclusionMap);       SAMPLER(sampler_OcclusionMap);
TEXTURE2D(_MetallicGlossMap);   SAMPLER(sampler_MetallicGlossMap);
TEXTURE2D(_SpecGlossMap);       SAMPLER(sampler_SpecGlossMap);

half4 SampleAlbedoAlphaGrad(float2 uv, TEXTURE2D_PARAM(albedoAlphaMap, sampler_albedoAlphaMap), float2 dpdx, float2 dpdy)
{
    return SAMPLE_TEXTURE2D_GRAD(albedoAlphaMap, sampler_albedoAlphaMap, uv, dpdx, dpdy);
}

half3 SampleNormalGrad(float2 uv, TEXTURE2D_PARAM(bumpMap, sampler_bumpMap), float2 dpdx, float2 dpdy, half scale = 1.0h)
{
#ifdef _NORMALMAP
    half4 n = SAMPLE_TEXTURE2D_GRAD(bumpMap, sampler_bumpMap, uv, dpdx, dpdy);
    #if BUMP_SCALE_NOT_SUPPORTED
        return UnpackNormal(n);
    #else
        return UnpackNormalScale(n, scale);
    #endif
#else
    return half3(0.0h, 0.0h, 1.0h);
#endif
}

half3 SampleEmissionGrad(float2 uv, half3 emissionColor, TEXTURE2D_PARAM(emissionMap, sampler_emissionMap), float2 dpdx, float2 dpdy)
{
#ifndef _EMISSION
    return 0;
#else
    return SAMPLE_TEXTURE2D_GRAD(emissionMap, sampler_emissionMap, uv, dpdx, dpdy).rgb * emissionColor;
#endif
}

#ifdef _SPECULAR_SETUP
    #define SAMPLE_METALLICSPECULAR_GRAD(uv, ddx, ddy) SAMPLE_TEXTURE2D_GRAD(_SpecGlossMap, sampler_SpecGlossMap, uv, ddx, ddy)
#else
    #define SAMPLE_METALLICSPECULAR_GRAD(uv, ddx, ddy) SAMPLE_TEXTURE2D_GRAD(_MetallicGlossMap, sampler_MetallicGlossMap, uv, ddx, ddy)
#endif

half4 SampleMetallicSpecGlossGrad(float2 uv, float2 dpdx, float2 dpdy, half albedoAlpha)
{
    half4 specGloss;

#ifdef _METALLICSPECGLOSSMAP
    specGloss = SAMPLE_METALLICSPECULAR_GRAD(uv, dpdx, dpdy);
    #ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
        specGloss.a = albedoAlpha * _Smoothness;
    #else
        specGloss.a *= _Smoothness;
    #endif
#else // _METALLICSPECGLOSSMAP
    #if _SPECULAR_SETUP
        specGloss.rgb = _SpecColor.rgb;
    #else
        specGloss.rgb = _Metallic.rrr;
    #endif

    #ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
        specGloss.a = albedoAlpha * _Smoothness;
    #else
        specGloss.a = _Smoothness;
    #endif
#endif

    return specGloss;
}

half SampleOcclusionGrad(float2 uv, float2 dpdx, float2 dpdy)
{
#ifdef _OCCLUSIONMAP
// TODO: Controls things like these by exposing SHADER_QUALITY levels (low, medium, high)
#if defined(SHADER_API_GLES)
    return SAMPLE_TEXTURE2D_GRAD(_OcclusionMap, sampler_OcclusionMap, uv, dpdx, dpdy).g;
#else
    half occ = SAMPLE_TEXTURE2D_GRAD(_OcclusionMap, sampler_OcclusionMap, uv, dpdx, dpdy).g;
    return LerpWhiteTo(occ, _OcclusionStrength);
#endif
#else
    return 1.0;
#endif
}

half3 SampleKnitwear(float2 uv, float2 dpdx, float2 dpdy)
{
    return SAMPLE_TEXTURE2D_GRAD(_KnitwearMap, sampler_KnitwearMap, uv, dpdx, dpdy).rgb;
}

inline void InitializeKnitwearLitSurfaceData(float2 uv, out SurfaceData outSurfaceData)
{
    
	ZERO_INITIALIZE(SurfaceData, outSurfaceData); 
    float2 texCoord = uv;

    float2 dtdx = ddx(uv);
    float2 dtdy = ddy(uv);

    half2 scale = _KnitwearDivision / half2(_KnitwearAspect, 1.0);
    uv *= scale;

    float2 duvdx = dtdx * scale;
    float2 duvdy = dtdy * scale;

    KnitwearCoordinate(uv, texCoord, _KnitwearDivision, _KnitwearShear, _KnitwearDistortionStrength);
    texCoord /= scale;

    half4 albedoAlpha = SampleAlbedoAlphaGrad(texCoord, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap), dtdx, dtdy);
    outSurfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);

    half3 knitwearColor = SampleKnitwear(uv, duvdx, duvdy);
    outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb * knitwearColor;

    half4 specGloss = SampleMetallicSpecGlossGrad(uv, duvdx, duvdy, albedoAlpha.a);

#if _SPECULAR_SETUP
    outSurfaceData.metallic = 1.0h;
    outSurfaceData.specular = specGloss.rgb;
#else
    outSurfaceData.metallic = specGloss.r;
    outSurfaceData.specular = half3(0.0h, 0.0h, 0.0h);
#endif

    outSurfaceData.smoothness = specGloss.a;
    outSurfaceData.normalTS = SampleNormalGrad(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), duvdx, duvdy, _BumpScale);
    outSurfaceData.occlusion = SampleOcclusionGrad(uv, duvdx, duvdy);
    outSurfaceData.emission = SampleEmissionGrad(uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap), duvdx, duvdy);
}

#endif // UNIVERSAL_INPUT_SURFACE_PBR_INCLUDED