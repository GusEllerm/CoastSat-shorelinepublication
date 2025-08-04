

"""
Publication crate builder for CoastSat shoreline analysis data.

This module creates RO-Crate compliant publication crates that include:
- Dynamic narrative documents (Stencila SMD format)
- Interface.crate dependencies from GitHub releases
- Publication logic for dynamic content generation
- Narrative zoning analysis scripts
- Complete metadata and provenance tracking
"""

from rocrate.rocrate import ROCrate, ContextEntity, Dataset
from rocrate.model.person import Person
from pathlib import Path
import argparse
import hashlib
import io
import os
import re
import requests
import shutil
import subprocess
import zipfile

def add_research_article(crate):
    """Add the main research article entity to the crate."""
    main_article = crate.add(ContextEntity(crate, "#research-article", properties={
        "@type": "ScholarlyArticle",
        "name": "LivePublication: A Dynamic and Reproducible Research Article",
        "description": "Headless publication.crate; does not contain a main article",
    }))

    # TODO: Add author, date, and other metadata

    return main_article

def add_eval_dnf(crate):
    """Add evaluated DNF document placeholder entity."""
    evaluated_document = crate.add(ContextEntity(crate, "#dnf-evaluated-document", properties={
        "@type": ["CreativeWork", "SoftwareSourceCode"],
        "name": "Evaluated DNF Document",
        "description": "Headless publication.crate; does not contain evaluated DNF document"
    }))
    return evaluated_document

def add_dnf_presentation(crate):
    """Add DNF presentation environment entity."""
    dnf_presentation_env = crate.add(ContextEntity(crate, "#dnf-presentation-environment", properties={
        "@type": "CreativeWork",
        "name": "DNF Presentation Environment",
        "description": "Environment responsible for converting the evaluated DNF document into presentation formats."
    }))

    return dnf_presentation_env

def add_dnf_schema(crate):
    """Get the stencila schema entity that should already exist."""
    # Return the entity directly - it should be created by add_dnf_engine_spec
    entities = crate.get_entities()
    for entity in entities:
        if entity.id == "#stencila-schema":
            return entity
    
    # Fallback: create it if it doesn't exist
    return add_dnf_engine_spec(crate)

def add_dnf_engine(crate):
    """Add Stencila DNF engine software entity."""
    try:
        version_output = subprocess.check_output(["stencila", "--version"], text=True).strip()
    except Exception:
        version_output = "unknown"

    stencila_software = crate.add(ContextEntity(crate, "#stencila", properties={
        "@type": "SoftwareApplication",
        "name": "Stencila",
        "description": "The DNF Engine used to resolve the dynamic narrative.",
        "softwareVersion": version_output,
        "url": "https://github.com/stencila/stencila",
        "license": "https://www.apache.org/licenses/LICENSE-2.0",
        "howToUse": "https://github.com/stencila/stencila/blob/main/docs/reference/cli.md",
        "operatingSystem": "all"
    }))

    return stencila_software

def add_dnf_engine_spec(crate):
    """Add Stencila DNF engine specification entity."""
    try:
        version_output = subprocess.check_output(["stencila", "--version"], text=True).strip()
    except subprocess.CalledProcessError:
        version_output = "unknown"

    version_match = re.search(r"(\d+\.\d+\.\d+)", version_output)
    version_tag = f"v{version_match.group(1)}" if version_match else "main"

    stencila_spec = crate.add(ContextEntity(crate, "#stencila-schema", properties={
        "@type": "CreativeWork",
        "name": "Stencila DNF Engine Specification",
        "description": "Specification and JSON Schemas used by the Stencila DNF Engine to validate and interpret dynamic documents.",
        "url": f"https://github.com/stencila/stencila/tree/{version_tag}/schema",
        "license": "https://www.apache.org/licenses/LICENSE-2.0"
    }))

    return stencila_spec

