-- =====================================================================
-- Paginação das Telas de Pesquisa — Seed da config page_size
-- (Infra-IA/prompts/prompt_paginacao_telas_pesquisa.md, decisões D4/D5/D6)
--
-- Executar após os seeds 06..19 (as interfaces precisam existir).
-- INSERT IGNORE + SELECT por i18n_key: idempotente e imune a divergência
-- de ids entre bases.
--
-- Catalogada por INTERFACE (peça do Framework de Configurações —
-- tb_interface_id NOT NULL): cada tela de lista lembra o próprio tamanho.
-- scope 'U': o seletor de itens/página da tela grava o override do usuário
-- (PUT /api/interface-configs/:id/page_size, target 'U'); admin define o
-- padrão da institution pelo painel; default do catálogo = 25 (D5).
--
-- FORA (D6): categories e financial-plans (árvores — carregam a hierarquia
-- inteira, não paginam). Interface de lista NOVA deve entrar neste seed.
-- =====================================================================

USE `setes_central`;

INSERT IGNORE INTO `tb_interface_has_config`
  (`tb_interface_id`, `name`, `description`, `kind`, `options`, `default_content`, `scope`, `created_at`, `updated_at`, `deleted`)
SELECT i.`id`, 'page_size',
       'Número de itens exibidos por página na lista de pesquisa.',
       'Options', '10=10;25=25;50=50;100=100', '25', 'U', NOW(), NOW(), 'N'
  FROM `tb_interface` i
 WHERE i.`deleted` = 'N'
   AND i.`i18n_key` IN (
       'institutions', 'privileges', 'interfaces', 'countries', 'states',
       'cities', 'cfop', 'users', 'customers', 'collaborators', 'contracts',
       'bank-accounts', 'payment-types', 'interface-fields',
       'interface-configs', 'service-orders', 'settlements',
       'salesmen', 'carriers', 'providers');
