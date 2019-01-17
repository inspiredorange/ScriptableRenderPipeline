Shader "Hidden/HDRP/DebugViewRayCount"
{
    SubShader
    {
        Tags{ "RenderPipeline" = "HDRenderPipeline" }
        Pass
        {
            ZWrite Off
            Cull Off
            ZTest Always
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma target 4.5
            #pragma only_renderers d3d11 ps4 xboxone vulkan metal switch

            #pragma vertex Vert
            #pragma fragment Frag

            //-------------------------------------------------------------------------------------
            // Include
            //-------------------------------------------------------------------------------------

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Debug/DebugDisplay.hlsl"
        
            //-------------------------------------------------------------------------------------
            // variable declaration
            //-------------------------------------------------------------------------------------

            //uint _NumMegaRays;
            RWTexture2D<float> _MegaRaysPerFrameTexture;

            struct Attributes
            {
                uint vertexID : SV_VertexID;
            };

            struct Varyings
            {
                float4  positionCS  : SV_POSITION;
                float2  texcoord    : TEXCOORD1;
            };

            Varyings Vert(Attributes input)
            {
                Varyings output;
                output.positionCS = GetFullScreenTriangleVertexPosition(input.vertexID);
                output.texcoord = GetFullScreenTriangleTexCoord(input.vertexID);
                if (ShouldFlipDebugTexture())
                {
                    output.texcoord.y = 1.0 - output.texcoord.y;
                }
                return output;
            }

            float4 AlphaBlend(float4 c0, float4 c1) // c1 over c0
            {
                return float4(lerp(c0.rgb, c1.rgb, c1.a), c0.a + c1.a - c0.a * c1.a);
            }
            
            float4 Frag(Varyings input) : SV_Target
            {
                // For debug shaders, Viewport can be at a non zero (x,y) but the pipeline render targets all starts at (0,0)
                // input.positionCS in in pixel coordinate relative to the render target origin so they will be offsted compared to internal render textures
                // To solve that, we compute pixel coordinates from full screen quad texture coordinates which start correctly at (0,0)
                uint2 pixelCoord = uint2(input.texcoord.xy * _ScreenSize.xy);
                int2 tileCoord = (float2)pixelCoord / 16;
                int2 offsetInTile = pixelCoord - tileCoord * 16;
                
                float4 result = float4(0.0, 0.0, 0.0, 0.0);
                
                // Print MRays/frame in corner of screen
                int kMaxNumDigits = 5; 
                if (tileCoord.y < 1 && tileCoord.x < kMaxNumDigits)
                {
                    float4 result2 = float4(.1,.1,.1,.9);
                    int2 fontCoord = int2(pixelCoord.x, offsetInTile.y);

                    int digit = 0;
                    int modulo = pow(10, tileCoord.x + 1);
                    int divisor = pow(10, tileCoord.x);
                    // digit = (int)floor(fmod((float)_NumMegaRays, 10) / divisor);
                   // digit = (int)floor(fmod((float)_MegaRaysPerFrameTexture[uint2(0, 0)], 10) / divisor);
                    digit = (int)_MegaRaysPerFrameTexture[uint2(0, 0)];
                    if (SampleDebugFontNumber(offsetInTile, digit))
                        result = float4(0.0, 0.0, 0.0, 1.0);
                    if (SampleDebugFontNumber(offsetInTile + 1, digit))
                        result = float4(1.0, 1.0, 1.0, 1.0);

                    //result = AlphaBlend(result, float4(0.0, .3, .2, .9));
                }
                return result;
            }

            ENDHLSL
        }
    }
    Fallback Off
}
