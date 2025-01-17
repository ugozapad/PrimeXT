/*
gaussblur_fp.glsl - Gaussian Blur For Mips program
Copyright (C) 2021 ncuxonaT

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
*/

#include "mathlib.h"

uniform sampler2D	u_ScreenMap;
uniform vec2		u_ScreenSizeInv;
uniform float		u_MipLod;	// source mip level, not target one
uniform vec4		u_TexCoordClamp;
uniform int			u_BloomFirstPass;
uniform float 		u_RefractScale; // bloom scale

varying vec2		var_TexCoord;

void main( void )
{
	//gaussian 3x3
	float weight[3];
	weight[0] = 0.25;
	weight[1] = 0.125;
	weight[2] = 0.0625;	
			
	vec4 tex_sample[9];
	tex_sample[0] = texture2DLod(u_ScreenMap, clamp(var_TexCoord ,u_TexCoordClamp.xy , u_TexCoordClamp.zw), u_MipLod);
	tex_sample[1] = texture2DLod(u_ScreenMap, clamp(var_TexCoord + vec2(u_ScreenSizeInv.x, 0.0) ,u_TexCoordClamp.xy, u_TexCoordClamp.zw), u_MipLod);
	tex_sample[2] = texture2DLod(u_ScreenMap, clamp(var_TexCoord + vec2(-u_ScreenSizeInv.x, 0.0) ,u_TexCoordClamp.xy, u_TexCoordClamp.zw), u_MipLod);
	tex_sample[3] = texture2DLod(u_ScreenMap, clamp(var_TexCoord + vec2(0.0, -u_ScreenSizeInv.y) ,u_TexCoordClamp.xy, u_TexCoordClamp.zw), u_MipLod);
	tex_sample[4] = texture2DLod(u_ScreenMap, clamp(var_TexCoord + vec2(0.0, u_ScreenSizeInv.y) ,u_TexCoordClamp.xy, u_TexCoordClamp.zw), u_MipLod);		
	tex_sample[5] = texture2DLod(u_ScreenMap, clamp(var_TexCoord + vec2(u_ScreenSizeInv.x, u_ScreenSizeInv.y), u_TexCoordClamp.xy, u_TexCoordClamp.zw), u_MipLod);
	tex_sample[6] = texture2DLod(u_ScreenMap, clamp(var_TexCoord + vec2(-u_ScreenSizeInv.x, u_ScreenSizeInv.y), u_TexCoordClamp.xy, u_TexCoordClamp.zw), u_MipLod);
	tex_sample[7] = texture2DLod(u_ScreenMap, clamp(var_TexCoord + vec2(-u_ScreenSizeInv.x, -u_ScreenSizeInv.y), u_TexCoordClamp.xy, u_TexCoordClamp.zw), u_MipLod);
	tex_sample[8] = texture2DLod(u_ScreenMap, clamp(var_TexCoord + vec2(u_ScreenSizeInv.x, -u_ScreenSizeInv.y), u_TexCoordClamp.xy, u_TexCoordClamp.zw), u_MipLod);	
	
	vec4 outputColor;
	outputColor = weight[0] * tex_sample[0];
	outputColor += weight[1] * (tex_sample[1] + tex_sample[2] + tex_sample[3] + tex_sample[4]);
	outputColor += weight[2] * (tex_sample[5] + tex_sample[6] + tex_sample[7] + tex_sample[8]);	
	
	if (u_BloomFirstPass > 0) 
	{
		const float threshold = 0.8;
		const float transitionSmooth = 0.7;
		float luminance = GetLuminance(outputColor.rgb);
		outputColor *= smoothstep(threshold - transitionSmooth, threshold, luminance);
		outputColor = clamp(outputColor * u_RefractScale, vec4(0.0), vec4(25000.0));
	}

	gl_FragColor = outputColor;
}