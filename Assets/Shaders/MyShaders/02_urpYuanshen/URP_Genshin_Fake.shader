Shader "Unity MyShader/FAKE_yuanshen0.1"
{
    Properties
    {
        [Header(ShaderEnum)]
        [Space(5)]
        [KeywordEnum(Base,Face,Hair)] _ShaderEnum ("Shader Enum",int) = 1
        [Enum(OFF,0,FRONT,1,BACK,2)] _Cull ("Cull Mode",int) = 1

        [Header(BaseMap)]
        [Space(5)]
        _MainTex ("Main Tex",2D) = "white"{}
        [HDR]_MainColor ("Main Color",Color) = (1,1,1,1)

        [Header(Diffuse)]
        [Space(5)]
        _RampTex ("Ramp Tex",2D) = "white"{}
        [Toggle(ISNIGHT)] _IsNight ("IsNight",int) = 0
        _RampYRange("Rame Y Axis",Range(0,0.5)) = 1
        _RampIntensity ("Ramp Intensity",Range(0,1)) = 0.3
        _FaceDiffuseIntensity ("Face Diffuse Intensity",Range(0,1)) = 0.4
        [ToggleOff]_isCloth ("isCloth",int) = 0
        
         //face, the same with paramTex
        [Space(5)]
        _LightMap ("Light Map(for specular :gloss or metal)",2D) = "grey"{}
        _FaceShadowOffset ("Face Shadow Offset", range(0.0, 1.0)) = 0.1
        _FaceShadowPow ("Face Shadow Pow", range(0.001, 1)) = 0.1

        [Header(ParamTex)]
        [Space(5)]
        _ParamTex ("param Tex(_HairLightMap or Face_LightMap)", 2D) = "white" { }
        [Space(30)]
        //now we have hair and cloth light map

        [Header(Specular)]
        [Space(5)]
        [Header(BasicSpecular)]
        _SpecularGloss ("Specular Gloss",Range(8.0,256)) = 20
        _SpecularIntensity ("Specular Intensity",Range(0,255)) = 20
        [Header(MetalSpecular)]
        _MetalMap ("Metal Map",2D) = "white" {}
        [HDR]_MetalColor ("Metal Color",Color) = (1,1,1,1)//metal color
        _MetalIntensity ("Metal Intensity",Range(0,10)) = 0
        _MetalMapV ("Metal Map V",Range(0,1)) = 0.2

        [Header(StepSpecular)]
        _SpecularStepGloss ("Specular Step Gloss",Range(0,1)) = 1
        _StepSpecularIntensity ("_Step Specular Intensity",Range(-1,2)) = 1
        
        [Space(5)]
        [Header(HairSpecular)]
        _HairSpecularIntensity ("Hair Specular Intensity",Range(0,10)) = 0.5
        _HairSpecularGloss ("Hair Specular Gloss",Range(0,3)) = 1
        _HairSpecularRange ("Hair Specular Range",Range(0,1)) = 0.5
        _HairSpecularVRange ("Hair Specular view Range",Range(0,1)) = 0.5
        _HairSpecularColor ("Hair Specular Color",Color) = (1,1,1,1)
        _KajiyaP ("Hair Kajiya",Range(0,1)) = 0.1
        [Header(LineSpecular)]
        _HairLineIntensity ("Hair Line Intensity",Range(0,1)) = 0.2 
        [Space(30)]


        [Header(RimLight)]
        [Space(5)]
        _RimIntensity ("Rim Light Intensity",Range(0,10)) = 8
        _RimRadius ("Rim Light Radius",Range(0,20)) = 0
        _RimLightColor ("Rim Color",Color) = (1,1,1,1)
        _RimLightBias ("Rim Light Bias",range(0,20)) = 0
        _RimLightAlbedoMix ("Albedo Mix (Multiply)", Range(0, 1)) = 0.5
        _RimLightSmoothstep ("Smoothstep", Range(0, 1)) = 0
        [Space(30)]

        [Header(Emission)]
        [Space(5)]
        _EmissionIntensity("Emission Intensity",Range(0,255)) = 1
        [HDR]_EmissionColor("Emission Color",Color) = (1,1,1,1)



        [Header(Sihouetting)]
        [Space(5)]
        _OutlineColor ("OutLine Color",Color) = (0,0,0,1)
        _OutlineWidth ("Outline Width",Range(-1,1)) = 0.1
        [Space(30)]
        [Header(ShadowCast)]
        [Space(5)]
        _ShadowArea("Shadow Area",RANGE(0,10)) = 0 
        _DarkShadowArea ("Dark Shadow Area",RANGE(0,10)) = 0
        _FixDarkShadow ("Fix Dark Shadow",RANGE(0,10)) = 0
        _ShadowColor ("Shadow Color",Color) = (1,1,1,1)

        _LightThreshold ("Light Threshold",Range(0,10)) = 0.5

       

    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalRenderPipeline"
            "RenderType"="Opaque"
        }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        //#include "mylib.hlsl"

        #pragma vertex vert
        #pragma fragment frag

        #pragma shader_feature _SHADERENUM_BASE _SHADERENUM_FACE _SHADERENUM_HAIR

        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
        #pragma multi_compile_fragment _ _SHADOWS_SOFT


        //声明
        CBUFFER_START(UnityPerMaterial) //缓冲区

        //BaseMap
        float4 _MainTex_ST;  //要注意纹理不能放在缓冲区
        float4 _MainColor;
        float4 _RampTex_ST;
       

        //RimLight
        uniform float _RimIntensity;
        uniform float _RimRadius;
        uniform float4 _RimLightColor;
        uniform float _RimLightBias;
        uniform float _RimLightAlbedoMix;
        uniform float _RimLightSmoothstep;

        //diffuse
        uniform float _FaceDiffuseIntensity;

        //Specualr
        uniform float _SpecularGloss;
        uniform float _SpecularIntensity;
        uniform float4 _MetalColor;
        uniform float _MetalIntensity;
        uniform float _MetalMapV;
        uniform float _HairSpecularIntensity;
        uniform float _HairSpecularRange;
        uniform float _HairSpecularVRange;
        uniform float _HairSpecularColor;
        uniform float _HairSpecularGloss;
        uniform float _SpecularStepGloss;
        uniform float _StepSpecularIntensity;
        uniform float _StepSpecularWidth;
        uniform float _HairLineIntensity;

        uniform float _KajiyaP;

        //decide which ramp
        uniform float _RampYRange;
        uniform float _RimPower;
        uniform int _isCloth;
        uniform float _RampIntensity;

        //Emission
        uniform float _EmissionIntensity;
        uniform float4 _EmissionColor;

        //Sihouetting
        uniform float4 _OutlineColor;
        uniform float _OutlineWidth;
        //face
        uniform float _FaceShadowPow;
        uniform float _FaceShadowOffset;

        uniform float _IsNight;

        //SHADOW 
        uniform float _ShadowArea;
        uniform float _DarkShadowArea;
        uniform float _FixDarkShadow;
        uniform float _ShadowColor;

        float _LightThreshold;

        CBUFFER_END

        //Texture
        TEXTURE2D(_MainTex);        //要注意在CG中只声明了采样器 sampler2D _MainTex,
        SAMPLER(sampler_MainTex); //而在HLSL中除了采样器还有纹理对象，分成了两部分
        TEXTURE2D(_RampTex);     
        SAMPLER(sampler_RampTex);//
        TEXTURE2D(_ParamTex);     
        SAMPLER(sampler_ParamTex);
        TEXTURE2D(_LightMap);     
        SAMPLER(sampler_LightMap);
        TEXTURE2D(_MetalMap);     
        SAMPLER(sampler_MetalMap);
        

        //depth
        TEXTURE2D_X_FLOAT(_CameraDepthTexture);
        SAMPLER(sampler_CameraDepthTexture);
            
        struct VertexInput //输入结构
        {
            float4 vertex : POSITION;
            float3 normal : NORMAL;
            float2 uv : TEXCOORD0;
            float4 tangent : TANGENT;
            float4 vertexColor: COLOR;
        };
        struct VertexOutput //输出结构
        {
            float4 pos : POSITION;
            float2 uv : TEXCOORD0;
            float4 vertexColor: COLOR;
            float3 nDirWS : TEXCOORD1;
            float3 nDirVS : TEXCOORD2;
            float3 vDirWS : TEXCOORD3;
            float3 worldPos : TEXCOORD4;
            float3 lightDirWS : TEXCOORD5;
            float3 worldTangent : TANGENT;
        };

        float3 NPR_Emission(float4 baseColor)
        {
            return baseColor.a * baseColor * _EmissionIntensity * abs((frac(_Time.y * 0.5) - 0.5) * 2) * _EmissionColor.rgb;
        }

        float3 NPR_Base_RimLight(float NdotV,float ndotL,float3 baseColor)
        {
            return (1 - smoothstep(_RimRadius,_RimRadius + 0.03,NdotV)) * _RimIntensity * (1 - (ndotL)) * baseColor;
        }

       

            
        ENDHLSL

        Pass
        {
            Name "Outline"
            Cull Front
            Tags
            {
                "LightMode"="SRPDefaultUnlit"
                "RenderType"="Opaque"
            }
   

            HLSLPROGRAM
            VertexOutput vert (VertexInput v)
            {
                VertexOutput o;
                float4 nearUpperRight = mul(unity_CameraInvProjection, float4(1, 1, UNITY_NEAR_CLIP_VALUE, _ProjectionParams.y));//将近裁剪面右上角位置的顶点变换到观察空间
                float aspect = abs(nearUpperRight.y / nearUpperRight.x);//求得屏幕宽高比
                //2.unity shader fenglele
                float4 pos = mul(UNITY_MATRIX_MV,v.vertex);
                
                float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV,v.normal);
                normal.x *= aspect;  //adapt for screen
                normal.z = -0.4;
                pos = pos + float4(normalize(normal),0) * _OutlineWidth;
                o.pos = mul(UNITY_MATRIX_P,pos);
                
                return o;
            }
            float4 frag (VertexOutput i) : SV_Target
            {
                return float4(_OutlineColor.rgb,1);
            }
            ENDHLSL
        }

        Pass
        {
            Name "Main"
            Tags
            {
                "LightMode"="UniversalForward"
                "RenderType"="Opaque"
            }
            Cull [_Cull]
            HLSLPROGRAM

            VertexOutput vert (VertexInput v)
            {
                VertexOutput o;
                o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
                o.uv = TRANSFORM_TEX(v.uv,_MainTex);
                o.nDirWS = TransformObjectToWorldDir(v.normal);
                o.worldPos = TransformObjectToWorld(v.vertex);
                o.worldTangent = TransformObjectToWorldDir(v.tangent);
                return o;
            }
            float4 frag (VertexOutput i) : SV_Target
            {
                //====================================================================
                //==================PREPAREATION FOR COMPUTE==========================
                Light mainLight = GetMainLight();

                float3 nDirWS = normalize(i.nDirWS);
                //float3 lightColor = mainLight.color;
                float3 lightDirWS = normalize(mainLight.direction);
                float3 vDirWS = normalize(GetCameraPositionWS().xyz - i.worldPos);
                float halfDirWS = normalize(lightDirWS + vDirWS);
                float3 tangentDir = normalize(i.worldTangent);

                //prepare dot product
                float ndotL = max(0,dot(nDirWS,lightDirWS)); //if less than 0,then it will be wrong in light dir
                float ndotH = max(0,dot(nDirWS,halfDirWS));
                float ndotV = saturate(dot(nDirWS,vDirWS));
                float hdotT = max(dot(halfDirWS,tangentDir),0); //切线点乘半角
                float halfLambert = dot(nDirWS,lightDirWS) * 0.5 + 0.5;

                //sample
                float4 baseColor = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                float4 lightMap = SAMPLE_TEXTURE2D(_LightMap,sampler_LightMap,i.uv);//ILM TEX
                float4 var_ParamTex = SAMPLE_TEXTURE2D(_ParamTex,sampler_ParamTex,i.uv);

                //==================PREPAREATION FOR COMPUTE==========================
                //====================================================================


                
                //========================Base Ramp====================================
                float4 rampColor = float4(0,0,0,0);
                //halfLambert = smoothstep(0.0, 0.5, ndotL); //只要halfLambert的一半映射Ramp
                //halfLambert = smoothstep(0.0,0.5,ndotL) * var_ParamTex.b; //----背光阴影
                //如果范围太小，会出现平滑不充分，明暗分界线过于明显，主要体现在腿部的前部阴影上
                //只保留0.0 - 0.5之间的，超出0.5的范围就强行改成1，一般ramp的明暗交界线是在贴图中间的，这样被推到贴图最右边的一个像素上

                if (_IsNight > 0.0)
                {
                   // rampColor = SAMPLE_TEXTURE2D(_RampTex,sampler_RampTex,float2(halfLambert,halfLambert));
                   //更改后的ramp贴图,贴图采用世界佬的,
                   rampColor = SAMPLE_TEXTURE2D(_RampTex,sampler_RampTex,float2(halfLambert, lightMap.a * 0.45 + 0.55));
                }
                else
                {
                    //rampColor = SAMPLE_TEXTURE2D(_RampTex,sampler_RampTex,float2(halfLambert,halfLambert + 0.5));
                    rampColor = SAMPLE_TEXTURE2D(_RampTex,sampler_RampTex,float2(halfLambert,lightMap.a * 0.45));
                }
                
                rampColor = lerp(baseColor,rampColor,_RampIntensity);

                 //-----------albedo-------------------------------
                float3 albedo = baseColor.rgb * rampColor * _MainLightColor.rgb;
                //-------------------------------------------------
                //-------------------------------------------------smoothstep(0,0.5,halfLambert)
                //------------diffuse------------------------------
                float3 diffuse = albedo * halfLambert;
                //------------diffuse------------------------------

                float3 emission = float3(0,0,0);
                float3 rimLight = NPR_Base_RimLight(ndotV,ndotL,baseColor);

                //========================Base Specular====================================
                float3 specular = float3(0,0,0);
                float3 stepSpecular = float3(0,0,0);
                float3 stepSpecular2 = float3(0,0,0);
                float specularLayer = lightMap.r * 255;

                if (specularLayer > 0 && specularLayer < 50)
                {
                    // stepSpecular = step(_StepSpecularWidth,ndotV * _StepSpecularIntensity);
                    // stepSpecular *= baseColor;
                }
                if (specularLayer > 50 && specularLayer < 150)
                {
                    // stepSpecular = step(_StepSpecularWidth,ndotV * _StepSpecularIntensity);
                    // stepSpecular *= baseColor  * _MainLightColor.rgb;
                }
                if (specularLayer > 150 && specularLayer < 260)                 //布料填充高光
                {
                    // stepSpecular = step(_StepSpecularWidth,ndotV * _StepSpecularIntensity);
                    // stepSpecular *= baseColor ;
                }

                float4 MetalMap = SAMPLE_TEXTURE2D(_MetalMap,sampler_MetalMap, mul((float3x3)UNITY_MATRIX_V, nDirWS).xz).r;
                MetalMap = saturate(MetalMap);
                MetalMap = step(_MetalMapV, MetalMap) * _MetalIntensity;    

                if (specularLayer >= 150 && specularLayer < 250)     //金属高光
                {
                    stepSpecular = pow(saturate(ndotV), 2 * _SpecularGloss) /** SpecularIntensityMask*/ *_SpecularIntensity;
                    stepSpecular = max(0, stepSpecular);
                    stepSpecular += MetalMap; 
                    stepSpecular *= baseColor;

                    //ornament emission
                    emission = NPR_Emission(baseColor) * 0.6;
                }

                specular = stepSpecular;
                float3 final = float3(0,0,0);
                float3 faceColor = float3(0,0,0);
                float4 FaceMap = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, float2(1 - i.uv.x, i.uv.y));

                #if  _SHADERENUM_HAIR
                    if (specularLayer > 50 && specularLayer < 150)
                    {
                        stepSpecular = step(_StepSpecularWidth,ndotH * _StepSpecularIntensity);
                        stepSpecular *= baseColor  * _MainLightColor.rgb;
                        stepSpecular = float3(1,1,1) - stepSpecular;
                    }
                    float specularRange = step(1 - _HairSpecularRange,pow(saturate(ndotH),_HairSpecularGloss));
                    float viewRange = step(1 - _HairSpecularVRange,saturate(ndotV));
                    float3 HairSpecular = _HairSpecularIntensity * specularRange * viewRange;
                    HairSpecular = max(0, HairSpecular);
                    HairSpecular *= baseColor;
                    specular = HairSpecular;
                    specular += emission;      

                   // specular += pow(sqrt(saturate(1-pow(hdotT,2))),_HairSpecularGloss) * 0.2 * _HairSpecularColor;//Kajiya模型实现头发高光            

                    // //line specular
                    // float3  Specular = lerp(stepSpecular, specular, LinearMask);     // //⾼光类型Layer 截断分布
                    // float LinearMask = pow(lightMap.r, 1 / 2.2);            //图⽚格式全部去掉勾选SRGB ⾼光类型Layer
                    // specular = lerp(0, Specular, LinearMask);
                    //float3 lineSpecular = lerp(specular,var_ParamTex.r * _HairSpecularColor * step(1-_HairLineIntensity,lightMap.g),var_ParamTex.a);
                    final =  diffuse + rimLight + specular;

                #elif _SHADERENUM_FACE
                //=====================face ================================

                    float lightAttenuation = 0;

                    float3 upDir = float3(0,1,0);
                    float3 frontDir = float3(0,0,1);
                    float3 leftDir = -cross(upDir,frontDir);
                    float3 rightDir = - leftDir;

                    float fDotL = dot(normalize(frontDir.xz),normalize(lightDirWS.xz));
                    float lDotL = dot(normalize(leftDir.xz),normalize(lightDirWS.xz));
                    float rDotL = dot(normalize(rightDir.xz),normalize(lightDirWS.xz));

                    //if light in the front,and facemap.r > rdotl && facemap.g>-rdotl,then lightAttenuation has value
                    lightAttenuation = (fDotL > 0) * min((FaceMap.r > rDotL),
                    (FaceMap.g > -rDotL));
                    lightAttenuation = max(0,lightAttenuation);

                    // we should lerp based on facemap(_lightmap) or the value will be overwrite
                    //use facemap to cast shadow,albedo to represent baseColor
                    //multiply .1,because if albedo too much,then the shadow contrast with albedo will be badly large
                    faceColor = lerp(FaceMap.rgb,baseColor,lightAttenuation) * albedo * _FaceDiffuseIntensity;

                    final = faceColor + specular + rimLight + diffuse;
                #elif _SHADERENUM_BASE
                    //final = diffuse + ambient;
                    final = diffuse + emission + specular + rimLight;
                #else
                    final = diffuse + emission + specular + rimLight;
                    //final = emission;
                #endif

                //return float4(diffuse,0);
                // baseSpecular + baseDiffuse + face + hair + others
                float3 ambient = float3(unity_SHAr.w,unity_SHAg.w,unity_SHAb.w) * albedo * 0.2;
                return float4(final + ambient,1.0);
               

            }
            ENDHLSL
        }

        
        UsePass "Universal Render Pipeline/Lit/DepthOnly"
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }

}
