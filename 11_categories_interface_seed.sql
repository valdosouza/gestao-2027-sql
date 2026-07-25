-- =====================================================================
-- Seed: interface 'categories' — Categorias de produtos e serviços
-- (pedido do Valdo 2026-07-18)
--
-- Executar após scripts 01, 02 e 06..10.
-- INSERT IGNORE: idempotente, seguro para re-execução.
--
-- Interface de CLIENTE: módulo categories no app (/home/categories) e
-- /api/categories na API (SEM superGuard — escopo por institution do JWT).
-- group_default = 'Registers' → menu "Cadastros"; i18n_key = 'categories'.
-- =====================================================================

USE `setes_central`;

INSERT IGNORE INTO `tb_interface`
  (`id`, `group_default`, `i18n_key`, `description`, `kind`, `position`, `created_at`, `updated_at`, `deleted`)
VALUES
  (13, 'Registers', 'categories', 'Category', 'T', NULL, NOW(), NOW(), 'N');

-- Contrato da Setes; outros clientes via aba Interfaces do Institution.
INSERT IGNORE INTO `setes_setes`.`tb_institution_has_interface`
  (`tb_institution_id`, `tb_interface_id`, `active`, `created_at`, `updated_at`, `deleted`)
VALUES
  (1, 13, 'S', NOW(), NOW(), 'N');

-- Gate técnico do módulo /api/categories para institutions EXISTENTES
-- (novas ganham via insertDefaultFlags).
INSERT IGNORE INTO `tb_feature_flag`
  (`id`, `tb_institution_id`, `module_key`, `enabled`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(f2.id), 0) FROM `tb_feature_flag` f2) + i.rn,
       i.id, 'categories', TRUE, NOW(), NOW(), 'N'
FROM (
  SELECT t.id, ROW_NUMBER() OVER (ORDER BY t.id) AS rn
  FROM `tb_institution` t
  WHERE t.deleted = 'N'
    AND NOT EXISTS (SELECT 1 FROM `tb_feature_flag` f
                    WHERE f.tb_institution_id = t.id
                      AND f.module_key = 'categories')
) i;

-- Catálogo de CAMPOS da tela (Fase 2 — engine obrigatório em tela nova):
-- baseline técnico = DDL NOT NULL ∪ DTO obrigatório.
INSERT IGNORE INTO `tb_interface_has_field`
  (`tb_interface_id`, `field_name`, `table_name`, `kind`, `required`, `created_at`, `updated_at`, `deleted`)
VALUES
  (13, 'id',          'tb_category', 'Integer', 'S', NOW(), NOW(), 'N'),
  (13, 'description', 'tb_category', 'String',  'S', NOW(), NOW(), 'N'),  -- DTO min(1)
  (13, 'posit_level', 'tb_category', 'String',  'N', NOW(), NOW(), 'N'),
  (13, 'kind',        'tb_category', 'String',  'N', NOW(), NOW(), 'N'),
  (13, 'active',      'tb_category', 'Boolean', 'N', NOW(), NOW(), 'N');
