-- =====================================================================
-- Seed 59: privilégio TRANSMITIR (id 9) — prompt_onda_nfe_sefaz.md D-E14 /
-- prompt_onda3_nfse_adn.md (Valdo, 2026-09-21 "siga as recomendações"):
-- transmitir o documento ao fisco é ato SEPARADO de faturar (o legado separava
-- AUTORIZAR de faturar). Regra Q-G29: o privilégio existe na TABELA, é OPÇÃO na
-- tela do RAMO e o código exige na rota (`POST /api/billing/transmit`,
-- `/transmit-batch` — `requirePrivilegeFor` resolve a interface pelo ramo do
-- pedido: `service-orders` × `orders`); admin/super passam sem vínculo.
-- Idempotente. Companheiro dos seeds 51–55. Tarefa de implantação: vincular o
-- privilégio aos usuários regulares que transmitem (tb_user_has_privilege).
-- =====================================================================

USE `setes_central`;

INSERT IGNORE INTO `tb_privilege` (`id`, `description`, `created_at`, `updated_at`, `deleted`)
VALUES (9, 'TRANSMITIR', NOW(), NOW(), 'N');

INSERT IGNORE INTO `tb_interface_has_privilege`
  (`tb_interface_id`, `tb_privilege_id`, `active`, `created_at`, `updated_at`, `deleted`)
SELECT i.`id`, p.`id`, 'S', NOW(), NOW(), 'N'
  FROM `tb_interface` i
  JOIN `tb_privilege` p ON p.`id` = 9 AND p.`deleted` = 'N'
 WHERE i.`i18n_key` IN ('service-orders', 'orders') AND i.`deleted` = 'N';
