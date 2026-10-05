# RUN24

Prototipo de run-and-gun roguelite desarrollado en Godot 4.7.2.

## Jugar en navegador

El repositorio incluye un workflow de GitHub Actions que exporta automaticamente la version Web y la publica en GitHub Pages cuando hay cambios en `main`.

## Desarrollo

- Engine: Godot 4.7.2
- Lenguaje: GDScript
- Renderer: Compatibility
- Web export: sin threads para compatibilidad con GitHub Pages

## Deploy

1. Configurar GitHub Pages con Source = GitHub Actions.
2. Hacer push a `main`.
3. El workflow `Deploy RUN24 Web` valida, exporta y publica el juego.
