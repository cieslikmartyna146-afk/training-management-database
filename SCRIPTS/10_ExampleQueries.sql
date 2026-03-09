-- =============================================
-- PRZYKŁADOWE ZAPYTANIA DEMONSTRACYJNE
-- Skrypt: 10_ExampleQueries.sql
-- =============================================

USE TrainingSystemDB;
GO

PRINT '========================================';
PRINT 'PRZYKŁADOWE ZAPYTANIA DEMONSTRACYJNE';
PRINT '========================================';
PRINT '';

-- =============================================
-- 1. FULL-TEXT SEARCH - Wyszukiwanie produktów
-- =============================================

PRINT '1. FULL-TEXT SEARCH - Wyszukiwanie szkoleń o "Power Query"';
PRINT '------------------------------------------------------';

SELECT 
    ProductID,
    ProductName,
    ProductType,
    Category,
    Level,
    BasePrice
FROM Products
WHERE CONTAINS(Description, '"Power Query"');

PRINT '';
PRINT 'Wynik: Produkty zawierające "Power Query" w opisie';
PRINT '';
GO

-- =============================================
-- 2. FULL-TEXT SEARCH - Wyszukiwanie trenera
-- =============================================

PRINT '2. FULL-TEXT SEARCH - Znajdź trenera znającego "Excel AND VBA"';
PRINT '------------------------------------------------------';

SELECT 
    TrainerID,
    FirstName,
    LastName,
    Email,
    AverageRating,
    IsActive
FROM Trainers
WHERE CONTAINS(CompetencyDescription, 'Excel AND VBA')
  AND IsActive = 1;

PRINT '';
PRINT 'Wynik: Aktywni trenerzy z kompetencjami Excel i VBA';
PRINT '';
GO

-- =============================================
-- 3. FULL-TEXT SEARCH - Analiza opinii
-- =============================================

PRINT '3. FULL-TEXT SEARCH - Pozytywne opinie wspominające "Power BI"';
PRINT '------------------------------------------------------';

SELECT 
    r.ReviewID,
    r.Rating,
    r.RatingTrainer,
    r.Comment,
    c.CompanyName,
    c.FirstName + ' ' + c.LastName AS ClientName
FROM Reviews r
LEFT JOIN Clients c ON r.ClientID = c.ClientID
WHERE CONTAINS(r.Comment, '"Power BI"')
  AND r.Rating >= 4
  AND r.Status = 'Approved';

PRINT '';
PRINT 'Wynik: Opinie 4+ gwiazdek zawierające "Power BI" (marketing)';
PRINT '';
GO

-- =============================================
-- 4. FULL-TEXT SEARCH - Quality control
-- =============================================

PRINT '4. FULL-TEXT SEARCH - Wykryj skargi na materiały';
PRINT '------------------------------------------------------';

SELECT 
    r.ReviewID,
    r.Rating,
    r.RatingMaterials,
    r.Comment,
    o.OrderID,
    p.ProductName
FROM Reviews r
INNER JOIN Orders o ON r.OrderID = o.OrderID
INNER JOIN OrderItems oi ON o.OrderID = oi.OrderID
INNER JOIN Products p ON oi.ProductID = p.ProductID
WHERE CONTAINS(r.Comment, 'materiały AND (słabe OR nieaktualne OR stare)')
   OR r.RatingMaterials <= 2;

PRINT '';
PRINT 'Wynik: Opinie ze skargami na materiały (action needed)';
PRINT '';
GO

-- =============================================
-- 5. SPATIAL - Klienci w promieniu 50km od Warszawy
-- =============================================

PRINT '5. SPATIAL - Klienci w promieniu 50km od Warszawy';
PRINT '------------------------------------------------------';

DECLARE @Warszawa GEOGRAPHY = geography::Point(52.2297, 21.0122, 4326);

SELECT 
    ClientID,
    COALESCE(CompanyName, FirstName + ' ' + LastName) AS ClientName,
    City,
    CAST(Location.STDistance(@Warszawa) / 1000 AS DECIMAL(10,2)) AS DistanceKM,
    TotalOrdersValue,
    DiscountPercent
