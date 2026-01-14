# CoastSat shoreline LivePublication [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.18250456.svg)](https://doi.org/10.5281/zenodo.18250456)

## What this is
This repository is a CoastSat shoreline LivePublication container: an executable, reproducible publication that combines narrative text, computational steps, and generated artefacts. It is designed as a publishable research object (Chapter 6 case study). The repository supports RO-Crate packaging and Stencila-based rendering to make the publication portable and inspectable.

## What it contains
- Narrative sources (Stencila Markdown) in `src/templates/shoreline_publication.smd` and generated instances in `docs/`.
- Build and render scripts in `src/` and `scripts/` for publication creation and GitHub Pages deployment.

## How to view / run
- Live preview: https://gusellerm.github.io/CoastSat-shorelinepublication/
- View this publication in its native environement within the CoastSat dashboard: https://coastsat.livepublication.org/
- Generate a publication locally:
  - `python src/publication_logic.py aus0001`
  - `python src/publication_logic.py aus0001 --populate-crate`

## Inputs & provenance
- interface.crate generation tool (Zenodo): https://doi.org/10.5281/zenodo.18250232

## How to cite
Use `CITATION.cff`. Zenodo DOI: https://doi.org/10.5281/zenodo.18250456

## License
CC BY 4.0 (see `LICENSE`).

