-------------------------------------------------------------------------------------------------
-- CREACION DE ESQUEMA
-------------------------------------------------------------------------------------------------

USE GD2C2024;
GO
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'NJRE')
BEGIN 
    EXEC ('CREATE SCHEMA NJRE')
END
GO


-------------------------------------------------------------------------------------------------
-- PROCEDURES AUXILIARES
-------------------------------------------------------------------------------------------------

IF OBJECT_ID('NJRE.borrar_fks') IS NOT NULL 
    DROP PROCEDURE NJRE.borrar_fks 
GO 
CREATE PROCEDURE NJRE.borrar_fks AS
BEGIN
    DECLARE @query nvarchar(255) 
    DECLARE query_cursor CURSOR FOR 
    SELECT 'ALTER TABLE ' 
        + object_schema_name(k.parent_object_id) 
        + '.[' + Object_name(k.parent_object_id) 
        + '] DROP CONSTRAINT ' + k.NAME query 
    FROM sys.foreign_keys k

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

IF OBJECT_ID('NJRE.borrar_tablas') IS NOT NULL 
  DROP PROCEDURE NJRE.borrar_tablas
GO 
CREATE PROCEDURE NJRE.borrar_tablas AS
BEGIN
    DECLARE @query nvarchar(255) 
    DECLARE query_cursor CURSOR FOR  
        SELECT 'DROP TABLE NJRE.' + name
        FROM  sys.tables 
        WHERE schema_id = (SELECT schema_id FROM sys.schemas WHERE name = 'NJRE')
    
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

IF OBJECT_ID('NJRE.borrar_procedimientos') IS NOT NULL 
    DROP PROCEDURE NJRE.borrar_procedimientos
GO 
CREATE PROCEDURE NJRE.borrar_procedimientos AS
BEGIN
    DECLARE @query nvarchar(255) 
    DECLARE query_cursor CURSOR FOR  
        SELECT 'DROP PROCEDURE NJRE.' + name
        FROM  sys.procedures 
        WHERE schema_id = (SELECT schema_id FROM sys.schemas WHERE name = 'NJRE') AND name LIKE 'migrar_%'
    
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

IF OBJECT_ID('NJRE.borrar_triggers') IS NOT NULL 
    DROP PROCEDURE NJRE.borrar_triggers
GO 
CREATE PROCEDURE NJRE.borrar_triggers AS
BEGIN
    DECLARE @query nvarchar(255) 
    DECLARE query_cursor CURSOR FOR  
        SELECT 'DROP TRIGGER NJRE.' + t.name
        FROM sys.triggers t
			INNER JOIN sys.objects o ON t.parent_id = o.object_id
			INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
        WHERE s.name = 'NJRE'
    
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

EXEC NJRE.borrar_fks;
EXEC NJRE.borrar_tablas;
EXEC NJRE.borrar_procedimientos;
EXEC NJRE.borrar_triggers;

GO


-------------------------------------------------------------------------------------------------
-- CREACION DE TABLAS
-------------------------------------------------------------------------------------------------

CREATE TABLE NJRE.publicacion (
    publicacion_id DECIMAL(18, 0) NOT NULL,  -- Posee un codigo en la tabla maestra
    publicacion_producto_id INT NOT NULL,
    publicacion_vendedor_id INT NOT NULL,
    publicacion_almacen_id DECIMAL(18, 0) NOT NULL,
    publicacion_descripcion NVARCHAR(50),
    publicacion_fecha_inicio DATE NOT NULL,
    publicacion_fecha_fin DATE NOT NULL,
    publicacion_stock DECIMAL(18, 0) NOT NULL,
    publicacion_precio DECIMAL(18, 2) NOT NULL,
    publicacion_costo DECIMAL(18, 2) NOT NULL,
    publicacion_porc_venta DECIMAL(18, 2) NOT NULL,
    publicacion_fecha_modificacion DATE
);

CREATE TABLE NJRE.producto (
    producto_id  INT IDENTITY(1, 1),
    producto_marca_id INT NOT NULL,  
    producto_mod_id DECIMAL(18, 0) NOT NULL, 
    producto_subrubro_id INT NOT NULL,  
    producto_codigo NVARCHAR(50), 
    producto_descripcion NVARCHAR(50) NOT NULL,  
    producto_precio DECIMAL(18, 2) NOT NULL,  
    producto_fecha_alta DATE NOT NULL, 
    producto_fecha_modificacion DATE 
);

CREATE TABLE NJRE.marca (
    marca_id INT IDENTITY(1, 1),
    marca_descripcion NVARCHAR(50) NOT NULL
);

CREATE TABLE NJRE.modelo (
    modelo_id DECIMAL(18, 0) NOT NULL, -- Posee un codigo en la tabla maestra
    modelo_descripcion NVARCHAR(50) NOT NULL,
);

CREATE TABLE NJRE.subrubro (
    subrubro_id INT IDENTITY(1,1),
    subrubro_rubro_id INT NOT NULL,
    subrubro_descripcion NVARCHAR(50) NOT NULL
);

CREATE TABLE NJRE.rubro (
    rubro_id INT IDENTITY(1,1),
    rubro_descripcion NVARCHAR(50) NOT NULL
);

CREATE TABLE NJRE.vendedor (
    vendedor_id INT IDENTITY(1,1),
    vendedor_usuario_id INT NOT NULL,
    vendedor_razon_social NVARCHAR(50) NOT NULL,
    vendedor_cuit NVARCHAR(50) NOT NULL
);

CREATE TABLE NJRE.almacen (
    almacen_id DECIMAL(18, 0) NOT NULL, -- Posee un código en la tabla maestra
    almacen_domicilio_id INT NOT NULL,
    almacen_nombre NVARCHAR(100) NULL,
    almacen_costo_dia DECIMAL(18, 2) NOT NULL
);

CREATE TABLE NJRE.historial_costo_almacen (
    historialCostoAlmacen_id INT IDENTITY(1,1), 
    historialCostoAlmacen_almacen_id DECIMAL(18, 0) NOT NULL,
    historialCostoAlmacen_fecha DATE NULL,
    historialCostoAlmacen_costo_dia DECIMAL(18, 2) NOT NULL
);

CREATE TABLE NJRE.venta (
    venta_id DECIMAL(18, 0) NOT NULL,  -- Posee un código en la tabla maestra
    venta_cliente_id INT NOT NULL, 
    venta_fecha DATETIME NOT NULL,
    venta_total DECIMAL(18, 2) NOT NULL
);