FROM Clients
WHERE Location.STDistance(@Warszawa) <= 50000
ORDER BY DistanceKM;

PRINT '';
PRINT 'Wynik: Klienci w promieniu 50km (targeted marketing)';
PRINT '';
GO

-- =============================================
-- 6. SPATIAL - Optymalizacja tras trenera
-- =============================================

PRINT '6. SPATIAL - Szkolenia w tym tygodniu najbliżej Krakowa';
PRINT '------------------------------------------------------';

DECLARE @Krakow GEOGRAPHY = geography::Point(50.0647, 19.9450, 4326);
DECLARE @WeekStart DATE = '2024-12-15';
DECLARE @WeekEnd DATE = '2024-12-21';

SELECT 
    o.OrderID,
    o.VenueName,
    o.PlannedStartDate,
    CAST(o.VenueLocation.STDistance(@Krakow) / 1000 AS DECIMAL(10,2)) AS DistanceKM,
    t.FirstName + ' ' + t.LastName AS TrainerName,
    p.ProductName
FROM Orders o
LEFT JOIN Trainers t ON o.LeadTrainerID = t.TrainerID
INNER JOIN OrderItems oi ON o.OrderID = oi.OrderID
INNER JOIN Products p ON oi.ProductID = p.ProductID
WHERE o.PlannedStartDate BETWEEN @WeekStart AND @WeekEnd
  AND o.VenueLocation IS NOT NULL
ORDER BY DistanceKM;

PRINT '';
PRINT 'Wynik: Szkolenia posortowane po odległości (oszczędność czasu dojazdu)';
PRINT '';
GO

-- =============================================
-- 7. COLUMNSTORE - TOP 10 produktów (bestsellery)
-- =============================================

PRINT '7. COLUMNSTORE - TOP 10 najpopularniejszych produktów';
PRINT '------------------------------------------------------';

SELECT TOP 10
    v.ProductID,
    MAX(p.ProductName) AS ProductName,
    MAX(v.ProductType) AS ProductType,
    MAX(v.Category) AS Category,
    SUM(v.Quantity) AS TotalSold,
    SUM(v.ItemTotalWithDiscount) AS TotalRevenue
FROM vw_OrderAnalytics v
INNER JOIN Products p ON v.ProductID = p.ProductID
WHERE v.Status = 'Completed'
GROUP BY v.ProductID
ORDER BY TotalSold DESC;

PRINT '';
PRINT 'Wynik: Bestsellery - użyto indexed view z columnstore (szybko!)';
PRINT '';
GO

-- =============================================
-- 8. COLUMNSTORE - Sprzedaż per miesiąc
-- =============================================

PRINT '8. COLUMNSTORE - Sprzedaż per miesiąc (trend)';
PRINT '------------------------------------------------------';

SELECT 
    OrderYear,
    OrderMonth,
    COUNT(DISTINCT OrderID) AS OrderCount,
    SUM(ItemTotalWithDiscount) AS Revenue,
    AVG(ItemTotalWithDiscount) AS AvgOrderValue
FROM vw_OrderAnalytics
WHERE Status = 'Completed'
GROUP BY OrderYear, OrderMonth
ORDER BY OrderYear, OrderMonth;

PRINT '';
PRINT 'Wynik: Trend sprzedaży miesięcznej (dashboard)';
PRINT '';
GO

-- =============================================
-- 9. COLUMNSTORE - Analiza per kategoria
-- =============================================

PRINT '9. COLUMNSTORE - Sprzedaż per kategoria produktów';
PRINT '------------------------------------------------------';

SELECT 
    Category,
    COUNT(DISTINCT OrderID) AS Orders,
    SUM(Quantity) AS UnitsSold,
    SUM(ItemTotalWithDiscount) AS Revenue,
    AVG(ItemTotalWithDiscount / Quantity) AS AvgPricePerUnit
FROM vw_OrderAnalytics
WHERE Status = 'Completed'
GROUP BY Category
ORDER BY Revenue DESC;

PRINT '';
PRINT 'Wynik: Która kategoria generuje największe przychody?';
PRINT '';
GO

