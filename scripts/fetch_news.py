#!/usr/bin/env python3
"""
Descarga las noticias de las fuentes RSS listadas en sources.json
y genera data/news.json, que es lo que consume la página web.

Se ejecuta a mano con:
    python3 scripts/fetch_news.py

o automáticamente todos los días vía GitHub Actions
(ver .github/workflows/update-news.yml).

Si una fuente falla (el sitio está caído, cambió de URL, etc.) el
script no corta todo el proceso: la salta, avisa por consola, y
sigue con las demás. Así el portal nunca se queda sin noticias
por un solo sitio caído.
"""

import json
import sys
from datetime import datetime, timezone
from pathlib import Path

import feedparser

ROOT = Path(__file__).resolve().parent.parent
SOURCES_FILE = ROOT / "scripts" / "sources.json"
OUTPUT_FILE = ROOT / "data" / "news.json"

MAX_ITEMS_PER_SOURCE = 6
MAX_TOTAL_ITEMS = 40


def load_sources():
    with open(SOURCES_FILE, "r", encoding="utf-8") as f:
        return json.load(f)


def parse_date(entry):
    """Devuelve una fecha ISO 8601 a partir de lo que traiga el feed."""
    for key in ("published_parsed", "updated_parsed"):
        value = entry.get(key)
        if value:
            return datetime(*value[:6], tzinfo=timezone.utc).isoformat()
    return datetime.now(timezone.utc).isoformat()


def clean_summary(entry, max_chars=220):
    summary = entry.get("summary", "") or ""
    # Saca etiquetas HTML simples que traen muchos feeds
    import re

    text = re.sub("<[^<]+?>", "", summary).strip()
    if len(text) > max_chars:
        text = text[:max_chars].rsplit(" ", 1)[0] + "…"
    return text


def fetch_source(source):
    print(f"→ Descargando: {source['name']} ({source['feed_url']})")
    parsed = feedparser.parse(source["feed_url"])

    if parsed.bozo and not parsed.entries:
        raise RuntimeError(f"No se pudo leer el feed ({parsed.bozo_exception})")

    items = []
    for entry in parsed.entries[:MAX_ITEMS_PER_SOURCE]:
        items.append(
            {
                "source_id": source["id"],
                "source_name": source["name"],
                "category": source["category"],
                "title": entry.get("title", "Sin título").strip(),
                "link": entry.get("link", "").strip(),
                "summary": clean_summary(entry),
                "published": parse_date(entry),
            }
        )
    print(f"  ✓ {len(items)} noticias obtenidas")
    return items


def main():
    sources = load_sources()
    all_items = []
    failed_sources = []

    for source in sources:
        try:
            all_items.extend(fetch_source(source))
        except Exception as exc:  # noqa: BLE001 - queremos seguir aunque falle una fuente
            print(f"  ✗ Error en {source['name']}: {exc}")
            failed_sources.append({"id": source["id"], "name": source["name"], "error": str(exc)})

    # Ordena por fecha de publicación, más nuevas primero
    all_items.sort(key=lambda item: item["published"], reverse=True)
    all_items = all_items[:MAX_TOTAL_ITEMS]

    output = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "items": all_items,
        "failed_sources": failed_sources,
    }

    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(output, f, ensure_ascii=False, indent=2)

    print(f"\nListo: {len(all_items)} noticias guardadas en {OUTPUT_FILE}")
    if failed_sources:
        print(f"Atención: {len(failed_sources)} fuente(s) fallaron y se omitieron.")

    # No corta el workflow con error aunque una fuente haya fallado;
    # solo falla si TODAS las fuentes fallaron (ahí sí algo está mal).
    if not all_items and sources:
        print("Ninguna fuente devolvió noticias.", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
