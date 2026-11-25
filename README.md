# AdventureWorks Data Warehouse

### Data Warehouse, ETL Incremental e Business Intelligence com PostgreSQL e Apache Airflow

Projeto de implementação de um Data Warehouse baseado na base AdventureWorks, utilizando arquitetura dimensional (Star Schema), processos de ETL incremental e orquestração com Apache Airflow.

O objetivo é transformar os dados operacionais de vendas em informações estruturadas para análise de desempenho comercial, acompanhamento de indicadores e apoio à tomada de decisão.

---

## 1. Visão geral

O projeto utiliza o banco AdventureWorks como fonte de dados operacional (OLTP) e realiza a integração das informações em um Data Warehouse (DW), organizado em um modelo dimensional.

O processo contempla:

- Extração incremental de dados da origem.
- Armazenamento temporário em tabelas de staging.
- Transformação e carga das dimensões.
- Carga da tabela fato de vendas.
- Controle de processamento por marca d'água (*watermark*).
- Validação de consistência entre origem e destino.
- Disponibilização de 10 indicadores de desempenho (KPIs).

## 2. Tecnologias utilizadas

| Tecnologia | Aplicação |
|---|---|
| PostgreSQL | Banco de dados OLTP e Data Warehouse |
| Apache Airflow 3.3.1 | Orquestração dos processos ETL |
| Python | Desenvolvimento das DAGs |
| SQL | Extração, transformação, carga e consultas analíticas |
| WSL2 / Ubuntu | Ambiente de execução local |
| Git / GitHub | Versionamento do projeto |
| PlantUML | Modelagem e documentação do Star Schema |

## 3. Arquitetura da solução

O fluxo de dados segue a seguinte estrutura:

```text
       ADVENTUREWORKS OLTP
          PostgreSQL
               |
               v
       APACHE AIRFLOW
               |
       ETL INCREMENTAL
               |
               v
          STAGING
          stg.*
               |
               v
       TRANSFORMAÇÃO
               |
       +-------+-------+
       |               |
       v               v
   DIMENSÕES        FATO VENDAS
    dw.dim_*         dw.fato_vendas
       |               |
       +-------+-------+
               |
               v
       DATA WAREHOUSE
               |
               v
          10 KPIs
          dw.vw_*
```

O Data Warehouse utiliza o modelo estrela, com dimensões relacionadas à tabela fato de vendas.

O controle do processamento é realizado por meio dos schemas `ctrl`, responsáveis pelo armazenamento das marcas d'água e dos registros de execução.

## 4. Estrutura do projeto

```text
adventureworks-data-warehouse/
│
├── config/
│
├── dags/
│   ├── aw_dw_01_setup.py
│   ├── aw_dw_02_etl_incremental.py
│   │
│   └── sql/
│       ├── setup/
│       ├── extract/
│       └── load/
│
├── data/
│
├── diagrams/
│   └── star_schema.puml
│
├── docs/
│   ├── relatorio_tecnico.docx
│   └── prints/
│
├── oltp/
│   ├── 01_adventureworks_oltp.sql.gz
│   └── 02_ajustar_sequences.sql
│
├── plugins/
│
├── sql/
│   ├── kpis.sql
│   └── simular_alteracoes_oltp.sql
│
├── .env.example
├── .gitignore
├── docker-compose.yml
└── README.md
```

## 5. Modelo dimensional

O Data Warehouse utiliza uma arquitetura Star Schema.

A tabela fato centraliza as informações das vendas, enquanto as dimensões fornecem o contexto necessário para as análises.

Entre as dimensões implementadas estão:

- Dimensão de data.
- Dimensão de cliente.
- Dimensão de produto.
- Dimensão de vendedor.
- Dimensão de território.
- Dimensão de promoção.
- Dimensão de método de envio.

**Tabela fato:** `dw.fato_vendas`

**Schemas utilizados:**

| Schema | Responsabilidade |
|---|---|
| `stg` | Armazenamento temporário dos dados extraídos |
| `dw` | Dimensões, tabela fato e indicadores |
| `ctrl` | Controle das marcas d'água e logs do ETL |

## 6. Como executar localmente com WSL2 (sem Docker)

O projeto foi executado em ambiente Ubuntu utilizando WSL2 no Windows, com PostgreSQL e Apache Airflow instalados diretamente no Linux.

### 6.1. Pré-requisitos

- Windows com WSL2 habilitado.
- Ubuntu instalado.
- Python 3.14.
- PostgreSQL.
- Apache Airflow 3.3.1.
- Provider PostgreSQL do Airflow.

### 6.2. Instalação do ambiente Python

Criar e ativar o ambiente virtual:

```bash
python3 -m venv ~/airflow_venv

source ~/airflow_venv/bin/activate
```

Instalar o Apache Airflow:

```bash
pip install "apache-airflow==3.3.1" \
--constraint "https://raw.githubusercontent.com/apache/airflow/constraints-3.3.1/constraints-3.14.txt"
```

