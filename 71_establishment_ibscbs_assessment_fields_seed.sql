-- =====================================================================
-- Seed 71: catálogo de campos configuráveis (tb_interface_has_field) da
-- interface 'establishment' (Meu Estabelecimento) — SÓ a seção da opção de
-- apuração do IBS/CBS do Simples (fase IBS/CBS, D-IB99/D-IB100 —
-- prompt_fase_ibs_cbs.md §14; motor de campos na própria frente — D-CF4 de
-- prompt_frente_campos_todas_telas.md). O resto da tela (cadeia de entidade,
-- regime em tb_entity_tax) entra na onda da D-CF4 (bloco C).
-- Tabela: tb_establishment_ibscbs_assessment (migration 076 do setes-api).
--   - id da interface DINÂMICO (por i18n_key — lição do seed 40);
--   - FORA: tb_institution_id (escopo do JWT), tb_user_id (autoria);
--   - baseline técnico 'S' nos dois: o DTO do sub-recurso
--     /api/establishment/ibscbs-assessments exige data e opção (o cliente só
--     ajusta o rótulo). Chave do payload = camelCase da coluna (validFrom,
--     assessment) — sem mapa de caminho.
-- Re-executável (INSERT IGNORE na PK interface+campo). Executar após o 60.
-- =====================================================================
USE `setes_central`;

INSERT IGNORE INTO `tb_interface_has_field`
  (`tb_interface_id`, `field_name`, `table_name`, `kind`, `required`, `created_at`, `updated_at`, `deleted`)
SELECT i.`id`, f.`field_name`, f.`table_name`, f.`kind`, f.`required`, NOW(), NOW(), 'N'
  FROM `tb_interface` i
  JOIN (
        SELECT 'valid_from' AS field_name, 'tb_establishment_ibscbs_assessment' AS table_name, 'Date' AS kind, 'S' AS required
        UNION ALL SELECT 'assessment', 'tb_establishment_ibscbs_assessment', 'String', 'S'
       ) f
 WHERE i.`i18n_key` = 'establishment' AND i.`deleted` = 'N';
