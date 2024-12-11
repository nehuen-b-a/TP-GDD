-------------------------------------------------------------------------------------------------
-- USO DE ESQUEMA
-------------------------------------------------------------------------------------------------

USE GD2C2024;
GO


-------------------------------------------------------------------------------------------------
-- PROCEDURES AUXILIARES
-------------------------------------------------------------------------------------------------

IF OBJECT_ID('NJRE.BI_borrar_fks') IS NOT NULL 
    DROP PROCEDURE NJRE.BI_borrar_fks
GO 
CREATE PROCEDURE NJRE.BI_borrar_fks AS
BEGIN
    DECLARE @query nvarchar(255) 
    DECLARE query_cursor CURSOR FOR 
    SELECT 'ALTER TABLE ' 
        + object_schema_name(k.parent_object_id) 
        + '.[' + Object_name(k.parent_object_id) 
        + '] DROP CONSTRAINT ' + k.NAME query 
    FROM sys.foreign_keys k
    WHERE Object_name(k.parent_object_id) LIKE 'BI_%'

    OPEN query_cursor 
    FETCH NEXT FROM query_cursor INTO @query 
    WHILE @@FETCH_STATUS = 0 
    BEGIN 
        EXEC sp_executesql @query 
        FETCH NEXT FROM query_cursor INTO @query 
    END

    CLOSE query_cursor 
    DEALLOCATE query_cursor 
END
GO 

IF OBJECT_ID('NJRE.BI_borrar_tablas') IS NOT NULL 
  DROP PROCEDURE NJRE.BI_borrar_tablas
GO 
CREATE PROCEDURE NJRE.BI_borrar_tablas AS
BEGIN
    DECLARE @query nvarchar(255) 
    DECLARE query_cursor CURSOR FOR  
        SELECT 'DROP TABLE NJRE.' + name
        FROM  sys.tables 
        WHERE schema_id = (
			SELECT schema_id 
			FROM sys.schemas
			WHERE name = 'NJRE'
		) AND name LIKE 'BI_%'
    
    OPEN query_cursor 
    FETCH NEXT FROM query_cursor INTO @query 
    WHILE @@FETCH_STATUS = 0 
    BEGIN 
        EXEC sp_executesql @query 
        FETCH NEXT FROM query_cursor INTO @query 
    END 

    CLOSE query_cursor 
    DEALLOCATE query_cursor
END
GO 

IF OBJECT_ID('NJRE.BI_borrar_procedimientos') IS NOT NULL 
    DROP PROCEDURE NJRE.BI_borrar_procedimientos
GO 
CREATE PROCEDURE NJRE.BI_borrar_procedimientos AS
BEGIN
    DECLARE @query nvarchar(255) 
    DECLARE query_cursor CURSOR FOR  
        SELECT 'DROP PROCEDURE NJRE.' + name
        FROM  sys.procedures 
        WHERE schema_id = (SELECT schema_id FROM sys.schemas WHERE name = 'NJRE') AND name LIKE 'bi_migrar_%'
    
    OPEN query_cursor 
    FETCH NEXT FROM query_cursor INTO @query 
    WHILE @@FETCH_STATUS = 0 
    BEGIN 
        EXEC sp_executesql @query 
        FETCH NEXT FROM query_cursor INTO @query 
    END 

    CLOSE query_cursor 
    DEALLOCATE query_cursor 
END
GO 


-------------------------------------------------------------------------------------------------
-- ELIMINACION DE TABLAS, FKS Y PROCEDURES
-------------------------------------------------------------------------------------------------

EXEC NJRE.BI_borrar_fks;
EXEC NJRE.BI_borrar_tablas;
EXEC NJRE.BI_borrar_procedimientos;

GO


-------------------------------------------------------------------------------------------------
-- CREACION DE TABLAS
-------------------------------------------------------------------------------------------------

-- Hechos

CREATE TABLE NJRE.BI_hecho_venta (
    hechoVenta_tiempo_id INT NOT NULL,
    hechoVenta_provinciaAlmacen_id NCHAR(2) NOT NULL,
    hechoVenta_localidadCliente_id INT NOT NULL,
    hechoVenta_rubro_id INT NOT NULL,
    hechoVenta_rangoEtarioCliente_id INT NOT NULL,
    hechoVenta_cantidadVentas DECIMAL(18, 0) NOT NULL,
    hechoVenta_totalVentas DECIMAL(18, 2) NOT NULL
);

CREATE TABLE NJRE.BI_hecho_publicacion (
    hechoPublicacion_tiempo_id INT NOT NULL,
    hechoPublicacion_subrubro_id INT NOT NULL,
    hechoPublicacion_marca_id INT NOT NULL,
    hechoPublicacion_totalDiasPublicaciones DECIMAL(18, 0) NOT NULL,
    hechoPublicacion_cantidadStockTotal DECIMAL(18, 0) NOT NULL,
	hechoPublicacion_cantidadPublicaciones DECIMAL(18, 0) NOT NULL,
);

CREATE TABLE NJRE.BI_hecho_pago (
    hechoPago_tiempo_id INT NOT NULL,
    hechoPago_medioPago_id INT NOT NULL,
    hechoPago_cuota_id INT NOT NULL,
    hechoPago_localidadCliente_id INT NOT NULL,
    hechoPago_tipoMedioPago_id INT NOT NULL,
    hechoPago_importeTotalCuotas DECIMAL(18, 2) NOT NULL
);

CREATE TABLE NJRE.BI_hecho_factura (
    hechoFactura_tiempo_id INT NOT NULL,
    hechoFactura_concepto_id INT NOT NULL,
    hechoFactura_provinciaVendedor_id NCHAR(2) NOT NULL,
    hechoFactura_montoFacturado DECIMAL(18, 2) NOT NULL
);

CREATE TABLE NJRE.BI_hecho_envio (
    hechoEnvio_tiempo_id INT NOT NULL,
    hechoEnvio_provinciaAlmacen_id NCHAR(2) NOT NULL,
    hechoEnvio_localidadCliente_id INT NOT NULL,
    hechoEnvio_tipoEnvio_id INT NOT NULL,
    hechoEnvio_cantidadEnvios DECIMAL(18, 0) NOT NULL,
    hechoEnvio_totalEnviosCumplidos DECIMAL(18, 0) NOT NULL,
    hechoEnvio_totalCostoEnvio DECIMAL(18, 2) NOT NULL
);


