# Eco Celestial — sitio web de la radio

Sitio con streaming en vivo y un portal de noticias que se actualiza
solo, todos los días, tomando fuentes oficiales de Argentina por RSS.

## Qué incluye

- `index.html`, `css/style.css`, `js/app.js` → el sitio en sí (reproductor + noticias).
- `data/news.json` → las noticias que muestra la página. Ahora mismo tiene datos de ejemplo.
- `scripts/sources.json` → la lista de fuentes RSS. Acá se agregan o sacan fuentes.
- `scripts/fetch_news.py` → el script que descarga las noticias y regenera `data/news.json`.
- `.github/workflows/update-news.yml` → la automatización: corre el script todos los días y publica el sitio en GitHub Pages.

## 0. Opción rápida: script automático

Si tenés `git` instalado (y opcionalmente `gh`, GitHub CLI), corré
esto desde adentro de esta carpeta, en tu PC:
```bash
bash deploy.sh
```
Te va a pedir tu usuario de GitHub y el nombre del repo, y hace el
resto solo. Si tenés `gh` instalado y logueado, automatiza también
la creación del repo y la activación de GitHub Pages. Si no,
te indica un único paso manual de 30 segundos en la web de GitHub.

Si preferís hacerlo a mano paso a paso, seguí desde el punto 1.

## 1. Subir el proyecto a GitHub

1. Creá un repositorio nuevo en GitHub (por ejemplo `eco-celestial`).
2. Desde la carpeta del proyecto, en la terminal:
   ```bash
   git init
   git add .
   git commit -m "Primera versión del sitio"
   git branch -M main
   git remote add origin https://github.com/TU_USUARIO/eco-celestial.git
   git push -u origin main
   ```
   (También podés hacer todo esto desde Visual Studio Code, con el panel de "Source Control".)

## 2. Activar GitHub Pages

1. En el repositorio, andá a **Settings → Pages**.
2. En "Build and deployment", elegí **Source: GitHub Actions**.
3. Listo — el workflow (`update-news.yml`) ya se encarga de publicar el sitio.

La primera vez que se ejecute el workflow (podés forzarlo desde la
pestaña **Actions → Actualizar noticias y publicar sitio → Run
workflow**), el sitio queda publicado en:
```
https://TU_USUARIO.github.io/eco-celestial/
```

## 3. Cómo funciona la automatización de noticias

Todos los días a las 09:00 (hora Argentina), GitHub ejecuta
automáticamente `scripts/fetch_news.py`, que:

1. Lee la lista de fuentes en `scripts/sources.json`.
2. Descarga las últimas noticias de cada una (por RSS).
3. Genera `data/news.json` con todo junto, ordenado por fecha.
4. Si algo cambió, lo guarda (commit) y GitHub Pages republica el sitio solo.

Si una fuente falla un día (el sitio está caído, cambió de dirección,
etc.) el script la salta y sigue con las demás — nunca se cae todo el
portal por una sola fuente.

### Agregar o cambiar fuentes de noticias

Editá `scripts/sources.json`. Cada fuente necesita:
```json
{
  "id": "un-nombre-corto",
  "name": "Nombre que se muestra en la web",
  "category": "Provincia | Nación | Regional (o la que quieras)",
  "feed_url": "URL del RSS del sitio"
}
```
Las fuentes que vienen cargadas por defecto:

| Fuente | Categoría |
|---|---|
| Gobierno del Chaco | Provincia |
| Agencia I+D+i (Ministerio de Ciencia) | Nación |
| Página/12 | Nación |
| Río Negro | Regional |
| El Día (La Plata) | Regional |

Podés sumar cualquier sitio que tenga RSS (buscá "rss" en el pie de
página del sitio que te interese, o probá `elsitio.com/feed` o
`elsitio.com/rss`). Cuantas más fuentes agregues, más completo el
portal — no hay límite técnico, solo edita la lista.

### Probar el script en tu computadora (opcional)

```bash
pip install -r requirements.txt
python3 scripts/fetch_news.py
```
Esto regenera `data/news.json` localmente, así podés ver los cambios
antes de subirlos.

## 4. El streaming de audio

El reproductor apunta a la URL pública de Zeno.fm
(`https://stream.zeno.fm/0gy32euz4rhvv`), configurada en `index.html`
dentro de la etiqueta `<audio>`. Si en algún momento cambiás de
proveedor de streaming, solo hay que reemplazar esa URL.

## 5. Para presentar en la municipalidad

Sugerencias para la presentación:
- Reemplazá la programación de ejemplo (`index.html`, sección
  "Programación") por la grilla real.
- Sumá un logo propio (hoy el sitio usa solo tipografía).
- Si querés, agregá alguna fuente de noticias específica de tu
  localidad (Presidencia Roque Sáenz Peña) si tiene RSS propio —
  reforzaría el vínculo con la municipalidad.
