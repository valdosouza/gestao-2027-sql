-- =====================================================================
-- Seed 65: interface 'institution-interfaces' ("Interfaces dos clientes") — D-PV11 (Valdo 2026-10-18,
-- Infra-IA/prompts/prompt_privilegios_interfaces.md §11): o vínculo estabelecimento × interfaces de cada cliente
-- (tb_institution_has_interface) numa tela PRÓPRIA do grupo Super, DELEGÁVEL pelo Super a usuário da Setes.
--   * group_default 'Super' (nunca vai ao menu de cliente; ao usuário da Setes só com o VISUALIZAR marcado pelo Super)
--   * privilégios VISUALIZAR (6) + ALTERAR (2) — regra "toda tela nasce com interface + privilégios" (D-GE19/D-PV1)
--   * page_size (lista nova nasce paginada — seed 22)
--   * flag técnica SÓ para a Setes (institution 1): a tela não existe para os clientes; o super escapa das flags
--   * SEM vínculo no contrato de ninguém: tela do Super não é vendida — a liberação do Super é a única chave (D-PV11 (b))
-- id DINÂMICO (MAX+1 — lição do seed 40). Idempotente. Conferência no fim falha alto (molde do seed 64).
-- NN conferido em 2026-10-18 (64 era o último) — conferir de novo antes de aplicar: há sessões paralelas.
-- =====================================================================

USE `setes_central`;

INSERT INTO `tb_interface`
  (`id`, `group_default`, `i18n_key`, `description`, `kind`, `position`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(i2.`id`), 0) + 1 FROM `tb_interface` i2),
       'Super', 'institution-interfaces', 'Client interfaces', 'T', NULL, NOW(), NOW(), 'N'
 WHERE NOT EXISTS (SELECT 1 FROM `tb_interface`
                    WHERE `i18n_key` = 'institution-interfaces' AND `deleted` = 'N');

INSERT IGNORE INTO `tb_interface_has_privilege`
  (`tb_interface_id`, `tb_privilege_id`, `active`, `created_at`, `updated_at`, `deleted`)
SELECT i.`id`, p.`id`, 'S', NOW(), NOW(), 'N'
  FROM `tb_interface` i
  JOIN `tb_privilege` p ON p.`id` IN (2, 6) AND p.`deleted` = 'N'
 WHERE i.`deleted` = 'N' AND i.`i18n_key` = 'institution-interfaces';

INSERT IGNORE INTO `tb_interface_has_config`
  (`tb_interface_id`, `name`, `description`, `kind`, `options`, `default_content`, `scope`, `created_at`, `updated_at`, `deleted`)
SELECT i.`id`, 'page_size',
       'Número de itens exibidos por página na lista de pesquisa.',
       'Options', '10=10;25=25;50=50;100=100', '25', 'U', NOW(), NOW(), 'N'
  FROM `tb_interface` i
 WHERE i.`deleted` = 'N' AND i.`i18n_key` = 'institution-interfaces';

-- D-PV25 (gate adversarial do delta da costura A1, L5): a config `page_size` acima faz da tela uma interface CONFIGURÁVEL — o par
-- (interface × CONFIGURAR, 11) nasce junto quando o verbo já existe com o nome exato (seed 68); assim a ordem 65 × 68 não importa.
INSERT IGNORE INTO `tb_interface_has_privilege`
  (`tb_interface_id`, `tb_privilege_id`, `active`, `created_at`, `updated_at`, `deleted`)
SELECT i.`id`, p.`id`, 'S', NOW(), NOW(), 'N'
  FROM `tb_interface` i
  JOIN `tb_privilege` p ON p.`id` = 11 AND BINARY p.`description` = 'CONFIGURAR' AND p.`deleted` = 'N'
 WHERE i.`deleted` = 'N' AND i.`i18n_key` = 'institution-interfaces';

-- Flag técnica só da Setes (institution 1) — D-PV10 tirou o atalho "a Setes tem acesso a tudo". Linha que já existe desligada ou
-- excluída é RELIGADA (gate socrático da D-PV11: o NOT EXISTS sozinho deixava a flag desligada como estava)
UPDATE `tb_feature_flag` SET `enabled` = TRUE, `deleted` = 'N', `updated_at` = NOW()
 WHERE `tb_institution_id` = 1 AND `module_key` = 'institution-interfaces';
INSERT IGNORE INTO `tb_feature_flag`
  (`id`, `tb_institution_id`, `module_key`, `enabled`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(f2.`id`), 0) + 1 FROM `tb_feature_flag` f2),
       1, 'institution-interfaces', TRUE, NOW(), NOW(), 'N'
 WHERE NOT EXISTS (SELECT 1 FROM `tb_feature_flag`
                    WHERE `tb_institution_id` = 1 AND `module_key` = 'institution-interfaces');

-- Conferência: a interface viva com os 2 privilégios E a flag ligada da Setes. Falha ALTO (SELECT numa tabela inexistente).
SET @seed65_ok = (
  SELECT COUNT(*) FROM `tb_interface` i
    JOIN `tb_interface_has_privilege` ihp ON ihp.`tb_interface_id` = i.`id` AND ihp.`deleted` = 'N' AND ihp.`active` = 'S'
   WHERE i.`i18n_key` = 'institution-interfaces' AND i.`deleted` = 'N' AND ihp.`tb_privilege_id` IN (2, 6)
);
SET @seed65_flag = (
  SELECT COUNT(*) FROM `tb_feature_flag`
   WHERE `tb_institution_id` = 1 AND `module_key` = 'institution-interfaces' AND `enabled` = TRUE AND `deleted` = 'N'
);
SET @seed65_sql = IF(@seed65_ok = 2 AND @seed65_flag = 1, 'SELECT 1', 'SELECT * FROM seed65_falhou_interface_privilegio_ou_flag_ausente');
PREPARE seed65_stmt FROM @seed65_sql;
EXECUTE seed65_stmt;
DEALLOCATE PREPARE seed65_stmt;
