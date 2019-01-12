using UnityEngine.Rendering;

namespace UnityEngine.Experimental.Rendering.HDPipeline
{
#if ENABLE_RAYTRACING
    public class DebugRayTrace
    {
        // Ray count UAV
        RTHandleSystem.RTHandle m_RayCountTex = null;
        
        // Material used to blit the output texture into the camera render target
        Material m_Blit;
        Material m_DrawRayCount;
        // Raycount shader
        ComputeShader m_RayCountCompute;

        public void Init(RenderPipelineResources renderPipelineResources)
        {
            m_Blit = CoreUtils.CreateEngineMaterial(renderPipelineResources.shaders.blitPS);
            m_DrawRayCount = CoreUtils.CreateEngineMaterial(renderPipelineResources.shaders.drawRayCountPS);
            m_RayCountCompute = renderPipelineResources.shaders.countRays;
            m_RayCountTex = RTHandles.Alloc(Vector2.one, filterMode: FilterMode.Point, colorFormat: RenderTextureFormat.ARGBHalf, sRGB: false, enableRandomWrite: true, useMipMap: false, name: "RayCountBuffer");
        }

        public void Release()
        {
            CoreUtils.Destroy(m_Blit);
            RTHandles.Release(m_RayCountTex);
        }

        public RTHandleSystem.RTHandle rayCountTex
        {
            get
            {
                return m_RayCountTex;
            }
        }

        public void ClearRayCount(CommandBuffer cmd)
        {
            int clearKernelIdx = m_RayCountCompute.FindKernel("CS_Clear");
            m_RayCountCompute.SetTexture(clearKernelIdx, HDShaderIDs._RayCountTexture, m_RayCountTex);
        }

        public void RenderRayCount(CommandBuffer cmd)
        {
        }
    }
#endif
}
