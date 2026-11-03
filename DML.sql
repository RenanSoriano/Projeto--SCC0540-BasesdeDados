-- ============================================================
-- DML.sql — população do banco (SCC0640 - Gestão de Eventos e Espaços)
-- Executar APÓS criar as estruturas com o DDL do Projeto.txt.
-- Idempotente: limpa as tabelas antes de inserir.
-- ============================================================

TRUNCATE SessaoHistorico, AtuacaoAtividade, ParticipacaoEvento,
         InscricaoSessao, InscricaoEvento, Promocao, Sessao, Atividade,
         Espaco, Evento, Organizacao, Pessoa
RESTART IDENTITY CASCADE;

-- ------------------------------------------------------------
-- Organizações
-- ------------------------------------------------------------
INSERT INTO Organizacao (nome, tipo) VALUES
 ('ICMC-USP', 'universidade'),
 ('TechCorp', 'empresa'),
 ('ACM', 'associacao');

-- ------------------------------------------------------------
-- Espaços (recursos variados; Pátio não recebe sessões)
-- ------------------------------------------------------------
INSERT INTO Espaco (nome, tipo, capacidade, projetor, computadores, audio, internet) VALUES
 ('Auditório B', 'auditorio', 120, true, false, true, true),
 ('Sala A', 'sala', 40, true, false, false, false),
 ('Lab Informática 1', 'laboratorio', 20, false, true, false, true),
 ('Sala Workshop', 'sala', 10, false, false, false, false),
 ('Pátio de Exposições', 'area_exposicao', 200, true, false, false, true);

-- ------------------------------------------------------------
-- Eventos (edições independentes de uma mesma iniciativa)
-- ------------------------------------------------------------
INSERT INTO Evento (nome, edicao, descricao, data_inicio, data_fim) VALUES
 ('Semana da Computação', 2026, 'Evento anual do ICMC-USP com palestras, workshops e minicursos.', '2026-05-10', '2026-05-14'),
 ('Semana da Computação', 2027, 'Edição futura, ainda em planejamento.', '2027-05-09', '2027-05-13');

-- ------------------------------------------------------------
-- Pessoas
-- ------------------------------------------------------------
INSERT INTO Pessoa (cpf, nome, email) VALUES
 ('00000000001', 'Ana Paula Ferreira', 'ana.ferreira@exemplo.com'),
 ('00000000002', 'Bruno Carvalho Lima', 'bruno.lima@exemplo.com'),
 ('00000000003', 'Camila Souza Rocha', 'camila.rocha@exemplo.com'),
 ('00000000004', 'Diego Almeida Pinto', 'diego.pinto@exemplo.com'),
 ('00000000005', 'Eduarda Nunes Ramos', 'eduarda.ramos@exemplo.com'),
 ('00000000006', 'Felipe Martins Costa', 'felipe.costa@exemplo.com'),
 ('00000000007', 'Giovana Pereira Dias', 'giovana.dias@exemplo.com'),
 ('00000000008', 'Henrique Oliveira Melo', 'henrique.melo@exemplo.com'),
 ('00000000009', 'Isabela Santos Rocha', 'isabela.rocha@exemplo.com'),
 ('00000000010', 'João Victor Barbosa', 'joao.barbosa@exemplo.com'),
 ('00000000011', 'Larissa Mendes Freitas', 'larissa.freitas@exemplo.com'),
 ('00000000012', 'Marcos Vinícius Teixeira', 'marcos.teixeira@exemplo.com');

-- ------------------------------------------------------------
-- Promoção de eventos (org OU pessoa — promoção conjunta no 2026)
-- ------------------------------------------------------------
INSERT INTO Promocao (id_evento, id_organizacao, cpf) VALUES
 (1, 1, NULL),
 (1, 2, NULL),
 (1, NULL, '00000000001'),
 (2, 1, NULL);

-- ------------------------------------------------------------
-- Atividades
-- ------------------------------------------------------------
INSERT INTO Atividade (id_evento, titulo, descricao, tipo) VALUES
 (1, 'Workshop de PostgreSQL', 'Prática de modelagem e consultas em PostgreSQL.', 'workshop'),
 (1, 'Minicurso de Python', 'Introdução à linguagem Python para análise de dados.', 'minicurso'),
 (1, 'Palestra: Carreiras em Dados', 'Panorama de carreiras na área de dados.', 'palestra'),
 (1, 'Painel: IA na Educação', 'Debate sobre uso de IA no ensino.', 'painel'),
 (1, 'Mesa-redonda: Ética em IA', 'Discussão sobre impactos éticos da IA.', 'mesa_redonda'),
 (1, 'Palestra: Segurança de Bancos de Dados', 'Boas práticas de segurança em SGBDs.', 'palestra'),
 (1, 'Oficina de Git', 'Controle de versão na prática.', 'workshop'),
 (2, 'Palestra: Tendências em Computação', 'Visão geral das tendências para 2027.', 'palestra');

-- ------------------------------------------------------------
-- Sessões (sem sobreposição de horário no mesmo espaço)
-- ------------------------------------------------------------
INSERT INTO Sessao (id_atividade, id_espaco, data, hora_inicio, hora_fim, vagas_limite) VALUES
 (1, 'Sala Workshop', '2026-05-12', '09:00', '12:00', 6),
 (2, 'Lab Informática 1', '2026-05-12', '14:00', '17:00', NULL),
 (2, 'Lab Informática 1', '2026-05-13', '14:00', '17:00', NULL),
 (3, 'Auditório B', '2026-05-12', '10:00', '11:30', NULL),
 (4, 'Auditório B', '2026-05-13', '16:00', '18:00', NULL),
 (5, 'Sala A', '2026-05-14', '10:00', '12:00', NULL),
 (6, 'Sala A', '2026-05-13', '10:00', '11:00', NULL),
 (7, 'Sala Workshop', '2026-05-13', '09:00', '11:00', NULL),
 (8, 'Auditório B', '2027-05-10', '10:00', '11:30', NULL);

