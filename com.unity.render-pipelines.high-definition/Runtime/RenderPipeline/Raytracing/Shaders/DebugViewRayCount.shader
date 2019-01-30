Shader "Hidden/HDRP/DebugViewRayCount"
{
    Properties
    {
        _CameraColorTexture("_CameraColorTexture", 2D) = "white" {}
		_TotalAORaysTex("_TotalAORaysTex", 2D) = "black" {}
		_TotalReflectionRaysTex("_TotalReflectionRaysTex", 2D) = "black" {}
		_TotalAreaShadowRaysTex("_TotalAreaShadowRaysTex", 2D) = "black" {}
        _FontColor("_FontColor", Color) = (1,1,1,1)
    }
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

            StructuredBuffer<uint> _TotalRayCountBuffer;
            TEXTURE2D(_CameraColorTexture);
            float4 _FontColor;

            struct Attributes
            {
                uint vertexID : SV_VertexID;
            };

            struct Varyings
            {
                float4  positionCS  : SV_POSITION;
                float2  texcoord    : TEXCOORD0;
            };

            Varyings Vert(Attributes input)
            {
                Varyings output;
                output.positionCS = GetFullScreenTriangleVertexPosition(input.vertexID);
                output.texcoord = GetFullScreenTriangleTexCoord(input.vertexID);
                return output;
            }

            float4 AlphaBlend(float4 c0, float4 c1) // c1 over c0
            {
                return float4(lerp(c0.rgb, c1.rgb, c1.a), c0.a + c1.a - c0.a * c1.a);
            }
            
            float4 Frag(Varyings input) : SV_Target
            {
                bool flipY = ShouldFlipDebugTexture();

                // Display message offset:
                int displayTextOffsetX = 1.5 * DEBUG_FONT_TEXT_WIDTH;
                int displayTextOffsetY;
                if (flipY)
                {
                    input.texcoord.y = 1.0 - input.texcoord.y;
                    displayTextOffsetY = DEBUG_FONT_TEXT_HEIGHT;
                }
                else
                {
                    displayTextOffsetY = -DEBUG_FONT_TEXT_HEIGHT;
                }
                // Get MRays/frame
                float aoMRays = (float)_TotalRayCountBuffer[0] / (1000.0f * 1000.0f);
                float reflectionMRays = (float)_TotalRayCountBuffer[1] / (1000.0f * 1000.0f);
                float areaShadowMRays = (float)_TotalRayCountBuffer[2] / (1000.0f * 1000.0f);
				float totalMRays = aoMRays + reflectionMRays + areaShadowMRays;

                uint2 displayUnormCoord = uint2(displayTextOffsetX, abs(displayTextOffsetY) * 4);
                uint2 unormCoord = input.positionCS.xy;
                float3 fontColor = _FontColor.rgb;
                float4 result = LOAD_TEXTURE2D(_CameraColorTexture, input.texcoord.xy * _ScreenSize.xy); //float4(0.0, 0.0, 0.0, 1.0);

                DrawCharacter('A', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('O', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter(':', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawFloat(aoMRays, fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('M', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('R', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('a', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('y', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('s', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('/', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('f', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('r', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('a', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('m', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('e', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);

                displayUnormCoord = uint2(displayTextOffsetX, abs(displayTextOffsetY) * 3);
                DrawCharacter('R', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('e', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('f', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('l', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('e', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('c', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('t', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('i', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('o', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('n', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter(':', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawFloat(reflectionMRays, fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('M', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('R', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('a', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('y', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('s', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('/', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('f', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('r', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('a', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('m', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('e', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);

                displayUnormCoord = uint2(displayTextOffsetX, abs(displayTextOffsetY) * 2);
                DrawCharacter('A', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('r', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('e', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('a', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('S', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('h', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('a', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('d', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('o', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('w', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter(':', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawFloat(areaShadowMRays, fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('M', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('R', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('a', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('y', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('s', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('/', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('f', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('r', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('a', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('m', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('e', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);

                displayUnormCoord = uint2(displayTextOffsetX, abs(displayTextOffsetY));
                DrawCharacter('T', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('o', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('t', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('a', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('l', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter(':', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawFloat(totalMRays, fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('M', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('R', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('a', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('y', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('s', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('/', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('f', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('r', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('a', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('m', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                DrawCharacter('e', fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
                return result;
            }

            ENDHLSL
        }
    }
    Fallback Off
}
