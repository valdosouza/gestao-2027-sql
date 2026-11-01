-- =====================================================================
-- Seed 72: retira do catálogo os 4 pares que NENHUM código confere — Infra-IA/prompts/prompt_privilegios_interfaces.md
-- (D-PV61, Valdo 2026-11-01 — Q-PV65; passo 4 do plano 10-21, costura A1 da auth-api).
--
--   D-PV51  o catálogo REGISTRADO é igual ao OPERADO ∪ regras ∪ reservados — par registrado que nenhuma
--           guarda (API, app ou API fiscal) confere é uma caixinha que não faz nada na tela de Permissões
--           do usuário. Com a costura A1 (veredito único pela vw_user_access), a cerca da D-PV9 achou 4:
--             billing       × VISUALIZAR  'R' (não é tela do menu); quem fatura é decidido pelo FATURAR da
--                                         tela do ramo (pedidos, OS, devoluções)
--             billing       × ALTERAR     registrado pela A-PV2 para editar as configs do faturamento; a
--                                         D-PV25 passou esse ato ao CONFIGURAR (seed 68)
--             establishment × ALTERAR     tela do perfil admin (adminGuard, D-PV5) — não se concede por usuário
--             users         × EXCLUIR     a exclusão de usuário morreu (D-PV19/D-UC1: só se inativa o vínculo)
--   D-PV61  os 4 saem por SOFT DELETE (PADROES §3.1 — nada se apaga fisicamente). Nada muda no acesso: a
--           vw_user_access só lê par vivo, e em 2026-11-01 nenhum usuário tinha concessão nessas três telas
--           (setes_setes, o único schema de cliente com `tb_user_has_privilege`). Concessão antiga que exista
--           noutro schema fica como está (D-PV60: sem script nas concessões) — morta pela view.
--           Se um dia um código passar a conferir um desses pares, o par volta na MESMA entrega do código
--           (regra da D-PV9: par novo consumido = lista + seed antes do app) — e, pela D-PV64, com a LISTA de quem volta a
--           ter o verbo (as concessões antigas reativam na volta), mostrada antes do "vai".
--
-- Por `i18n_key`, nunca por id fixo de interface (lição do seed 40v1). Ids de privilégio fixos do catálogo
-- (2 = ALTERAR, 3 = EXCLUIR, 6 = VISUALIZAR). Idempotente / RE-EXECUTÁVEL (UPDATE só do que ainda está vivo;
-- não revive nada). CONFERÊNCIA no fim: qualquer dos 4 ainda vivo FALHA o script com
-- "Table '...SEED72_FALHOU_...' doesn't exist" (molde do seed 64).
--
-- ORDEM: depois do 64 (que registrou os pares) e do 68 (o CONFIGURAR do billing nasce lá); ANTES do
-- setes-api desta onda — o boot do setes-api grita o alarme da D-PV9 e o `npm run check:privileges` (D-PV16)
-- recusa enquanto os 4 estiverem vivos. Provado em schema descartável em 2026-11-01 (§14 do prompt) —
-- NUNCA aplicado em `setes_central` por esta sessão (só com o "vai" da janela).
-- =====================================================================
USE `setes_central`;

DROP TEMPORARY TABLE IF EXISTS `tmp_seed72_retired`;
CREATE TEMPORARY TABLE `tmp_seed72_retired` (
  `k`   VARCHAR(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `pid` INT NOT NULL,
  PRIMARY KEY (`k`, `pid`)
) ENGINE=MEMORY;

INSERT INTO `tmp_seed72_retired` (`k`, `pid`) VALUES
('billing', 6), ('billing', 2), ('establishment', 2), ('users', 3);

-- (1) a retirada — soft delete, só do que ainda está vivo
UPDATE `tb_interface_has_privilege` ihp
  JOIN `tb_interface` i ON i.`id` = ihp.`tb_interface_id`
  JOIN `tmp_seed72_retired` r ON r.`k` = i.`i18n_key` AND r.`pid` = ihp.`tb_privilege_id`
   SET ihp.`active` = 'N', ihp.`deleted` = 'S', ihp.`updated_at` = NOW()
 WHERE ihp.`deleted` <> 'S' OR ihp.`active` IS NULL OR ihp.`active` <> 'N';

-- (2) conferência 1: o que ficou de cada par (linha ausente = o par nunca existiu aqui — inofensivo)
SELECT r.`k` AS `interface`, r.`pid` AS `privilege`, ihp.`active`, ihp.`deleted`
  FROM `tmp_seed72_retired` r
  LEFT JOIN `tb_interface` i ON i.`i18n_key` = r.`k`
  LEFT JOIN `tb_interface_has_privilege` ihp ON ihp.`tb_interface_id` = i.`id` AND ihp.`tb_privilege_id` = r.`pid`;

-- (3) conferência 2: nenhum dos 4 vivo — senão o script FALHA
SET @seed72_alive := (
  SELECT COUNT(*)
    FROM `tb_interface_has_privilege` ihp
    JOIN `tb_interface` i ON i.`id` = ihp.`tb_interface_id`
    JOIN `tmp_seed72_retired` r ON r.`k` = i.`i18n_key` AND r.`pid` = ihp.`tb_privilege_id`
   WHERE ihp.`deleted` = 'N' OR ihp.`active` = 'S'
);
SET @seed72_check := IF(@seed72_alive = 0,
  'DO 0', 'SELECT 1 FROM `SEED72_FALHOU_par_sem_consumidor_ainda_vivo`');
PREPARE seed72_check FROM @seed72_check;
EXECUTE seed72_check;
DEALLOCATE PREPARE seed72_check;

DROP TEMPORARY TABLE IF EXISTS `tmp_seed72_retired`;
