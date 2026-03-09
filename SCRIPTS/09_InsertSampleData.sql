-- =============================================
-- WSTAWIANIE DANYCH TESTOWYCH - SYSTEM ZARZĄDZANIA SZKOLENIAMI
-- Skrypt: 09_InsertSampleData.sql
-- =============================================

USE TrainingSystemDB;
GO

PRINT 'Rozpoczęcie wstawiania danych testowych...';
GO

-- =============================================
-- 1. CLIENTS - Klienci
-- =============================================

SET IDENTITY_INSERT Clients ON;

INSERT INTO Clients (ClientID, ClientType, FirstName, LastName, CompanyName, TaxID, Email, Phone, Street, BuildingNumber, PostalCode, City, Country, Location, AdditionalInfo, TotalOrdersValue, DiscountPercent, Status, MarketingConsent, IsDeleted, CreatedAt)
VALUES
-- Klienci indywidualni
(1, 'Individual', 'Jan', 'Kowalski', NULL, NULL, 'jan.kowalski@email.pl', '+48123456789', 'Marszałkowska', '1', '00-001', 'Warszawa', 'Polska', geography::Point(52.2297, 21.0122, 4326), 
 '{"survey": {"interests": ["Excel", "Power BI"], "experience": "intermediate"}, "notes": "Preferuje szkolenia weekendowe", "source": "Google Ads"}', 
 0, 0, 'Potential', 1, 0, '2025-01-15'),

(2, 'Individual', 'Anna', 'Nowak', NULL, NULL, 'anna.nowak@gmail.com', '+48987654321', 'Floriańska', '5', '31-019', 'Kraków', 'Polska', geography::Point(50.0647, 19.9450, 4326),
 '{"survey": {"interests": ["Python", "Machine Learning"], "experience": "beginner"}, "source": "Facebook"}',
 0, 0, 'Potential', 1, 0, '2025-01-20'),

-- Klienci firmowi
(3, 'Company', NULL, NULL, 'ABC Sp. z o.o.', '1234567890', 'biuro@abc.pl', '+48111222333', 'Piotrkowska', '100', '90-001', 'Łódź', 'Polska', geography::Point(51.7592, 19.4560, 4326),
 '{"notes": "Duża firma, regularne szkolenia dla działów", "contact_person": "Marek Wiśniewski"}',
 0, 0, 'Potential', 1, 0, '2024-11-10'),

(4, 'Company', NULL, NULL, 'TechCorp Polska', '9876543210', 'hr@techcorp.pl', '+48444555666', 'Grunwaldzka', '50', '80-244', 'Gdańsk', 'Polska', geography::Point(54.3520, 18.6466, 4326),
 '{"notes": "Stały klient, szkolenia IT", "contact_person": "Karolina Zielińska", "preferred_trainer": "Excel specialist"}',
 0, 0, 'Potential', 1, 0, '2024-09-05'),

(5, 'Company', NULL, NULL, 'BiznesMax', '5555666777', 'szkolenia@biznesmax.pl', '+48777888999', 'Kwiatowa', '15', '60-001', 'Poznań', 'Polska', geography::Point(52.4064, 16.9252, 4326),
 '{"notes": "Szkolenia sprzedażowe i soft skills"}',
 0, 0, 'Potential', 1, 0, '2024-10-12');

SET IDENTITY_INSERT Clients OFF;

PRINT 'Clients: 5 rekordów wstawionych.';
GO

-- =============================================
-- 2. PARTICIPANTS - Uczestnicy
-- =============================================

SET IDENTITY_INSERT Participants ON;

