-- =====================================================================
-- Fase Faturamento Fiscal e Financeiro — Seed: catálogos fiscais centrais
-- (CSTs, modalidades de base e desoneração — combos do cadastro tax-rules)
--
-- Origem do achado: gate adversarial da Onda 1 (2026-08-16) — os 8
-- catálogos existiam VAZIOS em dev: nenhuma regra podia ser criada (todo
-- CST caía no 422 da decisão 33) e /api/tax-rules/catalogs vinha vazio.
--
-- Conteúdo VERIFICADO no legado (paridade — critério de sucesso 1):
--   Funcao/un_Conversao.pas — CST ICMS :318, modBC :342, modBC-ST :362,
--   CST IPI :376, CST PIS :390, CST COFINS :404 (listas do emissor).
--   CSOSN: lista oficial do Simples (Ajuste SINIEF 07/10 — grupos
--   101/102/500/900 confirmados em componentes/tributacao.pas).
--   Desoneração: lista oficial motDesICMS do layout NF-e (o legado não a
--   constrange — tributacao.pas :5692 fixa 0 = sem desoneração).
--
-- Códigos oficiais NOVOS que o legado não tinha (monofasia ICMS 02/15/53/61,
-- PIS/COFINS de crédito 05/49/5x/6x/7x/98) ficam FORA — entrar com eles é
-- questão da rodada (Q-G4 do relatório dos gates).
--
-- Executar após o script 01. ON DUPLICATE: idempotente (atualiza descrição).
-- =====================================================================

USE `setes_central`;

-- CST ICMS — regime normal (tb_tax_icms_nr)
INSERT INTO `tb_tax_icms_nr` (`id`, `description`, `created_at`, `updated_at`, `deleted`) VALUES
  ('00', 'Tributada integralmente', NOW(), NOW(), 'N'),
  ('10', 'Tributada e com cobrança do ICMS por substituição tributária', NOW(), NOW(), 'N'),
  ('20', 'Com redução de base de cálculo', NOW(), NOW(), 'N'),
  ('30', 'Isenta ou não tributada e com cobrança do ICMS por substituição tributária', NOW(), NOW(), 'N'),
  ('40', 'Isenta', NOW(), NOW(), 'N'),
  ('41', 'Não tributada', NOW(), NOW(), 'N'),
  ('50', 'Suspensão', NOW(), NOW(), 'N'),
  ('51', 'Diferimento', NOW(), NOW(), 'N'),
  ('60', 'ICMS cobrado anteriormente por substituição tributária', NOW(), NOW(), 'N'),
  ('70', 'Com redução de base de cálculo e cobrança do ICMS por substituição tributária', NOW(), NOW(), 'N'),
  ('90', 'Outras', NOW(), NOW(), 'N')
ON DUPLICATE KEY UPDATE `description` = VALUES(`description`), `updated_at` = NOW(), `deleted` = 'N';

-- CSOSN — Simples Nacional (tb_tax_icms_sn)
INSERT INTO `tb_tax_icms_sn` (`id`, `description`, `created_at`, `updated_at`, `deleted`) VALUES
  ('101', 'Tributada pelo Simples Nacional com permissão de crédito', NOW(), NOW(), 'N'),
  ('102', 'Tributada pelo Simples Nacional sem permissão de crédito', NOW(), NOW(), 'N'),
  ('103', 'Isenção do ICMS no Simples Nacional para faixa de receita bruta', NOW(), NOW(), 'N'),
  ('201', 'Tributada pelo Simples Nacional com permissão de crédito e com cobrança do ICMS por ST', NOW(), NOW(), 'N'),
  ('202', 'Tributada pelo Simples Nacional sem permissão de crédito e com cobrança do ICMS por ST', NOW(), NOW(), 'N'),
  ('203', 'Isenção do ICMS no Simples Nacional para faixa de receita bruta e com cobrança do ICMS por ST', NOW(), NOW(), 'N'),
  ('300', 'Imune', NOW(), NOW(), 'N'),
  ('400', 'Não tributada pelo Simples Nacional', NOW(), NOW(), 'N'),
  ('500', 'ICMS cobrado anteriormente por substituição tributária ou por antecipação', NOW(), NOW(), 'N'),
  ('900', 'Outros', NOW(), NOW(), 'N')
ON DUPLICATE KEY UPDATE `description` = VALUES(`description`), `updated_at` = NOW(), `deleted` = 'N';

-- Modalidade de determinação da BC do ICMS (tb_deter_base_tax_icms)
INSERT INTO `tb_deter_base_tax_icms` (`id`, `description`, `created_at`, `updated_at`, `deleted`) VALUES
  ('0', 'Margem Valor Agregado (%)', NOW(), NOW(), 'N'),
  ('1', 'Pauta (Valor)', NOW(), NOW(), 'N'),
  ('2', 'Preço Tabelado Máximo (valor)', NOW(), NOW(), 'N'),
  ('3', 'Valor da operação', NOW(), NOW(), 'N')
ON DUPLICATE KEY UPDATE `description` = VALUES(`description`), `updated_at` = NOW(), `deleted` = 'N';

-- Modalidade de determinação da BC do ICMS-ST (tb_deter_base_tax_icms_st)
INSERT INTO `tb_deter_base_tax_icms_st` (`id`, `description`, `created_at`, `updated_at`, `deleted`) VALUES
  ('0', 'Preço tabelado ou máximo sugerido', NOW(), NOW(), 'N'),
  ('1', 'Lista Negativa (valor)', NOW(), NOW(), 'N'),
  ('2', 'Lista Positiva (valor)', NOW(), NOW(), 'N'),
  ('3', 'Lista Neutra (valor)', NOW(), NOW(), 'N'),
  ('4', 'Margem Valor Agregado (%)', NOW(), NOW(), 'N'),
  ('5', 'Pauta (valor)', NOW(), NOW(), 'N')
