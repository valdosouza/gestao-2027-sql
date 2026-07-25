-- =====================================================================
-- Framework de Configurações do Sistema — Seed
-- (prompt_framework_configuracoes_sistema.md, decisões 3, 9, 10 e 14)
--
-- Executar após scripts 01, 02, 06, 07 e 08.
-- INSERT IGNORE: idempotente, seguro para re-execução.
--
-- id 10 (interface-configs): PAINEL do cliente — vitrine de configurações
--   por interface (módulo interface_configs no app, /api/interface-configs
--   na API). Grupo 'Sistema' (decisão 9 — precedente: interfaces 7 e 8).
-- id 11 (general-configs): interface "Configurações Gerais" — dona das
--   configurações sem tela própria (decisão 3: tb_interface_id permanece
--   NOT NULL, zero caso especial). Contratável como qualquer outra.
-- =====================================================================

USE `setes_central`;

-- Normalização idempotente da coluna kind (decisão 13): valores legados
-- (ex.: 'N' dos seeds antigos) viram 'T' = tela. O INSERT IGNORE dos seeds
-- não altera linha existente — este UPDATE corrige bases já povoadas.
-- O aperto do TIPO (varchar(26) → char(1) NOT NULL DEFAULT 'T') é feito
-- pelo bootstrap-db.ts (precisa de checagem no information_schema).
UPDATE `tb_interface`
   SET `kind` = 'T', `updated_at` = NOW()
 WHERE `kind` IS NULL OR `kind` NOT IN ('T', 'R');

INSERT IGNORE INTO `tb_interface`
  (`id`, `group_default`, `i18n_key`, `description`, `kind`, `position`, `created_at`, `updated_at`, `deleted`)
VALUES
  (10, 'Sistema', 'interface-configs', 'Configurações das Interfaces', 'T', NULL, NOW(), NOW(), 'N'),
  (11, 'Sistema', 'general-configs',   'Configurações Gerais',         'T', NULL, NOW(), NOW(), 'N');

-- Contrato da Setes: painel (10) e Configurações Gerais (11).
-- Para outros clientes o Super concede pela aba Interfaces do Institution.
INSERT IGNORE INTO `setes_setes`.`tb_institution_has_interface`
  (`tb_institution_id`, `tb_interface_id`, `active`, `created_at`, `updated_at`, `deleted`)
VALUES
  (1, 10, 'S', NOW(), NOW(), 'N'),
  (1, 11, 'S', NOW(), NOW(), 'N');

-- ---------------------------------------------------------------------
-- Piloto — 3 configs da tela Clientes (interface 9, decisões 10, 14 e 15).
-- ATENÇÃO (regra do Valdo, 2026-07-18): description é o RÓTULO visto pelo
-- cliente no painel — NUNCA citar sistema legado/nomes técnicos de origem
-- em conteúdo visível do sistema (rastreio de origem fica na documentação).
-- ---------------------------------------------------------------------
INSERT IGNORE INTO `tb_interface_has_config`
  (`tb_interface_id`, `name`, `description`, `kind`, `options`, `default_content`, `scope`, `created_at`, `updated_at`, `deleted`)
VALUES
  (9, 'restrict_customer_to_salesman',
   'Restringe o usuário-vendedor à própria carteira de clientes (lista e consulta).',
   'Boolean', NULL, 'N', 'I', NOW(), NOW(), 'N'),
  (9, 'default_person_type',
   'Tipo de pessoa pré-selecionado ao abrir um cadastro novo de cliente (predominância da carteira).',
   'Options', 'F=Pessoa Física;J=Pessoa Jurídica', 'J', 'U', NOW(), NOW(), 'N'),
  (9, 'default_customer_kind',
   'Tipo de cliente pré-preenchido na aba Tributação do cadastro novo (Consumidor Final ou Revenda).',
   'Options', 'C=Consumidor;R=Revenda', 'R', 'U', NOW(), NOW(), 'N');

-- Correção idempotente para bases já povoadas (o INSERT IGNORE não altera
-- linha existente): remove referências ao sistema legado das descriptions.
UPDATE `tb_interface_has_config`
   SET `description` = 'Restringe o usuário-vendedor à própria carteira de clientes (lista e consulta).', `updated_at` = NOW()
 WHERE `tb_interface_id` = 9 AND `name` = 'restrict_customer_to_salesman'
   AND `description` <> 'Restringe o usuário-vendedor à própria carteira de clientes (lista e consulta).';
UPDATE `tb_interface_has_config`
   SET `description` = 'Tipo de pessoa pré-selecionado ao abrir um cadastro novo de cliente (predominância da carteira).', `updated_at` = NOW()
 WHERE `tb_interface_id` = 9 AND `name` = 'default_person_type'
   AND `description` <> 'Tipo de pessoa pré-selecionado ao abrir um cadastro novo de cliente (predominância da carteira).';
UPDATE `tb_interface_has_config`
   SET `description` = 'Tipo de cliente pré-preenchido na aba Tributação do cadastro novo (Consumidor Final ou Revenda).', `updated_at` = NOW()
 WHERE `tb_interface_id` = 9 AND `name` = 'default_customer_kind'
   AND `description` <> 'Tipo de cliente pré-preenchido na aba Tributação do cadastro novo (Consumidor Final ou Revenda).';