-- Dimensiones

CREATE TABLE NJRE.BI_rango_etario_cliente (
    rangoEtarioCliente_id INT IDENTITY(1, 1),
    rangoEtarioCliente_nombre NVARCHAR(16) NOT NULL,
	CONSTRAINT CHK_RangoEtarioClienteNombre CHECK (rangoEtarioCliente_nombre IN ('JUVENTUD', 'ADULTEZ_TEMPRANA', 'ADULTEZ_MEDIA', 'ADULTEZ_AVANZADA'))
);

CREATE TABLE NJRE.BI_rubro (
    rubro_id INT IDENTITY(1, 1),
    rubro_nombre NVARCHAR(50) NOT NULL
);

CREATE TABLE NJRE.BI_medio_pago (
    medioPago_id INT IDENTITY(1, 1),
    medioPago_nombre NVARCHAR(50) NOT NULL
);


CREATE TABLE NJRE.BI_subrubro (
    subrubro_id INT IDENTITY(1, 1),
    subrubro_descripcion NVARCHAR(50) NOT NULL
);

CREATE TABLE NJRE.BI_marca (
    marca_id INT IDENTITY(1, 1),
    marca_nombre NVARCHAR(50) NOT NULL
);

CREATE TABLE NJRE.BI_tipo_medio_pago (
    tipoMedioPago_id INT IDENTITY(1, 1),
    tipoMedioPago_nombre NVARCHAR(50) NOT NULL
);

CREATE TABLE NJRE.BI_concepto (
    concepto_id INT IDENTITY(1, 1),
    concepto_nombre NVARCHAR(50) NOT NULL
);

CREATE TABLE NJRE.BI_tipo_envio (
    tipoEnvio_id INT IDENTITY(1, 1),
    tipoEnvio_nombre NVARCHAR(50) NOT NULL
);

CREATE TABLE NJRE.BI_tiempo (
    tiempo_id INT IDENTITY(1,1), 
    tiempo_anio INT NOT NULL,
    tiempo_cuatrimestre INT NOT NULL,
    tiempo_mes INT NOT NULL,
	CONSTRAINT CHK_TiempoCuatrimestre CHECK (tiempo_cuatrimestre between 1 AND 4),
	CONSTRAINT CHK_TiempoMes CHECK (tiempo_mes between 1 AND 12)
);

CREATE TABLE NJRE.BI_localidad (
    localidad_id INT IDENTITY(1,1),
    localidad_nombre NVARCHAR(50) NOT NULL
);

CREATE TABLE NJRE.BI_provincia (
    provincia_id NCHAR(2) NOT NULL,
    provincia_nombre NVARCHAR(50) NOT NULL
);

CREATE TABLE NJRE.BI_cuota (
    cuota_id INT IDENTITY(1,1),
    cuota_cantidad DECIMAL(18,0) NOT NULL
);


-------------------------------------------------------------------------------------------------
-- CREACION DE PRIMARY KEYS
-------------------------------------------------------------------------------------------------

-- Hechos

ALTER TABLE NJRE.BI_hecho_venta
ADD CONSTRAINT PK_BI_HechoVenta PRIMARY KEY (hechoVenta_tiempo_id, hechoVenta_provinciaAlmacen_id, hechoVenta_localidadCliente_id, hechoVenta_rubro_id, hechoVenta_rangoEtarioCliente_id);

ALTER TABLE NJRE.BI_hecho_publicacion
ADD CONSTRAINT PK_BI_HechoPublicacion PRIMARY KEY (hechoPublicacion_tiempo_id, hechoPublicacion_subrubro_id, hechoPublicacion_marca_id);

ALTER TABLE NJRE.BI_hecho_pago
ADD CONSTRAINT PK_BI_HechoPago PRIMARY KEY (hechoPago_tiempo_id, hechoPago_medioPago_id, hechoPago_cuota_id, hechoPago_localidadCliente_id, hechoPago_tipoMedioPago_id);

ALTER TABLE NJRE.BI_hecho_factura
ADD CONSTRAINT PK_BI_HechoFactura PRIMARY KEY (hechoFactura_tiempo_id, hechoFactura_concepto_id, hechoFactura_provinciaVendedor_id);

ALTER TABLE NJRE.BI_hecho_envio
ADD CONSTRAINT PK_BI_HechoEnvio PRIMARY KEY (hechoEnvio_tiempo_id, hechoEnvio_provinciaAlmacen_id, hechoEnvio_localidadCliente_id, hechoEnvio_tipoEnvio_id);

-- Dimensiones

ALTER TABLE NJRE.BI_tiempo
ADD CONSTRAINT PK_BI_Tiempo PRIMARY KEY (tiempo_id);

ALTER TABLE NJRE.BI_localidad
ADD CONSTRAINT PK_BI_Localidad PRIMARY KEY (localidad_id);

ALTER TABLE NJRE.BI_provincia
ADD CONSTRAINT PK_BI_Provincia PRIMARY KEY (provincia_id);

ALTER TABLE NJRE.BI_medio_pago
ADD CONSTRAINT PK_BI_MedioPago PRIMARY KEY (medioPago_id);

ALTER TABLE NJRE.BI_rango_etario_cliente
ADD CONSTRAINT PK_BI_RangoEtarioCliente PRIMARY KEY (rangoEtarioCliente_id);

ALTER TABLE NJRE.BI_subrubro
ADD CONSTRAINT PK_BI_Subrubro PRIMARY KEY (subrubro_id);

ALTER TABLE NJRE.BI_rubro
ADD CONSTRAINT PK_BI_Rubro PRIMARY KEY (rubro_id);

ALTER TABLE NJRE.BI_marca
ADD CONSTRAINT PK_BI_Marca PRIMARY KEY (marca_id);

ALTER TABLE NJRE.BI_tipo_medio_pago
ADD CONSTRAINT PK_BI_TipoMedioPago PRIMARY KEY (tipoMedioPago_id);

ALTER TABLE NJRE.BI_concepto
ADD CONSTRAINT PK_BI_Concepto PRIMARY KEY (concepto_id);

