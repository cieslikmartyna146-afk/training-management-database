# Training Management Database System
*System Bazy Danych do Zarządzania Szkoleniami*

[English](#english) | [Polski](#polski)

---

<a name="english"></a>
## 🇬🇧 English Version

### Overview

Hybrid database system for training management company built with SQL Server 2022. Combines relational model with non-relational extensions (JSON, Spatial Data, Full-Text Search, Columnstore Index).

### 🎯 Features

- **Client Management** - individual & corporate clients, automatic discounts (10%/15%), soft delete
- **Hierarchical Products** - modules → trainings → courses (recursive CTE)
- **Orders & Participants** - status workflow, change history, certificates
- **Reviews & Moderation** - 1-5 star ratings, company responses, Full-Text Search
- **Multi-layer Security** - 4 roles (Sales, Trainer, SocialMedia, Manager), SQL Server Audit (GDPR compliance)
- **Automation** - SQL Agent Jobs (FULL/DIFF/LOG backups, CHECKDB, statistics, index maintenance)

### 🛠️ Technologies

- **SQL Server 2022** (Developer Edition)
- **JSON** - flexible data (surveys, technical requirements)
- **GEOGRAPHY (Spatial)** - GPS locations, distance calculations (STDistance)
- **Full-Text Search** - 10-100x faster than LIKE
- **Columnstore Index** - 10-100x faster analytical aggregations
- **Triggers** - business logic automation (10 triggers)
- **Indexed View** - JOIN materialization for performance

### 📊 Statistics

- **Tables:** 10
- **Indexes:** ~40 (3 Full-Text, 2 Spatial, 1 Columnstore, ~34 B-tree)
- **Views:** 6 (including indexed view with columnstore)
- **Triggers:** 10 (UpdatedAt, StatusChange, Rating, TotalValue)
- **Security Roles:** 4
- **SQL Agent Jobs:** 4 (backup, maintenance)
- **Code:** ~2000 lines of SQL across 9 scripts

### 🚀 Installation

#### Prerequisites
- SQL Server 2019+ (recommended: 2022 Developer Edition - free)
- SQL Server Management Studio (SSMS)
- Components: Full-Text Search, SQL Server Agent

#### Setup

1. **Run scripts in order:**
