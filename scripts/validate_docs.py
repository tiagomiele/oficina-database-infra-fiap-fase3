#!/usr/bin/env python3
"""Validação estática da documentação e do diagrama ER.

Roda sem rede e sem credenciais. Garante que:

- os documentos obrigatórios existem;
- as entidades do diagrama versionado, a documentação do modelo e a imagem
  renderizada descrevem exatamente o mesmo conjunto de tabelas;
- o índice de ADRs lista todos os ADRs presentes;
- todo link relativo em Markdown aponta para um arquivo existente.

A renderização do Mermaid não é byte a byte determinística (as curvas dos
relacionamentos variam entre execuções), por isso a imagem não é regerada aqui:
o que se valida é a coerência do conteúdo.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"

REQUIRED_DOCS = [
    ROOT / "README.md",
    DOCS / "architecture.md",
    DOCS / "data-model.md",
    DOCS / "index-review.md",
    DOCS / "observability.md",
    DOCS / "cost.md",
    DOCS / "aws-academy.md",
    DOCS / "hcp-terraform.md",
    DOCS / "validation.md",
    DOCS / "evidence-checklist.md",
    DOCS / "troubleshooting.md",
    DOCS / "repositories.md",
    DOCS / "adr" / "README.md",
    DOCS / "diagrams" / "er-model.mmd",
    DOCS / "diagrams" / "er-model.svg",
]

MERMAID_ENTITY = re.compile(r"^\s{4}([a-z_][a-z0-9_]*)\s*\{", re.MULTILINE)
DOC_TABLE = re.compile(r"^### `([a-z_][a-z0-9_]*)`", re.MULTILINE)
MARKDOWN_LINK = re.compile(r"\[[^\]]*\]\(([^)#\s]+)(?:#[^)]*)?\)")

errors: list[str] = []


def check_required_docs() -> None:
    for path in REQUIRED_DOCS:
        if not path.is_file():
            errors.append(f"documento obrigatório ausente: {path.relative_to(ROOT)}")


def check_er_model() -> None:
    mmd_path = DOCS / "diagrams" / "er-model.mmd"
    svg_path = DOCS / "diagrams" / "er-model.svg"
    doc_path = DOCS / "data-model.md"
    if not (mmd_path.is_file() and svg_path.is_file() and doc_path.is_file()):
        return

    diagram = set(MERMAID_ENTITY.findall(mmd_path.read_text(encoding="utf-8")))
    documented = set(DOC_TABLE.findall(doc_path.read_text(encoding="utf-8")))

    if not diagram:
        errors.append("nenhuma entidade encontrada em docs/diagrams/er-model.mmd")
        return

    for missing in sorted(diagram - documented):
        errors.append(f"entidade `{missing}` está no diagrama e não em docs/data-model.md")
    for missing in sorted(documented - diagram):
        errors.append(f"tabela `{missing}` está em docs/data-model.md e não no diagrama")

    svg = svg_path.read_text(encoding="utf-8", errors="ignore")
    for entity in sorted(diagram):
        if entity not in svg:
            errors.append(
                f"entidade `{entity}` não aparece em docs/diagrams/er-model.svg: "
                "regenere a imagem conforme docs/diagrams/README.md"
            )


def check_adr_index() -> None:
    index = DOCS / "adr" / "README.md"
    if not index.is_file():
        return
    listed = set(MARKDOWN_LINK.findall(index.read_text(encoding="utf-8")))
    present = {p.name for p in (DOCS / "adr").glob("[0-9]*.md")}
    for missing in sorted(present - listed):
        errors.append(f"ADR {missing} não está listado em docs/adr/README.md")
    for extra in sorted(listed - present):
        errors.append(f"docs/adr/README.md aponta para ADR inexistente: {extra}")


def check_relative_links() -> None:
    for markdown in sorted(ROOT.rglob("*.md")):
        if ".git" in markdown.parts:
            continue
        for target in MARKDOWN_LINK.findall(markdown.read_text(encoding="utf-8")):
            if "://" in target or target.startswith("mailto:"):
                continue
            resolved = (markdown.parent / target).resolve()
            if not resolved.exists():
                errors.append(
                    f"{markdown.relative_to(ROOT)}: link relativo quebrado -> {target}"
                )


def main() -> int:
    check_required_docs()
    check_er_model()
    check_adr_index()
    check_relative_links()

    if errors:
        for error in errors:
            print(f"::error::{error}")
        return 1

    print("Documentação e diagrama ER coerentes.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
