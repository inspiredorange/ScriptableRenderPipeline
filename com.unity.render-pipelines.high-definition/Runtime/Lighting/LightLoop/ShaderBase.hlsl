#ifndef __SHADERBASE_H__
#define __SHADERBASE_H__

#include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/Texture2DX.hlsl"

#ifdef SHADER_API_PSSL
    #ifndef Texture2DMS
        #define Texture2DMS         MS_Texture2D
    #endif

    #ifndef SampleCmpLevelZero
        #define SampleCmpLevelZero  SampleCmpLOD0
    #endif

    #ifndef firstbithigh
        #define firstbithigh        FirstSetBit_Hi
    #endif
#endif

#ifdef MSAA_ENABLED
    TEXTURE2DX_MSAA(float, g_depth_tex);

    float FetchDepthMSAA(uint2 pixCoord, uint sampleIdx)
    {
        float zdpth = LOAD_TEXTURE2DX_MSAA(g_depth_tex, pixCoord.xy, sampleIdx).x;
    #if UNITY_REVERSED_Z
        zdpth = 1.0 - zdpth;
    #endif
        return zdpth;
    }
#else
    TEXTURE2DX(g_depth_tex);

    float FetchDepth(uint2 pixCoord)
    {
        float zdpth = LOAD_TEXTURE2DX(g_depth_tex, pixCoord.xy).x;
    #if UNITY_REVERSED_Z
            zdpth = 1.0 - zdpth;
    #endif
        return zdpth;
    }
#endif

#endif
