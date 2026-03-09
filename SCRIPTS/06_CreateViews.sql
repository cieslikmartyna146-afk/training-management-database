-- =============================================
-- TWORZENIE WIDOKÓW - SYSTEM ZARZĄDZANIA SZKOLENIAMI
-- Skrypt: 06_CreateViews.sql
-- =============================================

USE TrainingSystemDB;
GO

-- =============================================
-- WIDOK 1: vw_Orders_ForTrainers
-- Widok zamówień dla trenerów (bez cen i rabatów)
-- =============================================

IF OBJECT_ID('vw_Orders_ForTrainers', 'V') IS NOT NULL
    DROP VIEW vw_Orders_ForTrainers;
GO

CREATE VIEW vw_Orders_ForTrainers
AS
SELECT 
    o.OrderID,
    o.OrderDate,
    o.Status,
    o.PlannedStartDate,
    o.PlannedEndDate,
    o.ActualStartDate,
    o.ActualEndDate,
    o.VenueName,
    o.VenueAddress,
    o.VenueLocation,
    o.LeadTrainerID,
    o.SpecialRequirements,
    -- Dane klienta (ograniczone - bez wrażliwych danych finansowych)
    c.ClientID,
    c.CompanyName,
    c.FirstName,
    c.LastName,
    c.Email AS ClientEmail,
    c.Phone AS ClientPhone,
    -- Produkty (bez cen!)
    (SELECT STRING_AGG(p.ProductName, ', ')
     FROM OrderItems oi
     INNER JOIN Products p ON oi.ProductID = p.ProductID
     WHERE oi.OrderID = o.OrderID) AS ProductList,
    -- Liczba uczestników
    (SELECT COUNT(*)
     FROM OrderParticipants op
     WHERE op.OrderID = o.OrderID) AS ParticipantCount
FROM Orders o
INNER JOIN Clients c ON o.ClientID = c.ClientID;
GO

PRINT 'Widok vw_Orders_ForTrainers utworzony.';
GO

-- =============================================
-- WIDOK 2: vw_ActiveProducts
-- Aktywne produkty z podstawowymi informacjami
-- =============================================

IF OBJECT_ID('vw_ActiveProducts', 'V') IS NOT NULL
    DROP VIEW vw_ActiveProducts;
GO

CREATE VIEW vw_ActiveProducts
AS
SELECT 
    ProductID,
    ProductType,
    ProductName,
    Description,
    BasePrice,
    DurationHours,
    Level,
    Category,
    -- Liczba modułów (dla Training i Course)
    (SELECT COUNT(*)
     FROM ProductHierarchy ph
     WHERE ph.ParentProductID = p.ProductID) AS ComponentCount,
    -- Liczba sprzedaży
    (SELECT ISNULL(SUM(oi.Quantity), 0)
     FROM OrderItems oi
     WHERE oi.ProductID = p.ProductID) AS TotalSold
FROM Products p
WHERE IsActive = 1;
GO

PRINT 'Widok vw_ActiveProducts utworzony.';
GO

-- =============================================
-- WIDOK 3: vw_ClientSummary
-- Podsumowanie klientów z statystykami
-- =============================================

IF OBJECT_ID('vw_ClientSummary', 'V') IS NOT NULL
    DROP VIEW vw_ClientSummary;
GO

CREATE VIEW vw_ClientSummary
AS
SELECT 
    c.ClientID,
    c.ClientType,
    c.CompanyName,
    c.FirstName,
    c.LastName,
    c.Email,
    c.Phone,
    c.City,
    c.Status,
    c.TotalOrdersValue,
    c.DiscountPercent,
    c.MarketingConsent,
    -- Statystyki zamówień
    (SELECT COUNT(*) 
     FROM Orders o 
     WHERE o.ClientID = c.ClientID) AS TotalOrders,
    (SELECT COUNT(*) 
     FROM Orders o 
     WHERE o.ClientID = c.ClientID 
       AND o.Status = 'Completed') AS CompletedOrders,
    (SELECT MAX(o.OrderDate) 
     FROM Orders o 
     WHERE o.ClientID = c.ClientID) AS LastOrderDate,
    -- Data pierwszego zamówienia
    (SELECT MIN(o.OrderDate) 
     FROM Orders o 
     WHERE o.ClientID = c.ClientID) AS FirstOrderDate
