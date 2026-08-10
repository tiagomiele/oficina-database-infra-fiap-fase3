# Diagramas

| Arquivo | Papel |
|---|---|
| `er-model.mmd` | fonte versionada do modelo entidade-relacionamento, em Mermaid |
| `er-model.svg` | imagem renderizada usada em [`../data-model.md`](../data-model.md) |

A fonte reflete as migrations Flyway `V1`, `V2` e `V3` do repositório
[oficina-backend-fiap-fase3](https://github.com/tiagomiele/oficina-backend-fiap-fase3),
não um modelo idealizado. Ao mudar uma migration lá, atualize aqui a fonte, a imagem e
[`../data-model.md`](../data-model.md).

## Regerar a imagem

```bash
npx --yes @mermaid-js/mermaid-cli@11.4.2 \
  -i docs/diagrams/er-model.mmd \
  -o docs/diagrams/er-model.svg \
  -b transparent
```

A renderização **não** é byte a byte determinística: o Mermaid recalcula as curvas dos
relacionamentos a cada execução, então dois SVGs do mesmo `.mmd` diferem em alguns
bytes. Por isso o CI não regenera nem compara a imagem; ele valida a coerência do
conteúdo com `scripts/validate_docs.py`:

- toda entidade do `.mmd` está documentada em `data-model.md` e vice-versa;
- toda entidade do `.mmd` aparece no SVG versionado, o que detecta imagem desatualizada;
- todo link relativo da documentação existe.

Só faça commit do SVG quando o `.mmd` mudar, para evitar diffs de ruído.
