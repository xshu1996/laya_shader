/*
	texture和fillrect使用的。
*/
#if defined(GL_FRAGMENT_PRECISION_HIGH)// 原来的写法会被我们自己的解析流程处理，而我们的解析是不认内置宏的，导致被删掉，所以改成 if defined 了
precision highp float;
#else
precision mediump float;
#endif

varying vec4 v_texcoordAlpha;
varying vec4 v_color;
varying float v_useTex;
uniform sampler2D texture;
uniform float u_alpha;
uniform float u_speed;
uniform float u_time;
uniform float u_rotated;
uniform vec4 u_uvOffset;
uniform vec4 u_size;
varying vec2 cliped;

// 把图集内的图片的 uv 坐标换算映射到 0.0 ～ 1.0 或者反之
float linear(float x0, float x1, float y0, float y1, float inputX) 
{
   return (y1 - y0) * (inputX - x0) / (x1 - x0) + y0;
}

// 图片是否旋转
vec2 rotateVec (vec2 uv) 
{
   if (u_rotated > 0.5)
   {
         float tmp = uv.x;
         uv.x = uv.y;
         uv.y = 1.0 - tmp;
   }
   return uv;
}

// 随机数
float randomNoise(vec2 seed)
{
   float speed = 10.0;
   return fract(sin(dot(seed * floor(u_time * speed), vec2(17.13, 3.71))) * 43758.5453123);
}

vec2 clampUV(vec2 uv)
{
   return vec2(clamp(uv.x, u_uvOffset.x, u_uvOffset.z), clamp(uv.y, u_uvOffset.y, u_uvOffset.w));
}
#define TAU 6.12
#define MAX_ITER 5  // 最大迭代次数

#ifdef BLUR_FILTER
uniform vec4 strength_sig2_2sig2_gauss1;//TODO模糊的过程中会导致变暗变亮  
uniform vec2 blurInfo;

#define PI 3.141593

float getGaussian(float x, float y){
    return strength_sig2_2sig2_gauss1.w*exp(-(x*x+y*y)/strength_sig2_2sig2_gauss1.z);
}

vec4 blur(){
    const float blurw = 9.0;
    vec4 vec4Color = vec4(0.0,0.0,0.0,0.0);
    vec2 halfsz=vec2(blurw,blurw)/2.0/blurInfo;    
    vec2 startpos=v_texcoordAlpha.xy-halfsz;
    vec2 ctexcoord = startpos;
    vec2 step = 1.0/blurInfo;  //每个像素      
    
    for(float y = 0.0;y<=blurw; ++y){
        ctexcoord.x=startpos.x;
        for(float x = 0.0;x<=blurw; ++x){
            //TODO 纹理坐标的固定偏移应该在vs中处理
            vec4Color += texture2D(texture, ctexcoord)*getGaussian(x-blurw/2.0,y-blurw/2.0);
            ctexcoord.x+=step.x;
        }
        ctexcoord.y+=step.y;
    }
    //vec4Color.w=1.0;  这个会导致丢失alpha。以后有时间再找模糊会导致透明的问题
    return vec4Color;
}
#endif

#ifdef COLOR_FILTER
uniform vec4 colorAlpha;
uniform mat4 colorMat;
#endif

#ifdef GLOW_FILTER
uniform vec4 u_color;
uniform vec4 u_blurInfo1;
uniform vec4 u_blurInfo2;
#endif

#ifdef COLOR_ADD
uniform vec4 colorAdd;
#endif

