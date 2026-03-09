-- =============================================
-- KONFIGURACJA BEZPIECZEŃSTWA - SYSTEM ZARZĄDZANIA SZKOLENIAMI
-- Skrypt: 07_CreateSecurity.sql
-- =============================================

USE TrainingSystemDB;
GO

-- =============================================
-- CZĘŚĆ 1: TWORZENIE RÓL
-- =============================================

-- Rola: SalesRole (Sprzedawca)
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'SalesRole' AND type = 'R')
BEGIN
    CREATE ROLE SalesRole;
    PRINT 'Rola SalesRole utworzona.';
END
GO

-- Rola: TrainerRole (Trener)
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'TrainerRole' AND type = 'R')
BEGIN
    CREATE ROLE TrainerRole;
    PRINT 'Rola TrainerRole utworzona.';
END
GO

-- Rola: SocialMediaRole (Specjalista ds. mediów społecznościowych)
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'SocialMediaRole' AND type = 'R')
BEGIN
    CREATE ROLE SocialMediaRole;
    PRINT 'Rola SocialMediaRole utworzona.';
END
GO

-- Rola: ManagerRole (Kierownik)
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'ManagerRole' AND type = 'R')
BEGIN
    CREATE ROLE ManagerRole;
    PRINT 'Rola ManagerRole utworzona.';
END
GO

-- =============================================
-- CZĘŚĆ 2: UPRAWNIENIA DLA SalesRole
-- =============================================

-- SELECT, INSERT, UPDATE na wszystkich głównych tabelach (z wyjątkiem Reviews)
GRANT SELECT, INSERT, UPDATE ON Clients TO SalesRole;
GRANT SELECT, INSERT, UPDATE ON Participants TO SalesRole;
GRANT SELECT, INSERT, UPDATE ON Trainers TO SalesRole;
GRANT SELECT, INSERT, UPDATE ON Products TO SalesRole;
GRANT SELECT, INSERT, UPDATE ON ProductHierarchy TO SalesRole;
GRANT SELECT, INSERT, UPDATE ON Orders TO SalesRole;
GRANT SELECT, INSERT, UPDATE ON OrderItems TO SalesRole;
GRANT SELECT, INSERT, UPDATE ON OrderParticipants TO SalesRole;
GRANT SELECT ON OrderStatusHistory TO SalesRole; -- tylko odczyt historii

-- DENY na Reviews (konflikt interesów - sprzedawcy nie widzą opinii)
DENY SELECT, INSERT, UPDATE, DELETE ON Reviews TO SalesRole;

-- Uprawnienia do widoków
GRANT SELECT ON vw_ActiveProducts TO SalesRole;
GRANT SELECT ON vw_ClientSummary TO SalesRole;
GRANT SELECT ON vw_TrainerWorkload TO SalesRole;
GRANT SELECT ON vw_OrderAnalytics TO SalesRole;
GRANT SELECT ON vw_ProductHierarchy_Expanded TO SalesRole;

PRINT 'Uprawnienia dla SalesRole przyznane.';
GO

-- =============================================
-- CZĘŚĆ 3: UPRAWNIENIA DLA TrainerRole
-- =============================================

-- Trenerzy mają dostęp tylko do:
-- - Katalogu produktów (readonly)
-- - Swoich zamówień (bez cen) przez widok vw_Orders_ForTrainers
-- - Uczestników swoich szkoleń (readonly przez widok)

GRANT SELECT ON Products TO TrainerRole;
GRANT SELECT ON ProductHierarchy TO TrainerRole;
GRANT SELECT ON vw_ActiveProducts TO TrainerRole;
GRANT SELECT ON vw_ProductHierarchy_Expanded TO TrainerRole;

-- Widok zamówień dla trenerów (bez cen i rabatów)
GRANT SELECT ON vw_Orders_ForTrainers TO TrainerRole;

-- Uczestnicy - tylko tych szkoleń które prowadzą
GRANT SELECT ON Participants TO TrainerRole;
GRANT SELECT ON OrderParticipants TO TrainerRole;

-- DENY na wszystko inne (jawnie blokujemy dostęp do wrażliwych danych)
DENY SELECT, INSERT, UPDATE, DELETE ON Clients TO TrainerRole;
DENY SELECT, INSERT, UPDATE, DELETE ON Orders TO TrainerRole; -- bezpośredni dostęp zabroniony (tylko przez widok)
DENY SELECT, INSERT, UPDATE, DELETE ON OrderItems TO TrainerRole;
DENY SELECT, INSERT, UPDATE, DELETE ON Reviews TO TrainerRole;
DENY SELECT, INSERT, UPDATE, DELETE ON OrderStatusHistory TO TrainerRole;
DENY SELECT ON vw_ClientSummary TO TrainerRole;
DENY SELECT ON vw_OrderAnalytics TO TrainerRole;

