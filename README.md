# 📺 AniCli-Cast V2

[**Ver Tutorial en YouTube**](#-presentación-y-tutorial-oficial) | [**Instalación Rápida**](#-instalación-y-uso) | [**Biblioteca**](#-características-principales)

---

## 📺 Presentación y Tutorial Oficial
[![AniCli-Cast V2](https://img.youtube.com/vi/tw1isZXJdpg/0.jpg)](https://www.youtube.com/watch?v=tw1isZXJdpg)

*Haz clic en la imagen para ver las nuevas funciones en acción (V2).*

---

# 📝 Descripción 
Un potente gestor y reproductor de Anime para tu terminal.
AniCli-Cast es un script de Bash diseñado para buscar, extraer y reproducir contenido de Jkanime directamente en tu terminal. Olvídate de la publicidad intrusiva y gestiona tu propia biblioteca local de enlaces de forma eficiente.
✨ Características Principales
 * 🔍 Buscador Inteligente: Encuentra cualquier serie o película disponible mediante integración con fzf.
 * 📂 Biblioteca Local: Guarda los enlaces extraídos para verlos más tarde sin necesidad de volver a buscar.
 * ⭐ Sistema de Favoritos: Marca tus series imprescindibles para un acceso rápido.
 * ⏱️ Watch Later (Reanudación): El script guarda automáticamente tu posición en cada video. Si cierras el reproductor, retomarás exactamente donde lo dejaste.
 * 🔗 Extracción Robusta: Procesa automáticamente múltiples servidores (Mediafire, etc.) y detecta si los enlaces están caídos antes de reproducir.
 * ⚡ Automatización de Capítulos: Permite extraer rangos completos de episodios (ej: del 1 al 12) de una sola vez.


# 🚀 Instalación y Uso
1. Clonar el repositorio
```
git clone https://github.com/S0ulx3/AniCli-Cast
cd AniCli-Cast
```

2. Dar permisos de ejecución
```
chmod +x AniCli.sh
```

3. Ejecutar
```
./AniCli.sh
```


> Nota: El script incluye un verificador de dependencias automático. Si te falta alguna herramienta (mpv, pup, fzf, etc.), el script te ofrecerá instalarla por ti (compatible con apt, pacman y dnf).

---

# ⭐ Características principales

---

# 🛠️ Dependencias Necesarias
Para un funcionamiento óptimo, el script utiliza:
 * mpv: El reproductor de video principal.
 * fzf: Para los menús interactivos y búsquedas.
 * pup: Para procesar el HTML de las webs de forma ultra rápida.
 * yt-dlp: Para gestionar el streaming de los servidores.
 * curl/wget: Para la descarga de datos.


# 📂 Estructura del Proyecto
Una vez en uso, el script organiza tus datos así:
 * ./series/: Almacena los archivos de enlaces de tus series.
 * ./peliculas/: Almacena los archivos de enlaces de películas.
 * ./watch_later/: Guarda los archivos de posición (.pos) de cada título.
 * favoritos.txt: Tu lista personalizada de favoritos.

# 🤝 Contribuciones
¿Tienes una idea para mejorar el scraping o añadir un servidor? ¡Las pull requests son bienvenidas!
 * Haz un Fork del proyecto.
 * Crea tu rama de función (git checkout -b feature/MejoraIncreible).
 * Haz commit de tus cambios (git commit -m 'Añadida mejora X').
 * Haz Push a la rama (git push origin feature/MejoraIncreible).
 * Abre un Pull Request.


# ⚠️ Descargo de Responsabilidad
Este script ha sido creado con fines educativos y de conveniencia personal. Todo el contenido es scrapeado de sitios públicos de terceros. No me hago responsable del uso que se le dé a esta herramienta.

> Desarrollado con 💻 por S0ulx3

