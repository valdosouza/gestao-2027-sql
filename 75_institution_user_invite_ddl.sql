-- =============================================================================
-- 75 — setes_central.tb_institution_has_user: o CONVITE, o ACEITE e a RETIRADA do vínculo (usuário convidado entre estabelecimentos)
-- Escopo: setes
-- Origem: Infra-IA/prompts/prompt_frente_usuario_convidado.md — D-UC10 (o fato mora no vínculo), revista pela D-UC14 (o que marca
--         "aguardando aceite" é o CONVITE) e completada pela D-UC15 (a retirada); D-UC12 (o LOGIN do titular é o aceite), A-UC8.
--         Parecer do guardião (`setes-conceito`) e rascunho pelo `revisar-ddl` de 2026-11-14 (ficha `ficha-conv-e2-p1-aguardando-aceite.md`
--         no Vault, setes-api:CONV.E2.P1). PADROES_BANCO §3/§3.1/§9 regra 10/§10/§11 regras 7 e 11.
--
-- O CONCEITO (D-UC14/D-UC15): quatro colunas novas, TODAS anuláveis, nenhuma preenchida para o que já existe:
--   tb_user_inviter_id   o usuário (tb_user.id) cujo ATO no cadastro criou ou interceptou o vínculo. Pode faltar mesmo com convite (o
--                        onboarding nem sempre tem quem criou).
--   invited_at           instante UTC desse ato. Preenchido = o vínculo nasceu de convite (ou da criação no 1º estabelecimento, que
--                        grava convite e aceite no mesmo instante).
--   accepted_at          instante UTC do aceite, gravado UMA vez (o aceite é o LOGIN do titular — D-UC12; o write-once fica no UPDATE do
--                        aceite, que filtra `accepted_at IS NULL`).
--   invite_withdrawn_at  instante UTC em que o admin RETIROU o convite ainda não aceito (D-UC15). Um novo convite no mesmo par regrava
--                        o convite e limpa a retirada; o histórico fica no log.
-- Estado DERIVADO, nunca coluna:
--   aguardando aceite = invited_at preenchido E accepted_at vazio E invite_withdrawn_at vazio (o login do titular o ativa)
--   convite retirado  = invite_withdrawn_at preenchido (o login NÃO o ativa)
--   sem convite       = invited_at vazio — os vínculos de antes deste script e os que o setes-sync grava (`kind='SYNC'`): NADA se
--                       inventa para eles (o `created_at` antigo está na hora de SP e o do sync na hora da sessão dele) e o login nunca
--                       os ativa. Por isso NÃO há preenchimento aqui (D-UC14; revê a D-UC10, que usava `active='N'` + aceite vazio e
--                       pegaria os inativos do sync e os inativados de hoje).
-- Nenhum leitor do acesso muda: a vw_user_link (script 70) exige `active='S'`.
--
-- INVARIANTES no banco (CHECK — o motor confere também as linhas que já existem ao criar o CHECK; vale com ou sem modo estrito):
--   ck_ihu_inviter_has_invite   quem convidou só existe com o instante do convite
--   ck_ihu_pending_inactive     convite NUNCA ACEITO (pendente OU retirado) nunca está ativo (rede de segurança contra qualquer
--                               escritor que ative sem o aceite — A-UC8; gate adversarial do CONV.E2.P6, X3: cobria só o pendente); `active` na colação da coluna (_ci): 's' conta como ativo, como nos leitores
--   ck_ihu_accept_after_invite  aceito sempre tem convite, e o aceite não vem antes dele
--   ck_ihu_withdraw_pending     só convite NUNCA aceito é retirado, e a retirada não vem antes do convite
--   Os escritores de hoje (setes-api, setes-sync, seed 02) não citam as colunas: gravam as quatro vazias e passam nos quatro CHECKs.
--
-- Nada se apaga (§3.1). Sem UNIQUE novo (o upsert do setes-api e do setes-sync nesta tabela segue legítimo — §9 regra 10). Tabela
-- CENTRAL: script numerado à mão, não migration de schema de cliente. `ADD COLUMN/CONSTRAINT/INDEX IF NOT EXISTS` são só do MariaDB
-- (a ida ao MySQL 8 — F3 — revê, PADROES §11 regra 11 (c)).
--
-- Re-executável (nenhum UPDATE de dados). Roda À MÃO em setes_central na janela da onda do convidado (CONV.E2.P6), ANTES do setes-api
-- que grava as colunas; rodar de novo depois não muda nada. Rodar com o usuário dono de sempre. CONFERÊNCIA no fim: qualquer desvio
-- FALHA o script com "Table '...SQL75_FALHOU_...' doesn't exist" (molde dos seeds 64/72). Espelho no sql/01.
-- Prova em setes_central DESCARTÁVEL: setes-api/scripts/prove-institution-user-invite.ts.
-- =============================================================================

