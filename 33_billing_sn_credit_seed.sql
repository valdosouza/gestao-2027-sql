-- =====================================================================
-- Seed 33: config sn_credit_aliq (P2.9 — CSOSN/Simples Nacional) no
-- catálogo 'billing' (mesma interface do seed 32/invoice_serie).
--
-- Evidência do legado: GRL_G_AQ_CRED_ICMS é uma alíquota ÚNICA por
-- estabelecimento (lida em venda/compra/ajuste/cupom — nunca por regra
-- ou produto). Aqui vira config de escopo Institution no Framework de
-- Configurações — resolução usuário→institution→default via
-- getConfigContent(institution, 'billing', 'sn_credit_aliq').
--
-- Idempotente (NOT EXISTS). Executar após script 32.
-- =====================================================================

USE `setes_central`;

INSERT INTO `tb_interface_has_config`
  (`tb_interface_id`, `name`, `description`, `kind`, `options`,
   `default_content`, `scope`, `created_at`, `updated_at`, `deleted`)
SELECT i.id, 'sn_credit_aliq',
       'Alíquota do crédito de ICMS do Simples Nacional (LC 123 art. 23) usada no faturamento',
       'Float', NULL, '0', 'I', NOW(), NOW(), 'N'
FROM `tb_interface` i
WHERE i.i18n_key = 'billing'
  AND NOT EXISTS (SELECT 1 FROM `tb_interface_has_config` c
                  WHERE c.tb_interface_id = i.id AND c.name = 'sn_credit_aliq');
