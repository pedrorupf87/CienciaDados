# Projeto 01 — Internações hospitalares do SUS

**Análise exploratória das Autorizações de Internação Hospitalar (AIH) do SIH-SUS.**
Fase 2 do roadmap. Status: em andamento.

---

## Pergunta de negócio

> **Onde está a variação evitável nas internações do SUS — em tempo de permanência, custo e
> mortalidade hospitalar — e quais fatores a explicam?**

A pergunta importa porque cada um desses três eixos é uma alavanca de gestão diferente: permanência
excessiva ocupa leito que outro paciente precisa, concentração de gasto indica onde a negociação
vale mais, e variação de mortalidade entre serviços semelhantes é o indicador que dispara
investigação clínica.

### Sub-perguntas

1. **Perfil** — quem interna (idade, sexo), por quê (capítulo CID-10), em que caráter (eletiva ou
   urgência) e em qual especialidade de leito?
2. **Permanência** — como se distribui o tempo de internação, e quais fatores deslocam a mediana?
3. **Custo** — como o gasto se concentra por diagnóstico, procedimento e estabelecimento? Qual é a
   curva de Pareto?
4. **Mortalidade hospitalar** — quais fatores estão associados ao óbito durante a internação, e o
   que a associação *não* permite concluir?
5. **Rede assistencial** — quanto de deslocamento existe entre município de residência e município
   de atendimento, e o que isso sugere sobre a distribuição da oferta?

---

## Por que este projeto

O domínio é deliberado. Sistemas hospitalares são o território do Intersystems Caché/IRIS, e o
vocabulário de negócio — AIH, CID-10, procedimento, caráter da internação, tempo de permanência —
já é familiar. Esse é o tipo de vantagem que não se adquire em curso: a maior parte dos candidatos
sabe rodar `groupby`, mas não sabe por que uma AIH de continuação não pode ser somada ingenuamente
ao tempo de permanência.

Nada aqui depende de Caché/IRIS instalado. Os dados vêm do DATASUS em arquivos `.dbc` e são
processados em Python e PostgreSQL.

---

## Dados

| | |
|---|---|
| **Fonte** | DATASUS, FTP público — `ftp.datasus.gov.br/dissemin/publicos/SIHSUS/200801_/Dados` |
| **Conjunto** | RD — AIH Reduzida, um arquivo por UF e por competência mensal |
| **Escopo** | Santa Catarina, 12 competências de 2024 (~600 mil AIH) |
| **Formato** | `.dbc` (DBF comprimido, formato proprietário do DATASUS) |
| **Colunas** | 24 das 113 disponíveis, listadas em [`src/dicionario.py`](src/dicionario.py) |
| **Layout oficial** | [`referencias/IT_SIHSUS_1603.pdf`](referencias/) |

### Reproduzindo a coleta

```bash
cd projetos/01-eda-internacoes-sus
../../.venv/bin/python src/coleta.py --uf SC --ano 2024
```

O download é idempotente e cada mês vira um Parquet antes da consolidação, então interromper e
retomar é seguro. Os dados brutos caem em `dados/bruto/sihsus/`, que está fora do Git.

Para trocar o escopo, mude `--uf` e `--ano`. Referência de tamanho por competência: Acre 306 KB,
Santa Catarina 3,7 MB, Minas Gerais 9,3 MB, São Paulo 17 MB.

---

## Advertências de domínio

Sete armadilhas do SIH-SUS que invalidam análises feitas sem conhecimento do dado. Todas foram
verificadas nos arquivos reais, não apenas lidas na documentação.

**1. A unidade de análise é a AIH, não o paciente.** Não existe identificador de paciente no RD.
Um mesmo paciente com três internações no ano aparece como três registros independentes. Qualquer
frase do tipo "N pacientes" é errada; o correto é "N internações".

**2. O arquivo é organizado por competência de pagamento, não por data de internação.** O arquivo
de janeiro de 2024 do Acre contém internações iniciadas em janeiro de **2023**. Para qualquer série
temporal, agrupe por `DT_INTER` e descarte os meses de borda, que vêm incompletos.

**3. `IDADE` sozinha não significa nada.** É preciso ler `COD_IDADE`: 2 = dias, 3 = meses,
4 = anos, e **5 = anos acima de 100**. Um registro com `IDADE = 4` e `COD_IDADE = 5` é um paciente
de 104 anos — conferido contra a data de nascimento. Ignorar isso joga a população mais idosa,
que é justamente a mais crítica, para a faixa pediátrica.

**4. `VAL_TOT` é repasse do SUS, não custo.** É quanto o gestor federal pagou pela AIH conforme a
tabela SIGTAP, não quanto a internação custou ao hospital. Conclusões sobre eficiência de custo
precisam dizer isso explicitamente.

**5. AIH de continuação duplica permanência.** `IDENT = 5` indica continuação de uma internação
longa já registrada. Somar `DIAS_PERM` sem tratar isso conta os mesmos dias duas vezes.

**6. Mortalidade hospitalar não é letalidade da doença.** `MORTE` marca óbito *durante a
internação*. Quem morre após a alta não aparece, e a taxa é sensível ao perfil de gravidade que
cada hospital recebe — um serviço de referência em oncologia tem mortalidade maior por receber
casos mais graves, não por ser pior.

**7. "Fora do município" mistura dois fenômenos.** `MUNIC_RES ≠ MUNIC_MOV` captura tanto
deslocamento real em busca de atendimento quanto erro de cadastro do endereço. No Acre, isso
alcança 28% das internações — grande o bastante para exigir cautela na interpretação.

---

## Método

| Semana | Etapa | Entrega |
|---|---|---|
| 1 | Coleta e preparação | Parquet consolidado, validado, e a tabela analítica com as colunas derivadas |
| 2 | Perfil e distribuições | Sub-pergunta 1 respondida; escolha das variáveis que seguem na análise |
| 3 | Permanência e custo | Sub-perguntas 2 e 3, com curva de Pareto e análise de assimetria |
| 4 | Mortalidade e rede | Sub-perguntas 4 e 5, com a distinção explícita entre associação e causa |
| 5 | Escrita e revisão | `relatorio.md` fechado, gráficos revisados, limitações declaradas |

### Notebooks

| Notebook | Conteúdo |
|---|---|
| [`01-coleta-e-preparacao.ipynb`](notebooks/01-coleta-e-preparacao.ipynb) | Executa a coleta, valida o dado e constrói a tabela analítica |
| [`02-analise-exploratoria.ipynb`](notebooks/02-analise-exploratoria.ipynb) | As cinco sub-perguntas |

---

## Achados

_A preencher ao longo da Fase 2. Cada achado deve vir com o número que o sustenta._

---

## Limitações

_A preencher. As advertências de domínio acima são o ponto de partida: as que permanecerem válidas
no fechamento entram aqui, com a consequência prática de cada uma para as conclusões._
