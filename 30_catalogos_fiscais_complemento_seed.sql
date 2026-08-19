-- =====================================================================
-- Fase Faturamento Fiscal e Financeiro — Seed 30: complemento dos
-- catálogos fiscais (decisão 37 — Q-G4 respondida pelo Valdo 2026-08-19:
-- "sim", incluir já os códigos oficiais que o legado não tinha).
--
-- Complementa o seed 28 (listas verificadas no legado):
--   • CST ICMS da monofasia de combustíveis (NT 2023.001): 02/15/53/61
--   • CST PIS/COFINS de crédito/entrada (tabelas 4.3.3/4.3.4 do SPED):
--     05, 49, 50–56, 60–67, 70–75, 98
-- CSOSN já estava COMPLETO no seed 28 (tabela oficial do Ajuste SINIEF
-- 07/10 — 10 códigos). CST × CSOSN são catálogos SEPARADOS por desenho
-- (espelho do legado TB_TRIB_ICMS_NR × TB_TRIB_ICMS_SN): a peça ICMS da
-- regra carrega os DOIS FKs e o despacho é pelo CRT do EMITENTE
-- (tributacao.md §P2.3: CRT 3/2 → CST; CRT 1 → CSOSN).
--
-- Executar após os scripts 01 e 28. ON DUPLICATE: idempotente.
-- =====================================================================

USE `setes_central`;

-- CST ICMS — monofasia de combustíveis (NT 2023.001)
INSERT INTO `tb_tax_icms_nr` (`id`, `description`, `created_at`, `updated_at`, `deleted`) VALUES
  ('02', 'Tributação monofásica própria sobre combustíveis', NOW(), NOW(), 'N'),
  ('15', 'Tributação monofásica própria e com responsabilidade pela retenção sobre combustíveis', NOW(), NOW(), 'N'),
  ('53', 'Tributação monofásica sobre combustíveis com recolhimento diferido', NOW(), NOW(), 'N'),
  ('61', 'Tributação monofásica sobre combustíveis cobrada anteriormente', NOW(), NOW(), 'N')
ON DUPLICATE KEY UPDATE `description` = VALUES(`description`), `updated_at` = NOW(), `deleted` = 'N';

-- CST PIS — crédito/entrada (tabela 4.3.3 do SPED)
INSERT INTO `tb_tax_pis` (`id`, `description`, `created_at`, `updated_at`, `deleted`) VALUES
  ('05', 'Operação Tributável por Substituição Tributária', NOW(), NOW(), 'N'),
  ('49', 'Outras Operações de Saída', NOW(), NOW(), 'N'),
  ('50', 'Operação com Direito a Crédito - Vinculada Exclusivamente a Receita Tributada no Mercado Interno', NOW(), NOW(), 'N'),
  ('51', 'Operação com Direito a Crédito - Vinculada Exclusivamente a Receita Não-Tributada no Mercado Interno', NOW(), NOW(), 'N'),
  ('52', 'Operação com Direito a Crédito - Vinculada Exclusivamente a Receita de Exportação', NOW(), NOW(), 'N'),
  ('53', 'Operação com Direito a Crédito - Vinculada a Receitas Tributadas e Não-Tributadas no Mercado Interno', NOW(), NOW(), 'N'),
  ('54', 'Operação com Direito a Crédito - Vinculada a Receitas Tributadas no Mercado Interno e de Exportação', NOW(), NOW(), 'N'),
  ('55', 'Operação com Direito a Crédito - Vinculada a Receitas Não-Tributadas no Mercado Interno e de Exportação', NOW(), NOW(), 'N'),
  ('56', 'Operação com Direito a Crédito - Vinculada a Receitas Tributadas e Não-Tributadas no Mercado Interno e de Exportação', NOW(), NOW(), 'N'),
  ('60', 'Crédito Presumido - Operação de Aquisição Vinculada Exclusivamente a Receita Tributada no Mercado Interno', NOW(), NOW(), 'N'),
  ('61', 'Crédito Presumido - Operação de Aquisição Vinculada Exclusivamente a Receita Não-Tributada no Mercado Interno', NOW(), NOW(), 'N'),
  ('62', 'Crédito Presumido - Operação de Aquisição Vinculada Exclusivamente a Receita de Exportação', NOW(), NOW(), 'N'),
  ('63', 'Crédito Presumido - Operação de Aquisição Vinculada a Receitas Tributadas e Não-Tributadas no Mercado Interno', NOW(), NOW(), 'N'),
  ('64', 'Crédito Presumido - Operação de Aquisição Vinculada a Receitas Tributadas no Mercado Interno e de Exportação', NOW(), NOW(), 'N'),
  ('65', 'Crédito Presumido - Operação de Aquisição Vinculada a Receitas Não-Tributadas no Mercado Interno e de Exportação', NOW(), NOW(), 'N'),
  ('66', 'Crédito Presumido - Operação de Aquisição Vinculada a Receitas Tributadas e Não-Tributadas no Mercado Interno e de Exportação', NOW(), NOW(), 'N'),
  ('67', 'Crédito Presumido - Outras Operações', NOW(), NOW(), 'N'),
  ('70', 'Operação de Aquisição sem Direito a Crédito', NOW(), NOW(), 'N'),
  ('71', 'Operação de Aquisição com Isenção', NOW(), NOW(), 'N'),
  ('72', 'Operação de Aquisição com Suspensão', NOW(), NOW(), 'N'),
  ('73', 'Operação de Aquisição a Alíquota Zero', NOW(), NOW(), 'N'),
  ('74', 'Operação de Aquisição sem Incidência da Contribuição', NOW(), NOW(), 'N'),
  ('75', 'Operação de Aquisição por Substituição Tributária', NOW(), NOW(), 'N'),
  ('98', 'Outras Operações de Entrada', NOW(), NOW(), 'N')