def add_dnf_doc(crate):
    """Add the dynamic narrative document (SMD) template to the crate."""
    # Use the template from the new structure
    template_path = Path(__file__).parent / "templates" / "shoreline_publication.smd"
    sha256_hash = hashlib.sha256(open(template_path, "rb").read()).hexdigest() if template_path.exists() else ""
    
    # Copy template to current working directory for ROCrate to find it
    working_dir_template = Path("shoreline_publication.smd")
    shutil.copy(template_path, working_dir_template)
    
    # Also copy to the publication.crate directory
    crate_path = Path(crate.source) if crate.source else Path("publication.crate")
    crate_path.mkdir(parents=True, exist_ok=True)
    publication_template = crate_path / "shoreline_publication.smd"
    shutil.copy(template_path, publication_template)
    
    dnf_file = crate.add_file("shoreline_publication.smd", properties={
        "@type": ["File", "SoftwareSourceCode", "SoftwareApplication"],
        "name": "DNF Document File",
        "description": "The unresolved dynamic narrative document serving as input to the DNF Engine.",
        "encodingFormat": "application/smd",
        "sha256": sha256_hash
    })
    return dnf_file

def add_dnf_deps(crate, interface_crate_version="latest"):
    """
    Download and add interface.crate dependencies from GitHub releases.
    
    Args:
        crate: The ROCrate instance to add dependencies to
        interface_crate_version: Version to download ('latest' or specific tag)
    
    Returns:
        Dataset entity representing the nested interface.crate
    """
    repo_owner = "GusEllerm"
    repo_name = "CoastSat-interface.crate"
    download_dir = "publication.crate"

    # Determine API URL based on version
    if interface_crate_version == "latest":
        api_url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/releases/latest"
        print("📦 Fetching latest interface.crate release...")
    else:
        api_url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/releases/tags/{interface_crate_version}"
        print(f"📦 Fetching interface.crate release: {interface_crate_version}...")

    token_path = Path("token.txt")
    token = token_path.read_text().strip() if token_path.exists() else None

    headers = {
        "Accept": "application/vnd.github.v3+json",
        "User-Agent": "CoastSat-ShorelinePublication"
    }
    if token:
        headers["Authorization"] = f"token {token}"
    
    try:
        response = requests.get(api_url, headers=headers)
        response.raise_for_status()
        release = response.json()

        asset = next((a for a in release["assets"] if a["name"].endswith(".zip")), None)
        if not asset:
            if interface_crate_version == "latest":
                raise Exception("No zip asset found in the latest release.")
            else:
                raise Exception(f"No zip asset found in release {interface_crate_version}. Please check that the version exists and has a zip asset.")

        print(f"⬇️ Downloading: {asset['name']}")
        zip_response = requests.get(asset["browser_download_url"], headers=headers)
        zip_response.raise_for_status()

        with zipfile.ZipFile(io.BytesIO(zip_response.content)) as z:
            z.extractall(download_dir)  # Extracts to current working directory  print(f"✅ Extracted to {download_dir}")

    except requests.exceptions.HTTPError as e:
        if hasattr(e, 'response') and e.response.status_code == 404:
            if interface_crate_version == "latest":
                raise Exception("Latest release not found. The repository may not have any releases.")
            else:
                raise Exception(f"Release {interface_crate_version} not found. Please check that the version exists.")
        else:
            raise Exception(f"HTTP error occurred: {e}")
    except Exception as e:
        if "Failed to download and extract interface.crate" not in str(e):
            raise Exception(f"Failed to download and extract interface.crate: {e}")
        else:
            raise e

    if not os.path.isdir(download_dir):
        raise Exception(f"{download_dir} directory is missing after extraction.")

    nested = crate.add(Dataset(crate, download_dir + "/interface.crate/", properties={
        "name": "Interface Crate",
        "@type": ["RO-Crate", "Dataset"],
        "description": "Nested interface.crate containing Experiment Infrastructure execution data.",
        "license": "https://creativecommons.org/licenses/by/4.0/"
    }))

    return nested

def add_publication_logic(crate):
    """Add the publication logic Python script to the crate."""
    # Copy the publication logic to current working directory and crate directory
    logic_source = Path(__file__).parent / "publication_logic.py"
    
    # Copy to current working directory for ROCrate to find it
    working_dir_logic = Path("publication_logic.py")
    shutil.copy(logic_source, working_dir_logic)
    
    # Copy to the publication.crate directory
    crate_path = Path(crate.source) if crate.source else Path("publication.crate")
    crate_path.mkdir(parents=True, exist_ok=True)
    crate_logic_path = crate_path / "publication_logic.py"
    shutil.copy(logic_source, crate_logic_path)
    
    logic_file = crate.add_file("publication_logic.py", properties={
        "@type": ["File", "SoftwareSourceCode"],
        "name": "Publication Logic",
        "description": "Python logic for generating publications from the DNF document.",
        "encodingFormat": "text/x-python",
        "sha256": hashlib.sha256(open(logic_source, "rb").read()).hexdigest()
    })
    return logic_file