-- =============================================
-- 10. TRIGGERY - Sprawdzenie TotalOrdersValue i rabatów
-- =============================================

PRINT '10. TRIGGERY - Klienci z automatycznymi rabatami';
PRINT '------------------------------------------------------';

SELECT 
    ClientID,
    COALESCE(CompanyName, FirstName + ' ' + LastName) AS ClientName,
    TotalOrdersValue,
    DiscountPercent,
    Status,
    (SELECT COUNT(*) FROM Orders WHERE ClientID = c.ClientID AND Status = 'Completed') AS CompletedOrders
FROM Clients c
WHERE TotalOrdersValue > 0
ORDER BY TotalOrdersValue DESC;

PRINT '';
PRINT 'Wynik: Trigger automatycznie obliczył TotalOrdersValue i przyznał rabaty';
PRINT '        (>=10k PLN → 10%, >=50k PLN → 15%)';
PRINT '';
GO

-- =============================================
-- 11. TRIGGERY - Sprawdzenie AverageRating trenerów
-- =============================================

PRINT '11. TRIGGERY - Średnia ocena trenerów (auto-kalkulowana)';
PRINT '------------------------------------------------------';

SELECT 
    t.TrainerID,
    t.FirstName + ' ' + t.LastName AS TrainerName,
    t.AverageRating,
    (SELECT COUNT(*) 
     FROM Reviews r 
     INNER JOIN Orders o ON r.OrderID = o.OrderID 
     WHERE o.LeadTrainerID = t.TrainerID 
       AND r.Status = 'Approved') AS ReviewCount,
    t.IsActive
FROM Trainers t
WHERE t.AverageRating IS NOT NULL
ORDER BY t.AverageRating DESC;

PRINT '';
PRINT 'Wynik: Trigger automatycznie przeliczył średnią po dodaniu opinii';
PRINT '';
GO

-- =============================================
-- 12. HIERARCHIA PRODUKTÓW - Recursive CTE
-- =============================================

PRINT '12. HIERARCHIA - Rozwinięcie kursu "Akademia Analityka Danych"';
PRINT '------------------------------------------------------';

WITH ProductTree AS (
    -- Poziom 1: Kurs
    SELECT 
        p.ProductID,
        p.ProductName,
        p.ProductType,
        CAST(NULL AS INT) AS ParentProductID,
        CAST(p.ProductName AS NVARCHAR(500)) AS HierarchyPath,
        1 AS Level
    FROM Products p
    WHERE p.ProductID = 11
    
    UNION ALL
    
    -- Kolejne poziomy: szkolenia i moduły
    SELECT 
        p.ProductID,
        p.ProductName,
        p.ProductType,
        ph.ParentProductID,
        CAST(pt.HierarchyPath + ' → ' + p.ProductName AS NVARCHAR(500)),
        pt.Level + 1
    FROM Products p
    INNER JOIN ProductHierarchy ph ON p.ProductID = ph.ChildProductID
    INNER JOIN ProductTree pt ON ph.ParentProductID = pt.ProductID
)
SELECT 
    ProductID,
    ProductName,
    ProductType,
    HierarchyPath,
    Level
FROM ProductTree
ORDER BY Level, ProductID;

PRINT '';
PRINT 'Wynik: Pełne drzewo kursu (Kurs → Szkolenia → Moduły)';
PRINT '';
GO

-- =============================================
-- 13. WIDOKI - Podsumowanie klientów
-- =============================================

PRINT '13. WIDOKI - Podsumowanie aktywnych klientów VIP';
PRINT '------------------------------------------------------';

SELECT 
    ClientID,
    CompanyName,
    City,
    TotalOrdersValue,
    DiscountPercent,
    TotalOrders,
    CompletedOrders,
    LastOrderDate
FROM vw_ClientSummary
WHERE Status = 'Active'
  AND TotalOrdersValue > 0
ORDER BY TotalOrdersValue DESC;

PRINT '';
PRINT 'Wynik: Widok agreguje dane z wielu tabel (uproszczenie zapytań)';
PRINT '';
GO

-- =============================================
-- 14. WIDOKI - Obciążenie trenerów
-- =============================================

