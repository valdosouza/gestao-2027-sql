-- =====================================================================
-- Seed: interface 'banks' — Cadastro do catálogo de Bancos (FEBRABAN)
-- (decisão do Valdo 2026-08-04 — fecho da decisão 8 da Fase 3: banco é
-- cadastro GERAL da central, SEM cadeia fiscal, liberado a todos os
-- schemas via lookup de conta corrente /api/bank-accounts/banks)
--
-- Executar após scripts 01, 02 e 06..24.
-- INSERT IGNORE: idempotente, seguro para re-execução.
--
-- Interface do MÓDULO SUPER (catálogo central setes_central.tb_bank — a
-- tabela já existe no sql/01, DP2 do Software House): módulo banks no
-- app (/home/banks) e /api/banks na API (superGuard por módulo). Sem
-- contrato/flag: o menu do super lê o catálogo direto (grupo 'Super' é
-- exclusivo dele).
--
-- id interno = MAX+1 (convenção do seed 17); número FEBRABAN (3 dígitos)
-- digitado pelo usuário, único — 409 se em uso, mesmo por excluído.
-- =====================================================================

USE `setes_central`;

-- id preferencial 25, mas resolvido dinamicamente (achado do gate
-- adversarial 2026-08-04): numa base onde o 25 já pertence a OUTRA
-- interface (Super cria interfaces por MAX+1), o INSERT IGNORE literal
-- seria ignorado em silêncio e a tela 'banks' nunca nasceria. NOT EXISTS
-- por i18n_key = idempotente; id = MAX(25, MAX+1).
INSERT INTO `tb_interface`
  (`id`, `group_default`, `i18n_key`, `description`, `kind`, `position`, `created_at`, `updated_at`, `deleted`)
SELECT GREATEST(25, (SELECT COALESCE(MAX(i2.`id`), 0) + 1 FROM `tb_interface` i2)),
       'Super', 'banks', 'Bank', 'T', NULL, NOW(), NOW(), 'N'
  FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM `tb_interface` WHERE `i18n_key` = 'banks' AND `deleted` = 'N');

-- Catálogo de CAMPOS da tela (Fase 2 — engine na fábrica). Resolvido por
-- i18n_key (não por id literal): numa base onde o 25 já pertença a outra
-- interface, o INSERT IGNORE da interface é silencioso e o id literal
-- penduraria os campos na tela errada (achado do gate 2026-08-04).
INSERT IGNORE INTO `tb_interface_has_field`
  (`tb_interface_id`, `field_name`, `table_name`, `kind`, `required`, `created_at`, `updated_at`, `deleted`)
SELECT i.`id`, f.`field_name`, 'tb_bank', 'String', 'S', NOW(), NOW(), 'N'
  FROM `tb_interface` i
 CROSS JOIN (SELECT 'number' AS field_name UNION ALL SELECT 'description') f
 WHERE i.`deleted` = 'N'
   AND i.`i18n_key` = 'banks';

-- Paginação (regra do prompt_paginacao_telas_pesquisa.md): lista NOVA nasce
-- paginada — config page_size da interface (mesmo shape do seed 22, que
-- também ganhou a chave na lista canônica para bases novas).
INSERT IGNORE INTO `tb_interface_has_config`
  (`tb_interface_id`, `name`, `description`, `kind`, `options`, `default_content`, `scope`, `created_at`, `updated_at`, `deleted`)
SELECT i.`id`, 'page_size',
       'Número de itens exibidos por página na lista de pesquisa.',
       'Options', '10=10;25=25;50=50;100=100', '25', 'U', NOW(), NOW(), 'N'
  FROM `tb_interface` i
 WHERE i.`deleted` = 'N'
   AND i.`i18n_key` = 'banks';
