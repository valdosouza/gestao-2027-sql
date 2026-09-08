-- =====================================================================
-- Seed 47: catálogo de campos configuráveis (tb_interface_has_field) da
-- interface 'financial-contracts' (Contratos Financeiros — migration 038,
-- prompt_contrato_financeiro_baixa_automatica.md D1–D22).
-- Gerado por setes-api/scripts/gerar-interface-fields.ts (2026-09-04) e
-- REVISADO: id da interface DINÂMICO (por i18n_key — lição do seed 40),
-- tb_institution_id fora (escopo do JWT), tb_payment_types_id = PK do
-- recurso (baseline técnico 'S'), demais com default no DTO ('N' — o
-- cliente pode apertar). Re-executável (INSERT IGNORE). Executar após o 46.
-- =====================================================================
USE `setes_central`;

INSERT IGNORE INTO `tb_interface_has_field`
  (`tb_interface_id`, `field_name`, `table_name`, `kind`, `required`, `created_at`, `updated_at`, `deleted`)
SELECT i.`id`, f.`field_name`, 'tb_financial_contract', f.`kind`, f.`required`, NOW(), NOW(), 'N'
  FROM `tb_interface` i
  JOIN (
        SELECT 'tb_payment_types_id' AS field_name, 'Integer' AS kind, 'S' AS required
        UNION ALL SELECT 'tb_bank_account_id', 'Integer', 'N'
        UNION ALL SELECT 'fee_rate',           'Float',   'N'
        UNION ALL SELECT 'payment_term',       'Integer', 'N'
        UNION ALL SELECT 'expiration_date',    'Date',    'N'
        UNION ALL SELECT 'note',               'String',  'N'
       ) f
 WHERE i.`i18n_key` = 'financial-contracts' AND i.`deleted` = 'N';
