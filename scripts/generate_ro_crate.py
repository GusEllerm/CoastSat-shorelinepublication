#!/usr/bin/env python3
from pathlib import Path
from rocrate.rocrate import ROCrate
from rocrate.model.contextentity import ContextEntity
import tempfile
import shutil

REPO_ROOT = Path(__file__).resolve().parents[1]

NAME = "CoastSat shoreline LivePublication"
DESCRIPTION = (
    "Executable shoreline LivePublication for the CoastSat case study, combining "
    "narrative, RO-Crate packaging, and generated artefacts for reproducible publication."
)
LICENSE_URL = "https://creativecommons.org/licenses/by/4.0/"
VERSION = "shoreline-crate-2025-10-28_15-09-45"
REPO_URL = "https://github.com/GusEllerm/CoastSat-shorelinepublication"
AUTHOR = {
    "@type": "Person",
    "name": "Augustus Ellerm",
    "@id": "https://orcid.org/0000-0001-8260-231X",
}

KEY_FILES = [
    "README.md",
    "CITATION.cff",
    "codemeta.json",
    ".zenodo.json",
    "LICENSE",
    "src/templates/shoreline_publication.smd",
    "src/publication_logic.py",
    "scripts/publish_to_docs.sh",
    "scripts/create_publication.sh",
    "docs/shoreline_publication.smd",
    "docs/shorelinepublication.html",
    "docs/cached_shoreline.geojson",
    "docs/cached_primary_result.geojson",
]


def add_file_if_present(crate: ROCrate, relative_path: str) -> None:
    file_path = REPO_ROOT / relative_path
    if file_path.exists():
        crate.add_file(source=str(file_path), dest_path=relative_path)


def main() -> None:
    crate = ROCrate()
    root = crate.get("./")
    root["name"] = NAME
    root["description"] = DESCRIPTION
    root["license"] = LICENSE_URL
    root["version"] = VERSION
    root["url"] = REPO_URL
    root["author"] = crate.add(ContextEntity(crate, AUTHOR["@id"], AUTHOR))

    publication = crate.add(
        ContextEntity(
            crate,
            "#publication",
            {
                "@type": "CreativeWork",
                "name": NAME,
                "description": DESCRIPTION,
                "license": LICENSE_URL,
                "url": REPO_URL,
                "version": VERSION,
                "author": crate.add(ContextEntity(crate, AUTHOR["@id"], AUTHOR)),
            },
        )
    )
    root["mainEntity"] = publication

    conforms_to = crate.add(
        ContextEntity(
            crate,
            "https://w3id.org/ro/crate/1.1",
            {
                "@type": "CreativeWork",
                "name": "RO-Crate Metadata Specification 1.1",
            },
        )
    )
    crate.metadata["conformsTo"] = conforms_to

    for relative_path in KEY_FILES:
        add_file_if_present(crate, relative_path)

    with tempfile.TemporaryDirectory() as temp_dir:
        crate.write(temp_dir)
        metadata_path = Path(temp_dir) / "ro-crate-metadata.json"
        shutil.copy2(metadata_path, REPO_ROOT / "ro-crate-metadata.json")


if __name__ == "__main__":
    main()
