# 🌈 Aprendo App - Documentación del Proyecto

## 1. Visión General del Proyecto
**Aprendo App** es una plataforma educativa interactiva compuesta por un Frontend desarrollado en **Flutter** y un Backend desarrollado en **Django**. El enfoque principal de la aplicación es proporcionar una serie de minijuegos terapéuticos y educativos para los usuarios, con mecánicas visuales llamativas (Diseño Premium Dark UI con gradientes y tarjetas estilo glassmorphism) y asistencia estructurada de voz vía **Text-To-Speech (TTS)**.

## 2. Arquitectura de la Solución
La plataforma sigue un modelo Cliente-Servidor donde:
- **Frontend (Mobile / Web):** Desarrollado en **Flutter** (Versión SDK ^3.11.1). Actúa como contenedor principal. Utiliza un `WebView` avanzado para incrustar los juegos que provienen del servidor.
- **Backend (API y Hosting de Juegos):** Desarrollado en **Django** y desplegado en la nube (actualmente hospedado en `https://aprendo-app-backend.onrender.com`). Renderiza las interfaces en HTML/JS de los juegos interactivos.

## 3. Características Principales

### 3.1. Hub de Juegos y Pantalla Principal
- **Listado Dinámico:** Solicita dinámicamente un catálogo de juegos disponibles a través de una API HTTP.
- **Ranking y Estadísticas Locales:** Implementa un sistema de guardado local utilizando `shared_preferences` que almacena datos de los juegos como la cantidad de **sesiones jugadas**, **mejor puntuación**, **puntuación total** y **fecha de la última partida** para trazar un Ranking competitivo.

### 3.2. Integración de WebView (Motor de Juegos)
- Los juegos se abren instantáneamente dentro de `GamePage` cargando una URL del backend basada en el nombre del juego (p. ej., `numero_master`, `rutinas`, `terapeutico`).
- **Canales de Comunicación JS-Flutter (JavaScriptChannels):**
  - `FlutterStorage`: Captura los datos guardados en el `localStorage` del WebView (HTML/JS del juego) y sincroniza automáticamente las estadísticas con el dispositivo nativo a través del método de Flutter en un intervalo (polling cada 5 segundos).

### 3.3. Text-to-Speech (TTS) Avanzado
- Utiliza la librería **`flutter_tts`** para proporcionar capacidades de lectura en voz alta dentro de los mismos juegos web.
- Se implementó un "Polyfill" nativo que intercepta y reemplaza la API de `window.speechSynthesis` del navegador del WebView, haciendo que cualquier solicitud de habla desde el juego sea transmitida nativamente a Flutter por el canal de comunicación `FlutterTTS`.
- Maneja configuraciones de velocidad (`rate`) dependientes del juego, por ejemplo: voces más lentas y controladas en el juego *Numero Master* o *Juegos Terapéuticos*.

### 4. Tecnologías y Librerías (Tech Stack)

#### Frontend (Flutter):
- **http (^1.1.0):** Para consumo de API y obtención de los juegos.
- **webview_flutter (^4.4.1):** Motor de renderizado en la aplicación para ejecutar los minijuegos web del Backend.
- **shared_preferences (^2.2.3):** Para almacenamiento persistente ligero de las estadísticas de juego y medallas a nivel local.
- **flutter_tts (^4.2.5):** Síntesis de voz para accesibilidad o guiado paso a paso.

#### Diseño (UI / UX):
- **Tema:** Variante oscura (Dark Mode), optimizada con una paleta vibrante de gradientes y transparencias simulando cristal.
- **Feedback Visual:** Implementación de medallas (🥇, 🥈, 🥉) según estadísticas del jugador.

### 5. Compilación y Despliegue
- El frontend soporta compilación nativa en **Android (APK)** y **Web**.
- Para la generación del APK en Android, usa Gradle y depende implícitamente de configuraciones locales de compilación y Java 17.

## 6. Próximos Pasos Recomendados o Mejoras
1. **Sincronización Cloud:** En vez de (o además de) usar `shared_preferences`, sincronizar los progresos locales de manera autenticada con los perfiles en el backend de Django.
2. **Sistema de Caching Offline:** Interceptar las peticiones Web para que los módulos del juego (HTML, CSS, JS e imágenes) sean cacheados y puedan jugar sin necesidad de conexión estable a internet todo el tiempo.
3. **Optimización del WebView:** Control estricto del ciclo de vida del WebView para asegurar que tanto la carga de CPU como el audio TTS no queden "zombies" una vez el usuario retorna al menú principal.