PRINT '14. WIDOKI - Obciążenie aktywnych trenerów';
PRINT '------------------------------------------------------';

SELECT 
    TrainerID,
    FirstName + ' ' + LastName AS TrainerName,
    AverageRating,
    TotalAssignments,
    CompletedTrainings,
    ActiveTrainings,
    NextTrainingDate,
    ReviewCount
FROM vw_TrainerWorkload
WHERE IsActive = 1
ORDER BY ActiveTrainings DESC, AverageRating DESC;

PRINT '';
PRINT 'Wynik: Kto jest najbardziej zajęty? Kto ma najlepszą ocenę?';
PRINT '';
GO

-- =============================================
-- 15. BEZPIECZEŃSTWO - Widok dla trenerów (bez cen)
-- =============================================

PRINT '15. BEZPIECZEŃSTWO - Widok zamówień dla trenerów (bez cen i rabatów)';
PRINT '------------------------------------------------------';

SELECT 
    OrderID,
    OrderDate,
    Status,
    PlannedStartDate,
    PlannedEndDate,
    VenueName,
    ClientEmail,
    ClientPhone,
    ProductList,
    ParticipantCount
FROM vw_Orders_ForTrainers
WHERE Status IN ('Confirmed', 'InProgress');

PRINT '';
PRINT 'Wynik: Trenerzy widzą zamówienia BEZ cen i rabatów (bezpieczeństwo)';
PRINT '';
GO

-- =============================================
-- 16. JSON - Odczyt danych z JSON
-- =============================================

PRINT '16. JSON - Klienci z zainteresowaniem "Excel" (z ankiety)';
PRINT '------------------------------------------------------';

SELECT 
    ClientID,
    FirstName + ' ' + LastName AS ClientName,
    Email,
    JSON_VALUE(AdditionalInfo, '$.survey.experience') AS Experience,
    JSON_QUERY(AdditionalInfo, '$.survey.interests') AS Interests,
    JSON_VALUE(AdditionalInfo, '$.source') AS Source
FROM Clients
WHERE AdditionalInfo IS NOT NULL
  AND JSON_QUERY(AdditionalInfo, '$.survey.interests') LIKE '%Excel%';

PRINT '';
PRINT 'Wynik: Elastyczne dane JSON - różne struktury bez ALTER TABLE';
PRINT '';
GO

-- =============================================
-- 17. SOFT DELETE - Klienci (aktywni vs usunięci)
-- =============================================

PRINT '17. SOFT DELETE - Tylko aktywni klienci (IsDeleted=0)';
PRINT '------------------------------------------------------';

SELECT 
    ClientID,
    COALESCE(CompanyName, FirstName + ' ' + LastName) AS ClientName,
    Status,
    IsDeleted,
    DeletedAt
FROM Clients
WHERE IsDeleted = 0;

PRINT '';
PRINT 'Wynik: Soft delete - usunięci klienci dalej w bazie (recovery możliwy)';
PRINT '';
GO

-- =============================================
-- PODSUMOWANIE
-- =============================================

PRINT '';
PRINT '========================================';
PRINT 'KONIEC PRZYKŁADOWYCH ZAPYTAŃ';
PRINT '========================================';
PRINT '';
PRINT 'Przetestowano:';
PRINT '- Full-Text Search (3 zapytania): produkty, trenerzy, opinie';
PRINT '- Spatial Data (2 zapytania): klienci w promieniu, optymalizacja tras';
PRINT '- Columnstore Index (3 zapytania): bestsellery, trendy, analiza kategorii';
PRINT '- Triggery (2 zapytania): TotalOrdersValue, AverageRating';
PRINT '- Hierarchia produktów (1 zapytanie): recursive CTE';
PRINT '- Widoki (3 zapytania): vw_ClientSummary, vw_TrainerWorkload, vw_Orders_ForTrainers';
PRINT '- JSON (1 zapytanie): elastyczne dane ankiet';
PRINT '- Soft Delete (1 zapytanie): IsDeleted';
PRINT '';
PRINT 'WSZYSTKIE ELEMENTY BAZY DZIAŁAJĄ POPRAWNIE!';
PRINT '========================================';
GO