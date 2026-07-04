-- =====================================================================
-- Setes API — Fase 2: Gerenciamento Central
-- Script 04 — Limpeza do schema de cliente (setes_<schema>)
-- Remove do schema do cliente tudo o que foi CENTRALIZADO em setes_central,
-- garantindo que as duas bases NÃO tenham as mesmas tabelas.
--
-- ⚠️ ATENÇÃO:
--   1. Rodar UMA VEZ POR CLIENTE, substituindo `setes_setes` pelo schema dele.
--   2. Se o schema tiver dados legados (ex.: base Delphi migrada), migre o que
--      interessa para setes_central ANTES de rodar este script. DROP é definitivo.
--   3. Faça backup (mysqldump) do schema antes de executar.
--   4. NÃO remove tb_customer nem tabelas operacionais do cliente.
-- =====================================================================

USE `setes_setes`;

SET FOREIGN_KEY_CHECKS = 0;

-- Núcleo cadastral (agora exclusivo de setes_central)
DROP TABLE IF EXISTS `tb_entity`;
DROP TABLE IF EXISTS `tb_linebusiness`;
DROP TABLE IF EXISTS `tb_line_business`;
DROP TABLE IF EXISTS `tb_company`;
DROP TABLE IF EXISTS `tb_person`;
DROP TABLE IF EXISTS `tb_address`;
DROP TABLE IF EXISTS `tb_phone`;
DROP TABLE IF EXISTS `tb_social_media`;
DROP TABLE IF EXISTS `tb_mailing`;
DROP TABLE IF EXISTS `tb_mailing_group`;
DROP TABLE IF EXISTS `tb_entity_has_mailing`;

-- Autenticação e licenças (agora exclusivo de setes_central)
DROP TABLE IF EXISTS `tb_user`;
DROP TABLE IF EXISTS `tb_institution`;
DROP TABLE IF EXISTS `tb_institution_has_user`;

-- Interfaces e privilégios (agora exclusivo de setes_central)
DROP TABLE IF EXISTS `tb_privilege`;
DROP TABLE IF EXISTS `tb_interface`;
DROP TABLE IF EXISTS `tb_interface_has_privilege`;

-- Referência geográfica (agora exclusivo de setes_central)
DROP TABLE IF EXISTS `tb_country`;
DROP TABLE IF EXISTS `tb_state`;
DROP TABLE IF EXISTS `tb_city`;

-- Referência fiscal (agora exclusivo de setes_central)
DROP TABLE IF EXISTS `tb_cfop`;
DROP TABLE IF EXISTS `tb_ncm`;
DROP TABLE IF EXISTS `tb_cest`;
DROP TABLE IF EXISTS `tb_tax_icms_nr`;
DROP TABLE IF EXISTS `tb_tax_icms_sn`;
DROP TABLE IF EXISTS `tb_deter_base_tax_icms`;
DROP TABLE IF EXISTS `tb_deter_base_tax_icms_st`;
DROP TABLE IF EXISTS `tb_discharge_icms`;
DROP TABLE IF EXISTS `tb_tax_ipi`;
DROP TABLE IF EXISTS `tb_tax_pis`;
DROP TABLE IF EXISTS `tb_tax_cofins`;

-- Resíduos da Fase 1, se existirem no schema do cliente
DROP TABLE IF EXISTS `tenants`;
DROP TABLE IF EXISTS `feature_flags`;
DROP TABLE IF EXISTS `tb_feature_flag`;

SET FOREIGN_KEY_CHECKS = 1;