ALTER TABLE NJRE.BI_tipo_envio
ADD CONSTRAINT PK_BI_TipoEnvio PRIMARY KEY (tipoEnvio_id);

ALTER TABLE NJRE.BI_cuota
ADD CONSTRAINT PK_BI_Cuota PRIMARY KEY (cuota_id);


-------------------------------------------------------------------------------------------------
-- CREACION DE FOREING KEYS
-------------------------------------------------------------------------------------------------

ALTER TABLE NJRE.BI_hecho_venta
ADD CONSTRAINT FK_BI_HechoVenta_Tiempo FOREIGN KEY (hechoVenta_tiempo_id) REFERENCES NJRE.BI_tiempo(tiempo_id),
    CONSTRAINT FK_BI_HechoVenta_ProvinciaAlmacen FOREIGN KEY (hechoVenta_provinciaAlmacen_id) REFERENCES NJRE.BI_provincia(provincia_id),
    CONSTRAINT FK_BI_HechoVenta_LocalidadCliente FOREIGN KEY (hechoVenta_localidadCliente_id) REFERENCES NJRE.BI_localidad(localidad_id),
    CONSTRAINT FK_BI_HechoVenta_Rubro FOREIGN KEY (hechoVenta_rubro_id) REFERENCES NJRE.BI_rubro(rubro_id),
    CONSTRAINT FK_BI_HechoVenta_RangoEtarioCliente FOREIGN KEY (hechoVenta_rangoEtarioCliente_id) REFERENCES NJRE.BI_rango_etario_cliente(rangoEtarioCliente_id);

ALTER TABLE NJRE.BI_hecho_publicacion
ADD CONSTRAINT FK_BI_HechoPublicacion_Tiempo FOREIGN KEY (hechoPublicacion_tiempo_id) REFERENCES NJRE.BI_tiempo(tiempo_id),
    CONSTRAINT FK_BI_HechoPublicacion_Subrubro FOREIGN KEY (hechoPublicacion_subrubro_id) REFERENCES NJRE.BI_subrubro(subrubro_id),
    CONSTRAINT FK_BI_HechoPublicacion_Marca FOREIGN KEY (hechoPublicacion_marca_id) REFERENCES NJRE.BI_marca(marca_id);

ALTER TABLE NJRE.BI_hecho_pago
ADD CONSTRAINT FK_BI_HechoPago_Tiempo FOREIGN KEY (hechoPago_tiempo_id) REFERENCES NJRE.BI_tiempo(tiempo_id),
	CONSTRAINT FK_BI_HechoPago_MedioPago FOREIGN KEY (hechoPago_medioPago_id) REFERENCES NJRE.BI_medio_pago(medioPago_id),
    CONSTRAINT FK_BI_HechoPago_Cuota FOREIGN KEY (hechoPago_cuota_id) REFERENCES NJRE.BI_cuota(cuota_id),
    CONSTRAINT FK_BI_HechoPago_LocalidadCliente FOREIGN KEY (hechoPago_localidadCliente_id) REFERENCES NJRE.BI_localidad(localidad_id),
	CONSTRAINT FK_BI_HechoPago_TipoMedioPago FOREIGN KEY (hechoPago_tipoMedioPago_id) REFERENCES NJRE.BI_tipo_medio_pago(tipoMedioPago_id);

ALTER TABLE NJRE.BI_hecho_factura
ADD CONSTRAINT FK_BI_HechoFactura_Tiempo FOREIGN KEY (hechoFactura_tiempo_id) REFERENCES NJRE.BI_tiempo(tiempo_id),
    CONSTRAINT FK_BI_HechoFactura_Concepto FOREIGN KEY (hechoFactura_concepto_id) REFERENCES NJRE.BI_concepto(concepto_id),
    CONSTRAINT FK_BI_HechoFactura_ProvinciaVendedor FOREIGN KEY (hechoFactura_provinciaVendedor_id) REFERENCES NJRE.BI_provincia(provincia_id);

ALTER TABLE NJRE.BI_hecho_envio
ADD CONSTRAINT FK_BI_HechoEnvio_Tiempo FOREIGN KEY (hechoEnvio_tiempo_id) REFERENCES NJRE.BI_tiempo(tiempo_id),
    CONSTRAINT FK_BI_HechoEnvio_ProvinciaAlmacen FOREIGN KEY (hechoEnvio_provinciaAlmacen_id) REFERENCES NJRE.BI_provincia(provincia_id),
    CONSTRAINT FK_BI_HechoEnvio_LocalidadCliente FOREIGN KEY (hechoEnvio_localidadCliente_id) REFERENCES NJRE.BI_localidad(localidad_id),
    CONSTRAINT FK_BI_HechoEnvio_TipoEnvio FOREIGN KEY (hechoEnvio_tipoEnvio_id) REFERENCES NJRE.BI_tipo_envio(tipoEnvio_id);


-------------------------------------------------------------------------------------------------
-- FUNCIONES AUXILIARES DE LA MIGRACION
-------------------------------------------------------------------------------------------------

IF OBJECT_ID('NJRE.BI_obtener_tiempo_cuatrimestre') IS NOT NULL 
    DROP FUNCTION NJRE.BI_obtener_tiempo_cuatrimestre;
GO
CREATE FUNCTION NJRE.BI_obtener_tiempo_cuatrimestre(@fecha DATE) 
RETURNS INT 
AS 
BEGIN
    DECLARE @cuatrimestre INT;

    SET @cuatrimestre = CASE 
        WHEN MONTH(@fecha) BETWEEN 1 AND 4 THEN 1 
        WHEN MONTH(@fecha) BETWEEN 5 AND 8 THEN 2  
        WHEN MONTH(@fecha) BETWEEN 9 AND 12 THEN 3 
        ELSE NULL
    END;

    RETURN @cuatrimestre;
END;
GO

IF OBJECT_ID('NJRE.BI_obtener_rangoEtario_id') IS NOT NULL 
    DROP FUNCTION NJRE.BI_obtener_rangoEtario_id;
