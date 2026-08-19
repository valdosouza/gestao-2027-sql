-- =====================================================================
-- Seed 29: flag 'users' RETROATIVA para institutions existentes
-- (chip do módulo de menus, 2026-08-04: flag 'users' nunca semeada —
-- admin de cliente tomava 403 ao gerenciar os próprios usuários)
--
-- Institutions NOVAS já ganham 'users' pelo insertDefaultFlags (A2,
-- 2026-08-15); este script cobre as CRIADAS ANTES disso. Gate técnico
-- de administração, não produto vendável — a tela Usuários continua
-- guardada pelo adminGuard.
--
-- Executar após scripts 01..28. INSERT IGNORE / NOT EXISTS: idempotente
-- (UNIQUE tb_institution_id + module_key), seguro para re-execução.
-- Mesmo shape do bloco de flag retroativa do seed 27 (tax-rules).
-- =====================================================================

USE `setes_central`;

INSERT IGNORE INTO `tb_feature_flag`
  (`id`, `tb_institution_id`, `module_key`, `enabled`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(f2.id), 0) FROM `tb_feature_flag` f2) + i.rn,
       i.id, 'users', TRUE, NOW(), NOW(), 'N'
FROM (
  SELECT t.id, ROW_NUMBER() OVER (ORDER BY t.id) AS rn
  FROM `tb_institution` t
  WHERE t.deleted = 'N'
    AND NOT EXISTS (SELECT 1 FROM `tb_feature_flag` f
                    WHERE f.tb_institution_id = t.id
                      AND f.module_key = 'users')
) i;