def add_narrative_zoning_script(crate):
    """Add the narrative zoning analysis script to the crate."""
    script_source = Path("src/narrative_zoning.py")
    if not script_source.exists():
        raise FileNotFoundError(f"Narrative zoning script not found: {script_source}")
    
    # Copy the script to the crate directory
    crate_path = Path(crate.root_dataset.id)
    narrative_script = crate_path / "narrative_zoning.py"
    shutil.copy(script_source, narrative_script)
    
    # Calculate SHA256 hash
    sha256_hash = hashlib.sha256(open(script_source, "rb").read()).hexdigest()
    
    # Add to crate
    script_file = crate.add_file("narrative_zoning.py", properties={
        "@type": ["File", "SoftwareSourceCode", "SoftwareApplication"],
        "name": "Narrative Zoning Analysis Script",
        "description": "Python script for analyzing shoreline transects and identifying narrative zones with similar characteristics.",
        "encodingFormat": "text/x-python",
        "programmingLanguage": "Python",
        "sha256": sha256_hash,
        "applicationCategory": "Data Analysis",
        "keywords": ["shoreline", "coastal", "narrative", "zoning", "transects", "analysis"]
    })
    
    return script_file

def create_publication_crate(crate_dir="publication.crate", interface_crate_version="latest"):
    """
    Create a complete publication crate with all necessary components.
    
    Args:
        crate_dir: Directory to create the publication crate in
        interface_crate_version: Version of interface.crate to download
    
    Returns:
        None (writes crate to disk)
    """
    crate = ROCrate()
    crate.name = "Publication Crate"
    crate.description = "This crate contains the interface.crate and a Stencila DNF document for generating publications."
    creator = crate.add(Person(crate, "#creator", {"name": "Unknown Author"}))
    crate.creator = creator

    # Add all entities to the crate
    dnf_document = add_dnf_doc(crate)
    dnf_engine = add_dnf_engine(crate)
    dnf_engine_spec = add_dnf_engine_spec(crate)
    dnf_data_dependencies = add_dnf_deps(crate, interface_crate_version)
    dnf_engine_schema = add_dnf_schema(crate)
    dnf_eval_doc = add_eval_dnf(crate)
    dnf_presentation_env = add_dnf_presentation(crate)
    research_article = add_research_article(crate)
    publication_logic = add_publication_logic(crate)
    narrative_zoning = add_narrative_zoning_script(crate)

    crate.mainEntity = research_article
    
    # Set relationships between entities
    # Note: Using type: ignore because static analysis incorrectly infers tuple types
    research_article["isBasedOn"] = [dnf_eval_doc, dnf_presentation_env]  # type: ignore
    research_article["wasGeneratedBy"] = [dnf_presentation_env, publication_logic]  # type: ignore

    dnf_eval_doc["isBasedOn"] = [dnf_document, dnf_data_dependencies, dnf_engine]  # type: ignore
    dnf_presentation_env["isBasedOn"] = [dnf_engine]  # type: ignore
    dnf_engine["isBasedOn"] = [dnf_engine_spec]  # type: ignore
    
    # Publication logic depends on narrative zoning for analysis
    publication_logic["isBasedOn"] = [narrative_zoning]  # type: ignore

    dnf_document["conformsTo"] = dnf_engine_spec  # type: ignore

    # Write to disk
    Path(crate_dir).mkdir(parents=True, exist_ok=True)
    crate.write(crate_dir)

    # Clean up temporary files in working directory
    _cleanup_temporary_files()

    # Clean up the downloaded interface.crate directory
    if os.path.isdir("interface.crate"):
        shutil.rmtree("interface.crate")


def _cleanup_temporary_files():
    """Clean up temporary files created during crate building."""
    temp_files = [
        "shoreline_publication.smd",
        "publication_logic.py", 
        "narrative_zoning.py"
    ]
    
    for file_path in temp_files:
        path = Path(file_path)
        if path.exists():
            path.unlink()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Create a publication crate with optional custom interface.crate version")
    parser.add_argument(
        "--interface-crate", "-i",
        default="latest",
        help="Specify interface.crate version (e.g., v1.0.0, v2.1.3, or 'latest' for latest release)"
    )
    
    args = parser.parse_args()
    
    create_publication_crate(interface_crate_version=args.interface_crate)