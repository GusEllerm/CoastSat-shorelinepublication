#!/usr/bin/env python3
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
REQUIRED_FILES = [
    "LICENSE",
    "README.md",
    "CITATION.cff",
    "codemeta.json",
    ".zenodo.json",
    "ro-crate-metadata.json",
    "scripts/generate_ro_crate.py",
]

EXPECTED_TITLE = "CoastSat shoreline LivePublication"
EXPECTED_ORCID = "0000-0001-8260-231X"
LICENSE_ID = "CC-BY-4.0"
LICENSE_URL = "https://creativecommons.org/licenses/by/4.0/"


def load_json(path: Path):
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def load_yaml(path: Path):
    try:
        import yaml  # type: ignore
    except Exception as exc:  # pragma: no cover - dependency check
        raise RuntimeError(
            "PyYAML is required for CITATION.cff validation. Install with `pip install pyyaml`."
        ) from exc
    with path.open("r", encoding="utf-8") as handle:
        return yaml.safe_load(handle)


def ro_crate_entity(graph, entity_id):
    for entity in graph:
        if entity.get("@id") == entity_id:
            return entity
    return None


def normalize_orcid(value: str) -> str:
    return value.replace("https://orcid.org/", "").strip()


def check_contains_ellipsis(value: str) -> bool:
    return "..." in value


def main() -> int:
    results = []

    def report(label: str, ok: bool, detail: str = "") -> None:
        icon = "✅" if ok else "❌"
        message = f"{icon} {label}"
        if detail:
            message += f" - {detail}"
        results.append((ok, message))

    for filename in REQUIRED_FILES:
        path = REPO_ROOT / filename
        report(f"exists: {filename}", path.exists())

    missing = [ok for ok, _ in results if not ok]
    if missing:
        for _, message in results:
            print(message)
        return 1

    try:
        citation = load_yaml(REPO_ROOT / "CITATION.cff")
        report("parse: CITATION.cff", True)
    except Exception as exc:
        report("parse: CITATION.cff", False, str(exc))
        citation = {}

    try:
        codemeta = load_json(REPO_ROOT / "codemeta.json")
        report("parse: codemeta.json", True)
    except Exception as exc:
        report("parse: codemeta.json", False, str(exc))
        codemeta = {}

    try:
        zenodo = load_json(REPO_ROOT / ".zenodo.json")
        report("parse: .zenodo.json", True)
    except Exception as exc:
        report("parse: .zenodo.json", False, str(exc))
        zenodo = {}

    try:
        ro_crate = load_json(REPO_ROOT / "ro-crate-metadata.json")
        report("parse: ro-crate-metadata.json", True)
    except Exception as exc:
        report("parse: ro-crate-metadata.json", False, str(exc))
        ro_crate = {}

    graph = ro_crate.get("@graph", []) if isinstance(ro_crate, dict) else []
    root_dataset = ro_crate_entity(graph, "./") if graph else None
    metadata_entity = ro_crate_entity(graph, "ro-crate-metadata.json") if graph else None

    report("ro-crate: root dataset", root_dataset is not None)
    conforms_to = None
    if metadata_entity:
        conforms_to = metadata_entity.get("conformsTo")
    conforms_ids = []
    if isinstance(conforms_to, list):
        conforms_ids = [entry.get("@id") for entry in conforms_to if isinstance(entry, dict)]
    elif isinstance(conforms_to, dict):
        conforms_ids = [conforms_to.get("@id")]
    report(
        "ro-crate: conformsTo 1.1",
        "https://w3id.org/ro/crate/1.1" in conforms_ids,
    )

    title_checks = [
        ("CITATION.cff title", citation.get("title")),
        ("codemeta name", codemeta.get("name")),
        ("zenodo title", zenodo.get("title")),
        ("ro-crate name", root_dataset.get("name") if root_dataset else None),
    ]
    for label, value in title_checks:
        report(label, value == EXPECTED_TITLE, f"{value!r}")

    license_checks = [
        ("CITATION.cff license", citation.get("license")),
        ("zenodo license", zenodo.get("license")),
        ("codemeta license", codemeta.get("license")),
        ("ro-crate license", root_dataset.get("license") if root_dataset else None),
    ]
    for label, value in license_checks:
        ok = value in (LICENSE_ID, LICENSE_URL)
        report(label, ok, f"{value!r}")

    orcid_checks = []
    citation_authors = citation.get("authors") or []
    if citation_authors:
        orcid = citation_authors[0].get("orcid", "")
        orcid_checks.append(("CITATION.cff ORCID", orcid))
    codemeta_author = (codemeta.get("author") or [{}])[0]
    if codemeta_author:
        orcid_checks.append(("codemeta ORCID", codemeta_author.get("@id", "")))
    zenodo_creators = zenodo.get("creators") or []
    if zenodo_creators:
        orcid_checks.append(("zenodo ORCID", zenodo_creators[0].get("orcid", "")))

    for label, value in orcid_checks:
        ok = normalize_orcid(str(value)) == EXPECTED_ORCID
        report(label, ok, f"{value!r}")

    description_checks = [
        ("CITATION.cff abstract", citation.get("abstract")),
        ("codemeta description", codemeta.get("description")),
        ("zenodo description", zenodo.get("description")),
        ("ro-crate description", root_dataset.get("description") if root_dataset else None),
    ]
    for label, value in description_checks:
        if isinstance(value, str):
            report(label, not check_contains_ellipsis(value))
        else:
            report(label, False, "missing or non-string")

    for _, message in results:
        print(message)

    return 0 if all(ok for ok, _ in results) else 1


if __name__ == "__main__":
    sys.exit(main())
