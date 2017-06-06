#define EPSILON 0.000001

bool intersectRayTriangle(float3 orig,
						  float3 dir,
						  float3 v0,
						  float3 v1,
						  float3 v2) {
	float3 e1 = v1 - v0;
	float3 e2 = v2 - v0;
	float3 p = cross((float4)(dir, 0), (float4)(e2, 0)).xyz;
	
	float a = dot((float4)(e1, 0), (float4)(p, 0));
	if (-EPSILON < a && a < EPSILON) return false;
	float f = 1.0 / a;
	
	float3 s = orig - v0;
	float x = dot((float4)(s, 0), (float4)(p, 0)) * f;
	if (x < 0 || x > 1) return false;
	
	float3 q = cross((float4)(s, 0), (float4)(e1, 0)).xyz;
	float y = dot((float4)(dir, 0), (float4)(q, 0)) * f;
	if (y <0 || x + y > 1) return false;
	
	float z = dot((float4)(e2, 0), (float4)(q, 0)) * f;
	
	return z >= 0;
	
}

float getValue(int x, int y, int z, __global float* refIndex, int voxel_cnt) {
	if (x < 0 || x >= voxel_cnt) return -1.0f;
	if (y < 0 || y >= voxel_cnt) return -1.0f;
	if (z < 0 || z >= voxel_cnt) return -1.0f;
	int index = x*voxel_cnt*voxel_cnt + y*voxel_cnt + z;
	return refIndex[index];
}

// Check 3x3x3 neighborhood. Return TRUE for any difference.
bool isBorder(int x, int y, int z, __global float* refIndex, int voxel_cnt) {
	float r, thisr = refIndex[x*voxel_cnt*voxel_cnt + y*voxel_cnt + z];

	for (int i = x-1; i <= x+1; i++) {
		for (int j = y-1; j <= y+1; j++) {
			for (int k = z-1; k <= z+1; k++) {
				r = getValue(i, j, k, refIndex, voxel_cnt);
				if (r > 0 && fabs(r - thisr) > EPSILON) return true;
			}
		}
	}
	
	return false;
}

__kernel void voxelize(__global ushort* indices,
					   __global float3* indexed_vertices,
					   __global float* refIndex,
					   int index_cnt,
					   int voxel_cnt) {
	
	int i = get_global_id(0);
	int x = i / (voxel_cnt * voxel_cnt);
	int y = (i  % (voxel_cnt * voxel_cnt)) / voxel_cnt;
	int z = i % voxel_cnt;
	int intersectCnt = 0;
	float3 pos = float3((x-voxel_cnt/2.0)/(voxel_cnt/2.0), (y-voxel_cnt/2.0)/(voxel_cnt/2.0), (z-voxel_cnt/2.0)/(voxel_cnt/2.0));
	for (int i = 0; i < voxel_cnt; i += 3) {
		if (intersectRayTriangle(pos, float3(1,0,0), indexed_vertices[indices[i]], indexed_vertices[indices[i+1]], indexed_vertices[indices[i+2]]))
			intersectCnt++;
	}
	if (intersectCnt % 2 == 1) refIndex[i] = 1.5f;
	else refIndex[i] = 1.0f;
	
	if (isBorder(x, y, z, refIndex, voxel_cnt)) {
		// super sample
		refIndex[i] = 0;
		float voxel_len = 2.0f / voxel_cnt;
		
		for (float a = -0.375; a <= 0.375; a += 0.25) {
			for (float b = -0.375; b <= 0.375; b += 0.25) {
				for (float c = -0.375; c <= 0.375; c += 0.25) {
					float3 newPos = pos + float3(a, b, c)*voxel_len;
					int intersectCnt = 0;
					for (int i = 0; i < voxel_cnt; i += 3) {
						if (intersectRayTriangle(newPos, float3(1,0,0), indexed_vertices[indices[i]], indexed_vertices[indices[i+1]], indexed_vertices[indices[i+2]]))
							intersectCnt++;
					}
					if (intersectCnt % 2 == 1) refIndex[i] += 1.5f/64;
					else refIndex[i] += 1.0f/64;
				}
			}
		}
	}
	
	// Gaussin filter

}

