-- =============================================
-- TWORZENIE TABEL - SYSTEM ZARZĄDZANIA SZKOLENIAMI
-- =============================================

USE TrainingSystemDB;
GO

-- =============================================
-- 1. TABELA: Clients
-- =============================================
CREATE TABLE Clients (
    ClientID INT IDENTITY(1,1) PRIMARY KEY,
    ClientType NVARCHAR(20) NOT NULL CHECK (ClientType IN ('Individual', 'Company')),
    FirstName NVARCHAR(100) NULL,
    LastName NVARCHAR(100) NULL,
    CompanyName NVARCHAR(250) NULL,
    TaxID VARCHAR(20) NULL,
    Email NVARCHAR(255) NOT NULL UNIQUE,
    Phone VARCHAR(20) NULL,
    AlternativePhone VARCHAR(20) NULL,
    Street NVARCHAR(200) NULL,
    BuildingNumber VARCHAR(20) NULL,
    PostalCode VARCHAR(10) NULL,
    City NVARCHAR(100) NULL,
    Country NVARCHAR(100) DEFAULT 'Polska',
    Location GEOGRAPHY NULL,
    AdditionalInfo NVARCHAR(MAX) NULL CHECK (ISJSON(AdditionalInfo) = 1 OR AdditionalInfo IS NULL),
    TotalOrdersValue DECIMAL(10,2) DEFAULT 0,
    DiscountPercent TINYINT DEFAULT 0 CHECK (DiscountPercent BETWEEN 0 AND 15),
    Status VARCHAR(20) DEFAULT 'Potential' CHECK (Status IN ('Active', 'Inactive', 'Potential')),
    MarketingConsent BIT DEFAULT 0,
    IsDeleted BIT DEFAULT 0,
    DeletedAt DATETIME2 NULL,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT CHK_Clients_TypeData CHECK (
        (ClientType = 'Individual' AND FirstName IS NOT NULL AND LastName IS NOT NULL) OR
        (ClientType = 'Company' AND CompanyName IS NOT NULL)
    )
);
GO

-- =============================================
-- 2. TABELA: Participants
-- =============================================
CREATE TABLE Participants (
    ParticipantID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(255) NOT NULL UNIQUE,
    Phone VARCHAR(20) NULL,
    SpecialRequirements NVARCHAR(500) NULL,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE()
);
GO

-- =============================================
-- 3. TABELA: Trainers
-- =============================================
CREATE TABLE Trainers (
    TrainerID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(255) NOT NULL UNIQUE,
    Phone VARCHAR(20) NULL,
    CompetencyDescription NVARCHAR(MAX) NULL,
    Bio NVARCHAR(MAX) NULL,
    PhotoURL VARCHAR(500) NULL,
    HourlyRate DECIMAL(10,2) NULL,
    DailyRate DECIMAL(10,2) NULL,
    EmploymentType VARCHAR(20) CHECK (EmploymentType IN ('Employee', 'Contractor', 'B2B', 'Freelance')),
    Availability NVARCHAR(MAX) NULL CHECK (ISJSON(Availability) = 1 OR Availability IS NULL),
    IsActive BIT DEFAULT 1,
    AverageRating DECIMAL(3,2) NULL CHECK (AverageRating BETWEEN 1 AND 5),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE()
);
GO

-- =============================================
-- 4. TABELA: Products
-- =============================================
CREATE TABLE Products (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductType VARCHAR(10) NOT NULL CHECK (ProductType IN ('Module', 'Training', 'Course')),
    ProductName NVARCHAR(200) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    BasePrice DECIMAL(10,2) NULL,
    DurationHours DECIMAL(4,1) NULL,
    Level VARCHAR(20) CHECK (Level IN ('Beginner', 'Intermediate', 'Advanced')),
    Category VARCHAR(50) NULL,
    TechnicalRequirements NVARCHAR(MAX) NULL CHECK (ISJSON(TechnicalRequirements) = 1 OR TechnicalRequirements IS NULL),
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE()
);
GO

-- =============================================
-- 5. TABELA: ProductHierarchy
-- =============================================
CREATE TABLE ProductHierarchy (
    HierarchyID INT IDENTITY(1,1) PRIMARY KEY,
    ParentProductID INT NOT NULL,
    ChildProductID INT NOT NULL,
    SequenceOrder INT NULL,
    IsRequired BIT DEFAULT 1,
    CONSTRAINT FK_ProductHierarchy_Parent FOREIGN KEY (ParentProductID) REFERENCES Products(ProductID) ON DELETE NO ACTION,
    CONSTRAINT FK_ProductHierarchy_Child FOREIGN KEY (ChildProductID) REFERENCES Products(ProductID) ON DELETE NO ACTION
);
GO