Instalar o provider PostgreSQL:

```bash
pip install apache-airflow-providers-postgres
```

### 6.3. Configuração do PostgreSQL

Iniciar o serviço:

```bash
sudo service postgresql start
```

Criar os bancos necessários:

```sql
CREATE DATABASE adventureworks;
CREATE DATABASE adventureworks_dw;
CREATE DATABASE airflow;
```

Criar o usuário utilizado pelo Airflow:

```sql
CREATE USER airflow WITH PASSWORD 'SUA_SENHA';
```

Configurar as permissões do banco de metadados:

```sql
ALTER DATABASE airflow OWNER TO airflow;

\c airflow

GRANT ALL ON SCHEMA public TO airflow;
ALTER SCHEMA public OWNER TO airflow;
```

Configurar uma senha para o usuário PostgreSQL utilizado nas conexões do projeto:

```sql
ALTER USER postgres WITH PASSWORD 'SUA_SENHA';
```

As senhas devem ser definidas localmente e não devem ser publicadas no GitHub.

### 6.4. Importação do AdventureWorks OLTP

Na pasta raiz do projeto, descompactar o arquivo:

```bash
gunzip -k oltp/01_adventureworks_oltp.sql.gz
```

Importar os dados:

```bash
sudo -u postgres psql -d adventureworks \
-v ON_ERROR_STOP=1 \
-f oltp/01_adventureworks_oltp.sql
```

Ajustar as sequências:

```bash
sudo -u postgres psql -d adventureworks \
-v ON_ERROR_STOP=1 \
-f oltp/02_ajustar_sequences.sql
```

### 6.5. Configuração do Airflow

Definir o diretório e a conexão com o banco de metadados:

```bash
export AIRFLOW_HOME=~/airflow

export AIRFLOW__DATABASE__SQL_ALCHEMY_CONN="postgresql+psycopg2://airflow:SENHA@localhost:5432/airflow"
```

Inicializar as tabelas do Airflow:

```bash
airflow db migrate
```

Copiar as DAGs e os respectivos scripts SQL:

```bash
mkdir -p ~/airflow/dags

cp -r dags/*.py ~/airflow/dags/

cp -r dags/sql ~/airflow/dags/
```

### 6.6. Configuração das conexões

Na interface web do Airflow, acessar:

**Administração → Connections**

Cadastrar duas conexões do tipo PostgreSQL:

| Campo | `aw_oltp` | `aw_dw` |
|---|---|---|
| Connection Id | `aw_oltp` | `aw_dw` |
| Host | `127.0.0.1` | `127.0.0.1` |
| Database | `adventureworks` | `adventureworks_dw` |
| Login | `postgres` | `postgres` |
| Password | Senha local | Senha local |
| Port | `5432` | `5432` |

Os identificadores das conexões devem corresponder exatamente aos utilizados nas DAGs.

### 6.7. Inicialização dos serviços

O Airflow deve permanecer em execução enquanto as DAGs são utilizadas.

Abrir terminais Ubuntu separados, ativando o ambiente virtual e configurando as variáveis de ambiente em cada terminal.

Iniciar o servidor web:

```bash
airflow api-server --port 8080
```

Iniciar o Scheduler:

```bash
airflow scheduler
```

Iniciar o DAG Processor:

```bash
airflow dag-processor
```

Iniciar o Triggerer:

```bash
airflow triggerer
```

Acessar a interface:

http://localhost:8080

A autenticação depende da configuração local do Airflow.

## 7. Execução das DAGs

O projeto possui duas DAGs principais.

### DAG 01 — Setup do Data Warehouse

`aw_dw_01_setup`

Responsável pela criação da estrutura do Data Warehouse:

1. Criação dos schemas de controle e staging.
2. Criação da dimensão de data.
3. Criação das demais dimensões.
4. Criação da tabela fato.
5. Criação das views dos KPIs.

Executar inicialmente antes do processo de ETL.

### DAG 02 — ETL Incremental

`aw_dw_02_etl_incremental`

Responsável pela integração dos dados entre OLTP e DW.

O processo contempla:

1. Extração incremental das dimensões e vendas.
2. Armazenamento dos dados na staging.
3. Atualização das dimensões utilizando UPSERT (SCD Tipo 1).
4. Carga incremental da tabela fato.
5. Validação da reconciliação entre origem e destino.
6. Atualização das marcas d'água.
7. Registro das execuções em `ctrl.log_etl`.

A DAG utiliza `max_active_runs=1` para evitar execuções concorrentes que possam interferir na staging.

## 8. Estratégia de ETL incremental

A estratégia utiliza o mecanismo de marca d'água (*watermark*).

A tabela `ctrl.marca_dagua` armazena a última data de modificação processada para cada tabela.

O processo funciona da seguinte maneira:

