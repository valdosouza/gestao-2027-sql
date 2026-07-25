-- =====================================================================
-- Setes API — Fase 3: Entidade Única
-- Script 08 — Seed: interface 'customers' (primeiro papel novo da fase)
--
-- Executar após scripts 01, 02, 06 e 07.
-- INSERT IGNORE: idempotente, seguro para re-execução.
--
-- Interface de CLIENTE (não é Super): módulo customers no app
-- (/home/customers) e /api/customers na API (SEM superGuard — escopo por
-- institution vem do JWT; padrão simétrico ARQUITETURA_MODULOS_API.md).
--
-- group_default = 'Registers' → chave de menu.groups no app
-- (pt "Cadastros" / en "Registers" — trCatalog, decisão 26). NUNCA usar o
-- grupo 'Super' (exclusivo do superusuário — some do menu de não-super).
-- i18n_key = 'customers' → menu.interfaces.customers (pt "Clientes").
-- =====================================================================

USE `setes_central`;

INSERT IGNORE INTO `tb_interface`
  (`id`, `group_default`, `i18n_key`, `description`, `kind`, `position`, `created_at`, `updated_at`, `deleted`)
VALUES
  (9, 'Registers', 'customers', 'Customer', 'T', NULL, NOW(), NOW(), 'N');

-- Contrato da Setes (validação ponta a ponta da decisão 8: cadastrar a
-- Setes como cliente dela mesma em setes_setes reaproveitando a entity 1).
-- Para outros clientes o Super concede pela aba Interfaces do Institution.
INSERT IGNORE INTO `setes_setes`.`tb_institution_has_interface`
  (`tb_institution_id`, `tb_interface_id`, `active`, `created_at`, `updated_at`, `deleted`)
VALUES
  (1, 9, 'S', NOW(), NOW(), 'N');

-- Gate técnico do módulo /api/customers para institutions EXISTENTES
-- (insertDefaultFlags só cobre as criadas a partir da Fase 3). Idempotente:
-- o UNIQUE (tb_institution_id, module_key) barra duplicação; id = MAX+1
-- por linha (padrão sem AUTO_INCREMENT).
INSERT IGNORE INTO `tb_feature_flag`
  (`id`, `tb_institution_id`, `module_key`, `enabled`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(f2.id), 0) FROM `tb_feature_flag` f2) + i.rn,
       i.id, 'customers', TRUE, NOW(), NOW(), 'N'
FROM (
  SELECT t.id, ROW_NUMBER() OVER (ORDER BY t.id) AS rn
  FROM `tb_institution` t
  WHERE t.deleted = 'N'
    AND NOT EXISTS (SELECT 1 FROM `tb_feature_flag` f
                    WHERE f.tb_institution_id = t.id
                      AND f.module_key = 'customers')
) i;
