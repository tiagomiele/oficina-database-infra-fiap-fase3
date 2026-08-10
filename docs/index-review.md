# Revisão estática de índices e consultas

Revisão feita sobre as migrations `V1`, `V2` e `V3` e sobre os repositórios de
persistência do backend, sem executar `EXPLAIN` em banco real. Nenhuma migration é
criada neste repositório: alterações de schema pertencem ao Flyway do backend.

## Consultas mapeadas

| Consulta | Origem | Predicado | Índice usado hoje | Situação |
|---|---|---|---|---|
| login por CPF | Lambda de autenticação | `documento_normalizado = ?` (`tipo_documento='CPF' AND ativo`) | `ux_clientes_documento_normalizado` e `idx_clientes_cpf_ativo` | adequado |
| `findByDocumento` / `existsByDocumento` | `SpringDataClienteRepository` | `documento = ?` | unique de `documento` | adequado |
| veículos do cliente | `SpringDataVeiculoRepository.findByIdCliente` | `id_cliente = ?` | `idx_veiculos_cliente` | adequado |
| OS ativa por cliente | `existeOsAtivaPorCliente` | `id_cliente = ? AND status IN (5 status ativos)` | `idx_os_cliente` | melhorável |
| OS ativa por veículo | `existeOsAtivaPorVeiculo` | `id_placa = ? AND id_cliente = ? AND status IN (...)` | `idx_os_cliente` | melhorável |
| OS ativa por serviço/SKU | `existeOsAtivaPorServicoSku` | `i.id_servico_sku = ? AND i.tipo_item = ? AND i.status <> 'CANCELADO'` + join com OS ativa | nenhum (`Seq Scan` em `orcamentos_itens_ordem_servico`) | **falta índice** |
| etapa aberta da OS | `findFirstByIdOrdemServicoAndSaidaEmIsNullOrderByEntradaEmDesc` | `id_ordem_servico = ? AND saida_em IS NULL` | `ux_historico_os_status_aberto` (único parcial) | adequado |
| histórico da OS | `findByIdOrdemServicoOrderByEntradaEmAsc` | `id_ordem_servico = ?` ordenado por `entrada_em` | `idx_historico_os_entrada` | adequado |
| tempo médio de execução | `JpaRelatorioRepository.tempoMedioPorOs` | `inicio_execucao IS NOT NULL AND fim_execucao IS NOT NULL` ordenado por `fim_execucao` | nenhum (`Seq Scan` em `ordens_servico`) | aceitável hoje, ver abaixo |
| lançamentos por tipo | `findByTipoOrderByDataLancamentoDesc` | `tipo = ?` ordenado por `data_lancamento DESC` | `idx_cc_tipo` | melhorável |
| lançamento por NF | `findByNumeroNotaAndSerieNotaAndCnpjFornecedorAndDataEmissao` | 4 colunas de correlação | nenhum | **falta índice** |
| numerador da OS | `SpringDataNumeroOSSequenciaRepository` | `mes = ? AND ano = ?` com `FOR UPDATE` | PK composta | adequado |
| itens do orçamento atual | `orcamentos_itens_ordem_servico` por OS e orçamento | `id_ordem_servico = ? AND id_orcamento = ?` | `idx_itens_orc_os` | adequado |
| movimentação por SKU / por OS | `movimentacao_estoque_pecas` | `id_sku = ?`, `id_ordem_servico = ?` | `idx_mov_estoque_sku`, `idx_mov_estoque_os` | adequado |

## Índices recomendados — exigem migration no backend

Os itens abaixo **não** são criados aqui. Precisam de uma migration Flyway
(`V4__indices_de_consulta.sql` ou equivalente) no repositório
`oficina-backend-fiap-fase3`.

1. `orcamentos_itens_ordem_servico (id_servico_sku, tipo_item)` — hoje a verificação
   de vínculo ativo de serviço ou peça varre a tabela inteira antes do join. É a
   consulta com pior perfil do modelo atual, e roda a cada tentativa de inativar
   serviço ou peça.

   ```sql
   CREATE INDEX idx_itens_orc_servico_sku
     ON orcamentos_itens_ordem_servico (id_servico_sku, tipo_item);
   ```

2. `conta_corrente_oficina (numero_nota, serie_nota, cnpj_fornecedor, data_emissao)` —
   busca do lançamento de uma NF específica, usada no estorno.

   ```sql
   CREATE INDEX idx_cc_nota_fornecedor
     ON conta_corrente_oficina (numero_nota, serie_nota, cnpj_fornecedor, data_emissao);
   ```

3. `conta_corrente_oficina (tipo, data_lancamento DESC)` — substitui `idx_cc_tipo` na
   listagem ordenada por data, eliminando o `Sort` posterior.

   ```sql
   CREATE INDEX idx_cc_tipo_data ON conta_corrente_oficina (tipo, data_lancamento DESC);
   ```

4. `ordens_servico (id_cliente, status)` e `ordens_servico (id_placa, id_cliente, status)`
   — tornam as verificações de OS ativa cobertas pelo índice. Ganho moderado enquanto o
   volume é baixo; recomendável quando a listagem operacional crescer.

5. `ordens_servico (fim_execucao)` parcial, para o relatório de tempo médio:

   ```sql
   CREATE INDEX idx_os_execucao_concluida
     ON ordens_servico (fim_execucao)
     WHERE inicio_execucao IS NOT NULL AND fim_execucao IS NOT NULL;
   ```

## Índices que não devem ser criados

- `conta_corrente_oficina (origem)` (`idx_cc_origem`) tem baixa seletividade: apenas
  dois valores possíveis. Já existe e não vale ampliar.
- `movimentacao_estoque_pecas` não precisa de índice por `origem` pelo mesmo motivo.
- `itens_nota_fiscal_fornecedor` não precisa de índice extra: o prefixo da PK composta
  já cobre a busca por nota.
- Nenhum índice sobre `documento` sem normalização: a autenticação usa somente
  `documento_normalizado`.

## Como validar em ambiente real

Com o banco no ar e a sessão do Learner Lab ativa, dentro da VPC:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*) FROM orcamentos_itens_ordem_servico i
  JOIN ordens_servico o ON o.id_ordem_servico = i.id_ordem_servico
 WHERE i.id_servico_sku = 1 AND i.tipo_item = 'SERVICO'
   AND i.status <> 'CANCELADO'
   AND o.status IN ('RECEBIDA','EM_DIAGNOSTICO','AGUARDANDO_APROVACAO',
                    'EM_EXECUCAO','AGUARDANDO_PAGAMENTO');
```

Consultas com duração acima de `log_min_duration_statement_ms` aparecem no CloudWatch
Logs, sem os parâmetros de bind. Ver [`observability.md`](observability.md).