INSERT INTO Participants (ParticipantID, FirstName, LastName, Email, Phone, SpecialRequirements, CreatedAt)
VALUES
(1, 'Piotr', 'Nowicki', 'piotr.nowicki@abc.pl', '+48111222333', NULL, '2024-11-15'),
(2, 'Magdalena', 'Kowal', 'magdalena.kowal@abc.pl', '+48111222334', 'Dieta wegetariańska', '2024-11-15'),
(3, 'Tomasz', 'Lewandowski', 'tomasz.lewandowski@abc.pl', '+48111222335', NULL, '2024-11-15'),
(4, 'Katarzyna', 'Zając', 'katarzyna.zajac@techcorp.pl', '+48444555667', NULL, '2024-12-01'),
(5, 'Michał', 'Kaczmarek', 'michal.kaczmarek@techcorp.pl', '+48444555668', NULL, '2024-12-01'),
(6, 'Joanna', 'Wójcik', 'joanna.wojcik@techcorp.pl', '+48444555669', 'Potrzebny dostęp dla wózka inwalidzkiego', '2024-12-01'),
(7, 'Marcin', 'Szymański', 'marcin.szymanski@biznesmax.pl', '+48777888991', NULL, '2024-12-10'),
(8, 'Agnieszka', 'Dąbrowska', 'agnieszka.dabrowska@biznesmax.pl', '+48777888992', NULL, '2024-12-10');

SET IDENTITY_INSERT Participants OFF;

PRINT 'Participants: 8 rekordów wstawionych.';
GO

-- =============================================
-- 3. TRAINERS - Trenerzy
-- =============================================

SET IDENTITY_INSERT Trainers ON;

INSERT INTO Trainers (TrainerID, FirstName, LastName, Email, Phone, CompetencyDescription, Bio, PhotoURL, HourlyRate, DailyRate, EmploymentType, Availability, IsActive, AverageRating, CreatedAt)
VALUES
(1, 'Robert', 'Kowalczyk', 'robert.kowalczyk@trainers.pl', '+48500100200', 
 'Specjalista Excel: tabele przestawne, Power Query, Power Pivot, VBA, makra. 15 lat doświadczenia w szkoleniach korporacyjnych. Certyfikat Microsoft Office Specialist Expert. Specjalizacja w analityce finansowej i controlingu. Prowadzę szkolenia dla banków, firm ubezpieczeniowych i działów finansowych.',
 'Trener z pasją do Excela i automatyzacji procesów biznesowych.', 
 NULL, NULL, 2500, 'B2B', 
 '{"preferred_days": ["Monday", "Tuesday", "Wednesday"], "max_distance_km": 100, "willing_to_travel": true}',
 1, NULL, '2023-05-10'),

(2, 'Marta', 'Wiśniewska', 'marta.wisniewska@trainers.pl', '+48500200300',
 'Ekspertka Power BI i wizualizacji danych. DAX, Power Query, modelowanie danych. Certyfikat Microsoft Certified: Data Analyst Associate. Doświadczenie w tworzeniu dashboardów dla zarządów firm. Szkolenia z Business Intelligence, raportowania i self-service BI. Praktyczne case studies z prawdziwych projektów.',
 'Pasjonatka danych i storytellingu przez wizualizację.',
 NULL, 250, NULL, 'Contractor',
 '{"preferred_days": ["Thursday", "Friday"], "max_distance_km": 200, "willing_to_travel": true}',
 1, NULL, '2023-06-15'),

(3, 'Andrzej', 'Zieliński', 'andrzej.zielinski@trainers.pl', '+48500300400',
 'Trener SQL i baz danych. SQL Server, MySQL, PostgreSQL. Projektowanie baz danych, optymalizacja zapytań, indeksy, procedury składowane. 10 lat jako DBA w korporacji, teraz freelancer. Szkolenia dla programistów, analityków danych i administratorów. Nauka przez praktykę - dużo ćwiczeń i case studies.',
 'Z korporacji do szkoleń - dzielę się wiedzą praktyczną.',
 NULL, NULL, 2000, 'Freelance',
 '{"preferred_days": ["Monday", "Wednesday", "Friday"], "max_distance_km": 50, "willing_to_travel": false}',
 1, NULL, '2023-08-20'),

