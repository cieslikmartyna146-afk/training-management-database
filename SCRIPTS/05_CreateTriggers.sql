-- =============================================
-- TWORZENIE TRIGGERÓW - SYSTEM ZARZĄDZANIA SZKOLENIAMI
-- Skrypt: 05_CreateTriggers.sql (POPRAWIONY - bez rekurencji)
-- =============================================

USE TrainingSystemDB;
GO

-- =============================================
-- WYŁĄCZENIE REKURENCYJNYCH TRIGGERÓW (bezpieczeństwo)
-- =============================================
-- Ustawiamy opcję bazy żeby triggery nie wywoływały się rekurencyjnie
ALTER DATABASE TrainingSystemDB SET RECURSIVE_TRIGGERS OFF;
GO

-- =============================================
-- TRIGGER 1: Automatyczna aktualizacja UpdatedAt
-- =============================================

-- Clients
IF OBJECT_ID('trg_Clients_UpdatedAt', 'TR') IS NOT NULL
    DROP TRIGGER trg_Clients_UpdatedAt;
GO

CREATE TRIGGER trg_Clients_UpdatedAt
ON Clients
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Aktualizuj tylko jeśli UpdatedAt nie był częścią UPDATE
    IF NOT UPDATE(UpdatedAt)
    BEGIN
        UPDATE Clients
        SET UpdatedAt = GETDATE()
        WHERE ClientID IN (SELECT ClientID FROM inserted);
    END
END;
GO

-- Participants
IF OBJECT_ID('trg_Participants_UpdatedAt', 'TR') IS NOT NULL
    DROP TRIGGER trg_Participants_UpdatedAt;
GO

CREATE TRIGGER trg_Participants_UpdatedAt
ON Participants
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT UPDATE(UpdatedAt)
    BEGIN
        UPDATE Participants
        SET UpdatedAt = GETDATE()
        WHERE ParticipantID IN (SELECT ParticipantID FROM inserted);
    END
END;
GO

-- Trainers
IF OBJECT_ID('trg_Trainers_UpdatedAt', 'TR') IS NOT NULL
    DROP TRIGGER trg_Trainers_UpdatedAt;
GO

CREATE TRIGGER trg_Trainers_UpdatedAt
ON Trainers
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT UPDATE(UpdatedAt)
    BEGIN
        UPDATE Trainers
        SET UpdatedAt = GETDATE()
        WHERE TrainerID IN (SELECT TrainerID FROM inserted);
    END
END;
GO

-- Products
IF OBJECT_ID('trg_Products_UpdatedAt', 'TR') IS NOT NULL
    DROP TRIGGER trg_Products_UpdatedAt;
GO

CREATE TRIGGER trg_Products_UpdatedAt
ON Products
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT UPDATE(UpdatedAt)
    BEGIN
        UPDATE Products
        SET UpdatedAt = GETDATE()
        WHERE ProductID IN (SELECT ProductID FROM inserted);
    END
END;
GO

-- Orders - SPECJALNA WERSJA (unika konfliktu z trg_Order_StatusChange)
IF OBJECT_ID('trg_Orders_UpdatedAt', 'TR') IS NOT NULL
    DROP TRIGGER trg_Orders_UpdatedAt;
GO

CREATE TRIGGER trg_Orders_UpdatedAt
ON Orders
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Aktualizuj tylko jeśli UpdatedAt, ActualStartDate i ActualEndDate NIE były częścią UPDATE
    -- (unikamy konfliktu z trg_Order_StatusChange który ustawia ActualStartDate/ActualEndDate)
    IF NOT UPDATE(UpdatedAt) AND NOT UPDATE(ActualStartDate) AND NOT UPDATE(ActualEndDate)
    BEGIN
        UPDATE Orders
        SET UpdatedAt = GETDATE()
        WHERE OrderID IN (SELECT OrderID FROM inserted);
    END
END;
GO

-- Reviews
IF OBJECT_ID('trg_Reviews_UpdatedAt', 'TR') IS NOT NULL
    DROP TRIGGER trg_Reviews_UpdatedAt;
GO

