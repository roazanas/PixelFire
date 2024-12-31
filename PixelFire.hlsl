Texture2D shaderTexture;
SamplerState samplerState;

cbuffer PixelShaderSettings {
    float Time;
    float Scale;
    float2 Resolution;
    float4 Background;
};

float2 GenerateVoronoiCellOffset(float2 cellUV, float angleOffset)
{
    float2x2 noiseMatrix = float2x2(15.27, 47.63, 99.41, 89.98);
    cellUV = frac(sin(mul(cellUV, noiseMatrix)) * 46839.32);
    return float2(sin(cellUV.y * angleOffset), cos(cellUV.x * angleOffset)) * 0.5 + 0.5;
}

float GenerateVoronoiNoise(float2 uv, float angleOffset, float cellDensity)
{
    float2 gridCell = floor(uv * cellDensity);
    float2 gridUV = frac(uv * cellDensity);
    float3 minDistance = float3(8.0, 0.0, 0.0);

    for (int y = -1; y <= 1; y++)
    {
        for (int x = -1; x <= 1; x++)
        {
            float2 neighborCell = float2(x, y);
            float2 cellOffset = GenerateVoronoiCellOffset(neighborCell + gridCell, angleOffset);
            float distToFeaturePoint = distance(neighborCell + cellOffset, gridUV);
            
            if (distToFeaturePoint < minDistance.x)
            {
                minDistance = float3(distToFeaturePoint, cellOffset.xy);
            }
        }
    }
    return minDistance.x + 0.125;
}

float2 GenerateGradientNoiseDir(float2 position)
{
    position = position % 289;
    float hash = (34 * position.x + 1) * position.x % 289 + position.y;
    hash = (34 * hash + 1) * hash % 289;
    hash = frac(hash / 41) * 2 - 1;
    return normalize(float2(hash - floor(hash + 0.5), abs(hash) - 0.5));
}

float GenerateGradientNoise(float2 position)
{
    float2 gridCell = floor(position);
    float2 gridUV = frac(position);
    
    float2 dir00 = GenerateGradientNoiseDir(gridCell);
    float2 dir01 = GenerateGradientNoiseDir(gridCell + float2(0, 1));
    float2 dir10 = GenerateGradientNoiseDir(gridCell + float2(1, 0));
    float2 dir11 = GenerateGradientNoiseDir(gridCell + float2(1, 1));
    
    float dot00 = dot(dir00, gridUV);
    float dot01 = dot(dir01, gridUV - float2(0, 1));
    float dot10 = dot(dir10, gridUV - float2(1, 0));
    float dot11 = dot(dir11, gridUV - float2(1, 1));
    
    gridUV = gridUV * gridUV * gridUV * (gridUV * (gridUV * 6 - 15) + 10);
    return 0.5 - lerp(lerp(dot00, dot01, gridUV.y), lerp(dot10, dot11, gridUV.y), gridUV.x);
}

float2 CalculateLocalUV(float2 globalUV, float2 rectCenter, float2 rectSize)
{
    float2 bottomLeft = rectCenter - rectSize * 0.5;
    return (globalUV - bottomLeft) / rectSize;
}

bool IsPointInRectangle(float2 pnt, float2 rectCenter, float2 rectSize)
{
    float2 bottomLeft = rectCenter - rectSize * 0.5;
    float2 topRight = rectCenter + rectSize * 0.5;
    return pnt.x >= bottomLeft.x && pnt.x <= topRight.x &&
           pnt.y >= bottomLeft.y && pnt.y <= topRight.y;
}

// Applies outline effect by sampling neighboring pixels
// https://github.com/microsoft/terminal/blob/main/samples/PixelShaders/Outlines.hlsl
float4 ApplyTextOutline(float2 uv, float4 originalColor)
{
    int t = 1;  // thickness (use only 0, 1 or 2)
    float4 outlinedColor = originalColor;

    for (int dy = -t; dy <= t; dy += t)
    {
        for (int dx = -t; dx <= t; dx += t)
        {
            if (dx == 0 && dy == 0) continue;
            float4 neighborColor = shaderTexture.Sample(samplerState, uv, int2(dx, dy));
            outlinedColor.a += neighborColor.a * 0.25;
        }
    }
    
    return outlinedColor;
}

