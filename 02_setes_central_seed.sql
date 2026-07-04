-- =====================================================================
-- Setes API — Fase 2: Gerenciamento Central
-- Script 02 — Seed: dados padrão + superusuário (rodar após o script 01)
-- =====================================================================

USE `setes_central`;

-- ---------------------------------------------------------------------
-- Tipos de email
-- ---------------------------------------------------------------------
INSERT INTO `tb_mailing_group` (`id`,`description`,`created_at`,`updated_at`) VALUES
  (1,'principal',NOW(),NOW()),
  (2,'sistema',NOW(),NOW()),
  (3,'nfe',NOW(),NOW()),
  (4,'contato',NOW(),NOW());

-- ---------------------------------------------------------------------
-- Geografia mínima para o endereço do seed
-- (carga completa de países/estados/cidades: rotina de importação futura)
-- ---------------------------------------------------------------------
INSERT INTO `tb_country` (`id`,`name`,`created_at`,`updated_at`) VALUES
  (1058,'Brasil',NOW(),NOW());

INSERT INTO `tb_state` (`id`,`tb_country_id`,`abbreviation`,`name`,`aliquota`,`created_at`,`updated_at`) VALUES
  (41,1058,'PR','Paraná',NULL,NOW(),NOW());

INSERT INTO `tb_city` (`id`,`tb_state_id`,`ibge`,`name`,`created_at`,`updated_at`) VALUES
  (4004,41,'4106902','Curitiba',NOW(),NOW());

-- ---------------------------------------------------------------------
-- Superusuário: Setes (entity 1 = company = institution 1)
-- ---------------------------------------------------------------------
INSERT INTO `tb_entity` (`id`,`name_company`,`nick_trade`,`aniversary`,`created_at`,`updated_at`,`tb_linebusiness_id`,`note`)
VALUES (1,'F. D. SOUZA DESENVOLVIMENTO E LICENCIAMENTO DE PROGRAMAS','GESTAO COMPUTACIONAL SETES',NULL,'2024-01-19 00:00:00','2026-04-16 14:07:54',NULL,NULL);

INSERT INTO `tb_company` (`id`,`cnpj`,`ie`,`im`,`iest`,`dt_foundation`,`crt`,`crt_modal`,`ind_ie_destinatario`,`created_at`,`updated_at`,`iss_ind_exig`,`iss_retencao`,`iss_inc_fiscal`,`iss_process_number`,`send_xml_nfe_only`)
VALUES (1,'07742094000113',NULL,NULL,NULL,'2018-05-11','3','N','1',NOW(),'2024-01-19 08:54:37','01','N','N','0','N');

INSERT INTO `tb_address` (`id`,`kind`,`street`,`nmbr`,`complement`,`neighborhood`,`region`,`zip_code`,`tb_country_id`,`tb_state_id`,`tb_city_id`,`main`,`longitude`,`latitude`,`created_at`,`updated_at`)
VALUES (1,'COMERCIAL','RUA FAUSTINO JACOB STOFELLA','28','','ALTO BOQUEIRAO',NULL,'81770090',1058,41,4004,'S',NULL,NULL,'2024-01-19 08:54:37','2026-04-16 14:07:54');

INSERT INTO `tb_mailing` (`id`,`email`,`created_at`,`updated_at`)
VALUES (1,'valdo@setes.com.br',NOW(),'2026-04-16 14:07:54');

-- Grupo 1 = principal; grupo 2 = sistema (login)
INSERT INTO `tb_entity_has_mailing` (`tb_entity_id`,`tb_mailing_id`,`tb_mailing_group_id`,`created_at`,`updated_at`) VALUES
  (1,1,1,'2026-04-16 14:07:54','2026-04-16 14:07:54'),
  (1,1,2,NOW(),'2022-04-26 14:10:14');

-- Senha MD5 (decisão 2: manter MD5, sem salt)
INSERT INTO `tb_user` (`id`,`password`,`active`,`activation_key`,`created_at`,`updated_at`)
VALUES (1,'827CCB0EEA8A706C4C34A16891F84E7B','S',NULL,NOW(),'2022-04-26 14:10:14');

-- Setes como institution 1 (decisão 12: setes_setes)
INSERT INTO `tb_institution` (`id`,`schema_name`,`active`,`created_at`,`updated_at`)
VALUES (1,'setes_setes','S',NOW(),NOW());

-- Perfil 'super' — só reconhecido na institution 1 (decisões 8 e 14)
INSERT INTO `tb_institution_has_user` (`tb_institution_id`,`tb_user_id`,`kind`,`active`,`created_at`,`updated_at`)
VALUES (1,1,'super','S',NOW(),NOW());
