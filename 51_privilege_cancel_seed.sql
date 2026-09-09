-- =====================================================================
-- Seed 51: privilégio CANCELAR (id 7) no catálogo central + vínculo dos
-- privilégios de AÇÃO da interface 'orders' (FATURAR 5, CANCELAR 7) —
-- prompt_cancelamento_nota.md D12 + Q-P5 (Valdo, 2026-09-08).
-- A API passa a APLICAR privilégio de ação na rota (guard
-- @shared/auth/require-privilege): super e admin passam; usuário regular
-- precisa do vínculo em tb_user_has_privilege (schema do cliente).
-- Idempotente. Acompanha a migration 042 (setes-api).
-- =====================================================================

USE `setes_central`;

INSERT IGNORE INTO `tb_privilege` (`id`, `description`, `created_at`, `updated_at`, `deleted`)
VALUES (7, 'CANCELAR', NOW(), NOW(), 'N');

INSERT IGNORE INTO `tb_interface_has_privilege`
  (`tb_interface_id`, `tb_privilege_id`, `active`, `created_at`, `updated_at`, `deleted`)
SELECT i.`id`, p.`id`, 'S', NOW(), NOW(), 'N'
  FROM `tb_interface` i
  JOIN `tb_privilege` p ON p.`id` IN (5, 7) AND p.`deleted` = 'N'
 WHERE i.`i18n_key` = 'orders' AND i.`deleted` = 'N';
