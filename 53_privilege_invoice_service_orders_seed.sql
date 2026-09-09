-- =====================================================================
-- Seed 53: privilégio FATURAR (5) na interface 'service-orders' —
-- prompt_cancelamento_nota.md Q-G23 (Valdo, 2026-09-09): a rota de faturar
-- da OS (POST /api/service-orders/:id/invoice) passa a exigir FATURAR na
-- interface do RAMO; admin/super passam sem vínculo. Idempotente.
-- Companheiro do seed 52 (CANCELAR).
-- =====================================================================

USE `setes_central`;

INSERT IGNORE INTO `tb_interface_has_privilege`
  (`tb_interface_id`, `tb_privilege_id`, `active`, `created_at`, `updated_at`, `deleted`)
SELECT i.`id`, p.`id`, 'S', NOW(), NOW(), 'N'
  FROM `tb_interface` i
  JOIN `tb_privilege` p ON p.`id` = 5 AND p.`deleted` = 'N'
 WHERE i.`i18n_key` = 'service-orders' AND i.`deleted` = 'N';
