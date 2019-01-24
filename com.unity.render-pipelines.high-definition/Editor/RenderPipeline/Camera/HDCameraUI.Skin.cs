using UnityEditor.Rendering;
using UnityEngine;

namespace UnityEditor.Experimental.Rendering.HDPipeline
{
    static partial class HDCameraUI
    {
        const string generalSettingsHeaderContent = "General";
        const string physicalSettingsHeaderContent = "Physical Settings";
        const string outputSettingsHeaderContent = "Output Settings";
        const string xrSettingsHeaderContent = "XR Settings";

        const string clippingPlaneMultiFieldTitle = "Clipping Planes";

        const string msaaWarningMessage = "Manual MSAA target set with deferred rendering. This will lead to undefined behavior.";

        static readonly GUIContent clearModeContent = EditorGUIUtility.TrTextContent("Clear Mode", "The Clear Mode HDRP Cameras use to clear the screen.");
        static readonly GUIContent backgroundColorContent = EditorGUIUtility.TrTextContent("Background Color", "The color HDRP uses to clear the screen when you set Clear Mode to Background Color.");
        static readonly GUIContent clearDepthContent = EditorGUIUtility.TrTextContent("Clear Depth", "The Camera clears the depth buffer before rendering.");
        static readonly GUIContent cullingMaskContent = EditorGUIUtility.TrTextContent("Culling Mask");
        static readonly GUIContent volumeLayerMaskContent = EditorGUIUtility.TrTextContent("Volume Layer Mask");
        static readonly GUIContent volumeAnchorOverrideContent = EditorGUIUtility.TrTextContent("Volume Anchor Override");
        static readonly GUIContent occlusionCullingContent = EditorGUIUtility.TrTextContent("Occlusion Culling");

        static readonly GUIContent projectionContent = EditorGUIUtility.TrTextContent("Projection", "How the Camera renders perspective.\n\nChoose Perspective to render objects with perspective.\n\nChoose Orthographic to render objects uniformly, with no sense of perspective.");
        static readonly GUIContent sizeContent = EditorGUIUtility.TrTextContent("Size");
        static readonly GUIContent fieldOfViewContent = EditorGUIUtility.TrTextContent("Field of View", "The height of the Camera’s view angle, measured in degrees along the local Y axis.");
        static readonly GUIContent nearPlaneContent = EditorGUIUtility.TrTextContent("Near", "The closest point relative to the camera that drawing occurs.");
        static readonly GUIContent farPlaneContent = EditorGUIUtility.TrTextContent("Far", "The furthest point relative to the camera that drawing occurs.");

        static readonly GUIContent renderingPathContent = EditorGUIUtility.TrTextContent("Custom Frame Settings", "Define the custom Frame Settings for this Camera to use.");

        static readonly GUIContent apertureContent = EditorGUIUtility.TrTextContent("Aperture");
        static readonly GUIContent shutterSpeedContent = EditorGUIUtility.TrTextContent("Shutter Speed (1 / x)");
        static readonly GUIContent isoContent = EditorGUIUtility.TrTextContent("ISO");

        static readonly GUIContent viewportContent = EditorGUIUtility.TrTextContent("Viewport Rect", "Four values that indicate where on the screen HDRP draws this Camera view. Measured in Viewport Coordinates (values in the range of [0, 1]).");
        static readonly GUIContent depthContent = EditorGUIUtility.TrTextContent("Depth");
#if ENABLE_MULTIPLE_DISPLAYS
        static readonly GUIContent targetDisplayContent = EditorGUIUtility.TrTextContent("Target Display");
#endif


        static readonly GUIContent stereoSeparationContent = EditorGUIUtility.TrTextContent("Stereo Separation");
        static readonly GUIContent stereoConvergenceContent = EditorGUIUtility.TrTextContent("Stereo Convergence");
        static readonly GUIContent targetEyeContent = EditorGUIUtility.TrTextContent("Target Eye");
        static readonly GUIContent[] k_TargetEyes = //order must match k_TargetEyeValues
        {
            new GUIContent("Both"),
            new GUIContent("Left"),
            new GUIContent("Right"),
            new GUIContent("None (Main Display)"),
        };

    }
}
