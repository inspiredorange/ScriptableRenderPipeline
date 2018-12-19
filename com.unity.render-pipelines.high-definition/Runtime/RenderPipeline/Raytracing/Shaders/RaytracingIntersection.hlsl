// Engine includes
#include "UnityRaytracingMeshUtils.cginc"

// The target acceleration acceleration structure
RaytracingAccelerationStructure 		_RaytracingAccelerationStructure;

// Ray data used for the intersections
float 									_RaytracingRayBias;
float 									_RaytracingRayMaxLength;

// Camera data required that is not part of the classic information
float 									_PixelSpreadAngle;

// Raycone structure that defines the stateof the ray
struct RayCone
{
	float width;
	float spreadAngle;
};

// Structure that defines the current state of the intersection
struct RayIntersection
{
	// Origin of the current ray
	float3 origin;
	// Direction of the current ray
	float3 incidentDirection;
	// Distance of the intersection
	float t;
	// Value that holds the color of the ray
	float3 color;
	// Cone representation of the ray
	RayCone cone;
};

struct AttributeData
{
	// Barycentric value of the intersection
	float2 barycentrics;
};

// Macro that interpolate any attribute using barycentric coordinates
#define INTERPOLATE_RAYTRACING_ATTRIBUTE(A0, A1, A2, BARYCENTRIC_COORDINATES) (A0 * BARYCENTRIC_COORDINATES.x + A1 * BARYCENTRIC_COORDINATES.y + A2 * BARYCENTRIC_COORDINATES.z)

// Structure to fill for intersections
struct IntersectionVertice
{
	// World space position of the vertex
	float3 	positionOS;
	// World space normal of the vertex
	float3 	normalOS;
	// World space normal of the vertex
	float3 	tangentOS;
	// UV coordinates
	float2 	texCoord0;
	float2 	texCoord1;
	float2 	texCoord2;
	float2 	texCoord3;
	// Vertex color
	float4 vertexColor;
	// Value used for LOD sampling
	float triangleArea;
	float texCoord0Area;
	float texCoord1Area;
	float texCoord2Area;
	float texCoord3Area;
};

// Fetch the intersetion vertex data for the target vertex
void FetchIntersectionVertex(uint vertexIndex, out IntersectionVertice outVertex)
{
    outVertex.positionOS  			= UnityRaytracingFetchVertexAttribute3(vertexIndex, kVertexAttributePosition);
    outVertex.normalOS    			= UnityRaytracingFetchVertexAttribute3(vertexIndex, kVertexAttributeNormal);
    outVertex.tangentOS    			= UnityRaytracingFetchVertexAttribute3(vertexIndex, kVertexAttributeTangent);
    outVertex.texCoord0    			= UnityRaytracingFetchVertexAttribute2(vertexIndex, kVertexAttributeTexCoord0);
    outVertex.texCoord1    			= UnityRaytracingFetchVertexAttribute2(vertexIndex, kVertexAttributeTexCoord1);
    outVertex.texCoord2    			= UnityRaytracingFetchVertexAttribute2(vertexIndex, kVertexAttributeTexCoord2);
    outVertex.texCoord3    			= UnityRaytracingFetchVertexAttribute2(vertexIndex, kVertexAttributeTexCoord3);
    outVertex.vertexColor    		= UnityRaytracingFetchVertexAttribute4(vertexIndex, kVertexAttributeColor);
}

