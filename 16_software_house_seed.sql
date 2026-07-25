-- =====================================================================
-- Seed: 16_software_house_seed.sql — Módulo Software House (Onda 1/2)
-- (Valdo, 2026-07-18 — prompt FECHADO prompt_modulo_software_house.md)
--
-- Executar ANTES da migration 013 rodar nos schemas (dependência: a 013
-- migra os bancos locais para setes_central.tb_bank). Idempotente.
--
-- 1. tb_bank na CENTRAL para bases existentes (bases novas: sql/01);
-- 2. Interface 17 'contracts' (Contratos — grupo Registers) + contrato da
--    Setes + flag técnica p/ institutions existentes + catálogo de campos.
-- =====================================================================

USE `setes_central`;

CREATE TABLE IF NOT EXISTS `tb_bank` (
  `id`          int(11) NOT NULL,
  `number`      varchar(3) NOT NULL,
  `description` varchar(100) DEFAULT NULL,
  `created_at`  datetime DEFAULT NULL,
  `updated_at`  datetime DEFAULT NULL,
  `deleted`     char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`),
  UNIQUE KEY `number` (`number`),
  KEY `updated_at` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO `tb_interface`
  (`id`, `group_default`, `i18n_key`, `description`, `kind`, `position`, `created_at`, `updated_at`, `deleted`)
VALUES
  (17, 'Registers', 'contracts', 'Contracts', 'T', NULL, NOW(), NOW(), 'N');

-- Contrato da Setes; outros clientes via aba Interfaces do Institution.
INSERT IGNORE INTO `setes_setes`.`tb_institution_has_interface`
  (`tb_institution_id`, `tb_interface_id`, `active`, `created_at`, `updated_at`, `deleted`)
VALUES
  (1, 17, 'S', NOW(), NOW(), 'N');

-- Gate técnico do módulo /api/contracts para institutions EXISTENTES
-- (novas ganham via insertDefaultFlags).
INSERT IGNORE INTO `tb_feature_flag`
  (`id`, `tb_institution_id`, `module_key`, `enabled`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(f2.id), 0) FROM `tb_feature_flag` f2) + i.rn,
       i.id, 'contracts', TRUE, NOW(), NOW(), 'N'
FROM (
  SELECT t.id, ROW_NUMBER() OVER (ORDER BY t.id) AS rn
  FROM `tb_institution` t
  WHERE t.deleted = 'N'
    AND NOT EXISTS (SELECT 1 FROM `tb_feature_flag` f
                    WHERE f.tb_institution_id = t.id
                      AND f.module_key = 'contracts')
) i;

-- Catálogo de CAMPOS da tela (Fase 2).
INSERT IGNORE INTO `tb_interface_has_field`
  (`tb_interface_id`, `field_name`, `table_name`, `kind`, `required`, `created_at`, `updated_at`, `deleted`)
VALUES
  (17, 'id',             'tb_contract', 'Integer', 'S', NOW(), NOW(), 'N'),
  (17, 'tb_customer_id', 'tb_contract', 'Integer', 'S', NOW(), NOW(), 'N'),
  (17, 'dt_start',       'tb_contract', 'Date',    'S', NOW(), NOW(), 'N'),
  (17, 'dt_end',         'tb_contract', 'Date',    'N', NOW(), NOW(), 'N'),
  (17, 'payment_day',    'tb_contract', 'Integer', 'N', NOW(), NOW(), 'N'),
  (17, 'active',         'tb_contract', 'Boolean', 'N', NOW(), NOW(), 'N'),
  (17, 'tb_product_id',  'tb_contract_item', 'Integer', 'S', NOW(), NOW(), 'N'),
  (17, 'value',          'tb_contract_item', 'Float',   'S', NOW(), NOW(), 'N');
