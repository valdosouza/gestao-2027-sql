-- =============================================================================
-- 77 — setes_central: o NOME de cada item do catálogo de telas e verbos é ÚNICO NO BANCO
--      (tb_interface.i18n_key entre as VIVAS; tb_privilege.description em TODAS as linhas)
-- Escopo: setes
-- Origem: Vault/prompts/prompt_privilegios_interfaces.md — D-PV43 (Q-PV51 = a: `i18n_key` única entre as vivas, coluna gerada STORED +
--         UNIQUE), D-PV45 (o conserto de duplicata da tela Interfaces SAI do código com este script), D-PV63 (UNIQUE nos dois nomes como
--         tarefa própria, script novo no `sql/`, conferindo duplicata viva E excluída antes) e A-PV28 (formas fechadas com o guardião).
--         Parecer do guardião `setes-conceito` de 2026-11-20 (Vault/projetos/setes-api/SUBJECT/PRIVILEGIOS/parecer-guardiao-priv-e7-p1.md),
--         revisar-ddl e prova em setes_central DESCARTÁVEL (setes-api `scripts/prove-catalog-unique-names.ts`). Passo setes-api:PRIV.E7.P1.
--         PADROES_BANCO §3.1 (soft delete; revive = a MESMA linha) e §9 regra 10 (upsert só onde a PK é o único UNIQUE).
--
-- O CONCEITO: o nome técnico de um item do catálogo central identifica UM id. A colisão passa a ser barrada pelo BANCO (a conferência do
-- service fica como a mensagem amigável — 409 antes do erro 1062; a corrida e o seed ficam cobertos por construção).
--   tb_interface  coluna gerada `i18n_key_live` = CASE WHEN deleted='N' THEN i18n_key END (STORED, colação EXPLÍCITA utf8mb4_general_ci —
--                 a da `i18n_key`) + UNIQUE `uq_interface_i18n_key_live`. Só as VIVAS: a identidade da interface é a chave (rota, seeds e
--                 views a resolvem pela chave); o NULL das excluídas não colide — "estacionar" com deleted='S' tira a linha do UNIQUE.
--   tb_privilege  UNIQUE `uq_privilege_description` em TODAS as linhas, excluídas inclusive: os seeds citam o verbo por id FIXO e o app e a
--                 view o leem pelo NOME exato (A-PV26) — nome e id são 1:1 para sempre. A ASSIMETRIA entre as duas é intencional.
-- Colação general_ci nos dois (aceito pelo guardião): a colisão ignora caixa, acento e espaço no FIM — 'Orders' colide com 'orders ',
-- 'FATURAR' com 'faturar', 'APROVAÇÃO' com 'APROVACAO'. Fecha a maior parte da comparação frouxa que a A-PV26 e as views recusam; o espaço
-- no INÍCIO conta (' ARQUIVAR' não colide) — limite conhecido (a chave de interface nem o aceita: o DTO exige a forma da rota). Não usar
-- utf8mb4_bin (deixaria 'faturar' ao lado de 'FATURAR').
-- A tela NUNCA revive linha excluída (A-PV28): reviver reativa pelas views os pares, contratos e concessões presos ao id. A volta de um
-- verbo ou interface excluído é ato de seed/entrega que revive a MESMA linha (§3.1) mostrando antes quem volta a ter o quê (D-PV64).
-- Consequências para quem escreve nas duas tabelas: proibido `ON DUPLICATE KEY UPDATE` (§9 regra 10 — a colisão no nome viraria UPDATE
-- calado da linha que colidiu) e `REPLACE INTO` (apagaria FISICAMENTE a linha que colidiu — §3.1); cerca na suíte do setes-api.
-- `INSERT IGNORE` passa a calar também a colisão no NOME — seed novo usa `INSERT … SELECT … WHERE NOT EXISTS` e confere a linha esperada
-- depois; o NOT EXISTS do seed de INTERFACE olha TODAS as linhas da chave, excluídas inclusive (o UNIQUE só barra entre as vivas: um
-- NOT EXISTS só das vivas criaria um id NOVO para a chave de uma excluída — contra a A-PV28, a volta revive a MESMA linha).
--
-- Re-executável SEM DROP+ADD e sem confiar no `IF NOT EXISTS` (que decide pelo NOME e aceitaria em silêncio um homônimo de outra forma):
-- o script lê o information_schema e, para a coluna e para cada índice, AUSENTE → cria; IDÊNTICO → nada; DIFERENTE → FALHA, sem consertar.
-- Antes do primeiro ALTER, a PRÉ-CONFERÊNCIA para o script se houver chave VIVA repetida (tb_interface) ou verbo repetido em QUALQUER
-- linha (tb_privilege), comparando na colação das colunas (a mesma do UNIQUE); chave repetida entre uma viva e uma excluída é só RELATADA.
-- Nada se apaga nem se atualiza (nenhum UPDATE/DELETE). O ADD da coluna STORED reconstrói a tabela (dezenas de linhas): roda À MÃO em
-- setes_central ANTES do setes-api que conta com ela (o boot recusa subir sem os dois UNIQUE — `assertCatalogUniqueNames`), com
-- `SET NAMES utf8mb4` e o usuário dono de sempre. Qualquer desvio FALHA o script com "Table '...SQL77_FALHOU_...' doesn't exist"
-- (molde dos scripts 64/72/75/76). Espelho no sql/01.
-- =============================================================================

