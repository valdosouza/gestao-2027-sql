-- =====================================================================
-- Seed 62: catálogo de campos configuráveis (tb_interface_has_field) da
-- interface 'services' (Serviços — prompt_modulo_services.md D1–D7 +
-- fase IBS/CBS IB-1, prompt_fase_ibs_cbs.md §11: aba IBS/CBS com NBS e a
-- classificação cClassTrib/cIndOp — D-IB6).
-- Gerado por setes-api/scripts/gerar-interface-fields.ts (2026-10-10, tabelas
-- tb_product + tb_service + tb_service_ibscbs) e REVISADO:
--   - id da interface DINÂMICO (por i18n_key — lição do seed 40);
--   - FORA: id (gerado MAX+1), tb_institution_id (escopo do JWT), kind
--     (fixo 'S' pelo módulo), tb_user_id (auditoria);
--   - baseline técnico 'S' só no que o DTO exige: description, tb_category_id;
--     identifier é 'N' (em branco = o id — D7);
--   - classification_code/place_indicator_code são NOT NULL na peça 1:1, mas
--     a PEÇA é opcional (presença = serviço classificado) → baseline 'N'; o
--     cliente pode apertar (a obrigação LEGAL no faturamento é da IB-2, D-IB8).
-- A chave do payload de cada coluna está em setes-api
-- src/modules/services/services.dto.ts (SERVICE_FIELD_PATHS).
-- Re-executável (INSERT IGNORE na PK interface+campo). Executar após o 42.
-- =====================================================================
USE `setes_central`;

INSERT IGNORE INTO `tb_interface_has_field`
  (`tb_interface_id`, `field_name`, `table_name`, `kind`, `required`, `created_at`, `updated_at`, `deleted`)
SELECT i.`id`, f.`field_name`, f.`table_name`, f.`kind`, f.`required`, NOW(), NOW(), 'N'
  FROM `tb_interface` i
  JOIN (
        SELECT 'identifier' AS field_name, 'tb_product' AS table_name, 'String' AS kind, 'N' AS required
        UNION ALL SELECT 'description',            'tb_product',        'String',  'S'
        UNION ALL SELECT 'tb_category_id',         'tb_product',        'Integer', 'S'
        UNION ALL SELECT 'tb_financial_plans_id',  'tb_product',        'Integer', 'N'
        UNION ALL SELECT 'promotion',              'tb_product',        'Boolean', 'N'
        UNION ALL SELECT 'highlights',             'tb_product',        'Boolean', 'N'
        UNION ALL SELECT 'active',                 'tb_product',        'Boolean', 'N'
        UNION ALL SELECT 'published',              'tb_product',        'Boolean', 'N'
        UNION ALL SELECT 'note',                   'tb_product',        'String',  'N'
        UNION ALL SELECT 'tb_service_tax_rule_id', 'tb_service',        'Integer', 'N'
        UNION ALL SELECT 'nbs',                    'tb_service',        'String',  'N'
        UNION ALL SELECT 'classification_code',    'tb_service_ibscbs', 'String',  'N'
        UNION ALL SELECT 'place_indicator_code',   'tb_service_ibscbs', 'String',  'N'
       ) f
 WHERE i.`i18n_key` = 'services' AND i.`deleted` = 'N';
