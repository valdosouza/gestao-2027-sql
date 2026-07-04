-- =====================================================================
-- Setes API — Fase 2: Gerenciamento Central
-- Script 01 — DDL da base setes_central (ordem de dependência)
-- Fonte: Prompt - Fase 2 - Gerenciamento Central.md (19 decisões registradas)
-- Constraints consolidadas no CREATE TABLE para o script ser re-executável
-- (IF NOT EXISTS). IDs gerados pela aplicação (decisão 7 — sem AUTO_INCREMENT).
-- =====================================================================

CREATE DATABASE IF NOT EXISTS `setes_central` DEFAULT CHARSET = utf8mb4;
USE `setes_central`;

-- ---------------------------------------------------------------------
-- Núcleo cadastral
-- ---------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `tb_linebusiness` (
  `id`          int(11) NOT NULL,
  `description` varchar(100) DEFAULT NULL,
  `created_at`  datetime NOT NULL,
  `updated_at`  datetime NOT NULL,
  `deleted`     char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Entidade: todo mundo que usa o sistema (usuário/institution/customer/provider/carrier/bank...)
CREATE TABLE IF NOT EXISTS `tb_entity` (
  `id`                 int(11) NOT NULL,
  `name_company`       varchar(100) DEFAULT '',
  `nick_trade`         varchar(100) DEFAULT '',
  `aniversary`         date DEFAULT NULL,
  `created_at`         datetime NOT NULL,
  `updated_at`         datetime NOT NULL,
  `tb_linebusiness_id` int(11) DEFAULT NULL,
  `note`               blob DEFAULT NULL,
  `deleted`            char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`),
  KEY `nick_trade` (`nick_trade`),
  KEY `name_company` (`name_company`),
  KEY `fk_entity_to_linebusiness` (`tb_linebusiness_id`),
  CONSTRAINT `fk_entity_to_linebusiness` FOREIGN KEY (`tb_linebusiness_id`) REFERENCES `tb_linebusiness` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Emails centralizados (sem repetição)
CREATE TABLE IF NOT EXISTS `tb_mailing` (
  `id`         int(11) NOT NULL,
  `email`      varchar(100) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `deleted`    char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tipos de email: principal / sistema (login) / nfe / contato
CREATE TABLE IF NOT EXISTS `tb_mailing_group` (
  `id`          int(11) NOT NULL,
  `description` varchar(100) DEFAULT NULL,
  `created_at`  datetime NOT NULL,
  `updated_at`  datetime NOT NULL,
  `deleted`     char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- N:N — uma entidade usa o mesmo email para várias situações
CREATE TABLE IF NOT EXISTS `tb_entity_has_mailing` (
  `tb_entity_id`        int(11) NOT NULL,
  `tb_mailing_id`       int(11) NOT NULL,
  `tb_mailing_group_id` int(11) NOT NULL,
  `created_at`          datetime NOT NULL,
  `updated_at`          datetime NOT NULL,
  `deleted`             char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`tb_entity_id`,`tb_mailing_id`,`tb_mailing_group_id`),
  KEY `tb_mailing_id` (`tb_mailing_id`),
  KEY `tb_mailing_group_id` (`tb_mailing_group_id`),
  CONSTRAINT `fk_ehm_to_entity`        FOREIGN KEY (`tb_entity_id`)        REFERENCES `tb_entity` (`id`),
  CONSTRAINT `fk_ehm_to_mailing`       FOREIGN KEY (`tb_mailing_id`)       REFERENCES `tb_mailing` (`id`),
  CONSTRAINT `fk_ehm_to_mailing_group` FOREIGN KEY (`tb_mailing_group_id`) REFERENCES `tb_mailing_group` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- Autenticação (tb_user controla SOMENTE autenticação — decisão 10)
-- Senha MD5, sem salt (decisão 2). 1 registro por entity.
-- ---------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `tb_user` (
  `id`             int(11) NOT NULL,
  `password`       varchar(100) DEFAULT NULL,
  `active`         char(1) NOT NULL DEFAULT 'S',
  `activation_key` varchar(255) DEFAULT NULL,
  `created_at`     datetime DEFAULT NULL,
  `updated_at`     datetime DEFAULT NULL,
  `deleted`        char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_user_to_entity` FOREIGN KEY (`id`) REFERENCES `tb_entity` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- Especializações fiscais da entidade (herança por PK compartilhada — decisão 1)
-- ---------------------------------------------------------------------

-- PJ (preenchida quando a UI informar Pessoa Jurídica com CNPJ válido)
CREATE TABLE IF NOT EXISTS `tb_company` (
  `id`                  int(11) NOT NULL,
  `cnpj`                char(14) NOT NULL DEFAULT '0',
  `ie`                  varchar(45) DEFAULT NULL,
  `im`                  varchar(45) DEFAULT NULL,
  `iest`                varchar(45) DEFAULT NULL,
  `dt_foundation`       date DEFAULT NULL,
  `crt`                 char(1) DEFAULT NULL,
  `crt_modal`           char(1) DEFAULT NULL,
  `ind_ie_destinatario` varchar(1) DEFAULT NULL,
  `created_at`          datetime NOT NULL,
  `updated_at`          datetime NOT NULL,
  `iss_ind_exig`        char(2) DEFAULT NULL,
  `iss_retencao`        char(1) DEFAULT NULL,
  `iss_inc_fiscal`      char(1) DEFAULT NULL,
  `iss_process_number`  varchar(50) DEFAULT NULL,
  `send_xml_nfe_only`   char(1) DEFAULT NULL,
  `deleted`             char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`),
  UNIQUE KEY `cnpj` (`cnpj`),
  CONSTRAINT `fk_company_to_entity` FOREIGN KEY (`id`) REFERENCES `tb_entity` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- PF (preenchida quando a UI informar Pessoa Física com CPF válido)
CREATE TABLE IF NOT EXISTS `tb_person` (
  `id`               int(11) NOT NULL,
  `cpf`              char(11) NOT NULL,
  `rg`               char(20) DEFAULT NULL,
  `rg_dt_emission`   date DEFAULT NULL,
  `rg_organ_issuer`  varchar(45) DEFAULT NULL,
  `rg_state_issuer`  int(11) DEFAULT NULL,
  `birthday`         date DEFAULT NULL,
  `tb_profession_id` int(11) DEFAULT NULL,
  `created_at`       datetime DEFAULT NULL,
  `updated_at`       datetime DEFAULT NULL,
  `deleted`          char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`),
  UNIQUE KEY `cpf` (`cpf`),
  CONSTRAINT `fk_person_to_entity` FOREIGN KEY (`id`) REFERENCES `tb_entity` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- Referência geográfica (antes de tb_address, que depende delas)
-- ---------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `tb_country` (
  `id`         int(11) NOT NULL,
  `name`       varchar(100) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted`    char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tb_state` (
  `id`            int(11) NOT NULL,
  `tb_country_id` int(11) NOT NULL,
  `abbreviation`  varchar(2) DEFAULT NULL,
  `name`          varchar(100) DEFAULT NULL,
  `aliquota`      decimal(10,2) DEFAULT NULL,
  `created_at`    datetime DEFAULT NULL,
  `updated_at`    datetime DEFAULT NULL,
  `deleted`       char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`),
  KEY `fk_state_to_country` (`tb_country_id`),
  CONSTRAINT `fk_state_to_country` FOREIGN KEY (`tb_country_id`) REFERENCES `tb_country` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tb_city` (
  `id`          int(11) NOT NULL,
  `tb_state_id` int(11) NOT NULL,
  `ibge`        varchar(20) DEFAULT NULL,
  `name`        varchar(100) DEFAULT NULL,
  `aliq_iss`    decimal(10,2) NOT NULL DEFAULT 0.00,
  `population`  int(11) DEFAULT 0,
  `density`     decimal(10,2) DEFAULT 0.00,
  `area`        decimal(10,2) DEFAULT 0.00,
  `created_at`  datetime DEFAULT NULL,
  `updated_at`  datetime DEFAULT NULL,
  `deleted`     char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`),
  KEY `fk_city_to_state` (`tb_state_id`),
  CONSTRAINT `fk_city_to_state` FOREIGN KEY (`tb_state_id`) REFERENCES `tb_state` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- Complementos da entidade
-- ---------------------------------------------------------------------

-- Vários endereços por entidade, desde que de kind diferente (decisão 3)
CREATE TABLE IF NOT EXISTS `tb_address` (
  `id`            int(11) NOT NULL,
  `kind`          varchar(100) NOT NULL DEFAULT 'COMERCIAL',
  `street`        varchar(100) NOT NULL,
  `nmbr`          varchar(10) DEFAULT 'sn',
  `complement`    varchar(100) DEFAULT NULL,
  `neighborhood`  varchar(100) DEFAULT NULL,
  `region`        varchar(100) DEFAULT NULL,
  `zip_code`      varchar(15) DEFAULT NULL,
  `tb_country_id` int(11) NOT NULL,
  `tb_state_id`   int(11) NOT NULL,
  `tb_city_id`    int(11) NOT NULL,
  `main`          char(1) NOT NULL DEFAULT 'S',
  `longitude`     varchar(20) DEFAULT NULL,
  `latitude`      varchar(20) DEFAULT NULL,
  `created_at`    datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at`    datetime NOT NULL,
  `deleted`       char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`,`kind`),
  KEY `fk_country_to_address` (`tb_country_id`),
  KEY `fk_state_to_address` (`tb_state_id`),
  KEY `fk_city_to_address` (`tb_city_id`),
  CONSTRAINT `fk_address_to_entity`  FOREIGN KEY (`id`)            REFERENCES `tb_entity` (`id`),
  CONSTRAINT `fk_country_to_address` FOREIGN KEY (`tb_country_id`) REFERENCES `tb_country` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_state_to_address`   FOREIGN KEY (`tb_state_id`)   REFERENCES `tb_state` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_city_to_address`    FOREIGN KEY (`tb_city_id`)    REFERENCES `tb_city` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tb_phone` (
  `id`           int(11) NOT NULL,
  `kind`         varchar(20) NOT NULL,
  `contact`      varchar(100) DEFAULT NULL,
  `number`       varchar(20) DEFAULT NULL,
  `address_kind` varchar(100) DEFAULT '',
  `created_at`   datetime DEFAULT NULL,
  `updated_at`   datetime DEFAULT NULL,
  `deleted`      char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`,`kind`),
  CONSTRAINT `fk_phone_to_entity` FOREIGN KEY (`id`) REFERENCES `tb_entity` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tb_social_media` (
  `id`         int(11) NOT NULL,
  `kind`       varchar(50) NOT NULL,
  `link`       varchar(100) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `deleted`    char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`,`kind`),
  CONSTRAINT `fk_social_media_to_entity` FOREIGN KEY (`id`) REFERENCES `tb_entity` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- Institution (substitui `tenants` — decisão 4) e vínculo com usuário
-- Licenças controladas por `active` (decisão 9)
-- ---------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `tb_institution` (
  `id`          int(11) NOT NULL,
  `schema_name` varchar(100) NOT NULL,
  `active`      char(1) DEFAULT NULL,
  `created_at`  datetime DEFAULT NULL,
  `updated_at`  datetime DEFAULT NULL,
  `deleted`     char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`),
  UNIQUE KEY `schema_name` (`schema_name`),
  CONSTRAINT `fk_institution_to_entity` FOREIGN KEY (`id`) REFERENCES `tb_entity` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- `kind` = perfil do usuário NAQUELA institution (decisão 10).
-- 'super' só vale na institution 1 / Setes — hard coded no backend (decisão 14).
CREATE TABLE IF NOT EXISTS `tb_institution_has_user` (
  `tb_institution_id` int(11) NOT NULL,
  `tb_user_id`        int(11) NOT NULL,
  `kind`              varchar(20) DEFAULT NULL,
  `active`            char(1) DEFAULT NULL,
  `created_at`        datetime DEFAULT NULL,
  `updated_at`        datetime DEFAULT NULL,
  `deleted`           char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`tb_institution_id`,`tb_user_id`),
  KEY `tb_user_id` (`tb_user_id`),
  CONSTRAINT `fk_ihu_to_institution` FOREIGN KEY (`tb_institution_id`) REFERENCES `tb_institution` (`id`),
  CONSTRAINT `fk_ihu_to_user`        FOREIGN KEY (`tb_user_id`)        REFERENCES `tb_user` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- Interfaces e privilégios (ponte perfil × privilégio: implementação futura — decisão 15)
-- ---------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `tb_privilege` (
  `id`          int(11) NOT NULL,
  `description` varchar(100) DEFAULT NULL,
  `created_at`  datetime DEFAULT NULL,
  `updated_at`  datetime DEFAULT NULL,
  `deleted`     char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tb_interface` (
  `id`            int(11) NOT NULL,
  `group_default` varchar(100) DEFAULT NULL,
  `description`   varchar(100) DEFAULT NULL,
  `kind`          varchar(26) DEFAULT NULL,
  `position`      varchar(10) DEFAULT NULL,
  `img_index`     int(11) NOT NULL,
  `button_action` varchar(100) DEFAULT NULL,
  `created_at`    datetime DEFAULT NULL,
  `updated_at`    datetime DEFAULT NULL,
  `deleted`       char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`),
  KEY `position` (`position`),
  KEY `kind` (`kind`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tb_interface_has_privilege` (
  `tb_interface_id` int(11) NOT NULL,
  `tb_privilege_id` int(11) NOT NULL,
  `active`          char(1) DEFAULT NULL,
  `created_at`      datetime DEFAULT NULL,
  `updated_at`      datetime DEFAULT NULL,
  `deleted`         char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`tb_interface_id`,`tb_privilege_id`),
  KEY `tb_privilege_id` (`tb_privilege_id`),
  CONSTRAINT `tb_interface_has_privilege_ibfk_1` FOREIGN KEY (`tb_interface_id`) REFERENCES `tb_interface` (`id`),
  CONSTRAINT `tb_interface_has_privilege_ibfk_2` FOREIGN KEY (`tb_privilege_id`) REFERENCES `tb_privilege` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- Referência fiscal
-- ---------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `tb_cfop` (
  `id`           varchar(10) NOT NULL,
  `description`  varchar(100) DEFAULT NULL,
  `concise`      varchar(60) DEFAULT NULL,
  `active`       char(1) DEFAULT NULL,
  `register`     int(11) DEFAULT NULL,
  `way`          varchar(1) DEFAULT NULL,
  `jurisdiction` varchar(1) DEFAULT NULL,
  `note`         blob DEFAULT NULL,
  `created_at`   datetime DEFAULT NULL,
  `updated_at`   datetime DEFAULT NULL,
  `deleted`      char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tb_ncm` (
  `number`      varchar(10) NOT NULL,
  `description` varchar(150) DEFAULT NULL,
  `exc`         varchar(5) DEFAULT NULL,
  `tabela`      int(11) DEFAULT NULL,
  `aliq_nac`    decimal(10,3) DEFAULT NULL,
  `aliq_imp`    decimal(10,3) DEFAULT NULL,
  `aliq_est`    decimal(10,3) DEFAULT NULL,
  `aliq_mun`    decimal(10,3) DEFAULT NULL,
  `deleted`     char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tb_cest` (
  `cest`        varchar(7) NOT NULL,
  `ncm`         varchar(8) DEFAULT NULL,
  `description` varchar(200) DEFAULT NULL,
  `deleted`     char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`cest`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tb_tax_icms_nr` (
  `id`          char(2) NOT NULL DEFAULT '',
  `description` varchar(100) DEFAULT NULL,
  `created_at`  datetime DEFAULT NULL,
  `updated_at`  datetime DEFAULT NULL,
  `deleted`     char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tb_tax_icms_sn` (
  `id`          char(3) NOT NULL DEFAULT '',
  `description` varchar(100) DEFAULT NULL,
  `created_at`  datetime DEFAULT NULL,
  `updated_at`  datetime DEFAULT NULL,
  `deleted`     char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tb_deter_base_tax_icms` (
  `id`          char(2) NOT NULL DEFAULT '',
  `description` varchar(100) DEFAULT NULL,
  `created_at`  datetime DEFAULT NULL,
  `updated_at`  datetime DEFAULT NULL,
  `deleted`     char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tb_deter_base_tax_icms_st` (
  `id`          char(2) NOT NULL DEFAULT '',
  `description` varchar(100) DEFAULT NULL,
  `created_at`  datetime DEFAULT NULL,
  `updated_at`  datetime DEFAULT NULL,
  `deleted`     char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tb_discharge_icms` (
  `id`          int(11) NOT NULL,
  `description` varchar(100) DEFAULT NULL,
  `created_at`  datetime DEFAULT NULL,
  `updated_at`  datetime DEFAULT NULL,
  `deleted`     char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tb_tax_ipi` (
  `id`          char(2) NOT NULL DEFAULT '',
  `description` varchar(100) DEFAULT NULL,
  `created_at`  datetime DEFAULT NULL,
  `updated_at`  datetime DEFAULT NULL,
  `deleted`     char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tb_tax_pis` (
  `id`          char(2) NOT NULL DEFAULT '',
  `description` varchar(100) DEFAULT NULL,
  `created_at`  datetime DEFAULT NULL,
  `updated_at`  datetime DEFAULT NULL,
  `deleted`     char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tb_tax_cofins` (
  `id`          char(2) NOT NULL DEFAULT '',
  `description` varchar(100) DEFAULT NULL,
  `created_at`  datetime DEFAULT NULL,
  `updated_at`  datetime DEFAULT NULL,
  `deleted`     char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- Feature flags (Fase 1) — padronizada com prefixo tb_ (objetivo 2)
-- e indexada por institution (decisão 16). `enabled` continua BOOLEAN
-- para não quebrar o flag.service da Fase 1.
-- ⚠️ Ajustar flag.repository.ts: FROM tb_feature_flag WHERE tb_institution_id = ?
-- ---------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `tb_feature_flag` (
  `id`                int(11) NOT NULL,
  `tb_institution_id` int(11) NOT NULL,
  `module_key`        varchar(100) NOT NULL,
  `enabled`           boolean NOT NULL DEFAULT FALSE,
  `created_at`        datetime DEFAULT NULL,
  `updated_at`        datetime DEFAULT NULL,
  `deleted`           char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_institution_module` (`tb_institution_id`,`module_key`),
  CONSTRAINT `fk_ff_to_institution` FOREIGN KEY (`tb_institution_id`) REFERENCES `tb_institution` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- Remoção das tabelas da Fase 1 substituídas (decisão 18: sem produção,
-- troca direta — sem migração de dados)
-- ---------------------------------------------------------------------

DROP TABLE IF EXISTS `feature_flags`;
DROP TABLE IF EXISTS `tenants`;
