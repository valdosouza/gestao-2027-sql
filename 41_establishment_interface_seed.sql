-- =====================================================================
-- Seed 41: interface 'establishment' — Meu Estabelecimento
-- (2026-08-26). Grupo "Sistema" (mesmo grupo de users/modules).
--
-- Tela ESTRUTURAL (não vendável): permite ao ADMIN do cliente ler/editar
-- um subconjunto restrito do PRÓPRIO tb_institution (nome fantasia, razão
-- social, IE/IM, endereços/fones/redes) sem nunca aceitar :id de rota —
-- adminGuard em /api/establishment. id DINÂMICO (MAX+1, lição do seed 40 —
-- o v1 do seed 40 fixava id 30 e colidiu com o cashier do seed 38; nunca
-- fixar id de interface). Idempotente (NOT EXISTS / INSERT IGNORE).
-- Executar após script 40.
-- =====================================================================

USE `setes_central`;

INSERT INTO `tb_interface`
  (`id`, `group_default`, `i18n_key`, `description`, `kind`, `position`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(i2.`id`), 0) + 1 FROM `tb_interface` i2),
       'Sistema', 'establishment', 'My Establishment', 'T', NULL, NOW(), NOW(), 'N'
 WHERE NOT EXISTS (SELECT 1 FROM `tb_interface`
                    WHERE `i18n_key` = 'establishment' AND `deleted` = 'N');

-- Contrato da Setes (único institution existente em dev, id 1); para
-- outros clientes já existentes, grantStructuralInterfaces cobre daqui pra
-- frente (é ESTRUTURAL — STRUCTURAL_INTERFACE_KEYS), mas institutions
-- criadas ANTES desta mudança de código precisam do INSERT retroativo
-- abaixo, em TODOS os schemas de cliente (mesmo padrão do seed 26/40).
INSERT IGNORE INTO `setes_setes`.`tb_institution_has_interface`
  (`tb_institution_id`, `tb_interface_id`, `active`, `created_at`, `updated_at`, `deleted`)
SELECT 1, i.`id`, 'S', NOW(), NOW(), 'N'
  FROM `tb_interface` i
 WHERE i.`deleted` = 'N' AND i.`i18n_key` = 'establishment';

-- Gate técnico do módulo /api/establishment para institutions EXISTENTES
-- (novas ganham via insertDefaultFlags — 'establishment' entrou nos defaults).
INSERT IGNORE INTO `tb_feature_flag`
  (`id`, `tb_institution_id`, `module_key`, `enabled`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(f2.id), 0) FROM `tb_feature_flag` f2) + i.rn,
       i.id, 'establishment', TRUE, NOW(), NOW(), 'N'
FROM (
  SELECT t.id, ROW_NUMBER() OVER (ORDER BY t.id) AS rn
  FROM `tb_institution` t
  WHERE t.deleted = 'N'
    AND NOT EXISTS (SELECT 1 FROM `tb_feature_flag` f
                    WHERE f.tb_institution_id = t.id
                      AND f.module_key = 'establishment')
) i;
