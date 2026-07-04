-- =====================================================================
-- Setes API — Fase 2: Gerenciamento Central
-- Script 05 — Sincronizador: tb_sync_api_key (rodar após os scripts 01 e 02)
-- Padroniza a antiga sync_api_keys: prefixo tb_, indexada por institution
-- (tb_institution_id int). schema_name deixa de ser duplicado aqui — o
-- sync.auth.middleware busca via JOIN em tb_institution (fonte única).
-- =====================================================================

USE `setes_central`;

CREATE TABLE IF NOT EXISTS `tb_sync_api_key` (
  `id`                 int(11) NOT NULL,
  `api_key`            varchar(255) NOT NULL,
  `tb_institution_id`  int(11) NOT NULL,
  `establishment_code` varchar(50) NOT NULL,
  `active`             char(1) NOT NULL DEFAULT 'S',
  `created_at`         datetime DEFAULT NULL,
  `updated_at`         datetime DEFAULT NULL,
  `deleted`            char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`),
  UNIQUE KEY `api_key` (`api_key`),
  KEY `fk_sak_to_institution` (`tb_institution_id`),
  CONSTRAINT `fk_sak_to_institution` FOREIGN KEY (`tb_institution_id`) REFERENCES `tb_institution` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Remoção da tabela antiga (decisão 18: sem produção, troca direta).
-- Se houver chaves em uso, migre antes:
--   INSERT INTO tb_sync_api_key (id, api_key, tb_institution_id, establishment_code, active, created_at, updated_at)
--   SELECT <id_app>, api_key, <novo_id_int>, establishment_code, IF(active,'S','N'), NOW(), NOW() FROM sync_api_keys;
DROP TABLE IF EXISTS `sync_api_keys`;
