# Velyntora

Velyntora es un editor original de animación 2D. Su primera plataforma de prueba es Android mediante APK; posteriormente llegará a escritorio. Busca conservar la facilidad de una aplicación móvil y crecer hacia un flujo profesional, sin anuncios, marcas de agua ni funciones bloqueadas.

## Primera versión funcional

- Galería local de proyectos.
- Apertura y eliminación segura de proyectos guardados.
- Proyectos HD, Full HD, cuadrados y verticales.
- Editor adaptable para Android y escritorio.
- Lienzo dibujable con ratón o pantalla táctil.
- Pincel, marcador, tinta, borrador, relleno, texto y selección.
- Capas reordenables con visibilidad, bloqueo y opacidad.
- Fotogramas, duplicación, reproducción y deshacer/rehacer.
- Velocidad configurable entre 6 y 60 FPS.
- Miniaturas reales en la línea de tiempo.
- Papel cebolla.
- Cuadrícula.
- Transformación de trazos y textos: mover, escalar y rotar.
- Guardado local de proyectos `.vely`.
- Guardado automático y aviso antes de descartar cambios.
- Exportación del fotograma actual o de una secuencia PNG completa.
- Exportación GIF animada según los FPS del proyecto.
- Exportación de video MP4 H.264, con audio importado y los FPS del proyecto.
- Compartir fotogramas, GIF y MP4 mediante el menú nativo del sistema.
- Identidad visual e icono de Velyntora.

## Ejecutar

Se requiere Flutter estable con soporte de escritorio habilitado.

```bash
flutter create . --platforms=windows,linux,macos
flutter pub get
flutter run -d windows
```

En Linux sustituye `windows` por `linux`; en macOS usa `macos`.

Para Android:

```bash
flutter create . --platforms=android
flutter pub get
flutter build apk --release
```

## Próximos hitos

1. Importación de imágenes, audio y video.
2. Optimización continua del rendimiento en proyectos extensos.
3. Relleno por regiones cerradas.
4. Presión de tableta y motor de pinceles avanzado.

## Estado

Versión `0.1.0`: prototipo funcional en desarrollo. El guardado local y la exportación PNG ya funcionan.
