-- =============================================
-- ZADANIA KONSERWACYJNE - SQL SERVER AGENT JOBS
-- Skrypt: 08_CreateMaintenanceJobs.sql
-- =============================================

USE msdb;
GO

-- =============================================
-- JOB 1: WeeklyMaintenance
-- Harmonogram: Niedziela 01:00
-- Zadania: DBCC CHECKDB, FULL Backup, Cleanup
-- =============================================

-- Usuń job jeśli istnieje
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = 'TrainingDB_WeeklyMaintenance')
    EXEC msdb.dbo.sp_delete_job @job_name = 'TrainingDB_WeeklyMaintenance';
GO

-- Utworzenie job
EXEC msdb.dbo.sp_add_job
    @job_name = N'TrainingDB_WeeklyMaintenance',
    @enabled = 1,
    @description = N'Cotygodniowa konserwacja: CHECKDB, FULL Backup, czyszczenie starych kopii';
GO

-- Krok 1: DBCC CHECKDB (sprawdzenie integralności)
EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'TrainingDB_WeeklyMaintenance',
    @step_name = N'DBCC CHECKDB',
    @subsystem = N'TSQL',
    @command = N'
USE TrainingSystemDB;
DBCC CHECKDB (TrainingSystemDB) WITH NO_INFOMSGS, ALL_ERRORMSGS;
PRINT ''DBCC CHECKDB wykonany - '' + CONVERT(VARCHAR, GETDATE(), 120);
',
    @on_success_action = 3, -- Go to next step
    @on_fail_action = 2;    -- Quit with failure
GO

-- Krok 2: FULL Backup
EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'TrainingDB_WeeklyMaintenance',
    @step_name = N'FULL Backup',
    @subsystem = N'TSQL',
    @command = N'