SET NAMES utf8mb4;
-- Espera curta = DUAS variáveis (PADROES §11 regra 7): o ALTER pede trava de METADADOS nas tabelas que o veredito de acesso lê em TODA
-- rota (vw_interface_catalog, vw_user_access). Uma transação ociosa segurando a tabela não pode enfileirar o produto atrás do ALTER — sem
-- trava em 10 s o script falha. Rode de novo.
SET SESSION lock_wait_timeout = 10;
SET SESSION innodb_lock_wait_timeout = 10;

USE `setes_central`;

-- (1) RELATÓRIO (para o operador ler): nomes repetidos, comparados como o UNIQUE compara (colação da coluna)
SELECT 'tb_interface' AS `tabela`, `i18n_key` AS `nome`, COUNT(*) AS `linhas`, SUM(`deleted` = 'N') AS `vivas`,
       GROUP_CONCAT(`id`, ':', `deleted` ORDER BY `id`) AS `ids`
  FROM `tb_interface`
 WHERE `i18n_key` IS NOT NULL
 GROUP BY `i18n_key`
HAVING COUNT(*) > 1
UNION ALL
SELECT 'tb_privilege', `description`, COUNT(*), SUM(`deleted` = 'N'), GROUP_CONCAT(`id`, ':', `deleted` ORDER BY `id`)
  FROM `tb_privilege`
 WHERE `description` IS NOT NULL
 GROUP BY `description`
HAVING COUNT(*) > 1;

-- (2) PRÉ-CONFERÊNCIA — antes de qualquer ALTER
-- (2a) as colunas NOMEADAS estão em utf8mb4_general_ci (gate adversarial do PRIV.E7.P1): com `description` em utf8mb4_bin o UNIQUE
-- deixaria 'faturar' ao lado de 'FATURAR'; com `i18n_key` em bin a pré-conferência agruparia diferente do UNIQUE da coluna gerada
SET @sql77_coll := (
  SELECT COUNT(*) FROM information_schema.COLUMNS c
   WHERE c.`TABLE_SCHEMA` = DATABASE() AND c.`COLLATION_NAME` = 'utf8mb4_general_ci'
     AND ((c.`TABLE_NAME` = 'tb_interface' AND c.`COLUMN_NAME` = 'i18n_key')
       OR (c.`TABLE_NAME` = 'tb_privilege' AND c.`COLUMN_NAME` = 'description')));
SET @sql77_check := IF(@sql77_coll = 2, 'DO 0', 'SELECT 1 FROM `SQL77_FALHOU_colacao_de_i18n_key_ou_description_nao_e_general_ci`');
PREPARE sql77_check FROM @sql77_check;
EXECUTE sql77_check;
DEALLOCATE PREPARE sql77_check;

-- (2b) duplicatas, comparadas EXPLICITAMENTE na colação do UNIQUE
SET @sql77_dup_key := (
  SELECT COUNT(*) FROM (SELECT `i18n_key` COLLATE utf8mb4_general_ci AS k FROM `tb_interface`
                         WHERE `deleted` = 'N' AND `i18n_key` IS NOT NULL
                         GROUP BY k HAVING COUNT(*) > 1) d);
SET @sql77_check := IF(@sql77_dup_key = 0, 'DO 0', 'SELECT 1 FROM `SQL77_FALHOU_chave_viva_repetida_em_tb_interface`');
PREPARE sql77_check FROM @sql77_check;
EXECUTE sql77_check;
DEALLOCATE PREPARE sql77_check;

SET @sql77_dup_verb := (
  SELECT COUNT(*) FROM (SELECT `description` COLLATE utf8mb4_general_ci AS n FROM `tb_privilege`
                         WHERE `description` IS NOT NULL
                         GROUP BY n HAVING COUNT(*) > 1) d);
