import { CustomTextureSV } from "./value/CustomTextureSV";
import texture_vs from './files/texture.vs.glsl';
import texture_ps from './files/texture.ps.glsl';

export default class CustomRender extends Laya.Image 
{

    // 类似于 cocos 自定义的 effect 文件
    public customTexSV: CustomTextureSV = null;
    // 类似于 cocos effect 默认传入的 texture， 类型： Laya.Texture | Laya.RenderTexture
    private _tex: any = null;

    public set texture(v: Laya.Texture) 
    {
        this._tex = v;
        // 传入 uniform 
        this.customTexSV.u_uvOffset = v.uvrect;
        this.customTexSV.u_size = [v.width, v.height, v.bitmap.width, v.bitmap.height];
        console.log(v.uvrect, v.bitmap.width, v.bitmap.height);
        // this.customTexSV.u_rotated
        this.width = v.width || 0;
        this.height = v.height || 0;
    }

    constructor() 
    {
        super();
        this.init();
    }

    public init(): void
    {
        this.initShader();
        // 开启自定义渲染流
        this.customRenderEnable = true;
    }


    /** 是否变灰。*/
    get gray(): boolean
    {
        return this._gray;
    }

    set gray(value: boolean)
    {
        if (value !== this._gray)
        {
            this._gray = value;
            if (this["_renderType"] & Laya.SpriteConst.CUSTOM)
            {
                this.customTexSV.u_gray = value ? 1 : 0;
            }
            else
            {
                Laya.UIUtils.gray(this, value);
            }
        }
    }

    /** 是否禁用页面，设置为true后，会变灰并且禁用鼠标。*/
    get disabled(): boolean
    {
        return this._disabled;
    }

    set disabled(value: boolean)
    {
        if (value !== this._disabled)
        {
            this.gray = this._disabled = value;
            this.mouseEnabled = !value;
        }
    }


    // 初始化 shader 参数
    public initShader(): void 
    {
        console.log("Begin preCompile Custom Shader");
        // 给自定义的 shader 定义的唯一的标志
        Laya.ShaderDefines2D["CustomRender"] = 0x400;
        // 将 shader 名称与 id 映射起来
        Laya.ShaderDefines2D.reg("CustomRender", Laya.ShaderDefines2D["CustomRender"]);
        // 将 id 与 effect 绑定
        Laya.Value2D._initone(Laya.ShaderDefines2D["CustomRender"], CustomTextureSV);
        // 预编译顶点着色器和片元着色器
        Laya.Shader.preCompile2D(0, Laya.ShaderDefines2D["CustomRender"], texture_vs, texture_ps, null);
        // 创建一个effect
        this.customTexSV = new CustomTextureSV();
        console.log(this.customTexSV);
    }

    /**
     * important 自定义渲染必须实现此方法
     * @param context 
     * @param x 
     * @param y 
     */
    public customRender(context: Laya.Context, x: number, y: number): void
    {
        if (this._tex)
        {
            // 更新 uniform 变量的值
            this.customTexSV.u_alpha = Math.sin(Laya.timer.currTimer / 1000) + 0.7;
            // this.customTexSV.u_offsetX = Math.sin(Laya.timer.currTimer / 1000) + 0.5;
            this.customTexSV.u_time = Laya.timer.currFrame / 60;
            this.customTexSV.u_speed = 0.5;
            context.drawTarget(this._tex as any, x, y, this._tex.width, this._tex.height, null, this.customTexSV);
        }
    }
}