/*
light_bmodel_fp.glsl - fragment uber shader for all dlight types for bmodel surfaces
Copyright (C) 2015 Uncle Mike

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
*/

#include "const.h"
#include "mathlib.h"
#include "texfetch.h"
#include "lightmodel.h"
#include "terrain.h"
#include "parallax.h"

// texture units
#if defined( APPLY_TERRAIN )
uniform sampler2DArray	u_ColorMap;
uniform sampler2DArray	u_NormalMap;
uniform sampler2DArray	u_GlossMap;
#else
uniform sampler2D		u_ColorMap;
uniform sampler2D		u_NormalMap;
uniform sampler2D		u_GlossMap;
#endif

uniform sampler2D		u_ProjectMap;
uniform sampler2D		u_DetailMap;

#if defined( APPLY_SHADOW )
#if defined( LIGHT_SPOT )
#include "shadow_spot.h"
#elif defined( LIGHT_OMNI )
#include "shadow_omni.h"
#elif defined( LIGHT_PROJ )
#include "shadow_proj.h"
#endif
#endif

uniform vec4		u_LightDir;
uniform vec3		u_LightDiffuse;
uniform vec4		u_LightOrigin;
uniform vec4		u_ShadowParams;
uniform float		u_RefractScale;
uniform float		u_AmbientFactor;
uniform float		u_SunRefract;

#if defined( APPLY_TERRAIN )
uniform float		u_Smoothness[TERRAIN_NUM_LAYERS];
#else
uniform float		u_Smoothness;
#endif

varying vec2		var_TexDiffuse;
varying vec3		var_LightVec;
varying vec3		var_ViewVec;

#if defined( HAS_DETAIL )
varying vec2		var_TexDetail;
#endif

#if defined( APPLY_TERRAIN )
varying vec2		var_TexGlobal;
#endif

#if defined( HAS_NORMALMAP )
varying mat3		var_WorldMat;
#else
varying vec3		var_Normal;
#endif

#if defined( PLANAR_REFLECTION )
varying vec4		var_TexMirror;	// mirror coords
#endif

#if defined( LIGHT_SPOT )
varying vec4		var_ProjCoord;
#endif

#if defined( LIGHT_SPOT ) || defined( LIGHT_PROJ )
varying vec4		var_ShadowCoord;
#endif

#if defined( PARALLAX_SIMPLE ) || defined( PARALLAX_OCCLUSION )
varying vec3		var_ViewDir;
#endif