GO
CREATE FUNCTION NJRE.BI_obtener_rangoEtario_id(@fecha DATE) 
RETURNS INT 
AS 
BEGIN
    DECLARE @idRangoEtario INT;
    DECLARE @edad INT;

    -- Calcular la edad basada en el año actual
    SET @edad = DATEDIFF(YEAR, @fecha, GETDATE()) - 
		CASE 
			WHEN MONTH(@fecha) > MONTH(GETDATE()) OR (MONTH(@fecha) = MONTH(GETDATE()) AND DAY(@fecha) > DAY(GETDATE())) 
			THEN 1 
			ELSE 0 
    END;

    SET @idRangoEtario = CASE 
        WHEN @edad < 25 THEN 1 
        WHEN @edad BETWEEN 25 AND 35 THEN 2  
        WHEN @edad BETWEEN 36 AND 50 THEN 3
        WHEN @edad > 50 THEN 4 
        ELSE NULL
    END;

    RETURN @idRangoEtario;
END;
GO

IF OBJECT_ID('NJRE.BI_envioCumplido') IS NOT NULL 
    DROP FUNCTION NJRE.BI_envioCumplido;
GO
CREATE FUNCTION NJRE.BI_envioCumplido(@fecha_entrega DATETIME, @fecha_programada DATE, @hora_inicio DECIMAL(18, 0), @hora_fin DECIMAL(18, 0)) 
RETURNS BIT 
AS 
BEGIN
    DECLARE @resultado BIT;

    IF (
        DATEPART(HOUR, @fecha_entrega) BETWEEN @hora_inicio AND @hora_fin
        AND CONVERT(DATE, @fecha_entrega) = @fecha_programada
    )
        SET @resultado = 1;
    ELSE 
        SET @resultado = 0;

    RETURN @resultado;
END;
GO

-------------------------------------------------------------------------------------------------
-- PROCEDURES PARA LA MIGRACION DE DATOS
-------------------------------------------------------------------------------------------------

-- Dimensiones

IF OBJECT_ID('NJRE.BI_migrar_tiempo') IS NOT NULL 
    DROP PROCEDURE NJRE.BI_migrar_tiempo
GO 
CREATE PROCEDURE NJRE.BI_migrar_tiempo AS
BEGIN
    INSERT INTO NJRE.BI_tiempo (tiempo_anio, tiempo_mes, tiempo_cuatrimestre) 
	SELECT DISTINCT YEAR(p.publicacion_fecha_inicio), MONTH(p.publicacion_fecha_inicio), NJRE.BI_obtener_tiempo_cuatrimestre(publicacion_fecha_inicio)
	FROM NJRE.publicacion p
	UNION
	SELECT DISTINCT YEAR(v.venta_fecha), MONTH(v.venta_fecha), NJRE.BI_obtener_tiempo_cuatrimestre(v.venta_fecha)
	FROM NJRE.venta v
    UNION
	SELECT DISTINCT YEAR( e.envio_fecha_programada), MONTH(e.envio_fecha_programada), NJRE.BI_obtener_tiempo_cuatrimestre(e.envio_fecha_programada)
	FROM NJRE.envio e
    UNION
	SELECT DISTINCT YEAR( p.pago_fecha), MONTH(p.pago_fecha), NJRE.BI_obtener_tiempo_cuatrimestre(p.pago_fecha)
	FROM NJRE.pago p
	UNION
	SELECT DISTINCT YEAR(f.factura_fecha), MONTH(f.factura_fecha), NJRE.BI_obtener_tiempo_cuatrimestre(f.factura_fecha)
	FROM NJRE.factura f
END
GO 

IF OBJECT_ID('NJRE.BI_migrar_localidad') IS NOT NULL 
    DROP PROCEDURE NJRE.BI_migrar_localidad
GO 
CREATE PROCEDURE NJRE.BI_migrar_localidad AS
BEGIN
    INSERT INTO NJRE.BI_localidad (localidad_nombre)
	SELECT localidad_nombre
	FROM NJRE.localidad
END
GO

IF OBJECT_ID('NJRE.BI_migrar_medio_pago') IS NOT NULL 
    DROP PROCEDURE NJRE.BI_migrar_medio_pago
GO 
CREATE PROCEDURE NJRE.BI_migrar_medio_pago AS
BEGIN
    INSERT INTO NJRE.BI_medio_pago(medioPago_nombre)
	SELECT medioPago_nombre
	FROM NJRE.medio_pago
END
GO

IF OBJECT_ID('NJRE.BI_migrar_provincia') IS NOT NULL 
    DROP PROCEDURE NJRE.BI_migrar_provincia
GO 
CREATE PROCEDURE NJRE.BI_migrar_provincia AS
BEGIN
    INSERT INTO NJRE.BI_provincia (provincia_id, provincia_nombre)
	SELECT provincia_id, provincia_nombre
	FROM NJRE.provincia
END
GO

IF OBJECT_ID('NJRE.BI_migrar_rubro') IS NOT NULL 
    DROP PROCEDURE NJRE.BI_migrar_rubro
GO 
CREATE PROCEDURE NJRE.BI_migrar_rubro AS
BEGIN
    INSERT INTO NJRE.BI_rubro (rubro_nombre)
	SELECT rubro_descripcion
	FROM NJRE.rubro
END
GO

IF OBJECT_ID('NJRE.BI_migrar_subrubro') IS NOT NULL 
    DROP PROCEDURE NJRE.BI_migrar_subrubro
GO 
CREATE PROCEDURE NJRE.BI_migrar_subrubro AS
BEGIN
    INSERT INTO NJRE.BI_subrubro (subrubro_descripcion)
    SELECT subrubro_descripcion
    FROM NJRE.subrubro
END
GO

IF OBJECT_ID('NJRE.BI_migrar_marca') IS NOT NULL 
    DROP PROCEDURE NJRE.BI_migrar_marca
GO 
CREATE PROCEDURE NJRE.BI_migrar_marca AS
BEGIN
    INSERT INTO NJRE.BI_marca (marca_nombre)
    SELECT marca_descripcion
    FROM NJRE.marca
END
GO

IF OBJECT_ID('NJRE.BI_migrar_rangoEtarioCliente') IS NOT NULL 
    DROP PROCEDURE NJRE.BI_migrar_rangoEtarioCliente
