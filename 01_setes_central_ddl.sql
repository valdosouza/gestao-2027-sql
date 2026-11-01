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
  `updated_by`         int(11) DEFAULT NULL,
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
  `password_set_at` datetime DEFAULT NULL,  -- D-EA7: instante (UTC) em que a senha atual foi definida — token com iat anterior = revogado
  `active`         char(1) NOT NULL DEFAULT 'S',
  `activation_key` varchar(255) DEFAULT NULL,
  `created_at`     datetime DEFAULT NULL,
  `updated_at`     datetime DEFAULT NULL,
  `deleted`        char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_user_to_entity` FOREIGN KEY (`id`) REFERENCES `tb_entity` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Pedido de troca de senha (Q-PV38 / D-PV13, 2026-10-18 — espelho do script 67; parecer do guardião): a autorização de uso
-- único para redefinir a senha, provada por um código de 6 dígitos enviado ao e-mail de login. Uma linha por código emitido;
-- vale só o de MAIOR seq, não usado (used_at), dentro do prazo (15 min por created_at) e abaixo do teto de tentativas erradas
-- (tudo derivado). O código nunca é guardado: code_hmac = HMAC-SHA256 de user:seq:hash da senha:e-mail de login:código (segredo
-- fora do banco). seq = MAX+1 POR USUÁRIO sob a trava da linha de tb_user (PADROES §9 regras 12 e 13). Nada se apaga (§3.1).
CREATE TABLE IF NOT EXISTS `tb_user_password_reset` (
  `tb_user_id`      int(11)     NOT NULL COMMENT 'Usuario dono da credencial',
  `seq`             int(11)     NOT NULL COMMENT 'N-esimo codigo do usuario: MAX+1 sob FOR UPDATE da linha tb_user; vale so o maior',
  `code_hmac`       char(64)    NOT NULL COMMENT 'HMAC-SHA256 hex de user:seq:hash da senha:e-mail de login:codigo (segredo fora do banco) - nunca o codigo',
  `failed_attempts` smallint(6) NOT NULL DEFAULT 0 COMMENT 'Tentativas erradas enquanto o codigo valia (para no teto)',
  `used_at`         datetime    DEFAULT NULL COMMENT 'Instante UTC do uso - write-once (NULL -> instante)',
  `created_at`      datetime    NOT NULL COMMENT 'Instante UTC da emissao = inicio do prazo',
  `updated_at`      datetime    DEFAULT NULL,
  `deleted`         char(1)     NOT NULL DEFAULT 'N',
  PRIMARY KEY (`tb_user_id`, `seq`),
  CONSTRAINT `fk_user_password_reset_to_user` FOREIGN KEY (`tb_user_id`) REFERENCES `tb_user` (`id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `ck_user_password_reset_seq` CHECK (`seq` > 0),
  CONSTRAINT `ck_user_password_reset_code_hmac` CHECK (`code_hmac` COLLATE utf8mb4_bin REGEXP '^[0-9a-f]{64}$'),
  CONSTRAINT `ck_user_password_reset_failed_attempts` CHECK (`failed_attempts` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Aviso ao DONO da conta (D-RS4, Valdo 2026-10-20 — espelho do script 67; parecer do guardião 2026-10-21): fato da CONTA (não do
-- código), IRMÃ de tb_user_password_reset sob tb_user — o sistema avisou o titular, pelo e-mail de login GRAVADO, que alguém está
-- forçando a recuperação da conta dele. Uma linha por aviso; `kind` = a CAUSA de lista fechada (forense, nunca vai ao texto do e-mail,
-- que é neutro): E = código esgotado por tentativas erradas · C = teto de emissões por conta atingido. created_at = instante em que o
-- sistema TOMOU a vaga da hora (o SMTP corre depois do COMMIT); coalescência = existe aviso do usuário há < 1 h (lida sob a trava da
-- linha de tb_user, na MESMA transação que detectou o gatilho — regras 12/13). Não entra no teto de códigos (tabela própria); sem FK
-- para o código (no caso C não existe código). seq = MAX+1 POR USUÁRIO. Nada se apaga (§3.1).
CREATE TABLE IF NOT EXISTS `tb_user_password_reset_notice` (
  `tb_user_id` int(11)  NOT NULL COMMENT 'Usuario dono da credencial avisado',
  `seq`        int(11)  NOT NULL COMMENT 'N-esimo aviso do usuario: MAX+1 sob FOR UPDATE da linha tb_user',
  `kind`       char(1)  NOT NULL COMMENT 'Causa (forense): E = codigo esgotado por erradas | C = teto de emissoes atingido',
  `created_at` datetime NOT NULL COMMENT 'Instante UTC em que o sistema tomou a vaga da hora (e-mail sai depois do COMMIT)',
  `updated_at` datetime DEFAULT NULL,
  `deleted`    char(1)  NOT NULL DEFAULT 'N',
  PRIMARY KEY (`tb_user_id`, `seq`),
  CONSTRAINT `fk_user_password_reset_notice_to_user` FOREIGN KEY (`tb_user_id`) REFERENCES `tb_user` (`id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `ck_user_password_reset_notice_seq`  CHECK (`seq` > 0),
  CONSTRAINT `ck_user_password_reset_notice_kind` CHECK (`kind` COLLATE utf8mb4_bin IN ('E', 'C'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- Especializações fiscais da entidade (herança por PK compartilhada — decisão 1)
-- ---------------------------------------------------------------------

-- PJ (preenchida quando a UI informar Pessoa Jurídica com CNPJ válido).
-- Fase 3 Rodada 4 (decisão 16, 2026-07-16): os campos FISCAIS (crt, crt_modal,
-- ind_ie_destinatario, iss_*, send_xml_nfe_only) SAÍRAM daqui — tributação é
-- POR RELAÇÃO COMERCIAL e vive em setes_<schema>.tb_entity_tax (fonte única).
CREATE TABLE IF NOT EXISTS `tb_company` (
  `id`                  int(11) NOT NULL,
  `cnpj`                char(14) NOT NULL DEFAULT '0',
  `ie`                  varchar(45) DEFAULT NULL,
  `im`                  varchar(45) DEFAULT NULL,
  `iest`                varchar(45) DEFAULT NULL,
  `dt_foundation`       date DEFAULT NULL,
  `created_at`          datetime NOT NULL,
  `updated_at`          datetime NOT NULL,
  `deleted`             char(1) NOT NULL DEFAULT 'N',
  `updated_by`          int(11) DEFAULT NULL,
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
  `updated_by`       int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `cpf` (`cpf`),
  CONSTRAINT `fk_person_to_entity` FOREIGN KEY (`id`) REFERENCES `tb_entity` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Sem documento (Fase 3 Entidade Única, decisões 4 e 5): terceira via de
-- identificação — pessoa que não fornece CPF/CNPJ. external_id = UUID v4
-- gerado no backend (app) ou chave do legado (sincronizador, fase futura).
CREATE TABLE IF NOT EXISTS `tb_no_doc` (
  `id`          int(11) NOT NULL,
  `external_id` varchar(255) NOT NULL,
  `created_at`  datetime DEFAULT NULL,
  `updated_at`  datetime DEFAULT NULL,
  `deleted`     char(1) NOT NULL DEFAULT 'N',
  `updated_by`  int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_no_doc_external` (`external_id`),
  CONSTRAINT `fk_no_doc_to_entity` FOREIGN KEY (`id`) REFERENCES `tb_entity` (`id`)
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
  `updated_by`    int(11) DEFAULT NULL,
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
  `updated_by`   int(11) DEFAULT NULL,
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
  `updated_by` int(11) DEFAULT NULL,
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
  `i18n_key`      varchar(100) DEFAULT NULL,  -- chave de tradução no app (setes-app decisão 26); NULL = mostra description
  `description`   varchar(100) DEFAULT NULL,
  -- Framework de Configurações (decisão 13): 'T' = tela (vai a menu);
  -- 'R' = recurso/aba vendável (NUNCA vai a menu — a tela pai consulta o
  -- contrato tb_institution_has_interface para montar/omitir a aba).
  -- Coluna legada varchar(26) reaproveitada: bootstrap-db.ts normaliza os
  -- valores antigos para 'T' e aperta o tipo em bases existentes.
  `kind`          char(1) NOT NULL DEFAULT 'T',
  `position`      varchar(10) DEFAULT NULL,
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

-- Catálogo de CAMPOS por interface (setes-app Fase 2 campos configuráveis,
-- decisões 4 e 12): baseline TÉCNICO do produto — required='S' = campo
-- travado no painel do cliente. Sem reuso entre interfaces (decisão 4).
-- Povoada por setes-api `npm run fields:gen` (interface ≠ tabela).
-- COLLATE explícito: a FK composta de setes_<schema>.tb_institution_has_field
-- inclui field_name — as collations precisam coincidir.
CREATE TABLE IF NOT EXISTS `tb_interface_has_field` (
  `tb_interface_id` int(11) NOT NULL,
  `field_name`      varchar(100) NOT NULL,      -- nome da coluna conforme a tabela
  `table_name`      varchar(100) DEFAULT NULL,  -- tabela de origem
  `kind`            varchar(50) NOT NULL,       -- String | Integer | Float | Boolean | Date
  `required`        char(1) NOT NULL DEFAULT 'N',
  `created_at`      datetime DEFAULT NULL,
  `updated_at`      datetime DEFAULT NULL,
  `deleted`         char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`tb_interface_id`,`field_name`),
  CONSTRAINT `fk_ihf_to_interface` FOREIGN KEY (`tb_interface_id`) REFERENCES `tb_interface` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Catálogo de CONFIGURAÇÕES por interface (Framework de Configurações do
-- Sistema, decisões 2, 4 e 6 — prompt_framework_configuracoes_sistema.md).
-- Substituto do TB_GERAL do Delphi: nome + descrição + default de TODAS as
-- opções visíveis ao suporte. Só PREFERÊNCIA/COMPORTAMENTO entra aqui —
-- recurso VENDÁVEL é interface (kind 'R') gateada pelo contrato (decisão 1).
-- Valores escolhidos ficam em setes_<schema>.tb_institution_has_config
-- (só grava o que diverge do default). COLLATE explícito: a FK composta do
-- schema do cliente inclui `name` — as collations precisam coincidir.
CREATE TABLE IF NOT EXISTS `tb_interface_has_config` (
  `tb_interface_id` int(11) NOT NULL,
  `name`            varchar(50)  NOT NULL,             -- chave da configuração (ex-GRL_CAMPO)
  `description`     varchar(255) NOT NULL,             -- ex-GRL_DESCRICAO — obrigatória: é o que salva o suporte
  `kind`            varchar(50)  NOT NULL,             -- String|Integer|Float|Boolean|Date|Options (decisão 6)
  `options`         varchar(255) DEFAULT NULL,         -- lista fechada p/ kind Options: "A=Por item;B=Por total"
  `default_content` varchar(100) NOT NULL,             -- padrão inicial do produto
  `scope`           char(1)      NOT NULL DEFAULT 'I', -- 'I'=só institution; 'U'=admite override por usuário (decisão 4)
  `created_at`      datetime DEFAULT NULL,
  `updated_at`      datetime DEFAULT NULL,
  `deleted`         char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`tb_interface_id`, `name`),
  CONSTRAINT `fk_ihc_interface` FOREIGN KEY (`tb_interface_id`)
    REFERENCES `tb_interface` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- setes-app Fase 1 (Fundação) — preferências do usuário e tema por
-- institution (prompt_fase1_fundacao.md, decisões 14 e 16)
-- ---------------------------------------------------------------------

-- Preferências chave/valor por usuário (decisão 14 setes-app).
-- Primeira preferência: 'locale' (i18n). Institution padrão NÃO entra aqui
-- (fica local no dispositivo — decisão 15 setes-app).
CREATE TABLE IF NOT EXISTS `tb_user_has_preference` (
  `tb_user_id`       int(11) NOT NULL,
  `preference_key`   varchar(50) NOT NULL,
  `preference_value` varchar(255) DEFAULT NULL,
  `created_at`       datetime DEFAULT NULL,
  `updated_at`       datetime DEFAULT NULL,
  `deleted`          char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`tb_user_id`,`preference_key`),
  CONSTRAINT `fk_uhp_to_user` FOREIGN KEY (`tb_user_id`) REFERENCES `tb_user` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tema/identidade visual por institution (decisão 16 setes-app).
-- Herança por PK compartilhada (decisão 1 da Fase 2): id = tb_institution.id.
-- Logomarca: arquivo em storage servido pela API (logo_path) — nunca BLOB.
CREATE TABLE IF NOT EXISTS `tb_institution_theme` (
  `id`              int(11) NOT NULL,
  `primary_color`   varchar(9) DEFAULT NULL,   -- #AARRGGBB
  `secondary_color` varchar(9) DEFAULT NULL,
  `logo_path`       varchar(255) DEFAULT NULL, -- servido por GET /api/core/theme/logo
  `created_at`      datetime DEFAULT NULL,
  `updated_at`      datetime DEFAULT NULL,
  `deleted`         char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_theme_to_institution` FOREIGN KEY (`id`) REFERENCES `tb_institution` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- Referência fiscal
-- ---------------------------------------------------------------------

-- Formas de pagamento (Valdo, 2026-07-18): catálogo COMPARTILHADO entre os
-- clientes — o CLIENTE inicia o cadastro (existe? só vincula; não existe?
-- cria aqui e vincula — reuso entre clientes, mesmo espírito da entidade
-- única). O vínculo/uso por institution vive em
-- setes_<schema>.tb_institution_has_payment_types (atributos do vínculo —
-- migration 012: enable/app_mobile/bloqueios/parcelas/TEF/planos/uso).
-- id MAX+1 no backend; id_nfce = código de pagamento da NF-e (2 chars,
-- lista fiscal fixa — combobox no app; EDITÁVEL pela tela, vale p/ todos).
-- description é imutável (chave do reuso). KEY updated_at = sync incremental.
-- kind (decisões 16/26/32 da fase Faturamento/Financeiro, migration 027):
-- comportamento de QUITAÇÃO do meio — 'E' espécie, 'X' PIX, 'Q' cheque,
-- 'B' boleto, 'W' carteira/fiado, 'C' cartão, 'O' outros. Backfill único por
-- mapa determinístico id_nfce→kind; depois, SÓ o kind classifica (nunca a
-- descrição). Forma nova define kind no cadastro (sugerido pelo id_nfce).
CREATE TABLE IF NOT EXISTS `tb_payment_types` (
  `id`          int(11) NOT NULL,
  `description` varchar(45) NOT NULL,
  `id_nfce`     varchar(2) DEFAULT NULL,
  `kind`        char(1) NOT NULL DEFAULT 'O',
  `created_at`  datetime DEFAULT NULL,
  `updated_at`  datetime DEFAULT NULL,
  `deleted`     char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`),
  KEY `updated_at` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Catálogos de produto COMPARTILHADOS (revisão do sincronizador, decisões
-- D5/D17/D24 — Valdo 2026-07-19): Marca/Embalagem/Medida seguem o padrão
-- "catálogo central iniciado pelo cliente" (molde tb_payment_types acima):
-- registro ÚNICO por DESCRIÇÃO — dedupe por UPPER(TRIM(descricao)) SEM
-- colapsar acentos (D17; por isso SEM UNIQUE KEY na coluna: a collation
-- unicode_ci fundiria 'AÇO' com 'ACO' — o dedupe é da aplicação, dentro da
-- transação). Vínculo/uso por institution em setes_<schema>.
-- tb_institution_has_{brand,package,measure} (migration 018 realinha o
-- baseline legado). A central nasce VAZIA (D24 — sem dedupe retroativo).
-- tb_provider_id da tb_brand legada NÃO sobe: provider é papel POR CLIENTE
-- — catálogo compartilhado não pode referenciar papel de um cliente.
CREATE TABLE IF NOT EXISTS `tb_brand` (
  `id`          int(11) NOT NULL,
  `description` varchar(100) NOT NULL,
  `created_at`  datetime DEFAULT NULL,
  `updated_at`  datetime DEFAULT NULL,
  `deleted`     char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`),
  KEY `description` (`description`),
  KEY `updated_at` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tb_package` (
  `id`           int(11) NOT NULL,
  `description`  varchar(100) NOT NULL,
  `abbreviation` varchar(3) DEFAULT NULL,
  `created_at`   datetime DEFAULT NULL,
  `updated_at`   datetime DEFAULT NULL,
  `deleted`      char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`),
  KEY `description` (`description`),
  KEY `updated_at` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tb_measure` (
  `id`           int(11) NOT NULL,
  `description`  varchar(100) NOT NULL,
  `abbreviation` varchar(5) DEFAULT NULL,
  `escale`       decimal(10,2) DEFAULT NULL,
  `created_at`   datetime DEFAULT NULL,
  `updated_at`   datetime DEFAULT NULL,
  `deleted`      char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`),
  KEY `description` (`description`),
  KEY `updated_at` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- RASTRO DE ERRO TÉCNICO (Framework de Mensagens R2, Valdo 2026-07-19):
-- tb_crashlytics REFORMADA do baseline e movida p/ a CENTRAL (suporte da
-- Setes enxerga todos os clientes numa consulta; a local dos schemas é
-- derrubada pela migration 017). ref = código curto exibido ao usuário no
-- dialog de erro; code = catálogo de erros conhecidos (tb_error_catalog);
-- message = JSON {message, stack}. ⚠️ AUTO_INCREMENT é a EXCEÇÃO
-- documentada do padrão MAX+1 (PADROES_BANCO §4): log de erro não pode
-- falhar por corrida de lock justamente quando algo já deu errado.
CREATE TABLE IF NOT EXISTS `tb_crashlytics` (
  `id`                int(11) NOT NULL AUTO_INCREMENT,
  `tb_institution_id` int(11) NOT NULL DEFAULT 0,
  `tb_user_id`        int(11) NOT NULL DEFAULT 0,
  `origen`            varchar(100) NOT NULL,
  `ref`               varchar(12) DEFAULT NULL,
  `code`              varchar(40) DEFAULT NULL,
  `status_code`       int(11) DEFAULT NULL,
  `message`           blob DEFAULT NULL,
  `created_at`        datetime DEFAULT NULL,
  `updated_at`        datetime DEFAULT NULL,
  `deleted`           char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`),
  UNIQUE KEY `ref` (`ref`),
  KEY `code` (`code`),
  KEY `created_at` (`created_at`),
  KEY `idx_crash_institution` (`tb_institution_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Catálogo de ERROS CONHECIDOS (Framework de Mensagens R8): tabela de
-- REFERÊNCIA derivada de setes-api/src/shared/errors/error-codes.ts por
-- `npm run errors:gen` (NUNCA editada à mão — a fonte é o código, que
-- nasce no mesmo commit do throw). Serve aos joins SQL com a crashlytics.
CREATE TABLE IF NOT EXISTS `tb_error_catalog` (
  `code`        varchar(40) NOT NULL,
  `description` varchar(200) NOT NULL,
  `created_at`  datetime DEFAULT NULL,
  `updated_at`  datetime DEFAULT NULL,
  `deleted`     char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Catálogo de BANCOS (DP2 do módulo Software House, Valdo 2026-07-18):
-- referência FEBRABAN compartilhada (como tb_country) — NÃO entra na
-- cadeia de entidade fiscal. Contas correntes e históricos de extrato
-- ficam por schema (tb_bank_account/tb_bank_historic com FK cross-schema).
CREATE TABLE IF NOT EXISTS `tb_bank` (
  `id`          int(11) NOT NULL,
  `number`      varchar(3) NOT NULL,
  `description` varchar(100) DEFAULT NULL,
  `created_at`  datetime DEFAULT NULL,
  `updated_at`  datetime DEFAULT NULL,
  `deleted`     char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`),
  UNIQUE KEY `number` (`number`),
  KEY `updated_at` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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

CREATE TABLE IF NOT EXISTS `tb_service_list` (
  `id`              varchar(10) NOT NULL,
  `description`     varchar(255) NOT NULL,
  `local_incidence` char(1) NOT NULL DEFAULT 'P',
  `active`          char(1) NOT NULL DEFAULT 'S',
  `created_at`      datetime DEFAULT NULL,
  `updated_at`      datetime DEFAULT NULL,
  `deleted`         char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Lista de Serviços da LC 116/2003 (+ LC 157/2016) — referência fiscal
-- CENTRAL (fato do mundo, como tb_cfop). id = o PRÓPRIO item ('1.01').
-- local_incidence: 'P' = município do PRESTADOR (regra geral, art. 3º) /
-- 'E' = município da EXECUÇÃO (exceções do art. 3º — construção, limpeza,
-- vigilância, diversões, transporte, portos...). Prompt
-- prompt_regra_tributacao_servico.md (D10/D12, 2026-09-02).

CREATE TABLE IF NOT EXISTS `tb_service_national_code` (
  `code`               char(6) NOT NULL COMMENT 'cTribNac (Anexo B do Padrão Nacional): item(2)+subitem(2)+desdobro(2)',
  `tb_service_list_id` varchar(10) NOT NULL COMMENT 'Subitem da LC 116 (tb_service_list.id, ex.: 1.02)',
  `description`        varchar(255) NOT NULL,
  `active`             char(1) NOT NULL DEFAULT 'S',
  `created_at`         datetime DEFAULT NULL,
  `updated_at`         datetime DEFAULT NULL,
  `deleted`            char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`code`),
  KEY `idx_service_national_code_list` (`tb_service_list_id`),
  CONSTRAINT `fk_service_national_code_list` FOREIGN KEY (`tb_service_list_id`) REFERENCES `tb_service_list` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Código de tributação NACIONAL da NFS-e (Anexo B v1.01, 22/01/2026): 338 códigos para os
-- ~200 subitens da LC 116 — um subitem pode ter VÁRIOS desdobros, por isso é catálogo
-- próprio (FK ao subitem) e não coluna de tb_service_list. CENTRAL (fato do mundo, como
-- tb_cfop). A regra de ISS (tb_service_tax_rule.national_code) escolhe o código —
-- pré-preenchido quando o subitem só tem um (Onda 3 NFS-e, D-N11/D-N11a).

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

-- ---------------------------------------------------------------------
-- Revisao correcao de documento / graduacao do sem-doc (2026-07-25,
-- prompt_correcao_documento_entidade.md decisao 2): fila central de
-- conflitos de sincronizacao para ACAO MANUAL (documento ja pertence a
-- outra entity / externalCode orfao com documento ocupado). Dedupe por
-- UNIQUE (institution+documento+external_code); resolved='S' fecha o item.
-- ---------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `tb_sync_conflict` (
  `id`                int(11) NOT NULL AUTO_INCREMENT,
  `tb_institution_id` int(11) NOT NULL,
  `document`          varchar(14) NOT NULL,
  `external_code`     varchar(36) DEFAULT NULL,
  `tb_entity_id_doc`  int(11) DEFAULT NULL,
  `tb_entity_id_ext`  int(11) DEFAULT NULL,
  `origin`            varchar(30) NOT NULL,
  `message`           varchar(255) DEFAULT NULL,
  `resolved`          char(1) NOT NULL DEFAULT 'N',
  `created_at`        datetime DEFAULT NULL,
  `updated_at`        datetime DEFAULT NULL,
  `deleted`           char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_sync_conflict` (`tb_institution_id`,`document`,`external_code`),
  KEY `idx_sync_conflict_resolved` (`resolved`),
  CONSTRAINT `fk_sync_conflict_institution` FOREIGN KEY (`tb_institution_id`) REFERENCES `tb_institution` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- Catálogo IBS/CBS (fase IBS/CBS, IB-1 — D-IB5/D-IB22/D-IB23/D-IB26; script 61)
-- Dados: rotina do Super setes-api/scripts/load-ibscbs-catalog.ts (IT 2025.002 + Anexo VII + NBS)
-- ---------------------------------------------------------------------

-- A1. CST do IBS/CBS (familia de tb_tax_pis/_cofins). Flags de grupo do CST (ind_gRed,
--     ind_gDif...) sem consumidor no 1º release — entram por coluna quando houver.
CREATE TABLE IF NOT EXISTS `tb_tax_ibscbs` (
  `id`                 CHAR(3) NOT NULL COMMENT 'CST do IBS/CBS (ex.: 000)',
  `description`        VARCHAR(255) NOT NULL,
  `source_version`     VARCHAR(30) NOT NULL COMMENT 'Proveniencia: ex. IT 2025.002 v1.70',
  `created_at`         DATETIME DEFAULT NULL,
  `updated_at`         DATETIME DEFAULT NULL,
  `deleted`            CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`),
  CONSTRAINT `ck_tax_ibscbs_id` CHECK (`id` REGEXP '^[0-9]{3}$')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- A2. IDENTIDADE do cClassTrib (D-IB22): o servico/regra presume o CODIGO, nao a versao.
--     CST = prefixo por construcao (E0959) — a regra "CST = prefixo" morre no CHECK.
CREATE TABLE IF NOT EXISTS `tb_tax_ibscbs_classification` (
  `code`               CHAR(6) NOT NULL COMMENT 'cClassTrib',
  `tb_tax_ibscbs_id`   CHAR(3) NOT NULL COMMENT 'CST = LEFT(code,3)',
  `created_at`         DATETIME DEFAULT NULL,
  `updated_at`         DATETIME DEFAULT NULL,
  `deleted`            CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`code`),
  KEY `idx_ibscbs_classification_cst` (`tb_tax_ibscbs_id`),
  CONSTRAINT `fk_ibscbs_classification_cst` FOREIGN KEY (`tb_tax_ibscbs_id`) REFERENCES `tb_tax_ibscbs` (`id`),
  CONSTRAINT `ck_ibscbs_classification_code` CHECK (`code` REGEXP '^[0-9]{6}$'),
  CONSTRAINT `ck_ibscbs_classification_cst` CHECK (`tb_tax_ibscbs_id` = LEFT(`code`, 3))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- A3. HISTORIA do cClassTrib (D-IB22/D-IB5): vigencia e a linha (dIniVig/dFimVig do IT).
--     Atributo corrigido sem dIniVig novo = UPDATE da mesma linha (source_* registram).
--     Linha nunca e apagada (nota antiga aponta codigo antigo).
CREATE TABLE IF NOT EXISTS `tb_tax_ibscbs_classification_validity` (
  `code`                       CHAR(6) NOT NULL,
  `valid_from`                 DATE NOT NULL COMMENT 'dIniVig',
  `valid_until`                DATE DEFAULT NULL COMMENT 'dFimVig; NULL = vigente',
  `name`                       VARCHAR(255) NOT NULL COMMENT 'Nome cClassTrib',
  `description`                VARCHAR(2000) NOT NULL COMMENT 'Descricao cClassTrib (max oficial 1.155)',
  `requires_regular_taxation`  CHAR(1) NOT NULL COMMENT 'ind_gTribRegular — classificacao que exige gTribRegular (o builder nao emite: 422 antes de faturar)',
  `source_version`             VARCHAR(30) NOT NULL COMMENT 'ex.: IT 2025.002 v1.70',
  `source_updated_at`          DATE NOT NULL COMMENT 'DataAtualizacao da linha oficial',
  `absent_since_version`       VARCHAR(30) DEFAULT NULL COMMENT 'versao da fonte (IT) em que a linha deixou de vir — NULL = presente (D-IB36, script 63)',
  `created_at`                 DATETIME DEFAULT NULL,
  `updated_at`                 DATETIME DEFAULT NULL,
  `deleted`                    CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`code`, `valid_from`),
  CONSTRAINT `fk_ibscbs_validity_classification` FOREIGN KEY (`code`) REFERENCES `tb_tax_ibscbs_classification` (`code`),
  CONSTRAINT `ck_ibscbs_validity_period` CHECK (`valid_until` IS NULL OR `valid_until` >= `valid_from`),
  CONSTRAINT `ck_ibscbs_validity_regular` CHECK (`requires_regular_taxation` IN ('S','N'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- A4. APLICABILIDADE por modelo de documento (presenca = aceita no documento; indNFSe/indNFe/indNFCe).
--     Modelo novo = linha nova. Carga so de SE agora; 55/65 entram como DADO na F4.
CREATE TABLE IF NOT EXISTS `tb_tax_ibscbs_classification_applicability` (
  `code`        CHAR(6) NOT NULL,
  `valid_from`  DATE NOT NULL,
  `model`       VARCHAR(2) NOT NULL COMMENT 'Dominio de tb_invoice.model: SE (NFS-e) · 55 · 65',
  `created_at`  DATETIME DEFAULT NULL,
  `updated_at`  DATETIME DEFAULT NULL,
  `deleted`     CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`code`, `valid_from`, `model`),
  CONSTRAINT `fk_ibscbs_applicability_validity` FOREIGN KEY (`code`, `valid_from`)
    REFERENCES `tb_tax_ibscbs_classification_validity` (`code`, `valid_from`),
  CONSTRAINT `ck_ibscbs_applicability_model` CHECK (`model` IN ('SE','55','65'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- A5. Indicador da operacao (cIndOp, Anexo VII — LC 214 art. 11). "operation" e palavra ocupada.
CREATE TABLE IF NOT EXISTS `tb_ibscbs_place_indicator` (
  `code`            CHAR(6) NOT NULL COMMENT 'cIndOp (ex.: 100301)',
  `description`     VARCHAR(1000) NOT NULL COMMENT 'Tipo de operacao + caracteristica + local do fornecimento (max oficial 535)',
  `source_version`  VARCHAR(30) NOT NULL COMMENT 'ex.: Anexo VII v1.03.00',
  `created_at`      DATETIME DEFAULT NULL,
  `updated_at`      DATETIME DEFAULT NULL,
  `deleted`         CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`code`),
  CONSTRAINT `ck_ibscbs_place_indicator_code` CHECK (`code` REGEXP '^[0-9]{6}$')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- A6. Aplicabilidade do cIndOp por modelo (indNFSe/indNFe do Anexo VII) — o lookup do servico so
--     oferece cIndOp aceito na NFS-e. Local de incidencia (NFSeLocIncidIBS) sem consumidor: fora.
CREATE TABLE IF NOT EXISTS `tb_ibscbs_place_indicator_applicability` (
  `code`        CHAR(6) NOT NULL,
  `model`       VARCHAR(2) NOT NULL,
  `created_at`  DATETIME DEFAULT NULL,
  `updated_at`  DATETIME DEFAULT NULL,
  `deleted`     CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`code`, `model`),
  CONSTRAINT `fk_place_indicator_applicability` FOREIGN KEY (`code`) REFERENCES `tb_ibscbs_place_indicator` (`code`),
  CONSTRAINT `ck_place_indicator_applicability_model` CHECK (`model` IN ('SE','55','65'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- A7. Nomenclatura Brasileira de Servicos (NBS 2.0, 9 digitos sem pontos; 920 codigos).
CREATE TABLE IF NOT EXISTS `tb_nbs` (
  `code`            CHAR(9) NOT NULL COMMENT 'NBS sem pontos (ex.: 115021000 = 1.1502.10.00)',
  `description`     VARCHAR(255) NOT NULL COMMENT 'max oficial 200',
  `source_version`  VARCHAR(30) NOT NULL,
  `created_at`      DATETIME DEFAULT NULL,
  `updated_at`      DATETIME DEFAULT NULL,
  `deleted`         CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`code`),
  CONSTRAINT `ck_nbs_code` CHECK (`code` REGEXP '^[0-9]{9}$')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- VIEWs CENTRAIS do VEREDITO DE ACESSO (costura A1 da frente auth-api — D-AU3/D-AU6, 2026-10-31; espelho do script 70).
-- vw_user_link = vínculo VIVO + perfil ('super' só na Setes, `kind` em binário e sem PAD SPACE); vw_interface_catalog = interface
-- viva (chave sem espaço à direita) + modo de concessão (delegável do Super — D-PV11). Literais amarrados às constantes do código
-- pelo boot do setes-api.
-- =====================================================================
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `setes_central`.`vw_user_link` AS
SELECT ihu.`tb_user_id`,
       ihu.`tb_institution_id`,
       i.`schema_name`,
       u.`password_set_at`,
       (CASE
          WHEN CHAR_LENGTH(ihu.`kind`) = CHAR_LENGTH(RTRIM(ihu.`kind`)) AND ihu.`kind` COLLATE utf8mb4_bin = 'super'
               AND ihu.`tb_institution_id` = 1 THEN 'super'                     -- 1 = SETES_INSTITUTION_ID (cerca)
          WHEN CHAR_LENGTH(ihu.`kind`) = CHAR_LENGTH(RTRIM(ihu.`kind`)) AND ihu.`kind` COLLATE utf8mb4_bin = 'admin' THEN 'admin'
          ELSE 'user'
        END) COLLATE utf8mb4_bin AS `profile`,
       (CASE WHEN ihu.`tb_institution_id` = 1 THEN 'S' ELSE 'N' END) COLLATE utf8mb4_bin AS `vendor`
  FROM `setes_central`.`tb_institution_has_user` ihu
  JOIN `setes_central`.`tb_user` u
    ON u.`id` = ihu.`tb_user_id` AND u.`active` = 'S' AND u.`deleted` = 'N'
  JOIN `setes_central`.`tb_institution` i
    ON i.`id` = ihu.`tb_institution_id` AND i.`active` = 'S' AND i.`deleted` = 'N'
 WHERE ihu.`active` = 'S' AND ihu.`deleted` = 'N';

CREATE OR REPLACE SQL SECURITY DEFINER VIEW `setes_central`.`vw_interface_catalog` AS
SELECT i.`id` AS `tb_interface_id`,
       i.`i18n_key` COLLATE utf8mb4_bin AS `interface_key`,
       (CASE WHEN i.`i18n_key` COLLATE utf8mb4_bin IN ('institution-interfaces')   -- = DELEGABLE_SUPER_INTERFACES (cerca)
             THEN 'S' ELSE 'N' END) COLLATE utf8mb4_bin AS `delegable`
  FROM `setes_central`.`tb_interface` i
 WHERE i.`deleted` = 'N'
   AND CHAR_LENGTH(i.`i18n_key`) = CHAR_LENGTH(RTRIM(i.`i18n_key`));     -- sem PAD SPACE: 'orders ' nunca responde por 'orders'
