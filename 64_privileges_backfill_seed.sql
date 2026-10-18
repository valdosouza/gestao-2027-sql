-- =====================================================================
-- Seed 64: privilégios DEVIDOS de cada interface (backfill do catálogo) —
-- Infra-IA/prompts/prompt_privilegios_interfaces.md (Valdo, 2026-10-18).
--
-- Regra (D-GE19 + Q-G29): toda tela nasce com interface + privilégios no
-- catálogo. Achado: 31 das 40 interfaces sem privilégio nenhum e 5 só com
-- os de AÇÃO (sem VISUALIZAR) — usuário regular não recebia a tela no menu.
--   D-PV1  catálogo COMPLETO já: VISUALIZAR (6) + o CRUD do que a tela faz
--          (INSERIR 1, ALTERAR 2, EXCLUIR 3, IMPRIMIR 4) + as ações
--          (FATURAR 5, CANCELAR 7, DESCONTO 8, TRANSMITIR 9) — mesmo antes
--          de o código conferir o CRUD (a onda da D-PV2 é quem o torna efetivo).
--   D-PV3  telas do grupo Super também (A-PV3: V, I, A, E).
--   D-PV4  interfaces kind 'R' também (A-PV2: V + A; as ações do faturamento
--          seguem na tela do RAMO — Q-G22 —, nunca em `billing`).
--   A-PV4  telas do perfil admin (users, modules = V, I, A, E; establishment
--          = V, A) — a guarda segue a D-PV5 / D-GE20.
--   D-PV7  atos das telas de processo no catálogo existente (baixa = I,
--          estorno = E, registrar no banco = 9, PDF = 4, cheque = A/7, caixa
--          = I/A …).
--   C1     `settlements` × ALTERAR: o "trocar cobrança" (D21) estava escondido
--          até do admin — os botões do admin/super vêm do CATÁLOGO.
--
-- A lista abaixo é o ESTADO FINAL esperado (157 pares = 23 que já existiam,
-- dos seeds 51–59 e da tela Interfaces, + 134 novos). Por `i18n_key`, nunca
-- por id fixo de interface (lição do seed 40v1).
--
-- Idempotente (INSERT IGNORE pela PK interface × privilégio). Par removido
-- pelo Super na tela Interfaces (deleted='S') NÃO é revivido — é listado.
-- CONFERÊNCIA no fim: par esperado sem linha nenhuma (interface renomeada,
-- privilégio inexistente, INSERT ignorado em silêncio) FALHA o script com
-- "Table '...SEED64_FALHOU_par_esperado_ausente' doesn't exist".
--
-- Efeito ao aplicar: os menus do admin/super passam a carregar o catálogo
-- novo (só o C1 muda na tela hoje); o cadastro de privilégios do usuário
-- passa a oferecer as telas; nenhum acesso é retirado. As APIs fiscais não
-- leem este catálogo. Provado em schema descartável em 2026-10-18 (§9 do
-- prompt) antes de ir ao `setes_central`.
-- =====================================================================

USE `setes_central`;

