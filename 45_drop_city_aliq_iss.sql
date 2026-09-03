-- =====================================================================
-- Seed 45: D8 da Regra de Tributação de Serviço (2026-09-03) —
-- tb_city.aliq_iss MORRE. A alíquota do ISS vive na tb_service_tax_rule
-- (cidade de incidência × item LC 116), no schema do cliente; UMA alíquota
-- por cidade contradizia a lei (faixas por atividade) e a regra "dado
-- interpretável não se compartilha". O catálogo de campos da tela Cidades
-- perde a linha. MariaDB 10.4: DROP COLUMN IF EXISTS. Idempotente.
-- Canônicos atualizados: sql/01 (DDL), sql/06d (seed sem a coluna), sql/07.
-- =====================================================================

USE `setes_central`;

ALTER TABLE `tb_city` DROP COLUMN IF EXISTS `aliq_iss`;

UPDATE `tb_interface_has_field`
   SET `deleted` = 'S', `updated_at` = NOW()
 WHERE `table_name` = 'tb_city' AND `field_name` = 'aliq_iss' AND `deleted` = 'N';
