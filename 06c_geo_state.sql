-- =====================================================================
-- Setes API — setes-app Fase 1: Seed geo — tb_state
-- Fonte: seed/tb_state.sql (phpMyAdmin dump adaptado)
-- INSERT IGNORE: idempotente. Executar após 06b.
-- =====================================================================

USE `setes_central`;
INSERT IGNORE INTO `tb_state` (`id`, `tb_country_id`, `abbreviation`, `name`) VALUES
(0, 1058, 'NI', 'Ifnformar UF'),
(11, 1058, 'RO', 'Rondonia'),
(12, 1058, 'AC', 'Acre'),
(13, 1058, 'AM', 'Amazonas'),
(14, 1058, 'RR', 'Roraima'),
(15, 1058, 'PA', 'Para'),
(16, 1058, 'AP', 'Amapa'),
(17, 1058, 'TO', 'Tocantins'),
(21, 1058, 'MA', 'Maranhão'),
(22, 1058, 'PI', 'Piauí'),
(23, 1058, 'CE', 'Ceará'),
(24, 1058, 'RN', 'Rio Grande do Norte'),
(25, 1058, 'PB', 'Paraiba'),
(26, 1058, 'PE', 'Pernambuco'),
(27, 1058, 'AL', 'Alagoas'),
(28, 1058, 'SE', 'Sergipe'),
(29, 1058, 'BA', 'Bahia'),
(31, 1058, 'MG', 'Minas Gerais'),
(32, 1058, 'ES', 'Espirito Santo'),
(33, 1058, 'RJ', 'Rio de Janeiro'),
(35, 1058, 'SP', 'São Paulo'),
(41, 1058, 'PR', 'Paraná'),
(42, 1058, 'SC', 'Santa Catarina'),
(43, 1058, 'RS', 'Rio Grande do Sul'),
(50, 1058, 'MS', 'Mato Grosso do Sul'),
(51, 1058, 'MT', 'Mato Grosso'),
(52, 1058, 'GO', 'Goias'),
(53, 1058, 'DF', 'Distrito Federal'),
(54, 1058, 'EX', 'Exterior');
COMMIT;