GO 
CREATE PROCEDURE NJRE.BI_migrar_rangoEtarioCliente AS
BEGIN
    INSERT INTO NJRE.BI_rango_etario_cliente (rangoEtarioCliente_nombre)
    VALUES ('JUVENTUD'), ('ADULTEZ_TEMPRANA'), ('ADULTEZ_MEDIA'), ('ADULTEZ_AVANZADA');
END
GO

IF OBJECT_ID('NJRE.BI_migrar_tipoEnvio') IS NOT NULL 
    DROP PROCEDURE NJRE.BI_migrar_tipoEnvio
GO 
CREATE PROCEDURE NJRE.BI_migrar_tipoEnvio AS
BEGIN
    INSERT INTO NJRE.BI_tipo_envio (tipoEnvio_nombre)
    SELECT DISTINCT tipoEnvio_medio
    FROM NJRE.tipo_envio
END
GO

IF OBJECT_ID('NJRE.BI_migrar_tipoMedioPago') IS NOT NULL 
    DROP PROCEDURE NJRE.BI_migrar_tipoMedioPago
GO 
CREATE PROCEDURE NJRE.BI_migrar_tipoMedioPago AS
BEGIN
    INSERT INTO NJRE.BI_tipo_medio_pago (tipoMedioPago_nombre)
    SELECT DISTINCT tipoMedioPago_nombre
    FROM NJRE.tipo_medio_pago 
END
GO

IF OBJECT_ID('NJRE.BI_migrar_concepto') IS NOT NULL 
    DROP PROCEDURE NJRE.BI_migrar_concepto
GO 
CREATE PROCEDURE NJRE.BI_migrar_concepto AS
BEGIN
    INSERT INTO NJRE.BI_concepto (concepto_nombre)
    SELECT DISTINCT concepto_nombre
    FROM NJRE.concepto 
END 
GO

IF OBJECT_ID('NJRE.BI_migrar_cuota') IS NOT NULL 
    DROP PROCEDURE NJRE.BI_migrar_cuota
GO 
CREATE PROCEDURE NJRE.BI_migrar_cuota AS
BEGIN
    INSERT INTO NJRE.BI_cuota (cuota_cantidad)
    SELECT DISTINCT detallePago_cant_cuotas
    FROM NJRE.detalle_pago 
END
GO 


-- Hechos

IF OBJECT_ID('NJRE.BI_migrar_hechoVenta') IS NOT NULL 
    DROP PROCEDURE NJRE.BI_migrar_hechoVenta
GO 
CREATE PROCEDURE NJRE.BI_migrar_hechoVenta AS
BEGIN
	INSERT INTO NJRE.BI_hecho_venta
	(hechoVenta_tiempo_id, hechoVenta_provinciaAlmacen_id, hechoVenta_localidadCliente_id, hechoVenta_rubro_id, hechoVenta_rangoEtarioCliente_id, hechoVenta_cantidadVentas, hechoVenta_totalVentas)
	SELECT 
		tiempo_id,
		domAlmacen.domicilio_provincia,
		domCliente.domicilio_localidad,
		s.subrubro_rubro_id,
		NJRE.BI_obtener_rangoEtario_id(c.cliente_fecha_nacimiento),
		COUNT(DISTINCT venta_id),
		SUM(dv.detalleVenta_subtotal)
	FROM NJRE.venta v
        INNER JOIN NJRE.detalle_venta dv ON v.venta_id = dv.detalleVenta_venta_id
        INNER JOIN NJRE.publicacion p ON p.publicacion_id = dv.detalleVenta_publicacion_id
        INNER JOIN NJRE.almacen a ON a.almacen_id = p.publicacion_almacen_id
        INNER JOIN NJRE.envio e ON e.envio_venta_id = v.venta_id
		INNER JOIN NJRE.producto pr ON pr.producto_id = p.publicacion_producto_id
		INNER JOIN NJRE.subrubro s ON s.subrubro_id = pr.producto_subrubro_id
		INNER JOIN NJRE.cliente c ON c.cliente_id = v.venta_cliente_id
		INNER JOIN NJRE.BI_tiempo ON tiempo_anio = DATEPART(year, venta_fecha) AND tiempo_mes = DATEPART(month, venta_fecha)
        INNER JOIN NJRE.domicilio domAlmacen ON domAlmacen.domicilio_id = a.almacen_domicilio_id
		INNER JOIN NJRE.domicilio domCliente ON domCliente.domicilio_id = e.envio_domicilio_id
	GROUP BY 
        tiempo_id, 
        domAlmacen.domicilio_provincia, 
        domCliente.domicilio_localidad, 
        s.subrubro_rubro_id, 
        NJRE.BI_obtener_rangoEtario_id(c.cliente_fecha_nacimiento);  
END
GO

IF OBJECT_ID('NJRE.BI_migrar_hechoEnvio') IS NOT NULL 
    DROP PROCEDURE NJRE.BI_migrar_hechoEnvio
GO 
CREATE PROCEDURE NJRE.BI_migrar_hechoEnvio AS
BEGIN
    INSERT INTO NJRE.BI_hecho_envio 
    (hechoEnvio_tiempo_id, hechoEnvio_provinciaAlmacen_id, hechoEnvio_localidadCliente_id, hechoEnvio_tipoEnvio_id, hechoEnvio_cantidadEnvios, hechoEnvio_totalEnviosCumplidos, hechoEnvio_totalCostoEnvio)
    SELECT 
        tiempo_id,
        domAlmacen.domicilio_provincia, 
		domCliente.domicilio_localidad,
        e.envio_tipoEnvio_id,
        COUNT(DISTINCT e.envio_id),
        SUM(CASE WHEN NJRE.BI_envioCumplido(e.envio_fecha_entrega, e.envio_fecha_programada, e.envio_hora_inicio, e.envio_hora_fin) = 1 THEN 1 ELSE 0 END),
        SUM(e.envio_costo)
    FROM NJRE.envio e
        INNER JOIN NJRE.BI_tiempo ON tiempo_anio = DATEPART(year, envio_fecha_programada) AND tiempo_mes = DATEPART(month, envio_fecha_programada)
		INNER JOIN NJRE.detalle_venta dv ON dv.detalleVenta_venta_id = e.envio_venta_id
		INNER JOIN NJRE.publicacion p ON p.publicacion_id = dv.detalleVenta_publicacion_id
		INNER JOIN NJRE.almacen a ON a.almacen_id = p.publicacion_almacen_id
		INNER JOIN NJRE.domicilio domAlmacen ON domAlmacen.domicilio_id = a.almacen_domicilio_id
		INNER JOIN NJRE.domicilio domCliente ON domCliente.domicilio_id = e.envio_domicilio_id
    GROUP BY 
        tiempo_id,
        domAlmacen.domicilio_provincia, 
		domCliente.domicilio_localidad,
        e.envio_tipoEnvio_id