CREATE TRIGGER trg_Reviews_UpdatedAt
ON Reviews
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT UPDATE(UpdatedAt)
    BEGIN
        UPDATE Reviews
        SET UpdatedAt = GETDATE()
        WHERE ReviewID IN (SELECT ReviewID FROM inserted);
    END
END;
GO

PRINT 'Triggery UpdatedAt utworzone (z ochroną przed rekurencją).';
GO

-- =============================================
-- TRIGGER 2: Logowanie zmian statusu zamówienia
-- ZMIENIONY - ustawia UpdatedAt ręcznie żeby uniknąć wywołania trg_Orders_UpdatedAt
-- =============================================

IF OBJECT_ID('trg_Order_StatusChange', 'TR') IS NOT NULL
    DROP TRIGGER trg_Order_StatusChange;
GO

CREATE TRIGGER trg_Order_StatusChange
ON Orders
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Logowanie dla INSERT (nowe zamówienie)
    INSERT INTO OrderStatusHistory (OrderID, OldStatus, NewStatus, ChangedBy, ChangedAt, ChangeReason)
    SELECT 
        i.OrderID,
        NULL,
        i.Status,
        i.CreatedBy,
        GETDATE(),
        'Nowe zamówienie utworzone'
    FROM inserted i
    LEFT JOIN deleted d ON i.OrderID = d.OrderID
    WHERE d.OrderID IS NULL;
    
    -- Logowanie dla UPDATE (zmiana statusu)
    INSERT INTO OrderStatusHistory (OrderID, OldStatus, NewStatus, ChangedBy, ChangedAt, ChangeReason)
    SELECT 
        i.OrderID,
        d.Status,
        i.Status,
        i.CreatedBy,
        GETDATE(),
        CASE 
            WHEN i.Status = 'Confirmed' THEN 'Zamówienie potwierdzone'
            WHEN i.Status = 'InProgress' THEN 'Szkolenie rozpoczęte'
            WHEN i.Status = 'Completed' THEN 'Szkolenie zakończone'
            WHEN i.Status = 'Cancelled' THEN 'Zamówienie anulowane'
            WHEN i.Status = 'Archived' THEN 'Zamówienie zarchiwizowane'
            ELSE 'Zmiana statusu'
        END
    FROM inserted i
    INNER JOIN deleted d ON i.OrderID = d.OrderID
    WHERE i.Status <> d.Status;
    
    -- Automatyczne ustawianie dat przy zmianie statusu + UpdatedAt w jednym UPDATE
    -- (unikamy wywołania trg_Orders_UpdatedAt)
    UPDATE Orders
    SET ActualStartDate = CASE WHEN i.Status = 'InProgress' AND o.ActualStartDate IS NULL THEN GETDATE() ELSE o.ActualStartDate END,
        ActualEndDate = CASE WHEN i.Status = 'Completed' AND o.ActualEndDate IS NULL THEN GETDATE() ELSE o.ActualEndDate END,
        UpdatedAt = GETDATE()  -- ustawiamy UpdatedAt tutaj ręcznie
    FROM Orders o
    INNER JOIN inserted i ON o.OrderID = i.OrderID;
END;
GO

PRINT 'Trigger trg_Order_StatusChange utworzony.';
GO

-- =============================================
-- TRIGGER 3: Aktualizacja średniej oceny trenera
-- =============================================

IF OBJECT_ID('trg_Review_UpdateTrainerRating', 'TR') IS NOT NULL
    DROP TRIGGER trg_Review_UpdateTrainerRating;
GO

CREATE TRIGGER trg_Review_UpdateTrainerRating
ON Reviews
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @AffectedTrainers TABLE (TrainerID INT);
    
    INSERT INTO @AffectedTrainers (TrainerID)
    SELECT DISTINCT o.LeadTrainerID
    FROM inserted i
    INNER JOIN Orders o ON i.OrderID = o.OrderID
    WHERE o.LeadTrainerID IS NOT NULL;
    
    INSERT INTO @AffectedTrainers (TrainerID)
    SELECT DISTINCT o.LeadTrainerID
    FROM deleted d
    INNER JOIN Orders o ON d.OrderID = o.OrderID
    WHERE o.LeadTrainerID IS NOT NULL
    AND o.LeadTrainerID NOT IN (SELECT TrainerID FROM @AffectedTrainers);
    
    UPDATE Trainers
    SET AverageRating = (
        SELECT AVG(CAST(r.RatingTrainer AS DECIMAL(3,2)))
        FROM Reviews r
        INNER JOIN Orders o ON r.OrderID = o.OrderID
        WHERE o.LeadTrainerID = Trainers.TrainerID
          AND r.RatingTrainer IS NOT NULL
          AND r.Status = 'Approved'
    ),
    UpdatedAt = GETDATE()  -- ustawiamy UpdatedAt ręcznie
    WHERE TrainerID IN (SELECT TrainerID FROM @AffectedTrainers);
