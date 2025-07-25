

from rocrate.rocrate import ROCrate, ContextEntity, Dataset
from rocrate.model.person import Person
from pathlib import Path
import shutil

import subprocess
import requests
import zipfile
import os
import io
import re
import shutil
import hashlib

def add_research_article(crate):
    main_article = crate.add(ContextEntity(crate, "#research-article", properties={
        "@type": "ScholarlyArticle",
        "name": "LivePublication: A Dynamic and Reproducible Research Article",
        "description": "Headless publication.crate; does not contain a main article",
    }))

    # TODO: Add author, date, and other metadata

    return main_article

def add_eval_dnf(crate):
    evaluated_document = crate.add(ContextEntity(crate, "#dnf-evaluated-document", properties={
        "@type": ["CreativeWork", "SoftwareSourceCode"],
        "name": "Evaluated DNF Document",
        "description": "Headless publicatoion.crate; does not contain evaluated DNF document"
    }))
    return evaluated_document

def add_dnf_presentation(crate):
    dnf_presentation_env = crate.add(ContextEntity(crate, "#dnf-presentation-environment", properties={
        "@type": "CreativeWork",
        "name": "DNF Presentation Environment",
        "description": "Environment responsible for converting the evaluated DNF document into presentation formats."
    }))

    return dnf_presentation_env

def add_dnf_schema(crate):
    wrapper = crate.get("#stencila-schema")

    return wrapper

def add_dnf_engine(crate):
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

def add_dnf_deps(crate):
    repo_owner = "GusEllerm"
    repo_name = "CoastSat-interface.crate"
    download_dir = "publication.crate"

    api_url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/releases/latest"

    token_path = Path("token.txt")
    token = token_path.read_text().strip() if token_path.exists() else None

    headers = {
        "Accept": "application/vnd.github.v3+json",
        "User-Agent": "CoastSat-ShorelinePublication"
    }
    if token:
        headers["Authorization"] = f"token {token}"

    print("📦 Fetching latest interface.crate release...")
    
    try:
        response = requests.get(api_url, headers=headers)
        response.raise_for_status()
        release = response.json()

        asset = next((a for a in release["assets"] if a["name"].endswith(".zip")), None)
        if not asset:
            raise Exception("No zip asset found in the latest release.")

        print(f"⬇️ Downloading: {asset['name']}")
        zip_response = requests.get(asset["browser_download_url"], headers=headers)
        zip_response.raise_for_status()

        with zipfile.ZipFile(io.BytesIO(zip_response.content)) as z:
            z.extractall(download_dir)  # Extracts to current working directory  print(f"✅ Extracted to {download_dir}")

    except Exception as e:
        raise Exception(f"Failed to download and extract interface.crate: {e}")

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
    
    # TODO: Add a RO-Crate entity for this file
    
    return script_file

def create_publication_crate(crate_dir="publication.crate"):
    crate = ROCrate()
    crate.name = "Publication Crate"
    crate.description = "This crate contains the interface.crate and a Stencila DNF document for generating publications."
    creator = crate.add(Person(crate, "#creator", {"name": "Unknown Author"}))
    crate.creator = creator

    # Add relations
    dnf_document = add_dnf_doc(crate)
    dnf_engine = add_dnf_engine(crate)
    dnf_engine_spec = add_dnf_engine_spec(crate)
    dnf_data_dependencies = add_dnf_deps(crate)
    dnf_engine_schema = add_dnf_schema(crate)
    dnf_eval_doc = add_eval_dnf(crate)
    dnf_presentation_env = add_dnf_presentation(crate)
    research_article = add_research_article(crate)
    publication_logic = add_publication_logic(crate)
    narrative_zoning = add_narrative_zoning_script(crate)

    print(dnf_presentation_env)

    crate.mainEntity = research_article
    research_article["isBasedOn"] = [dnf_eval_doc, dnf_presentation_env]
    research_article["wasGeneratedBy"] = [dnf_presentation_env, publication_logic]

    dnf_eval_doc["isBasedOn"] = [dnf_document, dnf_data_dependencies, dnf_engine]
    dnf_presentation_env["isBasedOn"] = [dnf_engine]
    dnf_engine["isBasedOn"] = [dnf_engine_spec]

    dnf_document["conformsTo"] = dnf_engine_spec

    # Write to disk
    Path(crate_dir).mkdir(parents=True, exist_ok=True)
    crate.write(crate_dir)

    # Clean up temporary files in working directory
    working_dir_template = Path("shoreline_publication.smd")
    if working_dir_template.exists():
        working_dir_template.unlink()
    
    working_dir_logic = Path("publication_logic.py") 
    if working_dir_logic.exists():
        working_dir_logic.unlink()

    # Clean up the downloaded interface.crate directory
    if os.path.isdir("interface.crate"):
        shutil.rmtree("interface.crate")

    # Clean up narrative_zoning script if it exists
    narrative_script = Path("narrative_zoning.py")
    if narrative_script.exists():
        narrative_script.unlink()

if __name__ == "__main__":
    create_publication_crate()