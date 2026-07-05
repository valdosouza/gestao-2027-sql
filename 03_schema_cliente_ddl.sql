-- =====================================================================
-- Setes API — Fase 2: Gerenciamento Central
-- Script 03 — DDL do schema de cliente (setes_<schema>)
-- Rodar UMA VEZ POR CLIENTE, substituindo `setes_setes` pelo schema dele.
--
-- REGRA (sem duplicidade com setes_central): o schema do cliente contém
-- APENAS tabelas operacionais e de CONFIGURAÇÃO dele. Cadastro (entity/
-- company/person/address/phone/social_media/mailing), autenticação (user),
-- licenças (institution), catálogo de interfaces/privilégios e TODAS as
-- referências geográficas/fiscais vivem exclusivamente em setes_central.
-- setes-app Fase 1 (decisão 18): configuração por institution vive AQUI —
-- tb_institution_has_interface, tb_module, tb_module_has_interface,
-- tb_user_has_privilege (são escolhas/contrato do institution).
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

-- =====================================================================
-- setes-app Fase 1 (Fundação) — prompt_fase1_fundacao.md
-- Configuração por institution no schema do cliente (decisão 18).
-- Catálogo (tb_interface/tb_privilege) permanece na central — FKs cross-schema.
-- =====================================================================

-- Contrato comercial: interfaces liberadas para o cliente (decisões 17 e 18).
-- Escrita feita pelo módulo Super via institutionId alvo (decisão 23).
-- Coexiste com setes_central.tb_feature_flag (gate técnico de módulos da API — decisão 17).
CREATE TABLE IF NOT EXISTS `tb_institution_has_interface` (
  `tb_institution_id` INT NOT NULL,
  `tb_interface_id`   INT NOT NULL,
  `active`            CHAR(1) DEFAULT NULL,
  `created_at`        DATETIME DEFAULT NULL,
  `updated_at`        DATETIME DEFAULT NULL,
  `deleted`           CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`tb_institution_id`,`tb_interface_id`),
  KEY `idx_ihi_interface` (`tb_interface_id`),
  CONSTRAINT `fk_ihi_to_institution`
    FOREIGN KEY (`tb_institution_id`)
    REFERENCES `setes_central`.`tb_institution` (`id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_ihi_to_interface`
    FOREIGN KEY (`tb_interface_id`)
    REFERENCES `setes_central`.`tb_interface` (`id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- Módulos definidos pelo cliente (menu vertical do shell — decisão 18).
-- id gerado pela aplicação (decisão 7 da Fase 2 — sem AUTO_INCREMENT).
CREATE TABLE IF NOT EXISTS `tb_module` (
  `id`          INT NOT NULL,
  `description` VARCHAR(100) DEFAULT NULL,
  `link_name`   VARCHAR(255) NOT NULL,
  `image_icon`  INT DEFAULT 0,
  `created_at`  DATETIME DEFAULT NULL,
  `updated_at`  DATETIME DEFAULT NULL,
  `deleted`     CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- Detail do módulo: interfaces incluídas (Master-Detail — decisão 18).
-- Uma interface pode estar em mais de um módulo (prompt, seção G).
CREATE TABLE IF NOT EXISTS `tb_module_has_interface` (
  `tb_module_id`    INT NOT NULL,
  `tb_interface_id` INT NOT NULL,
  `active`          CHAR(1) DEFAULT NULL,
  `created_at`      DATETIME DEFAULT NULL,
  `updated_at`      DATETIME DEFAULT NULL,
  `deleted`         CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`tb_module_id`,`tb_interface_id`),
  KEY `idx_mhi_interface` (`tb_interface_id`),
  CONSTRAINT `fk_mhi_to_module`
    FOREIGN KEY (`tb_module_id`)
    REFERENCES `tb_module` (`id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_mhi_to_interface`
    FOREIGN KEY (`tb_interface_id`)
    REFERENCES `setes_central`.`tb_interface` (`id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- Privilégios do usuário por interface (decisão 18; alimenta GET /api/core/menus
-- e os botões Inserir/Alterar/Excluir — decisão 21).
CREATE TABLE IF NOT EXISTS `tb_user_has_privilege` (
  `tb_user_id`      INT NOT NULL,
  `tb_interface_id` INT NOT NULL,
  `tb_privilege_id` INT NOT NULL,
  `active`          CHAR(1) DEFAULT NULL,
  `created_at`      DATETIME DEFAULT NULL,
  `updated_at`      DATETIME DEFAULT NULL,
  `deleted`         CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`tb_user_id`,`tb_interface_id`,`tb_privilege_id`),
  KEY `idx_uhp_interface` (`tb_interface_id`),
  KEY `idx_uhp_privilege` (`tb_privilege_id`),
  CONSTRAINT `fk_uhpriv_to_user`
    FOREIGN KEY (`tb_user_id`)
    REFERENCES `setes_central`.`tb_user` (`id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_uhpriv_to_interface`
    FOREIGN KEY (`tb_interface_id`)
    REFERENCES `setes_central`.`tb_interface` (`id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_uhpriv_to_privilege`
    FOREIGN KEY (`tb_privilege_id`)
    REFERENCES `setes_central`.`tb_privilege` (`id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