SET NAMES utf8mb4;
-- Espera curta = DUAS variáveis (PADROES §11 regra 7): o ALTER pede trava de METADADOS na tabela do LOGIN (vw_user_link). Uma transação
-- ociosa segurando a tabela não pode enfileirar todo login atrás do ALTER — sem trava em 10 s o script falha; rode de novo.
SET SESSION lock_wait_timeout = 10;
SET SESSION innodb_lock_wait_timeout = 10;

USE `setes_central`;

-- (1) as colunas — anuláveis, sem default (vazio = sem convite)
ALTER TABLE `tb_institution_has_user`
  ADD COLUMN IF NOT EXISTS `tb_user_inviter_id` int(11) NULL DEFAULT NULL
    COMMENT 'D-UC10: usuario cujo ato criou ou interceptou o vinculo - NULL = sem convite ou sem autor' AFTER `active`,
  ADD COLUMN IF NOT EXISTS `invited_at` datetime NULL DEFAULT NULL
    COMMENT 'D-UC14: instante UTC do convite - NULL = vinculo sem convite (anterior ou do setes-sync)' AFTER `tb_user_inviter_id`,
  ADD COLUMN IF NOT EXISTS `accepted_at` datetime NULL DEFAULT NULL
    COMMENT 'D-UC10/D-UC12: instante UTC do aceite (login do titular), gravado uma vez' AFTER `invited_at`,
  ADD COLUMN IF NOT EXISTS `invite_withdrawn_at` datetime NULL DEFAULT NULL
    COMMENT 'D-UC15: instante UTC em que o admin retirou o convite ainda nao aceito' AFTER `accepted_at`;

-- (2) índice + FK do convidante (índice por fora, para a reexecução consertar; a FK guardada pelo NOME)
CREATE INDEX IF NOT EXISTS `idx_ihu_inviter` ON `tb_institution_has_user` (`tb_user_inviter_id`);

SET @sql75_fk := (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
                   WHERE CONSTRAINT_SCHEMA = 'setes_central' AND TABLE_NAME = 'tb_institution_has_user'
                     AND CONSTRAINT_NAME = 'fk_ihu_inviter_to_user' AND CONSTRAINT_TYPE = 'FOREIGN KEY');
SET @sql75_ddl := IF(@sql75_fk = 0,
  'ALTER TABLE `tb_institution_has_user` ADD CONSTRAINT `fk_ihu_inviter_to_user` FOREIGN KEY (`tb_user_inviter_id`) REFERENCES `tb_user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION',
  'DO 0');
PREPARE sql75_ddl FROM @sql75_ddl;
EXECUTE sql75_ddl;
DEALLOCATE PREPARE sql75_ddl;