END
GO

IF OBJECT_ID('NJRE.BI_migrar_hechoFactura') IS NOT NULL 
    DROP PROCEDURE NJRE.BI_migrar_hechoFactura
GO 
CREATE PROCEDURE NJRE.BI_migrar_hechoFactura AS
BEGIN
    INSERT INTO NJRE.BI_hecho_factura
    (hechoFactura_tiempo_id, hechoFactura_concepto_id, hechoFactura_provinciaVendedor_id, hechoFactura_montoFacturado)
    SELECT 
        tiempo_id,
        facturaDetalle_concepto_id,
        domicilio_provincia,
        SUM(facturaDetalle_subtotal)
    FROM NJRE.factura
        INNER JOIN NJRE.BI_tiempo ON tiempo_anio = DATEPART(year, factura_fecha) and tiempo_mes = DATEPART(month, factura_fecha)
        INNER JOIN NJRE.vendedor ON vendedor_id = factura_usuario
        INNER JOIN NJRE.usuario_domicilio ON usuarioDomicilio_usuario_id = vendedor_usuario_id  
		INNER JOIN NJRE.domicilio ON domicilio_id = usuarioDomicilio_domicilio_id
        INNER JOIN NJRE.factura_detalle ON facturaDetalle_factura_id = factura_id
    GROUP BY
        tiempo_id,
        facturaDetalle_concepto_id,
        domicilio_provincia;
END
GO

IF OBJECT_ID('NJRE.BI_migrar_hechoPublicacion') IS NOT NULL 
    DROP PROCEDURE NJRE.BI_migrar_hechoPublicacion
GO 
CREATE PROCEDURE NJRE.BI_migrar_hechoPublicacion AS
BEGIN
    INSERT INTO NJRE.BI_hecho_publicacion
    (hechoPublicacion_tiempo_id, hechoPublicacion_subrubro_id, hechoPublicacion_marca_id, hechoPublicacion_totalDiasPublicaciones, hechoPublicacion_cantidadStockTotal, hechoPublicacion_cantidadPublicaciones)
    SELECT 
        tiempo_id,
        producto_subrubro_id,
        producto_marca_id,
        SUM(DATEDIFF(day, p.publicacion_fecha_inicio, p.publicacion_fecha_fin)),
        SUM(p.publicacion_stock),
        COUNT(DISTINCT p.publicacion_id)
    FROM NJRE.publicacion p
        INNER JOIN NJRE.BI_tiempo ON tiempo_anio = DATEPART(year, publicacion_fecha_inicio) AND tiempo_mes = DATEPART(month, publicacion_fecha_inicio)
        INNER JOIN NJRE.producto ON producto_id = publicacion_producto_id
    GROUP BY 
        tiempo_id,
        producto_subrubro_id,
        producto_marca_id;
END
GO

IF OBJECT_ID('NJRE.BI_migrar_hechoPago') IS NOT NULL 
    DROP PROCEDURE NJRE.BI_migrar_hechoPago
GO 
CREATE PROCEDURE NJRE.BI_migrar_hechoPago AS
BEGIN
    INSERT INTO NJRE.BI_hecho_pago
    (hechoPago_tiempo_id, hechoPago_medioPago_id, hechoPago_cuota_id, hechoPago_localidadCliente_id, hechoPago_tipoMedioPago_id, hechoPago_importeTotalCuotas)
    SELECT 
        tiempo_id,
		pago_medioPago_id,
        cuota_id,	
        domicilio_localidad,
        medioPago_tipoMedioPago_id,
        SUM(detallePago_importe_parcial)
    FROM NJRE.pago
        INNER JOIN NJRE.BI_tiempo ON tiempo_anio = DATEPART(year, pago_fecha) AND tiempo_mes = DATEPART(month, pago_fecha)
        INNER JOIN NJRE.medio_pago ON medioPago_id = pago_medioPago_id
        INNER JOIN NJRE.envio ON envio_venta_id = pago_venta_id
        INNER JOIN NJRE.domicilio ON domicilio_id = envio_domicilio_id
        INNER JOIN NJRE.detalle_pago ON detallePago_pago_id = pago_id
        INNER JOIN NJRE.BI_cuota ON cuota_cantidad = detallePago_cant_cuotas
    GROUP BY 
        tiempo_id,
        domicilio_localidad,
		pago_medioPago_id,
        medioPago_tipoMedioPago_id,
        cuota_id;
END
GO

-------------------------------------------------------------------------------------------------
-- EJECUCION DE LA MIGRACION DE DATOS
-------------------------------------------------------------------------------------------------

-- Dimensiones
EXEC NJRE.BI_migrar_rubro;
EXEC NJRE.BI_migrar_tiempo;
EXEC NJRE.BI_migrar_localidad;
EXEC NJRE.BI_migrar_provincia;
EXEC NJRE.BI_migrar_rangoEtarioCliente;
EXEC NJRE.BI_migrar_subrubro;
EXEC NJRE.BI_migrar_marca;
EXEC NJRE.BI_migrar_tipoEnvio;
EXEC NJRE.BI_migrar_medio_pago;
EXEC NJRE.BI_migrar_tipoMedioPago;
EXEC NJRE.BI_migrar_concepto;
EXEC NJRE.BI_migrar_cuota;

-- Hechos
EXEC NJRE.BI_migrar_hechoVenta;
EXEC NJRE.BI_migrar_hechoEnvio;
EXEC NJRE.BI_migrar_hechoFactura;
EXEC NJRE.BI_migrar_hechoPublicacion;
EXEC NJRE.BI_migrar_hechoPago;

GO


