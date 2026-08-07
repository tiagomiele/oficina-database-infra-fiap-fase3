# Modelo de dados e responsabilidades

## Divisão de responsabilidades

Este repositório cria o serviço RDS. O repositório da aplicação mantém migrations Flyway, constraints funcionais e evolução do schema.

## Evoluções previstas na aplicação

- índice único de documento normalizado para autenticação por CPF;
- consulta de cliente por documento e status ativo;
- histórico de transições da Ordem de Serviço;
- índices para status, período, cliente e movimentações;
- revisão do diagrama entidade-relacionamento.

## Histórico de status

A nova estrutura deverá registrar status, entrada, saída, duração e correlação. Esses dados alimentarão o dashboard de tempo médio em diagnóstico, execução e finalização.

A Lambda terá acesso mínimo aos dados necessários do cliente e não reutilizará entidades JPA da aplicação.