DECLARE @BackupPath NVARCHAR(500);
DECLARE @FileName NVARCHAR(500);
SET @BackupPath = ''C:\SQLBackup\TrainingSystem\'';
SET @FileName = @BackupPath + ''TrainingSystemDB_FULL_'' + CONVERT(VARCHAR, GETDATE(), 112) + ''_'' + REPLACE(CONVERT(VARCHAR, GETDATE(), 108), '':'', '''') + ''.bak'';

-- Utworzenie folderu jeśli nie istnieje
EXEC xp_cmdshell ''IF NOT EXIST "C:\SQLBackup\TrainingSystem\" MKDIR "C:\SQLBackup\TrainingSystem\"'', NO_OUTPUT;

BACKUP DATABASE TrainingSystemDB
TO DISK = @FileName
WITH COMPRESSION, CHECKSUM, STATS = 10;

PRINT ''FULL Backup utworzony: '' + @FileName;
',
    @on_success_action = 3,
    @on_fail_action = 2;
GO

-- Krok 3: Cleanup starych backupów (starsze niż 4 tygodnie)
EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'TrainingDB_WeeklyMaintenance',
    @step_name = N'Cleanup Old Backups',
    @subsystem = N'TSQL',
    @command = N'
EXEC xp_cmdshell ''forfiles /p "C:\SQLBackup\TrainingSystem" /s /m *.bak /d -28 /c "cmd /c del @path"'', NO_OUTPUT;
PRINT ''Stare backupy (>28 dni) usunięte.'';
',
    @on_success_action = 1; -- Quit with success
GO

-- Harmonogram: Niedziela 01:00
EXEC msdb.dbo.sp_add_jobschedule
    @job_name = N'TrainingDB_WeeklyMaintenance',
    @name = N'Weekly_Sunday_1AM',
    @freq_type = 8,        -- Weekly
    @freq_interval = 1,    -- Sunday
    @freq_recurrence_factor = 1,
    @active_start_time = 010000; -- 01:00:00
GO

-- Przypisanie do lokalnego serwera
EXEC msdb.dbo.sp_add_jobserver
    @job_name = N'TrainingDB_WeeklyMaintenance',
    @server_name = N'(local)';
GO

PRINT 'Job TrainingDB_WeeklyMaintenance utworzony.';
GO

-- =============================================
-- JOB 2: DailyMaintenance
-- Harmonogram: Codziennie 02:00
-- Zadania: DIFFERENTIAL Backup, UPDATE STATISTICS
-- =============================================

IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = 'TrainingDB_DailyMaintenance')
    EXEC msdb.dbo.sp_delete_job @job_name = 'TrainingDB_DailyMaintenance';
GO

EXEC msdb.dbo.sp_add_job
    @job_name = N'TrainingDB_DailyMaintenance',
    @enabled = 1,
    @description = N'Codzienna konserwacja: DIFFERENTIAL Backup, aktualizacja statystyk';
GO

-- Krok 1: DIFFERENTIAL Backup
EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'TrainingDB_DailyMaintenance',
    @step_name = N'DIFFERENTIAL Backup',
    @subsystem = N'TSQL',
    @command = N'
DECLARE @BackupPath NVARCHAR(500);
DECLARE @FileName NVARCHAR(500);
SET @BackupPath = ''C:\SQLBackup\TrainingSystem\'';
SET @FileName = @BackupPath + ''TrainingSystemDB_DIFF_'' + CONVERT(VARCHAR, GETDATE(), 112) + ''_'' + REPLACE(CONVERT(VARCHAR, GETDATE(), 108), '':'', '''') + ''.bak'';

BACKUP DATABASE TrainingSystemDB
TO DISK = @FileName
WITH DIFFERENTIAL, COMPRESSION, CHECKSUM, STATS = 10;

PRINT ''DIFFERENTIAL Backup utworzony: '' + @FileName;
',
    @on_success_action = 3,
    @on_fail_action = 2;
GO

-- Krok 2: UPDATE STATISTICS
EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'TrainingDB_DailyMaintenance',
    @step_name = N'UPDATE STATISTICS',
    @subsystem = N'TSQL',
    @command = N'
USE TrainingSystemDB;

-- Full scan dla kluczowych tabel
UPDATE STATISTICS Clients WITH FULLSCAN;
UPDATE STATISTICS Orders WITH FULLSCAN;
UPDATE STATISTICS OrderItems WITH FULLSCAN;
UPDATE STATISTICS Products WITH FULLSCAN;

-- Sampled dla mniejszych tabel
UPDATE STATISTICS Participants WITH SAMPLE 50 PERCENT;
UPDATE STATISTICS Trainers WITH SAMPLE 50 PERCENT;
UPDATE STATISTICS Reviews WITH SAMPLE 50 PERCENT;

PRINT ''Statystyki zaktualizowane - '' + CONVERT(VARCHAR, GETDATE(), 120);
',
    @on_success_action = 1;
GO

-- Harmonogram: Codziennie 02:00
EXEC msdb.dbo.sp_add_jobschedule
    @job_name = N'TrainingDB_DailyMaintenance',
    @name = N'Daily_2AM',
    @freq_type = 4,        -- Daily
    @freq_interval = 1,
    @active_start_time = 020000; -- 02:00:00
GO

EXEC msdb.dbo.sp_add_jobserver
    @job_name = N'TrainingDB_DailyMaintenance',
    @server_name = N'(local)';
GO

PRINT 'Job TrainingDB_DailyMaintenance utworzony.';
GO

-- =============================================
-- JOB 3: HourlyLogBackup
-- Harmonogram: Co 2 godziny
-- Zadania: Transaction Log Backup
-- =============================================

IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = 'TrainingDB_HourlyLogBackup')
    EXEC msdb.dbo.sp_delete_job @job_name = 'TrainingDB_HourlyLogBackup';
GO

EXEC msdb.dbo.sp_add_job
    @job_name = N'TrainingDB_HourlyLogBackup',
    @enabled = 1,
    @description = N'Backup logu transakcji co 2 godziny (RPO = 2h)';
GO

-- Krok 1: LOG Backup
EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'TrainingDB_HourlyLogBackup',
    @step_name = N'LOG Backup',
    @subsystem = N'TSQL',
    @command = N'
