-- =====================================================================
-- Setes API — setes-app Fase 1: Fundação
-- Script 06 — Seed: tb_privilege + tb_interface (catálogo central)
--
-- Executar após scripts 01 e 02.
-- INSERT IGNORE: idempotente, seguro para re-execução.
--
-- NÃO incluídos aqui (com motivo):
--   tb_interface_has_privilege → populado via tela "Interfaces" (módulo Super)
--   tb_module / tb_module_has_interface → vivem no schema do CLIENTE (setes_<schema>),
--     não na central; criados pelo próprio cliente no módulo Sistema
--   tb_institution_has_interface → vivem no schema do CLIENTE; gerenciados
--     pelo Super via /api/admin/institutions/:id/interfaces
--
-- Geo (Países / Estados / Cidades) → scripts separados:
--   06b_geo_country.sql
--   06c_geo_state.sql
--   06d_geo_city.sql
-- =====================================================================

USE `setes_central`;

-- ---------------------------------------------------------------------
-- 1. Privilégios (fonte: seed/tb_privilege.sql)
-- ---------------------------------------------------------------------

INSERT IGNORE INTO `tb_privilege` (`id`, `description`, `created_at`, `updated_at`, `deleted`) VALUES
(1, 'INSERIR',    '2018-12-25 23:49:22', '2018-12-25 23:49:22', 'N'),
(2, 'ALTERAR',    '2018-12-25 23:49:27', '2018-12-25 23:49:27', 'N'),
(3, 'EXCLUIR',    '2018-12-25 23:49:32', '2018-12-25 23:49:32', 'N'),
(4, 'IMPRIMIR',   '2018-12-25 23:50:53', '2018-12-25 23:50:53', 'N'),
(5, 'FATURAR',    '2018-12-25 23:51:01', '2018-12-25 23:51:01', 'N'),
(6, 'VISUALIZAR', '2018-12-25 23:51:42', '2018-12-25 23:51:42', 'N');

-- ---------------------------------------------------------------------
-- 2. Interfaces do módulo Super (fonte: seed/tb_interface.sql)
--
-- group_default = 'Super' → aparece como pseudo-módulo no menu do app
--   (GET /api/core/menus faz UNION com interfaces sem tb_module, agrupando
--   por group_default — decisão 21 do prompt_fase1_fundacao.md)
-- i18n_key → chave de tradução em menu.interfaces.<key> (decisão 26)
--
-- id 1 (institutions): tela de gestão de clientes — populada via UI do Super
-- id 2 (privileges)  : CRUD de tb_privilege — populada via UI do Super
-- id 3 (interfaces)  : CRUD de tb_interface + tb_interface_has_privilege — via UI
-- id 4 (countries)   : CRUD de tb_country — primeiras telas a serem criadas
-- id 5 (states)      : CRUD de tb_state
-- id 6 (cities)      : CRUD de tb_city
-- ---------------------------------------------------------------------

INSERT IGNORE INTO `tb_interface` (`id`, `group_default`, `i18n_key`, `description`, `kind`, `position`, `created_at`, `updated_at`, `deleted`) VALUES
(1, 'Super', 'institutions', 'Institution', 'T', NULL, '2026-07-05 22:06:19', '2026-07-05 22:06:19', 'N'),
(2, 'Super', 'privileges',   'Privilege',   'T', '2',  '2026-07-05 22:09:33', '2026-07-05 22:09:33', 'N'),
(3, 'Super', 'interfaces',   'Interfaces',  'T', '3',  '2026-07-05 22:10:48', '2026-07-05 22:10:48', 'N'),
(4, 'Super', 'countries',    'Country',     'T', '4',  '2026-07-05 22:11:39', '2026-07-05 22:11:39', 'N'),
(5, 'Super', 'states',       'State',       'T', '5',  '2026-07-05 22:12:14', '2026-07-05 22:12:14', 'N'),
(6, 'Super', 'cities',       'City',        'T', '6',  '2026-07-05 22:15:51', '2026-07-05 22:15:51', 'N');
