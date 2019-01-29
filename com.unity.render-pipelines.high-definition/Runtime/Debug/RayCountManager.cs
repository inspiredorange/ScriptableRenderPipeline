using UnityEngine.Rendering;

namespace UnityEngine.Experimental.Rendering.HDPipeline
{
#if ENABLE_RAYTRACING
    public class RayCountManager
    {
        // Ray count UAV
        RTHandleSystem.RTHandle m_RayCountTex = null;
        RTHandleSystem.RTHandle m_TotalAORaysTex = null;
        RTHandleSystem.RTHandle m_TotalReflectionRaysTex = null;
        RTHandleSystem.RTHandle m_TotalAreaShadowRaysTex = null;
        Texture2D s_DebugFontTex = null;

        // Material used to blit the output texture into the camera render target
        Material m_Blit;
        Material m_DrawRayCount;
        MaterialPropertyBlock m_DrawRayCountProperties = new MaterialPropertyBlock();
        // Raycount shader
        ComputeShader m_RayCountCompute;

        int _TotalAORaysTex = Shader.PropertyToID("_TotalAORaysTex");
        int _TotalReflectionRaysTex = Shader.PropertyToID("_TotalReflectionRaysTex");
        int _TotalAreaShadowRaysTex = Shader.PropertyToID("_TotalAreaShadowRaysTex");
        int _FontColor = Shader.PropertyToID("_FontColor");

        public void Init(RenderPipelineResources renderPipelineResources)
        {
            m_Blit = CoreUtils.CreateEngineMaterial(renderPipelineResources.shaders.blitPS);
            m_DrawRayCount = CoreUtils.CreateEngineMaterial(renderPipelineResources.shaders.debugViewRayCountPS);
            m_RayCountCompute = renderPipelineResources.shaders.countTracedRays;
            s_DebugFontTex = renderPipelineResources.textures.debugFontTex;
            // UINT textures must use UINT32, since groupshared uint used to synchronize counts is allocated as a UINT32
            m_RayCountTex = RTHandles.Alloc(Vector2.one, filterMode: FilterMode.Point, colorFormat: GraphicsFormat.R32G32B32A32_UInt, enableRandomWrite: true, useMipMap: false, name: "RayCountTex");
            m_TotalAORaysTex = RTHandles.Alloc(1, 1, filterMode: FilterMode.Point, colorFormat: GraphicsFormat.R32_UInt, enableRandomWrite: true, useMipMap: false, name: "TotalAORaysTex");
            m_TotalReflectionRaysTex = RTHandles.Alloc(1, 1, filterMode: FilterMode.Point, colorFormat: GraphicsFormat.R32_UInt, enableRandomWrite: true, useMipMap: false, name: "TotalReflectionRaysTex");
            m_TotalAreaShadowRaysTex = RTHandles.Alloc(1, 1, filterMode: FilterMode.Point, colorFormat: GraphicsFormat.R32_UInt, enableRandomWrite: true, useMipMap: false, name: "TotalAreaShadowRaysTex");
        }

        public void Release()
        {
            CoreUtils.Destroy(m_Blit);
            CoreUtils.Destroy(m_DrawRayCount);

            RTHandles.Release(m_RayCountTex);
            RTHandles.Release(m_TotalAORaysTex);
            RTHandles.Release(m_TotalReflectionRaysTex);
            RTHandles.Release(m_TotalAreaShadowRaysTex);
        }

        public RTHandleSystem.RTHandle rayCountTex
        {
            get
            {
                return m_RayCountTex;
            }
        }

        public void ClearRayCount(CommandBuffer cmd, HDCamera camera)
        {
            HDUtils.SetRenderTarget(cmd, camera, m_TotalAORaysTex, ClearFlag.Color);
            HDUtils.SetRenderTarget(cmd, camera, m_TotalReflectionRaysTex, ClearFlag.Color);
            HDUtils.SetRenderTarget(cmd, camera, m_TotalAreaShadowRaysTex, ClearFlag.Color);            
            HDUtils.SetRenderTarget(cmd, camera, m_RayCountTex, ClearFlag.Color);
        }

        public void RenderRayCount(CommandBuffer cmd, HDCamera camera, RTHandleSystem.RTHandle colorTex, Color fontColor)
        {
            using (new ProfilingSample(cmd, "Raytracing Debug Overlay", CustomSamplerId.RaytracingDebug.GetSampler()))
            {
                int width = camera.actualWidth;
                int height = camera.actualHeight;

                // Sum across all rays per pixel
                int countKernelIdx = m_RayCountCompute.FindKernel("CS_CountRays");
                uint groupSizeX = 0, groupSizeY = 0, groupSizeZ = 0;
                m_RayCountCompute.GetKernelThreadGroupSizes(countKernelIdx, out groupSizeX, out groupSizeY, out groupSizeZ);
                int dispatchWidth = 0, dispatchHeight = 0;
                dispatchWidth = (int)((width + groupSizeX - 1) / groupSizeX);
                dispatchHeight = (int)((height + groupSizeY - 1) / groupSizeY);
                cmd.SetComputeTextureParam(m_RayCountCompute, countKernelIdx, HDShaderIDs._RayCountTexture, m_RayCountTex);
                cmd.SetComputeTextureParam(m_RayCountCompute, countKernelIdx, _TotalAORaysTex, m_TotalAORaysTex);
                cmd.SetComputeTextureParam(m_RayCountCompute, countKernelIdx, _TotalReflectionRaysTex, m_TotalReflectionRaysTex);
                cmd.SetComputeTextureParam(m_RayCountCompute, countKernelIdx, _TotalAreaShadowRaysTex, m_TotalAreaShadowRaysTex);
                cmd.DispatchCompute(m_RayCountCompute, countKernelIdx, dispatchWidth, dispatchHeight, 1);
                
                // Draw overlay
                m_DrawRayCountProperties.SetTexture(_TotalAORaysTex, m_TotalAORaysTex);
                m_DrawRayCountProperties.SetTexture(_TotalReflectionRaysTex, m_TotalReflectionRaysTex);
                m_DrawRayCountProperties.SetTexture(_TotalAreaShadowRaysTex, m_TotalAreaShadowRaysTex);
                m_DrawRayCountProperties.SetTexture(HDShaderIDs._CameraColorTexture, colorTex);
                m_DrawRayCountProperties.SetTexture(HDShaderIDs._DebugFont, s_DebugFontTex);
                m_DrawRayCountProperties.SetColor(_FontColor, fontColor);
                CoreUtils.DrawFullScreen(cmd, m_DrawRayCount, m_DrawRayCountProperties);
            }
        }
    }
#endif
}
