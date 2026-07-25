-- =====================================================================
-- Seed: interface 'financial-plans' — Plano de Contas
-- (pedido do Valdo 2026-07-18; 2º cadastro em árvore)
--
-- Executar após scripts 01, 02 e 06..11.
-- INSERT IGNORE: idempotente, seguro para re-execução.
--
-- Interface de CLIENTE: módulo financial_plans no app
-- (/home/financial-plans) e /api/financial-plans na API (SEM superGuard —
-- escopo por institution do JWT). group_default = 'Registers' → menu
-- "Cadastros"; i18n_key = 'financial-plans'.
-- =====================================================================

USE `setes_central`;

INSERT IGNORE INTO `tb_interface`
  (`id`, `group_default`, `i18n_key`, `description`, `kind`, `position`, `created_at`, `updated_at`, `deleted`)
VALUES
  (14, 'Registers', 'financial-plans', 'Financial Plans', 'T', NULL, NOW(), NOW(), 'N');

-- Contrato da Setes; outros clientes via aba Interfaces do Institution.
INSERT IGNORE INTO `setes_setes`.`tb_institution_has_interface`
  (`tb_institution_id`, `tb_interface_id`, `active`, `created_at`, `updated_at`, `deleted`)
VALUES
  (1, 14, 'S', NOW(), NOW(), 'N');

-- Gate técnico do módulo /api/financial-plans para institutions EXISTENTES
-- (novas ganham via insertDefaultFlags).
INSERT IGNORE INTO `tb_feature_flag`
  (`id`, `tb_institution_id`, `module_key`, `enabled`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(f2.id), 0) FROM `tb_feature_flag` f2) + i.rn,
       i.id, 'financial-plans', TRUE, NOW(), NOW(), 'N'
FROM (
  SELECT t.id, ROW_NUMBER() OVER (ORDER BY t.id) AS rn
  FROM `tb_institution` t
  WHERE t.deleted = 'N'
    AND NOT EXISTS (SELECT 1 FROM `tb_feature_flag` f
                    WHERE f.tb_institution_id = t.id
                      AND f.module_key = 'financial-plans')
) i;

-- Catálogo de CAMPOS da tela (Fase 2 — documentação do painel; o form em
-- árvore é artesanal, o engine não se aplica na v1).
INSERT IGNORE INTO `tb_interface_has_field`
  (`tb_interface_id`, `field_name`, `table_name`, `kind`, `required`, `created_at`, `updated_at`, `deleted`)
VALUES
  (14, 'id',          'tb_financial_plans', 'Integer', 'S', NOW(), NOW(), 'N'),
  (14, 'description', 'tb_financial_plans', 'String',  'S', NOW(), NOW(), 'N'),
  (14, 'posit_level', 'tb_financial_plans', 'String',  'S', NOW(), NOW(), 'N'),
  (14, 'source_',     'tb_financial_plans', 'String',  'N', NOW(), NOW(), 'N'),
  (14, 'kind',        'tb_financial_plans', 'String',  'N', NOW(), NOW(), 'N'),
  (14, 'cluster',     'tb_financial_plans', 'String',  'N', NOW(), NOW(), 'N'),
  (14, 'active',      'tb_financial_plans', 'Boolean', 'N', NOW(), NOW(), 'N');