void CurrentIntersectionVertice(AttributeData attributeData, out IntersectionVertice outVertex)
{
	// Fetch the indices of the currentr triangle
	uint3 triangleIndices = UnityRaytracingFetchTriangleIndices(PrimitiveIndex());

	// Fetch the 3 vertices
	IntersectionVertice v0, v1, v2;
	FetchIntersectionVertex(triangleIndices.x, v0);
	FetchIntersectionVertex(triangleIndices.y, v1);
	FetchIntersectionVertex(triangleIndices.z, v2);

	// Compute the full barycentric coordinates
	float3 barycentricCoordinates = float3(1.0 - attributeData.barycentrics.x - attributeData.barycentrics.y, attributeData.barycentrics.x, attributeData.barycentrics.y);

	// Interpolate all the data
	outVertex.positionOS = INTERPOLATE_RAYTRACING_ATTRIBUTE(v0.positionOS, v1.positionOS, v2.positionOS, barycentricCoordinates);
	outVertex.normalOS = INTERPOLATE_RAYTRACING_ATTRIBUTE(v0.normalOS, v1.normalOS, v2.normalOS, barycentricCoordinates);
	outVertex.tangentOS = INTERPOLATE_RAYTRACING_ATTRIBUTE(v0.tangentOS, v1.tangentOS, v2.tangentOS, barycentricCoordinates);
	outVertex.texCoord0 = INTERPOLATE_RAYTRACING_ATTRIBUTE(v0.texCoord0, v1.texCoord0, v2.texCoord0, barycentricCoordinates);
	outVertex.texCoord1 = INTERPOLATE_RAYTRACING_ATTRIBUTE(v0.texCoord1, v1.texCoord1, v2.texCoord1, barycentricCoordinates);
	outVertex.texCoord2 = INTERPOLATE_RAYTRACING_ATTRIBUTE(v0.texCoord2, v1.texCoord2, v2.texCoord2, barycentricCoordinates);
	outVertex.texCoord3 = INTERPOLATE_RAYTRACING_ATTRIBUTE(v0.texCoord3, v1.texCoord3, v2.texCoord3, barycentricCoordinates);
	outVertex.vertexColor = INTERPOLATE_RAYTRACING_ATTRIBUTE(v0.vertexColor, v1.vertexColor, v2.vertexColor, barycentricCoordinates);

	// Compute the lambda value
	outVertex.triangleArea = length(cross(v1.positionOS - v0.positionOS, v2.positionOS - v0.positionOS));
	outVertex.texCoord0Area = abs((v1.texCoord0.x - v0.texCoord0.x) * (v2.texCoord0.y - v0.texCoord0.y) - (v2.texCoord0.x - v0.texCoord0.x) * (v1.texCoord0.y - v0.texCoord0.y));
	outVertex.texCoord1Area = length(cross(float3(v1.texCoord1, 0.0f) - float3(v0.texCoord1, 0.0f), float3(v2.texCoord1, 0.0f) - float3(v0.texCoord1, 0.0f)));
	outVertex.texCoord2Area = length(cross(float3(v1.texCoord2, 0.0f) - float3(v0.texCoord2, 0.0f), float3(v2.texCoord2, 0.0f) - float3(v0.texCoord2, 0.0f)));
	outVertex.texCoord3Area = length(cross(float3(v1.texCoord3, 0.0f) - float3(v0.texCoord3, 0.0f), float3(v2.texCoord3, 0.0f) - float3(v0.texCoord3, 0.0f)));
}

#ifdef INTERSECTION_SHADING
void BuildFragInputsFromIntersection(IntersectionVertice currentVertex, out FragInputs outFragInputs)
{
	outFragInputs.positionSS = float4(0.0, 0.0, 0.0, 0.0);
	outFragInputs.positionRWS = mul(ObjectToWorld3x4(), float4(currentVertex.positionOS, 1.0)).xyz - _WorldSpaceCameraPos;
	outFragInputs.texCoord0 = float4(currentVertex.texCoord0, 0.0, 0.0);
	outFragInputs.texCoord1 = float4(currentVertex.texCoord1, 0.0, 0.0);
	outFragInputs.texCoord2 = float4(currentVertex.texCoord2, 0.0, 0.0);
	outFragInputs.texCoord3 = float4(currentVertex.texCoord3, 0.0, 0.0);
	outFragInputs.color = currentVertex.vertexColor;
	outFragInputs.isFrontFace = true;

	// Let's compute the object space binormal
	float3 binormal = cross(currentVertex.normalOS, currentVertex.tangentOS);
	float3x3 worldToObject = (float3x3)WorldToObject4x3();
	outFragInputs.worldToTangent[0] = normalize(mul(binormal, worldToObject));
	outFragInputs.worldToTangent[1] = normalize(mul(currentVertex.tangentOS, worldToObject));
	outFragInputs.worldToTangent[2] = normalize(mul(currentVertex.normalOS, worldToObject));
}
#endif