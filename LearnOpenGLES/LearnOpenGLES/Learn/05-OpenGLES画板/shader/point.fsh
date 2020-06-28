// 片元着色器

// 获取纹理
uniform sampler2D texture;
/*
 sampler2D,中的2D,表示这是一个2D纹理。我们也可以使用1D\3D或者其他类型的采样器。我们总是
 把这个值设置为0。来指示纹理单元0.
 */

// 获取从顶点程序传递过来的颜色
// lowp,精度
varying lowp vec4 color;

void main()
{
    // 将颜色和纹理组合 是相乘！！！！
    gl_FragColor = color * texture2D(texture, gl_PointCoord);
}
