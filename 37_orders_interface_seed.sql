-- =====================================================================
-- Seed 37: interface 'orders' (id 29) — Pedido de Venda/Conjugado
-- (2026-08-22). Espelha o padrão do seed 23 (salesmen/carriers).
--
-- Módulo Flutter já construído em apps/web/lib/app/modules/orders/
-- (rota /home/orders/, grupo de menu "Vendas" — chave i18n `Vendas` já
-- adicionada em pt.json/en.json pelo agente que fez a tela). Sem isso o
-- módulo fica pronto mas invisível no menu — este seed é o que falta.
--
-- Executar após script 36.
-- =====================================================================

USE `setes_central`;

INSERT IGNORE INTO `tb_interface`
  (`id`, `group_default`, `i18n_key`, `description`, `kind`, `position`, `created_at`, `updated_at`, `deleted`)
VALUES
  (29, 'Vendas', 'orders', 'Sales Order', 'T', NULL, NOW(), NOW(), 'N');

-- Contrato da Setes; para outros clientes o Super concede pela aba
-- Interfaces do Institution.
INSERT IGNORE INTO `setes_setes`.`tb_institution_has_interface`
  (`tb_institution_id`, `tb_interface_id`, `active`, `created_at`, `updated_at`, `deleted`)
VALUES
  (1, 29, 'S', NOW(), NOW(), 'N');

-- Paginação (regra do prompt_paginacao_telas_pesquisa.md): lista nova
-- nasce paginada.
INSERT IGNORE INTO `tb_interface_has_config`
  (`tb_interface_id`, `name`, `description`, `kind`, `options`, `default_content`, `scope`, `created_at`, `updated_at`, `deleted`)
SELECT i.`id`, 'page_size',
       'Número de itens exibidos por página na lista de pesquisa.',
       'Options', '10=10;25=25;50=50;100=100', '25', 'U', NOW(), NOW(), 'N'
  FROM `tb_interface` i
 WHERE i.`deleted` = 'N' AND i.`i18n_key` = 'orders';
