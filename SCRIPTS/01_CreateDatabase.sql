/* =============================================
   01_CreateDatabase.sql
   Tworzenie bazy danych projektu szkoleniowego
   ============================================= */

USE master;
GO

-- Zamknij wszystkie połączenia i usuń bazę, jeśli istnieje
IF DB_ID('TrainingSystemDB') IS NOT NULL
BEGIN
    ALTER DATABASE TrainingSystemDB
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    
    DROP DATABASE TrainingSystemDB;
END
GO

-- Utworzenie nowej bazy danych
CREATE DATABASE TrainingSystemDB;
GO

-- Ustawienia podstawowe bazy
ALTER DATABASE TrainingSystemDB SET RECOVERY FULL;
ALTER DATABASE TrainingSystemDB SET AUTO_UPDATE_STATISTICS ON;
ALTER DATABASE TrainingSystemDB SET AUTO_CREATE_STATISTICS ON;
GO

-- Przejście do nowej bazy
USE TrainingSystemDB;
GO