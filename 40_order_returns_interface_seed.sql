-- =====================================================================
-- Seed 40 (v2): interface 'order-returns' — Devolução de Mercadoria
-- (2026-08-24). Grupo "Vendas".
--
-- v2 (achado HIGH do gate adversarial 2026-08-24): a v1 fixava id 30,
-- que o seed 38 (cashier) JÁ tinha ocupado — o INSERT IGNORE silenciou
-- e a interface nunca nasceu. Agora o id é DINÂMICO (MAX+1, padrão do
-- seed 27) e todos os vínculos são keyed por i18n_key — nunca por id
-- fixo. Idempotente (NOT EXISTS). Executar após script 39.
-- =====================================================================

USE `setes_central`;

INSERT INTO `tb_interface`
  (`id`, `group_default`, `i18n_key`, `description`, `kind`, `position`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(i2.`id`), 0) + 1 FROM `tb_interface` i2),
       'Vendas', 'order-returns', 'Merchandise Return', 'T', NULL, NOW(), NOW(), 'N'
 WHERE NOT EXISTS (SELECT 1 FROM `tb_interface`
                    WHERE `i18n_key` = 'order-returns' AND `deleted` = 'N');

-- Contrato da Setes; para outros clientes o Super concede pela aba
-- Interfaces do Institution.
INSERT IGNORE INTO `setes_setes`.`tb_institution_has_interface`
  (`tb_institution_id`, `tb_interface_id`, `active`, `created_at`, `updated_at`, `deleted`)
SELECT 1, i.`id`, 'S', NOW(), NOW(), 'N'
  FROM `tb_interface` i
 WHERE i.`deleted` = 'N' AND i.`i18n_key` = 'order-returns';

-- Paginação (regra do prompt_paginacao_telas_pesquisa.md): lista nova
-- nasce paginada.
INSERT IGNORE INTO `tb_interface_has_config`
  (`tb_interface_id`, `name`, `description`, `kind`, `options`, `default_content`, `scope`, `created_at`, `updated_at`, `deleted`)
SELECT i.`id`, 'page_size',
       'Número de itens exibidos por página na lista de pesquisa.',
       'Options', '10=10;25=25;50=50;100=100', '25', 'U', NOW(), NOW(), 'N'
  FROM `tb_interface` i
 WHERE i.`deleted` = 'N' AND i.`i18n_key` = 'order-returns';