-- =============================================
-- 6. TABELA: Orders
-- =============================================
CREATE TABLE Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    ClientID INT NOT NULL,
    OrderDate DATETIME2 DEFAULT GETDATE(),
    Status VARCHAR(20) DEFAULT 'New' CHECK (Status IN ('New', 'Confirmed', 'InProgress', 'Completed', 'Cancelled', 'Archived')),
    DiscountPercent TINYINT DEFAULT 0 CHECK (DiscountPercent BETWEEN 0 AND 15),
    PlannedStartDate DATE NOT NULL,
    PlannedEndDate DATE NOT NULL,
    ActualStartDate DATE NULL,
    ActualEndDate DATE NULL,
    VenueName NVARCHAR(200) NULL,
    VenueAddress NVARCHAR(500) NULL,
    VenueLocation GEOGRAPHY NULL,
    LeadTrainerID INT NULL,
    InvoiceNumber VARCHAR(50) NULL,
    InvoiceIssueDate DATE NULL,
    SpecialRequirements NVARCHAR(MAX) NULL CHECK (ISJSON(SpecialRequirements) = 1 OR SpecialRequirements IS NULL),
    CreatedBy INT NULL,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Orders_Clients FOREIGN KEY (ClientID) REFERENCES Clients(ClientID) ON DELETE NO ACTION,
    CONSTRAINT FK_Orders_Trainers FOREIGN KEY (LeadTrainerID) REFERENCES Trainers(TrainerID) ON DELETE SET NULL
);
GO

-- =============================================
-- 7. TABELA: OrderItems
-- =============================================
CREATE TABLE OrderItems (
    OrderItemID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    Quantity INT DEFAULT 1,
    Notes NVARCHAR(500) NULL,
    CONSTRAINT FK_OrderItems_Orders FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) ON DELETE CASCADE,
    CONSTRAINT FK_OrderItems_Products FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE NO ACTION
);
GO

-- =============================================
-- 8. TABELA: OrderParticipants
-- =============================================
CREATE TABLE OrderParticipants (
    OrderParticipantID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    ParticipantID INT NOT NULL,
    ClientID INT NOT NULL,
    AttendanceStatus VARCHAR(20) DEFAULT 'Registered' CHECK (AttendanceStatus IN ('Registered', 'Attended', 'Absent', 'Cancelled')),
    CertificateIssued BIT DEFAULT 0,
    CertificateNumber VARCHAR(50) NULL,
    CertificateIssuedDate DATE NULL,
    Notes NVARCHAR(500) NULL,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_OrderParticipants_Orders FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) ON DELETE CASCADE,
    CONSTRAINT FK_OrderParticipants_Participants FOREIGN KEY (ParticipantID) REFERENCES Participants(ParticipantID) ON DELETE NO ACTION,
    CONSTRAINT FK_OrderParticipants_Clients FOREIGN KEY (ClientID) REFERENCES Clients(ClientID) ON DELETE NO ACTION
);
GO

-- Filtered UNIQUE index - tylko NOT NULL wartości muszą być unikalne
CREATE UNIQUE INDEX UQ_OrderParticipants_CertificateNumber 
ON OrderParticipants(CertificateNumber) 
WHERE CertificateNumber IS NOT NULL;
GO

-- =============================================
-- 9. TABELA: Reviews
-- =============================================
CREATE TABLE Reviews (
    ReviewID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    ReviewerType VARCHAR(20) NOT NULL CHECK (ReviewerType IN ('Participant', 'Client')),
    ParticipantID INT NULL,
    ClientID INT NULL,
    Rating TINYINT NOT NULL CHECK (Rating BETWEEN 1 AND 5),
    RatingTrainer TINYINT NULL CHECK (RatingTrainer BETWEEN 1 AND 5),
    RatingMaterials TINYINT NULL CHECK (RatingMaterials BETWEEN 1 AND 5),
    RatingOrganization TINYINT NULL CHECK (RatingOrganization BETWEEN 1 AND 5),
    RatingUsefulness TINYINT NULL CHECK (RatingUsefulness BETWEEN 1 AND 5),
    Comment NVARCHAR(MAX) NULL,
    IsAnonymous BIT DEFAULT 0,
    IsVerified BIT DEFAULT 0,
    Status VARCHAR(20) DEFAULT 'Pending' CHECK (Status IN ('Pending', 'Approved', 'Rejected', 'Spam')),
    ReviewDate DATETIME2 DEFAULT GETDATE(),
    CompanyResponse NVARCHAR(2000) NULL,
    ResponseDate DATETIME2 NULL,
    HelpfulCount INT DEFAULT 0,
    NotHelpfulCount INT DEFAULT 0,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Reviews_Orders FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) ON DELETE CASCADE,
    CONSTRAINT FK_Reviews_Participants FOREIGN KEY (ParticipantID) REFERENCES Participants(ParticipantID) ON DELETE SET NULL,
    CONSTRAINT FK_Reviews_Clients FOREIGN KEY (ClientID) REFERENCES Clients(ClientID) ON DELETE SET NULL,
    CONSTRAINT CHK_Reviews_Reviewer CHECK (
        (ParticipantID IS NOT NULL AND ClientID IS NULL) OR
        (ParticipantID IS NULL AND ClientID IS NOT NULL)
    )
);
GO

-- =============================================
-- 10. TABELA: OrderStatusHistory
-- =============================================
CREATE TABLE OrderStatusHistory (
    HistoryID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    OldStatus VARCHAR(20) NULL,
    NewStatus VARCHAR(20) NOT NULL,
    ChangedBy INT NULL,
    ChangedAt DATETIME2 DEFAULT GETDATE(),
    ChangeReason NVARCHAR(500) NULL,
    CONSTRAINT FK_OrderStatusHistory_Orders FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) ON DELETE CASCADE
);
GO

-- =============================================
-- KONIEC TWORZENIA TABEL
-- =============================================