CREATE TABLE NJRE.detalle_venta (
    detalleVenta_id INT IDENTITY(1,1), 
    detalleVenta_venta_id DECIMAL(18, 0) NOT NULL, 
    detalleVenta_publicacion_id DECIMAL(18, 0) NOT NULL, 
    detalleVenta_precio DECIMAL(18, 2) NOT NULL,
    detalleVenta_cantidad DECIMAL(18, 0) NOT NULL,
    detalleVenta_subtotal DECIMAL(18, 2) NOT NULL
);

CREATE TABLE NJRE.cliente (
    cliente_id INT IDENTITY(1,1), 
    cliente_usuario_id INT NOT NULL, 
    cliente_nombre NVARCHAR(50) NOT NULL,
    cliente_apellido NVARCHAR(50) NOT NULL,
    cliente_fecha_nacimiento DATE NOT NULL,
    cliente_dni DECIMAL(18, 0) NOT NULL
);

CREATE TABLE NJRE.usuario (
    usuario_id INT IDENTITY(1,1),
    usuario_nombre NVARCHAR(50) NOT NULL,
    usuario_pass NVARCHAR(50) NOT NULL,
    usuario_fecha_creacion DATE NOT NULL,
    usuario_mail NVARCHAR(50) NOT NULL
);

CREATE TABLE NJRE.usuario_domicilio (
    usuarioDomicilio_usuario_id INT NOT NULL,
    usuarioDomicilio_domicilio_id INT NOT NULL,
);

CREATE TABLE NJRE.pago (
    pago_id INT IDENTITY(1, 1),
    pago_medioPago_id INT NOT NULL,
    pago_venta_id DECIMAL(18, 0) NOT NULL,
    pago_fecha DATE NOT NULL,
    pago_importe DECIMAL(18,2) NOT NULL
);

CREATE TABLE NJRE.detalle_pago (
    detallePago_id INT IDENTITY(1, 1),
    detallePago_pago_id INT NOT NULL,
    detallePago_tarjeta_nro  NVARCHAR(50),
    detallePago_tarjeta_fecha_vencimiento DATE,
    detallePago_cant_cuotas DECIMAL(18, 0),
    detallePago_cvu NCHAR(22),
    detallePago_importe_parcial DECIMAL(18, 2) NOT NULL
);

CREATE TABLE NJRE.medio_pago (
    medioPago_id INT IDENTITY(1, 1),
    medioPago_tipoMedioPago_id INT NOT NULL,
    medioPago_nombre NVARCHAR(50) NOT NULL
);

CREATE TABLE NJRE.tipo_medio_pago (
    tipoMedioPago_id INT IDENTITY(1, 1),
    tipoMedioPago_nombre NVARCHAR(50) NOT NULL
);

CREATE TABLE NJRE.domicilio (
    domicilio_id INT IDENTITY(1, 1),
    domicilio_localidad INT NOT NULL,
    domicilio_provincia NCHAR(2) NOT NULL,
    domicilio_calle NVARCHAR(50) NOT NULL,
    domicilio_nro_calle DECIMAL(18, 0) NOT NULL,
    domicilio_piso DECIMAL(18, 0),
    domicilio_depto NVARCHAR(50),
    domicilio_cp NVARCHAR(50)
);

CREATE TABLE NJRE.localidad (
    localidad_id INT IDENTITY(1, 1),
    localidad_nombre NVARCHAR(50) NOT NULL
);

CREATE TABLE NJRE.provincia (
    provincia_id NCHAR(2) NOT NULL,
    provincia_nombre NVARCHAR(50) NOT NULL
);

CREATE TABLE NJRE.envio (
    envio_id INT IDENTITY(1, 1) NOT NULL ,
    envio_venta_id DECIMAL(18,0) NOT NULL,
    envio_domicilio_id INT NOT NULL,
    envio_tipoEnvio_id INT NOT NULL,
    envio_fecha_programada DATE NOT NULL,
    envio_hora_inicio DECIMAL(18,0),
    envio_hora_fin DECIMAL(18,0),
    envio_costo DECIMAL(18,2) NOT NULL,
    envio_fecha_entrega DATETIME,
    envio_estado NVARCHAR(20) NOT NULL, 
    CONSTRAINT CHK_EnvioEstado CHECK (envio_estado IN ('En preparación', 'En camino', 'Entregado'))
);

CREATE TABLE NJRE.tipo_envio (
    tipoEnvio_id INT IDENTITY(1, 1) NOT NULL,
    tipoEnvio_medio NVARCHAR(50) NOT NULL,
);

CREATE TABLE NJRE.historial_estado_envio (
    historialEstadoEnvio_id INT IDENTITY(1, 1) NOT NULL,
    historialEstadoEnvio_envio_id INT NOT NULL,
    historialEstadoEnvio_fecha DATE NOT NULL,
    historialEstadoEnvio_estado NVARCHAR(20) NOT NULL,
    CONSTRAINT CHK_HistorialEstadoEnvioEstado CHECK (historialEstadoEnvio_estado IN ('En preparación', 'En camino', 'Entregado'))
);

CREATE TABLE NJRE.factura (
    factura_id DECIMAL(18,0) NOT NULL, -- Posee un número en la tabla maestra
    factura_usuario INT NOT NULL,
    factura_fecha DATE NOT NULL,
    factura_total DECIMAL(18,2) NOT NULL,
);

CREATE TABLE NJRE.factura_detalle (
    facturaDetalle_id INT IDENTITY(1, 1) NOT NULL,
    facturaDetalle_factura_id DECIMAL(18,0) NOT NULL,
    facturaDetalle_publicacion DECIMAL(18,0) NOT NULL,
    facturaDetalle_concepto_id INT NOT NULL,
    facturaDetalle_precio_unitario DECIMAL(18,2) NOT NULL,
    facturaDetalle_cantidad DECIMAL(18,0) NOT NULL,
    facturaDetalle_subtotal DECIMAL(18,2) NOT NULL,
);

CREATE TABLE NJRE.concepto (
    concepto_id INT IDENTITY(1, 1) NOT NULL,
    concepto_nombre NVARCHAR(50) NOT NULL,
);


