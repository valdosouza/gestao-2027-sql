-- =====================================================================
-- Seed: interface 'cfop' — CFOP (suporte à emissão de nota)
-- (pedido do Valdo 2026-07-18)
--
-- Executar após scripts 01, 02 e 06..12.
-- INSERT IGNORE: idempotente, seguro para re-execução.
--
-- Interface do MÓDULO SUPER (catálogo central setes_central.tb_cfop — a
-- tabela já existe no sql/01, seção "Referência fiscal"): módulo cfop no
-- app (/home/cfop) e /api/cfop na API (superGuard por módulo). Sem
-- contrato/flag: o menu do super lê o catálogo direto (grupo 'Super' é
-- exclusivo dele).
--
-- id = o PRÓPRIO código CFOP (varchar 10, informado pelo usuário — padrão
-- de código externo: 409 se já existir, imutável na edição).
-- Semântica (reg_cfop.pas/ControllerNatureza.pas): way = Sentido
-- E(ntrada)/S(aída); jurisdiction = Alçada E(stadual)/N(acional)/X(terior);
-- register = "Registro" (inteiro livre); note = "Aplicação" (texto longo).
-- =====================================================================

USE `setes_central`;

INSERT IGNORE INTO `tb_interface`
  (`id`, `group_default`, `i18n_key`, `description`, `kind`, `position`, `created_at`, `updated_at`, `deleted`)
VALUES
  (15, 'Super', 'cfop', 'CFOP', 'T', NULL, NOW(), NOW(), 'N');

-- Catálogo de CAMPOS da tela (Fase 2 — engine na fábrica).
INSERT IGNORE INTO `tb_interface_has_field`
  (`tb_interface_id`, `field_name`, `table_name`, `kind`, `required`, `created_at`, `updated_at`, `deleted`)
VALUES
  (15, 'id',           'tb_cfop', 'String',  'S', NOW(), NOW(), 'N'),  -- código CFOP digitado
  (15, 'description',  'tb_cfop', 'String',  'S', NOW(), NOW(), 'N'),  -- DTO min(1)
  (15, 'concise',      'tb_cfop', 'String',  'N', NOW(), NOW(), 'N'),
  (15, 'register',     'tb_cfop', 'Integer', 'N', NOW(), NOW(), 'N'),
  (15, 'way',          'tb_cfop', 'String',  'N', NOW(), NOW(), 'N'),
  (15, 'jurisdiction', 'tb_cfop', 'String',  'N', NOW(), NOW(), 'N'),
  (15, 'note',         'tb_cfop', 'String',  'N', NOW(), NOW(), 'N'),
  (15, 'active',       'tb_cfop', 'Boolean', 'N', NOW(), NOW(), 'N');