DECLARE @BackupPath NVARCHAR(500);
DECLARE @FileName NVARCHAR(500);
SET @BackupPath = ''C:\SQLBackup\TrainingSystem\'';
SET @FileName = @BackupPath + ''TrainingSystemDB_LOG_'' + CONVERT(VARCHAR, GETDATE(), 112) + ''_'' + REPLACE(CONVERT(VARCHAR, GETDATE(), 108), '':'', '''') + ''.trn'';

BACKUP LOG TrainingSystemDB
TO DISK = @FileName
WITH COMPRESSION, CHECKSUM, STATS = 10;

PRINT ''LOG Backup utworzony: '' + @FileName;
',
    @on_success_action = 1;
GO

-- Harmonogram: Co 2 godziny
EXEC msdb.dbo.sp_add_jobschedule
    @job_name = N'TrainingDB_HourlyLogBackup',
    @name = N'Every_2_Hours',
    @freq_type = 4,        -- Daily
    @freq_interval = 1,
    @freq_subday_type = 8, -- Hours
    @freq_subday_interval = 2, -- Every 2 hours
    @active_start_time = 000000;
GO

EXEC msdb.dbo.sp_add_jobserver
    @job_name = N'TrainingDB_HourlyLogBackup',
    @server_name = N'(local)';
GO

PRINT 'Job TrainingDB_HourlyLogBackup utworzony.';
GO

-- =============================================
-- JOB 4: WeeklyIndexMaintenance
-- Harmonogram: Sobota 01:00
-- Zadania: Rebuild/Reorganize indeksów
-- =============================================

IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = 'TrainingDB_IndexMaintenance')
    EXEC msdb.dbo.sp_delete_job @job_name = 'TrainingDB_IndexMaintenance';
GO

EXEC msdb.dbo.sp_add_job
    @job_name = N'TrainingDB_IndexMaintenance',
    @enabled = 1,
    @description = N'Cotygodniowa defragmentacja indeksów (rebuild >30%, reorganize 10-30%)';
GO

-- Krok 1: Index Maintenance
EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'TrainingDB_IndexMaintenance',
    @step_name = N'Rebuild and Reorganize Indexes',
    @subsystem = N'TSQL',
    @command = N'
USE TrainingSystemDB;

DECLARE @TableName NVARCHAR(128);
DECLARE @IndexName NVARCHAR(128);
DECLARE @Fragmentation FLOAT;
DECLARE @SQL NVARCHAR(MAX);

DECLARE IndexCursor CURSOR FOR
SELECT 
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, ''LIMITED'') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent > 10
  AND ips.page_count > 1000 -- tylko większe indeksy
  AND i.name IS NOT NULL;

OPEN IndexCursor;
FETCH NEXT FROM IndexCursor INTO @TableName, @IndexName, @Fragmentation;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @Fragmentation > 30
    BEGIN
        SET @SQL = ''ALTER INDEX ['' + @IndexName + ''] ON ['' + @TableName + ''] REBUILD WITH (ONLINE = OFF);'';
        PRINT ''REBUILD: '' + @TableName + ''.'' + @IndexName + '' ('' + CAST(@Fragmentation AS VARCHAR) + ''%)'';
    END
    ELSE
    BEGIN
        SET @SQL = ''ALTER INDEX ['' + @IndexName + ''] ON ['' + @TableName + ''] REORGANIZE;'';
        PRINT ''REORGANIZE: '' + @TableName + ''.'' + @IndexName + '' ('' + CAST(@Fragmentation AS VARCHAR) + ''%)'';
    END
    
    EXEC sp_executesql @SQL;
    
    FETCH NEXT FROM IndexCursor INTO @TableName, @IndexName, @Fragmentation;
END

CLOSE IndexCursor;
DEALLOCATE IndexCursor;

PRINT ''Index Maintenance zakończony - '' + CONVERT(VARCHAR, GETDATE(), 120);
',
    @on_success_action = 1;
GO

-- Harmonogram: Sobota 01:00
EXEC msdb.dbo.sp_add_jobschedule
    @job_name = N'TrainingDB_IndexMaintenance',
    @name = N'Weekly_Saturday_1AM',
    @freq_type = 8,        -- Weekly
    @freq_interval = 64,   -- Saturday
    @freq_recurrence_factor = 1,
    @active_start_time = 010000;
GO

EXEC msdb.dbo.sp_add_jobserver
    @job_name = N'TrainingDB_IndexMaintenance',
    @server_name = N'(local)';
GO

PRINT 'Job TrainingDB_IndexMaintenance utworzony.';
GO

-- =============================================
-- WŁĄCZENIE xp_cmdshell (wymagane dla backupów)
-- =============================================

USE master;
GO

EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;
GO

PRINT 'xp_cmdshell włączony (wymagany dla tworzenia folderów backup).';
GO

-- =============================================
-- KONIEC TWORZENIA JOBÓW
-- =============================================

PRINT '';
PRINT '========================================';
PRINT 'PODSUMOWANIE SQL AGENT JOBS:';
PRINT '- TrainingDB_WeeklyMaintenance (Niedziela 01:00)';
PRINT '- TrainingDB_DailyMaintenance (Codziennie 02:00)';
PRINT '- TrainingDB_HourlyLogBackup (Co 2h)';
PRINT '- TrainingDB_IndexMaintenance (Sobota 01:00)';
PRINT '';
PRINT 'Backupy zapisywane w: C:\SQLBackup\TrainingSystem\';
PRINT 'Retencja: FULL=28 dni, DIFF=7 dni, LOG=7 dni';
PRINT 'RPO (Recovery Point Objective): 2 godziny';
PRINT '========================================';
GO