-------------------------------------------------------------------------------------------------
-- CREACION DE PRIMARY KEYS
-------------------------------------------------------------------------------------------------

ALTER TABLE NJRE.pago
ADD CONSTRAINT PK_Pago PRIMARY KEY (pago_id);

ALTER TABLE NJRE.detalle_pago
ADD CONSTRAINT PK_DetallePago PRIMARY KEY (detallePago_id);

ALTER TABLE NJRE.medio_pago
ADD CONSTRAINT PK_MedioPago PRIMARY KEY (medioPago_id);

ALTER TABLE NJRE.tipo_medio_pago
ADD CONSTRAINT PK_TipoMedioPago PRIMARY KEY (tipoMedioPago_id);

ALTER TABLE NJRE.domicilio
ADD CONSTRAINT PK_Domicilio PRIMARY KEY (domicilio_id);

ALTER TABLE NJRE.localidad
ADD CONSTRAINT PK_Localidad PRIMARY KEY (localidad_id);

ALTER TABLE NJRE.provincia
ADD CONSTRAINT PK_Provincia PRIMARY KEY (provincia_id);

ALTER TABLE NJRE.envio 
ADD CONSTRAINT PK_Envio PRIMARY KEY (envio_id);

ALTER TABLE NJRE.tipo_envio 
ADD CONSTRAINT PK_TipoEnvio PRIMARY KEY (tipoEnvio_id);

ALTER TABLE NJRE.historial_estado_envio 
ADD CONSTRAINT PK_HistorialEstadoEnvio PRIMARY KEY (historialEstadoEnvio_id);

ALTER TABLE NJRE.factura 
ADD CONSTRAINT PK_Factura PRIMARY KEY (factura_id);

ALTER TABLE NJRE.factura_detalle 
ADD CONSTRAINT PK_FacturaDetalle PRIMARY KEY (facturaDetalle_id);

ALTER TABLE NJRE.concepto 
ADD CONSTRAINT PK_Concepto PRIMARY KEY (concepto_id);

ALTER TABLE NJRE.usuario_domicilio 
ADD CONSTRAINT PK_UsuarioDomicilio PRIMARY KEY (usuarioDomicilio_usuario_id, usuarioDomicilio_domicilio_id);

ALTER TABLE NJRE.publicacion
ADD CONSTRAINT PK_Publicacion PRIMARY KEY (publicacion_id);

ALTER TABLE NJRE.producto
ADD CONSTRAINT PK_Producto PRIMARY KEY (producto_id);

ALTER TABLE NJRE.marca
ADD CONSTRAINT PK_Marca PRIMARY KEY (marca_id);

ALTER TABLE NJRE.modelo
ADD CONSTRAINT PK_Modelo PRIMARY KEY (modelo_id);

ALTER TABLE NJRE.subrubro
ADD CONSTRAINT PK_Subrubro PRIMARY KEY (subrubro_id);

ALTER TABLE NJRE.rubro
ADD CONSTRAINT PK_Rubro PRIMARY KEY (rubro_id);

ALTER TABLE NJRE.vendedor
ADD CONSTRAINT PK_Vendedor PRIMARY KEY (vendedor_id);

ALTER TABLE NJRE.almacen
ADD CONSTRAINT PK_Almacen PRIMARY KEY (almacen_id);

ALTER TABLE NJRE.historial_costo_almacen
ADD CONSTRAINT PK_HistorialCostoAlmacen PRIMARY KEY (historialCostoAlmacen_id);   

ALTER TABLE NJRE.venta
ADD CONSTRAINT PK_Venta PRIMARY KEY (venta_id);

ALTER TABLE NJRE.detalle_venta
ADD CONSTRAINT PK_DetalleVenta PRIMARY KEY (detalleVenta_id);

ALTER TABLE NJRE.cliente
ADD CONSTRAINT PK_Cliente PRIMARY KEY (cliente_id);

ALTER TABLE NJRE.usuario
ADD CONSTRAINT PK_Usuario PRIMARY KEY (usuario_id);


-------------------------------------------------------------------------------------------------
-- CREACION DE FOREIGN KEYS
-------------------------------------------------------------------------------------------------

ALTER TABLE NJRE.pago
ADD 
	CONSTRAINT FK_Pago_MedioPago FOREIGN KEY (pago_medioPago_id) REFERENCES NJRE.medio_pago (medioPago_id),
	CONSTRAINT FK_Pago_Venta FOREIGN KEY (pago_venta_id) REFERENCES NJRE.venta (venta_id);
	
ALTER TABLE NJRE.detalle_pago
ADD CONSTRAINT FK_DetallePago_Pago FOREIGN KEY (detallePago_pago_id) REFERENCES NJRE.pago (pago_id);
	
ALTER TABLE NJRE.medio_pago
ADD CONSTRAINT FK_MedioPago_TipoMedioPago FOREIGN KEY (medioPago_tipoMedioPago_id) REFERENCES NJRE.tipo_medio_pago (tipoMedioPago_id);

ALTER TABLE NJRE.domicilio
ADD 
	CONSTRAINT FK_Domicilio_Localidad FOREIGN KEY (domicilio_localidad) REFERENCES NJRE.localidad (localidad_id),
	CONSTRAINT FK_Domicilio_Provincia FOREIGN KEY (domicilio_provincia) REFERENCES NJRE.provincia (provincia_id);

ALTER TABLE NJRE.envio
ADD 
    CONSTRAINT FK_Envio_TipoEnvio FOREIGN KEY (envio_tipoEnvio_id) REFERENCES NJRE.tipo_envio,
    CONSTRAINT FK_Envio_Domicilio FOREIGN KEY (envio_domicilio_id) REFERENCES NJRE.domicilio,
    CONSTRAINT FK_Envio_Venta FOREIGN KEY (envio_venta_id) REFERENCES NJRE.venta;

ALTER TABLE NJRE.historial_estado_envio 
ADD CONSTRAINT FK_Historial_Envio FOREIGN KEY (historialEstadoEnvio_envio_id) REFERENCES NJRE.envio;

ALTER TABLE NJRE.factura_detalle 
ADD 
    CONSTRAINT FK_FacturaDetalle_Concepto FOREIGN KEY (facturaDetalle_concepto_id) REFERENCES NJRE.concepto,
    CONSTRAINT FK_FacturaDetalle_Factura FOREIGN KEY (facturaDetalle_factura_id) REFERENCES NJRE.factura,
    CONSTRAINT FK_FacturaDetalle_Publicacion FOREIGN KEY (facturaDetalle_publicacion) REFERENCES NJRE.publicacion;

