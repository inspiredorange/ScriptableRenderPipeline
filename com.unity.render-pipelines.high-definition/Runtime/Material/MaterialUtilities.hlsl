// Flipping or mirroring a normal can be done directly on the tangent space. This has the benefit to apply to the whole process either in surface gradient or not.
// This function will modify FragInputs and this is not propagate outside of GetSurfaceAndBuiltinData(). This is ok as tangent space is not use outside of GetSurfaceAndBuiltinData().
void ApplyDoubleSidedFlipOrMirror(inout FragInputs input)
{
#ifdef _DOUBLESIDED_ON
    // _DoubleSidedConstants is float3(-1, -1, -1) in flip mode and float3(1, 1, -1) in mirror mode
    float flipSign = input.isFrontFace ? 1.0 : _DoubleSidedConstants.z;
    // For the 'Flip' mode, we should not modify the tangent and the bitangent (which correspond
    // to the surface derivatives), and instead modify (invert) the displacements.
    input.worldToTangent[2] = flipSign * input.worldToTangent[2]; // normal

#ifndef SURFACE_GRADIENT
    // Do the stupid thing and just flip the TB. Conceptually wrong, but it works.
    float2 flipSigns = input.isFrontFace ? float2(1.0, 1.0) : _DoubleSidedConstants.xy;
    input.worldToTangent[0] = flipSigns.x * input.worldToTangent[0]; // tangent
    input.worldToTangent[1] = flipSigns.y * input.worldToTangent[1]; // bitangent
#endif // SURFACE_GRADIENT

#endif // _DOUBLESIDED_ON
}

// This function convert the tangent space normal/tangent to world space and orthonormalize it + apply a correction of the normal if it is not pointing towards the near plane
void GetNormalWS(FragInputs input, float3 normalTS, out float3 normalWS)
{
#ifdef SURFACE_GRADIENT

#ifdef _DOUBLESIDED_ON
    // Flip the displacements (the entire surface gradient) in the 'flip normal' mode.
    float flipSign = input.isFrontFace ? 1.0 : _DoubleSidedConstants.x;
    normalTS *= flipSign;
#endif // _DOUBLESIDED_ON

    normalWS = SurfaceGradientResolveNormal(input.worldToTangent[2], normalTS);
#else
    // We need to normalize as we use mikkt tangent space and this is expected (tangent space is not normalize)
    normalWS = normalize(TransformTangentToWorld(normalTS, input.worldToTangent));
#endif
}