SET @sql77_check := IF(@sql77_dup_verb = 0, 'DO 0', 'SELECT 1 FROM `SQL77_FALHOU_verbo_repetido_em_tb_privilege_viva_ou_excluida`');
PREPARE sql77_check FROM @sql77_check;
EXECUTE sql77_check;
DEALLOCATE PREPARE sql77_check;

-- (3) a COLUNA gerada — estado: 0 ausente · 1 idêntica · 2 diferente (tipo, colação, STORED ou expressão)
SET @sql77_col := (
  SELECT CASE
           WHEN COUNT(*) = 0 THEN 0
           WHEN MAX(c.`DATA_TYPE` = 'varchar' AND c.`CHARACTER_MAXIMUM_LENGTH` = 100
                    AND c.`CHARACTER_SET_NAME` = 'utf8mb4' AND c.`COLLATION_NAME` = 'utf8mb4_general_ci'
                    AND UPPER(c.`EXTRA`) LIKE '%STORED GENERATED%'
                    AND LOWER(REPLACE(REPLACE(REPLACE(c.`GENERATION_EXPRESSION`, '`', ''), ' ', ''), '"', ''))
                        = 'casewhendeleted=''n''theni18n_keyend') THEN 1
           ELSE 2
         END
    FROM information_schema.COLUMNS c
   WHERE c.`TABLE_SCHEMA` = DATABASE() AND c.`TABLE_NAME` = 'tb_interface' AND c.`COLUMN_NAME` = 'i18n_key_live');