ALTER TABLE NJRE.usuario_domicilio 
ADD 
    CONSTRAINT FK_UsuarioDomicilio_Usuario FOREIGN KEY (usuarioDomicilio_usuario_id) REFERENCES NJRE.usuario (usuario_id),
    CONSTRAINT FK_UsuarioDomicilio_Domicilio FOREIGN KEY (usuarioDomicilio_domicilio_id) REFERENCES NJRE.domicilio (domicilio_id);

ALTER TABLE NJRE.publicacion
ADD 
	CONSTRAINT FK_Publicacion_Producto FOREIGN KEY (publicacion_producto_id) REFERENCES NJRE.producto (producto_id),
    CONSTRAINT FK_Publicacion_Vendedor FOREIGN KEY (publicacion_vendedor_id) REFERENCES NJRE.vendedor (vendedor_id),
    CONSTRAINT FK_Publicacion_Almacen FOREIGN KEY (publicacion_almacen_id) REFERENCES NJRE.almacen (almacen_id);

ALTER TABLE NJRE.producto
ADD 
    CONSTRAINT FK_Producto_Marca FOREIGN KEY (producto_marca_id) REFERENCES NJRE.marca (marca_id),
    CONSTRAINT FK_Producto_Modelo FOREIGN KEY (producto_mod_id) REFERENCES NJRE.modelo (modelo_id),
    CONSTRAINT FK_Producto_Subrubro FOREIGN KEY (producto_subrubro_id) REFERENCES NJRE.subrubro (subrubro_id);

ALTER TABLE NJRE.subrubro 
ADD CONSTRAINT FK_Subrubro_Rubro FOREIGN KEY (subrubro_rubro_id) REFERENCES NJRE.rubro (rubro_id);

ALTER TABLE NJRE.vendedor 
ADD  CONSTRAINT FK_Vendedor_Usuario FOREIGN KEY (vendedor_usuario_id) REFERENCES NJRE.usuario (usuario_id);

ALTER TABLE NJRE.almacen 
ADD CONSTRAINT FK_Almacen_Domicilio FOREIGN KEY (almacen_domicilio_id) REFERENCES NJRE.domicilio (domicilio_id);

ALTER TABLE NJRE.historial_costo_almacen 
ADD CONSTRAINT FK_HistorialCostoAlmacen_Almacen FOREIGN KEY (historialCostoAlmacen_almacen_id) REFERENCES NJRE.almacen (almacen_id);

ALTER TABLE NJRE.venta
ADD CONSTRAINT FK_Venta_Cliente FOREIGN KEY (venta_cliente_id) REFERENCES NJRE.cliente (cliente_id);

ALTER TABLE NJRE.detalle_venta
ADD     
    CONSTRAINT FK_DetalleVenta_Venta FOREIGN KEY (detalleVenta_venta_id) REFERENCES NJRE.venta (venta_id),
    CONSTRAINT FK_DetalleVenta_Publicacion FOREIGN KEY (detalleVenta_publicacion_id) REFERENCES NJRE.publicacion (publicacion_id);

ALTER TABLE NJRE.cliente
ADD CONSTRAINT FK_Cliente_Usuario FOREIGN KEY (cliente_usuario_id) REFERENCES NJRE.usuario (usuario_id);

GO


-------------------------------------------------------------------------------------------------
-- TRIGGERS PARA LA MIGRACION DE DATOS
-------------------------------------------------------------------------------------------------

CREATE TRIGGER insertarHistorialEstadoEnvio 
ON NJRE.envio
AFTER INSERT AS
BEGIN
    INSERT INTO NJRE.historial_estado_envio(historialEstadoEnvio_envio_id, historialEstadoEnvio_fecha, historialEstadoEnvio_estado)
	SELECT envio_id, GETDATE(), envio_estado
	FROM inserted
END
GO

CREATE TRIGGER insertarHistorialCostoAlmacen 
ON NJRE.almacen
AFTER INSERT AS
BEGIN
    INSERT INTO NJRE.historial_costo_almacen(historialCostoAlmacen_almacen_id, historialCostoAlmacen_fecha, historialCostoAlmacen_costo_dia)
    SELECT almacen_id, GETDATE(), almacen_costo_dia
	FROM inserted
END
GO


-------------------------------------------------------------------------------------------------
-- PROCEDURES PARA LA MIGRACION DE DATOS
-------------------------------------------------------------------------------------------------

IF OBJECT_ID('NJRE.migrar_tipoMedioPago') IS NOT NULL 
    DROP PROCEDURE NJRE.migrar_tipoMedioPago
GO
CREATE PROCEDURE NJRE.migrar_tipoMedioPago AS
BEGIN
    INSERT INTO NJRE.tipo_medio_pago (tipoMedioPago_nombre) 
    SELECT DISTINCT pago_tipo_medio_pago 
    FROM gd_esquema.Maestra 
    WHERE pago_tipo_medio_pago IS NOT NULL
END
GO

IF OBJECT_ID('NJRE.migrar_medioPago') IS NOT NULL 
    DROP PROCEDURE NJRE.migrar_migrar_medioPago
GO
CREATE PROCEDURE NJRE.migrar_medioPago AS
BEGIN
    INSERT INTO NJRE.medio_pago (medioPago_tipoMedioPago_id, medioPago_nombre) 
    SELECT DISTINCT tipoMedioPago_id, pago_medio_pago 
    FROM gd_esquema.Maestra 
        INNER JOIN NJRE.tipo_medio_pago ON tipoMedioPago_nombre = pago_tipo_medio_pago
    WHERE pago_medio_pago IS NOT NULL
END
GO

IF OBJECT_ID('NJRE.migrar_provincia') IS NOT NULL 
    DROP PROCEDURE NJRE.migrar_provincia
