﻿/*
Unity Standard Vertex Color Shader v0.92 (for Unity 5.4.0)
by defaxer
*/

Shader "Standard (Vertex Color)" {

	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo", 2D) = "white" {}

		_Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

    	_NoiseTex ("NoiseTex (R)",2D) = "white"{}
	    _EdgeWidth("EdgeWidth",Range(0,0.5)) = 0.1
	    _EdgeColor("EdgeColor",Color) =  (1,1,1,1)
	    _DissolveSpeed ("DissolveSpeed (Second)",Float) = 10.0
	    _StartTime("StartTime (Second)", Float) = 0.0
	    _Duration("Duration (Second)", Float) = 10.0
    

		_Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
		_GlossMapScale("Smoothness Scale", Range(0.0, 1.0)) = 1.0
		[Enum(Metallic Alpha,0,Albedo Alpha,1)] _SmoothnessTextureChannel("Smoothness texture channel", Float) = 0

		[Gamma] _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
		_MetallicGlossMap("Metallic", 2D) = "white" {}

		[ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
		[ToggleOff] _GlossyReflections("Glossy Reflections", Float) = 1.0

		_BumpScale("Scale", Float) = 1.0
		_BumpMap("Normal Map", 2D) = "bump" {}

		_Parallax("Height Scale", Range(0.005, 0.08)) = 0.02
		_ParallaxMap("Height Map", 2D) = "black" {}

		_OcclusionStrength("Strength", Range(0.0, 1.0)) = 1.0
		_OcclusionMap("Occlusion", 2D) = "white" {}

		_EmissionColor("Color", Color) = (0,0,0)
		_EmissionMap("Emission", 2D) = "white" {}

		_DetailMask("Detail Mask", 2D) = "white" {}

		_DetailAlbedoMap("Detail Albedo x2", 2D) = "grey" {}
		_DetailNormalMapScale("Scale", Float) = 1.0
		_DetailNormalMap("Normal Map", 2D) = "bump" {}

		[Enum(UV0,0,UV1,1)] _UVSec("UV Set for secondary textures", Float) = 0


		// Blending state
		[HideInInspector] _Mode("__mode", Float) = 0.0
		[HideInInspector] _SrcBlend("__src", Float) = 1.0
		[HideInInspector] _DstBlend("__dst", Float) = 0.0
		[HideInInspector] _ZWrite("__zw", Float) = 1.0

		_IntensityVC("Vertex Color Intencity", Float) = 1.0
	}

	CGINCLUDE
		#define UNITY_SETUP_BRDF_INPUT MetallicSetup
	ENDCG

	SubShader
	{
		Tags{ "RenderType" = "Opaque" "PerformanceChecks" = "False" }
		LOD 300

		// Pass
  //       {
  //           CGPROGRAM
  //           #pragma vertex vert_img
  //           #pragma fragment frag
  //           #include "UnityCG.cginc"
             
  //           uniform sampler2D _MainTex;
  //           uniform sampler2D _NoiseTex;
  //           uniform float _DissolveSpeed;
  //           uniform float _EdgeWidth;
  //           uniform float4 _EdgeColor;
            
  //           float4 frag(v2f_img i):COLOR
  //           {
  //               float DissolveFactor = saturate(_Time.y / _DissolveSpeed);
  //               float noiseValue = tex2D(_NoiseTex,i.uv).r;            
  //               if(noiseValue <= DissolveFactor)
  //               {
  //                   discard;
  //               }
                
  //               float4 texColor = tex2D(_MainTex,i.uv);
  //               float EdgeFactor = saturate((noiseValue - DissolveFactor)/(_EdgeWidth*DissolveFactor));
  //               float4 BlendColor = texColor * _EdgeColor;
                                
  //               return lerp(texColor,BlendColor,1 - EdgeFactor);
  //           }
            
  //           ENDCG
  //       }

		// ------------------------------------------------------------------
		//  Base forward pass (directional light, emission, lightmaps, ...)
		Pass
		{
			Name "FORWARD"
			Tags{ "LightMode" = "ForwardBase" }

			Blend[_SrcBlend][_DstBlend]
			ZWrite[_ZWrite]

			CGPROGRAM
			#pragma target 3.0

			// -------------------------------------

			#pragma shader_feature _NORMALMAP
			#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			#pragma shader_feature _EMISSION
			#pragma shader_feature _METALLICGLOSSMAP 
			#pragma shader_feature ___ _DETAIL_MULX2
			#pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			#pragma shader_feature _ _SPECULARHIGHLIGHTS_OFF
			#pragma shader_feature _ _GLOSSYREFLECTIONS_OFF
			#pragma shader_feature _PARALLAXMAP
			#pragma shader_feature _VERTEXCOLOR_OFF _VERTEXCOLOR _VERTEXCOLOR_LERP

			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog

			#pragma vertex vertForwardBase_VC
			#pragma fragment fragForwardBase_VC
			#include "UnityStandardCore.cginc"
			#include "UnityVC.cginc"


			ENDCG
		}
		// ------------------------------------------------------------------
		//  Additive forward pass (one light per pass)
		Pass
		{
			Name "FORWARD_DELTA"
			Tags{ "LightMode" = "ForwardAdd" }
			Blend[_SrcBlend] One
			Fog{ Color(0,0,0,0) } // in additive pass fog should be black
			ZWrite Off
			ZTest LEqual

			CGPROGRAM
			#pragma target 3.0

			// -------------------------------------

			#pragma shader_feature _NORMALMAP
			#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			#pragma shader_feature _METALLICGLOSSMAP
			#pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			#pragma shader_feature _ _SPECULARHIGHLIGHTS_OFF
			#pragma shader_feature ___ _DETAIL_MULX2
			#pragma shader_feature _PARALLAXMAP
			#pragma shader_feature _VERTEXCOLOR

			#pragma multi_compile_fwdadd_fullshadows
			#pragma multi_compile_fog

			#pragma vertex vertForwardAdd_VC
			#pragma fragment fragForwardAdd_VC

			#include "UnityStandardCore.cginc"
			#include "UnityVC.cginc"
			ENDCG
		}
		// ------------------------------------------------------------------
		//  Shadow rendering pass
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }

			ZWrite On ZTest LEqual

			CGPROGRAM
			#pragma target 3.0
			
			// -------------------------------------

			#pragma shader_feature _VERTEXCOLOR
			#pragma shader_feature _VERTEXCOLOR_LERP
			#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			#pragma multi_compile_shadowcaster

			#pragma vertex vertShadowCaster_VC
			#pragma fragment fragShadowCaster_VC

			#include "UnityStandardShadow.cginc"
			#include "UnityVCShadow.cginc"

			ENDCG
		}
		// ------------------------------------------------------------------
		//  Deferred pass
		Pass
		{
			Name "DEFERRED"
			Tags{ "LightMode" = "Deferred" }

			CGPROGRAM
			#pragma target 3.0
			#pragma exclude_renderers nomrt

			// -------------------------------------

			#pragma shader_feature _NORMALMAP
			#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			#pragma shader_feature _EMISSION
			#pragma shader_feature _METALLICGLOSSMAP
			#pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			#pragma shader_feature _ _SPECULARHIGHLIGHTS_OFF
			#pragma shader_feature ___ _DETAIL_MULX2
			#pragma shader_feature _PARALLAXMAP
			#pragma shader_feature _VERTEXCOLOR_OFF _VERTEXCOLOR _VERTEXCOLOR_LERP

			#pragma multi_compile ___ UNITY_HDR_ON
			#pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON
			#pragma multi_compile ___ DIRLIGHTMAP_COMBINED DIRLIGHTMAP_SEPARATE
			#pragma multi_compile DYNAMICLIGHTMAP_OFF DYNAMICLIGHTMAP_ON

			#pragma vertex vertDeferred_VC
			#pragma fragment fragDeferred_VC

			#include "UnityStandardCore.cginc"
			#include "UnityVC.cginc"

			ENDCG
		}

		// ------------------------------------------------------------------
		// Extracts information for lightmapping, GI (emission, albedo, ...)
		// This pass it not used during regular rendering.
		Pass
		{
			Name "META"
			Tags{ "LightMode" = "Meta" }

			Cull Off

			CGPROGRAM
			#pragma vertex vert_meta
			#pragma fragment frag_meta

			#pragma shader_feature _EMISSION
			#pragma shader_feature _METALLICGLOSSMAP
			#pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			#pragma shader_feature ___ _DETAIL_MULX2

			#include "UnityStandardMeta.cginc"
			ENDCG
		}
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque" "PerformanceChecks" = "False" }
		LOD 150

		// ------------------------------------------------------------------
		//  Base forward pass (directional light, emission, lightmaps, ...)
		Pass
		{
			Name "FORWARD"
			Tags{ "LightMode" = "ForwardBase" }

			Blend[_SrcBlend][_DstBlend]
			ZWrite[_ZWrite]

			CGPROGRAM
			#pragma target 2.0

			#pragma shader_feature _NORMALMAP
			#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			#pragma shader_feature _EMISSION 
			#pragma shader_feature _METALLICGLOSSMAP 
			#pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			#pragma shader_feature _ _SPECULARHIGHLIGHTS_OFF
			#pragma shader_feature _ _GLOSSYREFLECTIONS_OFF
			#pragma shader_feature _VERTEXCOLOR_OFF _VERTEXCOLOR _VERTEXCOLOR_LERP

			// SM2.0: NOT SUPPORTED shader_feature ___ _DETAIL_MULX2
			// SM2.0: NOT SUPPORTED shader_feature _PARALLAXMAP

			#pragma skip_variants SHADOWS_SOFT DIRLIGHTMAP_COMBINED DIRLIGHTMAP_SEPARATE

			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog

			#pragma vertex vertForwardBase_VC
			#pragma fragment fragForwardBase_VC

			#include "UnityStandardCore.cginc"
			#include "UnityVC.cginc"

			ENDCG
		}
		// ------------------------------------------------------------------
		//  Additive forward pass (one light per pass)
		Pass
		{
			Name "FORWARD_DELTA"
			Tags{ "LightMode" = "ForwardAdd" }
			Blend[_SrcBlend] One
			Fog{ Color(0,0,0,0) } // in additive pass fog should be black
			ZWrite Off
			ZTest LEqual

			CGPROGRAM
			#pragma target 2.0

			#pragma shader_feature _NORMALMAP
			#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			#pragma shader_feature _METALLICGLOSSMAP
			#pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			#pragma shader_feature _ _SPECULARHIGHLIGHTS_OFF
			#pragma shader_feature ___ _DETAIL_MULX2
			// SM2.0: NOT SUPPORTED shader_feature _PARALLAXMAP
			#pragma skip_variants SHADOWS_SOFT
			#pragma shader_feature _VERTEXCOLOR

			#pragma multi_compile_fwdadd_fullshadows
			#pragma multi_compile_fog

			#pragma vertex vertForwardAdd_VC
			#pragma fragment fragForwardAdd_VC

			#include "UnityStandardCore.cginc"
			#include "UnityVC.cginc"
			ENDCG
		}
		// ------------------------------------------------------------------
		//  Shadow rendering pass
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }

			ZWrite On ZTest LEqual

			CGPROGRAM
			#pragma target 2.0

			#pragma shader_feature _VERTEXCOLOR
			#pragma shader_feature _VERTEXCOLOR_LERP
			#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			#pragma skip_variants SHADOWS_SOFT
			#pragma multi_compile_shadowcaster

			#pragma vertex vertShadowCaster_VC
			#pragma fragment fragShadowCaster_VC

			#include "UnityStandardShadow.cginc"
			#include "UnityVCShadow.cginc"

			ENDCG
		}

		// ------------------------------------------------------------------
		// Extracts information for lightmapping, GI (emission, albedo, ...)
		// This pass it not used during regular rendering.
		Pass
		{
			Name "META"
			Tags{ "LightMode" = "Meta" }

			Cull Off

			CGPROGRAM
			#pragma vertex vert_meta
			#pragma fragment frag_meta

			#pragma shader_feature _EMISSION
			#pragma shader_feature _METALLICGLOSSMAP
			#pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			#pragma shader_feature ___ _DETAIL_MULX2

			#include "UnityStandardMeta.cginc"
			ENDCG
		}
	}


	FallBack "VertexLit"
	CustomEditor "StandardShaderVCGUI"
}
