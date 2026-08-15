-- =====================================================================
-- Seed: interface 'modules' — Módulos de Menu do cliente
-- (prompt_modulo_menus.md, D1–D4 — Valdo 2026-08-04)
--
-- Executar após scripts 01, 02 e 06..25.
-- Idempotente (NOT EXISTS por i18n_key / INSERT IGNORE).
--
-- Interface do grupo 'Sistema' (precedente: interfaces 7/8/10/11): tela do
-- ADMIN do cliente (adminGuard em /api/modules) que gerencia a camada 2 do
-- menu (tb_module + tb_module_has_interface no schema do cliente).
-- id preferencial 26, resolvido dinamicamente (lição do seed 25).
-- =====================================================================

USE `setes_central`;

INSERT INTO `tb_interface`
  (`id`, `group_default`, `i18n_key`, `description`, `kind`, `position`, `created_at`, `updated_at`, `deleted`)
SELECT GREATEST(26, (SELECT COALESCE(MAX(i2.`id`), 0) + 1 FROM `tb_interface` i2)),
       'Sistema', 'modules', 'Menu Modules', 'T', NULL, NOW(), NOW(), 'N'
  FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM `tb_interface` WHERE `i18n_key` = 'modules' AND `deleted` = 'N');

-- Contrato da Setes; para outros clientes o Super concede pela aba
-- Interfaces do Institution.
INSERT IGNORE INTO `setes_setes`.`tb_institution_has_interface`
  (`tb_institution_id`, `tb_interface_id`, `active`, `created_at`, `updated_at`, `deleted`)
SELECT 1, i.`id`, 'S', NOW(), NOW(), 'N'
  FROM `tb_interface` i
 WHERE i.`deleted` = 'N' AND i.`i18n_key` = 'modules';

-- Gate técnico do módulo /api/modules para institutions EXISTENTES
-- (novas ganham via insertDefaultFlags — 'modules' entrou nos defaults).
INSERT IGNORE INTO `tb_feature_flag`
  (`id`, `tb_institution_id`, `module_key`, `enabled`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(f2.id), 0) FROM `tb_feature_flag` f2) + i.rn,
       i.id, 'modules', TRUE, NOW(), NOW(), 'N'
FROM (
  SELECT t.id, ROW_NUMBER() OVER (ORDER BY t.id) AS rn
  FROM `tb_institution` t
  WHERE t.deleted = 'N'
    AND NOT EXISTS (SELECT 1 FROM `tb_feature_flag` f
                    WHERE f.tb_institution_id = t.id
                      AND f.module_key = 'modules')
) i;

-- Catálogo de CAMPOS da tela (Fase 2 — engine na fábrica), por i18n_key.
INSERT IGNORE INTO `tb_interface_has_field`
  (`tb_interface_id`, `field_name`, `table_name`, `kind`, `required`, `created_at`, `updated_at`, `deleted`)
SELECT i.`id`, f.`field_name`, 'tb_module', f.`kind`, f.`required`, NOW(), NOW(), 'N'
  FROM `tb_interface` i
 CROSS JOIN (
   SELECT 'description' AS field_name, 'String'  AS kind, 'S' AS required
   UNION ALL SELECT 'position',   'Integer', 'N'
   UNION ALL SELECT 'image_icon', 'String',  'N'
 ) f
 WHERE i.`deleted` = 'N' AND i.`i18n_key` = 'modules';

-- Paginação (lista NOVA nasce paginada) — config page_size da interface.
INSERT IGNORE INTO `tb_interface_has_config`
  (`tb_interface_id`, `name`, `description`, `kind`, `options`, `default_content`, `scope`, `created_at`, `updated_at`, `deleted`)
SELECT i.`id`, 'page_size',
       'Número de itens exibidos por página na lista de pesquisa.',
       'Options', '10=10;25=25;50=50;100=100', '25', 'U', NOW(), NOW(), 'N'
  FROM `tb_interface` i
 WHERE i.`deleted` = 'N'
   AND i.`i18n_key` = 'modules';
