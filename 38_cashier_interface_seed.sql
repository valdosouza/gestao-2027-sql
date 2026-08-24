-- =====================================================================
-- Seed 38: interface 'cashier' (id 30) — Abertura/Fechamento de Caixa
-- (2026-08-22). Espelha o padrão do seed 37 (orders).
--
-- Módulo Flutter já construído em apps/web/lib/app/modules/cashier/
-- (rota /home/cashier/, grupo 'Financial' REAPROVEITADO — mesmo grupo de
-- settlements/bank-accounts, sem i18n novo). Sem isso o módulo fica
-- pronto mas invisível no menu.
--
-- Executar após script 37.
-- =====================================================================

USE `setes_central`;

INSERT IGNORE INTO `tb_interface`
  (`id`, `group_default`, `i18n_key`, `description`, `kind`, `position`, `created_at`, `updated_at`, `deleted`)
VALUES
  (30, 'Financial', 'cashier', 'Cashier', 'T', NULL, NOW(), NOW(), 'N');

-- Contrato da Setes; para outros clientes o Super concede pela aba
-- Interfaces do Institution.
INSERT IGNORE INTO `setes_setes`.`tb_institution_has_interface`
  (`tb_institution_id`, `tb_interface_id`, `active`, `created_at`, `updated_at`, `deleted`)
VALUES
  (1, 30, 'S', NOW(), NOW(), 'N');
