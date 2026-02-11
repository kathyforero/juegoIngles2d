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

## Modos de juego
El proyecto tiene 4 modos, que se desbloquean/gestionan desde el menú de juegos (según progreso):

### 1) Normal (Classic)
Modo estándar por minijuego y dificultad (Easy/Medium/Hard).
- Guarda progreso y records.
- Se usa para desbloquear contenido y modos.

### 2) Random
Modo con selección aleatoria (orientado a rejugabilidad).
- Se desbloquea al cumplir condiciones de progreso.
- Puede seleccionar contenido aleatorio del banco del minijuego.
- También guarda records/progreso según configuración del modo.

### 3) Libre (Practice)
Modo de práctica sin presión.
- No guarda records (ideal para practicar sin afectar puntajes).
- Puede desactivar lógica de tiempo/competencia (según minijuego).
- Útil para repetir ejercicios sin penalización.

### 4) Turbo (Time Attack)
Modo contrarreloj.
- El objetivo es hacer la mayor cantidad de aciertos antes de que acabe el tiempo.
- Puede ser por minijuego específico o selección aleatoria (según configuración actual).
- Guarda records del modo Turbo/Time Attack.

> Nota: Las reglas exactas (si guarda record, si usa random interno, si aplica timer) están centralizadas principalmente en `Scripts/Global/Score.gd` y el progreso/desbloqueos se guardan en archivos dentro de `user://Progress/`.

## Sistemas de puntajes y logros

### Puntajes / Records
El sistema maneja records por modo y minijuego.
- Centralizado en `Scripts/Global/Score.gd`.
- Incluye soporte para:
  - **Classic** (Normal)
  - **Time Attack** (Turbo)
  - **Practice** (Libre, usualmente sin persistencia de record)
- Los records se guardan en `user://Progress/` (archivos `.dat`).
- Dependiendo del modo:
  - Classic guarda progreso y record.
  - Time Attack guarda record específico del modo.
  - Practice evita persistir records para no “ensuciar” estadísticas.

### Logros (Achievements)
El juego incluye un sistema de logros persistentes.
- Se guardan en `user://Progress/achievements.dat`.
- También se gestionan desde `Scripts/Global/Score.gd` (y escenas/UI relacionadas).
- Hay logros por minijuego, por desempeño (ej. perfect), y por modos (ej. speed/time-attack), con soporte de iconos/estados (incluyendo “unknown” cuando no está desbloqueado).

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

## Issues
Durante el desarrollo hubo problemas debido a un **cambio de estructura del proyecto** (reorganización de carpetas), que incluyó:
- Mover archivos a nuevas rutas.
- Eliminar archivos obsoletos.
- Renombrar escenas/scripts/assets.

Esto provocó errores típicos como:
- Rutas rotas en escenas (`.tscn`) y scripts (`res://...`).
- Recursos no encontrados (sprites, sonidos, JSON).
- Referencias antiguas en botones, nodos o `load()/preload()`.

**Recomendación:** Si aparece un error de “resource not found”, revisar primero rutas y nombres reales en el árbol del proyecto, y luego buscar en scripts por `res://` hardcodeado.

## Contribución
- Mantener rutas y carpetas existentes; reutilizar scripts globales (`Scripts/Global/*`) y `scene_router.gd`.
- Antes de subir, abrir en Godot 4.5 y validar la exportación a Windows.
