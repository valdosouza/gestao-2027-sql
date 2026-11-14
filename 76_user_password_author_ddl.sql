-- =============================================================================
-- 76 — setes_central.tb_user: o PAPEL de quem definiu a senha vigente (titular, administrador ou operador)
-- Escopo: setes
-- Origem: Vault/prompts/prompt_frente_usuario_convidado.md — D-UC19 (o login só aceita convite com a senha do PRÓPRIO titular) e A-UC9
--         (credenciais de antes ficam sem autor). Parecer do guardião
--         (`setes-conceito`) e rascunho pelo `revisar-ddl` de 2026-11-14. Irmã da D-EA7 (script 70: `password_set_at`).
--         PADROES_BANCO §3/§3.1/§9 regra 10/§11 regras 7, 11 e 16.
--
-- O CONCEITO: uma coluna nova, anulável, NENHUMA linha preenchida aqui:
--   password_author_role  char(1) — o PAPEL de quem definiu a senha que vale hoje, gravado JUNTO com o hash e o `password_set_at`
--                         pela peça "definir a senha" do setes-api (a mesma que grava o `password_set_at` — D-EA7):
--                           T = o titular (a própria pessoa: troca pelo código — "Esqueci minha senha" — ou "Minha senha")
--                           A = um administrador (a senha inicial na criação — D-UC8 — e a 1ª senha da conta vinda do sync — A-PV23)
--                           O = o operador da Setes (script do Super)
--                           NULL = desconhecido (senha definida antes deste script) ou sem senha
--                         É o PAPEL, não a pessoa: quem foi fica no log. Nunca pelo salvar do cadastro sem troca de senha nem pela
--                         migração do hash (que não muda a senha). Vai COM o hash para `tb_user_credential` na A2 (como o
--                         `password_set_at` — D-AU5).
-- SEM backfill (A-UC9): um papel carimbado agora para as senhas de antes seria fato falso. O setes-sync segue criando `tb_user` sem a
-- coluna (NULL — sem senha). Os escritores de hoje não citam a coluna: gravam NULL e passam nos dois CHECKs.
--
-- INVARIANTES no banco (CHECK — o motor confere também as linhas que já existem ao criar o CHECK):
--   ck_user_password_author_role          domínio fechado BINÁRIO (§11 regra 11): 't' minúscula é recusada. char(1): o espaço no fim
--                                         não existe na coluna CHAR, então a regra 16 (PAD SPACE) não abre brecha aqui.
--   ck_user_password_author_has_password  papel só existe com senha E com o instante dela (`password` e `password_set_at`).
--                                         Consequência para os escritores: quem LIMPAR a senha limpa o papel no MESMO UPDATE.
-- Conhecimento negativo (§11 regra 11 (d)): numa sessão SEM modo estrito (o servidor do dev roda assim) um texto maior que a coluna é
-- CORTADO antes do CHECK — 'Admin' grava 'A' e passa. Quem grava confere o valor exato antes (ou roda em sessão estrita).
--
-- Nada se apaga (§3.1). Sem UNIQUE novo. Tabela CENTRAL: script numerado à mão. `ADD COLUMN IF NOT EXISTS`/`DROP CONSTRAINT IF EXISTS`
-- são só do MariaDB (a ida ao MySQL 8 — F3 — revê, PADROES §11 regra 11 (c)).
--
-- Re-executável (nenhum UPDATE de dados). Os dois CHECKs são TROCADOS a cada execução (DROP + ADD): o `ADD CONSTRAINT IF NOT EXISTS`
-- decide pelo NOME e manteria um corpo antigo (lição do 75, re-gate do CONV.E2.P6, D3a). Roda À MÃO em setes_central ANTES do setes-api
-- que grava a coluna; rodar de novo depois não muda nada. Rodar com `SET NAMES utf8mb4` (numa sessão latin1 o COLLATE utf8mb4_bin dá
-- erro 1253) e com o usuário dono de sempre. CONFERÊNCIA no fim: qualquer desvio FALHA o script com
-- "Table '...SQL76_FALHOU_...' doesn't exist" (molde dos seeds 64/72 e do 75). Espelho no sql/01.
-- =============================================================================