-- (3) as invariantes (o ADD CONSTRAINT confere as linhas existentes e falha alto se alguma violar)
-- O CHECK do pendente é TROCADO a cada execução (DROP + ADD): a 1ª versão deste script recusava só o pendente ativo e, com o ADD … IF NOT
-- EXISTS, uma reexecução a manteria (re-gate adversarial do CONV.E2.P6, D3a); o boot do setes-api também confere o corpo
ALTER TABLE `tb_institution_has_user` DROP CONSTRAINT IF EXISTS `ck_ihu_pending_inactive`;
ALTER TABLE `tb_institution_has_user`
  ADD CONSTRAINT IF NOT EXISTS `ck_ihu_inviter_has_invite`
    CHECK (`tb_user_inviter_id` IS NULL OR `invited_at` IS NOT NULL),
  ADD CONSTRAINT IF NOT EXISTS `ck_ihu_pending_inactive`
    CHECK (NOT (`invited_at` IS NOT NULL AND `accepted_at` IS NULL AND `active` = 'S')),
  ADD CONSTRAINT IF NOT EXISTS `ck_ihu_accept_after_invite`
    CHECK (`accepted_at` IS NULL OR (`invited_at` IS NOT NULL AND `invited_at` <= `accepted_at`)),
  ADD CONSTRAINT IF NOT EXISTS `ck_ihu_withdraw_pending`
    CHECK (`invite_withdrawn_at` IS NULL
           OR (`invited_at` IS NOT NULL AND `accepted_at` IS NULL AND `invited_at` <= `invite_withdrawn_at`));

-- (4) relatório (para o operador ler): vínculos por situação
SELECT CASE
         WHEN `invited_at` IS NULL                                   THEN 'sem convite'
         WHEN `invite_withdrawn_at` IS NOT NULL                      THEN 'convite retirado'
         WHEN `accepted_at` IS NULL                                  THEN 'aguardando aceite'
         ELSE 'aceito'
       END AS `situacao`,
       `active`,
       COUNT(*) AS `vinculos`
  FROM `tb_institution_has_user`
 GROUP BY 1, 2
 ORDER BY 1, 2;

-- (5) CONFERÊNCIA — qualquer desvio FALHA o script
SET @sql75_cols := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = 'setes_central' AND TABLE_NAME = 'tb_institution_has_user' AND IS_NULLABLE = 'YES'
     AND COALESCE(COLUMN_DEFAULT, 'NULL') = 'NULL'
     AND (   (COLUMN_NAME = 'tb_user_inviter_id'  AND DATA_TYPE = 'int')
          OR (COLUMN_NAME IN ('invited_at', 'accepted_at', 'invite_withdrawn_at') AND DATA_TYPE = 'datetime')));
SET @sql75_cons := (
  SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
   WHERE CONSTRAINT_SCHEMA = 'setes_central' AND TABLE_NAME = 'tb_institution_has_user'
     AND (   (CONSTRAINT_TYPE = 'CHECK' AND CONSTRAINT_NAME IN ('ck_ihu_inviter_has_invite', 'ck_ihu_pending_inactive',
                                                               'ck_ihu_accept_after_invite', 'ck_ihu_withdraw_pending'))
          OR (CONSTRAINT_TYPE = 'FOREIGN KEY' AND CONSTRAINT_NAME = 'fk_ihu_inviter_to_user')));
SET @sql75_fk_target := (
  SELECT COUNT(*) FROM information_schema.KEY_COLUMN_USAGE
   WHERE CONSTRAINT_SCHEMA = 'setes_central' AND TABLE_NAME = 'tb_institution_has_user'
     AND CONSTRAINT_NAME = 'fk_ihu_inviter_to_user' AND COLUMN_NAME = 'tb_user_inviter_id'
     AND REFERENCED_TABLE_SCHEMA = 'setes_central' AND REFERENCED_TABLE_NAME = 'tb_user' AND REFERENCED_COLUMN_NAME = 'id');
SELECT @sql75_cols AS `colunas_ok_de_4`, @sql75_cons AS `constraints_ok_de_5`, @sql75_fk_target AS `fk_alvo_ok_de_1`,
       @@check_constraint_checks AS `check_aplicado`;

SET @sql75_check := IF(@sql75_cols = 4 AND @sql75_cons = 5 AND @sql75_fk_target = 1 AND @@check_constraint_checks = 1,
  'DO 0', 'SELECT 1 FROM `SQL75_FALHOU_conferencia_do_convite_no_vinculo`');
PREPARE sql75_check FROM @sql75_check;
EXECUTE sql75_check;
DEALLOCATE PREPARE sql75_check;