(4, 'Karolina', 'Mazur', 'karolina.mazur@trainers.pl', '+48500400500',
 'Soft skills i sprzedaż. Komunikacja interpersonalna, negocjacje, prezentacje, public speaking, leadership. 12 lat w sprzedaży B2B, 5 lat jako trener. Szkolenia dla zespołów sprzedażowych, managerów, customer service. Interaktywne warsztaty, role-play, feedback. Certyfikat trenera biznesu.',
 'Uczę ludzi skutecznej komunikacji i sprzedaży.',
 NULL, 200, NULL, 'Employee',
 '{"preferred_days": ["Tuesday", "Thursday"], "max_distance_km": 150}',
 1, NULL, '2023-09-01');

SET IDENTITY_INSERT Trainers OFF;

PRINT 'Trainers: 4 rekordów wstawionych.';
GO

-- =============================================
-- 4. PRODUCTS - Produkty
-- =============================================

SET IDENTITY_INSERT Products ON;

INSERT INTO Products (ProductID, ProductType, ProductName, Description, BasePrice, DurationHours, Level, Category, TechnicalRequirements, IsActive, CreatedAt)
VALUES
-- MODUŁY
(1, 'Module', 'Excel - Tabele Przestawne', 
 'Moduł poświęcony tabelom przestawnym (pivot tables) w Excel. Uczestnicy nauczą się tworzyć zaawansowane analizy danych, grupować, filtrować, używać formatowania warunkowego w pivot tables. Praktyczne przykłady z analizy sprzedaży, budżetowania i raportowania.',
 600, 4, 'Intermediate', 'Office',
 '{"software": ["Microsoft Excel 2016 lub nowszy"], "hardware": ["Laptop", "Mysz (zalecana)"], "preparation": ["Instalacja przykładowych danych - link w emailu"]}',
 1, '2024-01-10'),

(2, 'Module', 'Excel - Power Query',
 'Power Query to narzędzie do automatyzacji pobierania i przekształcania danych. Moduł uczy importu danych z różnych źródeł (CSV, Excel, bazy danych, web), czyszczenia danych, transformacji, łączenia tabel. Automatyzacja miesięcznych raportów. Język M - podstawy.',
 700, 4, 'Advanced', 'Office',
 '{"software": ["Microsoft Excel 2016+ z Power Query"], "hardware": ["Laptop", "Min 8GB RAM"]}',
 1, '2024-01-10'),

(3, 'Module', 'Excel - VBA Podstawy',
 'Wprowadzenie do programowania w VBA (Visual Basic for Applications). Tworzenie makr, automatyzacja powtarzalnych zadań, obsługa zdarzeń, pętle, warunki. Praktyczne przykłady: automatyczne formatowanie, generowanie raportów, walidacja danych.',
 800, 6, 'Advanced', 'Office',
 '{"software": ["Microsoft Excel 2016+"], "hardware": ["Laptop"], "preparation": ["Włączenie zakładki Developer w Excel"]}',
 1, '2024-01-10'),

(4, 'Module', 'Power BI - Wprowadzenie',
 'Podstawy Power BI Desktop. Import danych, modelowanie (relacje, kardinalność), podstawowe wizualizacje (wykresy, tabele, karty). Publikowanie raportów do Power BI Service. Interaktywne dashboardy.',
 650, 4, 'Beginner', 'DataAnalysis',
 '{"software": ["Power BI Desktop (darmowy)"], "hardware": ["Laptop", "Min 8GB RAM"], "preparation": ["Instalacja Power BI Desktop przed szkoleniem"]}',
 1, '2024-01-15'),

(5, 'Module', 'Power BI - DAX',
 'Data Analysis Expressions (DAX) - język formuł w Power BI. Miary (measures), kolumny kalkulowane, funkcje agregujące (SUM, AVERAGE, COUNT), funkcje czasowe (time intelligence), kontekst filtrowania. Zaawansowane analizy: YoY, MoM, running totals.',
 750, 6, 'Advanced', 'DataAnalysis',
 '{"software": ["Power BI Desktop"], "hardware": ["Laptop"], "note": ["Wymagana znajomość Power BI podstaw"]}',
 1, '2024-01-15'),