-- ------------------------------------------------------------
-- Inscrições no evento
-- ------------------------------------------------------------
INSERT INTO InscricaoEvento (cpf, id_evento, status) VALUES
 ('00000000001', 1, 'confirmada'),
 ('00000000002', 1, 'confirmada'),
 ('00000000003', 1, 'confirmada'),
 ('00000000004', 1, 'confirmada'),
 ('00000000005', 1, 'confirmada'),
 ('00000000006', 1, 'confirmada'),
 ('00000000007', 1, 'confirmada'),
 ('00000000008', 1, 'confirmada'),
 ('00000000009', 1, 'confirmada'),
 ('00000000010', 1, 'confirmada'),
 ('00000000011', 1, 'cancelada'),
 ('00000000001', 2, 'confirmada'),
 ('00000000002', 2, 'confirmada');

-- ------------------------------------------------------------
-- Inscrições em sessões
-- S1 (limite 6): 6 confirmadas, 2 lista_espera, 1 cancelada
-- S8 (Oficina de Git): sem inscrições
-- ------------------------------------------------------------
INSERT INTO InscricaoSessao (cpf, id_sessao, status) VALUES
 ('00000000003', 1, 'confirmada'),
 ('00000000004', 1, 'confirmada'),
 ('00000000005', 1, 'confirmada'),
 ('00000000006', 1, 'confirmada'),
 ('00000000007', 1, 'confirmada'),
 ('00000000008', 1, 'confirmada'),
 ('00000000009', 1, 'lista_espera'),
 ('00000000010', 1, 'lista_espera'),
 ('00000000002', 1, 'cancelada'),
 ('00000000001', 2, 'confirmada'),
 ('00000000002', 2, 'confirmada'),
 ('00000000003', 2, 'confirmada'),
 ('00000000004', 2, 'confirmada'),
 ('00000000009', 2, 'cancelada'),
 ('00000000005', 3, 'confirmada'),
 ('00000000006', 3, 'confirmada'),
 ('00000000007', 3, 'confirmada'),
 ('00000000001', 4, 'confirmada'),
 ('00000000002', 4, 'confirmada'),
 ('00000000005', 4, 'confirmada'),
 ('00000000009', 4, 'confirmada'),
 ('00000000010', 4, 'confirmada'),
 ('00000000006', 4, 'cancelada'),
 ('00000000003', 5, 'confirmada'),
 ('00000000004', 5, 'confirmada'),
 ('00000000007', 5, 'confirmada'),
 ('00000000008', 5, 'confirmada'),
 ('00000000001', 6, 'confirmada'),
 ('00000000002', 6, 'confirmada'),
 ('00000000003', 6, 'confirmada'),
 ('00000000004', 7, 'confirmada'),
 ('00000000005', 7, 'confirmada');

-- ------------------------------------------------------------
-- Participação no evento (papéis: ouvinte/organizador)
-- Ana (cpf 1) exerce os dois papéis no evento 1
-- ------------------------------------------------------------
INSERT INTO ParticipacaoEvento (cpf, id_evento, papel) VALUES
 ('00000000001', 1, 'organizador'),
 ('00000000002', 1, 'organizador'),
 ('00000000001', 1, 'ouvinte'),
 ('00000000003', 1, 'ouvinte'),
 ('00000000004', 1, 'ouvinte'),
 ('00000000005', 1, 'ouvinte'),
 ('00000000006', 1, 'ouvinte'),
 ('00000000007', 1, 'ouvinte'),
 ('00000000008', 1, 'ouvinte'),
 ('00000000009', 1, 'ouvinte'),
 ('00000000010', 1, 'ouvinte'),
 ('00000000001', 2, 'organizador');

-- ------------------------------------------------------------
-- Atuação em atividades (papéis: palestrante/instrutor/mediador)
-- ------------------------------------------------------------
INSERT INTO AtuacaoAtividade (cpf, id_atividade, papel) VALUES
 ('00000000006', 1, 'instrutor'),
 ('00000000007', 2, 'instrutor'),
 ('00000000003', 3, 'palestrante'),
 ('00000000004', 4, 'palestrante'),
 ('00000000005', 4, 'palestrante'),
 ('00000000001', 4, 'mediador'),
 ('00000000008', 5, 'palestrante'),
 ('00000000009', 5, 'palestrante'),
 ('00000000002', 5, 'mediador'),
 ('00000000010', 6, 'palestrante'),
 ('00000000012', 6, 'palestrante'),
 ('00000000006', 7, 'instrutor'),
 ('00000000003', 8, 'palestrante');

-- ------------------------------------------------------------
-- Reprogramações de sessões (o histórico é gravado por trigger)
-- 1) Sessão 4 muda de espaço: Auditório B -> Sala A
-- 2) Sessão 7 muda de horário: 10:00-11:00 -> 11:30-12:30
-- ------------------------------------------------------------
UPDATE Sessao SET id_espaco = 'Sala A' WHERE id_sessao = 4;
UPDATE Sessao SET hora_inicio = '11:30', hora_fim = '12:30' WHERE id_sessao = 7;
