-- =============================================================================
-- 67 — setes_central.tb_user_password_reset (Q-PV38 / D-PV13 — força bruta no código de 6 dígitos do /auth/change-password)
-- Escopo: setes
-- Origem: Infra-IA/prompts/prompt_privilegios_interfaces.md §11.4 (Q-PV38) e §13 (execução); parecer do guardião (2026-10-18);
--         PADROES_BANCO §3/§3.1/§4/§9 (regras 2, 7 e 12)/§10/§11 regra 15.
--
-- O conceito: a AUTORIZAÇÃO DE USO ÚNICO para redefinir a senha de um usuário, provada por um código enviado ao e-mail de login.
-- Nasce do pedido de recuperação (`POST /auth/recovery-password`): uma linha por código emitido. O único fato gravado depois é o USO
-- (`used_at`, write-once). Tudo o mais é DERIVADO — vale só o código de MAIOR `seq` do usuário (pedir outro substitui o anterior),
-- não usado, com `created_at` dentro do prazo (15 min) e `failed_attempts` abaixo do teto (N tentativas erradas esgotam o código).
--
-- O código NUNCA é guardado: `code_hmac` = HMAC-SHA256 de user:seq:hash da senha:e-mail de login:código, com segredo derivado da chave
-- de assinatura do setes-api (fora do banco e do repositório). Quem só LÊ o banco não reverte o código; trocar a senha ou o e-mail de
-- login invalida o código aberto por construção (o HMAC deixa de casar), sem nenhuma chamada de revogação.
--
-- Substitui a maquete `tb_user.activation_key` + `tb_user.updated_at` (o instante de emissão era o updated_at do USUÁRIO — o PUT do
-- admin reiniciava a janela do código aberto). `activation_key` fica sem consumidor no setes-api (limpa abaixo; sem DROP/ALTER).
--
-- PK por usuário (`tb_user_id`, `seq`): o `seq` é MAX+1 cunhado sob a trava da LINHA do usuário em tb_user (ela existe — regra 12),
-- nunca MAX+1 global (cunhadores de usuários diferentes não se esperariam — regras 7/11). Nada se apaga (§3.1): a história limita as
-- emissões por janela e o volume é limitado pelo próprio teto.
--
-- Re-executável. Aplicar em setes_central ANTES do setes-api que a lê (o boot confere: assertPasswordResetSchema).
-- =============================================================================

USE `setes_central`;

CREATE TABLE IF NOT EXISTS `tb_user_password_reset` (
  `tb_user_id`      int(11)     NOT NULL COMMENT 'Usuario dono da credencial',
  `seq`             int(11)     NOT NULL COMMENT 'N-esimo codigo do usuario: MAX+1 sob FOR UPDATE da linha tb_user; vale so o maior',
  `code_hmac`       char(64)    NOT NULL COMMENT 'HMAC-SHA256 hex de user:seq:hash da senha:e-mail de login:codigo (segredo fora do banco) - nunca o codigo',
  `failed_attempts` smallint(6) NOT NULL DEFAULT 0 COMMENT 'Tentativas erradas enquanto o codigo valia (para no teto)',
  `used_at`         datetime    DEFAULT NULL COMMENT 'Instante UTC do uso - write-once (NULL -> instante)',
  `created_at`      datetime    NOT NULL COMMENT 'Instante UTC da emissao = inicio do prazo',
  `updated_at`      datetime    DEFAULT NULL,
  `deleted`         char(1)     NOT NULL DEFAULT 'N',
  PRIMARY KEY (`tb_user_id`, `seq`),
  CONSTRAINT `fk_user_password_reset_to_user` FOREIGN KEY (`tb_user_id`) REFERENCES `tb_user` (`id`)
    ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `ck_user_password_reset_seq` CHECK (`seq` > 0),
  CONSTRAINT `ck_user_password_reset_code_hmac` CHECK (`code_hmac` COLLATE utf8mb4_bin REGEXP '^[0-9a-f]{64}$'),
  CONSTRAINT `ck_user_password_reset_failed_attempts` CHECK (`failed_attempts` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- `activation_key` fica SEM consumidor (sem DROP e sem ALTER — um MODIFY só para COMMENT pediria trava de METADADOS na tabela do
-- login, e uma transação ociosa em tb_user enfileiraria todo login atrás dele — gate socrático). Os códigos antigos em texto puro são
-- LIMPOS: nenhum leitor os aceita mais, e num rollback para o código anterior (que lia activation_key + updated_at) eles voltariam a
-- valer. Em 2026-10-18 havia 0 preenchidos. O grupo do sync não toca a coluna (Q4 de setes-sync/prompt_indexacao_usuario_firebird.md).
UPDATE `tb_user` SET `activation_key` = NULL WHERE `activation_key` IS NOT NULL;