GO
CREATE PROCEDURE NJRE.migrar_provincia AS
BEGIN
INSERT INTO NJRE.provincia (provincia_id, provincia_nombre) VALUES
    ('BA', 'Buenos Aires'),
    ('CF', 'Capital Federal'),
    ('CA', 'Catamarca'),
    ('CH', 'Chaco'),
    ('CU', 'Chubut'),
    ('CO', 'Cordoba'),
    ('CR', 'Corrientes'),
    ('ER', 'Entre Rios'),
    ('FO', 'Formosa'),
    ('JU', 'Jujuy'),
    ('LP', 'La Pampa'),
    ('LR', 'La Rioja'),
    ('ME', 'Mendoza'),
    ('MI', 'Misiones'),
    ('NE', 'Neuquen'),
    ('RN', 'Rio Negro'),
    ('SA', 'Salta'),
    ('SJ', 'San Juan'),
    ('SL', 'San Luis'),
    ('SC', 'Santa Cruz'),
    ('SF', 'Santa Fe'),
    ('SE', 'Santiago del Estero'),
    ('TF', 'Tierra del Fuego'),
    ('TU', 'Tucuman');
END
GO

IF OBJECT_ID('NJRE.migrar_localidad') IS NOT NULL 
    DROP PROCEDURE NJRE.migrar_localidad
GO
CREATE PROCEDURE NJRE.migrar_localidad AS
BEGIN
    CREATE TABLE #tmp_localidad (nombre NVARCHAR(50))

    INSERT INTO #tmp_localidad
    SELECT DISTINCT cli_usuario_domicilio_localidad
    FROM gd_esquema.Maestra 
    WHERE cli_usuario_domicilio_localidad IS NOT NULL
    UNION
    SELECT DISTINCT ven_usuario_domicilio_localidad
    FROM gd_esquema.Maestra 
    WHERE ven_usuario_domicilio_localidad IS NOT NULL
    UNION
    SELECT DISTINCT almacen_localidad
    FROM gd_esquema.Maestra 
    WHERE almacen_localidad IS NOT NULL

    INSERT INTO NJRE.localidad (localidad_nombre) 
    SELECT DISTINCT nombre FROM #tmp_localidad

    DROP TABLE #tmp_localidad
END
GO

IF OBJECT_ID('NJRE.migrar_domicilio') IS NOT NULL 
    DROP PROCEDURE NJRE.migrar_domicilio
GO
CREATE PROCEDURE NJRE.migrar_domicilio AS
BEGIN
    INSERT INTO NJRE.domicilio (
        domicilio_calle, domicilio_cp, domicilio_nro_calle, 
        domicilio_piso, domicilio_depto, domicilio_provincia, domicilio_localidad
    )
    SELECT DISTINCT 
        cli_usuario_domicilio_calle, cli_usuario_domicilio_cp, cli_usuario_domicilio_nro_calle, 
        cli_usuario_domicilio_piso, cli_usuario_domicilio_depto, provincia_id, localidad_id
    FROM gd_esquema.Maestra 
        INNER JOIN NJRE.provincia ON cli_usuario_domicilio_provincia = provincia_nombre
        INNER JOIN NJRE.localidad ON cli_usuario_domicilio_localidad = localidad_nombre
    WHERE cli_usuario_domicilio_calle IS NOT NULL
    UNION
    SELECT DISTINCT 
        ven_usuario_domicilio_calle, ven_usuario_domicilio_cp, ven_usuario_domicilio_nro_calle, 
        ven_usuario_domicilio_piso, ven_usuario_domicilio_depto, provincia_id, localidad_id
    FROM gd_esquema.Maestra 
        INNER JOIN NJRE.provincia ON ven_usuario_domicilio_provincia = provincia_nombre
        INNER JOIN NJRE.localidad ON ven_usuario_domicilio_localidad = localidad_nombre
    WHERE ven_usuario_domicilio_calle IS NOT NULL
    UNION
    SELECT DISTINCT almacen_calle, NULL, almacen_nro_calle, NULL, NULL, provincia_id, localidad_id
    FROM gd_esquema.Maestra 
        INNER JOIN NJRE.provincia ON almacen_provincia = provincia_nombre
        INNER JOIN NJRE.localidad ON almacen_localidad = localidad_nombre
    WHERE almacen_calle IS NOT NULL
END
GO

IF OBJECT_ID('NJRE.migrar_rubro') IS NOT NULL 
    DROP PROCEDURE NJRE.migrar_rubro
GO
CREATE PROCEDURE NJRE.migrar_rubro AS
BEGIN
    INSERT INTO NJRE.rubro (rubro_descripcion)
    SELECT DISTINCT producto_rubro_descripcion
    FROM gd_esquema.Maestra 
    WHERE producto_rubro_descripcion IS NOT NULL
END
GO

IF OBJECT_ID('NJRE.migrar_subrubro') IS NOT NULL 
    DROP PROCEDURE NJRE.migrar_subrubro
GO
CREATE PROCEDURE NJRE.migrar_subrubro AS
BEGIN
    INSERT INTO NJRE.subrubro (subrubro_rubro_id, subrubro_descripcion)
    SELECT DISTINCT n.rubro_id, producto_sub_rubro
    FROM gd_esquema.Maestra m
        INNER JOIN NJRE.rubro n ON n.rubro_descripcion = m.producto_rubro_descripcion
    WHERE producto_sub_rubro IS NOT NULL
END
GO

IF OBJECT_ID('NJRE.migrar_marca') IS NOT NULL 
    DROP PROCEDURE NJRE.migrar_marca
GO
CREATE PROCEDURE NJRE.migrar_marca AS
BEGIN
    INSERT INTO NJRE.marca(marca_descripcion)
    SELECT DISTINCT producto_marca
    FROM gd_esquema.Maestra 
    WHERE producto_marca IS NOT NULL
END
GO

IF OBJECT_ID('NJRE.migrar_modelo') IS NOT NULL 
    DROP PROCEDURE NJRE.migrar_modelo
GO
CREATE PROCEDURE NJRE.migrar_modelo AS
BEGIN
    INSERT INTO NJRE.modelo (modelo_id, modelo_descripcion)
    SELECT DISTINCT producto_mod_codigo, producto_mod_descripcion
    FROM gd_esquema.Maestra 
    WHERE producto_mod_codigo IS NOT NULL
END
GO

IF OBJECT_ID('NJRE.migrar_almacen') IS NOT NULL 
    DROP PROCEDURE NJRE.migrar_almacen