END;
GO

PRINT 'Trigger trg_Review_UpdateTrainerRating utworzony.';
GO

-- =============================================
-- TRIGGER 4: Aktualizacja TotalOrdersValue klienta
-- =============================================

IF OBJECT_ID('trg_Order_UpdateClientTotalValue', 'TR') IS NOT NULL
    DROP TRIGGER trg_Order_UpdateClientTotalValue;
GO

CREATE TRIGGER trg_Order_UpdateClientTotalValue
ON Orders
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @AffectedClients TABLE (ClientID INT);
    
    INSERT INTO @AffectedClients (ClientID)
    SELECT DISTINCT ClientID FROM inserted
    UNION
    SELECT DISTINCT ClientID FROM deleted;
    
    UPDATE Clients
    SET TotalOrdersValue = ISNULL((
        SELECT SUM(OrderTotals.OrderTotal * (1 - OrderTotals.DiscountPercent / 100.0))
        FROM (
            SELECT o.OrderID, o.DiscountPercent, SUM(oi.UnitPrice * oi.Quantity) AS OrderTotal
            FROM Orders o
            INNER JOIN OrderItems oi ON o.OrderID = oi.OrderID
            WHERE o.ClientID = Clients.ClientID
              AND o.Status IN ('Completed', 'InProgress')
            GROUP BY o.OrderID, o.DiscountPercent
        ) AS OrderTotals
    ), 0),
    DiscountPercent = CASE
        WHEN ISNULL((
            SELECT SUM(OrderTotals.OrderTotal * (1 - OrderTotals.DiscountPercent / 100.0))
            FROM (
                SELECT o.OrderID, o.DiscountPercent, SUM(oi.UnitPrice * oi.Quantity) AS OrderTotal
                FROM Orders o
                INNER JOIN OrderItems oi ON o.OrderID = oi.OrderID
                WHERE o.ClientID = Clients.ClientID
                  AND o.Status IN ('Completed', 'InProgress')
                GROUP BY o.OrderID, o.DiscountPercent
            ) AS OrderTotals
        ), 0) >= 50000 THEN 15
        WHEN ISNULL((
            SELECT SUM(OrderTotals.OrderTotal * (1 - OrderTotals.DiscountPercent / 100.0))
            FROM (
                SELECT o.OrderID, o.DiscountPercent, SUM(oi.UnitPrice * oi.Quantity) AS OrderTotal
                FROM Orders o
                INNER JOIN OrderItems oi ON o.OrderID = oi.OrderID
                WHERE o.ClientID = Clients.ClientID
                  AND o.Status IN ('Completed', 'InProgress')
                GROUP BY o.OrderID, o.DiscountPercent
            ) AS OrderTotals
        ), 0) >= 10000 THEN 10
        ELSE 0
    END,
    Status = CASE 
        WHEN ISNULL((
            SELECT SUM(OrderTotals.OrderTotal * (1 - OrderTotals.DiscountPercent / 100.0))
            FROM (
                SELECT o.OrderID, o.DiscountPercent, SUM(oi.UnitPrice * oi.Quantity) AS OrderTotal
                FROM Orders o
                INNER JOIN OrderItems oi ON o.OrderID = oi.OrderID
                WHERE o.ClientID = Clients.ClientID
                  AND o.Status IN ('Completed', 'InProgress')
                GROUP BY o.OrderID, o.DiscountPercent
            ) AS OrderTotals
        ), 0) > 0 AND Status = 'Potential' THEN 'Active'
        ELSE Status
    END,
    UpdatedAt = GETDATE()  -- ustawiamy UpdatedAt ręcznie
    WHERE ClientID IN (SELECT ClientID FROM @AffectedClients);
