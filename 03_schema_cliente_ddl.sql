-- =====================================================================
-- Setes API — Fase 2: Gerenciamento Central
-- Script 03 — DDL do schema de cliente (setes_<schema>)
-- Rodar UMA VEZ POR CLIENTE, substituindo `setes_setes` pelo schema dele.
--
-- REGRA (sem duplicidade com setes_central): o schema do cliente contém
-- APENAS tabelas operacionais dele. Cadastro (entity/company/person/address/
-- phone/social_media/mailing), autenticação (user), licenças (institution),
-- interfaces/privilégios e TODAS as referências geográficas/fiscais vivem
-- exclusivamente em setes_central.
-- =====================================================================

CREATE DATABASE IF NOT EXISTS `setes_setes` DEFAULT CHARSET = utf8mb4;
USE `setes_setes`;

-- Customer: especialização local da entity central (herança por PK — decisão 1)
CREATE TABLE IF NOT EXISTS `tb_customer` (
  `id`                INT NOT NULL,
  `tb_institution_id` INT NOT NULL,
  `tb_salesman_id`    INT DEFAULT NULL,
  `tb_carrier_id`     INT DEFAULT NULL,      -- FK/índice: implementação futura (decisão 11)
  `credit_status`     CHAR(1) DEFAULT NULL,
  `credit_value`      DECIMAL(10,2) DEFAULT NULL,
  `wallet`            CHAR(1) DEFAULT NULL,
  `consumer`          CHAR(1) DEFAULT NULL,
  `multiplier`        DECIMAL(10,2) DEFAULT NULL,
  `by_pass_st`        CHAR(1) DEFAULT NULL,
  `active`            CHAR(1) DEFAULT NULL,
  `created_at`        DATETIME DEFAULT NULL,
  `updated_at`        DATETIME DEFAULT NULL,
  `deleted`           CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`, `tb_institution_id`),
  KEY `idx_tb_customer_institution` (`tb_institution_id`),
  KEY `idx_tb_customer_salesman` (`tb_salesman_id`),
  CONSTRAINT `fk_tb_customer_entity`
    FOREIGN KEY (`id`)
    REFERENCES `setes_central`.`tb_entity` (`id`)      -- cross-schema: entity vive na central
    ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_tb_customer_institution`
    FOREIGN KEY (`tb_institution_id`)
    REFERENCES `setes_central`.`tb_institution` (`id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_tb_customer_salesman`
    FOREIGN KEY (`tb_salesman_id`)
    REFERENCES `setes_central`.`tb_entity` (`id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