GO
CREATE PROCEDURE NJRE.migrar_almacen AS
BEGIN
    INSERT INTO NJRE.almacen (almacen_id, almacen_domicilio_id, almacen_nombre, almacen_costo_dia)
    SELECT DISTINCT almacen_codigo, domicilio_id, almacen_calle + ' ' + CAST(almacen_nro_calle AS NVARCHAR), almacen_costo_dia_al
    FROM gd_esquema.Maestra 
        INNER JOIN NJRE.localidad ON localidad_nombre = almacen_localidad
        INNER JOIN NJRE.provincia ON provincia_nombre = almacen_provincia
        INNER JOIN NJRE.domicilio ON domicilio_calle = almacen_calle 
            AND domicilio_nro_calle = almacen_nro_calle 
            AND domicilio_localidad = localidad_id 
            AND domicilio_provincia = provincia_id
    WHERE almacen_codigo IS NOT NULL
END
GO

IF OBJECT_ID('NJRE.migrar_tipoEnvio') IS NOT NULL 
    DROP PROCEDURE NJRE.migrar_tipoEnvio
GO
CREATE PROCEDURE NJRE.migrar_tipoEnvio AS
BEGIN
    INSERT INTO NJRE.tipo_envio (tipoEnvio_medio)
    SELECT DISTINCT envio_tipo
    FROM gd_esquema.Maestra 
    WHERE envio_tipo IS NOT NULL
END
GO

IF OBJECT_ID('NJRE.migrar_concepto') IS NOT NULL 
    DROP PROCEDURE NJRE.migrar_concepto
GO
CREATE PROCEDURE NJRE.migrar_concepto AS
BEGIN
    INSERT INTO NJRE.concepto (concepto_nombre)
    SELECT DISTINCT factura_det_tipo
    FROM gd_esquema.Maestra 
    WHERE factura_det_tipo IS NOT NULL
END
GO

IF OBJECT_ID('NJRE.migrar_usuario') IS NOT NULL 
    DROP PROCEDURE NJRE.migrar_usuario
GO
CREATE PROCEDURE NJRE.migrar_usuario AS
BEGIN
    INSERT INTO NJRE.usuario (usuario_nombre, usuario_pass, usuario_fecha_creacion, usuario_mail)
    SELECT DISTINCT cli_usuario_nombre, cli_usuario_pass, cli_usuario_fecha_creacion, cliente_mail
    FROM gd_esquema.Maestra 
    WHERE cli_usuario_nombre IS NOT NULL 
    UNION
    SELECT DISTINCT ven_usuario_nombre, ven_usuario_pass, ven_usuario_fecha_creacion, vendedor_mail
    FROM gd_esquema.Maestra 
    WHERE ven_usuario_nombre IS NOT NULL
END
GO

IF OBJECT_ID('NJRE.migrar_usuarioDomicilio') IS NOT NULL 
    DROP PROCEDURE NJRE.migrar_usuarioDomicilio
GO
CREATE PROCEDURE NJRE.migrar_usuarioDomicilio AS
BEGIN
    INSERT INTO NJRE.usuario_domicilio (usuarioDomicilio_usuario_id, usuarioDomicilio_domicilio_id)
    SELECT DISTINCT u.usuario_id, d.domicilio_id 
    FROM gd_esquema.Maestra m
        INNER JOIN NJRE.usuario u ON u.usuario_nombre = m.cli_usuario_nombre  
            AND u.usuario_mail = m.cliente_mail
            AND u.usuario_fecha_creacion = cli_usuario_fecha_creacion
		INNER JOIN NJRE.localidad ON localidad_nombre = CLI_USUARIO_DOMICILIO_LOCALIDAD
		INNER JOIN NJRE.provincia ON provincia_nombre = CLI_USUARIO_DOMICILIO_PROVINCIA
        INNER JOIN NJRE.domicilio d ON d.domicilio_calle = m.cli_usuario_domicilio_calle
            AND d.domicilio_nro_calle = m.cli_usuario_domicilio_nro_calle
            AND d.domicilio_piso = m.cli_usuario_domicilio_piso
            AND d.domicilio_depto = m.cli_usuario_domicilio_depto
            AND d.domicilio_cp = m.cli_usuario_domicilio_cp
            AND d.domicilio_localidad = localidad_id
            AND d.domicilio_provincia = provincia_id
	UNION
	SELECT DISTINCT u.usuario_id, d.domicilio_id 
		FROM gd_esquema.Maestra m
			INNER JOIN NJRE.usuario u ON u.usuario_nombre = m.ven_usuario_nombre 
                AND u.usuario_mail = m.vendedor_mail
                AND u.usuario_fecha_creacion = m.ven_usuario_fecha_creacion 
			INNER JOIN NJRE.localidad ON localidad_nombre = VEN_USUARIO_DOMICILIO_LOCALIDAD
			INNER JOIN NJRE.provincia ON provincia_nombre = VEN_USUARIO_DOMICILIO_PROVINCIA          
			INNER JOIN NJRE.domicilio d ON d.domicilio_calle = m.ven_usuario_domicilio_calle
                AND d.domicilio_nro_calle = m.ven_usuario_domicilio_nro_calle
                AND d.domicilio_piso = m.ven_usuario_domicilio_piso
                AND d.domicilio_depto = m.ven_usuario_domicilio_depto
                AND d.domicilio_cp = m.ven_usuario_domicilio_cp 
                AND d.domicilio_localidad = localidad_id
                AND d.domicilio_provincia = provincia_id
END
GO

IF OBJECT_ID('NJRE.migrar_producto') IS NOT NULL 
    DROP PROCEDURE NJRE.migrar_producto
GO
CREATE PROCEDURE NJRE.migrar_producto AS
BEGIN
    INSERT INTO NJRE.producto (
        producto_marca_id, producto_mod_id, producto_subrubro_id, producto_codigo, 
        producto_precio, producto_fecha_alta, producto_descripcion
    )
    SELECT 
        marca_id, producto_mod_codigo, subrubro_id, producto_codigo, 
        producto_precio, MIN(publicacion_fecha), producto_codigo -- valor por default para la migración
    FROM gd_esquema.Maestra 
        INNER JOIN NJRE.marca ON marca_descripcion = producto_marca
        INNER JOIN NJRE.rubro ON rubro_descripcion = producto_rubro_descripcion
        INNER JOIN NJRE.subrubro ON subrubro_descripcion = producto_sub_rubro AND subrubro_rubro_id = rubro_id
    WHERE producto_codigo IS NOT NULL
    GROUP BY producto_marca, producto_mod_codigo, producto_sub_rubro, producto_codigo, producto_precio, marca_id, subrubro_id