FROM Clients c
WHERE IsDeleted = 0;
GO

PRINT 'Widok vw_ClientSummary utworzony.';
GO

-- =============================================
-- WIDOK 4: vw_TrainerWorkload
-- Obciążenie trenerów (liczba szkoleń)
-- =============================================

IF OBJECT_ID('vw_TrainerWorkload', 'V') IS NOT NULL
    DROP VIEW vw_TrainerWorkload;
GO

CREATE VIEW vw_TrainerWorkload
AS
SELECT 
    t.TrainerID,
    t.FirstName,
    t.LastName,
    t.Email,
    t.IsActive,
    t.AverageRating,
    -- Statystyki szkoleń
    (SELECT COUNT(*) 
     FROM Orders o 
     WHERE o.LeadTrainerID = t.TrainerID) AS TotalAssignments,
    (SELECT COUNT(*) 
     FROM Orders o 
     WHERE o.LeadTrainerID = t.TrainerID 
       AND o.Status = 'Completed') AS CompletedTrainings,
    (SELECT COUNT(*) 
     FROM Orders o 
     WHERE o.LeadTrainerID = t.TrainerID 
       AND o.Status IN ('New', 'Confirmed', 'InProgress')) AS ActiveTrainings,
    -- Najbliższe szkolenie
    (SELECT MIN(o.PlannedStartDate) 
     FROM Orders o 
     WHERE o.LeadTrainerID = t.TrainerID 
       AND o.PlannedStartDate >= CAST(GETDATE() AS DATE)
       AND o.Status IN ('Confirmed', 'InProgress')) AS NextTrainingDate,
    -- Liczba opinii
    (SELECT COUNT(*) 
     FROM Reviews r 
     INNER JOIN Orders o ON r.OrderID = o.OrderID
     WHERE o.LeadTrainerID = t.TrainerID
       AND r.Status = 'Approved') AS ReviewCount
FROM Trainers t;
GO

PRINT 'Widok vw_TrainerWorkload utworzony.';
GO

-- =============================================
-- WIDOK 5: vw_OrderAnalytics (dla Columnstore Index)
-- Dane analityczne sprzedaży - WIDOK ZMATERIALIZOWANY
-- =============================================

-- Najpierw tworzymy zwykły widok z odpowiednimi danymi
IF OBJECT_ID('vw_OrderAnalytics', 'V') IS NOT NULL
    DROP VIEW vw_OrderAnalytics;
GO

CREATE VIEW vw_OrderAnalytics
WITH SCHEMABINDING
AS
SELECT 
    o.OrderID,
    o.ClientID,
    o.OrderDate,
    YEAR(o.OrderDate) AS OrderYear,
    MONTH(o.OrderDate) AS OrderMonth,
    o.Status,
    o.DiscountPercent,
    o.LeadTrainerID,
    oi.ProductID,
    p.ProductType,
    p.Category,
    p.Level,
    oi.UnitPrice,
    oi.Quantity,
    (oi.UnitPrice * oi.Quantity) AS ItemTotal,
    ((oi.UnitPrice * oi.Quantity) * (1 - o.DiscountPercent / 100.0)) AS ItemTotalWithDiscount,
    c.City AS ClientCity,
    c.ClientType
FROM dbo.Orders o
INNER JOIN dbo.OrderItems oi ON o.OrderID = oi.OrderID
INNER JOIN dbo.Products p ON oi.ProductID = p.ProductID
INNER JOIN dbo.Clients c ON o.ClientID = c.ClientID;
GO

