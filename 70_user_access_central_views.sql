-- =============================================================================
-- 70 — VIEWs CENTRAIS do veredito de acesso: setes_central.vw_user_link + setes_central.vw_interface_catalog
-- Escopo: setes
-- Origem: costura A1 da frente auth-api (D-AU3/D-AU6/D-AU8/D-AU12, Valdo 2026-10-31 — Infra-IA/prompts/prompt_frente_auth_api.md;
--         parecer do guardião no §7 de lá); PADROES_BANCO §6/§11 (regras 3 e 11)/§12; D-UC2/D-UC9; D-PV11/D-PV37; A-PV1/D-PV24.
--
-- O conceito: o veredito "o usuário U pode exercer o verbo V na interface I do estabelecimento X" é a COMPOSIÇÃO de três peças, cada uma
-- com o seu fato gerador — o VÍNCULO vivo com o perfil (ato do admin), o ALCANCE da interface (venda/liberação) e a CONCESSÃO do verbo
-- (ato de quem concede). Vira uma PILHA de views fundíveis em que cada predicado aparece UMA vez:
--   setes_central.vw_user_link          (este script) vínculo VIVO com o perfil — credencial, vínculo e estabelecimento ativos (D-UC9)
--   setes_central.vw_interface_catalog  (este script) interface viva + o modo de concessão (delegável do Super — D-PV11)
--   <schema>.vw_user_reach              (migration 075 do setes-api) interface ao alcance do usuário no estabelecimento
--   <schema>.vw_user_access             (migration 075 do setes-api) verbo PERMITIDO — presença = permissão (D-AU3)
-- O ÚNICO leitor é a biblioteca `fiscal-api/access` (setes-api, nfse-api e o menu); o vínculo e o catálogo são dados CENTRAIS, a licença e
-- a concessão moram no schema do cliente — por isso o veredito só existe por schema (uma view central exigiria UNION entre schemas).
-- A vw_user_link é também a fronteira do GRANT (D-AU12): o usuário das APIs fiscais confere a sessão viva SEM ler tb_user (DEFINER).
--
-- Regras da casa aplicadas:
--  - FUNDÍVEL (PADROES §11 regra 3): um SELECT por view, sem UNION/DISTINCT/GROUP BY/LIMIT/subconsulta na lista; o LIMIT fica no leitor.
--  - Coluna DERIVADA de literal com COLLATE utf8mb4_bin (regra 3): `profile`, `vendor`, `interface_key`, `delegable` — o leitor de outro
--    serviço compara exato em qualquer colação de conexão (erro 1267 nunca), e 'Admin' NÃO vira admin (o JS compara exato).
--  - `kind` comparado em BINÁRIO: a vw_user_link é o ÚNICO intérprete de `tb_institution_has_user.kind` (perfil × origem 'SYNC' →
--    qualquer valor fora de super/admin = 'user'); 'super' só vale na institution da Setes (o `resolveRole` do login morre aqui).
--  - Literais com dono no código, amarrados por CERCA (teste ao vivo do setes-api confere view × constante): `1` = SETES_INSTITUTION_ID
--    (D-PV37 — a troca pelo predicado do grupo, onda 1, é um ato só); 'institution-interfaces' = DELEGABLE_SUPER_INTERFACES (D-PV11 (d)).
--    Na A2 o modo de concessão vira DADO do registro (dono = auth-api — D-AU2).
--  - Ativo ESTRITO (`active = 'S'`): todo escritor grava 'S'/'N' (conferido em 2026-10-31: nenhum NULL em tb_institution_has_user,
--    tb_interface_has_privilege, tb_institution_has_interface, tb_user_has_privilege).
--  Conhecimento negativo: (a) `DATABASE()` numa view devolve o banco da CONEXÃO, nunca o da view — não serve para escopar; (b) nunca
--  "verbo exige VISUALIZAR" aqui (a invariante é da ESCRITA — D-PV60); (c) nunca DISTINCT para "limpar" duplicata; (d) apagar o usuário
--  DEFINIDOR quebra a view (erro 1449) — recriar as views quando o dono mudar (A2).
--
-- D-EA7 (Valdo 2026-10-31 — `prompt_endurecer_autenticacao.md`; parecer do guardião): o FATO "a senha que vale hoje foi definida no
-- instante T" — `tb_user.password_set_at DATETIME NULL` (UTC, ao segundo, a precisão do `iat`), AO LADO do hash, gravado SÓ pela peça
-- "definir a senha" do setes-api (criação da credencial, 1ª senha da A-PV23, troca pelo código, script do Super) com o relógio de quem
-- assina o token; nunca pelo salvar do cadastro nem pela migração do hash (D-EA9); sem `ON UPDATE` (seria o `updated_at` recusado voltando).
-- NULL = senha definida antes da regra (sem revogação — o TTL de 24 h fecha); SEM backfill (um T carimbado no deploy seria fato falso).
-- A `vw_user_link` expõe a coluna CRUA (nunca `UNIX_TIMESTAMP` — depende do `time_zone` de quem lê); a biblioteca compara na MESMA leitura
-- da sessão: `password_set_at <= iat` vale (iat = T vale; iat < T = 401 SESSION_REVOKED). Vai COM o hash para `tb_user_credential` na A2
-- (D-AU5). O setes-sync segue criando `tb_user` sem a coluna (NULL — sem senha, sem token). `ADD COLUMN IF NOT EXISTS` é só do MariaDB
-- (a ida para o MySQL 8 — F3 — revê, como no PADROES §11 regra 11 (c)).
--
-- Re-executável (ADD COLUMN IF NOT EXISTS + CREATE OR REPLACE). Rodar com `SET NAMES utf8mb4` (numa sessão latin1 o COLLATE utf8mb4_bin dá erro 1253) e com o
-- usuário DONO de sempre (o DEFINER é quem cria). Aplicar em setes_central ANTES do setes-api com a migration 075 (as views por schema
-- leem estas) — o boot do setes-api confere as duas pelo NOME (assertAccessViews).
-- =============================================================================
SET NAMES utf8mb4;

