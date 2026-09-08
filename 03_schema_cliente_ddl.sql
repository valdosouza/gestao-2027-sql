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
-- DEFAULT 0 = não definido). A antiga usage_preference ('C'/'B'/'A') foi
-- APOSENTADA em 2026-09-03 (migration 038, D17 do contrato financeiro): o
-- destino caixa × banco vem do tb_financial_contract.
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

-- CONTRATO FINANCEIRO (Valdo, 2026-09-03 — migration 038;
-- prompt_contrato_financeiro_baixa_automatica.md D1–D22): POLÍTICA de
-- baixa automática da forma de pagamento — especialização do vínculo
-- acima (PK compartilhada = 1 contrato por forma, D2). A PRESENÇA do
-- contrato é o único gatilho da baixa no faturamento (D1/D9); sem contrato
-- o título nasce aberto. tb_bank_account_id 0 = caixa (exige caixa aberto)
-- / > 0 = conta corrente (sentinela sem FK física, como no statement);
-- fee_rate = taxa da operadora (débito no mesmo settled_code); payment_term
-- = dias até o dinheiro cair (dt_record = faturamento + prazo × parcela,
-- D12); expiration_date informativa (vencido = avisa e gera aberto, D11).
CREATE TABLE IF NOT EXISTS `tb_financial_contract` (
  `tb_institution_id`   INT NOT NULL,
  `tb_payment_types_id` INT NOT NULL,
  `tb_bank_account_id`  INT NOT NULL DEFAULT 0,
  `fee_rate`            DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  `payment_term`        INT NOT NULL DEFAULT 0,
  `expiration_date`     DATE DEFAULT NULL,
  `note`                TEXT DEFAULT NULL,
  `created_at`          DATETIME DEFAULT NULL,
  `updated_at`          DATETIME DEFAULT NULL,
  `deleted`             CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`tb_institution_id`, `tb_payment_types_id`),
  CONSTRAINT `fk_fc_payment_type_link`
    FOREIGN KEY (`tb_institution_id`, `tb_payment_types_id`)
    REFERENCES `tb_institution_has_payment_types` (`tb_institution_id`, `tb_payment_types_id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- BOLETO EMITIDO (Valdo, 2026-09-03 — migration 039; prompt_boleto_emitido.md
-- D1–D11): instrumento de cobrança de 1..N títulos. Família tb_bank_charge_*
-- (baseline 001) relida: tb_bank_charge_slip RENOMEADA tb_bank_charge_agreement
-- (= contratação/carteira configurada; + active D8, + our_number_next D3),
-- tb_bank_charge_ticket = carteira bancária, tb_bank_charge_kind = espécie
-- do documento. Cabeçalho IMUTÁVEL (taxas congeladas da config) + vínculo
-- boleto↔título SEM FK ao título (decisão 33) + eventos append-only
-- (E emitido, L liquidado, C cancelado, X estornado; S/G/A = canal, fora).
CREATE TABLE IF NOT EXISTS `tb_bank_slip` (
  `id`                          INT NOT NULL,
  `tb_institution_id`           INT NOT NULL,
  `tb_bank_charge_agreement_id` INT NOT NULL,
  `tb_bank_account_id`          INT NOT NULL,
  `tb_bank_charge_kind_id`      INT DEFAULT NULL,
  `our_number`                  VARCHAR(30) NOT NULL,
  `document_number`             VARCHAR(30) NOT NULL,
  `dt_emission`                 DATE NOT NULL,
  `dt_expiration`               DATE NOT NULL,
  `value`                       DECIMAL(10,2) NOT NULL,
  `accept`                      CHAR(1) DEFAULT NULL,
  `aliq_discount`               DECIMAL(10,2) DEFAULT NULL,
  `discount_value`              DECIMAL(10,2) DEFAULT NULL,
  `dt_discount_until`           DATE DEFAULT NULL,
  `aliq_interest`               DECIMAL(10,2) DEFAULT NULL,
  `aliq_late`                   DECIMAL(10,2) DEFAULT NULL,
  `value_late_min`              DECIMAL(10,2) DEFAULT NULL,
  `aliq_fine`                   DECIMAL(10,2) DEFAULT NULL,
  `value_fine`                  DECIMAL(10,2) DEFAULT NULL,
  `value_rate`                  DECIMAL(10,2) DEFAULT NULL,
  `instruction`                 TEXT DEFAULT NULL,
  `protest_days`                INT DEFAULT NULL,
  `protest_day_kind`            CHAR(1) DEFAULT NULL,
  `negativation_days`           INT DEFAULT NULL,
  `tb_user_id`                  INT DEFAULT NULL,
  `created_at`                  DATETIME DEFAULT NULL,
  `updated_at`                  DATETIME DEFAULT NULL,
  `deleted`                     CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`, `tb_institution_id`),
  KEY `idx_bank_slip_our_number` (`tb_institution_id`, `our_number`),
  KEY `idx_bank_slip_expiration` (`tb_institution_id`, `dt_expiration`),
  CONSTRAINT `fk_bank_slip_agreement`
    FOREIGN KEY (`tb_bank_charge_agreement_id`, `tb_institution_id`)
    REFERENCES `tb_bank_charge_agreement` (`id`, `tb_institution_id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `tb_bank_slip_title` (
  `tb_institution_id` INT NOT NULL,
  `tb_bank_slip_id`   INT NOT NULL,
  `tb_order_id`       INT NOT NULL,
  `terminal`          INT NOT NULL DEFAULT 0,
  `parcel`            INT NOT NULL,
  `value`             DECIMAL(10,2) NOT NULL,
  `created_at`        DATETIME DEFAULT NULL,
  `updated_at`        DATETIME DEFAULT NULL,
  `deleted`           CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`tb_institution_id`, `tb_bank_slip_id`, `tb_order_id`, `terminal`, `parcel`),
  KEY `idx_bank_slip_title_title` (`tb_institution_id`, `tb_order_id`, `terminal`, `parcel`),
  CONSTRAINT `fk_bank_slip_title_slip`
    FOREIGN KEY (`tb_bank_slip_id`, `tb_institution_id`)
    REFERENCES `tb_bank_slip` (`id`, `tb_institution_id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `tb_bank_slip_event` (
  `tb_institution_id`  INT NOT NULL,
  `tb_bank_slip_id`    INT NOT NULL,
  `event`              INT NOT NULL,
  `kind`               CHAR(1) NOT NULL,
  `dt_record`          DATE NOT NULL,
  `source`             CHAR(1) NOT NULL DEFAULT 'M',
  `settled_code`       INT DEFAULT NULL,
  `tb_bank_account_id` INT DEFAULT NULL,
  `paid_value`         DECIMAL(10,2) DEFAULT NULL,
  `dt_expiration`      DATE DEFAULT NULL,
  `bank_code`          VARCHAR(10) DEFAULT NULL,
  `bank_message`       VARCHAR(100) DEFAULT NULL,
  `origin_event`       INT DEFAULT NULL,
  `note`               VARCHAR(255) DEFAULT NULL,
  `tb_user_id`         INT DEFAULT NULL,
  `created_at`         DATETIME DEFAULT NULL,
  `updated_at`         DATETIME DEFAULT NULL,
  `deleted`            CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`tb_institution_id`, `tb_bank_slip_id`, `event`),
  CONSTRAINT `fk_bank_slip_event_slip`
    FOREIGN KEY (`tb_bank_slip_id`, `tb_institution_id`)
    REFERENCES `tb_bank_slip` (`id`, `tb_institution_id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;

-- CHEQUE (Valdo, 2026-09-03 — migration 040; prompt_cheque_rastreabilidade.md
-- D1–D10 + D7a–c): título ao PORTADOR que substitui a dívida do cliente a
-- partir da baixa do faturamento (evento R). Cabeçalho IMUTÁVEL + história
-- append-only (R recebido · B depositado · D descontado · P usado em
-- pagamento · T retornado com reembolso · F retornado bom · V devolvido ·
-- X estornado). D5: UNIQUE identidade — cheque que volta é o MESMO registro.
CREATE TABLE IF NOT EXISTS `tb_check` (
  `id`                 INT NOT NULL,
  `tb_institution_id`  INT NOT NULL,
  `tb_bank_id`         INT NOT NULL,
  `agency`             VARCHAR(10) NOT NULL,
  `account`            VARCHAR(15) NOT NULL,
  `number`             VARCHAR(20) NOT NULL,
  `issuer`             VARCHAR(100) NOT NULL,
  `value`              DECIMAL(10,2) NOT NULL,
  `dt_check`           DATE NOT NULL,
  `kind`               CHAR(1) NOT NULL DEFAULT 'P',
  `created_at`         DATETIME DEFAULT NULL,
  `updated_at`         DATETIME DEFAULT NULL,
  `deleted`            CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`, `tb_institution_id`),
  UNIQUE KEY `uq_check_identity` (`tb_institution_id`, `tb_bank_id`, `agency`, `account`, `number`),
  KEY `idx_check_inst_id` (`tb_institution_id`, `id`) -- contador MAX+1 por institution (migration 041, Q-G5)
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `tb_check_event` (
  `tb_institution_id`  INT NOT NULL,
  `tb_check_id`        INT NOT NULL,
  `event`              INT NOT NULL,
  `kind`               CHAR(1) NOT NULL,
  `dt_record`          DATE NOT NULL,
  `tb_entity_id`       INT DEFAULT NULL,
  `settled_code`       INT DEFAULT NULL,
  `payment_event`      INT DEFAULT NULL,
  `tb_order_id`        INT DEFAULT NULL,
  `terminal`           INT DEFAULT NULL,
  `parcel`             INT DEFAULT NULL,
  `tb_bank_account_id` INT DEFAULT NULL,
  `origin_event`       INT DEFAULT NULL,
  `note`               VARCHAR(255) DEFAULT NULL,
  `tb_user_id`         INT DEFAULT NULL,
  `created_at`         DATETIME DEFAULT NULL,
  `updated_at`         DATETIME DEFAULT NULL,
  `deleted`            CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`tb_institution_id`, `tb_check_id`, `event`),
  CONSTRAINT `fk_check_event_check`
    FOREIGN KEY (`tb_check_id`, `tb_institution_id`)
    REFERENCES `tb_check` (`id`, `tb_institution_id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;

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

-- Papel FORNECEDOR (Onda 3 da Entidade Única, D2 — 2026-08-03): estava só
-- no baseline (fora do realinhamento da migration 005); entra no canônico
-- alinhado aos irmãos (migration 022 realinha schemas existentes). O papel
-- não tem campo próprio no legado (tblProvider.pas = só active).
CREATE TABLE IF NOT EXISTS `tb_provider` (
  `id`                INT NOT NULL,
  `tb_institution_id` INT NOT NULL,
  `active`            CHAR(1) NOT NULL DEFAULT 'S',
  `created_at`        DATETIME DEFAULT NULL,
  `updated_at`        DATETIME DEFAULT NULL,
  `deleted`           CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`, `tb_institution_id`),
  KEY `idx_tb_provider_institution` (`tb_institution_id`),
  CONSTRAINT `fk_tb_provider_entity`
    FOREIGN KEY (`id`)
    REFERENCES `setes_central`.`tb_entity` (`id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_tb_provider_institution`
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
-- Módulo de Menus 2026-08-04 (prompt_modulo_menus.md D3/D4 + migration 023):
-- position = ordem no menu; image_icon = NOME de ícone Material (o app
-- renderiza pelo nome); link_name legado DROPADA.
CREATE TABLE IF NOT EXISTS `tb_module` (
  `id`          INT NOT NULL,
  `description` VARCHAR(100) DEFAULT NULL,
  `position`    INT DEFAULT NULL,
  `image_icon`  VARCHAR(50) DEFAULT NULL,
  `created_at`  DATETIME DEFAULT NULL,
  `updated_at`  DATETIME DEFAULT NULL,
  `deleted`     CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- Detail do módulo: interfaces incluídas (Master-Detail — decisão 18).
-- Uma interface pode estar em mais de um módulo (prompt, seção G).
-- position (D3): a ordem do array do PUT é a ordem das telas no menu.
CREATE TABLE IF NOT EXISTS `tb_module_has_interface` (
  `tb_module_id`    INT NOT NULL,
  `tb_interface_id` INT NOT NULL,
  `active`          CHAR(1) DEFAULT NULL,
  `position`        INT DEFAULT NULL,
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

-- ============================================================================
-- Fase Faturamento Fiscal e Financeiro (2026-08-16) — blocos canônicos.
-- Fonte: Infra-IA/prompts/prompt_fase_faturamento_financeiro.md (32 decisões)
-- + parecer setes-conceito. Migration correspondente: setes-api 025/026.
-- Regra de Tributação: SELETOR (só campos do WHERE do motor) + peças 1:1 por
-- tributo — PRESENÇA = a regra DEFINE o tributo (isenção = presença com
-- alíquota nula). Coringas por NULL (produto/cliente/estado/ncm). As 6
-- sutilezas do matching vivem em @shared/tax-rule. tb_tax_ruler (baseline
-- legado) foi APOSENTADA pela decisão 30. FKs cross-schema só em INT (nota de
-- collation na migration 025); CSTs validados na aplicação.
-- Decisão 35 (2026-08-19, migration 029): `direction` OBRIGATÓRIA E/S — toda
-- regra declara o sentido, sem coringa (paridade com NAT_SENTIDO do legado);
-- o sentido da OPERAÇÃO vem do way da natureza (tb_cfop, sempre E/S).
-- ============================================================================

-- Regra de tributação de SERVIÇO (ISS) — prompt_regra_tributacao_servico.md
-- (D1/D4/D12/D13, 2026-09-02): o que o MUNICÍPIO cobra de um item da Lista
-- de Serviços (LC 116): cidade de incidência × item → alíquota + código
-- municipal. Dado fiscal INTERPRETÁVEL do cliente (schema do cliente, como
-- MVA/FCP — nunca compartilhado na central, D8). tb_service_list_id SEM FK
-- física (catálogo central varchar — validado na peça, padrão dos CSTs da
-- 025); tb_city_id com FK à central. tb_taxes_id = elo da reforma (IBS),
-- sem FK (mesmo status da tb_tax_rule). Unicidade do FATO (institution ×
-- cidade × item) garantida pela aplicação (409) — soft delete impede UNIQUE.
CREATE TABLE IF NOT EXISTS `tb_service_tax_rule` (
  `id`                  int(11) NOT NULL,
  `tb_institution_id`   int(11) NOT NULL,
  `tb_city_id`          int(11) NOT NULL,
  `tb_service_list_id`  varchar(10) NOT NULL,
  `aliq`                decimal(10,2) NOT NULL DEFAULT 0.00,
  `municipal_code`      varchar(20) DEFAULT NULL,
  `active`              char(1) NOT NULL DEFAULT 'S',
  `tb_taxes_id`         int(11) DEFAULT NULL,
  `created_at`          datetime DEFAULT NULL,
  `updated_at`          datetime DEFAULT NULL,
  `deleted`             char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`, `tb_institution_id`),
  KEY `idx_service_tax_rule_fact` (`tb_institution_id`, `tb_city_id`, `tb_service_list_id`),
  CONSTRAINT `fk_service_tax_rule_institution` FOREIGN KEY (`tb_institution_id`) REFERENCES `setes_central`.`tb_institution` (`id`),
  CONSTRAINT `fk_service_tax_rule_city` FOREIGN KEY (`tb_city_id`) REFERENCES `setes_central`.`tb_city` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Especialização FISCAL do serviço (D3 — espelho da tb_merchandise, herança
-- por PK compartilhada com tb_product kind='S'): o serviço aponta a REGRA
-- (D1, FK literal). Natureza do produto continua sendo tb_product.kind.
CREATE TABLE IF NOT EXISTS `tb_service` (
  `id`                      int(11) NOT NULL,
  `tb_institution_id`       int(11) NOT NULL,
  `tb_service_tax_rule_id`  int(11) DEFAULT NULL,
  `created_at`              datetime DEFAULT NULL,
  `updated_at`              datetime DEFAULT NULL,
  `deleted`                 char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`, `tb_institution_id`),
  KEY `idx_service_tax_rule` (`tb_service_tax_rule_id`, `tb_institution_id`),
  CONSTRAINT `fk_service_product` FOREIGN KEY (`id`, `tb_institution_id`) REFERENCES `tb_product` (`id`, `tb_institution_id`),
  CONSTRAINT `fk_service_tax_rule` FOREIGN KEY (`tb_service_tax_rule_id`, `tb_institution_id`) REFERENCES `tb_service_tax_rule` (`id`, `tb_institution_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Regra de tributação de SERVIÇO POR ITEM da ordem — irmã da
-- tb_order_item_tax_rule (D14 do prompt_regra_tributacao_servico.md:
-- paridade com mercadoria, INCLUINDO RegraDireta). origin 'A' = gravada
-- pelo /billing/validate (re-resolvida a cada validação); 'M' = escolha
-- manual do cliente (nunca sobrescrita). FK da regra não é física (mesma
-- escolha da 031: regra soft-deletada é detectada no faturamento).
CREATE TABLE IF NOT EXISTS `tb_order_item_service_tax_rule` (
  `tb_order_id`             int(11) NOT NULL,
  `tb_order_item_id`        int(11) NOT NULL,
  `tb_institution_id`       int(11) NOT NULL,
  `terminal`                int(11) NOT NULL DEFAULT 0,
  `kind`                    varchar(50) NOT NULL DEFAULT 'Service',
  `tb_service_tax_rule_id`  int(11) NOT NULL,
  `origin`                  char(1) NOT NULL,
  `created_at`              datetime DEFAULT NULL,
  `updated_at`              datetime DEFAULT NULL,
  `deleted`                 char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`tb_order_id`,`tb_order_item_id`,`tb_institution_id`,`terminal`,`kind`),
  KEY `idx_oistr_rule` (`tb_institution_id`,`tb_service_tax_rule_id`),
  CONSTRAINT `fk_oistr_order` FOREIGN KEY (`tb_order_id`,`tb_institution_id`,`terminal`)
    REFERENCES `tb_order` (`id`,`tb_institution_id`,`terminal`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tb_tax_rule` (
  `id`                 INT(11) NOT NULL,
  `tb_institution_id`  INT(11) NOT NULL,
  `tb_product_id`      INT(11) DEFAULT NULL,
  `tb_entity_id`       INT(11) DEFAULT NULL,
  `ncm`                VARCHAR(8) DEFAULT NULL,
  `origin`             CHAR(1) NOT NULL,
  `final_consumer`     CHAR(1) NOT NULL DEFAULT 'N',
  `simples`            CHAR(1) NOT NULL DEFAULT 'N',
  `st`                 CHAR(1) NOT NULL DEFAULT 'N',
  `purpose`            CHAR(1) NOT NULL DEFAULT '0',
  `direction`          CHAR(1) NOT NULL DEFAULT 'S',
  `tb_cfop_id`         VARCHAR(10) DEFAULT NULL,
  `tb_state_id`        INT(11) DEFAULT NULL,
  `tb_observation_id`  INT(11) DEFAULT NULL,
  `tb_taxes_id`        INT(11) DEFAULT NULL,
  `created_at`         DATETIME DEFAULT NULL,
  `updated_at`         DATETIME DEFAULT NULL,
  `deleted`            CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`),
  KEY `idx_tax_rule_selector` (`tb_institution_id`,`origin`,`st`,`final_consumer`,`simples`,`purpose`),
  KEY `idx_tax_rule_ncm` (`ncm`),
  KEY `idx_tax_rule_cfop` (`tb_cfop_id`),
  CONSTRAINT `fk_tax_rule_entity` FOREIGN KEY (`tb_entity_id`) REFERENCES `setes_central`.`tb_entity` (`id`),
  CONSTRAINT `fk_tax_rule_state` FOREIGN KEY (`tb_state_id`) REFERENCES `setes_central`.`tb_state` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tb_tax_rule_icms` (
  `id`                          INT(11) NOT NULL,
  `tb_tax_icms_nr_id`           CHAR(2) DEFAULT NULL,
  `tb_tax_icms_sn_id`           CHAR(3) DEFAULT NULL,
  `tb_deter_base_tax_icms_id`   CHAR(2) DEFAULT NULL,
  `tb_discharge_icms_id`        INT(11) DEFAULT NULL,
  `aliq`                        DECIMAL(10,2) DEFAULT NULL,
  `aliq_reduction`              DECIMAL(10,2) DEFAULT NULL,
  `base_reduction`              DECIMAL(10,2) DEFAULT NULL,
  `deferred`                    CHAR(1) NOT NULL DEFAULT 'N',
  `deferred_aliq`               DECIMAL(10,2) DEFAULT NULL,
  `highlight`                   CHAR(1) NOT NULL DEFAULT 'N',
  `created_at`                  DATETIME DEFAULT NULL,
  `updated_at`                  DATETIME DEFAULT NULL,
  `deleted`                     CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_txr_icms_rule` FOREIGN KEY (`id`) REFERENCES `tb_tax_rule` (`id`),
  CONSTRAINT `fk_txr_icms_discharge` FOREIGN KEY (`tb_discharge_icms_id`) REFERENCES `setes_central`.`tb_discharge_icms` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tb_tax_rule_icms_st` (
  `id`                             INT(11) NOT NULL,
  `tb_deter_base_tax_icms_st_id`   CHAR(2) DEFAULT NULL,
  `propagate_base_reduction`       CHAR(1) NOT NULL DEFAULT 'N',
  `created_at`                     DATETIME DEFAULT NULL,
  `updated_at`                     DATETIME DEFAULT NULL,
  `deleted`                        CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_txr_st_rule` FOREIGN KEY (`id`) REFERENCES `tb_tax_rule` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tb_tax_rule_ipi` (
  `id`              INT(11) NOT NULL,
  `tb_tax_ipi_id`   CHAR(2) NOT NULL,
  `aliq`            DECIMAL(10,2) DEFAULT NULL,
  `created_at`      DATETIME DEFAULT NULL,
  `updated_at`      DATETIME DEFAULT NULL,
  `deleted`         CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_txr_ipi_rule` FOREIGN KEY (`id`) REFERENCES `tb_tax_rule` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tb_tax_rule_pis_cofins` (
  `id`          INT(11) NOT NULL,
  `kind`        CHAR(1) NOT NULL,
  `cst`         CHAR(2) NOT NULL,
  `aliq`        DECIMAL(10,2) DEFAULT NULL,
  `created_at`  DATETIME DEFAULT NULL,
  `updated_at`  DATETIME DEFAULT NULL,
  `deleted`     CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`,`kind`),
  CONSTRAINT `fk_txr_piscofins_rule` FOREIGN KEY (`id`) REFERENCES `tb_tax_rule` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tb_tax_rule_ii` (
  `id`             INT(11) NOT NULL,
  `ii_aliq`        DECIMAL(10,2) DEFAULT NULL,
  `irpj_aliq`      DECIMAL(10,2) DEFAULT NULL,
  `csll_aliq`      DECIMAL(10,2) DEFAULT NULL,
  `afrmm_aliq`     DECIMAL(10,5) DEFAULT NULL,
  `siscomex_aliq`  DECIMAL(10,5) DEFAULT NULL,
  `created_at`     DATETIME DEFAULT NULL,
  `updated_at`     DATETIME DEFAULT NULL,
  `deleted`        CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_txr_ii_rule` FOREIGN KEY (`id`) REFERENCES `tb_tax_rule` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- Parcelamento ELABORADO da ordem (decisões 25/31): presença = negociação
-- parcela a parcela; ausência = o prazo string do tb_order_billing gera as
-- parcelas no faturamento. O financeiro só consome o materializado.
CREATE TABLE IF NOT EXISTS `tb_order_installment` (
  `tb_institution_id`    INT(11) NOT NULL,
  `tb_order_id`          INT(11) NOT NULL,
  `terminal`             INT(11) NOT NULL DEFAULT 0,
  `parcel`               SMALLINT NOT NULL,
  `due_date`             DATE NOT NULL,
  `amount`               DECIMAL(15,2) NOT NULL,
  `tb_payment_types_id`  INT(11) DEFAULT NULL,
  `created_at`           DATETIME DEFAULT NULL,
  `updated_at`           DATETIME DEFAULT NULL,
  `deleted`              CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`tb_institution_id`,`tb_order_id`,`terminal`,`parcel`),
  CONSTRAINT `fk_order_installment_order` FOREIGN KEY (`tb_order_id`,`tb_institution_id`,`terminal`) REFERENCES `tb_order` (`id`,`tb_institution_id`,`terminal`),
  CONSTRAINT `fk_order_installment_paytype` FOREIGN KEY (`tb_payment_types_id`) REFERENCES `setes_central`.`tb_payment_types` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ============================================================================
-- W2 Onda 2 (2026-08-20) — Catálogo MVA/FCP por UF×NCM.
-- Fonte: Infra-IA/prompts/prompt_fase_faturamento_financeiro.md (Rodada 3 +
-- desenho do Valdo) + tributacao.md P2.7/P3.1/P7.1. Dado FISCAL INTERPRETÁVEL
-- (decisão Q22): schema do CLIENTE, sem compartilhamento entre institutions —
-- cada contador tem sua leitura do MVA; divergência não é mediável pela Setes.
-- Chave UF × NCM × institution (P2.7): a mesma tabela serve ICMS-ST (alíquota/
-- MVA pela UF do DESTINATÁRIO) e ICMS próprio no Simples (alíquota NR pela UF
-- do EMITENTE) — quem escolhe o stateId é o caller do motor, não a tabela.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `tb_state_mva_ncm` (
  `id`                 INT(11) NOT NULL,
  `tb_institution_id`  INT(11) NOT NULL,
  `tb_state_id`        INT(11) NOT NULL,
  `ncm`                VARCHAR(8) NOT NULL,
  `internal_aliq`      DECIMAL(10,2) NOT NULL DEFAULT 0,
  `mva_original`       DECIMAL(10,4) NOT NULL DEFAULT 0,
  `mva_adjusted`       DECIMAL(10,4) DEFAULT NULL,
  `created_at`         DATETIME DEFAULT NULL,
  `updated_at`         DATETIME DEFAULT NULL,
  `deleted`            CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_state_mva_ncm` (`tb_institution_id`,`tb_state_id`,`ncm`),
  CONSTRAINT `fk_state_mva_ncm_state` FOREIGN KEY (`tb_state_id`) REFERENCES `setes_central`.`tb_state` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- Match do NCM: IGUALDADE EXATA (mesma fidelidade da decisão 36 do motor da
-- regra) — sem prefixo aqui, diferente do FCP abaixo.

CREATE TABLE IF NOT EXISTS `tb_state_fcp_ncm` (
  `id`                 INT(11) NOT NULL,
  `tb_institution_id`  INT(11) NOT NULL,
  `tb_state_id`        INT(11) NOT NULL,
  `ncm`                VARCHAR(8) NOT NULL,
  `aliq`               DECIMAL(10,2) NOT NULL DEFAULT 0,
  `created_at`         DATETIME DEFAULT NULL,
  `updated_at`         DATETIME DEFAULT NULL,
  `deleted`            CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_state_fcp_ncm` (`tb_institution_id`,`tb_state_id`,`ncm`),
  CONSTRAINT `fk_state_fcp_ncm_state` FOREIGN KEY (`tb_state_id`) REFERENCES `setes_central`.`tb_state` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- Match do NCM: PREFIXO (P7.1 — "o NCM da tabela pode ser parcial; a
-- primeira linha que casar vence"; resolver escolhe o prefixo MAIS
-- específico, não a ordem de inserção).

-- ============================================================================
-- W2 Onda 3 (2026-08-20) — Regra de tributação POR ITEM da ordem.
-- Port da TB_ITENS_NFL_TRIBUTACAO (P2.6b — modo RegraDireta) com papel
-- ampliado (rodada R4): a VALIDAÇÃO do faturamento grava a regra achada
-- (origin 'A'); a escolha manual do cliente é origin 'M' e nunca é
-- sobrescrita. O faturamento consome a regra gravada sem rebuscar (mata a
-- dupla checagem do legado). PK inclui kind (correção sobre o legado).
-- Migration correspondente: setes-api 031.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `tb_order_item_tax_rule` (
  `tb_order_id`        INT(11) NOT NULL,
  `tb_order_item_id`   INT(11) NOT NULL,
  `tb_institution_id`  INT(11) NOT NULL,
  `terminal`           INT(11) NOT NULL DEFAULT 0,
  `kind`               VARCHAR(50) NOT NULL DEFAULT 'Sale',
  `tb_tax_rule_id`     INT(11) NOT NULL,
  `tb_cfop_id`         VARCHAR(10) DEFAULT NULL,
  `set_financial`      CHAR(1) NOT NULL DEFAULT 'S',
  `origin`             CHAR(1) NOT NULL,
  `created_at`         DATETIME DEFAULT NULL,
  `updated_at`         DATETIME DEFAULT NULL,
  `deleted`            CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`tb_order_id`,`tb_order_item_id`,`tb_institution_id`,`terminal`,`kind`),
  KEY `idx_oitr_rule` (`tb_institution_id`,`tb_tax_rule_id`),
  CONSTRAINT `fk_oitr_order` FOREIGN KEY (`tb_order_id`,`tb_institution_id`,`terminal`)
    REFERENCES `tb_order` (`id`,`tb_institution_id`,`terminal`)
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ============================================================================
-- Comissão + Devolução (2026-08-24) — rodada Q1–Q5 do Valdo + parecer
-- setes-conceito. Comissão = lançamento IMUTÁVEL por ITEM faturado
-- (devolução = value NEGATIVO, nunca UPDATE/DELETE); tb_order_item_return =
-- elo item devolvido → item vendido (equiv. TB_ITENS_DEV, saldo devolvível
-- DERIVADO); tb_order_stock_adjust_return = âncora do ajuste no pedido de
-- venda original (vendedor DERIVADO do tb_order_sale — D3). tb_kickback do
-- baseline foi DROPADA (mesmo conceito, nome errado — DROP autorizado).
-- Migration correspondente: setes-api 035.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `tb_commission` (
  `id`                 INT(11) NOT NULL,
  `tb_institution_id`  INT(11) NOT NULL,
  `terminal`           INT(11) NOT NULL DEFAULT 0,
  `kind`               CHAR(1) NOT NULL DEFAULT 'F',
  `tb_order_id`        INT(11) NOT NULL,
  `tb_order_item_id`   INT(11) NOT NULL,
  `tb_order_item_kind` VARCHAR(50) NOT NULL DEFAULT 'Sale',
  `tb_customer_id`     INT(11) NOT NULL,
  `tb_salesman_id`     INT(11) NOT NULL,
  `base_value`         DECIMAL(10,2) NOT NULL,
  `aliq`               DECIMAL(10,2) NOT NULL,
  `value`              DECIMAL(10,2) NOT NULL,
  `dt_payment`         DATE DEFAULT NULL,
  `created_at`         DATETIME DEFAULT NULL,
  `updated_at`         DATETIME DEFAULT NULL,
  `deleted`            CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`,`tb_institution_id`,`terminal`),
  KEY `idx_commission_item` (`tb_institution_id`,`tb_order_id`,`tb_order_item_id`),
  KEY `idx_commission_salesman` (`tb_institution_id`,`tb_salesman_id`),
  CONSTRAINT `fk_commission_order` FOREIGN KEY (`tb_order_id`,`tb_institution_id`,`terminal`)
    REFERENCES `tb_order` (`id`,`tb_institution_id`,`terminal`)
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- kind: 'F'aturamento | 'R'ecebimento (modo por config — Q5; só 'F' tem
-- produtor na versão mínima).

CREATE TABLE IF NOT EXISTS `tb_order_item_return` (
  `id`                   INT(11) NOT NULL,
  `tb_institution_id`    INT(11) NOT NULL,
  `tb_order_id`          INT(11) NOT NULL,
  `terminal`             INT(11) NOT NULL DEFAULT 0,
  `kind`                 VARCHAR(50) NOT NULL DEFAULT 'Adjust',
  `tb_order_id_ori`      INT(11) NOT NULL,
  `tb_order_item_id_ori` INT(11) NOT NULL,
  `terminal_ori`         INT(11) NOT NULL DEFAULT 0,
  `kind_ori`             VARCHAR(50) NOT NULL DEFAULT 'Sale',
  `created_at`           DATETIME DEFAULT NULL,
  `updated_at`           DATETIME DEFAULT NULL,
  `deleted`              CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`,`tb_institution_id`,`tb_order_id`,`terminal`,`kind`),
  KEY `idx_item_return_ori` (`tb_institution_id`,`tb_order_id_ori`,`tb_order_item_id_ori`),
  CONSTRAINT `fk_item_return_item` FOREIGN KEY
    (`id`,`tb_institution_id`,`tb_order_id`,`terminal`,`kind`)
    REFERENCES `tb_order_item` (`id`,`tb_institution_id`,`tb_order_id`,`terminal`,`kind`)
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;
-- COLLATE general_ci: a FK composta inclui `kind` VARCHAR e precisa casar
-- com a colação do tb_order_item do baseline (divergir = errno 150).

CREATE TABLE IF NOT EXISTS `tb_order_stock_adjust_return` (
  `id`                INT(11) NOT NULL,
  `tb_institution_id` INT(11) NOT NULL,
  `terminal`          INT(11) NOT NULL DEFAULT 0,
  `tb_order_id_ori`   INT(11) NOT NULL,
  `terminal_ori`      INT(11) NOT NULL DEFAULT 0,
  `created_at`        DATETIME DEFAULT NULL,
  `updated_at`        DATETIME DEFAULT NULL,
  `deleted`           CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`,`tb_institution_id`,`terminal`),
  KEY `idx_adjust_return_ori` (`tb_institution_id`,`tb_order_id_ori`),
  CONSTRAINT `fk_adjust_return_adjust` FOREIGN KEY (`id`,`tb_institution_id`,`terminal`)
    REFERENCES `tb_order_stock_adjust` (`id`,`tb_institution_id`,`terminal`)
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
