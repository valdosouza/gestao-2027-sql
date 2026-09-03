-- =====================================================================
-- Seed 43: Lista de Serviços (LC 116/2003 + LC 157/2016) + interface Super
-- 'service-list' — prompt_regra_tributacao_servico.md (D10/D12, 2026-09-02).
--
-- tb_service_list = referência fiscal CENTRAL (fato do mundo, como tb_cfop):
-- id = o PRÓPRIO item da lista ('1.01'); local_incidence 'P' = município
-- do PRESTADOR (regra geral, art. 3º caput) / 'E' = município da EXECUÇÃO
-- (exceções do art. 3º: 3.05, 7.02/7.04/7.05/7.09-7.12/7.16-7.19, 11.01/
-- 11.02/11.04, item 12 exceto 12.13, item 16, 17.05/17.10, item 20).
-- Itens 4.22/4.23/5.09/15.01/15.09 (LC 157 — "domicílio do tomador") ficam
-- 'P': a regra foi suspensa pelo STF (ADI 5835, 2023). Descrições
-- RESUMIDAS (o módulo Super permite corrigir sem migration — D10).
-- Idempotente (CREATE IF NOT EXISTS / ON DUPLICATE / NOT EXISTS).
-- DDL canônico: sql/01 (seção Referência fiscal). Executar após o 42.
-- =====================================================================

USE `setes_central`;

