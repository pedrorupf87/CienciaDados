-- Criação da tabela clientes (exemplo realista e genérico)
CREATE TABLE IF NOT EXISTS clientes 
(
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    cpf CHAR(11) UNIQUE,
    telefone VARCHAR(20),
    data_nascimento DATE,
    ativo BOOLEAN DEFAULT true,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para melhorar performance (recomendado)
CREATE INDEX idx_clientes_email ON clientes(email);
CREATE INDEX idx_clientes_ativo ON clientes(ativo);
CREATE INDEX idx_clientes_data_cadastro ON clientes(data_cadastro);


-------------------------------------------------------------------------


INSERT INTO clientes (nome, email, cpf, telefone, data_nascimento, ativo) VALUES
('Ana Silva', 'ana.silva@email.com', '12345678901', '11987654321', '1990-03-15', true),
('Carlos Santos', 'carlos.santos@email.com', '23456789012', '21988765432', '1985-07-22', true),
('Maria Oliveira', 'maria.oliveira@email.com', '34567890123', '31999887766', '1992-11-30', true),
('João Pereira', 'joao.pereira@email.com', '45678901234', '11955443322', '1988-01-10', true),
('Fernanda Costa', 'fernanda.costa@email.com', '56789012345', '21987651234', '1995-05-18', false),
('Pedro Almeida', 'pedro.almeida@email.com', '67890123456', '11933221100', '1980-09-25', true),
('Juliana Lima', 'juliana.lima@email.com', '78901234567', '31988776655', '1993-12-05', true),
('Ricardo Mendes', 'ricardo.mendes@email.com', '89012345678', '21944332211', '1978-04-12', true),
('Beatriz Rocha', 'beatriz.rocha@email.com', '90123456789', '11966554433', '1998-08-20', true),
('Lucas Ferreira', 'lucas.ferreira@email.com', '01234567890', '31911223344', '1991-06-14', true),
('Camila Souza', 'camila.souza@email.com', '11223344556', '11977889900', '1987-02-28', true),
('Gustavo Nogueira', 'gustavo.nogueira@email.com', '22334455667', '21966778899', '1994-10-03', false),
('Patrícia Ramos', 'patricia.ramos@email.com', '33445566778', '31955667788', '1989-07-07', true),
('Felipe Castro', 'felipe.castro@email.com', '44556677889', '11944556677', '1996-11-11', true),
('Tatiana Barbosa', 'tatiana.barbosa@email.com', '55667788990', '21933445566', '1983-03-22', true),
('Renato Vieira', 'renato.vieira@email.com', '66778899001', '31922334455', '1990-09-01', true),
('Larissa Duarte', 'larissa.duarte@email.com', '77889900112', '11911223344', '1997-04-16', true),
('Marcelo Freitas', 'marcelo.freitas@email.com', '88990011223', '21999887766', '1981-12-25', false),
('Vanessa Cardoso', 'vanessa.cardoso@email.com', '99001122334', '31988776655', '1993-05-30', true),
('Eduardo Martins', 'eduardo.martins@email.com', '10111213141', '11977665544', '1986-08-08', true),
('Aline Teixeira', 'aline.teixeira@email.com', '12131415161', '21955443322', '1995-01-20', true),
('Roberto Dias', 'roberto.dias@email.com', '13141516171', '31944332211', '1979-10-10', true),
('Sônia Ribeiro', 'sonia.ribeiro@email.com', '14151617181', '11933221100', '1992-02-14', true),
('Thiago Moreira', 'thiago.moreira@email.com', '15161718191', '21988776655', '1988-06-18', true),
('Cláudia Fernandes', 'claudia.fernandes@email.com', '16171819201', '31977665544', '1990-11-05', false),
('André Luis', 'andre.luis@email.com', '17181920211', '11966554433', '1984-07-27', true),
('Isabela Monteiro', 'isabela.monteiro@email.com', '18192021221', '21944332211', '1996-03-12', true),
('Fábio Correia', 'fabio.correia@email.com', '19202122231', '31955443322', '1987-09-09', true),
('Natália Pires', 'natalia.pires@email.com', '20212223241', '11988776655', '1994-12-01', true),
('Vinícius Gomes', 'vinicius.gomes@email.com', '21222324251', '21977665544', '1991-05-25', true),
('Letícia Araújo', 'leticia.araujo@email.com', '22232425261', '31966554433', '1998-08-15', true),
('Rafael Bezerra', 'rafael.bezerra@email.com', '23242526271', '11955443322', '1985-04-04', true),
('Carolina Farias', 'carolina.farias@email.com', '24252627281', '21988776655', '1993-10-20', true),
('Daniela Campos', 'daniela.campos@email.com', '25262728291', '31944332211', '1989-01-30', false),
('Leonardo Macedo', 'leonardo.macedo@email.com', '26272829301', '11977665544', '1990-07-15', true),
('Priscila Viana', 'priscila.viana@email.com', '27282930311', '21966554433', '1995-11-22', true),
('Sérgio Batista', 'sergio.batista@email.com', '28293031321', '31955443322', '1982-02-28', true),
('Érica Lemos', 'erica.lemos@email.com', '29303132331', '11944332211', '1997-06-10', true),
('Otávio Rezende', 'otavio.rezende@email.com', '30313233341', '21988776655', '1986-09-18', true),
('Bianca Teles', 'bianca.teles@email.com', '31323334351', '31977665544', '1994-03-05', true),
('Rodrigo Meireles', 'rodrigo.meireles@email.com', '32333435361', '11966554433', '1988-12-12', true),
('Talita Xavier', 'talita.xavier@email.com', '33343536371', '21955443322', '1996-05-08', true),
('Hugo Queiroz', 'hugo.queiroz@email.com', '34353637381', '31944332211', '1991-08-25', true),
('Débora Lira', 'debora.lira@email.com', '35363738391', '11988776655', '1993-04-14', false),
('Vitor Hugo', 'vitor.hugo@email.com', '36373839401', '21977665544', '1989-10-30', true),
('Lívia Fontes', 'livia.fontes@email.com', '37383940411', '31966554433', '1997-07-07', true),
('Márcio Dantas', 'marcio.dantas@email.com', '38394041421', '11955443322', '1984-01-19', true),
('Jéssica Porto', 'jessica.porto@email.com', '39404142431', '21944332211', '1995-09-27', true),
('Fábio André', 'fabio.andre@email.com', '40414243441', '31988776655', '1990-11-11', true),
('Amanda Reis', 'amanda.reis@email.com', '41424344451', '11977665544', '1998-02-28', true);

-- Confirmação rápida
SELECT COUNT(*) AS total_clientes FROM clientes


select * from clientes