void main( void )
{
#if !defined( LIGHT_PROJ )
	float dist = length( var_LightVec );
	float atten = 1.0 - saturate( pow( dist * u_LightOrigin.w, LIGHT_FALLOFF ));
	if( atten <= 0.0 ) discard; // fast reject
#else
	// directional light has no attenuation
	float atten = 1.0;
#endif
	vec3 V = normalize( var_ViewVec );
	vec3 L = vec3( 0.0 );
	vec2 vec_TexDiffuse = var_TexDiffuse.xy;  

#if defined( LIGHT_SPOT )
	L = normalize( var_LightVec );
	
	// spot attenuation
	float spotDot = dot( normalize( u_LightDir.xyz ), L );
	float fov = ( u_LightDir.w * FOV_MULT * ( M_PI / 180.0 ));
	float spotCos = cos( fov + fov );
	if( spotDot < spotCos ) discard;
#elif defined( LIGHT_OMNI )
	L = normalize( var_LightVec );
#elif defined( LIGHT_PROJ )
	L = normalize( u_LightDir.xyz );
#endif

#if defined( APPLY_TERRAIN )
	vec4 mask0, mask1, mask2, mask3;
	TerrainReadMask( var_TexGlobal, mask0, mask1, mask2, mask3 );
#endif

// parallax     
#if defined( PARALLAX_SIMPLE )
	vec_TexDiffuse = ParallaxMapSimple(var_TexDiffuse.xy, normalize(var_ViewDir));
#elif defined( PARALLAX_OCCLUSION )
	vec_TexDiffuse = ParallaxOcclusionMap(var_TexDiffuse.xy, normalize(var_ViewDir)).xy;
#endif

// compute the normal first
#if defined( HAS_NORMALMAP )
#if defined( APPLY_TERRAIN )
	vec3 N = TerrainApplyNormal( u_NormalMap, vec_TexDiffuse, mask0, mask1, mask2, mask3 );
#else
	vec3 N = normalmap2D( u_NormalMap, vec_TexDiffuse );
#endif
#else
	vec3 N = normalize( var_Normal );
#endif
	// compute the diffuse term
#if defined( PLANAR_REFLECTION ) && !defined( LIQUID_UNDERWATER ) // HACKHACK
	vec4 diffuse = reflectmap2D( u_ColorMap, var_TexMirror, N, gl_FragCoord.xyz, u_RefractScale );
#elif defined( APPLY_TERRAIN )
	vec4 diffuse = TerrainApplyDiffuse( u_ColorMap, vec_TexDiffuse, mask0, mask1, mask2, mask3 );
#else
	vec4 diffuse = colormap2D( u_ColorMap, vec_TexDiffuse );
#endif

#if defined( HAS_NORMALMAP )
	// rotate normal to worldpsace
	N = normalize( var_WorldMat * N );
#endif

#if defined( SIGNED_DISTANCE_FIELD )
	diffuse.a *= smoothstep( SOFT_EDGE_MIN, SOFT_EDGE_MAX, diffuse.a ); 
#endif

#if defined( HAS_DETAIL )
#if defined( APPLY_TERRAIN )
	diffuse.rgb *= detailmap2D( u_DetailMap, var_TexGlobal ).rgb * DETAIL_SCALE;
#else
	diffuse.rgb *= detailmap2D( u_DetailMap, var_TexDetail ).rgb * DETAIL_SCALE;
#endif
#endif
	// lighting the world polys
#if defined( APPLY_TERRAIN )
	float smoothness = TerrainCalcSmoothness( u_Smoothness, mask0, mask1, mask2, mask3 );
#else
	float smoothness = u_Smoothness;
#endif
	vec4 glossmap = vec4( 0.0 );

	// compute the specular term
#if defined( HAS_GLOSSMAP )
#if defined( APPLY_TERRAIN )
	glossmap = TerrainApplySpecular( u_GlossMap, vec_TexDiffuse, mask0, mask1, mask2, mask3 );
#else
	glossmap = texture2D( u_GlossMap, vec_TexDiffuse );
#endif
#endif//HAS_GLOSSMAP

	vec3 light = vec3( 1.0 );
	float shadow = 1.0;

	light = u_LightDiffuse * DLIGHT_SCALE;	// light color
	float NdotL = saturate( dot( N, L ));
	if( NdotL <= 0.0 ) discard; // fast reject

#if defined( LIGHT_SPOT )
	// texture or procedural spotlight
	light *= texture2DProj( u_ProjectMap, var_ProjCoord ).rgb;
#if defined( APPLY_SHADOW )
	if( NdotL > 0.0 ) shadow = ShadowSpot( var_ShadowCoord, u_ShadowParams.xy );
#endif
#elif defined( LIGHT_OMNI )
#if defined( APPLY_SHADOW )
	if( NdotL > 0.0 ) shadow = ShadowOmni( -var_LightVec, u_ShadowParams );
#endif
#elif defined( LIGHT_PROJ )
#if defined( APPLY_SHADOW )
	if( NdotL > 0.0 )
	{
		shadow = ShadowProj( var_ShadowCoord.xyz );
		shadow = mix( shadow, 0.0, u_SunRefract );
		shadow = max( shadow, u_AmbientFactor );
	}
#endif
#endif
	if( shadow <= 0.0 ) discard; // fast reject

	vec3 albedo = diffuse.rgb;
	float factor = DiffuseBRDF( N, V, L, smoothness, NdotL );
	diffuse.rgb *= light.rgb * factor * atten * shadow;
#if defined( LIGHT_PROJ )
	diffuse.rgb += (albedo * u_LightDiffuse * u_AmbientFactor);
#endif
#if defined( HAS_GLOSSMAP )
	vec3 gloss = SpecularBRDF( N, V, L, smoothness, glossmap.rgb ) * light * NdotL * atten;
	diffuse.rgb += gloss * shadow;
#endif
	// compute final color
	gl_FragColor = diffuse;
}