ON DUPLICATE KEY UPDATE `description` = VALUES(`description`), `updated_at` = NOW(), `deleted` = 'N';

-- CST COFINS — mesma lista do PIS (decisão 2: PIS = COFINS)
INSERT INTO `tb_tax_cofins` (`id`, `description`, `created_at`, `updated_at`, `deleted`) VALUES
  ('05', 'Operação Tributável por Substituição Tributária', NOW(), NOW(), 'N'),
  ('49', 'Outras Operações de Saída', NOW(), NOW(), 'N'),
  ('50', 'Operação com Direito a Crédito - Vinculada Exclusivamente a Receita Tributada no Mercado Interno', NOW(), NOW(), 'N'),
  ('51', 'Operação com Direito a Crédito - Vinculada Exclusivamente a Receita Não-Tributada no Mercado Interno', NOW(), NOW(), 'N'),
  ('52', 'Operação com Direito a Crédito - Vinculada Exclusivamente a Receita de Exportação', NOW(), NOW(), 'N'),
  ('53', 'Operação com Direito a Crédito - Vinculada a Receitas Tributadas e Não-Tributadas no Mercado Interno', NOW(), NOW(), 'N'),
  ('54', 'Operação com Direito a Crédito - Vinculada a Receitas Tributadas no Mercado Interno e de Exportação', NOW(), NOW(), 'N'),
  ('55', 'Operação com Direito a Crédito - Vinculada a Receitas Não-Tributadas no Mercado Interno e de Exportação', NOW(), NOW(), 'N'),
  ('56', 'Operação com Direito a Crédito - Vinculada a Receitas Tributadas e Não-Tributadas no Mercado Interno e de Exportação', NOW(), NOW(), 'N'),
  ('60', 'Crédito Presumido - Operação de Aquisição Vinculada Exclusivamente a Receita Tributada no Mercado Interno', NOW(), NOW(), 'N'),
  ('61', 'Crédito Presumido - Operação de Aquisição Vinculada Exclusivamente a Receita Não-Tributada no Mercado Interno', NOW(), NOW(), 'N'),
  ('62', 'Crédito Presumido - Operação de Aquisição Vinculada Exclusivamente a Receita de Exportação', NOW(), NOW(), 'N'),
  ('63', 'Crédito Presumido - Operação de Aquisição Vinculada a Receitas Tributadas e Não-Tributadas no Mercado Interno', NOW(), NOW(), 'N'),
  ('64', 'Crédito Presumido - Operação de Aquisição Vinculada a Receitas Tributadas no Mercado Interno e de Exportação', NOW(), NOW(), 'N'),
  ('65', 'Crédito Presumido - Operação de Aquisição Vinculada a Receitas Não-Tributadas no Mercado Interno e de Exportação', NOW(), NOW(), 'N'),
  ('66', 'Crédito Presumido - Operação de Aquisição Vinculada a Receitas Tributadas e Não-Tributadas no Mercado Interno e de Exportação', NOW(), NOW(), 'N'),
  ('67', 'Crédito Presumido - Outras Operações', NOW(), NOW(), 'N'),
  ('70', 'Operação de Aquisição sem Direito a Crédito', NOW(), NOW(), 'N'),
  ('71', 'Operação de Aquisição com Isenção', NOW(), NOW(), 'N'),
  ('72', 'Operação de Aquisição com Suspensão', NOW(), NOW(), 'N'),
  ('73', 'Operação de Aquisição a Alíquota Zero', NOW(), NOW(), 'N'),
  ('74', 'Operação de Aquisição sem Incidência da Contribuição', NOW(), NOW(), 'N'),
  ('75', 'Operação de Aquisição por Substituição Tributária', NOW(), NOW(), 'N'),
  ('98', 'Outras Operações de Entrada', NOW(), NOW(), 'N')
ON DUPLICATE KEY UPDATE `description` = VALUES(`description`), `updated_at` = NOW(), `deleted` = 'N';