DROP TEMPORARY TABLE IF EXISTS `tmp_seed64_expected`;
CREATE TEMPORARY TABLE `tmp_seed64_expected` (
  `k`   VARCHAR(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `pid` INT NOT NULL,
  PRIMARY KEY (`k`, `pid`)
) ENGINE=MEMORY;

INSERT INTO `tmp_seed64_expected` (`k`, `pid`) VALUES
-- Super (D-PV3 + A-PV3) — institutions: emitir a chave do sync = ALTERAR
('institutions', 1), ('institutions', 2), ('institutions', 3), ('institutions', 6),
('privileges', 1), ('privileges', 2), ('privileges', 3), ('privileges', 6),
('interfaces', 1), ('interfaces', 2), ('interfaces', 3), ('interfaces', 6),
('countries', 1), ('countries', 2), ('countries', 3), ('countries', 6),
('states', 1), ('states', 2), ('states', 3), ('states', 6),
('cities', 1), ('cities', 2), ('cities', 3), ('cities', 6),
('cfop', 1), ('cfop', 2), ('cfop', 3), ('cfop', 6),
('banks', 1), ('banks', 2), ('banks', 3), ('banks', 6),
('service-list', 1), ('service-list', 2), ('service-list', 3), ('service-list', 6),
-- Sistema: painéis (não incluem nem excluem) e telas do perfil admin (A-PV4)
('interface-fields', 2), ('interface-fields', 6),
('interface-configs', 2), ('interface-configs', 6),
('general-configs', 2), ('general-configs', 6),
('users', 1), ('users', 2), ('users', 3), ('users', 6),
('modules', 1), ('modules', 2), ('modules', 3), ('modules', 6),
('establishment', 2), ('establishment', 6),
-- Cadastros (D-PV1)
('customers', 1), ('customers', 2), ('customers', 3), ('customers', 6),
('collaborators', 1), ('collaborators', 2), ('collaborators', 3), ('collaborators', 6),
('salesmen', 1), ('salesmen', 2), ('salesmen', 3), ('salesmen', 6),
('carriers', 1), ('carriers', 2), ('carriers', 3), ('carriers', 6),
('providers', 1), ('providers', 2), ('providers', 3), ('providers', 6),
('categories', 1), ('categories', 2), ('categories', 3), ('categories', 6),
('financial-plans', 1), ('financial-plans', 2), ('financial-plans', 3), ('financial-plans', 6),
('contracts', 1), ('contracts', 2), ('contracts', 3), ('contracts', 6),
('tax-rules', 1), ('tax-rules', 2), ('tax-rules', 3), ('tax-rules', 6),
('price-lists', 1), ('price-lists', 2), ('price-lists', 3), ('price-lists', 6),
('services', 1), ('services', 2), ('services', 3), ('services', 6),
('service-tax-rules', 1), ('service-tax-rules', 2), ('service-tax-rules', 3), ('service-tax-rules', 6),
('payment-types', 1), ('payment-types', 2), ('payment-types', 3), ('payment-types', 6),
('settlement-rules', 1), ('settlement-rules', 2), ('settlement-rules', 3), ('settlement-rules', 6),
('bank-accounts', 1), ('bank-accounts', 2), ('bank-accounts', 3), ('bank-accounts', 6),
('bank-charge-agreements', 1), ('bank-charge-agreements', 2), ('bank-charge-agreements', 3), ('bank-charge-agreements', 6),
('bank-charge-agreements', 8),
-- Recursos kind 'R' (D-PV4 + A-PV2)
('partnerships', 2), ('partnerships', 6),
('billing', 2), ('billing', 6),
-- Telas de processo (D-PV1 + D-PV7; FATURAR/CANCELAR/TRANSMITIR/DESCONTO dos seeds 51–59)
('orders', 1), ('orders', 2), ('orders', 3), ('orders', 5), ('orders', 6), ('orders', 7), ('orders', 9),
('service-orders', 1), ('service-orders', 2), ('service-orders', 3), ('service-orders', 5),
('service-orders', 6), ('service-orders', 7), ('service-orders', 9),
('order-returns', 1), ('order-returns', 2), ('order-returns', 3), ('order-returns', 5), ('order-returns', 6),
-- settlements: baixa = I · estorno = E · trocar cobrança = A (C1) · desconto = 8
('settlements', 1), ('settlements', 2), ('settlements', 3), ('settlements', 6), ('settlements', 8),
-- bank-slips: emitir = I · liquidar = A · PDF = 4 · cancelar/estornar = 7 · registrar no banco = 9
('bank-slips', 1), ('bank-slips', 2), ('bank-slips', 4), ('bank-slips', 6), ('bank-slips', 7), ('bank-slips', 9),
-- checks: depositar/descontar/devolver/usar em pagamento = A · estornar = 7 (o cheque nasce no faturamento)
('checks', 2), ('checks', 6), ('checks', 7),
-- cashier: abrir = I · sangria/fechar = A
('cashier', 1), ('cashier', 2), ('cashier', 6);

INSERT IGNORE INTO `tb_interface_has_privilege`
  (`tb_interface_id`, `tb_privilege_id`, `active`, `created_at`, `updated_at`, `deleted`)
SELECT i.`id`, p.`id`, 'S', NOW(), NOW(), 'N'
  FROM `tmp_seed64_expected` e
  JOIN `tb_interface` i ON i.`i18n_key` = e.`k` AND i.`deleted` = 'N'
  JOIN `tb_privilege` p ON p.`id` = e.`pid` AND p.`deleted` = 'N';

-- Conferência 1 (informativa): pares que existem mas não estão vivos — removidos
-- pelo Super na tela Interfaces; o seed respeita e NÃO revive.
SELECT e.`k` AS `interface`, e.`pid` AS `privilege`, ip.`active`, ip.`deleted`
  FROM `tmp_seed64_expected` e
  JOIN `tb_interface` i ON i.`i18n_key` = e.`k` AND i.`deleted` = 'N'
  JOIN `tb_interface_has_privilege` ip ON ip.`tb_interface_id` = i.`id` AND ip.`tb_privilege_id` = e.`pid`
 WHERE ip.`deleted` <> 'N' OR ip.`active` IS NULL OR ip.`active` <> 'S';

-- Conferência 2 (informativa): interface do catálogo sem NENHUM privilégio vivo
-- (tela nova que nasceu sem o seed dela — D-GE19; a cerca da D-PV9 cobra no boot).
SELECT i.`id`, i.`i18n_key`
  FROM `tb_interface` i
 WHERE i.`deleted` = 'N'
   AND NOT EXISTS (SELECT 1 FROM `tb_interface_has_privilege` ip
                    WHERE ip.`tb_interface_id` = i.`id` AND ip.`deleted` = 'N' AND ip.`active` = 'S');

-- Conferência 3 (FALHA ALTO): par esperado sem linha nenhuma.
SET @seed64_missing := (
  SELECT COUNT(*)
    FROM `tmp_seed64_expected` e
    LEFT JOIN `tb_interface` i ON i.`i18n_key` = e.`k` AND i.`deleted` = 'N'
    LEFT JOIN `tb_interface_has_privilege` ip ON ip.`tb_interface_id` = i.`id` AND ip.`tb_privilege_id` = e.`pid`
   WHERE ip.`tb_interface_id` IS NULL
);
SET @seed64_check := IF(@seed64_missing = 0, 'DO 0', 'SELECT 1 FROM `SEED64_FALHOU_par_esperado_ausente`');
PREPARE seed64_check FROM @seed64_check;
EXECUTE seed64_check;
DEALLOCATE PREPARE seed64_check;

DROP TEMPORARY TABLE IF EXISTS `tmp_seed64_expected`;
