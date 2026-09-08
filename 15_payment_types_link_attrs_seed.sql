-- =====================================================================
-- Seed: 15_payment_types_link_attrs_seed.sql — Formas de Pagamento v2
-- (pedido do Valdo 2026-07-18)
--
-- Acompanha a migration 012 (setes-api) que alterou
-- tb_institution_has_payment_types nos schemas de cliente:
--   active -> enable · app_delivery -> app_mobile · + configuração
--   operacional (bloqueios, parcelas, TEF, Plano de Contas, uso).
--
-- Este script REALINHA o catálogo de campos (tb_interface_has_field) em
-- bases CENTRAIS EXISTENTES. Bases novas já nascem certas pelo sql/14
-- atualizado — aqui os UPDATEs viram no-op e os INSERT IGNORE não duplicam
-- (PK tb_interface_id + field_name). Idempotente.
--
-- Atenção: se algum schema de cliente tiver override em
-- tb_institution_has_field para 'active'/'app_delivery' (FK composta para
-- este catálogo), renomeie lá ANTES de rodar os UPDATEs.
-- =====================================================================

USE `setes_central`;

UPDATE `tb_interface_has_field`
   SET `field_name` = 'enable', `updated_at` = NOW()
 WHERE `tb_interface_id` = 16 AND `field_name` = 'active';

UPDATE `tb_interface_has_field`
   SET `field_name` = 'app_mobile', `updated_at` = NOW()
 WHERE `tb_interface_id` = 16 AND `field_name` = 'app_delivery';

INSERT IGNORE INTO `tb_interface_has_field`
  (`tb_interface_id`, `field_name`, `table_name`, `kind`, `required`, `created_at`, `updated_at`, `deleted`)
VALUES
  (16, 'block_for_customer_blocked',  'tb_institution_has_payment_types', 'Boolean', 'N', NOW(), NOW(), 'N'),
  (16, 'block_for_customer_no_limit', 'tb_institution_has_payment_types', 'Boolean', 'N', NOW(), NOW(), 'N'),
  (16, 'max_parcels',                 'tb_institution_has_payment_types', 'Integer', 'N', NOW(), NOW(), 'N'),
  (16, 'tef',                         'tb_institution_has_payment_types', 'Boolean', 'N', NOW(), NOW(), 'N'),
  (16, 'tb_financial_plans_id_cre',   'tb_institution_has_payment_types', 'Integer', 'N', NOW(), NOW(), 'N'),
  (16, 'tb_financial_plans_id_deb',   'tb_institution_has_payment_types', 'Integer', 'N', NOW(), NOW(), 'N');
-- usage_preference APOSENTADA (migration 038 / seed 46 — D17 do contrato financeiro)
