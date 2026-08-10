# ADR 0002 — Modelagem relacional normalizada com chaves naturais compostas

- Status: Aceito
- Data: 2026-08-10

## Contexto

O modelo real, descrito em [`../data-model.md`](../data-model.md), mistura chaves
surrogate e chaves naturais compostas, e mantém algumas correlações sem chave
estrangeira. Isso precisa ser explicado, porque parece inconsistente à primeira vista.

## Decisão

Manter o modelo em terceira forma normal, com três padrões deliberados:

1. **Chave surrogate** (`BIGSERIAL`/`UUID`) onde não existe chave natural estável:
   `users`, `clientes`, `servicos`, `pecas`, `movimentacao_estoque_pecas`,
   `historico_status_ordem_servico` e `conta_corrente_oficina`.
2. **Chave natural composta** onde o identificador é do negócio e a duplicidade precisa
   ser impossível: `veiculos (id_placa, id_cliente)`,
   `notas_fiscais_fornecedor (numero_nota, serie_nota, cnpj_fornecedor, data_emissao)`,
   `orcamentos_itens_ordem_servico (id_ordem_servico, id_orcamento, id_orcamento_item)`
   e `numero_os_sequencia (mes, ano)`. A OS usa identificador textual de negócio
   (`VARCHAR(20)`) porque o número é impresso e comunicado ao cliente.
3. **Correlação sem FK** onde a coluna de origem é anulável por natureza:
   `movimentacao_estoque_pecas` e `conta_corrente_oficina` referenciam ora uma nota
   fiscal, ora uma ordem de serviço, conforme a coluna `origem`/`tipo`; e
   `orcamentos_itens_ordem_servico.id_servico_sku` é polimórfico entre `servicos` e
   `pecas`, conforme `tipo_item`.

Separar saldo (`estoque_pecas`) de histórico (`movimentacao_estoque_pecas`) também é
deliberado: o saldo é lido a cada orçamento e o histórico é apenas acrescido.

## Consequências

- integridade referencial das relações polimórficas é responsabilidade da aplicação e
  precisa de teste automatizado no backend;
- o índice parcial `ux_historico_os_status_aberto` garante no banco a invariante de uma
  etapa aberta por OS, sem depender de lock na aplicação;
- exclusão é lógica (`ativo`, `estornada`, `estornado`), preservando histórico contábil
  e de estoque;
- consultas sobre relação polimórfica precisam de índice explícito, ver
  [`../index-review.md`](../index-review.md).

## Alternativas descartadas

- **Tabela por tipo de item de orçamento** (uma para serviço, outra para peça):
  duplicaria a lógica de versão do orçamento e a invariante de status por item.
- **FK polimórfica com colunas exclusivas e `CHECK`**: possível, mas tornaria a
  movimentação de estoque muito mais rígida do que os cenários de estorno exigem.
- **Placa como PK global de veículo**: impediria registrar a transferência de um veículo
  entre clientes sem apagar histórico.
