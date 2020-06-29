// vertex shader--顶点着色器

attribute vec4 position;            // 顶点
attribute vec4 positionColor;       // 顶点颜色
uniform   mat4 projectionMatrix;    // 投影矩阵
uniform   mat4 modelViewMatrix;     // 模型视图矩阵

varying lowp vec4 varyColor;        // 将纹理数据传递到片元着色器去（从顶点着色器传一个值到片元着色器，就要用到varying来传），注意：两个着色器的这两个参数名字一样

void main()
{
    varyColor = positionColor;
    
    vec4 vPos;// 顶点
    // 投影矩阵*模型矩阵*顶点
    vPos = projectionMatrix * modelViewMatrix * position;
    
    //vPos = position;
    // 内建变量
    gl_Position = vPos;
}
