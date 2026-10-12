#!/usr/bin/env python3
"""Build honda-hrv-ru1.yaml from the HR-V maintenance XLSX (Honda RU1)."""
from __future__ import annotations

import json
import re
import sys
import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_XLSX = Path.home() / "Downloads" / "HR-V.xlsx"
OUT = ROOT / "cms" / "fixtures" / "data" / "honda-hrv-ru1.json"

NS = {"m": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
MILESTONE_COLS = list("EFGHIJKLMNO")
MILESTONE_KM = [15_000, 30_000, 45_000, 60_000, 75_000, 90_000, 105_000, 120_000, 135_000, 150_000, 165_000]
MILESTONE_MONTHS = [12, 24, 36, 48, 60, 72, 84, 96, 108, 120, 132]
COL_KM = dict(zip(MILESTONE_COLS, MILESTONE_KM))
COL_MO = dict(zip(MILESTONE_COLS, MILESTONE_MONTHS))

CVT_TITLE = "Заміна трансмісійної рідини CVT (Безступенева трансміссія, варіатор)"
MKPP_TITLE = "Заміна трансмісійної рідини МКПП (механічна трансміссія)"
LABOR_RATE_UAH = 950  # орієнтовна нормо-година СТО (без запчастин)


def estimate_labor_price_uah(title: str, category: str) -> int:
    t = title.lower()
    if "моторної оливи" in t and "заміна" in t:
        return 950
    if "фільтра оливи" in t:
        return 480
    if "повітряного фільтра" in t and "заміна" in t:
        return 620
    if "паливного фільтра" in t:
        return 1180
    if "свічок запалювання" in t and "заміна" in t:
        return 2100
    if "cvt" in t:
        return 3200
    if "мкпп" in t:
        return 1850
    if "гальмівної рідини" in t:
        return 1100
    if "охолоджуючої рідини" in t:
        return 1650
    if "hds" in t:
        return 850
    if "ротація коліс" in t:
        return 420
    if "пилового фільтра салону" in t:
        return 380
    if category == "control":
        return int(LABOR_RATE_UAH * 0.45)
    return int(LABOR_RATE_UAH * 0.6)


def slugify(title: str) -> str:
    base = title.lower()
    base = re.sub(r"[^a-z0-9а-яіїєґ]+", "-", base, flags=re.I)
    base = re.sub(r"-+", "-", base).strip("-")
    return ("hrv-ru1-" + base[:48]).rstrip("-")


def load_grid(path: Path) -> dict[tuple[int, str], str]:
    with zipfile.ZipFile(path) as z:
        ss_root = ET.fromstring(z.read("xl/sharedStrings.xml"))
        strings = [
            "".join((t.text or "") for t in si.findall(".//m:t", NS))
            for si in ss_root.findall("m:si", NS)
        ]
        sheet = ET.fromstring(z.read("xl/worksheets/sheet1.xml"))
        grid: dict[tuple[int, str], str] = {}
        for row in sheet.findall("m:sheetData/m:row", NS):
            for c in row.findall("m:c", NS):
                ref = c.get("r", "")
                m = re.match(r"([A-Z]+)(\d+)", ref)
                if not m:
                    continue
                col, row_num = m.group(1), int(m.group(2))
                v = c.find("m:v", NS)
                if v is None:
                    continue
                if c.get("t") == "s":
                    grid[(row_num, col)] = strings[int(v.text)]
                else:
                    grid[(row_num, col)] = v.text
    return grid


def infer_interval(due_km: list[int], due_mo: list[int]) -> tuple[int | None, int | None]:
    km = mo = None
    if len(due_km) >= 2:
        steps = [due_km[i + 1] - due_km[i] for i in range(len(due_km) - 1)]
        km = steps[0] if all(s == steps[0] for s in steps) else min(steps)
    elif len(due_km) == 1:
        km = due_km[0]
    if len(due_mo) >= 2:
        steps = [due_mo[i + 1] - due_mo[i] for i in range(len(due_mo) - 1)]
        mo = steps[0] if all(s == steps[0] for s in steps) else min(steps)
    elif len(due_mo) == 1:
        mo = due_mo[0]
    return km, mo


def parse_xlsx(path: Path) -> dict:
    grid = load_grid(path)
    procedures: list[dict] = []
    informational: list[dict] = []
    current_title: str | None = None
    section = "operations"
    code_counts: dict[str, int] = {}

    def next_code(title: str) -> str:
        base = slugify(title)
        code_counts[base] = code_counts.get(base, 0) + 1
        if code_counts[base] > 1:
            return f"{base}-{code_counts[base]}"
        return base

    for r in range(6, 47):
        a = grid.get((r, "A"))
        if a:
            t = str(a).strip()
            if t.startswith("Контрольні"):
                section = "control"
                current_title = None
                continue
            if t.startswith("Додаткові"):
                section = "extra"
                current_title = None
                continue
            if t.startswith("Тривалість"):
                break
            current_title = t
        if not current_title:
            continue

        note_parts = [
            str(grid.get((r, c))).strip()
            for c in "BCD"
            if grid.get((r, c)) and "•" not in str(grid.get((r, c)))
        ]
        notes = " ".join(note_parts) if note_parts else None

        due_km = [COL_KM[c] for c in MILESTONE_COLS if grid.get((r, c)) == "•"]
        due_mo = [COL_MO[c] for c in MILESTONE_COLS if grid.get((r, c)) == "•"]

        if due_km:
            ik, im = infer_interval(due_km, due_mo)
            procedures.append(
                {
                    "code": next_code(current_title),
                    "title_uk": current_title,
                    "category": section,
                    "description_uk": notes,
                    "interval_km": ik,
                    "interval_months": im,
                    "labor_price_uah": estimate_labor_price_uah(current_title, section),
                    "templates": {
                        "cvt": current_title != MKPP_TITLE,
                        "mkpp": current_title != CVT_TITLE,
                    },
                }
            )
        elif notes and not due_km and r > 6:
            informational.append({"title_uk": current_title, "note_uk": notes})

    footnotes = []
    for r in (51, 53):
        a = grid.get((r, "A"))
        if a:
            footnotes.append(str(a).strip())

    return {
        "source": "HR-V.xlsx — Регламент технічного обслуговування HR-V (моделі RU1)",
        "catalog": {
            "brand": {"slug": "honda", "name": "Honda"},
            "model": {"slug": "hr-v", "name": "HR-V"},
            "generation": {
                "slug": "ru1",
                "name": "RU1",
                "year_from": 2015,
                "year_to": 2022,
                "notes_uk": "Модельний ряд RU1 згідно регламенту Honda.",
            },
            "configurations": [
                {
                    "slug": "cvt",
                    "engine_label": "1.8 i-VTEC",
                    "transmission_label": "CVT",
                    "drivetrain_label": "2WD",
                    "template_key": "cvt",
                },
                {
                    "slug": "mkpp",
                    "engine_label": "1.5 VTEC Turbo",
                    "transmission_label": "МКПП",
                    "drivetrain_label": "2WD",
                    "template_key": "mkpp",
                },
            ],
        },
        "templates": {
            "cvt": {
                "name_uk": "HR-V RU1 — CVT (звичайні умови)",
                "notes_uk": "\n\n".join(footnotes),
            },
            "mkpp": {
                "name_uk": "HR-V RU1 — МКПП (звичайні умови)",
                "notes_uk": "\n\n".join(footnotes),
            },
        },
        "procedures": procedures,
        "informational_notes": informational,
        "service_milestones_km": MILESTONE_KM,
        "service_milestones_months": MILESTONE_MONTHS,
    }


def main() -> int:
    xlsx = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_XLSX
    if not xlsx.is_file():
        print(f"Missing XLSX: {xlsx}", file=sys.stderr)
        return 1
    data = parse_xlsx(xlsx)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    # YAML without PyYAML: emit JSON (Symfony yaml component can load JSON too) — use JSON for simplicity
    OUT.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {OUT} ({len(data['procedures'])} procedures)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