(6, 'Module', 'SQL - SELECT i JOIN',
 'Podstawy SQL: SELECT, WHERE, ORDER BY, GROUP BY, HAVING. Łączenie tabel: INNER JOIN, LEFT JOIN, RIGHT JOIN, FULL JOIN. Podzapytania (subqueries). Praktyczne ćwiczenia na bazie przykładowej (sklep internetowy).',
 700, 6, 'Beginner', 'Programming',
 '{"software": ["SQL Server Management Studio lub DBeaver"], "hardware": ["Laptop"], "preparation": ["Instalacja SSMS przed szkoleniem"]}',
 1, '2024-01-20'),

(7, 'Module', 'Prezentacje które przekonują',
 'Moduł soft skills: jak budować efektywne prezentacje. Struktura prezentacji, storytelling, wizualizacja danych, design slajdów. Praktyczne ćwiczenia: każdy uczestnik przygotowuje i prezentuje krótką prezentację. Feedback od trenera i grupy.',
 500, 4, 'Beginner', 'SoftSkills',
 '{"software": ["PowerPoint lub Google Slides"], "hardware": ["Laptop"]}',
 1, '2024-02-01'),

-- SZKOLENIA
(8, 'Training', 'Excel Zaawansowany',
 'Dwudniowe szkolenie z zaawansowanego Excela. Program obejmuje: tabele przestawne, Power Query do automatyzacji raportów, wprowadzenie do VBA. Szkolenie dla osób znających podstawy Excela, które chcą podnieść efektywność pracy. Dużo praktyki - uczestnicy pracują na własnych laptopach. Certyfikat ukończenia.',
 2200, 16, 'Advanced', 'Office',
 '{"software": ["Microsoft Excel 2016 lub nowszy"], "hardware": ["Laptop własny uczestnika", "Mysz"], "preparation": ["Przykładowe pliki Excel do pobrania przed szkoleniem"]}',
 1, '2024-01-10'),

(9, 'Training', 'Power BI - od podstaw do zaawansowanych',
 'Kompleksowe szkolenie Power BI. Dzień 1: Wprowadzenie, import danych, wizualizacje. Dzień 2: DAX, zaawansowane analizy, publikowanie. Dla analityków, controllerów, managerów. Uczestnicy tworzą własny dashboard na prawdziwych danych.',
 2400, 16, 'Intermediate', 'DataAnalysis',
 '{"software": ["Power BI Desktop"], "hardware": ["Laptop", "Min 8GB RAM"], "preparation": ["Instalacja Power BI Desktop"]}',
 1, '2024-01-15'),

(10, 'Training', 'SQL dla analityków',
 'Jednodniowe intensywne szkolenie SQL dla osób pracujących z danymi. SELECT, JOIN, agregacje, podzapytania. Praca na przykładowej bazie danych (e-commerce). Dużo ćwiczeń praktycznych. Dla analityków biznesowych, controllerów, marketerów.',
 1200, 8, 'Beginner', 'Programming',
 '{"software": ["SQL Server lub MySQL"], "hardware": ["Laptop"]}',
 1, '2024-01-20'),

-- KURSY
(11, 'Course', 'Akademia Analityka Danych',
 'Kompleksowy 5-dniowy kurs dla przyszłych analityków danych. Program: Excel Zaawansowany (2 dni), Power BI (2 dni), SQL (1 dzień). Certyfikat ukończenia Akademii. Idealne dla osób zmieniających karierę na analitykę lub dla pracowników chcących rozwinąć kompetencje. Małe grupy (max 10 osób), indywidualne podejście.',
 5500, 40, 'Intermediate', 'DataAnalysis',
 '{"software": ["Excel 2016+", "Power BI Desktop", "SQL Server"], "hardware": ["Laptop własny", "Min 8GB RAM"], "preparation": ["Instalacja oprogramowania przed kursem - instrukcje w emailu"]}',
 1, '2024-01-25');