-- Teraz tworzymy UNIQUE CLUSTERED INDEX (wymagany dla indexed view)
CREATE UNIQUE CLUSTERED INDEX IX_OrderAnalytics_OrderID_ProductID 
ON vw_OrderAnalytics(OrderID, ProductID);
GO

PRINT 'Widok vw_OrderAnalytics utworzony z clustered index.';
GO

-- Opcjonalnie: Columnstore Index jako NONCLUSTERED (dla lepszej analityki)
-- UWAGA: W SQL Server można mieć CLUSTERED (dla uniqueness) + NONCLUSTERED COLUMNSTORE
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'NCCI_OrderAnalytics' AND object_id = OBJECT_ID('vw_OrderAnalytics'))
BEGIN
    CREATE NONCLUSTERED COLUMNSTORE INDEX NCCI_OrderAnalytics
    ON vw_OrderAnalytics (
        OrderYear,
        OrderMonth,
        Status,
        ProductType,
        Category,
        Level,
        ClientCity,
        ClientType,
        ItemTotal,
        ItemTotalWithDiscount,
        Quantity,
        DiscountPercent
    );
    PRINT 'Nonclustered Columnstore Index na vw_OrderAnalytics utworzony.';
END
GO

-- =============================================
-- WIDOK 6: vw_ProductHierarchy_Expanded
-- Rozwinięta hierarchia produktów (rekurencyjny CTE jako widok)
-- =============================================

IF OBJECT_ID('vw_ProductHierarchy_Expanded', 'V') IS NOT NULL
    DROP VIEW vw_ProductHierarchy_Expanded;
GO

CREATE VIEW vw_ProductHierarchy_Expanded
AS
WITH ProductTree AS (
    -- Poziom 1: Produkty bez rodzica (Kursy lub standalone Training/Module)
    SELECT 
        p.ProductID,
        p.ProductName,
        p.ProductType,
        CAST(NULL AS INT) AS ParentProductID,
        CAST(p.ProductName AS NVARCHAR(500)) AS HierarchyPath,
        1 AS Level
    FROM Products p
    WHERE NOT EXISTS (
        SELECT 1 FROM ProductHierarchy ph WHERE ph.ChildProductID = p.ProductID
    )
    
    UNION ALL
    
    -- Poziomy zagnieżdżone: produkty z rodzicem
    SELECT 
        p.ProductID,
        p.ProductName,
        p.ProductType,
        ph.ParentProductID,
        CAST(pt.HierarchyPath + ' > ' + p.ProductName AS NVARCHAR(500)),
        pt.Level + 1
    FROM Products p
    INNER JOIN ProductHierarchy ph ON p.ProductID = ph.ChildProductID
    INNER JOIN ProductTree pt ON ph.ParentProductID = pt.ProductID
)
SELECT 
    ProductID,
    ProductName,
    ProductType,
    ParentProductID,
    HierarchyPath,
    Level
FROM ProductTree;
GO

PRINT 'Widok vw_ProductHierarchy_Expanded utworzony.';
GO

-- =============================================
-- KONIEC TWORZENIA WIDOKÓW
-- =============================================

PRINT '';
PRINT '========================================';
PRINT 'PODSUMOWANIE WIDOKÓW:';
PRINT '- vw_Orders_ForTrainers (bez cen dla trenerów)';
PRINT '- vw_ActiveProducts (aktywne produkty ze statystykami)';
PRINT '- vw_ClientSummary (podsumowanie klientów)';
PRINT '- vw_TrainerWorkload (obciążenie trenerów)';
PRINT '- vw_OrderAnalytics (indexed view + columnstore dla analityki)';
PRINT '- vw_ProductHierarchy_Expanded (rozwinięta hierarchia)';
PRINT 'RAZEM: 6 widoków';
PRINT '========================================';
GO