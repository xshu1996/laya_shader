export class CustomTextureSV extends Laya.Value2D
{
	// 声明并给 uniform 变量赋默认值 类似于 effect 文件 property
	u_colorMatrix: any[];
	strength: number = 0;
	blurInfo: any[] = null;
	colorMat: Float32Array = null;
	colorAlpha: Float32Array = null;
	u_alpha: number = 1;
	// u_offsetX: number = 0;
	u_time: number = 0;
	u_speed: number = 0;
	u_uvOffset: number[] = [0, 0, 1, 1];
	// 通过图片大小和 bitmap 大小，获取 uv 在图集中真实的位置
	u_size: number[] = [1, 1, 1, 1]; // width,height, bitmapW, bitmapH
	u_rotated: number = 0; // 图片在图集中是否旋转
	u_gray: number = 0;

	constructor(subID: number = 0)
	{
		super(Laya.ShaderDefines2D["CustomRender"], subID);
		this._attribLocation = ['posuv', 0, 'attribColor', 1, 'attribFlags', 2];// , 'clipDir', 3, 'clipRect', 4];
	}
	/**
	 * @override
	 */
	clear(): void
	{
		this.texture = null;
		this.shader = null;
		this.defines["_value"] = this.subID;
		//defines.setValue(0);
	}
}