-- =============================================================================
-- 74 — setes_central.tb_user_login_failure + tb_user_login_block_notice (D-EA1/D-EA2/D-EA3/D-EA14/D-EA15 — limite POR CONTA no
--      POST /auth/login e o aviso ao dono da conta bloqueada)
-- Escopo: setes
-- Origem: Infra-IA/prompts/prompt_endurecer_autenticacao.md — Decisões D-EA1, D-EA2, D-EA3, D-EA14, D-EA15 e A-EA1…A-EA8; §P.3
--         (parecer do guardião `setes-conceito`, 2026-11-01), §P.4 (rascunho pelo `revisar-ddl`) e §P.5 (plano de testes — prova
--         `setes-api/scripts/prove-login-lock.ts` em schema descartável). PADROES_BANCO §3/§3.1/§9 (regras 12 e 13)/§10/§11.
--
-- tb_user_login_failure — O CONCEITO (D-EA2): "uma senha ERRADA foi julgada contra a credencial do usuário, num login ADMITIDO (conta
-- fora do bloqueio), no instante T". Só FALHAS são gravadas (o sucesso não grava nada); append-only (nada se apaga — §3.1). O BLOQUEIO
-- é DERIVADO, nunca coluna de estado: 10 ou mais linhas do usuário com `created_at > NOW() - INTERVAL 15 MINUTE` (D-EA1 — janela
-- DESLIZANTE: a conta volta sozinha quando a falha mais velha da janela envelhece; sem botão de desbloquear). A leitura que decide
-- conta TODA linha (nem `deleted` nem `updated_at` entram no julgamento — soft delete não desbloqueia; o julgamento também NÃO filtra
-- por `tb_user.password_set_at`: trocar a senha, até pelo script do Super, NÃO desbloqueia — conhecimento negativo do parecer).
--   GRAVA: senha errada contra credencial EXISTENTE — também com o usuário ou o vínculo inativo/ausente (A-EA1: fato da CREDENCIAL).
--   NÃO GRAVA: senha certa (qualquer estado — D-EA6), e-mail inexistente, conta SEM credencial (`password` NULL ou '' — A-EA3),
--   tentativa DURANTE o bloqueio (nenhum palpite é julgado — o caminho bloqueado é só-leitura) e recusa por contenção na trava.
--   Consequência: a janela nunca passa de 10 linhas → ≤ 960 linhas/dia por conta atacada, sem retenção (A-EA5).
--
-- tb_user_login_block_notice — O CONCEITO (D-EA3, nome da D-EA14): "o sistema tomou a vaga horária de avisar o dono de que o login da
-- conta foi bloqueado". A vaga é tomada na falha que LEVA a janela a 10 (D-EA15 — contagem antes do INSERT = 9, sob a trava), no máximo
-- 1 por hora por conta (coalescência `EXISTS created_at > NOW() - INTERVAL 60 MINUTE`), sob SAVEPOINT na MESMA transação da falha (D-RS10
-- — a falha do aviso NUNCA desfaz a 10ª falha, senão a conta nunca bloquearia); o e-mail (neutro, sem link) sai DEPOIS do COMMIT, ao
-- e-mail de login GRAVADO, pela peça @shared/mailer. Sem `kind` (causa única = o nome), sem `sent_at` (SMTP aceito ≠ entregue).
--
-- PROTOCOLO DE TRAVA (PADROES §9 regras 12 e 13 — o MESMO das filhas do script 67): o serializador é a LINHA do usuário em
-- `setes_central.tb_user` (`SELECT … FOR UPDATE WAIT 5`, 1º statement da transação do login). Sob ela, as leituras das linhas DELE nas
-- duas tabelas são CONSISTENTES (sem FOR UPDATE de faixa — a trava de intervalo fecharia ciclo com o usuário vizinho); as gravações são
-- INSERT pela PK com `seq` = MAX+1 POR USUÁRIO (nunca global). A senha é conferida FORA da trava; um pré-filtro SEM trava (a mesma
-- contagem, fora de transação) recusa a conta já bloqueada sem conferir a senha e sem travar (A-EA2).
-- `created_at` = NOW() do banco em UTC (PADROES §10 regra 1; o boot confere a sessão em UTC); a janela lê o MESMO relógio.
--
-- Índice `idx_user_login_failure_window (tb_user_id, created_at)`: a leitura que decide é `range` + `Using index` e lê no máximo as
-- linhas da janela, qualquer que seja a história da conta. Vai também por fora do CREATE TABLE (revisar-ddl item 2: o reexecutar
-- CONSERTA uma tabela criada sem ele). O boot NÃO confere o índice (sem ele o login fica certo, só lento) — a prova confere o EXPLAIN.
--
-- EFEITO DA AUTH-API (D-AU4/D-AU5/D-AU6): as duas nascem em `setes_central` chaveadas por `tb_user_id` e mudam para o banco `auth_api`
-- na A2 com as filhas do 67, sem reforma — a trava passa a ser a linha de `tb_user_credential` e as FKs para `tb_user` caem (sem FK entre
-- bancos — PADROES §11.1). Os NOMES das FKs são contrato da A2 (o DROP é pelo nome). Fora do GRANT do usuário fiscal (D-AU12 — lista
-- positiva). Nenhuma senha, hash, IP ou e-mail nas tabelas (o rastro forense é UMA linha de LOG por falha — D-EA11).
--
-- Re-executável. Aplicar em setes_central ANTES do setes-api que a lê (o boot confere as DUAS tabelas pelas colunas:
-- `assertLoginLockSchema` — sem elas toda senha errada viraria 500). Espelho no sql/01 (logo depois de tb_user_password_reset_notice).
-- =============================================================================

