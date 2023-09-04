#define desatlevel 1.

void SetupMaterial(inout Material mat){
	vec4 color = getTexel(vTexCoord.st);
	float gray = (color.r+color.g+color.b)*2.;
	gray=min(0.7,0.5+(gray-0.5)*0.3);
	mat.Base = vec4(gray*0.7,gray*0.6,gray*0.5,color.a);
	mat.Normal = ApplyNormalMap(vTexCoord.st);
}