SET IDENTITY_INSERT Products OFF;

PRINT 'Products: 11 rekordów wstawionych.';
GO

-- =============================================
-- 5. PRODUCT HIERARCHY - Hierarchia produktów
-- =============================================

SET IDENTITY_INSERT ProductHierarchy ON;

INSERT INTO ProductHierarchy (HierarchyID, ParentProductID, ChildProductID, SequenceOrder, IsRequired)
VALUES
-- Szkolenie "Excel Zaawansowany" (ID=8) składa się z modułów:
(1, 8, 1, 1, 1),
(2, 8, 2, 2, 1),
(3, 8, 3, 3, 1),

-- Szkolenie "Power BI" (ID=9) składa się z modułów:
(4, 9, 4, 1, 1),
(5, 9, 5, 2, 1),

-- Szkolenie "SQL dla analityków" (ID=10):
(6, 10, 6, 1, 1),

-- Kurs "Akademia Analityka Danych" (ID=11) składa się ze szkoleń:
(7, 11, 8, 1, 1),
(8, 11, 9, 2, 1),
(9, 11, 10, 3, 1);

SET IDENTITY_INSERT ProductHierarchy OFF;

PRINT 'ProductHierarchy: 9 rekordów wstawionych.';
GO

-- =============================================
-- 6. ORDERS - Zamówienia
-- =============================================

SET IDENTITY_INSERT Orders ON;

INSERT INTO Orders (OrderID, ClientID, OrderDate, Status, DiscountPercent, PlannedStartDate, PlannedEndDate, ActualStartDate, ActualEndDate, VenueName, VenueAddress, VenueLocation, LeadTrainerID, InvoiceNumber, InvoiceIssueDate, SpecialRequirements, CreatedBy, CreatedAt)
VALUES
(1, 3, '2024-11-15', 'Completed', 0, '2024-12-01', '2024-12-02', '2024-12-01', '2024-12-02',
 'Siedziba ABC Sp. z o.o. - sala konferencyjna', 'Piotrkowska 100, 90-001 Łódź', geography::Point(51.7592, 19.4560, 4326),
 1, 'FV/2024/12/001', '2024-12-05',
 '{"preferred_hours": "9:00-17:00", "lunch": true, "coffee_breaks": 2, "av_equipment": ["projektor", "flipchart"], "participants_count": 3}',
 NULL, '2024-11-15'),

(2, 4, '2024-12-05', 'Completed', 0, '2024-12-15', '2024-12-16', '2024-12-15', '2024-12-16',
 'Hotel Marriott Gdańsk - sala szkoleniowa B', 'ul. Jelitkowska 20, 80-342 Gdańsk', geography::Point(54.4184, 18.5698, 4326),
 2, 'FV/2024/12/002', '2024-12-20',
 '{"preferred_hours": "9:00-16:00", "lunch": true, "participants_count": 3}',
 NULL, '2024-12-05'),

(3, 5, '2024-12-20', 'InProgress', 0, '2025-01-10', '2025-01-10', '2025-01-10', NULL,
 'Siedziba BiznesMax - sala szkoleniowa', 'Kwiatowa 15, 60-001 Poznań', geography::Point(52.4064, 16.9252, 4326),
 4, NULL, NULL,
 '{"preferred_hours": "10:00-18:00", "lunch": true, "participants_count": 2}',
 NULL, '2024-12-20'),

(4, 1, '2025-01-20', 'Confirmed', 0, '2025-02-15', '2025-02-15', NULL, NULL,
 'Hotel Novotel Warszawa Centrum', 'ul. Marszałkowska 94/98, 00-510 Warszawa', geography::Point(52.2290, 21.0118, 4326),
 3, NULL, NULL,
 '{"preferred_hours": "9:00-17:00"}',
 NULL, '2025-01-20'),

