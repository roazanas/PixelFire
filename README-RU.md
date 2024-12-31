# PixelFire

[English](README.md) | Русский

Проект PixelFire представляет собой реализацию HLSL шейдера для создания пиксельного эффекта огня с дополнительной возможностью добавления контура текста.

## Демонстрация

![Демонстрация работы шейдера](demo.gif)

## Описание

PixelFire - это HLSL шейдер для Windows Terminal, который создает процедурно-генерируемый эффект огня.

## Параметры для кастомизации

### Размер и позиция огня

```hlsl
float2 fireSize = float2(128, 128);  // Размер огня в пикселях
float2 firePosition = float2(
    Resolution.x - fireSize.x / 2,   // X-координата (справа)
    Resolution.y - fireSize.y / 2    // Y-координата (снизу)
);
```

### Цвета пламени

```hlsl
// Цвета в формате RGB (0-255)
float3 topColorRGB = float3(124, 68, 79);      // Верхний слой огня
float3 middleColorRGB = float3(159, 82, 85);   // Средний слой огня
float3 bottomColorRGB = float3(225, 106, 84);  // Нижний слой огня
```

## Пикселизация

```hlsl
float pixelDivisions = 30;     // Количество делений на пиксельной сетке (больше = мельче пиксели)
```

> 💡 **О пиксельной сетке**: Параметр `pixelDivisions` определяет детализацию эффекта. Маленькие значения (1-5) создают крупные пиксели, значения около 30 дают классический пиксельный вид, а большие значения (50+) делают эффект более плавным.

## Настройка контура текста

```hlsl
int t = 1;  // thickness (use only 0, 1 or 2)
```

0 - без контура, 1 - тонкий, 2 - толстый (больше не рекомендуется)

## Дополнительные параметры

> ⚠️ **Важно**: К этим параметрам следует отнестись с осторожностью, так как они могут значительно изменить внешний вид огня или испортить его.

```hlsl
float gradientInfluence = 0.25;   // Влияние градиентного шума
float voronoiInfluence = 0.75;    // Влияние шума Вороного
```

### Направление движения

```hlsl
float2 gradientMovementDir = float2(-0.1, 0.65);  // Направление движения градиентного шума
float2 voronoiMovementDir = float2(0.1, 0.3);     // Направление движения шума Вороного
```

Изменяя эти параметры, можно настроить как сильно и в каком направлении движется огонь.

## Установка в Windows Terminal

1. Откройте настройки Windows Terminal (Settings)
2. Найдите и откройте файл `settings.json`
3. В секции `profiles.defaults` или для конкретного профиля добавьте:

```json
"experimental.pixelShaderPath": "путь_к_файлу/PixelFire.hlsl"
```

4. Сохраните файл settings.json и перезапустите Windows Terminal

Пример полной конфигурации профиля:

```json
{
    "closeOnExit": "automatic",
    "colorScheme": "One Half Dark",
    "commandline": "%SystemRoot%\\System32\\cmd.exe",
    "experimental.pixelShaderPath": "D:\\PixelFire\\PixelFire.hlsl",
    "guid": "{fe031872-527f-49d0-bafd-82904a6fb3b3}",
    "hidden": false,
    "historySize": 9001,
    "name": "Shaders",
    "snapOnInput": true,
    "startingDirectory": "%USERPROFILE%",
    "tabTitle": "cmd"
}
```

**Примечание**: Убедитесь, что используете полный путь к файлу шейдера и прямые слеши (/) вместо обратных (\\) в пути. А если используете обратные, то экранируйте их (\\\\).
