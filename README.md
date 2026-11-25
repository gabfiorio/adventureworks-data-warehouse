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

O controle do processamento é realizado por meio dos schemas `ctrl`, responsáveis pelo