-------------------------------------------------------------------------------------------------
-- VISTAS
-------------------------------------------------------------------------------------------------

-- Vista 1
IF OBJECT_ID('NJRE.BI_promedioTiempoPublicacion') IS NOT NULL 
    DROP VIEW NJRE.BI_promedioTiempoPublicacion
GO 
CREATE VIEW NJRE.BI_promedioTiempoPublicacion AS
SELECT tiempo_anio, tiempo_cuatrimestre, subrubro_descripcion, SUM(hechoPublicacion_totalDiasPublicaciones) / SUM(hechoPublicacion_cantidadPublicaciones) AS 'promedio de dias vigente de una publicacion'
FROM NJRE.BI_hecho_publicacion
	INNER JOIN NJRE.BI_tiempo ON tiempo_id = hechoPublicacion_tiempo_id
	INNER JOIN NJRE.BI_subrubro ON subrubro_id = hechoPublicacion_subrubro_id
GROUP BY tiempo_anio, tiempo_cuatrimestre, hechoPublicacion_subrubro_id, subrubro_descripcion;
GO

-- Vista 2
IF OBJECT_ID('NJRE.BI_promedioStockInicial') IS NOT NULL 
    DROP VIEW NJRE.BI_promedioStockInicial
GO 
CREATE VIEW NJRE.BI_promedioStockInicial AS
SELECT tiempo_anio, hechoPublicacion_marca_id, marca_nombre, SUM(hechoPublicacion_cantidadStockTotal) / SUM(hechoPublicacion_cantidadPublicaciones) AS 'promedio stock inicial'
FROM NJRE.BI_hecho_publicacion
	INNER JOIN NJRE.BI_tiempo ON tiempo_id = hechoPublicacion_tiempo_id
	INNER JOIN NJRE.BI_marca ON marca_id = hechoPublicacion_marca_id
GROUP BY tiempo_anio, hechoPublicacion_marca_id, marca_nombre
GO

-- Vista 3
IF OBJECT_ID('NJRE.BI_ventaPromedioMensual') IS NOT NULL 
    DROP VIEW NJRE.BI_ventaPromedioMensual
GO 
CREATE VIEW NJRE.BI_ventaPromedioMensual AS
SELECT tiempo_anio, tiempo_mes, provincia_nombre, SUM(hechoVenta_totalVentas) / SUM(hechoVenta_cantidadVentas) 'promedio ventas en $'
FROM NJRE.BI_hecho_venta
	INNER JOIN NJRE.BI_tiempo ON tiempo_id = hechoVenta_tiempo_id
	INNER JOIN NJRE.provincia ON provincia_id = hechoVenta_provinciaAlmacen_id
GROUP BY hechoVenta_tiempo_id, tiempo_anio, tiempo_mes, provincia_id, provincia_nombre
GO

-- Vista 4
IF OBJECT_ID('NJRE.BI_rendimientoDeRubros') IS NOT NULL 
    DROP VIEW NJRE.BI_rendimientoDeRubros
GO 
CREATE VIEW NJRE.BI_rendimientoDeRubros AS
SELECT tiempo_anio, tiempo_cuatrimestre, localidad_nombre, rangoEtarioCliente_nombre, rubro_id, rubro_nombre, SUM(hechoVenta_totalVentas) 'ventas en $'
FROM NJRE.BI_hecho_venta v
	INNER JOIN NJRE.BI_tiempo t ON tiempo_id = hechoVenta_tiempo_id
	INNER JOIN NJRE.BI_rubro ON rubro_id = hechoVenta_rubro_id
	INNER JOIN NJRE.BI_localidad ON localidad_id = hechoVenta_localidadCliente_id
	INNER JOIN NJRE.BI_rango_etario_cliente ON rangoEtarioCliente_id= hechoVenta_rangoEtarioCliente_id
GROUP BY tiempo_anio, tiempo_cuatrimestre, localidad_id, localidad_nombre, rangoEtarioCliente_id, rangoEtarioCliente_nombre, rubro_id, rubro_nombre
HAVING rubro_id IN (
	SELECT TOP 5 hechoVenta_rubro_id 
	FROM NJRE.BI_hecho_venta 
		INNER JOIN NJRE.BI_tiempo ON tiempo_id = hechoVenta_tiempo_id
	WHERE tiempo_anio = t.tiempo_anio AND tiempo_cuatrimestre = t.tiempo_cuatrimestre
		AND hechoVenta_localidadCliente_id = localidad_id
		AND hechoVenta_rangoEtarioCliente_id = rangoEtarioCliente_id
	GROUP BY hechoVenta_rubro_id
	ORDER BY SUM(hechoVenta_totalVentas) DESC
)
GO


-- Vista 6
IF OBJECT_ID('NJRE.BI_localidadesConMayorImporteEnCuotas') IS NOT NULL 
    DROP VIEW NJRE.BI_localidadesConMayorImporteEnCuotas
GO 
CREATE VIEW NJRE.BI_localidadesConMayorImporteEnCuotas AS
WITH RankingLocalidades AS (
    SELECT hechoPago_localidadCliente_id, hechoPago_tiempo_id, hechoPago_medioPago_id, 
		SUM(hechoPago_importeTotalCuotas) total_importe,
        ROW_NUMBER() OVER (PARTITION BY hechoPago_tiempo_id, hechoPago_medioPago_id ORDER BY SUM(hechoPago_importeTotalCuotas) DESC) ranking
    FROM NJRE.BI_hecho_Pago
    INNER JOIN NJRE.BI_cuota ON cuota_id = hechoPago_cuota_id
    WHERE cuota_cantidad > 1
    GROUP BY hechoPago_localidadCliente_id, hechoPago_tiempo_id, hechoPago_medioPago_id
)
SELECT tiempo_anio, tiempo_mes, medioPago_nombre, localidad_nombre, SUM(hechoPago_importeTotalCuotas) AS 'importe total cuotas'
FROM NJRE.BI_hecho_pago he
	INNER JOIN NJRE.BI_tiempo ON tiempo_id = he.hechoPago_tiempo_id
	INNER JOIN NJRE.BI_localidad ON localidad_id = he.hechoPago_localidadCliente_id
	INNER JOIN NJRE.BI_medio_pago ON medioPago_id = he.hechoPago_medioPago_id
	INNER JOIN RankingLocalidades rl ON he.hechoPago_localidadCliente_id = rl.hechoPago_localidadCliente_id 
								   AND he.hechoPago_tiempo_id = rl.hechoPago_tiempo_id 
								   AND he.hechoPago_medioPago_id = rl.hechoPago_medioPago_id
