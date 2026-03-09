-- =============================================
-- TWORZENIE INDEKSÓW - SYSTEM ZARZĄDZANIA SZKOLENIAMI
-- Skrypt: 04_CreateIndexes.sql
-- =============================================

USE TrainingSystemDB;
GO

-- =============================================
-- CZĘŚĆ 1: INDEKSY PEŁNOTEKSTOWE (FULL-TEXT)
-- =============================================

-- Utworzenie Full-Text Catalog (kontener dla indeksów full-text)
IF NOT EXISTS (SELECT 1 FROM sys.fulltext_catalogs WHERE name = 'ftCatalog')
BEGIN
    CREATE FULLTEXT CATALOG ftCatalog AS DEFAULT;
    PRINT 'Full-Text Catalog utworzony.';
END
GO

-- Indeks Full-Text na Products.Description
IF NOT EXISTS (SELECT 1 FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('Products'))
BEGIN
    DECLARE @ProductsPK NVARCHAR(128);
    SELECT @ProductsPK = name 
    FROM sys.indexes 
    WHERE object_id = OBJECT_ID('Products') AND is_primary_key = 1;
    
    EXEC('CREATE FULLTEXT INDEX ON Products(Description) 
          KEY INDEX ' + @ProductsPK + ' ON ftCatalog 
          WITH CHANGE_TRACKING AUTO');
    
    PRINT 'Full-Text Index na Products.Description utworzony.';
END
GO

-- Indeks Full-Text na Trainers.CompetencyDescription
IF NOT EXISTS (SELECT 1 FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('Trainers'))
BEGIN
    DECLARE @TrainersPK NVARCHAR(128);
    SELECT @TrainersPK = name 
    FROM sys.indexes 
    WHERE object_id = OBJECT_ID('Trainers') AND is_primary_key = 1;
    
    EXEC('CREATE FULLTEXT INDEX ON Trainers(CompetencyDescription) 
          KEY INDEX ' + @TrainersPK + ' ON ftCatalog 
          WITH CHANGE_TRACKING AUTO');
    
    PRINT 'Full-Text Index na Trainers.CompetencyDescription utworzony.';
END
GO

-- Indeks Full-Text na Reviews.Comment
IF NOT EXISTS (SELECT 1 FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('Reviews'))
BEGIN
    DECLARE @ReviewsPK NVARCHAR(128);
    SELECT @ReviewsPK = name 
    FROM sys.indexes 
    WHERE object_id = OBJECT_ID('Reviews') AND is_primary_key = 1;
    
    EXEC('CREATE FULLTEXT INDEX ON Reviews(Comment) 
          KEY INDEX ' + @ReviewsPK + ' ON ftCatalog 
          WITH CHANGE_TRACKING AUTO');
    
    PRINT 'Full-Text Index na Reviews.Comment utworzony.';
END
GO

-- =============================================
-- CZĘŚĆ 2: INDEKSY PRZESTRZENNE (SPATIAL)
-- =============================================

-- Indeks Spatial na Clients.Location
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'SIDX_Clients_Location' AND object_id = OBJECT_ID('Clients'))
BEGIN
    CREATE SPATIAL INDEX SIDX_Clients_Location ON Clients(Location)
        USING GEOGRAPHY_GRID
        WITH (
            GRIDS = (LEVEL_1 = MEDIUM, LEVEL_2 = MEDIUM, LEVEL_3 = MEDIUM, LEVEL_4 = MEDIUM),
            CELLS_PER_OBJECT = 16
        );
    PRINT 'Spatial Index na Clients.Location utworzony.';
END
GO

-- Indeks Spatial na Orders.VenueLocation
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'SIDX_Orders_VenueLocation' AND object_id = OBJECT_ID('Orders'))
BEGIN
    CREATE SPATIAL INDEX SIDX_Orders_VenueLocation ON Orders(VenueLocation)
        USING GEOGRAPHY_GRID
        WITH (
            GRIDS = (LEVEL_1 = MEDIUM, LEVEL_2 = MEDIUM, LEVEL_3 = MEDIUM, LEVEL_4 = MEDIUM),
            CELLS_PER_OBJECT = 16
        );
    PRINT 'Spatial Index na Orders.VenueLocation utworzony.';
END
GO

-- =============================================
-- CZĘŚĆ 3: INDEKSY KLASYCZNE (B-TREE)
-- =============================================

-- Indeksy na tabeli Clients
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Clients_Email' AND object_id = OBJECT_ID('Clients'))
    CREATE NONCLUSTERED INDEX IX_Clients_Email ON Clients(Email);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Clients_Status' AND object_id = OBJECT_ID('Clients'))
    CREATE NONCLUSTERED INDEX IX_Clients_Status ON Clients(Status, IsDeleted);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Clients_TotalOrdersValue' AND object_id = OBJECT_ID('Clients'))
    CREATE NONCLUSTERED INDEX IX_Clients_TotalOrdersValue ON Clients(TotalOrdersValue DESC);

PRINT 'Indeksy na Clients utworzone.';
GO

-- Indeksy na tabeli Participants
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Participants_Email' AND object_id = OBJECT_ID('Participants'))
    CREATE NONCLUSTERED INDEX IX_Participants_Email ON Participants(Email);

PRINT 'Indeksy na Participants utworzone.';
GO

-- Indeksy na tabeli Trainers
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Trainers_Email' AND object_id = OBJECT_ID('Trainers'))
    CREATE NONCLUSTERED INDEX IX_Trainers_Email ON Trainers(Email);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Trainers_IsActive' AND object_id = OBJECT_ID('Trainers'))
    CREATE NONCLUSTERED INDEX IX_Trainers_IsActive ON Trainers(IsActive);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Trainers_AverageRating' AND object_id = OBJECT_ID('Trainers'))
    CREATE NONCLUSTERED INDEX IX_Trainers_AverageRating ON Trainers(AverageRating DESC) WHERE AverageRating IS NOT NULL;

PRINT 'Indeksy na Trainers utworzone.';
GO

-- Indeksy na tabeli Products
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Products_Type_Active' AND object_id = OBJECT_ID('Products'))
    CREATE NONCLUSTERED INDEX IX_Products_Type_Active ON Products(ProductType, IsActive);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Products_Category' AND object_id = OBJECT_ID('Products'))
    CREATE NONCLUSTERED INDEX IX_Products_Category ON Products(Category);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Products_Level' AND object_id = OBJECT_ID('Products'))
    CREATE NONCLUSTERED INDEX IX_Products_Level ON Products(Level);

PRINT 'Indeksy na Products utworzone.';
GO

-- Indeksy na tabeli ProductHierarchy
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ProductHierarchy_Parent' AND object_id = OBJECT_ID('ProductHierarchy'))
    CREATE NONCLUSTERED INDEX IX_ProductHierarchy_Parent ON ProductHierarchy(ParentProductID);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ProductHierarchy_Child' AND object_id = OBJECT_ID('ProductHierarchy'))
    CREATE NONCLUSTERED INDEX IX_ProductHierarchy_Child ON ProductHierarchy(ChildProductID);

PRINT 'Indeksy na ProductHierarchy utworzone.';
GO

-- Indeksy na tabeli Orders
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Orders_ClientID' AND object_id = OBJECT_ID('Orders'))
    CREATE NONCLUSTERED INDEX IX_Orders_ClientID ON Orders(ClientID);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Orders_TrainerID' AND object_id = OBJECT_ID('Orders'))
    CREATE NONCLUSTERED INDEX IX_Orders_TrainerID ON Orders(LeadTrainerID);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Orders_OrderDate' AND object_id = OBJECT_ID('Orders'))
    CREATE NONCLUSTERED INDEX IX_Orders_OrderDate ON Orders(OrderDate DESC);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Orders_Status' AND object_id = OBJECT_ID('Orders'))
    CREATE NONCLUSTERED INDEX IX_Orders_Status ON Orders(Status);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Orders_PlannedStartDate' AND object_id = OBJECT_ID('Orders'))
    CREATE NONCLUSTERED INDEX IX_Orders_PlannedStartDate ON Orders(PlannedStartDate);

PRINT 'Indeksy na Orders utworzone.';
GO

-- Indeksy na tabeli OrderItems
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_OrderItems_OrderID' AND object_id = OBJECT_ID('OrderItems'))
    CREATE NONCLUSTERED INDEX IX_OrderItems_OrderID ON OrderItems(OrderID);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_OrderItems_ProductID' AND object_id = OBJECT_ID('OrderItems'))
    CREATE NONCLUSTERED INDEX IX_OrderItems_ProductID ON OrderItems(ProductID);

PRINT 'Indeksy na OrderItems utworzone.';
GO

-- Indeksy na tabeli OrderParticipants
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_OrderParticipants_OrderID' AND object_id = OBJECT_ID('OrderParticipants'))
    CREATE NONCLUSTERED INDEX IX_OrderParticipants_OrderID ON OrderParticipants(OrderID);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_OrderParticipants_ParticipantID' AND object_id = OBJECT_ID('OrderParticipants'))
    CREATE NONCLUSTERED INDEX IX_OrderParticipants_ParticipantID ON OrderParticipants(ParticipantID);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_OrderParticipants_ClientID' AND object_id = OBJECT_ID('OrderParticipants'))
    CREATE NONCLUSTERED INDEX IX_OrderParticipants_ClientID ON OrderParticipants(ClientID);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_OrderParticipants_CertificateNumber' AND object_id = OBJECT_ID('OrderParticipants'))
    CREATE NONCLUSTERED INDEX IX_OrderParticipants_CertificateNumber ON OrderParticipants(CertificateNumber) WHERE CertificateNumber IS NOT NULL;

PRINT 'Indeksy na OrderParticipants utworzone.';
GO

-- Indeksy na tabeli Reviews
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Reviews_OrderID' AND object_id = OBJECT_ID('Reviews'))
    CREATE NONCLUSTERED INDEX IX_Reviews_OrderID ON Reviews(OrderID);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Reviews_Status' AND object_id = OBJECT_ID('Reviews'))
    CREATE NONCLUSTERED INDEX IX_Reviews_Status ON Reviews(Status);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Reviews_Rating' AND object_id = OBJECT_ID('Reviews'))
    CREATE NONCLUSTERED INDEX IX_Reviews_Rating ON Reviews(Rating DESC);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Reviews_ReviewDate' AND object_id = OBJECT_ID('Reviews'))
    CREATE NONCLUSTERED INDEX IX_Reviews_ReviewDate ON Reviews(ReviewDate DESC);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Reviews_ParticipantID' AND object_id = OBJECT_ID('Reviews'))
    CREATE NONCLUSTERED INDEX IX_Reviews_ParticipantID ON Reviews(ParticipantID) WHERE ParticipantID IS NOT NULL;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Reviews_ClientID' AND object_id = OBJECT_ID('Reviews'))
    CREATE NONCLUSTERED INDEX IX_Reviews_ClientID ON Reviews(ClientID) WHERE ClientID IS NOT NULL;

PRINT 'Indeksy na Reviews utworzone.';
GO

-- Indeksy na tabeli OrderStatusHistory
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_OrderStatusHistory_OrderID' AND object_id = OBJECT_ID('OrderStatusHistory'))
    CREATE NONCLUSTERED INDEX IX_OrderStatusHistory_OrderID ON OrderStatusHistory(OrderID);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_OrderStatusHistory_ChangedAt' AND object_id = OBJECT_ID('OrderStatusHistory'))
    CREATE NONCLUSTERED INDEX IX_OrderStatusHistory_ChangedAt ON OrderStatusHistory(ChangedAt DESC);

PRINT 'Indeksy na OrderStatusHistory utworzone.';
GO

-- =============================================
-- KONIEC TWORZENIA INDEKSÓW
-- =============================================

PRINT '';
PRINT '========================================';
PRINT 'PODSUMOWANIE:';
PRINT '- 3 indeksy Full-Text (Products, Trainers, Reviews)';
PRINT '- 2 indeksy Spatial (Clients, Orders)';
PRINT '- ~30 indeksów B-tree (klucze obce, filtry, sortowania)';
PRINT '========================================';
GO