| Etapa | Descrição |
|---|---|
| Identificação | Consulta a última marca d'água processada |
| Extração | Busca registros modificados após a marca |
| Staging | Armazena temporariamente somente o delta |
| Transformação | Atualiza dimensões e dados da fato |
| Validação | Compara quantidade de itens e receita entre OLTP e DW |
| Controle | Atualiza as marcas d'água e registra a execução |

A marca d'água somente é atualizada após a conclusão da validação.

Os processos de UPSERT permitem o reprocessamento seguro dos registros já identificados.

**Limitações conhecidas:**

- Exclusões físicas na origem não são detectadas diretamente pelo mecanismo incremental.
- As dimensões utilizam SCD Tipo 1, sem preservação do histórico de alterações dos atributos.

## 9. Indicadores de desempenho (KPIs)

O Data Warehouse disponibiliza dez indicadores por meio de views SQL no schema `dw`.

| Nº | View | Indicador |
|---|---|---|
| 01 | `vw_kpi01_receita_mensal` | Receita líquida e quantidade de pedidos por mês |
| 02 | `vw_kpi02_ticket_medio` | Ticket médio por ano e canal |
| 03 | `vw_kpi03_margem_categoria` | Margem bruta por categoria |
| 04 | `vw_kpi04_crescimento_mensal` | Crescimento mensal da receita |
| 05 | `vw_kpi05_receita_territorio` | Receita e participação por território |
| 06 | `vw_kpi06_top10_produtos` | Dez produtos com maior receita |
| 07 | `vw_kpi07_desempenho_vendedor` | Receita, pedidos, ticket médio e ranking por vendedor |
| 08 | `vw_kpi08_taxa_desconto` | Taxa de desconto |
| 09 | `vw_kpi09_participacao_canal` | Participação dos canais Online e Revenda |
| 10 | `vw_kpi10_taxa_recompra` | Percentual de clientes recorrentes |

Para consultar os indicadores:

```bash
sudo -u postgres psql -d adventureworks_dw
```

Exemplo:

```sql
SELECT * FROM dw.vw_kpi01_receita_mensal;

SELECT * FROM dw.vw_kpi02_ticket_medio;

SELECT * FROM dw.vw_kpi03_margem_categoria;
```

O arquivo `sql/kpis.sql` reúne consultas para análise dos indicadores e dos registros de controle do ETL.

## 10. Validação e resultados obtidos

Durante a execução local do projeto, foram realizados os seguintes testes:

- Importação do banco AdventureWorks OLTP.
- Criação da estrutura dimensional.
- Execução completa das duas DAGs.
- Processamento das dimensões e da tabela fato.
- Validação da reconciliação entre origem e destino.
- Consulta dos dez KPIs.
- Segunda execução do ETL incremental.

**Resultados observados no ambiente de execução:**

| Indicador | Resultado |
|---|---:|
| Itens de venda no Data Warehouse | 121.317 |
| Receita líquida total | R$ 109.846.381,43 |
| Views de KPIs com registros | 10 |
| DAGs principais executadas com sucesso | 2 |

Na segunda execução do ETL, a quantidade de registros e a receita total permaneceram iguais aos valores anteriores:

- Antes: 121.317 itens.
- Depois: 121.317 itens.
- Receita antes: R$ 109.846.381,43.
- Receita depois: R$ 109.846.381,43.

Esses resultados demonstram que o reprocessamento foi concluído sem duplicação observável na tabela fato e sem alteração da receita total.

## 11. Execução alternativa com Docker

O repositório também disponibiliza `docker-compose.yml` e `.env.example` para execução utilizando Docker Compose.

Para utilizar essa alternativa:

```bash
cp .env.example .env

docker compose up airflow-init

docker compose up -d
```

Acompanhar os serviços:

```bash
docker compose ps
```

A execução com Docker utiliza os serviços e portas definidos no arquivo `docker-compose.yml`.

## 12. Origem dos dados

O banco AdventureWorks utilizado neste projeto foi baseado nos dados do AdventureWorks 2014 OLTP.

O arquivo compactado está disponível em:

`oltp/01_adventureworks_oltp.sql.gz`

A conversão da base para PostgreSQL utiliza como referência o projeto:

[AdventureWorks for PostgreSQL](https://github.com/lorint/AdventureWorks-for-Postgres)

## 13. Documentação e evidências

A documentação complementar está organizada no diretório `docs/`.

Recomenda-se incluir:

- Diagrama do modelo estrela.
- Capturas das DAGs concluídas.
- Evidências das consultas SQL.
- Resultados dos dez KPIs.
- Evidência da reconciliação.
- Resultados do teste de reprocessamento.

---

## Autor - Gabriel Fiorio

Projeto acadêmico desenvolvido como atividade de estudo de Data Warehouse, ETL, modelagem dimensional e Business Intelligence.

**Repositório:** [github.com/gabfiorio/adventureworks-data-warehouse](https://github.com/gabfiorio/adventureworks-data-warehouse)