#ifdef FILLTEXTURE	
uniform vec4 u_TexRange;//startu,startv,urange, vrange
#endif
void main() {
	if(cliped.x<0.) discard;
	if(cliped.x>1.) discard;
	if(cliped.y<0.) discard;
	if(cliped.y>1.) discard;
	
#ifdef FILLTEXTURE	
   vec4 color= texture2D(texture, fract(v_texcoordAlpha.xy)*u_TexRange.zw + u_TexRange.xy);
#else
   vec2 uv = v_texcoordAlpha.xy;//vec2(fract(v_texcoordAlpha.x - u_speed * u_time), v_texcoordAlpha.y);
   // vec2 r_uv = vec2(linear(u_uvOffset.x, u_uvOffset.z, 0.0, 1.0, uv.x), linear(u_uvOffset.y, u_uvOffset.w, 0.0, 1.0, uv.y));
   // vec2 r_uv = vec2(clamp(uv.x, u_uvOffset.x, u_uvOffset.z), clamp(uv.y, u_uvOffset.y, u_uvOffset.w));
   vec2 r_uv = vec2(uv.x * u_size.x / u_size.z + u_uvOffset.x, uv.y * u_size.y / u_size.w + u_uvOffset.y);
   vec4 color = texture2D(texture, r_uv);
#endif

   if(v_useTex<=0.)color = vec4(1.,1.,1.,1.);
   // color.a*= v_color.w;
   // color.rgb*= v_color.rgb;
   // color.rgb *= color.a;
   // gl_FragColor= color;
   // 呼吸灯效果
   // gl_FragColor.rgb *= u_alpha;

   vec2 v_uv0 = r_uv;
   vec4 o = color;
   // 错位图块故障（Image Block Glitch）
   // float block = randomNoise(floor(v_uv0 * 8.0));
   // float displaceNoise = pow(block, 8.0) * pow(block, 3.0);
   // float splitRGBNoise = pow(randomNoise(vec2(7.2341, 1.0)), 17.0);
   // float offsetX = displaceNoise - splitRGBNoise * 1.0; 
   // float offsetY = displaceNoise - splitRGBNoise * 1.0;

   // float noiseX = 0.05 * randomNoise(vec2(13.0, 1.0));
   // float noiseY = 0.05 * randomNoise(vec2(7.0, 1.0));
   // vec2 offset = vec2(offsetX * noiseX, offsetY * noiseY);

   // vec4 driftColor0 = texture2D(texture, clampUV(v_uv0 + offset));
   // vec4 driftColor1 = texture2D(texture, clampUV(v_uv0 - offset));

   // o = vec4(driftColor0.r, o.g, driftColor1.b, o.a + driftColor0.a + driftColor1.a);
   // gl_FragColor = o;

   vec2 p = mod(v_uv0 * TAU, TAU) - 250.;

   vec2 i = vec2(p);
   float c = 1.;
   float inten = 0.0065;

   for (int n = 0; n < MAX_ITER; ++n)
   {
      float t = u_time * (1.0 - (3.5 / float(n + 1)));
      i = p + vec2(cos(t - i.x) + sin(t + i.y), sin(t - i.y) + cos(1.5 * t + i.x));
      c += 1.0 / length(vec2(p.x / (cos(i.x + t) / inten), p.y / (cos(i.y + t) / inten)));
   }

   c /= float(MAX_ITER);
   c = 1.17 - pow(c, 1.4);
   vec4 tex = texture2D(texture, v_uv0);
   vec3 colour = vec3(pow(abs(c), 20.0));
   colour = clamp(colour + vec3(0.0, 0.0, 0.0), 0.0, tex.a);

   // 混合波光
   float alpha = c * tex.a;
   tex.r = tex.r + colour.x * alpha;
   tex.g = tex.g + colour.y * alpha;
   tex.b = tex.b + colour.z * alpha;

   gl_FragColor = vec4(1.0) * tex;
   
   #ifdef COLOR_ADD
	gl_FragColor = vec4(colorAdd.rgb,colorAdd.a*gl_FragColor.a);
	gl_FragColor.xyz *= colorAdd.a;
   #endif
   
   #ifdef BLUR_FILTER
	gl_FragColor =   blur();
	gl_FragColor.w*=v_color.w;   
   #endif
   
   #ifdef COLOR_FILTER
	mat4 alphaMat =colorMat;

	alphaMat[0][3] *= gl_FragColor.a;
	alphaMat[1][3] *= gl_FragColor.a;
	alphaMat[2][3] *= gl_FragColor.a;

	gl_FragColor = gl_FragColor * alphaMat;
	gl_FragColor += colorAlpha/255.0*gl_FragColor.a;
   #endif
   
   #ifdef GLOW_FILTER
	const float c_IterationTime = 10.0;
	float floatIterationTotalTime = c_IterationTime * c_IterationTime;
	vec4 vec4Color = vec4(0.0,0.0,0.0,0.0);
	vec2 vec2FilterDir = vec2(-(u_blurInfo1.z)/u_blurInfo2.x,-(u_blurInfo1.w)/u_blurInfo2.y);
	vec2 vec2FilterOff = vec2(u_blurInfo1.x/u_blurInfo2.x/c_IterationTime * 2.0,u_blurInfo1.y/u_blurInfo2.y/c_IterationTime * 2.0);
	float maxNum = u_blurInfo1.x * u_blurInfo1.y;
	vec2 vec2Off = vec2(0.0,0.0);
	float floatOff = c_IterationTime/2.0;
	for(float i = 0.0;i<=c_IterationTime; ++i){
		for(float j = 0.0;j<=c_IterationTime; ++j){
			vec2Off = vec2(vec2FilterOff.x * (i - floatOff),vec2FilterOff.y * (j - floatOff));
			vec4Color += texture2D(texture, v_texcoordAlpha.xy + vec2FilterDir + vec2Off)/floatIterationTotalTime;
		}
	}
	gl_FragColor = vec4(u_color.rgb,vec4Color.a * u_blurInfo2.z);
	gl_FragColor.rgb *= gl_FragColor.a;   
   #endif

}