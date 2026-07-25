-- =====================================================================
-- Seed: 18_service_orders_seed.sql — Software House Onda 4
-- (Valdo, 2026-07-19 — prompt fechado prompt_modulo_software_house.md)
--
-- Interface 20 'service-orders' (Ordens de Serviço — ciclo mensal 4.5)
-- no grupo NOVO 'Services' (menu "Serviços" — 1ª tela de PROCESSO do
-- produto: OS aberta acumulando itens, rotina mensal e Gerar Faturamento).
-- Contrato da Setes + flag técnica p/ institutions existentes + catálogo
-- de campos. Idempotente.
-- =====================================================================

USE `setes_central`;

INSERT IGNORE INTO `tb_interface`
  (`id`, `group_default`, `i18n_key`, `description`, `kind`, `position`, `created_at`, `updated_at`, `deleted`)
VALUES
  (20, 'Services', 'service-orders', 'Service Orders', 'T', NULL, NOW(), NOW(), 'N');

INSERT IGNORE INTO `setes_setes`.`tb_institution_has_interface`
  (`tb_institution_id`, `tb_interface_id`, `active`, `created_at`, `updated_at`, `deleted`)
VALUES
  (1, 20, 'S', NOW(), NOW(), 'N');

INSERT IGNORE INTO `tb_feature_flag`
  (`id`, `tb_institution_id`, `module_key`, `enabled`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(f2.id), 0) FROM `tb_feature_flag` f2) + i.rn,
       i.id, 'service-orders', TRUE, NOW(), NOW(), 'N'
FROM (
  SELECT t.id, ROW_NUMBER() OVER (ORDER BY t.id) AS rn
  FROM `tb_institution` t
  WHERE t.deleted = 'N'
    AND NOT EXISTS (SELECT 1 FROM `tb_feature_flag` f
                    WHERE f.tb_institution_id = t.id
                      AND f.module_key = 'service-orders')
) i;

-- Catálogo de CAMPOS (Fase 2) — os do fluxo de faturamento.
INSERT IGNORE INTO `tb_interface_has_field`
  (`tb_interface_id`, `field_name`, `table_name`, `kind`, `required`, `created_at`, `updated_at`, `deleted`)
VALUES
  (20, 'id',             'tb_order_service', 'Integer', 'S', NOW(), NOW(), 'N'),
  (20, 'number',         'tb_order_service', 'Integer', 'N', NOW(), NOW(), 'N'),
  (20, 'tb_customer_id', 'tb_order_service', 'Integer', 'S', NOW(), NOW(), 'N'),
  (20, 'tb_product_id',  'tb_order_item',    'Integer', 'S', NOW(), NOW(), 'N'),
  (20, 'quantity',       'tb_order_item',    'Float',   'S', NOW(), NOW(), 'N'),
  (20, 'unit_value',     'tb_order_item',    'Float',   'S', NOW(), NOW(), 'N'),
  (20, 'discount_value', 'tb_order_item',    'Float',   'N', NOW(), NOW(), 'N'),
  (20, 'dt_expiration',  'tb_financial',     'Date',    'S', NOW(), NOW(), 'N'),
  (20, 'tb_payment_types_id', 'tb_financial', 'Integer', 'S', NOW(), NOW(), 'N');