PRINT 'Uprawnienia dla TrainerRole przyznane.';
GO

-- =============================================
-- CZĘŚĆ 4: UPRAWNIENIA DLA SocialMediaRole
-- =============================================

-- Dostęp do opinii (pełny) i danych klientów (ograniczony)
GRANT SELECT, UPDATE ON Reviews TO SocialMediaRole; -- UPDATE dla moderacji i odpowiedzi firmy
GRANT SELECT ON Clients TO SocialMediaRole; -- dane kontaktowe dla komunikacji

-- Widoki pomocnicze
GRANT SELECT ON vw_ClientSummary TO SocialMediaRole;

-- Produkty (readonly - dla kontekstu opinii)
GRANT SELECT ON Products TO SocialMediaRole;
GRANT SELECT ON vw_ActiveProducts TO SocialMediaRole;

-- DENY na wrażliwe dane
DENY SELECT, INSERT, UPDATE, DELETE ON Orders TO SocialMediaRole;
DENY SELECT, INSERT, UPDATE, DELETE ON OrderItems TO SocialMediaRole;
DENY SELECT, INSERT, UPDATE, DELETE ON Trainers TO SocialMediaRole;
DENY SELECT ON vw_OrderAnalytics TO SocialMediaRole;

PRINT 'Uprawnienia dla SocialMediaRole przyznane.';
GO

-- =============================================
-- CZĘŚĆ 5: UPRAWNIENIA DLA ManagerRole
-- =============================================

-- Kierownik: SELECT na wszystkim, DENY na modyfikacje
GRANT SELECT ON Clients TO ManagerRole;
GRANT SELECT ON Participants TO ManagerRole;
GRANT SELECT ON Trainers TO ManagerRole;
GRANT SELECT ON Products TO ManagerRole;
GRANT SELECT ON ProductHierarchy TO ManagerRole;
GRANT SELECT ON Orders TO ManagerRole;
GRANT SELECT ON OrderItems TO ManagerRole;
GRANT SELECT ON OrderParticipants TO ManagerRole;
GRANT SELECT ON Reviews TO ManagerRole;
GRANT SELECT ON OrderStatusHistory TO ManagerRole;

-- Wszystkie widoki
GRANT SELECT ON vw_Orders_ForTrainers TO ManagerRole;
GRANT SELECT ON vw_ActiveProducts TO ManagerRole;
GRANT SELECT ON vw_ClientSummary TO ManagerRole;
GRANT SELECT ON vw_TrainerWorkload TO ManagerRole;
GRANT SELECT ON vw_OrderAnalytics TO ManagerRole;
GRANT SELECT ON vw_ProductHierarchy_Expanded TO ManagerRole;

-- DENY na modyfikacje (segregacja obowiązków)
DENY INSERT, UPDATE, DELETE ON Clients TO ManagerRole;
DENY INSERT, UPDATE, DELETE ON Participants TO ManagerRole;
DENY INSERT, UPDATE, DELETE ON Trainers TO ManagerRole;
DENY INSERT, UPDATE, DELETE ON Products TO ManagerRole;
DENY INSERT, UPDATE, DELETE ON ProductHierarchy TO ManagerRole;
DENY INSERT, UPDATE, DELETE ON Orders TO ManagerRole;
DENY INSERT, UPDATE, DELETE ON OrderItems TO ManagerRole;
DENY INSERT, UPDATE, DELETE ON OrderParticipants TO ManagerRole;
DENY INSERT, UPDATE, DELETE ON Reviews TO ManagerRole;

PRINT 'Uprawnienia dla ManagerRole przyznane.';
GO

-- =============================================
-- CZĘŚĆ 6: ROW-LEVEL SECURITY (RLS)
-- POMIJAMY - konflikt z indexed view vw_OrderAnalytics
-- Zamiast tego trenerzy używają widoku vw_Orders_ForTrainers
-- =============================================

PRINT 'Row-Level Security: pominięte z powodu konfliktu z indexed view.';
PRINT 'Trenerzy używają widoku vw_Orders_ForTrainers zamiast bezpośredniego dostępu do Orders.';
GO

-- =============================================
-- CZĘŚĆ 7: SQL SERVER AUDIT
-- Audyt dostępu do danych osobowych (RODO)
-- =============================================

-- Krok 0: Utworzenie folderu dla audytu (xp_cmdshell)
USE master;
GO

-- Włączenie xp_cmdshell (tymczasowo)
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;
GO