END
GO

IF OBJECT_ID('NJRE.migrar_publicacion') IS NOT NULL 
    DROP PROCEDURE NJRE.migrar_publicacion
GO
CREATE PROCEDURE NJRE.migrar_publicacion AS
BEGIN
    INSERT INTO NJRE.publicacion (
        publicacion_id, publicacion_producto_id, publicacion_vendedor_id, publicacion_almacen_id, 
        publicacion_descripcion, publicacion_fecha_inicio, publicacion_fecha_fin, publicacion_stock, 
        publicacion_precio, publicacion_costo, publicacion_porc_venta
    )
	SELECT DISTINCT 
        publicacion_codigo, producto_id, vendedor_id, almacen_codigo, 
		PUBLICACION_DESCRIPCION, PUBLICACION_FECHA, PUBLICACION_FECHA_V, PUBLICACION_STOCK, PUBLICACION_PRECIO,
		PUBLICACION_COSTO, PUBLICACION_PORC_VENTA
    FROM gd_esquema.Maestra m
		INNER JOIN NJRE.rubro ON rubro_descripcion = producto_rubro_descripcion
        INNER JOIN NJRE.subrubro ON subrubro_descripcion = producto_sub_rubro AND subrubro_rubro_id = rubro_id
        INNER JOIN NJRE.producto p ON producto_subrubro_id = subrubro_id AND p.producto_codigo = m.PRODUCTO_CODIGO
		INNER JOIN NJRE.vendedor n ON n.vendedor_razon_social = m.vendedor_razon_social
    WHERE publicacion_codigo IS NOT NULL
END
GO

IF OBJECT_ID('NJRE.migrar_envio') IS NOT NULL 
    DROP PROCEDURE NJRE.migrar_envio
GO
CREATE PROCEDURE NJRE.migrar_envio AS
BEGIN
	INSERT INTO NJRE.envio (
        envio_venta_id, envio_domicilio_id, envio_fecha_programada, envio_hora_inicio, 
        envio_hora_fin, envio_fecha_entrega, envio_costo, envio_tipoEnvio_id,envio_estado
    )
    SELECT DISTINCT 
        VENTA_CODIGO, d.domicilio_id, m.ENVIO_FECHA_PROGAMADA, m.ENVIO_HORA_INICIO, 
        m.ENVIO_HORA_FIN_INICIO, m.ENVIO_FECHA_ENTREGA, m.ENVIO_COSTO, te.tipoEnvio_id, 'En preparación' 
        -- todos los envíos tienen fecha para el 2025 recién, por eso directamente se le pone este estado
    FROM gd_esquema.Maestra m
        INNER JOIN NJRE.tipo_envio te ON te.tipoEnvio_medio = m.ENVIO_TIPO 
        INNER JOIN NJRE.localidad ON localidad_nombre = CLI_USUARIO_DOMICILIO_LOCALIDAD
        INNER JOIN NJRE.provincia ON provincia_nombre = CLI_USUARIO_DOMICILIO_PROVINCIA
        INNER JOIN NJRE.domicilio d ON domicilio_calle = CLI_USUARIO_DOMICILIO_CALLE 
            AND domicilio_nro_calle = CLI_USUARIO_DOMICILIO_NRO_CALLE 
            AND d.domicilio_piso = m.cli_usuario_domicilio_piso 
            AND d.domicilio_depto = m.cli_usuario_domicilio_depto
            AND d.domicilio_cp = m.cli_usuario_domicilio_cp 
            AND domicilio_localidad = localidad_id 
            AND domicilio_provincia = provincia_id
    WHERE m.ENVIO_FECHA_PROGAMADA IS NOT NULL
END
GO

IF OBJECT_ID('NJRE.migrar_vendedor') IS NOT NULL 
    DROP PROCEDURE NJRE.migrar_vendedor
GO
CREATE PROCEDURE NJRE.migrar_vendedor AS
BEGIN
    INSERT INTO NJRE.vendedor (vendedor_usuario_id, vendedor_razon_social, vendedor_cuit)
    SELECT DISTINCT usuario_id, VENDEDOR_RAZON_SOCIAL, VENDEDOR_CUIT
    FROM gd_esquema.Maestra m 
        INNER JOIN NJRE.usuario ON VEN_USUARIO_NOMBRE = usuario_nombre 
            AND VENDEDOR_MAIL = usuario_mail
            AND VEN_USUARIO_FECHA_CREACION = usuario_fecha_creacion 
    WHERE VEN_USUARIO_NOMBRE IS NOT NULL
END
GO

IF OBJECT_ID('NJRE.migrar_cliente') IS NOT NULL 
    DROP PROCEDURE NJRE.migrar_cliente
GO
CREATE PROCEDURE NJRE.migrar_cliente AS
BEGIN
    INSERT INTO NJRE.cliente (cliente_usuario_id, cliente_nombre, cliente_apellido, cliente_fecha_nacimiento, cliente_dni)
    SELECT DISTINCT usuario_id, CLIENTE_NOMBRE, CLIENTE_APELLIDO, CLIENTE_FECHA_NAC, CLIENTE_DNI
    FROM gd_esquema.Maestra m 
        INNER JOIN NJRE.usuario ON CLI_USUARIO_NOMBRE = usuario_nombre 
            AND CLIENTE_MAIL = usuario_mail
            AND CLI_USUARIO_FECHA_CREACION = usuario_fecha_creacion 
    WHERE CLI_USUARIO_NOMBRE IS NOT NULL
END
GO

IF OBJECT_ID('NJRE.migrar_pago') IS NOT NULL 
    DROP PROCEDURE NJRE.migrar_pago;
