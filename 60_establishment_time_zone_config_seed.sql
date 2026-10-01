-- =====================================================================
-- Seed 60: config `time_zone` da interface 'establishment' — FUSO DO
-- ESTABELECIMENTO (Q-BA14, Valdo 2026-09-30: "criar uma variável no
-- estabelecimento para definir o fuso do sistema como um todo").
--
-- Parecer do guardião (2026-09-30): variável de COMPORTAMENTO do cliente →
-- Framework de Configurações (catálogo aqui, valor em
-- tb_institution_has_config do schema do cliente), scope 'I' (sem nível de
-- usuário — o fuso é do estabelecimento), default America/Sao_Paulo. Zonas
-- IANA; as 4 oficiais do Brasil (UTC-2…-5) — options é varchar(255).
-- Lida pela peça @shared/time-zone. Consumo inicial: critérios de data sobre
-- DATETIME da pesquisa avançada; aplicação no sistema inteiro = fase própria
-- (prompt_pesquisa_avancada.md §10). Idempotente. Executar após o 41.
-- =====================================================================

USE `setes_central`;

INSERT INTO `tb_interface_has_config`
  (`tb_interface_id`, `name`, `description`, `kind`, `options`, `default_content`, `scope`, `created_at`, `updated_at`, `deleted`)
SELECT i.id, 'time_zone', 'Fuso horário do estabelecimento (define o "hoje" e os dias do calendário em todo o sistema)',
       'Options',
       'America/Noronha=Fernando de Noronha (UTC-2);America/Sao_Paulo=Brasília (UTC-3);America/Manaus=AM, MT, MS, RO, RR (UTC-4);America/Rio_Branco=Acre (UTC-5)',
       'America/Sao_Paulo', 'I', NOW(), NOW(), 'N'
  FROM `tb_interface` i
 WHERE i.i18n_key = 'establishment' AND i.deleted = 'N'
   AND NOT EXISTS (SELECT 1 FROM `tb_interface_has_config` c WHERE c.tb_interface_id = i.id AND c.name = 'time_zone');
