-- =====================================================================
-- Seed 48: interface 'bank-slips' (Boletos — tela de PROCESSO: emitir,
-- baixar manualmente, cancelar, estornar) + configuração
-- `auto_bank_slip` da interface `billing` — prompt_boleto_emitido.md
-- D1–D11 (2026-09-03) e D18 do contrato financeiro (gerar boleto
-- automaticamente no faturamento: 0 carteira ativa = só financeiro; 1 =
-- gera 1 boleto por título; 2..n = a tela do financeiro emite depois).
-- Grupo "Financial" (D2). id DINÂMICO (MAX+1 — lição do seed 40).
-- Idempotente. Acompanha a migration 039 (setes-api). Executar após o 47.
-- =====================================================================

USE `setes_central`;

-- Boletos (módulo bank-slips — /api/bank-slips ↔ /home/bank-slips)
INSERT INTO `tb_interface`
  (`id`, `group_default`, `i18n_key`, `description`, `kind`, `position`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(i2.`id`), 0) + 1 FROM `tb_interface` i2),
       'Financial', 'bank-slips', 'Bank Slips', 'T', NULL, NOW(), NOW(), 'N'
 WHERE NOT EXISTS (SELECT 1 FROM `tb_interface`
                    WHERE `i18n_key` = 'bank-slips' AND `deleted` = 'N');

-- Contrato da Setes (institution 1 — dev/dogfooding)
INSERT IGNORE INTO `setes_setes`.`tb_institution_has_interface`
  (`tb_institution_id`, `tb_interface_id`, `active`, `created_at`, `updated_at`, `deleted`)
SELECT 1, i.`id`, 'S', NOW(), NOW(), 'N'
  FROM `tb_interface` i
 WHERE i.`deleted` = 'N' AND i.`i18n_key` = 'bank-slips';

-- Paginação (regra: lista nova nasce paginada — seed 22)
INSERT IGNORE INTO `tb_interface_has_config`
  (`tb_interface_id`, `name`, `description`, `kind`, `options`, `default_content`, `scope`, `created_at`, `updated_at`, `deleted`)
SELECT i.`id`, 'page_size',
       'Número de itens exibidos por página na lista de pesquisa.',
       'Options', '10=10;25=25;50=50;100=100', '25', 'U', NOW(), NOW(), 'N'
  FROM `tb_interface` i
 WHERE i.`deleted` = 'N' AND i.`i18n_key` = 'bank-slips';

-- D18: "gerar boleto automaticamente no faturamento" (legado
-- FIN_FAT_GER_AUTO_BOLETO) vira configuração da interface billing —
-- Framework de Configurações (nunca flag avulsa). Default N; escopo I.
INSERT IGNORE INTO `tb_interface_has_config`
  (`tb_interface_id`, `name`, `description`, `kind`, `options`, `default_content`, `scope`, `created_at`, `updated_at`, `deleted`)
SELECT i.`id`, 'auto_bank_slip',
       'Gerar boleto automaticamente no faturamento (1 boleto por parcela em boleto) quando houver exatamente UMA carteira de cobrança ativa; com várias, a emissão é feita na tela de Boletos.',
       'Boolean', NULL, 'N', 'I', NOW(), NOW(), 'N'
  FROM `tb_interface` i
 WHERE i.`deleted` = 'N' AND i.`i18n_key` = 'billing';

-- Gate técnico do módulo /api/bank-slips para institutions EXISTENTES
INSERT IGNORE INTO `tb_feature_flag`
  (`id`, `tb_institution_id`, `module_key`, `enabled`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(f2.id), 0) FROM `tb_feature_flag` f2) + i.rn,
       i.id, 'bank-slips', TRUE, NOW(), NOW(), 'N'
FROM (
  SELECT t.id, ROW_NUMBER() OVER (ORDER BY t.id) AS rn
  FROM `tb_institution` t
  WHERE t.deleted = 'N'
    AND NOT EXISTS (SELECT 1 FROM `tb_feature_flag` f
                    WHERE f.tb_institution_id = t.id
                      AND f.module_key = 'bank-slips')
) i;
