-- =====================================================================
-- Seed 68: os verbos CONFIGURAR (11) e CONSULTAR (12) — Infra-IA/prompts/prompt_privilegios_interfaces.md
-- (Valdo, 2026-10-20 — rodada "uma pergunta por vez"; execução no §11.10).
--
--   D-PV25  nasce CONFIGURAR (id 11): "pode ajustar o comportamento desta tela" — gravar o valor da
--           INSTITUTION ('I') de uma config e o required/caption/mask de um campo da tela X exige
--           CONFIGURAR em X, por qualquer caminho (engrenagem ou painel solto). O par (interface ×
--           CONFIGURAR) existe para TODA interface com config ou campo no catálogo
--           (tb_interface_has_config / tb_interface_has_field) — DERIVADO do catálogo abaixo — e para
--           `general-configs` ("Configurações Gerais" = CONFIGURAR nela, regra 2 da D-PV25).
--   D-PV26  o ALTERAR dos painéis `interface-configs`/`interface-fields` perde o consumidor (o valor
--           'I' é de quem tem CONFIGURAR na tela ALVO) — sai do catálogo deles (regra C1 da D-PV9: par
--           sem consumidor é defeito). O ALTERAR de `general-configs` perde o consumidor pelo mesmo
--           motivo (a exceção da A-PV8 foi substituída pelo CONFIGURAR nela) e sai também.
--   D-PV40  nasce CONSULTAR (id 12): perguntar ao TERCEIRO (banco, fisco) a situação de um documento
--           sem mudar estado nele — boleto `refresh`; nfse-api `refresh` e a passada do rodízio pela
--           interface do RAMO. Pares: bank-slips, orders, service-orders. `order-returns` × CONSULTAR fica FORA
--           por decisão (A-PV12, ratificada 2026-10-20: devolução é NF-e — a API da NFS-e não consulta por ela e a
--           tela não tem o botão; a guarda pelo ramo a consome, marcada `absentBy` na lista única). Corrigido no
--           passo 4 do plano 10-21 (2026-10-31): a 1ª versão do seed inseria o par e contrariava a A-PV12.
--   Ids 11 e 12 = os próximos livres depois de CATALOGAR (10, seed 66 da branch `merchandise`).
--
-- Por `i18n_key`, nunca por id fixo de interface (lição do seed 40v1). Idempotente / RE-EXECUTÁVEL
-- (INSERT IGNORE pela PK; a remoção do ALTERAR é soft e não revive). Par CONFIGURAR removido pelo
-- Super na tela Interfaces (deleted='S') NÃO é revivido — é listado na conferência 1.
-- CONFERÊNCIA no fim: par esperado sem linha nenhuma, privilégio ausente ou ALTERAR ainda vivo nos
-- painéis FALHA o script com "Table '...SEED68_FALHOU_...' doesn't exist" (molde do seed 64).
--
-- ORDEM: depois do 64 (pares devidos), do 65 (tela institution-interfaces — ganha CONFIGURAR pelo
-- page_size dela) e do 66 (CATALOGAR = 10); ANTES do setes-api/app desta onda (o código consome os
-- pares; a cerca da D-PV9 cobra). Provado em schema descartável em 2026-10-20 (§11.10 do prompt)
-- — NUNCA aplicado em `setes_central` por esta sessão (só com o "vai").
-- =====================================================================

USE `setes_central`;

-- (1) os verbos
INSERT IGNORE INTO `tb_privilege` (`id`, `description`, `created_at`, `updated_at`, `deleted`)
VALUES (11, 'CONFIGURAR', NOW(), NOW(), 'N'),
       (12, 'CONSULTAR',  NOW(), NOW(), 'N');

