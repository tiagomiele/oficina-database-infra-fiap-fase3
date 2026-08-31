# ADR 0008 — CI/CD automático por merge com gate de ambiente

- Status: Aceito
- Data: 2026-08-10

## Contexto

A fase exige um pipeline de validação e um caminho de deploy controlado por ambiente. O
risco no AWS Academy é o oposto do usual: não é deploy lento, é recurso criado sem
intenção consumindo crédito, ou pipeline que falha de forma confusa porque a credencial
temporária expirou.

## Decisão

Três workflows, com responsabilidades separadas:

1. **CI** (`ci.yml`), em todo Pull Request e push para `homolog`/`main`: validação
   estática e sem nuvem — documentação obrigatória, `terraform fmt`,
   `terraform init -backend=false`, `terraform validate`, verificação dos nomes de
   variável nos `*.tfvars.example`, coerência entre o diagrama ER e a documentação,
   TFLint, Trivy e Gitleaks. Nunca usa credencial AWS.
2. **Terraform plan** (`terraform-plan.yml`), manual, por ambiente, preservado para
   análise e recuperação sem apply.
3. **Terraform apply** (`terraform-apply.yml`), iniciado por push em `homolog` ou `main`:
   resolve o workspace, exige `ENABLE_TERRAFORM_APPLY=true`, aguarda os *required
   reviewers* do GitHub Environment, valida a sessão AWS, executa plan e então apply.
   Configuração ausente ou credencial expirada falha explicitamente.

O `workflow_dispatch` permanece para recuperação e destroy. Nesse caminho, o input
`confirm` precisa ser exatamente `APPLY-<ambiente>` ou `DESTROY-<ambiente>`. O Auto apply
do workspace HCP permanece desligado.

## Consequências

- o merge inicia a entrega automaticamente, mas não cria recurso sem aprovação do ambiente;
- credencial ausente ou expirada falha no primeiro passo, com mensagem explícita, em vez
  de quebrar no meio do Terraform;
- o CI é totalmente gratuito e roda sem segredo da AWS, então funciona mesmo com o
  laboratório desligado;
- quem executa o apply precisa de permissão no GitHub Environment, e a execução fica
  registrada com o aprovador.

## Alternativas descartadas

- **Apply somente manual**: não atende ao requisito de pipeline iniciado pelo merge.
- **Apply sem gate**: criaria recursos assim que a branch fosse atualizada.
- **Confirmação textual também no merge**: não há input interativo em eventos `push`; ela
  permanece no fluxo manual de recuperação e destroy.
- **`terraform plan` no CI de Pull Request**: exigiria credencial AWS válida em todo PR,
  que expira, tornando o CI vermelho sem relação com a mudança.
