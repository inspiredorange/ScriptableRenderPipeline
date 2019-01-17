using UnityEngine.Rendering;

namespace UnityEngine.Experimental.Rendering.HDPipeline
{
#if ENABLE_RAYTRACING
    public class RayCountManager
    {
        // Ray count UAV
        RTHandleSystem.RTHandle m_RayCountTex = null;
        RTHandleSystem.RTHandle m_TotalRaysTex = null;
        RTHandleSystem.RTHandle m_TotalMegaRaysTex = null;

        // Material used to blit the output texture into the camera render target
        Material m_Blit;
        Material m_DrawRayCount;
        MaterialPropertyBlock m_DrawRayCountProperties = new MaterialPropertyBlock();
        // Raycount shader
        ComputeShader m_RayCountCompute;

        int _TotalRaysTex = Shader.PropertyToID("_TotalRaysTex");
        int _MegaRaysPerFrame = Shader.PropertyToID("_MegaRaysPerFrame");
        int _MegaRaysTex = Shader.PropertyToID("_MegaRaysPerFrameTexture");
        int m_CountInMegaRays;

        public void Init(RenderPipelineResources renderPipelineResources)
        {
            m_Blit = CoreUtils.CreateEngineMaterial(renderPipelineResources.shaders.blitPS);
            m_DrawRayCount = CoreUtils.CreateEngineMaterial(renderPipelineResources.shaders.drawRayCountPS);
            m_RayCountCompute = renderPipelineResources.shaders.countRays;
            m_RayCountTex = RTHandles.Alloc(Vector2.one, filterMode: FilterMode.Point, colorFormat: RenderTextureFormat.ARGBHalf, sRGB: false, enableRandomWrite: true, useMipMap: false, name: "RayCountTex");
            m_TotalRaysTex = RTHandles.Alloc(1, 1, filterMode: FilterMode.Point, colorFormat: RenderTextureFormat.RInt, sRGB: false, enableRandomWrite: true, useMipMap: false, name: "TotalRaysTex");
            m_TotalMegaRaysTex = RTHandles.Alloc(1, 1, filterMode: FilterMode.Point, colorFormat: RenderTextureFormat.RFloat, sRGB: false, enableRandomWrite: true, useMipMap: false, name: "TotalRaysTex");
        }

        public void Release()
        {
            CoreUtils.Destroy(m_Blit);
            RTHandles.Release(m_RayCountTex);
            RTHandles.Release(m_TotalRaysTex);
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
            //m_RayCountCompute.SetTexture(clearTotalKernel, _TotalRaysTex, m_TotalRaysTex);
            //m_RayCountCompute.Dispatch(clearTotalKernel, 1, 1, 1);
            cmd.SetComputeTextureParam(m_RayCountCompute, clearTotalKernel, _TotalRaysTex, m_TotalRaysTex);
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
            //m_RayCountCompute.SetTexture(clearKernel, HDShaderIDs._RayCountTexture, m_RayCountTex);
            //m_RayCountCompute.Dispatch(clearKernel, dispatchWidth, dispatchHeight, 1);
            cmd.SetComputeTextureParam(m_RayCountCompute, clearKernel, HDShaderIDs._RayCountTexture, m_RayCountTex);
            cmd.DispatchCompute(m_RayCountCompute, clearKernel, dispatchWidth, dispatchHeight, 1);
        }

        public void RenderRayCount(CommandBuffer cmd, HDCamera camera)
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
                //m_RayCountCompute.SetTexture(countKernelIdx, HDShaderIDs._RayCountTexture, m_RayCountTex);
                //m_RayCountCompute.SetTexture(countKernelIdx, _TotalRaysTex, m_TotalRaysTex);
                //m_RayCountCompute.Dispatch(countKernelIdx, dispatchWidth, dispatchHeight, 1);
                cmd.SetComputeTextureParam(m_RayCountCompute, countKernelIdx, HDShaderIDs._RayCountTexture, m_RayCountTex);
                cmd.SetComputeTextureParam(m_RayCountCompute, countKernelIdx, _TotalRaysTex, m_TotalRaysTex);
                cmd.DispatchCompute(m_RayCountCompute, countKernelIdx, dispatchWidth, dispatchHeight, 1);

                // Convert to MegaRays
                int convertToMRaysIdx = m_RayCountCompute.FindKernel("CS_GetMegaRaysPerFrameTexture");
                //m_RayCountCompute.SetTexture(convertToMRaysIdx, _MegaRaysTex, m_TotalMegaRaysTex);
                //m_RayCountCompute.SetTexture(convertToMRaysIdx, _TotalRaysTex, m_TotalRaysTex);
                //m_RayCountCompute.Dispatch(convertToMRaysIdx, 1, 1, 1);
                cmd.SetComputeTextureParam(m_RayCountCompute, convertToMRaysIdx, _MegaRaysTex, m_TotalMegaRaysTex);
                cmd.SetComputeTextureParam(m_RayCountCompute, convertToMRaysIdx, _TotalRaysTex, m_TotalRaysTex);
                cmd.DispatchCompute(m_RayCountCompute, convertToMRaysIdx, 1, 1, 1);

                // Draw overlay
                m_DrawRayCount.SetTexture(_MegaRaysTex, m_TotalMegaRaysTex);
                m_DrawRayCountProperties.SetTexture(_MegaRaysTex, m_TotalMegaRaysTex);
                CoreUtils.DrawFullScreen(cmd, m_DrawRayCount, m_DrawRayCountProperties, 0);
                //cmd.DrawProcedural(Matrix4x4.identity, m_DrawRayCount, 0, MeshTopology.Triangles, 3, 1, m_DrawRayCountProperties);
            }
        }
    }
#endif
}
