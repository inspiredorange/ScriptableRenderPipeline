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
            TEXTURE2D(_MegaRaysPerFrameTexture);
            TEXTURE2D(_CameraColorTexture);

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

                uint2 displayUnormCoord = uint2(displayTextOffsetX, 16.0 + displayTextOffsetY);
                uint2 unormCoord = input.positionCS.xy;
                float3 fontColor = float3(1.0, 1.0, 1.0);
                float4 result = LOAD_TEXTURE2D(_CameraColorTexture, input.texcoord.xy * _ScreenSize.xy); //float4(0.0, 0.0, 0.0, 1.0);

                DrawFloat(_MegaRaysPerFrameTexture[uint2(0, 0)].x, fontColor, unormCoord, displayUnormCoord, flipY, result.rgb);
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