GO
CREATE PROCEDURE NJRE.migrar_pago AS
BEGIN
    CREATE TABLE #tmp_pago (
        TMP_MEDIO_PAGO_ID INT,
        TMP_VENTA_CODIGO INT,
        TMP_PAGO_FECHA DATE,
        TMP_PAGO_IMPORTE DECIMAL(18, 2),
        TMP_TARJETA_NRO VARCHAR(50),
        TMP_FECHA_VENC_TARJETA DATE,
        TMP_CANT_CUOTAS INT
    );

    INSERT INTO #tmp_pago
    SELECT DISTINCT 
        mp.medioPago_id AS TMP_MEDIO_PAGO_ID, 
        m.VENTA_CODIGO AS TMP_VENTA_CODIGO, 
        m.PAGO_FECHA AS TMP_PAGO_FECHA, 
        m.PAGO_IMPORTE AS TMP_PAGO_IMPORTE,
        m.PAGO_NRO_TARJETA AS TMP_TARJETA_NRO, 
        m.PAGO_FECHA_VENC_TARJETA AS TMP_FECHA_VENC_TARJETA, 
        m.PAGO_CANT_CUOTAS AS TMP_CANT_CUOTAS
    FROM gd_esquema.Maestra m
    INNER JOIN NJRE.medio_pago mp ON mp.medioPago_nombre = m.PAGO_MEDIO_PAGO
    WHERE m.VENTA_CODIGO IS NOT NULL;

    INSERT INTO NJRE.pago (pago_medioPago_id, pago_venta_id, pago_fecha, pago_importe)
    SELECT TMP_MEDIO_PAGO_ID, TMP_VENTA_CODIGO, TMP_PAGO_FECHA, TMP_PAGO_IMPORTE
    FROM #tmp_pago;

    INSERT INTO NJRE.detalle_pago (
        detallePago_pago_id, detallePago_tarjeta_nro, detallePago_tarjeta_fecha_vencimiento, 
        detallePago_cant_cuotas, detallePago_importe_parcial
    )
    SELECT p.pago_id, t.TMP_TARJETA_NRO, t.TMP_FECHA_VENC_TARJETA, t.TMP_CANT_CUOTAS, t.TMP_PAGO_IMPORTE
    FROM #tmp_pago t INNER JOIN NJRE.pago p ON p.pago_venta_id = t.TMP_VENTA_CODIGO;

    DROP TABLE #tmp_pago;
END;
GO

IF OBJECT_ID('NJRE.migrar_venta') IS NOT NULL 
    DROP PROCEDURE NJRE.migrar_venta
GO
CREATE PROCEDURE NJRE.migrar_venta AS
BEGIN
    INSERT INTO NJRE.venta (venta_id, venta_cliente_id, venta_fecha, venta_total)
    SELECT DISTINCT VENTA_CODIGO, c.cliente_id, VENTA_FECHA, VENTA_TOTAL
    FROM gd_esquema.Maestra m 
        INNER JOIN NJRE.cliente c ON c.cliente_dni = m.CLIENTE_DNI and c.cliente_nombre = m.cliente_nombre 
    WHERE VENTA_CODIGO IS NOT NULL
END
GO

IF OBJECT_ID('NJRE.migrar_factura') IS NOT NULL 
    DROP PROCEDURE NJRE.migrar_factura
GO
CREATE PROCEDURE NJRE.migrar_factura AS
BEGIN
    INSERT INTO NJRE.factura (factura_id, factura_usuario, factura_fecha, factura_total)
    SELECT DISTINCT FACTURA_NUMERO, v.vendedor_id, FACTURA_FECHA, FACTURA_TOTAL
    FROM gd_esquema.Maestra m 
		INNER JOIN NJRE.publicacion p on p.publicacion_id = m.PUBLICACION_CODIGO
		INNER JOIN NJRE.vendedor v ON vendedor_id = p.publicacion_vendedor_id
	WHERE m.FACTURA_NUMERO IS NOT NULL
END
GO

IF OBJECT_ID('NJRE.migrar_facturaDetalle') IS NOT NULL 
    DROP PROCEDURE NJRE.migrar_facturaDetalle
GO
CREATE PROCEDURE NJRE.migrar_facturaDetalle AS
BEGIN
    INSERT INTO NJRE.factura_detalle (
        facturaDetalle_factura_id, facturaDetalle_publicacion, facturaDetalle_concepto_id, 
        facturaDetalle_precio_unitario, facturaDetalle_cantidad, facturaDetalle_subtotal
    )
    SELECT DISTINCT 
        FACTURA_NUMERO, PUBLICACION_CODIGO, c.concepto_id, 
        m.FACTURA_DET_PRECIO, m.FACTURA_DET_CANTIDAD, m.FACTURA_DET_SUBTOTAL
    FROM gd_esquema.Maestra m
        LEFT JOIN NJRE.concepto c ON c.concepto_nombre = m.FACTURA_DET_TIPO 
    WHERE m.FACTURA_NUMERO IS NOT NULL
END
GO

IF OBJECT_ID('NJRE.migrar_detalleVenta') IS NOT NULL 
    DROP PROCEDURE NJRE.migrar_detalleVenta
GO
CREATE PROCEDURE NJRE.migrar_detalleVenta AS
BEGIN
    INSERT INTO NJRE.detalle_venta (detalleVenta_venta_id, detalleVenta_publicacion_id, detalleVenta_precio, detalleVenta_cantidad, detalleVenta_subtotal)
    SELECT DISTINCT VENTA_CODIGO, PUBLICACION_CODIGO, m.VENTA_TOTAL, VENTA_DET_CANT, VENTA_DET_SUB_TOTAL
    FROM gd_esquema.Maestra m 
    WHERE m.VENTA_CODIGO IS NOT NULL
END
GO      


-------------------------------------------------------------------------------------------------
-- EJECUCION DE LA MIGRACION DE DATOS
-------------------------------------------------------------------------------------------------

EXEC NJRE.migrar_tipoMedioPago;
EXEC NJRE.migrar_medioPago;
EXEC NJRE.migrar_rubro;
EXEC NJRE.migrar_subrubro;
EXEC NJRE.migrar_marca;
EXEC NJRE.migrar_modelo;
EXEC NJRE.migrar_tipoEnvio;
EXEC NJRE.migrar_concepto;
EXEC NJRE.migrar_provincia;
EXEC NJRE.migrar_localidad;
EXEC NJRE.migrar_domicilio;
EXEC NJRE.migrar_almacen;
EXEC NJRE.migrar_usuario;
EXEC NJRE.migrar_vendedor;
EXEC NJRE.migrar_cliente;
EXEC NJRE.migrar_usuarioDomicilio;
EXEC NJRE.migrar_producto;
EXEC NJRE.migrar_publicacion;
EXEC NJRE.migrar_venta;
EXEC NJRE.migrar_detalleVenta;
EXEC NJRE.migrar_envio;
EXEC NJRE.migrar_factura;
EXEC NJRE.migrar_facturaDetalle;
EXEC NJRE.migrar_pago;

GO