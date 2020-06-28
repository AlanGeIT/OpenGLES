//SkyboxShader.vsh
//Vertex Shader


attribute vec3      a_position;     // 顶点
uniform highp mat4  u_mvpMatrix;    // mvp矩阵
uniform samplerCube u_unitCube[1];  // 纹理贴图
varying lowp vec3   v_texCoord[1];  // 纹理坐标

void main()
{
    // 获取纹理的位置
    v_texCoord[0] = a_position;
   
    // 修改顶点位置 = MVP矩阵 * 顶点
    // vec4(a_position, 1.0);表示将3维向量修改为4维向量，1.0是缩放因子
    gl_Position = u_mvpMatrix * vec4(a_position, 1.0);
    
}
