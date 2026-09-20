# Velyntora

Velyntora es un editor original de animación 2D para escritorio. Busca conservar la facilidad de una aplicación móvil y crecer hacia un flujo profesional, sin anuncios, marcas de agua ni funciones bloqueadas.

## Primera versión funcional

- Galería local de proyectos.
- Creación de proyectos 16:9 a 1920 × 1080.
- Editor oscuro optimizado para escritorio.
- Lienzo dibujable con ratón o pantalla táctil.
- Pincel, borrador, color y tamaño.
- Capas visibles y bloqueables.
- Fotogramas, duplicación y reproducción.
- Papel cebolla.
- Cuadrícula.
- Deshacer el último trazo.
- Identidad visual e icono de Velyntora.

## Ejecutar

Se requiere Flutter estable con soporte de escritorio habilitado.

```bash
flutter create . --platforms=windows,linux,macos
flutter pub get
flutter run -d windows
```

En Linux sustituye `windows` por `linux`; en macOS usa `macos`.

## Próximos hitos

1. Guardado local en formato `.vely`.
2. Miniaturas reales en la línea de tiempo.
3. Selección, transformación, relleno y texto.
4. Importación de imágenes, audio y video.
5. Exportación PNG, GIF y MP4 mediante FFmpeg.
6. Presión de tableta y motor de pinceles avanzado.

## Estado

Versión `0.1.0`: prototipo funcional inicial. El guardado en disco y la exportación todavía aparecen como funciones en preparación.
