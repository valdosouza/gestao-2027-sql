-- =====================================================================
-- Seed 31: flag 'state-tax-rates' RETROATIVA para institutions existentes
-- (W2 Onda 2, 2026-08-20 — catálogo MVA/FCP por UF×NCM, prompt_fase_
-- faturamento_financeiro.md Rodada 3). Fonte do ICMS-ST/FCP do motor de
-- cálculo por item; sem tela no app ainda (Q22), mas a API já precisa
-- estar acessível pra cadastrar dados via Postman/futura tela.
--
-- Institutions NOVAS já ganham 'state-tax-rates' pelo insertDefaultFlags;
-- este script cobre as CRIADAS ANTES disso. Mesmo shape do seed 29 (users).
--
-- Executar após scripts 01..30. INSERT IGNORE / NOT EXISTS: idempotente
-- (UNIQUE tb_institution_id + module_key), seguro para re-execução.
-- =====================================================================

USE `setes_central`;

INSERT IGNORE INTO `tb_feature_flag`
  (`id`, `tb_institution_id`, `module_key`, `enabled`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(f2.id), 0) FROM `tb_feature_flag` f2) + i.rn,
       i.id, 'state-tax-rates', TRUE, NOW(), NOW(), 'N'
FROM (
  SELECT t.id, ROW_NUMBER() OVER (ORDER BY t.id) AS rn
  FROM `tb_institution` t
  WHERE t.deleted = 'N'
    AND NOT EXISTS (SELECT 1 FROM `tb_feature_flag` f
                    WHERE f.tb_institution_id = t.id
                      AND f.module_key = 'state-tax-rates')
) i;
