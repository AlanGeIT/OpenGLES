//SkyboxShader.fsh
//fragment Shader

uniform highp mat4  u_mvpMatrix;    // MVP矩阵变化
uniform samplerCube u_unitCube[1];  // 立方体贴图 纹理 采样器
varying lowp vec3   v_texCoord[1];  // 纹理坐标

void main()
{
    // textureCube(sampler, p)
    // sampler:指定采样的纹理
    // p:指定纹理将被采样的纹理坐标。
    gl_FragColor = textureCube(u_unitCube[0], v_texCoord[0]);
}
