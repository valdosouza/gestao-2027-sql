-- =====================================================================
-- Seed 34: config approx_tax_enabled (P11 — motor de observações fiscais,
-- Imposto Aproximado / Lei da Transparência 12.741/2012) no catálogo
-- 'billing' (mesma interface dos seeds 32/33).
--
-- Evidência do legado: Fc_Obs_ImpostoAproximado só roda quando a config
-- geral GRL_G_IMPOSTO_APROX = 'S' — vira config de escopo Institution.
--
-- Idempotente (NOT EXISTS). Executar após script 33.
-- =====================================================================

USE `setes_central`;

INSERT INTO `tb_interface_has_config`
  (`tb_interface_id`, `name`, `description`, `kind`, `options`,
   `default_content`, `scope`, `created_at`, `updated_at`, `deleted`)
SELECT i.id, 'approx_tax_enabled',
       'Inclui a observação de imposto aproximado (Lei da Transparência 12.741/2012) na nota de venda',
       'Boolean', NULL, 'N', 'I', NOW(), NOW(), 'N'
FROM `tb_interface` i
WHERE i.i18n_key = 'billing'
  AND NOT EXISTS (SELECT 1 FROM `tb_interface_has_config` c
                  WHERE c.tb_interface_id = i.id AND c.name = 'approx_tax_enabled');