SET NAMES utf8mb4;
-- Espera curta = DUAS variáveis (PADROES §11 regra 7): o ALTER pede trava de METADADOS na tabela do LOGIN (vw_user_link). Uma transação
-- ociosa segurando a tabela não pode enfileirar todo login atrás do ALTER — sem trava em 10 s o script falha. Rode de novo.
SET SESSION lock_wait_timeout = 10;
SET SESSION innodb_lock_wait_timeout = 10;

USE `setes_central`;

-- (1) a coluna — anulável, sem preenchimento (vazio = desconhecido ou sem senha)
ALTER TABLE `tb_user`
  ADD COLUMN IF NOT EXISTS `password_author_role` char(1) NULL DEFAULT NULL
    COMMENT 'D-UC19/A-UC9: papel de quem definiu a senha vigente - T titular, A administrador, O operador, NULL desconhecido ou sem senha'
    AFTER `password_set_at`;

-- (2) as invariantes — TROCADAS a cada execução (o ADD confere as linhas existentes e falha alto se alguma violar)
ALTER TABLE `tb_user`
  DROP CONSTRAINT IF EXISTS `ck_user_password_author_role`,
  DROP CONSTRAINT IF EXISTS `ck_user_password_author_has_password`;
ALTER TABLE `tb_user`
  ADD CONSTRAINT `ck_user_password_author_role`
    CHECK (`password_author_role` IS NULL OR `password_author_role` COLLATE utf8mb4_bin IN ('T', 'A', 'O')),
  ADD CONSTRAINT `ck_user_password_author_has_password`
    CHECK (`password_author_role` IS NULL OR (`password` IS NOT NULL AND `password_set_at` IS NOT NULL));

-- (3) relatório (para o operador ler): credenciais por autor
SELECT COALESCE(`password_author_role`, '(desconhecido)') AS `autor`,
       (CASE WHEN `password` IS NULL THEN 'sem senha' ELSE 'com senha' END) AS `senha`,
       COUNT(*) AS `usuarios`
  FROM `tb_user`
 GROUP BY 1, 2
 ORDER BY 1, 2;

-- (4) CONFERÊNCIA — qualquer desvio FALHA o script
SET @sql76_col := (
  SELECT COUNT(*) FROM information_schema.COLUMNS c
   WHERE c.TABLE_SCHEMA = 'setes_central' AND c.TABLE_NAME = 'tb_user' AND c.COLUMN_NAME = 'password_author_role'
     AND c.DATA_TYPE = 'char' AND c.CHARACTER_MAXIMUM_LENGTH = 1 AND c.CHARACTER_SET_NAME = 'utf8mb4'
     AND c.IS_NULLABLE = 'YES' AND COALESCE(c.COLUMN_DEFAULT, 'NULL') = 'NULL'
     AND c.ORDINAL_POSITION = (SELECT p.ORDINAL_POSITION + 1 FROM information_schema.COLUMNS p
                                WHERE p.TABLE_SCHEMA = 'setes_central' AND p.TABLE_NAME = 'tb_user'
                                  AND p.COLUMN_NAME = 'password_set_at'));
SET @sql76_cons := (
  SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
   WHERE CONSTRAINT_SCHEMA = 'setes_central' AND TABLE_NAME = 'tb_user' AND CONSTRAINT_TYPE = 'CHECK'
     AND CONSTRAINT_NAME IN ('ck_user_password_author_role', 'ck_user_password_author_has_password'));
-- o corpo do domínio é BINÁRIO (a lição do 75: o nome sozinho não prova o corpo)
SET @sql76_bin := (
  SELECT COUNT(*) FROM information_schema.CHECK_CONSTRAINTS
   WHERE CONSTRAINT_SCHEMA = 'setes_central' AND TABLE_NAME = 'tb_user'
     AND CONSTRAINT_NAME = 'ck_user_password_author_role'
     AND LOWER(CHECK_CLAUSE) LIKE '%utf8mb4_bin%');
SELECT @sql76_col AS `coluna_ok_de_1`, @sql76_cons AS `checks_ok_de_2`, @sql76_bin AS `dominio_binario_ok_de_1`,
       @@check_constraint_checks AS `check_aplicado`;

SET @sql76_check := IF(@sql76_col = 1 AND @sql76_cons = 2 AND @sql76_bin = 1 AND @@check_constraint_checks = 1,
  'DO 0', 'SELECT 1 FROM `SQL76_FALHOU_conferencia_do_autor_da_senha`');
PREPARE sql76_check FROM @sql76_check;
EXECUTE sql76_check;
DEALLOCATE PREPARE sql76_check;
