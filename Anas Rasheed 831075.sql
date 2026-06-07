
-- Question no : 1
SELECT TOP 5
    c.CustomerID,
    c.Name AS CustomerName,
    SUM(so.TotalAmount) AS TotalSpent
FROM Customer c
INNER JOIN SalesOrder so
    ON c.CustomerID = so.CustomerID
GROUP BY
    c.CustomerID,
    c.Name
ORDER BY
    TotalSpent DESC;


	--Question no: 2
SELECT
    s.SupplierID,
    s.Name AS SupplierName,
    COUNT(DISTINCT pod.ProductID) AS ProductCount
FROM Supplier s
INNER JOIN PurchaseOrder po
    ON s.SupplierID = po.SupplierID
INNER JOIN PurchaseOrderDetail pod
    ON po.OrderID = pod.OrderID
GROUP BY
    s.SupplierID,
    s.Name
HAVING COUNT(DISTINCT pod.ProductID) > 10
ORDER BY ProductCount DESC;


--Question No :3
SELECT
    p.ProductID,
    p.Name AS ProductName,
    SUM(sod.Quantity) AS TotalOrderQuantity
FROM Product p
INNER JOIN SalesOrderDetail sod
    ON p.ProductID = sod.ProductID
WHERE NOT EXISTS (
    SELECT 1
    FROM ReturnDetail rd
    WHERE rd.ProductID = p.ProductID
)
GROUP BY
    p.ProductID,
    p.Name
ORDER BY
    TotalOrderQuantity DESC;

--Question No :4
SELECT
    c.CategoryID,
    c.Name AS CategoryName,
    p.Name AS ProductName,
    p.Price
FROM Product p
INNER JOIN Category c
    ON p.CategoryID = c.CategoryID
WHERE p.Price = (
    SELECT MAX(p2.Price)
    FROM Product p2
    WHERE p2.CategoryID = p.CategoryID
)
ORDER BY c.CategoryID;

--Question no : 05
SELECT
    so.OrderID,
    c.Name AS CustomerName,
    p.Name AS ProductName,
    cat.Name AS CategoryName,
    s.Name AS SupplierName,
    sod.Quantity
FROM SalesOrder so
INNER JOIN Customer c
    ON so.CustomerID = c.CustomerID
INNER JOIN SalesOrderDetail sod
    ON so.OrderID = sod.OrderID
INNER JOIN Product p
    ON sod.ProductID = p.ProductID
INNER JOIN Category cat
    ON p.CategoryID = cat.CategoryID
INNER JOIN PurchaseOrderDetail pod
    ON p.ProductID = pod.ProductID
INNER JOIN PurchaseOrder po
    ON pod.OrderID = po.OrderID
INNER JOIN Supplier s
    ON po.SupplierID = s.SupplierID
ORDER BY so.OrderID;

--Question NO : 06
SELECT 
    s.ShipmentID,
    l.Name AS WarehouseName,
    e.Name AS ManagerName,
    p.Name AS ProductName,
    sd.Quantity AS QuantityShipped,
    s.TrackingNumber
FROM Shipment s
JOIN Warehouse w ON s.WarehouseID = w.WarehouseID
JOIN Location l ON w.LocationID = l.LocationID
JOIN Employee e ON w.ManagerID = e.EmployeeID
JOIN ShipmentDetail sd ON s.ShipmentID = sd.ShipmentID
JOIN Product p ON sd.ProductID = p.ProductID;

--question no 07
WITH RankedOrders AS (
    SELECT 
        c.CustomerID,
        c.Name AS CustomerName,
        so.OrderID,
        so.TotalAmount,
        RANK() OVER (PARTITION BY c.CustomerID ORDER BY so.TotalAmount DESC) AS rnk
    FROM SalesOrder so
    JOIN Customer c ON so.CustomerID = c.CustomerID
)
SELECT 
    CustomerID,
    CustomerName,
    OrderID,
    TotalAmount
FROM RankedOrders
WHERE rnk <= 3
ORDER BY CustomerID, rnk;

--Question no : 08
SELECT 
    p.ProductID,
    p.Name AS ProductName,
    so.OrderID,
    so.OrderDate,
    sod.Quantity,
    LAG(sod.Quantity)  OVER (PARTITION BY p.ProductID ORDER BY so.OrderDate) AS PrevQuantity,
    LEAD(sod.Quantity) OVER (PARTITION BY p.ProductID ORDER BY so.OrderDate) AS NextQuantity
FROM SalesOrderDetail sod
JOIN SalesOrder so  ON sod.OrderID  = so.OrderID
JOIN Product p      ON sod.ProductID = p.ProductID
ORDER BY p.ProductID, so.OrderDate;

--question NO: 09
CREATE VIEW vw_CustomerOrderSummary AS
SELECT 
    c.CustomerID,
    c.Name                  AS CustomerName,
    COUNT(so.OrderID)       AS TotalOrders,
    SUM(so.TotalAmount)     AS TotalAmountSpent,
    MAX(so.OrderDate)       AS LastOrderDate
FROM Customer c
LEFT JOIN SalesOrder so ON c.CustomerID = so.CustomerID
GROUP BY c.CustomerID, c.Name;


-- Saare customers dekhne ke liye
SELECT * FROM vw_CustomerOrderSummary;

-- Sirf active/high-value customers filter karna ho
SELECT * 
FROM vw_CustomerOrderSummary
WHERE TotalOrders > 3
ORDER BY TotalAmountSpent DESC;

-- Specific customer dhundhna ho
SELECT *
FROM vw_CustomerOrderSummary
WHERE CustomerID = 98;


--question no: 10
CREATE PROCEDURE sp_GetSupplierSales
    @SupplierID INT
AS
BEGIN
    -- Validate: Supplier exists or not
    IF NOT EXISTS (SELECT 1 FROM Supplier WHERE SupplierID = @SupplierID)
    BEGIN
        RAISERROR('Supplier with ID %d does not exist.', 16, 1, @SupplierID);
        RETURN;
    END

    SELECT 
        s.SupplierID,
        s.Name                      AS SupplierName,
        p.ProductID,
        p.Name                      AS ProductName,
        SUM(sod.TotalAmount)        AS TotalSalesAmount
    FROM Supplier s
    JOIN PurchaseOrder po       ON s.SupplierID     = po.SupplierID
    JOIN PurchaseOrderDetail pod ON po.OrderID      = pod.OrderID
    JOIN Product p              ON pod.ProductID    = p.ProductID
    JOIN SalesOrderDetail sod   ON p.ProductID      = sod.ProductID
    GROUP BY 
        s.SupplierID,
        s.Name,
        p.ProductID,
        p.Name
    ORDER BY TotalSalesAmount DESC;
END;

-- SupplierID = 4 ke liye
EXEC sp_GetSupplierSales @SupplierID = 4;
