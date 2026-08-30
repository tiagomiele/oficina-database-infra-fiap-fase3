# ADR 0005 — Separação de ambientes por branch e workspace

- Status: Aceito
- Data: 2026-08-10

## Contexto

A fase exige homologação e produção separados, com o mesmo código de infraestrutura, sem
que um apply em homologação toque no banco de produção. O state precisa viver fora do
laboratório.

## Decisão

Um ambiente por branch, por workspace do HCP Terraform e por GitHub Environment:

| Branch | `environment` | Workspace HCP | GitHub Environment |
|---|---|---|---|
| `homolog` | `homolog` | `oficina-database-homolog` | `homolog` |
| `main` | `production` | `oficina-database-production` | `production` |

Consequências diretas na configuração: todos os nomes de recurso derivam de
`local.name = "${var.project_name}-${var.environment}"`, o que impede colisão de nomes
entre ambientes na mesma conta; a variável `environment` é validada contra
`["homolog", "production"]`; e os valores de rede e senha são variáveis do workspace, não
arquivos versionados.

Fluxo: toda mudança entra por Pull Request em `homolog`, é validada pelo CI, recebe
`plan` manual e só depois é promovida para `main`. `main` nunca recebe push direto.

## Consequências

- dois states independentes, portanto dois bancos independentes, com credenciais
  distintas;
- `production` é mais conservador que `homolog`: Multi-AZ, proteção contra exclusão,
  snapshot final e retenções maiores, conforme [`0007`](0007-controle-de-custo.md);
- promover para produção é um segundo `plan` e um segundo gate, nunca uma cópia de
  state;
- o perfil descartável do AWS Academy é um override explícito para demonstração e não
  altera o perfil versionado de produção;
- os arquivos `environments/*.tfvars.example` documentam os dois ambientes, mas o
  valor real vive no workspace: `*.tfvars` está no `.gitignore`.

## Alternativas descartadas

- **Terraform workspaces locais (`terraform workspace new`)**: state no mesmo backend e
  fácil de aplicar no ambiente errado.
- **Diretório por ambiente com código duplicado**: divergência garantida entre homolog e
  produção.
- **Uma conta AWS por ambiente**: impossível no Learner Lab.