SET NAMES utf8mb4;
USE `setes_central`;

CREATE TABLE IF NOT EXISTS `tb_user_login_failure` (
  `tb_user_id` int(11)  NOT NULL COMMENT 'Usuario dono da credencial contra a qual a senha errada foi julgada',
  `seq`        int(11)  NOT NULL COMMENT 'N-esima falha do usuario: MAX+1 sob FOR UPDATE da linha tb_user',
  `created_at` datetime NOT NULL COMMENT 'Instante UTC (NOW do banco) do julgamento - a janela de 15 min da D-EA1 le este relogio',
  `updated_at` datetime DEFAULT NULL COMMENT 'Padrao da casa; fato imutavel - sem escritor depois do INSERT',
  `deleted`    char(1)  NOT NULL DEFAULT 'N' COMMENT 'Padrao da casa; sem escritor - o julgamento conta toda linha (soft delete nao desbloqueia)',
  PRIMARY KEY (`tb_user_id`, `seq`),
  KEY `idx_user_login_failure_window` (`tb_user_id`, `created_at`),
  CONSTRAINT `fk_user_login_failure_to_user` FOREIGN KEY (`tb_user_id`) REFERENCES `tb_user` (`id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `ck_user_login_failure_seq` CHECK (`seq` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='D-EA2: senha errada julgada contra a credencial num login admitido; bloqueio = 10+ na janela de 15 min (derivado)';

-- revisar-ddl item 2: o índice também por fora, para o reexecutar CONSERTAR uma tabela criada sem ele (MariaDB >= 10.1.4)
CREATE INDEX IF NOT EXISTS `idx_user_login_failure_window` ON `tb_user_login_failure` (`tb_user_id`, `created_at`);

CREATE TABLE IF NOT EXISTS `tb_user_login_block_notice` (
  `tb_user_id` int(11)  NOT NULL COMMENT 'Usuario dono da credencial avisado',
  `seq`        int(11)  NOT NULL COMMENT 'N-esimo aviso do usuario: MAX+1 sob FOR UPDATE da linha tb_user',
  `created_at` datetime NOT NULL COMMENT 'Instante UTC em que o sistema tomou a vaga da hora (e-mail sai depois do COMMIT)',
  `updated_at` datetime DEFAULT NULL COMMENT 'Padrao da casa; sem escritor depois do INSERT',
  `deleted`    char(1)  NOT NULL DEFAULT 'N' COMMENT 'Padrao da casa; sem escritor',
  PRIMARY KEY (`tb_user_id`, `seq`),
  CONSTRAINT `fk_user_login_block_notice_to_user` FOREIGN KEY (`tb_user_id`) REFERENCES `tb_user` (`id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `ck_user_login_block_notice_seq` CHECK (`seq` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='D-EA3: vaga horaria do aviso ao dono de que o login da conta foi bloqueado (1/h por conta)';
