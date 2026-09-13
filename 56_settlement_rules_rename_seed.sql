-- =====================================================================
-- Seed 56: "Contrato Financeiro" vira REGRA DE RECEBIMENTO no CATÁLOGO
-- (Valdo 2026-09-13 — fase Primeiro Cliente, rodada da confusão "contrato").
--
-- Contexto: a D15 do prompt_contrato_financeiro_baixa_automatica.md manteve o
-- nome `tb_financial_contract` com UMA condição — "rótulo da tela deve
-- distinguir do contrato comercial do Software House (tb_contract)" — e a
-- condição não foi cumprida: as telas saíram "Contratos" e "Contratos
-- Financeiros". O Valdo reabriu a D15: o objeto passa a se chamar pelo que é,
-- na família que a casa já usa (tb_tax_rule → "Regras de Tributação").
--
-- Acompanha a migration 052 do setes-api (RENAME TABLE tb_financial_contract
-- → tb_settlement_rule). Aqui só o DADO do catálogo central muda; o objeto,
-- a PK e o efeito são os mesmos.
--
-- ⚠️ ORDEM DE IMPLANTAÇÃO: aplicar este seed ANTES de publicar o setes-app
-- novo — o menu casa pela i18n_key, então entre o seed e o deploy do app o
-- item aparece sem tradução (mesma classe da Q6 do módulo de menus).
--
-- Idempotente: só age se a chave antiga ainda existir. Os seeds 46 e 47 já
-- nascem com o nome novo (bases criadas do zero não precisam deste).
-- Executar após o script 55.
-- =====================================================================

USE `setes_central`;

-- 1. A interface: chave (= módulo = URL = pasta) e descrição
UPDATE `tb_interface`
   SET `i18n_key`    = 'settlement-rules',
       `description` = 'Settlement Rules',
       `updated_at`  = NOW()
 WHERE `i18n_key` = 'financial-contracts' AND `deleted` = 'N';

-- 2. Catálogo de campos configuráveis: a tabela de origem mudou de nome
UPDATE `tb_interface_has_field`
   SET `table_name` = 'tb_settlement_rule', `updated_at` = NOW()
 WHERE `table_name` = 'tb_financial_contract' AND `deleted` = 'N';

-- 3. Gate técnico do módulo (feature flag) — a chave é a URL
UPDATE `tb_feature_flag`
   SET `module_key` = 'settlement-rules', `updated_at` = NOW()
 WHERE `module_key` = 'financial-contracts' AND `deleted` = 'N';
