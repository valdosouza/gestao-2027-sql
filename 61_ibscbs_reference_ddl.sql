-- =====================================================================
-- Script 61: REFERÊNCIAS do catálogo IBS/CBS em setes_central (fase IBS/CBS, IB-1).
-- Decisões: D-IB5, D-IB22 (identidade × história do cClassTrib), D-IB23 (fonte = IT
-- 2025.002; Calculadora confere), D-IB26 (CHECK de domínio) — Infra-IA/prompts/
-- prompt_fase_ibs_cbs.md §8/§10.5. Guardião + revisar-ddl: §10.3.
-- SÓ estrutura (as tabelas nascem vazias); os DADOS vêm da rotina do Super
-- `setes-api/scripts/load-ibscbs-catalog.ts` (ensaio por padrão; grava com --vai).
-- Aplicar ANTES do deploy do setes-api que traz a migration 066 (FKs do cliente
-- apontam para estas tabelas). Canônico: sql/01. Idempotente (IF NOT EXISTS).
-- MariaDB 10.4: CHECK é aplicado (o boot do setes-api confere — D-IB26).
-- =====================================================================

USE `setes_central`;

-- A1. CST do IBS/CBS (familia de tb_tax_pis/_cofins). Flags de grupo do CST: ind_gIBSCBS entrou
--     pela D-IB113 (script 73 — requires_ibscbs_group); os demais (ind_gRed, ind_gDif...) seguem sem
--     consumidor — entram por coluna quando houver.
CREATE TABLE IF NOT EXISTS `tb_tax_ibscbs` (
  `id`                 CHAR(3) NOT NULL COMMENT 'CST do IBS/CBS (ex.: 000)',
  `description`        VARCHAR(255) NOT NULL,
  `requires_ibscbs_group` CHAR(1) DEFAULT NULL COMMENT 'ind_gIBSCBS do CST: S = o DPS leva cIndOp + gIBSCBS · N = proibidos (o ERP recusa — D-IB113) · NULL = carga anterior ao script 73 (a peca recusa)',
  `source_version`     VARCHAR(30) NOT NULL COMMENT 'Proveniencia: ex. IT 2025.002 v1.70',
  `created_at`         DATETIME DEFAULT NULL,
  `updated_at`         DATETIME DEFAULT NULL,
  `deleted`            CHAR(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`),
  CONSTRAINT `ck_tax_ibscbs_id` CHECK (`id` REGEXP '^[0-9]{3}$'),
  CONSTRAINT `ck_tax_ibscbs_requires_group` CHECK (`requires_ibscbs_group` IS NULL OR `requires_ibscbs_group` COLLATE utf8mb4_bin IN ('S','N'))
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

