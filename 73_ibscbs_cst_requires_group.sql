-- =====================================================================
-- 73 — Fase IBS/CBS, D-IB113 (Valdo 2026-11-01 — Infra-IA/prompts/prompt_fase_ibs_cbs.md §13.8, fim):
-- FATO "o CST leva o grupo IBS/CBS no documento" = coluna `ind_gIBSCBS` da aba CST do IT 2025.002 (1 = exige,
-- 0 = não é permitido). No leiaute da NT 009 (produção restrita desde 20/10/2026) o fisco o confere: com 1 o DPS
-- leva `cIndOp` (E0860) e `gIBSCBS` (E0960); com 0 os dois são PROIBIDOS (E0859/E0961). A nfse-api nunca consulta
-- o indicador — grupo declarado ⇒ `cIndOp` + `gIBSCBS`, por construção —, então o ERP RECUSA antes de congelar
-- toda classificação cujo CST não leva o grupo ("ainda não suportado na NFS-e"), no cadastro do serviço e no
-- faturamento, pelo MESMO veredito da peça @shared/ibscbs-classification.
-- Guardião: atributo da peça do CST (conceito único; fato gerador = a carga de uma versão do IT); sem tabela nova,
-- sem FK, sem regra de unicidade nova. Molde: `requires_regular_taxation` (ind_gTribRegular) da história.
-- Quem grava: SÓ a rotina do Super (setes-api/scripts/load-ibscbs-catalog.ts — confere 0/1 antes de gravar).
-- NULL = CST gravado por carga ANTERIOR a este script (indicador desconhecido): a peça RECUSA (falha fechada) até a
-- próxima carga — nenhum DEFAULT inventa o indicador.
-- Domínio fechado = CHECK BINÁRIO (PADROES_BANCO §11 regra 11): a minúscula 's' é recusada; o boot do setes-api
-- prova a recusa pelo NOME da constraint (`assertIbscbsCatalogSchema`).
-- ORDEM DE DEPLOY (precedente da D-IB33 — scripts → carga → deploy; o desconhecido nunca chega à produção): este
-- script em `setes_central` (o setes-api em produção ignora a coluna) → carga do catálogo rodada da BRANCH que traz a
-- D-IB113 (ensaio + ato — preenche o indicador) → deploy do setes-api que o lê (sem a coluna ou sem o CHECK o boot
-- NÃO sobe e diz este script; D-IB120: com indicador NULL num CST que ainda tem cClassTrib vivo também NÃO sobe e
-- manda rodar a carga). Executar após o 61.
-- Re-executável (ADD COLUMN IF NOT EXISTS / DROP CONSTRAINT IF EXISTS — só MariaDB; a ida para MySQL 8 revê).
-- =====================================================================
USE `setes_central`;

ALTER TABLE `tb_tax_ibscbs`
  ADD COLUMN IF NOT EXISTS `requires_ibscbs_group` CHAR(1) DEFAULT NULL
    COMMENT 'ind_gIBSCBS do CST: S = o DPS leva cIndOp + gIBSCBS · N = proibidos (o ERP recusa — D-IB113) · NULL = carga anterior ao script 73 (a peca recusa)'
    AFTER `description`;

ALTER TABLE `tb_tax_ibscbs`
  DROP CONSTRAINT IF EXISTS `ck_tax_ibscbs_requires_group`,
  ADD CONSTRAINT `ck_tax_ibscbs_requires_group`
    CHECK (`requires_ibscbs_group` IS NULL OR `requires_ibscbs_group` COLLATE utf8mb4_bin IN ('S','N'));