float4 main(float4 pos : SV_POSITION, float2 uv : TEXCOORD0) : SV_TARGET
{
    // Flame size and position
    float2 fireSize = float2(128, 
                             128);
    float2 firePosition = float2(
        // Right-bottom corner
        Resolution.x - fireSize.x / 2, 
        Resolution.y - fireSize.y / 2
    );
    
    float2 fireCenter = firePosition / Resolution;


    // Flame defining parameters
    float pixelDivisions = 30;
    float gradientInfluence = 0.25;
    float voronoiInfluence = 0.75;
    
    float2 gradientMovementDir = float2(-0.1, 0.65);
    float2 voronoiMovementDir = float2(0.1, 0.3);

    float topThreshold = 0.1;
    float middleThreshold = 0.25;
    float bottomThreshold = 0.5;


    // Flame colors
    float3 topColorRGB = float3(
        124, 68, 79
    );
    float3 middleColorRGB = float3(
        159, 82, 85
    );
    float3 bottomColorRGB = float3(
        225, 106, 84
    );
    
    float4 topColor = float4(topColorRGB / 255, 1);
    float4 middleColor = float4(middleColorRGB / 255, 1);
    float4 bottomColor = float4(bottomColorRGB / 255, 1);

    
    float4 textColor = shaderTexture.Sample(samplerState, uv);
    float4 outlinedText = ApplyTextOutline(uv, textColor);

    // If point is outside the fire rectangle, don't draw anything except the outlined text
    if (!IsPointInRectangle(uv, fireCenter, fireSize / Resolution))
    {
        return outlinedText;
    }

    // Local and pixelated coordinates
    float2 localUV = CalculateLocalUV(uv, fireCenter, fireSize / Resolution);
    float2 pixelatedUV = round(localUV * pixelDivisions) / pixelDivisions;

    // Noises
    float2 gradientOffset = gradientMovementDir * Time;
    float2 voronoiOffset = voronoiMovementDir * Time;
    
    float gradientNoise = GenerateGradientNoise((pixelatedUV + gradientOffset) * 10);
    float voronoiNoise = GenerateVoronoiNoise(
        pixelatedUV + voronoiOffset,
        2.0,
        5.0
    );

    float heightGradient = lerp(gradientNoise, pixelatedUV.y, gradientInfluence);
    float cellPattern = lerp(1, voronoiNoise, voronoiInfluence);
    float combinedNoise = cellPattern * heightGradient;
    
    // Apply fade masks
    float verticalFade = smoothstep(0, 0.75, localUV.y);
    float radialFade = 1.0 - length(localUV - float2(0.5, 0.5));
    float combinedMask = verticalFade / 1.5 + radialFade * radialFade;

    float4 noiseColor = float4(combinedNoise, combinedNoise, combinedNoise, 1);
    float4 maskedNoise = lerp(Background, noiseColor, combinedMask);

    // Divide the noise into 3 layers
    float4 topLayer = step(topThreshold, maskedNoise.y);
    float4 middleLayer = step(middleThreshold, maskedNoise.y);
    float4 bottomLayer = step(bottomThreshold, maskedNoise.y);

    float4 topFlame = (topLayer - middleLayer) * topColor;
    float4 middleFlame = (middleLayer - bottomLayer) * middleColor;
    float4 bottomFlame = bottomLayer * bottomColor;

    // Combine layers and draw outline on top
    float4 finalFlame = topFlame + middleFlame + bottomFlame;
    if (outlinedText.a != 0)
        return outlinedText;
    else
        return finalFlame;
}