WHERE rl.ranking <= 3
GROUP BY he.hechoPago_tiempo_id, tiempo_anio, tiempo_mes, localidad_id, localidad_nombre, he.hechoPago_medioPago_id, medioPago_nombre;
GO

/* Otra version de la vista 6, pero menos perfomante

    IF OBJECT_ID('NJRE.BI_localidadesConMayorImporteEnCuotas') IS NOT NULL 
        DROP VIEW NJRE.BI_localidadesConMayorImporteEnCuotas
    GO 
    CREATE VIEW NJRE.BI_localidadesConMayorImporteEnCuotas AS
    SELECT tiempo_anio, tiempo_mes, medioPago_nombre, localidad_nombre, SUM(hechoPago_importeTotalCuotas) AS 'importe total cuotas'
    FROM NJRE.BI_hecho_pago he
        INNER JOIN NJRE.BI_tiempo ON tiempo_id = he.hechoPago_tiempo_id
        INNER JOIN NJRE.BI_medio_pago ON medioPago_id = he.hechoPago_medioPago_id
        INNER JOIN NJRE.BI_localidad ON localidad_id = he.hechoPago_localidadCliente_id
        INNER JOIN NJRE.BI_cuota ON cuota_id = hechoPago_cuota_id
    WHERE cuota_cantidad > 1
    GROUP BY hechoPago_tiempo_id, tiempo_anio, tiempo_mes, localidad_id, localidad_nombre, hechoPago_medioPago_id, medioPago_nombre
    HAVING localidad_id IN (
        SELECT TOP 3 hechoPago_localidadCliente_id 
        FROM NJRE.BI_hecho_Pago INNER JOIN NJRE.BI_cuota ON cuota_id = hechoPago_cuota_id
        WHERE hechoPago_tiempo_id = he.hechoPago_tiempo_id
            AND hechoPago_medioPago_id = he.hechoPago_medioPago_id
            AND cuota_cantidad > 1
        GROUP BY hechoPago_localidadCliente_id
        ORDER BY SUM(hechoPago_importeTotalCuotas) DESC
    )
    GO
*/

-- Vista 7 
IF OBJECT_ID('NJRE.BI_porcentajeCumplimientoEnvios') IS NOT NULL 
    DROP VIEW NJRE.BI_porcentajeCumplimientoEnvios
GO 
CREATE VIEW NJRE.BI_porcentajeCumplimientoEnvios AS
SELECT provincia_nombre, tiempo_anio, tiempo_mes, SUM(hechoEnvio_totalEnviosCumplidos) * 100 / SUM(hechoEnvio_cantidadEnvios) AS 'porcentaje de cumplimiento de envios' 
FROM NJRE.BI_hecho_envio he
	INNER JOIN NJRE.BI_provincia p ON p.provincia_id = he.hechoEnvio_provinciaAlmacen_id
	INNER JOIN NJRE.BI_tiempo t ON t.tiempo_id = he.hechoEnvio_tiempo_id
GROUP BY provincia_id, provincia_nombre, tiempo_anio, tiempo_mes;
GO

-- Vista 8
IF OBJECT_ID('NJRE.BI_localidadesConMayorCostoEnvio') IS NOT NULL 
    DROP VIEW NJRE.BI_localidadesConMayorCostoEnvio
GO 
CREATE VIEW NJRE.BI_localidadesConMayorCostoEnvio AS
SELECT localidad_nombre, SUM(hechoEnvio_totalCostoEnvio) AS 'costo de envio'
FROM NJRE.BI_hecho_envio he 
	INNER JOIN NJRE.BI_localidad l ON l.localidad_id= he.hechoEnvio_localidadCliente_id
WHERE localidad_id in (SELECT TOP 5 hechoEnvio_localidadCliente_id FROM NJRE.BI_hecho_envio GROUP BY hechoEnvio_localidadCliente_id ORDER BY SUM(hechoEnvio_totalCostoEnvio) DESC)
GROUP BY localidad_id, localidad_nombre
GO

-- Vista 9
IF OBJECT_ID('NJRE.BI_porcentajeFacturacionPorConcepto') IS NOT NULL 
    DROP VIEW NJRE.BI_porcentajeFacturacionPorConcepto
GO 
CREATE VIEW NJRE.BI_porcentajeFacturacionPorConcepto AS
SELECT tiempo_anio, tiempo_mes, concepto_nombre, SUM(hechoFactura_montoFacturado) * 100 / (SELECT SUM(hechoFactura_montoFacturado) FROM NJRE.BI_hecho_factura where hechoFactura_tiempo_id = tiempo_id) AS 'porcentaje facturación'
FROM NJRE.BI_hecho_factura 
	INNER JOIN NJRE.BI_concepto ON concepto_id = hechoFactura_concepto_id
	INNER JOIN NJRE.BI_tiempo ON tiempo_id = hechoFactura_tiempo_id
GROUP BY tiempo_id, tiempo_anio, tiempo_mes, hechoFactura_concepto_id, concepto_nombre;	
GO

-- Vista 10
IF OBJECT_ID('NJRE.BI_facturacionPorProvincia') IS NOT NULL 
    DROP VIEW NJRE.BI_facturacionPorProvincia
GO 
CREATE VIEW NJRE.BI_facturacionPorProvincia AS
SELECT tiempo_anio, tiempo_cuatrimestre, provincia_nombre, SUM(hechoFactura_montoFacturado) AS 'monto facturado'
FROM NJRE.BI_hecho_factura 
	INNER JOIN NJRE.BI_provincia ON provincia_id = hechoFactura_provinciaVendedor_id
	INNER JOIN NJRE.BI_tiempo ON tiempo_id = hechoFactura_tiempo_id
GROUP BY tiempo_anio, tiempo_cuatrimestre, hechoFactura_provinciaVendedor_id, provincia_nombre;
