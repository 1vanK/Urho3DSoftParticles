#include "Uniforms.glsl"
#include "Samplers.glsl"
#include "Transform.glsl"
#include "ScreenPos.glsl"
#include "Fog.glsl"

varying vec4 vScreenPos;
varying vec2 vTexCoord;
varying vec4 vWorldPos;

#ifdef VERTEXCOLOR
    varying vec4 vColor;
#endif

#ifdef SOFTPARTICLES
uniform float cFadeScale;           // [1.0..n]
uniform float cFadeContrastPower;   // [1.0..n]
#endif  

void VS()
{
    mat4 modelMatrix = iModelMatrix;
    vec3 worldPos = GetWorldPos(modelMatrix);
    gl_Position = GetClipPos(worldPos);
    vTexCoord = GetTexCoord(iTexCoord);
    vWorldPos = vec4(worldPos, GetDepth(gl_Position));
    
    #ifdef VERTEXCOLOR
        vColor = iColor;
    #endif
    
    #ifdef SOFTPARTICLES    
        vScreenPos = GetScreenPos(gl_Position);
    #endif
}

void PS()
{
    // Get material diffuse albedo
    #ifdef DIFFMAP
        vec4 diffColor = cMatDiffColor * texture2D(sDiffMap, vTexCoord);
        #ifdef ALPHAMASK
            if (diffColor.a < 0.5)
                discard;
        #endif
    #else
        vec4 diffColor = cMatDiffColor;
    #endif

    #ifdef VERTEXCOLOR
        diffColor *= vColor;
    #endif

    // Get fog factor
    #ifdef HEIGHTFOG
        float fogFactor = GetHeightFogFactor(vWorldPos.w, vWorldPos.y);
    #else
        float fogFactor = GetFogFactor(vWorldPos.w);
    #endif
        
    #ifdef SOFTPARTICLES
        #ifdef HWDEPTH
            float sceneZ = ReconstructDepth(texture2DProj(sDepthBuffer, vScreenPos).r);            
        #else
            float sceneZ = DecodeDepth(texture2DProj(sDepthBuffer, vScreenPos).rgb);
        #endif
                    
        float particleDepth = vWorldPos.w;
        float sceneDepth = sceneZ;
                     
        float diffZ = (sceneDepth - particleDepth) * (cFarClipPS - cNearClipPS);
        diffZ *= cFadeScale;
        
        float input = clamp(diffZ, 0.0, 1.0);        
        float output = 0.5 * pow(clamp(2*((input > 0.5) ? 1 - input : input), 0.0, 1.0), cFadeContrastPower);
        float weight = (input > 0.5) ? 1 - output : output; 
            
        diffColor.a *= weight;
    #endif

    #if defined(PREPASS)
        // Fill light pre-pass G-Buffer
        gl_FragData[0] = vec4(0.5, 0.5, 0.5, 1.0);
        gl_FragData[1] = vec4(EncodeDepth(vWorldPos.w), 0.0);
    #elif defined(DEFERRED)
        gl_FragData[0] = vec4(GetFog(diffColor.rgb, fogFactor), diffColor.a);
        gl_FragData[1] = vec4(0.0, 0.0, 0.0, 0.0);
        gl_FragData[2] = vec4(0.5, 0.5, 0.5, 1.0);
        gl_FragData[3] = vec4(EncodeDepth(vWorldPos.w), 0.0);
    #else            
        gl_FragColor = vec4(GetFog(diffColor.rgb, fogFactor), diffColor.a);
    #endif
}

