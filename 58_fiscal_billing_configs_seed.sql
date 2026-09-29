-- =====================================================================
-- Seed 58: configurações de COMPORTAMENTO fiscal na interface `billing`
-- (Framework de Configurações — Onda 3 NFS-e, D-E24/§9.3 de
-- prompts/prompt_onda_nfe_sefaz.md). O legado guardava isto em
-- TB_NF_ELETRONICA/TB_GERAL; aqui é catálogo × valor por institution.
--   dps_description_format     — como o xDescServ do DPS é montado dos itens:
--                                'I' nome dos itens (qtd x nome) · 'O' texto da
--                                observação da nota · 'A' ambos
--   fiscal_accountant_email    — e-mail do contador para receber XML + DANFSe/DANFE
--   fiscal_email_copy_to_issuer— cópia do e-mail fiscal para o próprio emissor
-- A config `invoice_serie` é APOSENTADA (D-E2): a série virou coluna de
-- tb_establishment_issuer (migration 058 fez o backfill da linha 55) — o
-- catálogo marca deleted='S' para sumir da engrenagem; o valor gravado nas
-- institutions fica como história.
-- Idempotente; ancorado por i18n_key (nunca id fixo).
-- =====================================================================

USE `setes_central`;

INSERT INTO `tb_interface_has_config`
  (`tb_interface_id`, `name`, `description`, `kind`, `options`, `default_content`, `scope`, `created_at`, `updated_at`, `deleted`)
SELECT i.id, 'dps_description_format', 'NFS-e: como a descrição do serviço (xDescServ) é montada a partir da nota',
       'Options', 'I=Itens (qtd x nome);O=Observação da nota;A=Itens e observação', 'I', 'I', NOW(), NOW(), 'N'
  FROM `tb_interface` i
 WHERE i.i18n_key = 'billing'
   AND NOT EXISTS (SELECT 1 FROM `tb_interface_has_config` c WHERE c.tb_interface_id = i.id AND c.name = 'dps_description_format');

INSERT INTO `tb_interface_has_config`
  (`tb_interface_id`, `name`, `description`, `kind`, `options`, `default_content`, `scope`, `created_at`, `updated_at`, `deleted`)
SELECT i.id, 'fiscal_accountant_email', 'E-mail do contador para receber XML e DANFSe/DANFE das notas autorizadas',
       'String', NULL, '', 'I', NOW(), NOW(), 'N'
  FROM `tb_interface` i
 WHERE i.i18n_key = 'billing'
   AND NOT EXISTS (SELECT 1 FROM `tb_interface_has_config` c WHERE c.tb_interface_id = i.id AND c.name = 'fiscal_accountant_email');

INSERT INTO `tb_interface_has_config`
  (`tb_interface_id`, `name`, `description`, `kind`, `options`, `default_content`, `scope`, `created_at`, `updated_at`, `deleted`)
SELECT i.id, 'fiscal_email_copy_to_issuer', 'Receber cópia do e-mail fiscal no e-mail do próprio emissor',
       'Boolean', NULL, 'N', 'I', NOW(), NOW(), 'N'
  FROM `tb_interface` i
 WHERE i.i18n_key = 'billing'
   AND NOT EXISTS (SELECT 1 FROM `tb_interface_has_config` c WHERE c.tb_interface_id = i.id AND c.name = 'fiscal_email_copy_to_issuer');

-- D-E2: a série saiu da configuração (vive na habilitação do emissor por modelo)
UPDATE `tb_interface_has_config` c
  JOIN `tb_interface` i ON i.id = c.tb_interface_id
   SET c.deleted = 'S', c.updated_at = NOW()
 WHERE i.i18n_key = 'billing' AND c.name = 'invoice_serie' AND c.deleted = 'N';
