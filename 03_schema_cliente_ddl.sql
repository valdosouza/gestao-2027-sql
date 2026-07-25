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

-- Customer: especialização local da entity central (herança por PK — decisão 1).
-- Fase 3 Rodada 4 (2026-07-16): consumer/by_pass_st MIGRARAM para
-- tb_entity_tax; wallet char(1) virou tb_payment_types_id (decisão 18 — UI
-- radiobox Sim/Não: "Sim" grava o id da forma "Carteira", autocreate).
-- UI: credit_status = radiobox [L]iberado / [B]loqueado.
CREATE TABLE IF NOT EXISTS `tb_customer` (
  `id`                  INT NOT NULL,
  `tb_institution_id`   INT NOT NULL,
  `tb_salesman_id`      INT DEFAULT NULL,
  `tb_carrier_id`       INT DEFAULT NULL,
  `credit_status`       CHAR(1) DEFAULT NULL,
  `credit_value`        DECIMAL(10,2) DEFAULT NULL,
  `tb_payment_types_id` INT NOT NULL DEFAULT 0,
  `multiplier`          DECIMAL(10,2) NOT NULL DEFAULT 1,
  `active`              CHAR(1) DEFAULT 'S',
  `created_at`          DATETIME DEFAULT NULL,
  `updated_at`          DATETIME DEFAULT NULL,
  `deleted`             CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`, `tb_institution_id`),
  KEY `idx_tb_customer_institution` (`tb_institution_id`),
  KEY `idx_tb_customer_salesman` (`tb_salesman_id`),
  KEY `idx_tb_customer_carrier` (`tb_carrier_id`),
  CONSTRAINT `fk_tb_customer_carrier`
    FOREIGN KEY (`tb_carrier_id`)
    REFERENCES `setes_central`.`tb_entity` (`id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION,
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
-- Fase 3 (Entidade Única) — decisões 11 e 12 do prompt_fase3_entidade_unica.md
-- Salesman e Carrier: especializações locais da entity central (herança por
-- PK compartilhada + institution). Versão canônica das tabelas do legado,
-- que vinham SEM PK no dump — no schema provisionado, a migration 005
-- realinha as FKs do baseline para setes_central.
-- =====================================================================

-- VÍNCULO/uso das formas de pagamento (Valdo, 2026-07-18): o catálogo é
-- CENTRAL (setes_central.tb_payment_types — o cliente inicia o cadastro,
-- reuso entre clientes); aqui fica o que a institution usa, com a
-- configuração operacional do vínculo (migration 012): enable (o cliente
-- não exclui a linha compartilhada — desabilita por um tempo), app_mobile,
-- bloqueios por situação do cliente, parcelas, TEF, Plano de Contas
-- (Resultado/Centro de Custo — referência por coluna SEM FK física,
-- DEFAULT 0 = não definido) e preferência de uso 'C'aixa/'B'anco/'A'mbos.
CREATE TABLE IF NOT EXISTS `tb_institution_has_payment_types` (
  `tb_institution_id`           INT NOT NULL,
  `tb_payment_types_id`         INT NOT NULL,
  `enable`                      CHAR(1) NOT NULL DEFAULT 'S',
  `app_mobile`                  CHAR(1) NOT NULL DEFAULT 'N',
  `block_for_customer_blocked`  CHAR(1) NOT NULL DEFAULT 'N',
  `block_for_customer_no_limit` CHAR(1) NOT NULL DEFAULT 'N',
  `max_parcels`                 INT NOT NULL DEFAULT 1,
  `tef`                         CHAR(1) NOT NULL DEFAULT 'N',
  `tb_financial_plans_id_cre`   INT NOT NULL DEFAULT 0,
  `tb_financial_plans_id_deb`   INT NOT NULL DEFAULT 0,
  `usage_preference`            CHAR(1) NOT NULL DEFAULT 'A',
  `created_at`          DATETIME DEFAULT NULL,
  `updated_at`          DATETIME DEFAULT NULL,
  `deleted`             CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`tb_institution_id`, `tb_payment_types_id`),
  KEY `idx_ihpt_payment_types` (`tb_payment_types_id`),
  KEY `updated_at` (`updated_at`),
  CONSTRAINT `fk_ihpt_institution`
    FOREIGN KEY (`tb_institution_id`)
    REFERENCES `setes_central`.`tb_institution` (`id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_ihpt_payment_types`
    FOREIGN KEY (`tb_payment_types_id`)
    REFERENCES `setes_central`.`tb_payment_types` (`id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- VÍNCULO/uso de Marca/Embalagem/Medida (revisão do sincronizador, D5/D17 —
-- Valdo 2026-07-19; migration 018 realinha o baseline): catálogos CENTRAIS
-- (setes_central.tb_brand/tb_package/tb_measure, dedupe por descrição na
-- aplicação), aqui fica o que a institution usa — active = desabilitar sem
-- excluir a linha compartilhada. Molde: tb_institution_has_payment_types.
CREATE TABLE IF NOT EXISTS `tb_institution_has_brand` (
  `tb_institution_id` INT NOT NULL,
  `tb_brand_id`       INT NOT NULL,
  `active`            CHAR(1) NOT NULL DEFAULT 'S',
  `created_at`        DATETIME DEFAULT NULL,
  `updated_at`        DATETIME DEFAULT NULL,
  `deleted`           CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`tb_institution_id`, `tb_brand_id`),
  KEY `idx_ihb_brand` (`tb_brand_id`),
  KEY `updated_at` (`updated_at`),
  CONSTRAINT `fk_ihb_institution` FOREIGN KEY (`tb_institution_id`) REFERENCES `setes_central`.`tb_institution` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_ihb_brand` FOREIGN KEY (`tb_brand_id`) REFERENCES `setes_central`.`tb_brand` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tb_institution_has_package` (
  `tb_institution_id` INT NOT NULL,
  `tb_package_id`     INT NOT NULL,
  `active`            CHAR(1) NOT NULL DEFAULT 'S',
  `created_at`        DATETIME DEFAULT NULL,
  `updated_at`        DATETIME DEFAULT NULL,
  `deleted`           CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`tb_institution_id`, `tb_package_id`),
  KEY `idx_ihp_package` (`tb_package_id`),
  KEY `updated_at` (`updated_at`),
  CONSTRAINT `fk_ihp_institution` FOREIGN KEY (`tb_institution_id`) REFERENCES `setes_central`.`tb_institution` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_ihp_package` FOREIGN KEY (`tb_package_id`) REFERENCES `setes_central`.`tb_package` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tb_institution_has_measure` (
  `tb_institution_id` INT NOT NULL,
  `tb_measure_id`     INT NOT NULL,
  `active`            CHAR(1) NOT NULL DEFAULT 'S',
  `created_at`        DATETIME DEFAULT NULL,
  `updated_at`        DATETIME DEFAULT NULL,
  `deleted`           CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`tb_institution_id`, `tb_measure_id`),
  KEY `idx_ihm_measure` (`tb_measure_id`),
  KEY `updated_at` (`updated_at`),
  CONSTRAINT `fk_ihm_institution` FOREIGN KEY (`tb_institution_id`) REFERENCES `setes_central`.`tb_institution` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_ihm_measure` FOREIGN KEY (`tb_measure_id`) REFERENCES `setes_central`.`tb_measure` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- Categorias de produtos e serviços (Valdo, 2026-07-18): cadastro POR
-- institution (PK composta; id MAX+1 por institution na aplicação).
-- kind: 'P' = produto, 'S' = serviço. KEY updated_at = sync incremental.
-- Substitui a tb_category legada do baseline (migration 009 realinha).
CREATE TABLE IF NOT EXISTS `tb_category` (
  `id`                INT NOT NULL,
  `tb_institution_id` INT NOT NULL,
  `description`       VARCHAR(100) NOT NULL,
  `posit_level`       VARCHAR(40) DEFAULT NULL,
  `kind`              CHAR(1) DEFAULT NULL,
  `active`            CHAR(1) NOT NULL DEFAULT 'S',
  `created_at`        DATETIME DEFAULT NULL,
  `updated_at`        DATETIME DEFAULT NULL,
  `deleted`           CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`, `tb_institution_id`),
  KEY `idx_tb_category_institution` (`tb_institution_id`),
  KEY `updated_at` (`updated_at`),
  CONSTRAINT `fk_tb_category_institution`
    FOREIGN KEY (`tb_institution_id`)
    REFERENCES `setes_central`.`tb_institution` (`id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- PLANO DE CONTAS (Valdo, 2026-07-18): 2º cadastro em ÁRVORE (posit_level
-- materializado, porta do reg_plano_contas.pas), POR institution.
-- source_ = Natureza C/D; kind = Tipo C(usto)/R(esultado);
-- cluster = Nível S(intética)/A(nalítica). Substitui a versão legada do
-- baseline (migration 010 realinha).
CREATE TABLE IF NOT EXISTS `tb_financial_plans` (
  `id`                INT NOT NULL,
  `tb_institution_id` INT NOT NULL,
  `posit_level`       VARCHAR(50) NOT NULL,
  `description`       VARCHAR(100) NOT NULL,
  `source_`           CHAR(1) NOT NULL DEFAULT 'C',
  `kind`              CHAR(1) NOT NULL DEFAULT 'C',
  `cluster`           CHAR(1) NOT NULL DEFAULT 'S',
  `active`            CHAR(1) NOT NULL DEFAULT 'S',
  `created_at`        DATETIME DEFAULT NULL,
  `updated_at`        DATETIME DEFAULT NULL,
  `deleted`           CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`, `tb_institution_id`),
  KEY `idx_tb_financial_plans_institution` (`tb_institution_id`),
  KEY `source_` (`source_`),
  KEY `kind` (`kind`),
  KEY `updated_at` (`updated_at`),
  CONSTRAINT `fk_tb_financial_plans_institution`
    FOREIGN KEY (`tb_institution_id`)
    REFERENCES `setes_central`.`tb_institution` (`id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- Papel COLABORADOR (onda 2 da Entidade Única — hierarquia de papéis,
-- decisão 16 do Framework de Configurações): herança por PK em dois níveis
-- (tb_salesman.id = tb_collaborator.id = tb_entity.id). Colaborador pode
-- ser só administrativo; todo vendedor É colaborador — a PRECEDÊNCIA
-- (criar salesman exige colaborador) será instituída na APLICAÇÃO quando o
-- cadastro de salesman nascer (FK física avaliada no revisar-ddl da onda —
-- schemas com salesman sincronizado do legado inviabilizam a FK agora).
-- Campos reescritos do legado (tblCollaborator.pas — typo fahters_name
-- corrigido para fathers_name; mapeamento fica na revisão do sync).
CREATE TABLE IF NOT EXISTS `tb_collaborator` (
  `id`                   INT NOT NULL,
  `tb_institution_id`    INT NOT NULL,
  `active`               CHAR(1) NOT NULL DEFAULT 'S',
  `dt_admission`         DATE DEFAULT NULL,
  `dt_resignation`       DATE DEFAULT NULL,
  `salary`               DECIMAL(10,2) DEFAULT NULL,
  `fathers_name`         VARCHAR(100) DEFAULT NULL,
  `mothers_name`         VARCHAR(100) DEFAULT NULL,
  `vote_number`          VARCHAR(20) DEFAULT NULL,
  `vote_zone`            VARCHAR(10) DEFAULT NULL,
  `vote_section`         VARCHAR(10) DEFAULT NULL,
  `military_certificate` VARCHAR(30) DEFAULT NULL,
  `pis`                  VARCHAR(20) DEFAULT NULL,
  `created_at`           DATETIME DEFAULT NULL,
  `updated_at`           DATETIME DEFAULT NULL,
  `deleted`              CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`, `tb_institution_id`),
  KEY `idx_tb_collaborator_institution` (`tb_institution_id`),
  CONSTRAINT `fk_tb_collaborator_entity`
    FOREIGN KEY (`id`)
    REFERENCES `setes_central`.`tb_entity` (`id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_tb_collaborator_institution`
    FOREIGN KEY (`tb_institution_id`)
    REFERENCES `setes_central`.`tb_institution` (`id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tb_salesman` (
  `id`                INT NOT NULL,
  `tb_institution_id` INT NOT NULL,
  `active`            CHAR(1) NOT NULL DEFAULT 'N',
  `aliq_kickback`     DECIMAL(10,2) DEFAULT NULL,
  `kickback_product`  CHAR(1) DEFAULT NULL,
  `flex_value`        DECIMAL(10,2) NOT NULL,
  `created_at`        DATETIME DEFAULT NULL,
  `updated_at`        DATETIME DEFAULT NULL,
  `deleted`           CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`, `tb_institution_id`),
  KEY `idx_tb_salesman_institution` (`tb_institution_id`),
  CONSTRAINT `fk_tb_salesman_entity`
    FOREIGN KEY (`id`)
    REFERENCES `setes_central`.`tb_entity` (`id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_tb_salesman_institution`
    FOREIGN KEY (`tb_institution_id`)
    REFERENCES `setes_central`.`tb_institution` (`id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tb_carrier` (
  `id`                INT NOT NULL,
  `tb_institution_id` INT NOT NULL,
  `active`            CHAR(1) NOT NULL DEFAULT 'S',
  `created_at`        DATETIME DEFAULT NULL,
  `updated_at`        DATETIME DEFAULT NULL,
  `deleted`           CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`, `tb_institution_id`),
  KEY `idx_tb_carrier_institution` (`tb_institution_id`),
  CONSTRAINT `fk_tb_carrier_entity`
    FOREIGN KEY (`id`)
    REFERENCES `setes_central`.`tb_entity` (`id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_tb_carrier_institution`
    FOREIGN KEY (`tb_institution_id`)
    REFERENCES `setes_central`.`tb_institution` (`id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- =====================================================================
-- Fase 3 Rodada 4 (decisões 14–17): TRIBUTAÇÃO por relação comercial
-- (entity × institution) — QUALQUER entidade pode precisar de tributação
-- para receber notas, não só clientes. Fonte ÚNICA: os campos fiscais
-- saíram de setes_central.tb_company (decisão 16). Instruções de UI por
-- campo em setes-api/src/migrations/sql/006_entity_tax.sql.
-- =====================================================================

CREATE TABLE IF NOT EXISTS `tb_entity_tax` (
  `id`                         INT NOT NULL,
  `tb_institution_id`          INT NOT NULL,
  `consumer`                   CHAR(1) DEFAULT 'N',       -- UI: radiobox S/N
  `tax_regime`                 VARCHAR(100) DEFAULT NULL, -- UI: dropdown canônico (1 Simples, 2 Simples excesso, 3 Lucro Real, 3 Lucro Presumido)
  `by_pass_st`                 CHAR(1) DEFAULT 'N',       -- UI: checkbox S/N
  `ind_ie_dest`                CHAR(1) DEFAULT NULL,      -- UI: dropdown 1/2/9 (NFe)
  `iss_exigibilidade`          CHAR(2) DEFAULT NULL,      -- UI: dropdown 01..07 (códigos do legado — decisão 15)
  `iss_process_nr`             VARCHAR(25) DEFAULT NULL,
  `iss_retido`                 CHAR(1) DEFAULT 'N',       -- UI: radiobox S/N
  `iss_ind_inc_fiscal`         CHAR(1) DEFAULT 'N',       -- UI: radiobox S/N
  `auto_send_invoice`          CHAR(1) DEFAULT 'N',       -- UI: checkbox S/N
  `auto_send_invoice_just_xml` CHAR(1) DEFAULT 'N',       -- UI: checkbox S/N
  `created_at`                 DATETIME DEFAULT NULL,
  `updated_at`                 DATETIME DEFAULT NULL,
  `deleted`                    CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`, `tb_institution_id`),
  KEY `idx_tb_entity_tax_institution` (`tb_institution_id`),
  CONSTRAINT `fk_tb_entity_tax_entity`
    FOREIGN KEY (`id`)
    REFERENCES `setes_central`.`tb_entity` (`id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_tb_entity_tax_institution`
    FOREIGN KEY (`tb_institution_id`)
    REFERENCES `setes_central`.`tb_institution` (`id`)
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

-- Especialização de campos por institution (setes-app Fase 2 campos
-- configuráveis, decisões 2, 5 e 12): o cliente só APERTA o baseline técnico
-- do catálogo (setes_central.tb_interface_has_field) — nunca afrouxa.
-- required NULL = herda o catálogo; field_caption NULL = i18n padrão do app;
-- mask NULL = sem máscara custom (padrão técnico: # = dígito, A = letra,
-- demais literais — decisão 16). Editada pelo painel Sistema/Admin (decisão 6).
CREATE TABLE IF NOT EXISTS `tb_institution_has_field` (
  `tb_institution_id` INT NOT NULL,
  `tb_interface_id`   INT NOT NULL,
  `field_name`        VARCHAR(100) NOT NULL,
  `field_caption`     VARCHAR(100) DEFAULT NULL,
  `required`          CHAR(1) DEFAULT NULL,
  `mask`              VARCHAR(50) DEFAULT NULL,
  `created_at`        DATETIME DEFAULT NULL,
  `updated_at`        DATETIME DEFAULT NULL,
  `deleted`           CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`tb_institution_id`,`tb_interface_id`,`field_name`),
  KEY `idx_inhf_field` (`tb_interface_id`,`field_name`),
  CONSTRAINT `fk_inhf_to_institution`
    FOREIGN KEY (`tb_institution_id`)
    REFERENCES `setes_central`.`tb_institution` (`id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_inhf_to_field`
    FOREIGN KEY (`tb_interface_id`,`field_name`)
    REFERENCES `setes_central`.`tb_interface_has_field` (`tb_interface_id`,`field_name`)
    ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- VALORES de configuração escolhidos pelo cliente (Framework de
-- Configurações do Sistema, decisões 2 e 4) sobre o catálogo
-- setes_central.tb_interface_has_config. Só grava o que DIVERGE do default
-- do catálogo — a tela sempre mostra o efetivo (default com override por
-- cima). Resolução: usuário → institution → default.
-- tb_user_id = 0 (sentinel) = valor da institution; >0 = override do
-- usuário (permitido apenas quando o catálogo marca scope='U').
CREATE TABLE IF NOT EXISTS `tb_institution_has_config` (
  `tb_institution_id` INT NOT NULL,
  `tb_interface_id`   INT NOT NULL,
  `name`              VARCHAR(50) NOT NULL,
  `tb_user_id`        INT NOT NULL DEFAULT 0,
  `content`           VARCHAR(100) NOT NULL,
  `created_at`        DATETIME DEFAULT NULL,
  `updated_at`        DATETIME DEFAULT NULL,
  `deleted`           CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`tb_institution_id`,`tb_interface_id`,`name`,`tb_user_id`),
  KEY `idx_inhc_config` (`tb_interface_id`,`name`),
  CONSTRAINT `fk_inhc_institution`
    FOREIGN KEY (`tb_institution_id`)
    REFERENCES `setes_central`.`tb_institution` (`id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_inhc_config`
    FOREIGN KEY (`tb_interface_id`,`name`)
    REFERENCES `setes_central`.`tb_interface_has_config` (`tb_interface_id`,`name`)
    ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- =====================================================================
-- Módulo Software House / Ordem de Serviço (Valdo, 2026-07-18 — prompt
-- FECHADO Infra-IA/setes-api/prompt_modulo_software_house.md; migration 013)
-- =====================================================================

-- Contrato de serviços por cliente (D1/D9; DP3: mensalidade = SUM dos
-- itens). payment_day é informativo (4.2); o vencimento do faturamento é
-- DECIDIDO PELO USUÁRIO na tela (DP1 — 5º dia útil é só o default).
CREATE TABLE IF NOT EXISTS `tb_contract` (
  `id`                INT NOT NULL,
  `tb_institution_id` INT NOT NULL,
  `tb_customer_id`    INT NOT NULL,
  `dt_start`          DATE NOT NULL,
  `dt_end`            DATE DEFAULT NULL,
  `payment_day`       INT NOT NULL DEFAULT 5,
  `active`            CHAR(1) NOT NULL DEFAULT 'S',
  `created_at`        DATETIME DEFAULT NULL,
  `updated_at`        DATETIME DEFAULT NULL,
  `deleted`           CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`, `tb_institution_id`),
  KEY `idx_tb_contract_customer` (`tb_institution_id`, `tb_customer_id`, `active`),
  KEY `updated_at` (`updated_at`),
  CONSTRAINT `fk_tb_contract_institution`
    FOREIGN KEY (`tb_institution_id`)
    REFERENCES `setes_central`.`tb_institution` (`id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_tb_contract_customer`
    FOREIGN KEY (`tb_customer_id`)
    REFERENCES `setes_central`.`tb_entity` (`id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- N produtos por contrato (D9) com valor MENSAL por produto (DP3).
CREATE TABLE IF NOT EXISTS `tb_contract_item` (
  `tb_contract_id`    INT NOT NULL,
  `tb_institution_id` INT NOT NULL,
  `tb_product_id`     INT NOT NULL,
  `value`             DECIMAL(10,2) NOT NULL DEFAULT 0,
  `created_at`        DATETIME DEFAULT NULL,
  `updated_at`        DATETIME DEFAULT NULL,
  `deleted`           CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`tb_contract_id`, `tb_institution_id`, `tb_product_id`),
  KEY `updated_at` (`updated_at`),
  CONSTRAINT `fk_tb_contract_item_contract`
    FOREIGN KEY (`tb_contract_id`, `tb_institution_id`)
    REFERENCES `tb_contract` (`id`, `tb_institution_id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- Ramo de SERVIÇO do backbone tb_order (ciclo mensal). DP7: o status A/F
-- vive na tb_order (backbone dono do ciclo); open_lock é coluna NORMAL
-- mantida pela APLICAÇÃO na mesma transação (abrir = CONCAT(inst,'-',
-- cliente); faturar/cancelar = NULL) — a UNIQUE é a rede da D5.
CREATE TABLE IF NOT EXISTS `tb_order_service` (
  `id`                INT NOT NULL,
  `tb_institution_id` INT NOT NULL,
  `terminal`          INT NOT NULL DEFAULT 0,
  `number`            INT DEFAULT NULL,
  `tb_customer_id`    INT NOT NULL,
  `open_lock`         VARCHAR(30) DEFAULT NULL,
  `created_at`        DATETIME NOT NULL,
  `updated_at`        DATETIME NOT NULL,
  `deleted`           CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`, `tb_institution_id`, `terminal`),
  UNIQUE KEY `uk_open_per_customer` (`open_lock`),
  KEY `idx_service_customer` (`tb_institution_id`, `tb_customer_id`),
  KEY `updated_at` (`updated_at`),
  CONSTRAINT `fk_tb_order_service_order`
    FOREIGN KEY (`id`, `tb_institution_id`, `terminal`)
    REFERENCES `tb_order` (`id`, `tb_institution_id`, `terminal`)
    ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_tb_order_service_customer`
    FOREIGN KEY (`tb_customer_id`)
    REFERENCES `setes_central`.`tb_entity` (`id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- Ramo FINANCEIRO do backbone (DP10 — "sempre haverá uma ordem"): entidade
-- credora/devedora das ordens nascidas do financeiro (colaborador nos PA,
-- fornecedor nos PM) + trilha da baixa de origem (PA).
CREATE TABLE IF NOT EXISTS `tb_order_financial` (
  `id`                 INT NOT NULL,
  `tb_institution_id`  INT NOT NULL,
  `terminal`           INT NOT NULL DEFAULT 0,
  `tb_entity_id`       INT NOT NULL,
  `tb_order_id_origin` INT NOT NULL DEFAULT 0,
  `origin_parcel`      INT NOT NULL DEFAULT 0,
  `origin_event`       INT NOT NULL DEFAULT 0,
  `created_at`         DATETIME NOT NULL,
  `updated_at`         DATETIME NOT NULL,
  `deleted`            CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`, `tb_institution_id`, `terminal`),
  KEY `idx_order_financial_entity` (`tb_institution_id`, `tb_entity_id`),
  KEY `idx_order_financial_origin` (`tb_institution_id`, `tb_order_id_origin`),
  KEY `updated_at` (`updated_at`),
  CONSTRAINT `fk_tb_order_financial_order`
    FOREIGN KEY (`id`, `tb_institution_id`, `terminal`)
    REFERENCES `tb_order` (`id`, `tb_institution_id`, `terminal`)
    ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_tb_order_financial_entity`
    FOREIGN KEY (`tb_entity_id`)
    REFERENCES `setes_central`.`tb_entity` (`id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- Especialização de MERCADORIA do item universal (DP6): estoque e lista de
-- preço saem do tb_order_item (que fica enxuto p/ qualquer natureza).
CREATE TABLE IF NOT EXISTS `tb_order_item_merchandise` (
  `id`                INT NOT NULL,
  `tb_institution_id` INT NOT NULL,
  `tb_order_id`       INT NOT NULL,
  `terminal`          INT NOT NULL DEFAULT 0,
  `tb_stock_list_id`  INT NOT NULL,
  `tb_price_list_id`  INT DEFAULT NULL,
  `created_at`        DATETIME DEFAULT NULL,
  `updated_at`        DATETIME DEFAULT NULL,
  `deleted`           CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`, `tb_institution_id`, `tb_order_id`, `terminal`),
  KEY `tb_stock_list_id` (`tb_stock_list_id`),
  KEY `updated_at` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- PARCERIA v2 (Valdo, 2026-07-19 — prompt_parceria_v2.md, migration 016):
-- conceito de ANGARIAÇÃO — colaborador trouxe o cliente; a parceria É do
-- cliente (1 linha por colaborador envolvido; Σ rate ≤ 90 na aplicação;
-- os 10% da Setes são fixos). Sem entidade nomeada (D2); acesso pela ABA
-- Parceria do cliente (D3), gateada como recurso vendável kind 'R' (D4).
-- active (D7) suspende o parceiro sem excluir. A baixa de recebimento lê
-- esta tabela para gerar as ordens PA (rotina de parcerias do settlements).
CREATE TABLE IF NOT EXISTS `tb_partnership` (
  `tb_institution_id`  INT NOT NULL,
  `tb_customer_id`     INT NOT NULL,
  `tb_collaborator_id` INT NOT NULL,
  `rate`               DECIMAL(10,2) NOT NULL DEFAULT 0,
  `active`             CHAR(1) NOT NULL DEFAULT 'S',
  `created_at`         DATETIME DEFAULT NULL,
  `updated_at`         DATETIME DEFAULT NULL,
  `deleted`            CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`tb_institution_id`, `tb_customer_id`, `tb_collaborator_id`),
  KEY `idx_partnership_collaborator` (`tb_institution_id`, `tb_collaborator_id`),
  KEY `updated_at` (`updated_at`),
  CONSTRAINT `fk_tb_partnership_customer`
    FOREIGN KEY (`tb_customer_id`, `tb_institution_id`)
    REFERENCES `tb_customer` (`id`, `tb_institution_id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_tb_partnership_collaborator`
    FOREIGN KEY (`tb_collaborator_id`, `tb_institution_id`)
    REFERENCES `tb_collaborator` (`id`, `tb_institution_id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
