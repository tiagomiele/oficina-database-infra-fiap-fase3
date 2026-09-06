# Registros de decisão de arquitetura (ADR)

Decisões que afetam o banco de dados da oficina. Formato: contexto, decisão,
consequências e alternativas descartadas. Um ADR aceito não é reescrito: se a decisão
mudar, um novo ADR o substitui.

| ADR | Título | Status |
|---|---|---|
| [0001](0001-postgresql-gerenciado.md) | PostgreSQL gerenciado no Amazon RDS | Aceito |
| [0002](0002-modelagem-relacional.md) | Modelagem relacional normalizada com chaves naturais compostas | Aceito |
| [0003](0003-observabilidade-rds.md) | Observabilidade por logs do PostgreSQL no CloudWatch | Aceito |
| [0004](0004-limitacoes-aws-academy.md) | Restrições impostas pelo AWS Academy | Aceito |
| [0005](0005-separacao-de-ambientes.md) | Separação de ambientes por branch e workspace | Aceito |
| [0006](0006-backup-e-retencao.md) | Backup, retenção e proteção contra exclusão | Aceito |
| [0007](0007-controle-de-custo.md) | Controle de custo como padrão do repositório | Aceito |
| [0008](0008-cicd-com-gate-de-apply.md) | CI/CD com apply sempre bloqueado por gate | Aceito |