ALTER TABLE `setes_central`.`tb_user`
  ADD COLUMN IF NOT EXISTS `password_set_at` DATETIME NULL DEFAULT NULL AFTER `password`;

CREATE OR REPLACE SQL SECURITY DEFINER VIEW `setes_central`.`vw_user_link` AS
SELECT ihu.`tb_user_id`,
       ihu.`tb_institution_id`,
       i.`schema_name`,
       u.`password_set_at`,
       (CASE
          WHEN ihu.`kind` COLLATE utf8mb4_bin = 'super' AND ihu.`tb_institution_id` = 1 THEN 'super'   -- 1 = SETES_INSTITUTION_ID (cerca)
          WHEN ihu.`kind` COLLATE utf8mb4_bin = 'admin' THEN 'admin'
          ELSE 'user'
        END) COLLATE utf8mb4_bin AS `profile`,
       (CASE WHEN ihu.`tb_institution_id` = 1 THEN 'S' ELSE 'N' END) COLLATE utf8mb4_bin AS `vendor`
  FROM `setes_central`.`tb_institution_has_user` ihu
  JOIN `setes_central`.`tb_user` u
    ON u.`id` = ihu.`tb_user_id` AND u.`active` = 'S' AND u.`deleted` = 'N'
  JOIN `setes_central`.`tb_institution` i
    ON i.`id` = ihu.`tb_institution_id` AND i.`active` = 'S' AND i.`deleted` = 'N'
 WHERE ihu.`active` = 'S' AND ihu.`deleted` = 'N';

CREATE OR REPLACE SQL SECURITY DEFINER VIEW `setes_central`.`vw_interface_catalog` AS
SELECT i.`id` AS `tb_interface_id`,
       i.`i18n_key` COLLATE utf8mb4_bin AS `interface_key`,
       (CASE WHEN i.`i18n_key` COLLATE utf8mb4_bin IN ('institution-interfaces')   -- = DELEGABLE_SUPER_INTERFACES (cerca)
             THEN 'S' ELSE 'N' END) COLLATE utf8mb4_bin AS `delegable`
  FROM `setes_central`.`tb_interface` i
 WHERE i.`deleted` = 'N';
