

Shader "Unity MyShader/TypicalOfMarket"
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
        _SmoothRange("Smooth Range",Range(0,1)) = 0
        _Smooth("Smooth",Range(0,1)) = 1
        [Space(5)]
        _RampTex ("Ramp Tex",2D) = "white"{}
        [Toggle(ISNIGHT)] _IsNight ("IsNight",int) = 0
        _RampYRange("Rame Y Axis",Range(0,0.5)) = 1
        _RampIntensity ("Ramp Intensity",Range(0,1)) = 0.3
        _RampOffset ("Ramp Offset",Range(0,10)) = 0.2
        _TornLineIntensity ("Torn Line Intensity",Range(0,10)) = 0.3
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
        _StepSpecularWidth ("Step Specular Width",Range(0,1)) = 1
        _StepViewIntensity ("Step View Intensity",Range(0,1)) = 1
        _StepViewWidth ("Step View Width",Range(0,1)) = 1
        
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
        
        [Space(5)]
        [Header(ShadowAO)]
        _ShadowAOMap ("Shadow AO Map",2D) = "white"{}
        


        [Header(RimLight)]
        [Space(5)]
        _RimLightWidth ("Rim Light Width",Range(0,1)) = 1
        _RimIntensity ("Rim Light Intensity",Range(0,10)) = 8
        _RimRadius ("Rim Light Radius",Range(0,20)) = 0
        _RimLightColor ("Rim Color",Color) = (1,1,1,1)
        _RimLightBias ("Rim Light Bias",range(0,20)) = 0
        _RimLightAlbedoMix ("Albedo Mix (Multiply)", Range(0, 1)) = 0.5
        _RimLightSmoothstep ("Smoothstep", Range(0, 1)) = 0
        [Space(30)]

        [Header(Emission)]
        [Space(5)]
        [ToggleOff] _HasEmission ("Has Emission",Float) = 0.0
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
        uniform float _RimLightWidth;
        uniform float _RimRadius;
        uniform float4 _RimLightColor;
        uniform float _RimLightBias;
        uniform float _RimLightAlbedoMix;
        uniform float _RimLightSmoothstep;

        //diffuse
        uniform float _FaceDiffuseIntensity;
        uniform float _SmoothRange;
        uniform float _Smooth;

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
        uniform float _StepViewIntensity;
        uniform float _StepViewWidth;
        uniform float _HairLineIntensity;

        uniform float _KajiyaP;

        //decide which ramp
        uniform float _RampYRange;
        uniform float _RimPower;
        uniform int _isCloth;
        uniform float _RampIntensity;
        uniform float _RampOffset;
        uniform float _TornLineIntensity;

        //Emission
        uniform float _EmissionIntensity;
        uniform float4 _EmissionColor;
        uniform float _HasEmission;

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
        TEXTURE2D(_ShadowAOMap);     
        SAMPLER(sampler_ShadowAOMap);
        

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
            float3 worldNormal : NORMAL;
            float3 worldTangent : TANGENT;
        };


         float3 NPR_Emission(float4 baseColor)
        {
            return baseColor.a * baseColor * _EmissionIntensity * abs((frac(_Time.y * 0.5) - 0.5) * 2) * _EmissionColor.rgb;
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
             /*
                float4 pos = mul(UNITY_MATRIX_MV,v.vertex);
                
                float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV,v.normal);
                normal.x *= aspect;  //adapt for screen
                normal.z = -0.4;
                pos = pos + float4(normalize(normal),0) * _OutlineWidth;*/

                //罪恶装备strive 平滑后的法线存储在tangent中
                v.vertex.xyz += v.tangent.xyz * _OutlineWidth * 0.01 * v.vertexColor.a;
                o.pos = TransformObjectToHClip(v.vertex);
                //o.pos = mul(UNITY_MATRIX_P,pos);
                
                
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
                //o.worldNormal = v.normal;
                return o;
            }
            float4 frag (VertexOutput i) : SV_Target
            {
                //片元性能比较重要 需要省的话就用half3
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
                float4 shadowAOMap = SAMPLE_TEXTURE2D(_ShadowAOMap,sampler_ShadowAOMap,i.uv);

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
                // no ramp
                rampColor = float4(0,0,0,0);

                 //-----------albedo-------------------------------
                float3 albedo = baseColor.rgb * _MainLightColor.rgb;
                //-------------------------------------------------
                //-------------------------------------------------smoothstep(0,0.5,halfLambert)
                //------------diffuse------------------------------
                //漫反射 裁剪
                //============Base Diffuse=====================
                //将NL从(-1,1)映射到(0,1) ⽅便对贴图进⾏操作
                //float Threshold = step(_LightThreshold,halfLambert);
                //也可以对明暗交界先进⾏光滑过渡处理:
                halfLambert = smoothstep(0,_Smooth,halfLambert-_SmoothRange);
                float3 diffuse = albedo * halfLambert / 3.14159;
                //============Base Diffuse=====================

                //==================================Shadow AO + TornLine + Ramp=============================================
                float SpecularLayerMask = lightMap.r;//⾼光类型
                float RampOffsetMask = lightMap.g;//Ramp偏移值
                float SpecularIntensityMask = lightMap.b;//⾼光强度mask
                float InnerLineMask = lightMap.a;//内勾线Mask
                float ShadowAOMask =  shadowAOMap.r;//AO 常暗部分
                // VertexColor.g;//⽤来区分⾝体的部位, ⽐如 脸部=88
                // VertexColor.b;//渲染⽆⽤
                float OutlineIntensity = shadowAOMap.a;//描边粗细
                //裁边漫反射
                //float NL01 = 0.5 * ndotL + 0.5;
                float Threshold = step(_LightThreshold,(halfLambert + /*_RampOffset +*/RampOffsetMask) * ShadowAOMask);
                baseColor *= InnerLineMask;//磨损线条 乘以上一个颜色通道 获得暗部的颜色
                //baseColor = lerp(baseColor * BaseMapLineMap,_TornLineIntensity); //控制磨损线条强度
                diffuse = lerp(lerp(shadowAOMap * baseColor,baseColor,_RampIntensity),baseColor,Threshold);
                //------------diffuse------------------------------

                float3 emission = float3(0,0,0);

                //--------------rimLight---------------------------
                float3 rimLight = step(1-_RimLightWidth,1-ndotV)*_RimIntensity;

                //暗部为0,亮部为1
                float3 threshold = step(_LightThreshold,ndotL);
                float value1 = .3,value2 = .3;
                float3 Rim = step(1 - value1,1 - ndotV)*value2;
                float3 RimDarkSide = lerp(Rim,0,threshold);
                float3 RimBrightSide = lerp(0,Rim,Threshold);
                float3 FinalColor = RimDarkSide;

                //========================Base Specular====================================
                float3 stepSpecular = float3(0,0,0);
                float specularLayer = lightMap.r * 255;
                float3 finalRim = float3(0,0,0);
                if (specularLayer > 0 && specularLayer < 50)
                {
                    //无高光 暗部有边缘光 区别与亮部边缘光 这里直接用同一套
                    // stepSpecular *= baseColor;
                    finalRim = FinalColor;
                }
                if (specularLayer > 50 && specularLayer < 150)
                {
                    //皮革材质 需要视角裁边高光 暗部边缘光 这里直接用blinnPhong的参数了 区别[视角高光 blinnPhong]  
                    float3 stepViewLight = step(1 - _StepViewWidth,ndotH) * _StepViewIntensity;
                    stepSpecular = stepViewLight;
                    // stepSpecular *= baseColor  * _MainLightColor.rgb;
                }
                if (specularLayer > 190 && specularLayer < 260)                 //布料填充高光
                {
                    //金属材质 blinnPhong 光源裁剪高光
                    stepSpecular = step(1-_StepSpecularWidth * 0.01,ndotH) * _StepSpecularIntensity;
                    // stepSpecular = step(_StepSpecularWidth,ndotV * _StepSpecularIntensity);
                    // stepSpecular *= baseColor ;
                }
                /*
                specular = stepSpecular;
                float3 final = float3(0,0,0);
                float3 faceColor = float3(0,0,0);
                float4 FaceMap = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, float2(1 - i.uv.x, i.uv.y));*/
/*
                #if  _SHADERENUM_HAIR
                   

                   // specular += pow(sqrt(saturate(1-pow(hdotT,2))),_HairSpecularGloss) * 0.2 * _HairSpecularColor;//Kajiya模型实现头发高光            

                    // //line specular
                    // float3  Specular = lerp(stepSpecular, specular, LinearMask);     // //⾼光类型Layer 截断分布
                    // float LinearMask = pow(lightMap.r, 1 / 2.2);            //图⽚格式全部去掉勾选SRGB ⾼光类型Layer
                    // specular = lerp(0, Specular, LinearMask);
                    //float3 lineSpecular = lerp(specular,var_ParamTex.r * _HairSpecularColor * step(1-_HairLineIntensity,lightMap.g),var_ParamTex.a);
                    final =  diffuse + rimLight + specular;

                #elif _SHADERENUM_FACE
                //=====================face ================================

                  
                #elif _SHADERENUM_BASE
                    //final = diffuse + ambient;
                  
                #else
                    
                    final = diffuse;
                #endif

                //return float4(diffuse,0);
                // baseSpecular + baseDiffuse + face + hair + others
               */
         
                emission = float3(0,0,0);
                if (_HasEmission != 0.0)
                    emission = NPR_Emission(baseColor);
                return float4(diffuse + stepSpecular * baseColor + finalRim + emission,1.0);
               

            }
            ENDHLSL
        }

        
        UsePass "Universal Render Pipeline/Lit/DepthOnly"
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }

}