-- Utworzenie folderu (jeśli nie istnieje)
DECLARE @cmd NVARCHAR(500);
SET @cmd = 'IF NOT EXIST "C:\SQLAudit\TrainingSystem\" MKDIR "C:\SQLAudit\TrainingSystem\"';
EXEC xp_cmdshell @cmd, NO_OUTPUT;
GO

-- Wyłączenie xp_cmdshell (bezpieczeństwo)
EXEC sp_configure 'xp_cmdshell', 0;
RECONFIGURE;
EXEC sp_configure 'show advanced options', 0;
RECONFIGURE;
GO

PRINT 'Folder C:\SQLAudit\TrainingSystem\ utworzony.';
GO

-- Krok 1: Utworzenie Server Audit (na poziomie serwera)
IF NOT EXISTS (SELECT 1 FROM sys.server_audits WHERE name = 'TrainingSystemAudit')
BEGIN
    CREATE SERVER AUDIT TrainingSystemAudit
    TO FILE 
    (
        FILEPATH = 'C:\SQLAudit\TrainingSystem\',
        MAXSIZE = 100 MB,
        MAX_ROLLOVER_FILES = 10,
        RESERVE_DISK_SPACE = OFF
    )
    WITH 
    (
        QUEUE_DELAY = 1000,
        ON_FAILURE = CONTINUE
    );
    
    ALTER SERVER AUDIT TrainingSystemAudit WITH (STATE = ON);
    PRINT 'Server Audit TrainingSystemAudit utworzony i włączony.';
END
ELSE
BEGIN
    PRINT 'Server Audit TrainingSystemAudit już istnieje.';
END
GO

-- Krok 2: Utworzenie Database Audit Specification (na poziomie bazy)
USE TrainingSystemDB;
GO

-- Specyfikacja 1: Audyt dostępu do danych osobowych (Clients, Participants)
IF NOT EXISTS (SELECT 1 FROM sys.database_audit_specifications WHERE name = 'PersonalDataAccessAudit')
BEGIN
    CREATE DATABASE AUDIT SPECIFICATION PersonalDataAccessAudit
    FOR SERVER AUDIT TrainingSystemAudit
    ADD (SELECT ON Clients BY public),
    ADD (SELECT ON Participants BY public)
    WITH (STATE = ON);
    PRINT 'Audit Specification: PersonalDataAccessAudit utworzona.';
END
ELSE
BEGIN
    PRINT 'Audit Specification: PersonalDataAccessAudit już istnieje.';
END
GO

-- Specyfikacja 2: Audyt operacji na opiniach (dane wrażliwe biznesowo)
IF NOT EXISTS (SELECT 1 FROM sys.database_audit_specifications WHERE name = 'ReviewsAccessAudit')
BEGIN
    CREATE DATABASE AUDIT SPECIFICATION ReviewsAccessAudit
    FOR SERVER AUDIT TrainingSystemAudit
    ADD (SELECT ON Reviews BY public),
    ADD (UPDATE ON Reviews BY public),
    ADD (DELETE ON Reviews BY public)
    WITH (STATE = ON);
    PRINT 'Audit Specification: ReviewsAccessAudit utworzona.';
END
ELSE
BEGIN
    PRINT 'Audit Specification: ReviewsAccessAudit już istnieje.';
END
GO

-- Specyfikacja 3: Audyt nieudanych prób dostępu (wykrywanie ataków)
IF NOT EXISTS (SELECT 1 FROM sys.database_audit_specifications WHERE name = 'FailedAccessAudit')
BEGIN
    CREATE DATABASE AUDIT SPECIFICATION FailedAccessAudit
    FOR SERVER AUDIT TrainingSystemAudit
    ADD (FAILED_DATABASE_AUTHENTICATION_GROUP)
    WITH (STATE = ON);
    PRINT 'Audit Specification: FailedAccessAudit utworzona.';
END
ELSE
BEGIN
    PRINT 'Audit Specification: FailedAccessAudit już istnieje.';
END
GO

-- =============================================
-- KONIEC KONFIGURACJI BEZPIECZEŃSTWA
-- =============================================

PRINT '';
PRINT '========================================';
PRINT 'PODSUMOWANIE BEZPIECZEŃSTWA:';
PRINT '- 4 role: SalesRole, TrainerRole, SocialMediaRole, ManagerRole';
PRINT '- Uprawnienia GRANT/DENY dla każdej roli';
PRINT '- Row-Level Security: pominięte (konflikt z indexed view)';
PRINT '  Trenerzy używają widoku vw_Orders_ForTrainers zamiast RLS';
PRINT '- SQL Server Audit: 3 specyfikacje (dane osobowe, opinie, failed access)';
PRINT '- Logi audytu: C:\SQLAudit\TrainingSystem\';
PRINT '- Folder audytu utworzony automatycznie';
PRINT '========================================';
GO