END;
GO

PRINT 'Trigger trg_Order_UpdateClientTotalValue utworzony.';
GO

-- =============================================
-- TRIGGER 5: Aktualizacja TotalOrdersValue przy zmianie OrderItems
-- =============================================

IF OBJECT_ID('trg_OrderItems_UpdateClientTotalValue', 'TR') IS NOT NULL
    DROP TRIGGER trg_OrderItems_UpdateClientTotalValue;
GO

CREATE TRIGGER trg_OrderItems_UpdateClientTotalValue
ON OrderItems
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @AffectedClients TABLE (ClientID INT);
    
    INSERT INTO @AffectedClients (ClientID)
    SELECT DISTINCT o.ClientID
    FROM inserted i
    INNER JOIN Orders o ON i.OrderID = o.OrderID
    UNION
    SELECT DISTINCT o.ClientID
    FROM deleted d
    INNER JOIN Orders o ON d.OrderID = o.OrderID;
    
    UPDATE Clients
    SET TotalOrdersValue = ISNULL((
        SELECT SUM(OrderTotals.OrderTotal * (1 - OrderTotals.DiscountPercent / 100.0))
        FROM (
            SELECT o.OrderID, o.DiscountPercent, SUM(oi.UnitPrice * oi.Quantity) AS OrderTotal
            FROM Orders o
            INNER JOIN OrderItems oi ON o.OrderID = oi.OrderID
            WHERE o.ClientID = Clients.ClientID
              AND o.Status IN ('Completed', 'InProgress')
            GROUP BY o.OrderID, o.DiscountPercent
        ) AS OrderTotals
    ), 0),
    DiscountPercent = CASE
        WHEN ISNULL((
            SELECT SUM(OrderTotals.OrderTotal * (1 - OrderTotals.DiscountPercent / 100.0))
            FROM (
                SELECT o.OrderID, o.DiscountPercent, SUM(oi.UnitPrice * oi.Quantity) AS OrderTotal
                FROM Orders o
                INNER JOIN OrderItems oi ON o.OrderID = oi.OrderID
                WHERE o.ClientID = Clients.ClientID
                  AND o.Status IN ('Completed', 'InProgress')
                GROUP BY o.OrderID, o.DiscountPercent
            ) AS OrderTotals
        ), 0) >= 50000 THEN 15
        WHEN ISNULL((
            SELECT SUM(OrderTotals.OrderTotal * (1 - OrderTotals.DiscountPercent / 100.0))
            FROM (
                SELECT o.OrderID, o.DiscountPercent, SUM(oi.UnitPrice * oi.Quantity) AS OrderTotal
                FROM Orders o
                INNER JOIN OrderItems oi ON o.OrderID = oi.OrderID
                WHERE o.ClientID = Clients.ClientID
                  AND o.Status IN ('Completed', 'InProgress')
                GROUP BY o.OrderID, o.DiscountPercent
            ) AS OrderTotals
        ), 0) >= 10000 THEN 10
        ELSE 0
    END,
    UpdatedAt = GETDATE()  -- ustawiamy UpdatedAt ręcznie
    WHERE ClientID IN (SELECT ClientID FROM @AffectedClients);
END;
GO

PRINT 'Trigger trg_OrderItems_UpdateClientTotalValue utworzony.';
GO

-- =============================================
-- KONIEC TWORZENIA TRIGGERÓW
-- =============================================

PRINT '';
PRINT '========================================';
PRINT 'PODSUMOWANIE TRIGGERÓW:';
PRINT '- RECURSIVE_TRIGGERS wyłączone (ochrona przed pętlami)';
PRINT '- 6 triggerów UpdatedAt (z IF NOT UPDATE)';
PRINT '- 1 trigger StatusChange (+ UpdatedAt ręcznie)';
PRINT '- 1 trigger UpdateTrainerRating (+ UpdatedAt ręcznie)';
PRINT '- 2 triggery UpdateClientTotalValue (+ UpdatedAt ręcznie)';
PRINT 'RAZEM: 10 triggerów (bez rekurencji)';
PRINT '========================================';
GO