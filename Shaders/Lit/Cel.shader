﻿Shader "VeryRealHelp/Lit/Cel"
{
    Properties
    {
		[NoScaleOffset]
		_MainTex("Texture", 2D) = "white" {}
		[HDR]
		_Color("Color", Color) = (1,1,1,1)
		_FresnelMix("Edge Highlight Brightness", Range(0,1)) = 0.5
		_FresnelPower("Edge Highlight Fresnel Power", Float) = 2
		_PosterizeLevels("Posterize Levels", Float) = 3
		_PosterizeMix("Posterize Intensity", Range(0,1)) = 1
		_PosterizeValuePower("Posterize Brightness", Range(-1,1)) = 0
	}
	SubShader
	{
		Tags {
			"Queue" = "Geometry"
			"LightMode" = "ForwardBase"
		}
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog

			#include "UnityCG.cginc"
			#include "../Lib/HSV.cginc"
			#include "UnityLightingCommon.cginc"

			sampler2D _MainTex;
			half4 _Color;
			fixed _FresnelMix;
			fixed _FresnelPower;
			fixed _PosterizeLevels;
			fixed _PosterizeMix;
			fixed _PosterizeValuePower;
			fixed _PosterizeSaturation = 1;


			fixed4 posterize(fixed4 dry, fixed amount, fixed valuePower, fixed levels, fixed fresnelValue) {
				fixed3 hsv = rgb2hsv(dry.xyz);
				fixed levelCount = levels - 1;
				fixed v = round(levelCount * max(pow(hsv.z, valuePower), fresnelValue)) / levelCount;
				fixed4 wet = fixed4(hsv2rgb(fixed3(hsv.x, hsv.y, v)).xyz, dry.a);
				return lerp(dry, wet, amount);
			}


            struct VertexInput
            {
                float4 position : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
            };

            struct VertexOutput
            {
				float4 position : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 worldPosition : TEXCOORD1;
				half3 worldNormal : TEXCOORD2;
				fixed4 color : COLOR0;
				UNITY_FOG_COORDS(1)
            };


			VertexOutput vert (VertexInput v)
            {
				VertexOutput o;
                o.position = UnityObjectToClipPos(v.position);
				o.uv = v.uv;
				o.worldPosition = mul(unity_ObjectToWorld, v.position).xyz;
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.color = _LightColor0 * max(0, dot(o.worldNormal, _WorldSpaceLightPos0.xyz));
				o.color.xyz += ShadeSH9(half4(o.worldNormal, 1));
				UNITY_TRANSFER_FOG(o, o.position);
				return o;
            }

            fixed4 frag (VertexOutput i) : SV_Target
            {
				half3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPosition));
				fixed dotResult = 1 - abs(dot(worldViewDir, i.worldNormal));
				fixed fresnelValue = _FresnelMix * pow(dotResult, _FresnelPower);
				fixed4 dry = tex2D(_MainTex, i.uv) * _Color * i.color;
				UNITY_APPLY_FOG(i.fogCoord, dry);
				fixed4 color = posterize(dry, _PosterizeMix, 1 - _PosterizeValuePower, _PosterizeLevels, fresnelValue);
				return color;
            }
            ENDCG
        }
    }
}
