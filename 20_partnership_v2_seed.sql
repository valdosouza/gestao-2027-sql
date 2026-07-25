-- =====================================================================
-- Seed: 20_partnership_v2_seed.sql — Parceria v2 (Valdo, 2026-07-19)
-- Acompanha a migration 016 (tb_partnership FLAT — decisões D1–D7 do
-- prompt_parceria_v2.md). Idempotente.
--
-- D3/D4: a tela standalone morre; a parceria vira ABA do cliente,
-- gateada como RECURSO VENDÁVEL (Framework de Configurações, decisão 13):
-- interface 18 'partnerships' vira kind 'R' (nunca vai a menu — os ramos
-- da montagem filtram kind='T'). Flag técnica 'partnerships' desativada
-- (a API da aba vive em /api/customers — flag 'customers').
-- =====================================================================

USE `setes_central`;

UPDATE `tb_interface`
   SET `kind` = 'R', `updated_at` = NOW()
 WHERE `id` = 18 AND `i18n_key` = 'partnerships';

UPDATE `tb_feature_flag`
   SET `deleted` = 'S', `updated_at` = NOW()
 WHERE `module_key` = 'partnerships' AND `deleted` = 'N';

-- Catálogo de campos realinhado para a tabela flat: morrem os campos da
-- entidade nomeada (D2); os do vínculo apontam para a tb_partnership.
UPDATE `tb_interface_has_field`
   SET `deleted` = 'S', `updated_at` = NOW()
 WHERE `tb_interface_id` = 18
   AND `field_name` IN ('id', 'description', 'dt_record');

UPDATE `tb_interface_has_field`
   SET `table_name` = 'tb_partnership', `updated_at` = NOW()
 WHERE `tb_interface_id` = 18
   AND `field_name` IN ('tb_customer_id', 'tb_collaborator_id', 'rate');

INSERT IGNORE INTO `tb_interface_has_field`
  (`tb_interface_id`, `field_name`, `table_name`, `kind`, `required`, `created_at`, `updated_at`, `deleted`)
VALUES
  (18, 'active', 'tb_partnership', 'Boolean', 'N', NOW(), NOW(), 'N');
