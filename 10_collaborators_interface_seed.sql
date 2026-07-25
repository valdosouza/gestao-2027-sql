-- =====================================================================
-- Onda 2 da Entidade Única — Seed: interface 'collaborators'
-- (cadastro do Colaborador, pedido do Valdo 2026-07-18)
--
-- Executar após scripts 01, 02 e 06..09.
-- INSERT IGNORE: idempotente, seguro para re-execução.
--
-- Interface de CLIENTE (não é Super): módulo collaborators no app
-- (/home/collaborators) e /api/collaborators na API (SEM superGuard —
-- escopo por institution vem do JWT; padrão simétrico).
--
-- group_default = 'Registers' → menu.groups (pt "Cadastros" / en
-- "Registers"); i18n_key = 'collaborators' → menu.interfaces.collaborators.
-- =====================================================================

USE `setes_central`;

INSERT IGNORE INTO `tb_interface`
  (`id`, `group_default`, `i18n_key`, `description`, `kind`, `position`, `created_at`, `updated_at`, `deleted`)
VALUES
  (12, 'Registers', 'collaborators', 'Collaborator', 'T', NULL, NOW(), NOW(), 'N');

-- Contrato da Setes; para outros clientes o Super concede pela aba
-- Interfaces do Institution.
INSERT IGNORE INTO `setes_setes`.`tb_institution_has_interface`
  (`tb_institution_id`, `tb_interface_id`, `active`, `created_at`, `updated_at`, `deleted`)
VALUES
  (1, 12, 'S', NOW(), NOW(), 'N');

-- Gate técnico do módulo /api/collaborators para institutions EXISTENTES
-- (novas ganham via insertDefaultFlags). Idempotente: UNIQUE
-- (tb_institution_id, module_key); id = MAX+1 por linha (sem AUTO_INCREMENT).
INSERT IGNORE INTO `tb_feature_flag`
  (`id`, `tb_institution_id`, `module_key`, `enabled`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(f2.id), 0) FROM `tb_feature_flag` f2) + i.rn,
       i.id, 'collaborators', TRUE, NOW(), NOW(), 'N'
FROM (
  SELECT t.id, ROW_NUMBER() OVER (ORDER BY t.id) AS rn
  FROM `tb_institution` t
  WHERE t.deleted = 'N'
    AND NOT EXISTS (SELECT 1 FROM `tb_feature_flag` f
                    WHERE f.tb_institution_id = t.id
                      AND f.module_key = 'collaborators')
) i;
