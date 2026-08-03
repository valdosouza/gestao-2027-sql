-- =====================================================================
-- Onda 2 salesman/carrier (prompt_onda2_salesman_carrier.md, D1–D5) —
-- Seed: interfaces 'salesmen' (22) e 'carriers' (23)
--
-- Executar após scripts 01, 02 e 06..22.
-- INSERT IGNORE: idempotente, seguro para re-execução.
--
-- Interfaces de CLIENTE (não é Super): módulos salesmen/carriers no app
-- (/home/salesmen, /home/carriers) e /api/salesmen, /api/carriers na API
-- (SEM superGuard — escopo por institution vem do JWT; padrão simétrico).
--
-- salesmen (D1): PROMOÇÃO de colaborador — o form não edita a cadeia
-- fiscal. carriers (D2): cadeia fiscal completa + aba Tributação.
-- group_default = 'Registers' → menu.groups (pt "Cadastros").
-- =====================================================================

USE `setes_central`;

INSERT IGNORE INTO `tb_interface`
  (`id`, `group_default`, `i18n_key`, `description`, `kind`, `position`, `created_at`, `updated_at`, `deleted`)
VALUES
  (22, 'Registers', 'salesmen', 'Salesman', 'T', NULL, NOW(), NOW(), 'N'),
  (23, 'Registers', 'carriers', 'Carrier',  'T', NULL, NOW(), NOW(), 'N');

-- Contrato da Setes; para outros clientes o Super concede pela aba
-- Interfaces do Institution.
INSERT IGNORE INTO `setes_setes`.`tb_institution_has_interface`
  (`tb_institution_id`, `tb_interface_id`, `active`, `created_at`, `updated_at`, `deleted`)
VALUES
  (1, 22, 'S', NOW(), NOW(), 'N'),
  (1, 23, 'S', NOW(), NOW(), 'N');

-- Gate técnico dos módulos /api/salesmen e /api/carriers para institutions
-- EXISTENTES (novas ganham via insertDefaultFlags). Idempotente: UNIQUE
-- (tb_institution_id, module_key); id = MAX+1 por linha (sem AUTO_INCREMENT).
INSERT IGNORE INTO `tb_feature_flag`
  (`id`, `tb_institution_id`, `module_key`, `enabled`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(f2.id), 0) FROM `tb_feature_flag` f2) + i.rn,
       i.id, 'salesmen', TRUE, NOW(), NOW(), 'N'
FROM (
  SELECT t.id, ROW_NUMBER() OVER (ORDER BY t.id) AS rn
  FROM `tb_institution` t
  WHERE t.deleted = 'N'
    AND NOT EXISTS (SELECT 1 FROM `tb_feature_flag` f
                    WHERE f.tb_institution_id = t.id
                      AND f.module_key = 'salesmen')
) i;

INSERT IGNORE INTO `tb_feature_flag`
  (`id`, `tb_institution_id`, `module_key`, `enabled`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(f2.id), 0) FROM `tb_feature_flag` f2) + i.rn,
       i.id, 'carriers', TRUE, NOW(), NOW(), 'N'
FROM (
  SELECT t.id, ROW_NUMBER() OVER (ORDER BY t.id) AS rn
  FROM `tb_institution` t
  WHERE t.deleted = 'N'
    AND NOT EXISTS (SELECT 1 FROM `tb_feature_flag` f
                    WHERE f.tb_institution_id = t.id
                      AND f.module_key = 'carriers')
) i;

-- Paginação (regra do prompt_paginacao_telas_pesquisa.md): lista NOVA nasce
-- paginada — config page_size das duas interfaces (mesmo shape do seed 22,
-- que também ganhou as chaves na lista canônica para bases novas).
INSERT IGNORE INTO `tb_interface_has_config`
  (`tb_interface_id`, `name`, `description`, `kind`, `options`, `default_content`, `scope`, `created_at`, `updated_at`, `deleted`)
SELECT i.`id`, 'page_size',
       'Número de itens exibidos por página na lista de pesquisa.',
       'Options', '10=10;25=25;50=50;100=100', '25', 'U', NOW(), NOW(), 'N'
  FROM `tb_interface` i
 WHERE i.`deleted` = 'N'
   AND i.`i18n_key` IN ('salesmen', 'carriers');