(5, 3, '2025-01-25', 'New', 0, '2025-03-10', '2025-03-14', NULL, NULL,
 'Siedziba ABC Sp. z o.o.', 'Piotrkowska 100, 90-001 Łódź', geography::Point(51.7592, 19.4560, 4326),
 NULL, NULL, NULL,
 '{"participants_count": 5}',
 NULL, '2025-01-25');

SET IDENTITY_INSERT Orders OFF;

PRINT 'Orders: 5 rekordów wstawionych.';
GO

-- =============================================
-- 7. ORDER ITEMS - Pozycje zamówień
-- =============================================

SET IDENTITY_INSERT OrderItems ON;

INSERT INTO OrderItems (OrderItemID, OrderID, ProductID, UnitPrice, Quantity, Notes)
VALUES
(1, 1, 8, 2200, 1, 'Szkolenie dla 3 pracowników działu finansowego'),
(2, 2, 9, 2400, 1, 'Szkolenie dla analityków'),
(3, 3, 7, 500, 1, 'Szkolenie dla zespołu sprzedaży'),
(4, 4, 10, 1200, 1, NULL),
(5, 5, 11, 5500, 1, 'Pakiet dla 5 pracowników');

SET IDENTITY_INSERT OrderItems OFF;

PRINT 'OrderItems: 5 rekordów wstawionych.';
GO

-- =============================================
-- 8. ORDER PARTICIPANTS - Uczestnicy zamówień
-- =============================================

SET IDENTITY_INSERT OrderParticipants ON;

INSERT INTO OrderParticipants (OrderParticipantID, OrderID, ParticipantID, ClientID, AttendanceStatus, CertificateIssued, CertificateNumber, CertificateIssuedDate, Notes, CreatedAt)
VALUES
(1, 1, 1, 3, 'Attended', 1, 'CERT-2024-12-001', '2024-12-03', NULL, '2024-11-15'),
(2, 1, 2, 3, 'Attended', 1, 'CERT-2024-12-002', '2024-12-03', NULL, '2024-11-15'),
(3, 1, 3, 3, 'Attended', 1, 'CERT-2024-12-003', '2024-12-03', NULL, '2024-11-15'),
(4, 2, 4, 4, 'Attended', 1, 'CERT-2024-12-004', '2024-12-17', NULL, '2024-12-05'),
(5, 2, 5, 4, 'Attended', 1, 'CERT-2024-12-005', '2024-12-17', NULL, '2024-12-05'),
(6, 2, 6, 4, 'Absent', 0, NULL, NULL, 'Nieobecność z powodu choroby', '2024-12-05'),
(7, 3, 7, 5, 'Registered', 0, NULL, NULL, NULL, '2024-12-20'),
(8, 3, 8, 5, 'Registered', 0, NULL, NULL, NULL, '2024-12-20');

SET IDENTITY_INSERT OrderParticipants OFF;

PRINT 'OrderParticipants: 8 rekordów wstawionych.';
GO

-- =============================================
-- 9. REVIEWS - Opinie
-- =============================================

SET IDENTITY_INSERT Reviews ON;

INSERT INTO Reviews (ReviewID, OrderID, ReviewerType, ParticipantID, ClientID, Rating, RatingTrainer, RatingMaterials, RatingOrganization, RatingUsefulness, Comment, IsAnonymous, IsVerified, Status, ReviewDate, CompanyResponse, ResponseDate, HelpfulCount, NotHelpfulCount, CreatedAt)
VALUES
(1, 1, 'Client', NULL, 3, 5, 5, 5, 5, 5,
 'Fantastyczne szkolenie z Excela! Trener Robert świetnie tłumaczył zagadnienia Power Query i tabel przestawnych. Materiały były obszerne i praktyczne. Pracownicy bardzo zadowoleni, już stosują wiedzę w codziennej pracy. Polecam gorąco!',
 0, 1, 'Approved', '2024-12-05', NULL, NULL, 5, 0, '2024-12-05'),