-- (2) os pares esperados, DERIVADOS do catálogo (+ os fixos), numa tabela temporária — a conferência lê a mesma lista
DROP TEMPORARY TABLE IF EXISTS `tmp_seed68_expected`;
CREATE TEMPORARY TABLE `tmp_seed68_expected` (
  `k`   VARCHAR(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `pid` INT NOT NULL,
  PRIMARY KEY (`k`, `pid`)
) ENGINE=MEMORY;

-- CONFIGURAR: toda interface viva com config OU campo no catálogo (D-PV25 regra 5)
INSERT IGNORE INTO `tmp_seed68_expected` (`k`, `pid`)
SELECT i.`i18n_key`, 11
  FROM `tb_interface` i
 WHERE i.`deleted` = 'N' AND i.`i18n_key` IS NOT NULL
   AND (EXISTS (SELECT 1 FROM `tb_interface_has_config` c WHERE c.`tb_interface_id` = i.`id` AND c.`deleted` = 'N')
     OR EXISTS (SELECT 1 FROM `tb_interface_has_field`  f WHERE f.`tb_interface_id` = i.`id` AND f.`deleted` = 'N'));

-- CONFIGURAR em "Configurações Gerais" (D-PV25 regra 2 — a interface dona das configs sem tela própria)
INSERT IGNORE INTO `tmp_seed68_expected` (`k`, `pid`) VALUES ('general-configs', 11);

-- CONSULTAR (D-PV40): o banco (boletos) e o fisco pela interface do RAMO
INSERT IGNORE INTO `tmp_seed68_expected` (`k`, `pid`) VALUES
('bank-slips', 12), ('orders', 12), ('service-orders', 12);

INSERT IGNORE INTO `tb_interface_has_privilege`
  (`tb_interface_id`, `tb_privilege_id`, `active`, `created_at`, `updated_at`, `deleted`)
SELECT i.`id`, p.`id`, 'S', NOW(), NOW(), 'N'
  FROM `tmp_seed68_expected` e
  JOIN `tb_interface` i ON i.`i18n_key` = e.`k` AND i.`deleted` = 'N'
  JOIN `tb_privilege` p ON p.`id` = e.`pid` AND p.`deleted` = 'N';

-- (3) o ALTERAR dos painéis perde o consumidor (D-PV26 + C1) — remoção SOFT, como a tela Interfaces faz
UPDATE `tb_interface_has_privilege` ihp
  JOIN `tb_interface` i ON i.`id` = ihp.`tb_interface_id`
   SET ihp.`active` = 'N', ihp.`deleted` = 'S', ihp.`updated_at` = NOW()
 WHERE i.`i18n_key` IN ('interface-configs', 'interface-fields', 'general-configs')
   AND ihp.`tb_privilege_id` = 2
   AND (ihp.`deleted` <> 'S' OR ihp.`active` <> 'N');

-- Conferência 1 (informativa): par esperado que existe mas não está vivo — removido pelo Super; o seed respeita e NÃO revive.
SELECT e.`k` AS `interface`, e.`pid` AS `privilege`, ihp.`active`, ihp.`deleted`
  FROM `tmp_seed68_expected` e
  JOIN `tb_interface` i ON i.`i18n_key` = e.`k` AND i.`deleted` = 'N'
  JOIN `tb_interface_has_privilege` ihp ON ihp.`tb_interface_id` = i.`id` AND ihp.`tb_privilege_id` = e.`pid`
 WHERE ihp.`deleted` <> 'N' OR ihp.`active` IS NULL OR ihp.`active` <> 'S';

-- Conferência 2 (informativa): os pares CONFIGURAR vivos depois do seed (o número a registrar no prompt)
SELECT COUNT(*) AS `configurar_pairs`
  FROM `tb_interface_has_privilege` ihp
 WHERE ihp.`tb_privilege_id` = 11 AND ihp.`deleted` = 'N' AND ihp.`active` = 'S';

-- Conferência 3 (FALHA ALTO): privilégio ausente, par esperado sem linha nenhuma, ou ALTERAR ainda vivo num painel.
-- pelo NOME exato, não só pelo id (gate adversarial do delta da costura A1, L4: o INSERT IGNORE cala o id 11/12 ocupado por outro verbo)
SET @seed68_privs := (SELECT COUNT(*) FROM `tb_privilege` WHERE `deleted` = 'N'
  AND ((`id` = 11 AND BINARY `description` = 'CONFIGURAR') OR (`id` = 12 AND BINARY `description` = 'CONSULTAR')));
SET @seed68_missing := (
  SELECT COUNT(*)
    FROM `tmp_seed68_expected` e
    LEFT JOIN `tb_interface` i ON i.`i18n_key` = e.`k` AND i.`deleted` = 'N'
    LEFT JOIN `tb_interface_has_privilege` ihp ON ihp.`tb_interface_id` = i.`id` AND ihp.`tb_privilege_id` = e.`pid`
   WHERE ihp.`tb_interface_id` IS NULL
);
SET @seed68_alter_alive := (
  SELECT COUNT(*)
    FROM `tb_interface_has_privilege` ihp
    JOIN `tb_interface` i ON i.`id` = ihp.`tb_interface_id`
   WHERE i.`i18n_key` IN ('interface-configs', 'interface-fields', 'general-configs')
     AND ihp.`tb_privilege_id` = 2 AND ihp.`deleted` = 'N' AND ihp.`active` = 'S'
);
SET @seed68_check := IF(@seed68_privs = 2 AND @seed68_missing = 0 AND @seed68_alter_alive = 0,
  'DO 0', 'SELECT 1 FROM `SEED68_FALHOU_privilegio_par_ausente_ou_alterar_vivo`');
PREPARE seed68_check FROM @seed68_check;
EXECUTE seed68_check;
DEALLOCATE PREPARE seed68_check;

DROP TEMPORARY TABLE IF EXISTS `tmp_seed68_expected`;