ON DUPLICATE KEY UPDATE `description` = VALUES(`description`), `updated_at` = NOW(), `deleted` = 'N';

-- Motivo da desoneração do ICMS (tb_discharge_icms — layout NF-e motDesICMS)
INSERT INTO `tb_discharge_icms` (`id`, `description`, `created_at`, `updated_at`, `deleted`) VALUES
  (1,  'Táxi', NOW(), NOW(), 'N'),
  (3,  'Produtor Agropecuário', NOW(), NOW(), 'N'),
  (4,  'Frotista/Locadora', NOW(), NOW(), 'N'),
  (5,  'Diplomático/Consular', NOW(), NOW(), 'N'),
  (6,  'Utilitários e Motocicletas da Amazônia Ocidental e Áreas de Livre Comércio', NOW(), NOW(), 'N'),
  (7,  'SUFRAMA', NOW(), NOW(), 'N'),
  (8,  'Venda a Órgão Público', NOW(), NOW(), 'N'),
  (9,  'Outros', NOW(), NOW(), 'N'),
  (10, 'Deficiente Condutor', NOW(), NOW(), 'N'),
  (11, 'Deficiente Não Condutor', NOW(), NOW(), 'N'),
  (12, 'Órgão de fomento e desenvolvimento agropecuário', NOW(), NOW(), 'N'),
  (16, 'Olimpíadas Rio 2016', NOW(), NOW(), 'N'),
  (90, 'Solicitado pelo Fisco', NOW(), NOW(), 'N')
ON DUPLICATE KEY UPDATE `description` = VALUES(`description`), `updated_at` = NOW(), `deleted` = 'N';

-- CST IPI (tb_tax_ipi)
INSERT INTO `tb_tax_ipi` (`id`, `description`, `created_at`, `updated_at`, `deleted`) VALUES
  ('00', 'Entrada com recuperação de crédito', NOW(), NOW(), 'N'),
  ('01', 'Entrada tributada com alíquota zero', NOW(), NOW(), 'N'),
  ('02', 'Entrada isenta', NOW(), NOW(), 'N'),
  ('03', 'Entrada não-tributada', NOW(), NOW(), 'N'),
  ('04', 'Entrada imune', NOW(), NOW(), 'N'),
  ('05', 'Entrada com suspensão', NOW(), NOW(), 'N'),
  ('49', 'Outras entradas', NOW(), NOW(), 'N'),
  ('50', 'Saída tributada', NOW(), NOW(), 'N'),
  ('51', 'Saída tributada com alíquota zero', NOW(), NOW(), 'N'),
  ('52', 'Saída isenta', NOW(), NOW(), 'N'),
  ('53', 'Saída não-tributada', NOW(), NOW(), 'N'),
  ('54', 'Saída imune', NOW(), NOW(), 'N'),
  ('55', 'Saída com suspensão', NOW(), NOW(), 'N'),
  ('99', 'Outras saídas', NOW(), NOW(), 'N')
ON DUPLICATE KEY UPDATE `description` = VALUES(`description`), `updated_at` = NOW(), `deleted` = 'N';

-- CST PIS (tb_tax_pis) — lista do emissor (legado); códigos de crédito = Q-G4
INSERT INTO `tb_tax_pis` (`id`, `description`, `created_at`, `updated_at`, `deleted`) VALUES
  ('01', 'Operação Tributável com Alíquota Básica', NOW(), NOW(), 'N'),
  ('02', 'Operação Tributável com Alíquota Diferenciada', NOW(), NOW(), 'N'),
  ('03', 'Operação Tributável com Alíquota por Unidade de Medida de Produto', NOW(), NOW(), 'N'),
  ('04', 'Operação Tributável Monofásica - Revenda a Alíquota Zero', NOW(), NOW(), 'N'),
  ('06', 'Operação Tributável a Alíquota Zero', NOW(), NOW(), 'N'),
  ('07', 'Operação Isenta da Contribuição', NOW(), NOW(), 'N'),
  ('08', 'Operação sem Incidência da Contribuição', NOW(), NOW(), 'N'),
  ('09', 'Operação com Suspensão da Contribuição', NOW(), NOW(), 'N'),
  ('99', 'Outras Operações', NOW(), NOW(), 'N')
ON DUPLICATE KEY UPDATE `description` = VALUES(`description`), `updated_at` = NOW(), `deleted` = 'N';

-- CST COFINS (tb_tax_cofins) — mesma lista do PIS (decisão 2: PIS = COFINS)
INSERT INTO `tb_tax_cofins` (`id`, `description`, `created_at`, `updated_at`, `deleted`) VALUES
  ('01', 'Operação Tributável com Alíquota Básica', NOW(), NOW(), 'N'),
  ('02', 'Operação Tributável com Alíquota Diferenciada', NOW(), NOW(), 'N'),
  ('03', 'Operação Tributável com Alíquota por Unidade de Medida de Produto', NOW(), NOW(), 'N'),
  ('04', 'Operação Tributável Monofásica - Revenda a Alíquota Zero', NOW(), NOW(), 'N'),
  ('06', 'Operação Tributável a Alíquota Zero', NOW(), NOW(), 'N'),
  ('07', 'Operação Isenta da Contribuição', NOW(), NOW(), 'N'),
  ('08', 'Operação sem Incidência da Contribuição', NOW(), NOW(), 'N'),
  ('09', 'Operação com Suspensão da Contribuição', NOW(), NOW(), 'N'),
  ('99', 'Outras Operações', NOW(), NOW(), 'N')
ON DUPLICATE KEY UPDATE `description` = VALUES(`description`), `updated_at` = NOW(), `deleted` = 'N';
