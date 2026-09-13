-- =====================================================================
-- Seed 54: privilégio FATURAR (5) na interface 'order-returns' —
-- prompt_cancelamento_nota.md Q-G29 (Valdo, 2026-09-10): o privilégio existe
-- na tabela (tb_privilege 5), é referenciado como opção na tela da devolução
-- (tb_interface_has_privilege) e o código valida pelo RAMO do pedido
-- (POST /api/billing/invoice → resolver → 'order-returns'). CANCELAR (7)
-- entra com a Onda 2 (devolução faturada ainda não cancela). Idempotente.
-- Companheiro dos seeds 51 (orders), 52/53 (service-orders).
-- =====================================================================

USE `setes_central`;

INSERT IGNORE INTO `tb_interface_has_privilege`
  (`tb_interface_id`, `tb_privilege_id`, `active`, `created_at`, `updated_at`, `deleted`)
SELECT i.`id`, p.`id`, 'S', NOW(), NOW(), 'N'
  FROM `tb_interface` i
  JOIN `tb_privilege` p ON p.`id` = 5 AND p.`deleted` = 'N'
 WHERE i.`i18n_key` = 'order-returns' AND i.`deleted` = 'N';
