Shader "NPR/nprTest"{
    Properties{
        [Header(Settings)]
        [Space(5)]
        [Enum(Off ,0,Front, 1,Back, 2)] _Cull("Cull Set",int) = 0
        [Header(MainTexture)]
        [Space(5)]
        _MainTex ("Main Tex",2D) = "white"{}
        [Header(Ambient)]
        _Color ("Tint Color",Color) = (1,1,1,1)
        [Header(Diffuse)]
        [Space(5)]
        _Diffuse ("Diffuse",Color) = (1,1,1,1)
        _DiffuseIntensity ("Diffuse Intensity",Range(0.0,5)) = 0.01
        [Header(Specular)]
        [Space(5)]
        _Specular ("Specular",Color) = (1,1,1,1)
        _SpecularScale ("Specular Scale",FLOAT) = 1.0
        _Gloss ("高光次幂",Range(8.0,256)) = 20
        [Header(HairSpecular)]
        //optional part-1 hair specular
        [Space(5)]
        _HairSpecularColor ("Hair Specular Color",Color) = (1,1,1,1)
        _HairSpecularGloss ("Hair Specular Gloss",Range(0.0,10)) = 0
        [ToggleOff]_HairSpecularBtn ("是否开启头发高光",INT) = 0
            //_HairSpecularRange....
        [Header(Sihouetting)]
        [Space(5)]
        _OutlineWidth ("描边粗细",Range(0,10)) = 0.1
        _OutlineColor ("描边色",Color) = (0,0,0,1)
        //_ZBias ("z偏移",FLOAT) = 0.01
        _Cutoff ("剔除",Range(0.0,1)) = 0.5
        [Header(RimLight)]
        [Space(5)]
        _RimLightColor ("Rim Light Color",Color) = (1,1,1,1)
        _RimPower ("边缘光次幂",Range(8.0,256)) = 5
        _RimIntensity ("边缘光强度",Range(8.0,500)) = 20
        _RimSmoothStep ("Smooth Step",Range(0,1)) = 0
        [Header(Emission)]
        [Space(5)]
        _EmissionColor ("Emission Color",Color) = (1,1,1,1)
        _EmissionIntensity ("Emission Intensity",Range(8.0,250)) = 20
        //---------optional---------
        [Space(5)]
        [ToggleOff]_CoolWarmMix ("Switch of Cool and Warm",INT) = 0 
        //着色1 冷暖色渐变（处理着色渐变）
        [Header(ToneBasedShading)]
        [Space(5)]
        _CoolColor("Cool Color",Color) = (1,1,1,1)
		_WarmColor("Warm Color",Color) = (1,1,1,1)
        _CoolAlpha ("Cool Color Intensity",Range(0.0,10)) = 1
        _WarmBeta ("Warm Color Intensity",Range(0.0,10)) = 1
        //着色2 Cel Shading 赛璐璐风格
         _RampTex("_RampTex", 2D) = "White" {} //色阶贴图

    }

    SubShader{
            
            Tags{
                "RenderPipeline" = "UniversalPipeline"
                "RenderType" = "Opaque"
                "Queue" = "AlphaTest"       //剔除
                "IgnoreProjector" = "True" //忽略投影类材质对物体或着色器的影响
            }
         

         
        Pass{
            
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Cull [_Cull] 
            ZWrite On

            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #pragma vertex vert
            #pragma fragment frag

            

            //声明变量
            CBUFFER_START(UnityPerMaterial)
            uniform float4 _Color;
            //diffuse
            uniform float4 _Diffuse;
            uniform float _DiffuseIntensity;
            //specular
            uniform float4 _Specular;
            uniform float _SpecularScale;
            uniform float _Gloss;
            //Hair Specular Uniform
            uniform float4 _HairSpecularColor;
            uniform float4 _HairSpecularGloss;
            uniform float _HairSpecularBtn;
            //sihouetting
            uniform float _ZBias;
            //Rim
            uniform float4 _RimLightColor;
            uniform float _RimPower; 
            uniform float _RimIntensity;
            uniform float _RimSmoothStep;

            float _Cutoff;
            //uniform  float4 _MainTex_ST;

            //ToneBasedShading
            float4 _CoolColor;
            float4 _WarmColor;
            float _CoolAlpha;
			float _WarmBeta;
            int _CoolWarmMix;

            //_EmissionColor
            float4 _EmissionColor;
            float4 _EmissionIntensity;

            CBUFFER_END

            float4 _MainTex_ST;
            TEXTURE2D(_MainTex);
            #define textureSampler1 SamplerState_Point_Repeat
            SAMPLER(textureSampler1);
            //RmapTex
            TEXTURE2D(_RampTex);            
            SAMPLER(sampler_RampTex);
/*

            #pragma surface surf CelShading

            half4 LightingCelShading(SurfaceOutput s, half3 lightDir, half atten)
            {
                half NdotL = dot(s.Normal, lightDir);
                if (NdotL > 0.9)
                {
                    NdotL = 1.0;
                }
                else if (NdotL > 0.5)
                {
                    NdotL = 0.6;
                }
                else
                {
                    NdotL = 0;
                }

                half4 c;
                c.rgb = s.Albedo * _LightColor0.rgb * (NdotL * atten);
                c.a = s.Alpha;
                return c;
            }
*/
            struct a2v{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float3 tangent : TANGENT;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f{
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 worldViewDir : TEXCOORD1;
                float3 worldLightDir :TEXCOORD2;
                float3 worldNormal : TEXCOORD3;
                float2 uv : TEXCOORD4;
                float3 worldTangent : TEXCOORD5;
            };
           

            v2f vert(a2v v){
                v2f o;
                o.worldPos = TransformObjectToWorld(v.vertex).xyz;
                // //------------过程式几何描边------------
                // float4 pos = mul(UNITY_MATRIX_MV, v.vertex);
                // pos.z += _ZBias;
                // o.pos = mul(UNITY_MATRIX_P, pos);
                // //-----------------------
                o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
                o.worldNormal = TransformObjectToWorldNormal(v.normal);
                o.worldPos = TransformObjectToWorld(v.vertex).xyz;
                o.worldLightDir = _MainLightPosition.xyz - o.worldPos;
                o.worldTangent = TransformObjectToWorldDir(v.tangent);
                o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
                o.uv = v.texcoord;
                return o;
            }

            float4 frag(v2f i): SV_TARGET{
                //-----------卡渲

                //向量
                float3 worldNormal = normalize(i.worldNormal);
                float3 worldLightDir = normalize(i.worldLightDir);
                float3 worldViewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
                float3 halfDir = normalize(worldViewDir + worldLightDir);
                //float3 tangentDir = normalize(i.worldTangentDir);
                float3 tangentDir = normalize(i.worldTangent);

                //----------------点积---------------
                float ndotI = dot(worldNormal,worldLightDir);
                float ndotMinusI = dot(worldNormal,-worldLightDir); //用于冷暖着色渐变
                float ndotH = dot(worldNormal,halfDir);
                float ndotV = dot(worldNormal, worldViewDir);
                float HdotT = dot(halfDir,tangentDir); //切线点乘半角


                //---------------纹理 + 中间值-------------
                float4 baseMapColor = SAMPLE_TEXTURE2D(_MainTex,textureSampler1,i.uv);
                clip(baseMapColor.a - _Cutoff);
                float3 albedo = baseMapColor * _Color.rgb;
            
                float LN = dot(i.worldNormal ,-i.worldLightDir);//冷暖着色渐变

                float halfLambert = ndotI * 0.5 +0.5;
                
                
                
                


                //--------------光照模型---------------
                float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                //float3 diffuse =  max(0,ndotI) * _DiffuseIntensity; //兰伯特模型
                float3 diffuse = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(halfLambert, halfLambert)) * _MainLightColor *_DiffuseIntensity; // 漫反射
                float3 specular = _MainLightColor.rgb * pow(max(0,ndotH),_Gloss);//BlinnPhong模型

                float3 hairSpecular = pow(sqrt(1-pow(HdotT,2)),_HairSpecularGloss) * _HairSpecularColor.rgb;//Kajiya模型实现头发高光
                hairSpecular = _HairSpecularBtn == 0?0:1 * hairSpecular;

                //着色ToneBasedShading
                float4 tmpColor0 = baseMapColor * (1 - LN) + float4(1,0,0,1) * LN; //黑色到模型本身颜色的渐变，实现模型颜色的渐变
                _CoolColor = _CoolColor + _CoolAlpha * tmpColor0;  //将模型本身颜色进一步通过冷暖色调的叠加和渐变
                _WarmColor = _WarmColor + _WarmBeta * tmpColor0;
                
                float4 I = (0.5 + LN * 0.5) * _CoolColor + (0.5 - LN * 0.5) * _WarmColor;//混合模型
                //if(step(_CoolWarmMix,0)) I = float4(0,0,0,0);


                //Emission自发光  呼吸...
                float4 emission = baseMapColor.a * baseMapColor * _EmissionIntensity * abs((frac(_Time.y * 0.5) - 0.5) * 2);


                //菲涅尔求边缘光
                float NdotL = max(0,ndotI);

                float f = 1.0 - saturate(ndotV);

                float rimBloom = pow(f, _RimPower) * _RimIntensity * NdotL;
                float3 rimLight = f * _RimLightColor.rgb * _RimLightColor.a*_MainLightColor.rgb* rimBloom;
                //-------------返回----------------
                //diffuse + I.rgb + + hairSpecular
                return  float4((diffuse   +specular + ambient + hairSpecular + _EmissionColor.rgb) * albedo + rimLight + emission,1);
            }
            ENDHLSL
        
        }



        Pass
        {
            Name "Outline"
            Tags 
            { 
                
            }
            
            Cull Front
            ZWrite On

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            #pragma multi_compile_instancing
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float _OutlineWidth;
            float4 _OutlineColor;
            float _Cutoff;
            CBUFFER_END

            TEXTURE2D(_MainTex);
            float4 _MainTex_ST;

            #define textureSampler1 SamplerState_Point_Repeat
            SAMPLER(textureSampler1);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv :TEXCOORD0;
            };
            
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD2;

            };
            
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                float4 originalPositionCS = TransformObjectToHClip(v.positionOS.xyz);
                float4 positionCS = mul(UNITY_MATRIX_MV, v.positionOS);
                float3 normalOS = mul((float3x3)UNITY_MATRIX_IT_MV, v.normalOS);
                normalOS.z = -0.5;
                positionCS = positionCS + float4(normalize(normalOS), 0) * _OutlineWidth * 0.002;
                o.positionCS = mul(UNITY_MATRIX_P, positionCS);
                //o.uv = TRANSFORM_TEX(v.uv, _BaseMap);

                return o;
            }

            float4 frag(Varyings i) : SV_TARGET 
            {
                // float4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, textureSampler1, i.uv);
                // clip(baseMap.a - _Cutoff);

                return float4(_OutlineColor.rgb,1.0);
            }
            
            ENDHLSL
        }

       
       

    }
    
   FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"

}