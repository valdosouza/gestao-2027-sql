-- =====================================================================
-- Seed de tb_interface_has_field — 5 telas-piloto (setes-app Fase 2,
-- decisão 15): Privileges (2), Interfaces (3), Country (4), State (5),
-- City (6). Gerado por setes-api `npm run fields:gen` em 2026-07-12 e
-- REVISADO manualmente: required elevado a 'S' onde o DTO da API já exige
-- (baseline técnico = DDL NOT NULL ∪ DTO obrigatório — decisão 12).
-- Re-executável: INSERT IGNORE preserva linhas já editadas na base.
-- =====================================================================
USE `setes_central`;

-- Interface do PAINEL Sistema/Admin de campos configuráveis (decisão 6):
-- interface de CLIENTE (não é Super) — módulo interface_fields no app e
-- /api/interface-fields na API. Adquirida pela Setes logo abaixo.
INSERT IGNORE INTO `tb_interface`
  (`id`, `group_default`, `i18n_key`, `description`, `kind`, `position`, `created_at`, `updated_at`, `deleted`)
VALUES
  (7, 'Sistema', 'interface-fields', 'Campos das Interfaces', 'T', NULL, NOW(), NOW(), 'N');

INSERT IGNORE INTO `setes_setes`.`tb_institution_has_interface`
  (`tb_institution_id`, `tb_interface_id`, `active`, `created_at`, `updated_at`, `deleted`)
VALUES
  (1, 7, 'S', NOW(), NOW(), 'N');

-- Interface do cadastro de USUÁRIO (2026-07-12): tela DUAL (workflow do
-- Valdo): Super gerencia qualquer institution; ADMIN do cliente gerencia os
-- do próprio institution pelo módulo Sistema — por isso o grupo é 'Sistema'
-- (grupo 'Super' é EXCLUSIVO do superusuário e some do menu de não-super).
INSERT IGNORE INTO `tb_interface`
  (`id`, `group_default`, `i18n_key`, `description`, `kind`, `position`, `created_at`, `updated_at`, `deleted`)
VALUES
  (8, 'Sistema', 'users', 'Usuários', 'T', NULL, NOW(), NOW(), 'N');

-- Correção idempotente (o INSERT IGNORE não altera linha existente):
-- users saiu do grupo Super (2026-07-12 — admin precisa vê-la no Sistema).
UPDATE `tb_interface` SET `group_default` = 'Sistema', `updated_at` = NOW()
 WHERE `id` = 8 AND `group_default` = 'Super';

-- Contrato da Setes: painel de campos (7) e usuários (8) para o admin.
INSERT IGNORE INTO `setes_setes`.`tb_institution_has_interface`
  (`tb_institution_id`, `tb_interface_id`, `active`, `created_at`, `updated_at`, `deleted`)
VALUES
  (1, 8, 'S', NOW(), NOW(), 'N');

INSERT IGNORE INTO `tb_interface_has_field`
  (`tb_interface_id`, `field_name`, `table_name`, `kind`, `required`, `created_at`, `updated_at`, `deleted`)
VALUES
  -- Privileges (id MAX+1 no backend — travado)
  (2, 'id',            'tb_privilege', 'Integer', 'S', NOW(), NOW(), 'N'),
  (2, 'description',   'tb_privilege', 'String',  'S', NOW(), NOW(), 'N'),  -- DTO min(1)
  -- Interfaces (id MAX+1 no backend — travado)
  (3, 'id',            'tb_interface', 'Integer', 'S', NOW(), NOW(), 'N'),
  (3, 'group_default', 'tb_interface', 'String',  'N', NOW(), NOW(), 'N'),
  (3, 'i18n_key',      'tb_interface', 'String',  'N', NOW(), NOW(), 'N'),
  (3, 'description',   'tb_interface', 'String',  'S', NOW(), NOW(), 'N'),  -- DTO min(1)
  (3, 'kind',          'tb_interface', 'String',  'N', NOW(), NOW(), 'N'),
  (3, 'position',      'tb_interface', 'String',  'N', NOW(), NOW(), 'N'),
  -- Country (id = código BACEN informado pelo usuário)
  (4, 'id',            'tb_country',   'Integer', 'S', NOW(), NOW(), 'N'),
  (4, 'name',          'tb_country',   'String',  'S', NOW(), NOW(), 'N'),  -- DTO min(1)
  -- State (id = código IBGE da UF)
  (5, 'id',            'tb_state',     'Integer', 'S', NOW(), NOW(), 'N'),
  (5, 'tb_country_id', 'tb_state',     'Integer', 'S', NOW(), NOW(), 'N'),
  (5, 'abbreviation',  'tb_state',     'String',  'S', NOW(), NOW(), 'N'),  -- DTO min(1)
  (5, 'name',          'tb_state',     'String',  'S', NOW(), NOW(), 'N'),  -- DTO min(1)
  (5, 'aliquota',      'tb_state',     'Float',   'N', NOW(), NOW(), 'N'),
  -- City (id = código IBGE do município)
  (6, 'id',            'tb_city',      'Integer', 'S', NOW(), NOW(), 'N'),
  (6, 'tb_state_id',   'tb_city',      'Integer', 'S', NOW(), NOW(), 'N'),
  (6, 'ibge',          'tb_city',      'String',  'N', NOW(), NOW(), 'N'),
  (6, 'name',          'tb_city',      'String',  'S', NOW(), NOW(), 'N'),  -- DTO min(1)
  (6, 'aliq_iss',      'tb_city',      'Float',   'S', NOW(), NOW(), 'N'),  -- NOT NULL no DDL
  (6, 'population',    'tb_city',      'Integer', 'N', NOW(), NOW(), 'N'),
  (6, 'density',       'tb_city',      'Float',   'N', NOW(), NOW(), 'N'),
  (6, 'area',          'tb_city',      'Float',   'N', NOW(), NOW(), 'N'),
  -- Users (id MAX+1 da tb_entity no backend — travado; interface reúne
  -- tb_entity + tb_user + tb_mailing, revisão manual sobre o fields:gen).
  -- password required='N' no catálogo: obrigatória SÓ na inclusão (regra do
  -- código — na edição vazia mantém a senha atual).
  (8, 'id',            'tb_user',      'Integer', 'S', NOW(), NOW(), 'N'),
  (8, 'name_company',  'tb_entity',    'String',  'S', NOW(), NOW(), 'N'),  -- DTO min(1)
  (8, 'nick_trade',    'tb_entity',    'String',  'S', NOW(), NOW(), 'N'),  -- DTO min(1)
  (8, 'email',         'tb_mailing',   'String',  'S', NOW(), NOW(), 'N'),  -- login grupo 2
  (8, 'password',      'tb_user',      'String',  'N', NOW(), NOW(), 'N'),
  (8, 'active',        'tb_user',      'Boolean', 'N', NOW(), NOW(), 'N');
