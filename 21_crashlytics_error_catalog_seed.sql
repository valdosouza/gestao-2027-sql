-- =====================================================================
-- Seed: 21_crashlytics_error_catalog_seed.sql — Framework de Mensagens
-- (Valdo, 2026-07-19 — prompt_framework_mensagens_validacao.md R2/R8)
--
-- Cria em bases CENTRAIS EXISTENTES a tb_crashlytics reformada e a
-- tb_error_catalog (bases novas: sql/01). As LINHAS do catálogo entram
-- por `npm run errors:gen` (derivadas de error-codes.ts — nunca à mão).
-- Idempotente.
-- =====================================================================

USE `setes_central`;

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

CREATE TABLE IF NOT EXISTS `tb_error_catalog` (
  `code`        varchar(40) NOT NULL,
  `description` varchar(200) NOT NULL,
  `created_at`  datetime DEFAULT NULL,
  `updated_at`  datetime DEFAULT NULL,
  `deleted`     char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
