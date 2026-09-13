-- =====================================================================
-- Seed 55: política do DESCONTO na baixa a receber — prompt_cancelamento_nota.md
-- D-G32 (Valdo, 2026-09-13): "por config determina o teto, o privilégio DESCONTO
-- autoriza e bypassa a validação". Legado BX-15: desconto exigia autorização.
--   (1) privilégio DESCONTO (id 8) existe na TABELA (tb_privilege);
--   (2) é OPÇÃO na tela de Baixas (tb_interface_has_privilege × 'settlements');
--   (3) o código valida: POST /api/settlements → assertDiscountPolicy.
--   (4) teto por institution: config `max_discount_aliquot` (Framework de
--       Configurações, scope I, Float) — default 0 = nenhum desconto sem o
--       privilégio (fiel ao legado); admin/super passam.
-- Idempotente. Companheiro dos seeds 51–54.
-- =====================================================================

USE `setes_central`;

INSERT IGNORE INTO `tb_privilege` (`id`, `description`, `created_at`, `updated_at`, `deleted`)
VALUES (8, 'DESCONTO', NOW(), NOW(), 'N');

-- D-G36 (Valdo 2026-09-13): a alíquota de desconto da CARTEIRA é desconto — a
-- mesma autoridade vale na interface de quem cadastra a carteira.
INSERT IGNORE INTO `tb_interface_has_privilege`
  (`tb_interface_id`, `tb_privilege_id`, `active`, `created_at`, `updated_at`, `deleted`)
SELECT i.`id`, p.`id`, 'S', NOW(), NOW(), 'N'
  FROM `tb_interface` i
  JOIN `tb_privilege` p ON p.`id` = 8 AND p.`deleted` = 'N'
 WHERE i.`i18n_key` IN ('settlements', 'bank-charge-agreements') AND i.`deleted` = 'N';

INSERT IGNORE INTO `tb_interface_has_config`
  (`tb_interface_id`, `name`, `description`, `kind`, `options`, `default_content`, `scope`, `created_at`, `updated_at`, `deleted`)
SELECT i.`id`, 'max_discount_aliquot',
       'Teto do desconto (%) na baixa a receber para quem NÃO tem o privilégio DESCONTO; 0 = nenhum desconto sem o privilégio. Quem tem o privilégio passa sem teto.',
       'Float', NULL, '0', 'I', NOW(), NOW(), 'N'
  FROM `tb_interface` i
 WHERE i.`deleted` = 'N' AND i.`i18n_key` = 'settlements';
