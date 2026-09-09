-- =====================================================================
-- Seed 52: privilégio CANCELAR (7) na interface 'service-orders' —
-- prompt_cancelamento_nota.md Q-G16 (Valdo, 2026-09-09: o "Cancelar nota"
-- da OS vive no documento faturado; o privilégio é da interface do RAMO —
-- POST /api/billing/cancel aceita CANCELAR em `orders` OU `service-orders`).
-- Idempotente. Acompanha o seed 51.
-- =====================================================================

USE `setes_central`;

INSERT IGNORE INTO `tb_interface_has_privilege`
  (`tb_interface_id`, `tb_privilege_id`, `active`, `created_at`, `updated_at`, `deleted`)
SELECT i.`id`, p.`id`, 'S', NOW(), NOW(), 'N'
  FROM `tb_interface` i
  JOIN `tb_privilege` p ON p.`id` = 7 AND p.`deleted` = 'N'
 WHERE i.`i18n_key` = 'service-orders' AND i.`deleted` = 'N';
