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
        RTHandleSystem.RTHandle m_TotalMegaRaysTex = null;
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
        int _MegaRaysPerFrame = Shader.PropertyToID("_MegaRaysPerFrame");
        int _MegaRaysTex = Shader.PropertyToID("_MegaRaysPerFrameTexture");
        int _FontColor = Shader.PropertyToID("_FontColor");
        int m_CountInMegaRays;

        public void Init(RenderPipelineResources renderPipelineResources)
        {
            m_Blit = CoreUtils.CreateEngineMaterial(renderPipelineResources.shaders.blitPS);
            m_DrawRayCount = CoreUtils.CreateEngineMaterial(renderPipelineResources.shaders.drawRayCountPS);
            m_RayCountCompute = renderPipelineResources.shaders.countRays;
            s_DebugFontTex = renderPipelineResources.textures.debugFontTex;
            m_RayCountTex = RTHandles.Alloc(Vector2.one, filterMode: FilterMode.Point, colorFormat: GraphicsFormat.R16G16B16A16_SFloat, enableRandomWrite: true, useMipMap: false, name: "RayCountTex");
            m_TotalAORaysTex = RTHandles.Alloc(1, 1, filterMode: FilterMode.Point, colorFormat: GraphicsFormat.R16_UInt, enableRandomWrite: true, useMipMap: false, name: "TotalAORaysTex");
            m_TotalReflectionRaysTex = RTHandles.Alloc(1, 1, filterMode: FilterMode.Point, colorFormat: GraphicsFormat.R16_UInt, enableRandomWrite: true, useMipMap: false, name: "TotalReflectionRaysTex");
            m_TotalAreaShadowRaysTex = RTHandles.Alloc(1, 1, filterMode: FilterMode.Point, colorFormat: GraphicsFormat.R16_UInt, enableRandomWrite: true, useMipMap: false, name: "TotalAreaShadowRaysTex");
            m_TotalMegaRaysTex = RTHandles.Alloc(1, 1, filterMode: FilterMode.Point, colorFormat: GraphicsFormat.R16G16B16A16_SFloat, enableRandomWrite: true, useMipMap: false, name: "TotalRaysTex");
        }

        public void Release()
        {
            CoreUtils.Destroy(m_Blit);
            CoreUtils.Destroy(m_DrawRayCount);

            RTHandles.Release(m_RayCountTex);
            RTHandles.Release(m_TotalAORaysTex);
            RTHandles.Release(m_TotalReflectionRaysTex);
            RTHandles.Release(m_TotalAreaShadowRaysTex);
            RTHandles.Release(m_TotalMegaRaysTex);
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
            // Clear Total Raycount Texture
            int clearTotalKernel = m_RayCountCompute.FindKernel("CS_ClearTotal");
            cmd.SetComputeTextureParam(m_RayCountCompute, clearTotalKernel, _TotalAORaysTex, m_TotalAORaysTex);
            cmd.SetComputeTextureParam(m_RayCountCompute, clearTotalKernel, _TotalReflectionRaysTex, m_TotalReflectionRaysTex);
            cmd.SetComputeTextureParam(m_RayCountCompute, clearTotalKernel, _TotalAreaShadowRaysTex, m_TotalAreaShadowRaysTex);
            cmd.DispatchCompute(m_RayCountCompute, clearTotalKernel, 1, 1, 1);

            // Clear             
            int width = camera.actualWidth;
            int height = camera.actualHeight;
            uint groupSizeX = 0, groupSizeY = 0, groupSizeZ = 0;
            int clearKernel = m_RayCountCompute.FindKernel("CS_Clear");
            m_RayCountCompute.GetKernelThreadGroupSizes(clearKernel, out groupSizeX, out groupSizeY, out groupSizeZ);
            int dispatchWidth = 0, dispatchHeight = 0;
            dispatchWidth = (int)((width + groupSizeX - 1) / groupSizeX);
            dispatchHeight = (int)((height + groupSizeY - 1) / groupSizeY);
            cmd.SetComputeTextureParam(m_RayCountCompute, clearKernel, HDShaderIDs._RayCountTexture, m_RayCountTex);
            cmd.DispatchCompute(m_RayCountCompute, clearKernel, dispatchWidth, dispatchHeight, 1);
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

                // Convert to MegaRays
                int convertToMRaysIdx = m_RayCountCompute.FindKernel("CS_GetMegaRaysPerFrameTexture");
                cmd.SetComputeTextureParam(m_RayCountCompute, convertToMRaysIdx, _MegaRaysTex, m_TotalMegaRaysTex);
                cmd.SetComputeTextureParam(m_RayCountCompute, convertToMRaysIdx, _TotalAORaysTex, m_TotalAORaysTex);
                cmd.SetComputeTextureParam(m_RayCountCompute, convertToMRaysIdx, _TotalAreaShadowRaysTex, m_TotalAreaShadowRaysTex);
                cmd.SetComputeTextureParam(m_RayCountCompute, convertToMRaysIdx, _TotalReflectionRaysTex, m_TotalReflectionRaysTex);
                cmd.DispatchCompute(m_RayCountCompute, convertToMRaysIdx, 1, 1, 1);

                // Draw overlay
                m_DrawRayCountProperties.SetTexture(_MegaRaysTex, m_TotalMegaRaysTex);
                m_DrawRayCountProperties.SetTexture(HDShaderIDs._CameraColorTexture, colorTex);
                m_DrawRayCountProperties.SetTexture(HDShaderIDs._DebugFont, s_DebugFontTex);
                m_DrawRayCountProperties.SetColor(_FontColor, fontColor);
                CoreUtils.DrawFullScreen(cmd, m_DrawRayCount, m_DrawRayCountProperties);
            }
        }
    }
#endif
}