(2, 2, 'Participant', 4, NULL, 4, 5, 3, 4, 5,
 'Szkolenie Power BI bardzo pomocne. Trenerka Marta doskonale zna DAX i modelowanie danych. Jedyna uwaga - materiały mogłyby być bardziej aktualne, kilka screenshotów było ze starszej wersji Power BI. Poza tym super, nauczyłem się tworzyć dashboardy.',
 0, 1, 'Approved', '2024-12-18', 
 'Dziękujemy za feedback! Materiały zostały zaktualizowane do najnowszej wersji Power BI. Cieszymy się, że szkolenie było pomocne!',
 '2024-12-19', 3, 0, '2024-12-18'),

(3, 2, 'Client', NULL, 4, 5, 5, 4, 5, 5,
 'Świetna inwestycja w rozwój naszych analityków. Po szkoleniu Power BI zespół zaczął tworzyć profesjonalne raporty dla zarządu. Trenerka bardzo kompetentna, cierpliwa, odpowiadała na wszystkie pytania. Organizacja bez zarzutu. Będziemy zamawiać kolejne szkolenia!',
 0, 1, 'Approved', '2024-12-20', NULL, NULL, 8, 0, '2024-12-20');

SET IDENTITY_INSERT Reviews OFF;

PRINT 'Reviews: 3 rekordów wstawionych.';
GO

-- =============================================
-- AKTUALIZACJA TRIGGERÓW - uruchomienie logiki biznesowej
-- =============================================

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
), 0);

UPDATE Clients
SET DiscountPercent = CASE
    WHEN TotalOrdersValue >= 50000 THEN 15
    WHEN TotalOrdersValue >= 10000 THEN 10
    ELSE 0
END,
Status = CASE 
    WHEN TotalOrdersValue > 0 AND Status = 'Potential' THEN 'Active'
    ELSE Status
END;

UPDATE Trainers
SET AverageRating = (
    SELECT AVG(CAST(r.RatingTrainer AS DECIMAL(3,2)))
    FROM Reviews r
    INNER JOIN Orders o ON r.OrderID = o.OrderID
    WHERE o.LeadTrainerID = Trainers.TrainerID
      AND r.RatingTrainer IS NOT NULL
      AND r.Status = 'Approved'
);

PRINT 'TotalOrdersValue, DiscountPercent i AverageRating zaktualizowane.';
GO

-- =============================================
-- PODSUMOWANIE
-- =============================================

PRINT '';
PRINT '========================================';
PRINT 'DANE TESTOWE WSTAWIONE POMYŚLNIE!';
PRINT '========================================';
PRINT 'Clients: 5 (2 indywidualnych, 3 firmowych)';
PRINT 'Participants: 8';
PRINT 'Trainers: 4';
PRINT 'Products: 11 (7 modułów, 3 szkolenia, 1 kurs)';
PRINT 'ProductHierarchy: 9 relacji';
PRINT 'Orders: 5 (różne statusy: Completed, InProgress, Confirmed, New)';
PRINT 'OrderItems: 5';
PRINT 'OrderParticipants: 8';
PRINT 'Reviews: 3 (z komentarzami dla Full-Text)';
PRINT '';
PRINT 'DANE GOTOWE DO TESTOWANIA:';
PRINT '- Full-Text Search: opisy produktów, kompetencje trenerów, opinie';
PRINT '- Spatial Data: lokalizacje w Warszawie, Krakowie, Łodzi, Gdańsku, Poznaniu';
PRINT '- Triggery: TotalOrdersValue i rabaty zaktualizowane';
PRINT '- Hierarchia produktów: kurs → szkolenia → moduły';
PRINT '========================================';
GO