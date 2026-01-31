# Juego Inglés 2D (Godot 4.5)

Proyecto en Godot 4.5 con minijuegos para practicar inglés.

## Stack y requisitos
- Godot Engine 4.5 stable 64-bit (`Godot_v4.5-stable_win64.exe`).
- Plantillas de exportación 4.5 instaladas (Windows Desktop).
- Windows 10/11. No hay dependencias externas ni gestores de paquetes.

## Layout rápido
- `project.godot` -> escena principal del proyecto: `Escenas/menu_principal.tscn`.
- `Escenas/` -> escenas del menú y minijuegos.
- `Scripts/` -> GDScript (globales, HUD, lógica de juegos).
- `JsonJuegos/` -> datos para los juegos.
- `Sprites/`, `Sonido/`, `Fonts/`, `Piezas/`, `Videos/`, `styles/` -> assets.

## Exportar a Windows
GUI: Project > Export > preset **Windows Desktop** (ya creado). Ajustar la ruta de salida y Export.

## Datos en JSON
Todo el contenido editable está en `JsonJuegos/`.

### Puzzle (frases desordenadas) - `JsonJuegos/Banco_Puzzle.json`
- Array `exercises`: cada item tiene `id`, `image`, `esp`, `eng`.
- `image`: nombre del PNG en `Sprites/images_games/puzzle/` (sin extensión).
- `esp` / `eng` son objetos con `easy`, `medium`, `hard`.
  - `esp.<nivel>`: lista de frases completas en español.
  - `eng.<nivel>`: lista de listas; cada sublista es el orden correcto de fragmentos en inglés.
- Para agregar:
  1) Duplicar un ejercicio y cambiar `id` y `image` (PNG existente).  
  2) Escribir 1-2 frases por nivel en `esp`; armar los fragmentos equivalentes en `eng`.  
  3) Guardar y comprobar en Puzzle Easy/Medium/Hard.

### Order It (palabra + imagen) - `JsonJuegos/Banco_OrderIt.json`
- Claves de nivel: `easy`, `medium`, `hard`; cada una es una lista de objetos `{ esp, eng, image }`.
- `image`: ruta relativa a `Sprites/images_games/order/<Nivel>/archivo.png`.
- Para agregar:
  1) Copiar el PNG en la carpeta del nivel.  
  2) Añadir un objeto en el arreglo del nivel con `esp`, `eng`, `image` (`res://Sprites/...`).

### Match It (nombre + imagen) - `JsonJuegos/Banco_MatchIt.json`
- Diccionarios por nivel (`easy`, `medium`, `hard`): `"palabra" : "res://Sprites/images_games/match/<nivel>/Archivo.png"`.
- Para agregar:
  1) Colocar el PNG en la carpeta del nivel.  
  2) Añadir la pareja clave/valor en el diccionario del nivel.

### Guía / Vocabulario - `JsonJuegos/CardLabels.json`
- `categories`: lista de categorías. Cada una tiene `label`, `label_en`, `sprites`, `cards`.
- `sprites` y `cards` deben tener el mismo largo y orden. Se muestran 9 por página.
- Texto sugerido en `cards`: `Inglés:\nEspañol`.
- Para agregar:
  - Nueva categoría: duplicar una existente, cambiar labels, rellenar `sprites` y `cards`.  
  - Más cartas en una categoría: añadir al final en ambos arrays.

## Idioma
`language_setting.json`: `{"english": false}` -> arranca en español. Cambiar a `true` para inglés.

## Checks rápidos
- Correr el minijuego afectado y observar la consola por `push_error` (formato JSON o rutas rotas).
- Verificar que las imágenes carguen y que la cantidad de ítems por dificultad coincida.

## Contribución
- Mantener rutas y carpetas existentes; reutilizar scripts globales (`Scripts/Global/*`) y `scene_router.gd`.
- Antes de subir, abrir en Godot 4.5 y validar la exportación a Windows.
