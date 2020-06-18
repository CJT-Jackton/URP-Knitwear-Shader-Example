#ifndef UNIVERSAL_KNITWEAR_UNLIT_INPUT_INCLUDED
#define UNIVERSAL_KNITWEAR_UNLIT_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
half4 _BaseColor;
half _Cutoff;
half _KnitwearDivision;
half _KnitwearAspect;
half _KnitwearShear;
half _KnitwearDistortionStrength;
CBUFFER_END

TEXTURE2D(_KnitwearMap);        SAMPLER(sampler_KnitwearMap);

#endif