-- =====================================================================
-- 63 — Fase IBS/CBS, D-IB36 (Rodada 4, Valdo 2026-10-10 — Infra-IA/prompts/prompt_fase_ibs_cbs.md §11.10):
-- FATO "a linha de vigência sumiu da fonte oficial desde a versão X" na história do cClassTrib.
-- A linha nunca é apagada (nota antiga aponta código antigo); a rotina do Super grava a versão do IT
-- em que ela deixou de vir e LIMPA o fato se ela voltar; a peça @shared/ibscbs-classification ignora a
-- linha superada em toda resolução. Caso real: o IT corrige a dIniVig de um código — a linha antiga
-- ficava aberta e virava "a mais nova vigente" (gate socrático da Rodada 3, Q-IB36).
-- Guardião: atributo da peça de HISTÓRIA (conceito único, fato gerador = a carga de uma versão do IT
-- sem a linha); sem FK, sem default, sem regra de unicidade nova.
-- ORDEM DE DEPLOY: este script ANTES do setes-api que o lê (as consultas da peça referenciam a coluna).
-- Re-executável (ADD COLUMN IF NOT EXISTS — MariaDB 10.4). Executar após o 61.
-- =====================================================================
USE `setes_central`;

ALTER TABLE `tb_tax_ibscbs_classification_validity`
  ADD COLUMN IF NOT EXISTS `absent_since_version` VARCHAR(30) DEFAULT NULL
    COMMENT 'versao da fonte (IT) em que a linha deixou de vir — NULL = presente na fonte (D-IB36)'
    AFTER `source_updated_at`;