CREATE TABLE IF NOT EXISTS `tb_service_list` (
  `id`              varchar(10) NOT NULL,
  `description`     varchar(255) NOT NULL,
  `local_incidence` char(1) NOT NULL DEFAULT 'P',
  `active`          char(1) NOT NULL DEFAULT 'S',
  `created_at`      datetime DEFAULT NULL,
  `updated_at`      datetime DEFAULT NULL,
  `deleted`         char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Lista de Serviços da LC 116/2003 (+ LC 157/2016) — referência fiscal
-- CENTRAL (fato do mundo, como tb_cfop). id = o PRÓPRIO item ('1.01').
-- local_incidence: 'P' = município do PRESTADOR (regra geral, art. 3º) /
-- 'E' = município da EXECUÇÃO (exceções do art. 3º — construção, limpeza,
-- vigilância, diversões, transporte, portos...). Prompt
-- prompt_regra_tributacao_servico.md (D10/D12, 2026-09-02).

INSERT INTO `tb_service_list` (`id`, `description`, `local_incidence`, `active`, `created_at`, `updated_at`, `deleted`) VALUES
  ('1.01', 'Análise e desenvolvimento de sistemas', 'P', 'S', NOW(), NOW(), 'N'),
  ('1.02', 'Programação', 'P', 'S', NOW(), NOW(), 'N'),
  ('1.03', 'Processamento, armazenamento ou hospedagem de dados, textos, imagens, vídeos, páginas eletrônicas, aplicativos e sistemas de informação', 'P', 'S', NOW(), NOW(), 'N'),
  ('1.04', 'Elaboração de programas de computadores, inclusive de jogos eletrônicos', 'P', 'S', NOW(), NOW(), 'N'),
  ('1.05', 'Licenciamento ou cessão de direito de uso de programas de computação', 'P', 'S', NOW(), NOW(), 'N'),
  ('1.06', 'Assessoria e consultoria em informática', 'P', 'S', NOW(), NOW(), 'N'),
  ('1.07', 'Suporte técnico em informática, inclusive instalação, configuração e manutenção de programas e bancos de dados', 'P', 'S', NOW(), NOW(), 'N'),
  ('1.08', 'Planejamento, confecção, manutenção e atualização de páginas eletrônicas', 'P', 'S', NOW(), NOW(), 'N'),
  ('1.09', 'Disponibilização, sem cessão definitiva, de conteúdos de áudio, vídeo, imagem e texto por meio da internet', 'P', 'S', NOW(), NOW(), 'N'),
  ('2.01', 'Serviços de pesquisas e desenvolvimento de qualquer natureza', 'P', 'S', NOW(), NOW(), 'N'),
  ('3.02', 'Cessão de direito de uso de marcas e de sinais de propaganda', 'P', 'S', NOW(), NOW(), 'N'),
  ('3.03', 'Exploração de salões de festas, centros de convenções, escritórios virtuais, stands, quadras esportivas, estádios, ginásios, auditórios, casas de espetáculos, parques de diversões, canchas e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('3.04', 'Locação, sublocação, arrendamento, direito de passagem ou permissão de uso de ferrovia, rodovia, postes, cabos, dutos e condutos de qualquer natureza', 'P', 'S', NOW(), NOW(), 'N'),
  ('3.05', 'Cessão de andaimes, palcos, coberturas e outras estruturas de uso temporário', 'E', 'S', NOW(), NOW(), 'N'),
  ('4.01', 'Medicina e biomedicina', 'P', 'S', NOW(), NOW(), 'N'),
  ('4.02', 'Análises clínicas, patologia, eletricidade médica, radioterapia, quimioterapia, ultra-sonografia, ressonância magnética, radiologia, tomografia e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('4.03', 'Hospitais, clínicas, laboratórios, sanatórios, manicômios, casas de saúde, prontos-socorros, ambulatórios e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('4.04', 'Instrumentação cirúrgica', 'P', 'S', NOW(), NOW(), 'N'),
  ('4.05', 'Acupuntura', 'P', 'S', NOW(), NOW(), 'N'),
  ('4.06', 'Enfermagem, inclusive serviços auxiliares', 'P', 'S', NOW(), NOW(), 'N'),
  ('4.07', 'Serviços farmacêuticos', 'P', 'S', NOW(), NOW(), 'N'),
  ('4.08', 'Terapia ocupacional, fisioterapia e fonoaudiologia', 'P', 'S', NOW(), NOW(), 'N'),
  ('4.09', 'Terapias de qualquer espécie destinadas ao tratamento físico, orgânico e mental', 'P', 'S', NOW(), NOW(), 'N'),
  ('4.10', 'Nutrição', 'P', 'S', NOW(), NOW(), 'N'),
  ('4.11', 'Obstetrícia', 'P', 'S', NOW(), NOW(), 'N'),
  ('4.12', 'Odontologia', 'P', 'S', NOW(), NOW(), 'N'),
  ('4.13', 'Ortóptica', 'P', 'S', NOW(), NOW(), 'N'),
  ('4.14', 'Próteses sob encomenda', 'P', 'S', NOW(), NOW(), 'N'),
  ('4.15', 'Psicanálise', 'P', 'S', NOW(), NOW(), 'N'),
  ('4.16', 'Psicologia', 'P', 'S', NOW(), NOW(), 'N'),
  ('4.17', 'Casas de repouso e de recuperação, creches, asilos e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('4.18', 'Inseminação artificial, fertilização in vitro e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('4.19', 'Bancos de sangue, leite, pele, olhos, óvulos, sêmen e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('4.20', 'Coleta de sangue, leite, tecidos, sêmen, órgãos e materiais biológicos de qualquer espécie', 'P', 'S', NOW(), NOW(), 'N'),
  ('4.21', 'Unidade de atendimento, assistência ou tratamento móvel e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('4.22', 'Planos de medicina de grupo ou individual e convênios para prestação de assistência médica, hospitalar, odontológica e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('4.23', 'Outros planos de saúde que se cumpram através de serviços de terceiros contratados, credenciados, cooperados ou apenas pagos pelo operador do plano', 'P', 'S', NOW(), NOW(), 'N'),
  ('5.01', 'Medicina veterinária e zootecnia', 'P', 'S', NOW(), NOW(), 'N'),
  ('5.02', 'Hospitais, clínicas, ambulatórios, prontos-socorros e congêneres, na área veterinária', 'P', 'S', NOW(), NOW(), 'N'),
  ('5.03', 'Laboratórios de análise na área veterinária', 'P', 'S', NOW(), NOW(), 'N'),
  ('5.04', 'Inseminação artificial, fertilização in vitro e congêneres (veterinária)', 'P', 'S', NOW(), NOW(), 'N'),
  ('5.05', 'Bancos de sangue e de órgãos e congêneres (veterinária)', 'P', 'S', NOW(), NOW(), 'N'),
  ('5.06', 'Coleta de sangue, leite, tecidos, sêmen, órgãos e materiais biológicos de qualquer espécie (veterinária)', 'P', 'S', NOW(), NOW(), 'N'),
  ('5.07', 'Unidade de atendimento, assistência ou tratamento móvel e congêneres (veterinária)', 'P', 'S', NOW(), NOW(), 'N'),
  ('5.08', 'Guarda, tratamento, amestramento, embelezamento, alojamento e congêneres (animais)', 'P', 'S', NOW(), NOW(), 'N'),
  ('5.09', 'Planos de atendimento e assistência médico-veterinária', 'P', 'S', NOW(), NOW(), 'N'),
  ('6.01', 'Barbearia, cabeleireiros, manicuros, pedicuros e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('6.02', 'Esteticistas, tratamento de pele, depilação e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('6.03', 'Banhos, duchas, sauna, massagens e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('6.04', 'Ginástica, dança, esportes, natação, artes marciais e demais atividades físicas', 'P', 'S', NOW(), NOW(), 'N'),
  ('6.05', 'Centros de emagrecimento, spa e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('6.06', 'Aplicação de tatuagens, piercings e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('7.01', 'Engenharia, agronomia, agrimensura, arquitetura, geologia, urbanismo, paisagismo e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('7.02', 'Execução, por administração, empreitada ou subempreitada, de obras de construção civil, hidráulica ou elétrica e de outras obras semelhantes', 'E', 'S', NOW(), NOW(), 'N'),
  ('7.03', 'Elaboração de planos diretores, estudos de viabilidade, estudos organizacionais e outros, relacionados com obras e serviços de engenharia', 'P', 'S', NOW(), NOW(), 'N'),
  ('7.04', 'Demolição', 'E', 'S', NOW(), NOW(), 'N'),
  ('7.05', 'Reparação, conservação e reforma de edifícios, estradas, pontes, portos e congêneres', 'E', 'S', NOW(), NOW(), 'N'),
  ('7.06', 'Colocação e instalação de tapetes, carpetes, assoalhos, cortinas, revestimentos de parede, vidros, divisórias, placas de gesso e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('7.07', 'Recuperação, raspagem, polimento e lustração de pisos e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('7.08', 'Calafetação', 'P', 'S', NOW(), NOW(), 'N'),
  ('7.09', 'Varrição, coleta, remoção, incineração, tratamento, reciclagem, separação e destinação final de lixo, rejeitos e outros resíduos quaisquer', 'E', 'S', NOW(), NOW(), 'N'),
  ('7.10', 'Limpeza, manutenção e conservação de vias e logradouros públicos, imóveis, chaminés, piscinas, parques, jardins e congêneres', 'E', 'S', NOW(), NOW(), 'N'),
  ('7.11', 'Decoração e jardinagem, inclusive corte e poda de árvores', 'E', 'S', NOW(), NOW(), 'N'),
  ('7.12', 'Controle e tratamento de efluentes de qualquer natureza e de agentes físicos, químicos e biológicos', 'E', 'S', NOW(), NOW(), 'N'),
  ('7.13', 'Dedetização, desinfecção, desinsetização, imunização, higienização, desratização, pulverização e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('7.16', 'Florestamento, reflorestamento, semeadura, adubação, reparação de solo, plantio, silagem, colheita, corte e descascamento de árvores, silvicultura, exploração florestal e congêneres', 'E', 'S', NOW(), NOW(), 'N'),
  ('7.17', 'Escoramento, contenção de encostas e serviços congêneres', 'E', 'S', NOW(), NOW(), 'N'),
  ('7.18', 'Limpeza e dragagem de rios, portos, canais, baías, lagos, lagoas, represas, açudes e congêneres', 'E', 'S', NOW(), NOW(), 'N'),
  ('7.19', 'Acompanhamento e fiscalização da execução de obras de engenharia, arquitetura e urbanismo', 'E', 'S', NOW(), NOW(), 'N'),
  ('7.20', 'Aerofotogrametria, mapeamento e topografia', 'P', 'S', NOW(), NOW(), 'N'),
  ('7.21', 'Pesquisa, perfuração, cimentação, mergulho, perfilagem, concretação, testemunhagem, pescaria, estimulação e outros serviços relacionados com a exploração de petróleo, gás natural e outros recursos minerais', 'P', 'S', NOW(), NOW(), 'N'),
  ('7.22', 'Nucleação e bombardeamento de nuvens e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('8.01', 'Ensino regular pré-escolar, fundamental, médio e superior', 'P', 'S', NOW(), NOW(), 'N'),
  ('8.02', 'Instrução, treinamento, orientação pedagógica e educacional, avaliação de conhecimentos de qualquer natureza', 'P', 'S', NOW(), NOW(), 'N'),
  ('9.01', 'Hospedagem de qualquer natureza em hotéis, apart-service condominiais, flat, apart-hotéis, hotéis residência, residence-service, suite service, hotelaria marítima, motéis, pensões e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('9.02', 'Agenciamento, organização, promoção, intermediação e execução de programas de turismo, passeios, viagens, excursões, hospedagens e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('9.03', 'Guias de turismo', 'P', 'S', NOW(), NOW(), 'N'),
  ('10.01', 'Agenciamento, corretagem ou intermediação de câmbio, de seguros, de cartões de crédito, de planos de saúde e de planos de previdência privada', 'P', 'S', NOW(), NOW(), 'N'),
  ('10.02', 'Agenciamento, corretagem ou intermediação de títulos em geral, valores mobiliários e contratos quaisquer', 'P', 'S', NOW(), NOW(), 'N'),
  ('10.03', 'Agenciamento, corretagem ou intermediação de direitos de propriedade industrial, artística ou literária', 'P', 'S', NOW(), NOW(), 'N'),
  ('10.04', 'Agenciamento, corretagem ou intermediação de contratos de arrendamento mercantil (leasing), de franquia (franchising) e de faturização (factoring)', 'P', 'S', NOW(), NOW(), 'N'),
  ('10.05', 'Agenciamento, corretagem ou intermediação de bens móveis ou imóveis, não abrangidos em outros itens ou subitens', 'P', 'S', NOW(), NOW(), 'N'),
  ('10.06', 'Agenciamento marítimo', 'P', 'S', NOW(), NOW(), 'N'),
  ('10.07', 'Agenciamento de notícias', 'P', 'S', NOW(), NOW(), 'N'),
  ('10.08', 'Agenciamento de publicidade e propaganda, inclusive o agenciamento de veiculação por quaisquer meios', 'P', 'S', NOW(), NOW(), 'N'),
  ('10.09', 'Representação de qualquer natureza, inclusive comercial', 'P', 'S', NOW(), NOW(), 'N'),
  ('10.10', 'Distribuição de bens de terceiros', 'P', 'S', NOW(), NOW(), 'N'),
  ('11.01', 'Guarda e estacionamento de veículos terrestres automotores, de aeronaves e de embarcações', 'E', 'S', NOW(), NOW(), 'N'),
  ('11.02', 'Vigilância, segurança ou monitoramento de bens, pessoas e semoventes', 'E', 'S', NOW(), NOW(), 'N'),
  ('11.03', 'Escolta, inclusive de veículos e cargas', 'P', 'S', NOW(), NOW(), 'N'),
  ('11.04', 'Armazenamento, depósito, carga, descarga, arrumação e guarda de bens de qualquer espécie', 'E', 'S', NOW(), NOW(), 'N'),
  ('12.01', 'Espetáculos teatrais', 'E', 'S', NOW(), NOW(), 'N'),
  ('12.02', 'Exibições cinematográficas', 'E', 'S', NOW(), NOW(), 'N'),
  ('12.03', 'Espetáculos circenses', 'E', 'S', NOW(), NOW(), 'N'),
  ('12.04', 'Programas de auditório', 'E', 'S', NOW(), NOW(), 'N'),
  ('12.05', 'Parques de diversões, centros de lazer e congêneres', 'E', 'S', NOW(), NOW(), 'N'),
  ('12.06', 'Boates, taxi-dancing e congêneres', 'E', 'S', NOW(), NOW(), 'N'),
  ('12.07', 'Shows, ballet, danças, desfiles, bailes, óperas, concertos, recitais, festivais e congêneres', 'E', 'S', NOW(), NOW(), 'N'),
  ('12.08', 'Feiras, exposições, congressos e congêneres', 'E', 'S', NOW(), NOW(), 'N'),
  ('12.09', 'Bilhares, boliches e diversões eletrônicas ou não', 'E', 'S', NOW(), NOW(), 'N'),
  ('12.10', 'Corridas e competições de animais', 'E', 'S', NOW(), NOW(), 'N'),
  ('12.11', 'Competições esportivas ou de destreza física ou intelectual, com ou sem a participação do espectador', 'E', 'S', NOW(), NOW(), 'N'),
  ('12.12', 'Execução de música', 'E', 'S', NOW(), NOW(), 'N'),
  ('12.13', 'Produção, mediante ou sem encomenda prévia, de eventos, espetáculos, entrevistas, shows, ballet, danças, desfiles, bailes, teatros, óperas, concertos, recitais, festivais e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('12.14', 'Fornecimento de música para ambientes fechados ou não, mediante transmissão por qualquer processo', 'E', 'S', NOW(), NOW(), 'N'),
  ('12.15', 'Desfiles de blocos carnavalescos ou folclóricos, trios elétricos e congêneres', 'E', 'S', NOW(), NOW(), 'N'),
  ('12.16', 'Exibição de filmes, entrevistas, musicais, espetáculos, shows, concertos, desfiles, óperas, competições esportivas, de destreza intelectual ou congêneres', 'E', 'S', NOW(), NOW(), 'N'),
  ('12.17', 'Recreação e animação, inclusive em festas e eventos de qualquer natureza', 'E', 'S', NOW(), NOW(), 'N'),
  ('13.02', 'Fonografia ou gravação de sons, inclusive trucagem, dublagem, mixagem e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('13.03', 'Fotografia e cinematografia, inclusive revelação, ampliação, cópia, reprodução, trucagem e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('13.04', 'Reprografia, microfilmagem e digitalização', 'P', 'S', NOW(), NOW(), 'N'),
  ('13.05', 'Composição gráfica, inclusive confecção de impressos gráficos, fotocomposição, clicheria, zincografia, litografia e fotolitografia', 'P', 'S', NOW(), NOW(), 'N'),
  ('14.01', 'Lubrificação, limpeza, lustração, revisão, carga e recarga, conserto, restauração, blindagem, manutenção e conservação de máquinas, veículos, aparelhos, equipamentos, motores, elevadores ou de qualquer objeto', 'P', 'S', NOW(), NOW(), 'N'),
  ('14.02', 'Assistência técnica', 'P', 'S', NOW(), NOW(), 'N'),
  ('14.03', 'Recondicionamento de motores', 'P', 'S', NOW(), NOW(), 'N'),
  ('14.04', 'Recauchutagem ou regeneração de pneus', 'P', 'S', NOW(), NOW(), 'N'),
  ('14.05', 'Restauração, recondicionamento, acondicionamento, pintura, beneficiamento, lavagem, secagem, tingimento, galvanoplastia, anodização, corte, recorte, plastificação, costura, acabamento, polimento e congêneres de objetos quaisquer', 'P', 'S', NOW(), NOW(), 'N'),
  ('14.06', 'Instalação e montagem de aparelhos, máquinas e equipamentos, inclusive montagem industrial, prestados ao usuário final, exclusivamente com material por ele fornecido', 'P', 'S', NOW(), NOW(), 'N'),
  ('14.07', 'Colocação de molduras e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('14.08', 'Encadernação, gravação e douração de livros, revistas e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('14.09', 'Alfaiataria e costura, quando o material for fornecido pelo usuário final, exceto aviamento', 'P', 'S', NOW(), NOW(), 'N'),
  ('14.10', 'Tinturaria e lavanderia', 'P', 'S', NOW(), NOW(), 'N'),
  ('14.11', 'Tapeçaria e reforma de estofamentos em geral', 'P', 'S', NOW(), NOW(), 'N'),
  ('14.12', 'Funilaria e lanternagem', 'P', 'S', NOW(), NOW(), 'N'),
  ('14.13', 'Carpintaria e serralheria', 'P', 'S', NOW(), NOW(), 'N'),
  ('14.14', 'Guincho intramunicipal, guindaste e içamento', 'P', 'S', NOW(), NOW(), 'N'),
  ('15.01', 'Administração de fundos quaisquer, de consórcio, de cartão de crédito ou débito e congêneres, de carteira de clientes, de cheques pré-datados e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('15.02', 'Abertura de contas em geral, inclusive conta-corrente, conta de investimentos e aplicação e caderneta de poupança, no País e no exterior', 'P', 'S', NOW(), NOW(), 'N'),
  ('15.03', 'Locação e manutenção de cofres particulares, de terminais eletrônicos, de terminais de atendimento e de bens e equipamentos em geral', 'P', 'S', NOW(), NOW(), 'N'),
  ('15.04', 'Fornecimento ou emissão de atestados em geral, inclusive atestado de idoneidade, atestado de capacidade financeira e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('15.05', 'Cadastro, elaboração de ficha cadastral, renovação cadastral e congêneres, inclusão ou exclusão no Cadastro de Emitentes de Cheques sem Fundos e outros', 'P', 'S', NOW(), NOW(), 'N'),
  ('15.06', 'Emissão, reemissão e fornecimento de avisos, comprovantes e documentos em geral; abono de firmas; coleta e entrega de documentos, bens e valores', 'P', 'S', NOW(), NOW(), 'N'),
  ('15.07', 'Acesso, movimentação, atendimento e consulta a contas em geral, por qualquer meio ou processo', 'P', 'S', NOW(), NOW(), 'N'),
  ('15.08', 'Emissão, reemissão, alteração, cessão, substituição, cancelamento e registro de contrato de crédito; estudo, análise e avaliação de operações de crédito', 'P', 'S', NOW(), NOW(), 'N'),
  ('15.09', 'Arrendamento mercantil (leasing) de quaisquer bens, inclusive cessão de direitos e obrigações, substituição de garantia, alteração, cancelamento e registro de contrato', 'P', 'S', NOW(), NOW(), 'N'),
  ('15.10', 'Serviços relacionados a cobranças, recebimentos ou pagamentos em geral, de títulos quaisquer, de contas ou carnês, de câmbio, de tributos e por conta de terceiros', 'P', 'S', NOW(), NOW(), 'N'),
  ('15.11', 'Devolução de títulos, protesto de títulos, sustação de protesto, manutenção de títulos, reapresentação de títulos, e demais serviços a eles relacionados', 'P', 'S', NOW(), NOW(), 'N'),
  ('15.12', 'Custódia em geral, inclusive de títulos e valores mobiliários', 'P', 'S', NOW(), NOW(), 'N'),
  ('15.13', 'Serviços relacionados a operações de câmbio em geral', 'P', 'S', NOW(), NOW(), 'N'),
  ('15.14', 'Fornecimento, emissão, reemissão, renovação e manutenção de cartão magnético, cartão de crédito, cartão de débito, cartão salário e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('15.15', 'Compensação de cheques e títulos quaisquer; serviços relacionados a depósito, inclusive depósito identificado, a saque de contas quaisquer, por qualquer meio ou processo', 'P', 'S', NOW(), NOW(), 'N'),
  ('15.16', 'Emissão, reemissão, liquidação, alteração, cancelamento e baixa de ordens de pagamento, ordens de crédito e similares, por qualquer meio ou processo', 'P', 'S', NOW(), NOW(), 'N'),
  ('15.17', 'Emissão, fornecimento, devolução, sustação, cancelamento e oposição de cheques quaisquer, avulso ou por talão', 'P', 'S', NOW(), NOW(), 'N'),
  ('15.18', 'Serviços relacionados a crédito imobiliário, avaliação e vistoria de imóvel ou obra, análise técnica e jurídica, emissão, reemissão, alteração, transferência e renegociação de contrato', 'P', 'S', NOW(), NOW(), 'N'),
  ('16.01', 'Serviços de transporte coletivo municipal rodoviário, metroviário, ferroviário e aquaviário de passageiros', 'E', 'S', NOW(), NOW(), 'N'),
  ('16.02', 'Outros serviços de transporte de natureza municipal', 'E', 'S', NOW(), NOW(), 'N'),
  ('17.01', 'Assessoria ou consultoria de qualquer natureza, não contida em outros itens desta lista; análise, exame, pesquisa, coleta, compilação e fornecimento de dados e informações de qualquer natureza', 'P', 'S', NOW(), NOW(), 'N'),
  ('17.02', 'Datilografia, digitação, estenografia, expediente, secretaria em geral, resposta audível, redação, edição, interpretação, revisão, tradução, apoio e infra-estrutura administrativa e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('17.03', 'Planejamento, coordenação, programação ou organização técnica, financeira ou administrativa', 'P', 'S', NOW(), NOW(), 'N'),
  ('17.04', 'Recrutamento, agenciamento, seleção e colocação de mão-de-obra', 'P', 'S', NOW(), NOW(), 'N'),
  ('17.05', 'Fornecimento de mão-de-obra, mesmo em caráter temporário, inclusive de empregados ou trabalhadores, avulsos ou temporários, contratados pelo prestador de serviço', 'E', 'S', NOW(), NOW(), 'N'),
  ('17.06', 'Propaganda e publicidade, inclusive promoção de vendas, planejamento de campanhas ou sistemas de publicidade, elaboração de desenhos, textos e demais materiais publicitários', 'P', 'S', NOW(), NOW(), 'N'),
  ('17.08', 'Franquia (franchising)', 'P', 'S', NOW(), NOW(), 'N'),
  ('17.09', 'Perícias, laudos, exames técnicos e análises técnicas', 'P', 'S', NOW(), NOW(), 'N'),
  ('17.10', 'Planejamento, organização e administração de feiras, exposições, congressos e congêneres', 'E', 'S', NOW(), NOW(), 'N'),
  ('17.11', 'Organização de festas e recepções; bufê', 'P', 'S', NOW(), NOW(), 'N'),
  ('17.12', 'Administração em geral, inclusive de bens e negócios de terceiros', 'P', 'S', NOW(), NOW(), 'N'),
  ('17.13', 'Leilão e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('17.14', 'Advocacia', 'P', 'S', NOW(), NOW(), 'N'),
  ('17.15', 'Arbitragem de qualquer espécie, inclusive jurídica', 'P', 'S', NOW(), NOW(), 'N'),
  ('17.16', 'Auditoria', 'P', 'S', NOW(), NOW(), 'N'),
  ('17.17', 'Análise de Organização e Métodos', 'P', 'S', NOW(), NOW(), 'N'),
  ('17.18', 'Atuária e cálculos técnicos de qualquer natureza', 'P', 'S', NOW(), NOW(), 'N'),
  ('17.19', 'Contabilidade, inclusive serviços técnicos e auxiliares', 'P', 'S', NOW(), NOW(), 'N'),
  ('17.20', 'Consultoria e assessoria econômica ou financeira', 'P', 'S', NOW(), NOW(), 'N'),
  ('17.21', 'Estatística', 'P', 'S', NOW(), NOW(), 'N'),
  ('17.22', 'Cobrança em geral', 'P', 'S', NOW(), NOW(), 'N'),
  ('17.23', 'Assessoria, análise, avaliação, atendimento, consulta, cadastro, seleção, gerenciamento de informações, administração de contas a receber ou a pagar e em geral, relacionados a operações de faturização (factoring)', 'P', 'S', NOW(), NOW(), 'N'),
  ('17.24', 'Apresentação de palestras, conferências, seminários e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('17.25', 'Inserção de textos, desenhos e outros materiais de propaganda e publicidade, em qualquer meio (exceto em livros, jornais, periódicos e nas modalidades de serviços de radiodifusão sonora e de sons e imagens de recepção livre e gratuita)', 'P', 'S', NOW(), NOW(), 'N'),
  ('18.01', 'Serviços de regulação de sinistros vinculados a contratos de seguros; inspeção e avaliação de riscos para cobertura de contratos de seguros; prevenção e gerência de riscos seguráveis e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('19.01', 'Serviços de distribuição e venda de bilhetes e demais produtos de loteria, bingos, cartões, pules ou cupons de apostas, sorteios, prêmios, inclusive os decorrentes de títulos de capitalização e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('20.01', 'Serviços portuários, ferroportuários, utilização de porto, movimentação de passageiros, reboque de embarcações, rebocador escoteiro, atracação, desatracação, serviços de praticagem, capatazia, armazenagem de qualquer natureza, serviços acessórios, movimentação de mercadorias, serviços de apoio marítimo, de movimentação ao largo, serviços de armadores, estiva, conferência, logística e congêneres', 'E', 'S', NOW(), NOW(), 'N'),
  ('20.02', 'Serviços aeroportuários, utilização de aeroporto, movimentação de passageiros, armazenagem de qualquer natureza, capatazia, movimentação de aeronaves, serviços de apoio aeroportuários, serviços acessórios, movimentação de mercadorias, logística e congêneres', 'E', 'S', NOW(), NOW(), 'N'),
  ('20.03', 'Serviços de terminais rodoviários, ferroviários, metroviários, movimentação de passageiros, mercadorias, inclusive suas operações, logística e congêneres', 'E', 'S', NOW(), NOW(), 'N'),
  ('21.01', 'Serviços de registros públicos, cartorários e notariais', 'P', 'S', NOW(), NOW(), 'N'),
  ('22.01', 'Serviços de exploração de rodovia mediante cobrança de preço ou pedágio dos usuários, envolvendo execução de serviços de conservação, manutenção, melhoramentos para adequação de capacidade e segurança de trânsito, operação, monitoração, assistência aos usuários e outros serviços definidos em contratos, atos de concessão ou de permissão ou em normas oficiais', 'P', 'S', NOW(), NOW(), 'N'),
  ('23.01', 'Serviços de programação e comunicação visual, desenho industrial e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('24.01', 'Serviços de chaveiros, confecção de carimbos, placas, sinalização visual, banners, adesivos e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('25.01', 'Funerais, inclusive fornecimento de caixão, urna ou esquifes; aluguel de capela; transporte do corpo cadavérico; fornecimento de flores, coroas e outros paramentos; desembaraço de certidão de óbito; fornecimento de véu, essa e outros adornos; embalsamento, embelezamento, conservação ou restauração de cadáveres', 'P', 'S', NOW(), NOW(), 'N'),
  ('25.02', 'Translado intramunicipal e cremação de corpos e partes de corpos cadavéricos', 'P', 'S', NOW(), NOW(), 'N'),
  ('25.03', 'Planos ou convênio funerários', 'P', 'S', NOW(), NOW(), 'N'),
  ('25.04', 'Manutenção e conservação de jazigos e cemitérios', 'P', 'S', NOW(), NOW(), 'N'),
  ('25.05', 'Cessão de uso de espaços em cemitérios para sepultamento', 'P', 'S', NOW(), NOW(), 'N'),
  ('26.01', 'Serviços de coleta, remessa ou entrega de correspondências, documentos, objetos, bens ou valores, inclusive pelos correios e suas agências franqueadas; courrier e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('27.01', 'Serviços de assistência social', 'P', 'S', NOW(), NOW(), 'N'),
  ('28.01', 'Serviços de avaliação de bens e serviços de qualquer natureza', 'P', 'S', NOW(), NOW(), 'N'),
  ('29.01', 'Serviços de biblioteconomia', 'P', 'S', NOW(), NOW(), 'N'),
  ('30.01', 'Serviços de biologia, biotecnologia e química', 'P', 'S', NOW(), NOW(), 'N'),
  ('31.01', 'Serviços técnicos em edificações, eletrônica, eletrotécnica, mecânica, telecomunicações e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('32.01', 'Serviços de desenhos técnicos', 'P', 'S', NOW(), NOW(), 'N'),
  ('33.01', 'Serviços de desembaraço aduaneiro, comissários, despachantes e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('34.01', 'Serviços de investigações particulares, detetives e congêneres', 'P', 'S', NOW(), NOW(), 'N'),
  ('35.01', 'Serviços de reportagem, assessoria de imprensa, jornalismo e relações públicas', 'P', 'S', NOW(), NOW(), 'N'),
  ('36.01', 'Serviços de meteorologia', 'P', 'S', NOW(), NOW(), 'N'),
  ('37.01', 'Serviços de artistas, atletas, modelos e manequins', 'P', 'S', NOW(), NOW(), 'N'),
  ('38.01', 'Serviços de museologia', 'P', 'S', NOW(), NOW(), 'N'),
  ('39.01', 'Serviços de ourivesaria e lapidação (quando o material for fornecido pelo tomador do serviço)', 'P', 'S', NOW(), NOW(), 'N'),
  ('40.01', 'Obras de arte sob encomenda', 'P', 'S', NOW(), NOW(), 'N')
ON DUPLICATE KEY UPDATE `description` = VALUES(`description`), `local_incidence` = VALUES(`local_incidence`), `updated_at` = NOW();

-- Interface do MÓDULO SUPER (grupo 'Super' — sem contrato/flag, como cfop).
-- id DINÂMICO (lição do seed 40).
INSERT INTO `tb_interface`
  (`id`, `group_default`, `i18n_key`, `description`, `kind`, `position`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(i2.`id`), 0) + 1 FROM `tb_interface` i2),
       'Super', 'service-list', 'Service List', 'T', NULL, NOW(), NOW(), 'N'
 WHERE NOT EXISTS (SELECT 1 FROM `tb_interface`
                    WHERE `i18n_key` = 'service-list' AND `deleted` = 'N');

-- Catálogo de CAMPOS da tela (engine de campos configuráveis).
INSERT IGNORE INTO `tb_interface_has_field`
  (`tb_interface_id`, `field_name`, `table_name`, `kind`, `required`, `created_at`, `updated_at`, `deleted`)
SELECT i.`id`, f.`field_name`, 'tb_service_list', f.`kind`, f.`required`, NOW(), NOW(), 'N'
  FROM `tb_interface` i
  JOIN (SELECT 'id' AS field_name, 'String' AS kind, 'S' AS required
        UNION ALL SELECT 'description', 'String', 'S'
        UNION ALL SELECT 'local_incidence', 'String', 'S'
        UNION ALL SELECT 'active', 'Boolean', 'N') f
 WHERE i.`deleted` = 'N' AND i.`i18n_key` = 'service-list';

-- Paginação (regra: lista nova nasce paginada — seed 22).
INSERT IGNORE INTO `tb_interface_has_config`
  (`tb_interface_id`, `name`, `description`, `kind`, `options`, `default_content`, `scope`, `created_at`, `updated_at`, `deleted`)
SELECT i.`id`, 'page_size',
       'Número de itens exibidos por página na lista de pesquisa.',
       'Options', '10=10;25=25;50=50;100=100', '25', 'U', NOW(), NOW(), 'N'
  FROM `tb_interface` i
 WHERE i.`deleted` = 'N' AND i.`i18n_key` = 'service-list';