SET @sql77_check := CASE @sql77_col
  WHEN 0 THEN 'ALTER TABLE `tb_interface` ADD COLUMN `i18n_key_live` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci
    GENERATED ALWAYS AS (CASE WHEN `deleted` = ''N'' THEN `i18n_key` END) STORED
    COMMENT ''D-PV43: a chave entre as VIVAS (NULL nas excluidas) - base do UNIQUE uq_interface_i18n_key_live'''
  WHEN 1 THEN 'DO 0'
  ELSE 'SELECT 1 FROM `SQL77_FALHOU_coluna_i18n_key_live_com_outra_forma`' END;
PREPARE sql77_check FROM @sql77_check;
EXECUTE sql77_check;
DEALLOCATE PREPARE sql77_check;

-- (4) os dois UNIQUE — estado: 0 ausente · 1 idêntico (único, BTREE, uma coluna só, a certa, sem prefixo) · 2 diferente.
-- O nome é comparado COM caixa (BINARY): um homônimo em maiúsculas não passa por idêntico (o ADD falha alto com nome repetido); BTREE
-- porque o UNIQUE "USING HASH" do MariaDB (long unique) tem outra garantia sob concorrência (gate adversarial do PRIV.E7.P1)
SET @sql77_uq_key := (
  SELECT CASE WHEN COUNT(*) = 0 THEN 0
              WHEN COUNT(*) = 1 AND MAX(s.`NON_UNIQUE`) = 0 AND MAX(s.`COLUMN_NAME`) = 'i18n_key_live' AND MAX(s.`INDEX_TYPE`) = 'BTREE'
                   AND MAX(s.`SEQ_IN_INDEX`) = 1 AND MAX(s.`SUB_PART`) IS NULL THEN 1
              ELSE 2 END
    FROM information_schema.STATISTICS s
   WHERE s.`TABLE_SCHEMA` = DATABASE() AND s.`TABLE_NAME` = 'tb_interface' AND BINARY s.`INDEX_NAME` = 'uq_interface_i18n_key_live');
SET @sql77_check := CASE @sql77_uq_key
  WHEN 0 THEN 'ALTER TABLE `tb_interface` ADD UNIQUE KEY `uq_interface_i18n_key_live` (`i18n_key_live`)'
  WHEN 1 THEN 'DO 0'
  ELSE 'SELECT 1 FROM `SQL77_FALHOU_indice_uq_interface_i18n_key_live_com_outra_forma`' END;
PREPARE sql77_check FROM @sql77_check;
EXECUTE sql77_check;
DEALLOCATE PREPARE sql77_check;

SET @sql77_uq_verb := (
  SELECT CASE WHEN COUNT(*) = 0 THEN 0
              WHEN COUNT(*) = 1 AND MAX(s.`NON_UNIQUE`) = 0 AND MAX(s.`COLUMN_NAME`) = 'description' AND MAX(s.`INDEX_TYPE`) = 'BTREE'
                   AND MAX(s.`SEQ_IN_INDEX`) = 1 AND MAX(s.`SUB_PART`) IS NULL THEN 1
              ELSE 2 END
    FROM information_schema.STATISTICS s
   WHERE s.`TABLE_SCHEMA` = DATABASE() AND s.`TABLE_NAME` = 'tb_privilege' AND BINARY s.`INDEX_NAME` = 'uq_privilege_description');
SET @sql77_check := CASE @sql77_uq_verb
  WHEN 0 THEN 'ALTER TABLE `tb_privilege` ADD UNIQUE KEY `uq_privilege_description` (`description`)'
  WHEN 1 THEN 'DO 0'
  ELSE 'SELECT 1 FROM `SQL77_FALHOU_indice_uq_privilege_description_com_outra_forma`' END;
PREPARE sql77_check FROM @sql77_check;
EXECUTE sql77_check;
DEALLOCATE PREPARE sql77_check;

-- (5) CONFERÊNCIA — o estado final, relido do zero; qualquer desvio FALHA o script
SET @sql77_col_ok := (
  SELECT COUNT(*) FROM information_schema.COLUMNS c
   WHERE c.`TABLE_SCHEMA` = DATABASE() AND c.`TABLE_NAME` = 'tb_interface' AND c.`COLUMN_NAME` = 'i18n_key_live'
     AND c.`DATA_TYPE` = 'varchar' AND c.`CHARACTER_MAXIMUM_LENGTH` = 100 AND c.`COLLATION_NAME` = 'utf8mb4_general_ci'
     AND UPPER(c.`EXTRA`) LIKE '%STORED GENERATED%'
     AND LOWER(REPLACE(REPLACE(REPLACE(c.`GENERATION_EXPRESSION`, '`', ''), ' ', ''), '"', '')) = 'casewhendeleted=''n''theni18n_keyend');
SET @sql77_uq_ok := (
  SELECT COUNT(*) FROM information_schema.STATISTICS s
   WHERE s.`TABLE_SCHEMA` = DATABASE() AND s.`NON_UNIQUE` = 0 AND s.`SEQ_IN_INDEX` = 1 AND s.`SUB_PART` IS NULL AND s.`INDEX_TYPE` = 'BTREE'
     AND ((s.`TABLE_NAME` = 'tb_interface' AND BINARY s.`INDEX_NAME` = 'uq_interface_i18n_key_live' AND s.`COLUMN_NAME` = 'i18n_key_live')
       OR (s.`TABLE_NAME` = 'tb_privilege' AND BINARY s.`INDEX_NAME` = 'uq_privilege_description' AND s.`COLUMN_NAME` = 'description')));
-- §9 regra 10: além da PK e destes, NENHUM outro UNIQUE nas duas tabelas (contando por índice, não por coluna; nome com caixa)
SET @sql77_extra := (
  SELECT COUNT(DISTINCT s.`TABLE_NAME`, s.`INDEX_NAME`) FROM information_schema.STATISTICS s
   WHERE s.`TABLE_SCHEMA` = DATABASE() AND s.`TABLE_NAME` IN ('tb_interface', 'tb_privilege') AND s.`NON_UNIQUE` = 0
     AND BINARY s.`INDEX_NAME` NOT IN ('PRIMARY', 'uq_interface_i18n_key_live', 'uq_privilege_description'));
-- as colunas nomeadas seguem em general_ci (a colação É a regra do UNIQUE)
SET @sql77_coll := (
  SELECT COUNT(*) FROM information_schema.COLUMNS c
   WHERE c.`TABLE_SCHEMA` = DATABASE() AND c.`COLLATION_NAME` = 'utf8mb4_general_ci'
     AND ((c.`TABLE_NAME` = 'tb_interface' AND c.`COLUMN_NAME` = 'i18n_key')
       OR (c.`TABLE_NAME` = 'tb_privilege' AND c.`COLUMN_NAME` = 'description')));
SELECT @sql77_col_ok AS `coluna_ok_de_1`, @sql77_uq_ok AS `unique_ok_de_2`, @sql77_extra AS `unique_a_mais_de_0`,
       @sql77_coll AS `colacao_ok_de_2`;

SET @sql77_check := IF(@sql77_col_ok = 1 AND @sql77_uq_ok = 2 AND @sql77_extra = 0 AND @sql77_coll = 2,
  'DO 0', 'SELECT 1 FROM `SQL77_FALHOU_conferencia_dos_nomes_unicos`');
PREPARE sql77_check FROM @sql77_check;
EXECUTE sql77_check;
DEALLOCATE PREPARE sql77_check;
