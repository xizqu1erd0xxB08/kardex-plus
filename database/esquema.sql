CREATE DATABASE kardex_plus CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE kardex_plus;

-- Cada fila es un negocio un "tenant" (o inquilino), no es una configuración global única, varios negocios pueden coexistir en una sola base de datos
CREATE TABLE negocios (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre_propietario VARCHAR(150) NOT NULL,
    nombre_negocio VARCHAR(150) NOT NULL,
    nit VARCHAR(35) NOT NULL,
    direccion VARCHAR(255) NOT NULL,
    responsable_iva BOOLEAN NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en DATETIME DEFAULT CURRENT_TIMESTAMP,
    actualizado_en DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_negocios_nit (nit) -- En esta tabla no pueden existir dos negocios con el mismo NIT
) ENGINE=InnoDB;

-- Inserts semilla para iniciar en el proyecto (un negocio con responsabilidad de IVA y otro sin responsabilidad de IVA)
INSERT INTO negocios (nombre_propietario, nombre_negocio, nit, direccion, responsable_iva) VALUES
('Juan Diego Izquierdo Bohórquez', 'Minimercado La Esquina', '900111222-3', 'Cra 5 # 10-20', TRUE),
('Pepe Claudio II', 'Tienda Don Pepe', '800333444-5', 'Calle 8 #4-15', FALSE);

/* Tabla a nivel general del sistema, es decir que estos son los roles con los que el sistema va a funcionar y el
negocio los usará para hacer uso del software */
CREATE TABLE roles (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    creado_en DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_roles_nombre (nombre)
) ENGINE=InnoDB;

-- Insertar los roles en el sistema
INSERT INTO roles (nombre) VALUES
('Administrador'), -- gestiona usuarios, productos, proveedores, ve reportes completos.
('Vendedor/Cajero'), -- registra ventas, consulta stock, no puede editar productos ni ver reportes financieros completos.
('Encargado de Bodega/Inventario'); -- registra entradas de mercancía (nuevos lotes), pero no necesariamente vende.

-- Cada negocio puede tener sus propias categorías
CREATE TABLE categorias (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    negocio_id INT NOT NULL, -- Identifica a qué negocio pertenece esta categoría
    nombre VARCHAR(70) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    descripcion VARCHAR(500) NULL,
    creado_en DATETIME DEFAULT CURRENT_TIMESTAMP,
    actualizado_en DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_categorias_negocio_id
        FOREIGN KEY (negocio_id) REFERENCES negocios(id)
            ON DELETE RESTRICT
            ON UPDATE CASCADE,
    /* la categoría es única dentro del negocio, no dentro del sistema, puede haber dos negocios con la misma categoría,
    son independientes entre negocios. */
    UNIQUE KEY uq_categorias_negocio_id_nombre (negocio_id, nombre),
    -- Sirve para que los hijos puedan apuntar al par negocio_id, id (de la categoría).
    UNIQUE KEY uq_categorias_negocio_id_categoria_id (negocio_id, id)
) ENGINE=InnoDB;

/* Inserts semilla para la tabla categorías, se comprobará que ambos negocios pueden tener "Lácteos", ya que son negocios
distintos y pueden crear las categorías que deseen sin preocuparse por escribir lo mismo que el otro. Además, se usa una
sub consulta para obtener el id del primer negocio creado en el insert semilla (insertado manualmente) */
INSERT INTO categorias (negocio_id, nombre, descripcion) VALUES
((SELECT id FROM negocios WHERE nit = '900111222-3'), 'Lácteos', 'Alimentos derivados total o parcialmente de la leche de mamíferos como vacas, cabras u ovejas, reconocidos por su alto contenido de nutrientes esenciales como calcio, proteínas y vitaminas (como la leche, el queso o el yogur).'),
((SELECT id FROM negocios WHERE nit = '800333444-5'), 'Lácteos', 'Alimentos frescos y nutritivos derivados de la leche de mamíferos como la vaca, la cabra o la oveja.');

/* Cada negocio tiene sus propios proveedores */
CREATE TABLE proveedores (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    negocio_id INT NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    nit VARCHAR(35) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en DATETIME DEFAULT CURRENT_TIMESTAMP,
    actualizado_en DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_proveedores_negocios
        FOREIGN KEY (negocio_id) REFERENCES negocios(id)
            ON DELETE RESTRICT
            ON UPDATE CASCADE,
    UNIQUE KEY uq_proveedores_negocio_id_nit (negocio_id, nit), -- No pueden existir dos proveedores con el mismo NIT dentro del mismo negocio
    -- Crear el blanco de negocio con proveedor para que las tablas hijas puedan hacer referencia al proveedor del negocio específico
    UNIQUE KEY uq_proveedores_negocio_id_proveedor_id (negocio_id, id)
) ENGINE=InnoDB;

-- Tabla global (catálogo del sistema), en caso de que el cliente solicite más unidades de medida, se añadirán
CREATE TABLE unidades_medida (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(10) NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    UNIQUE KEY uq_unidades_medida_codigo (codigo),
    UNIQUE KEY uq_unidades_medida_nombre (nombre)
) ENGINE=InnoDB;

INSERT INTO unidades_medida (codigo, nombre) VALUES
('UND', 'Unidad'),
('KG', 'Kilogramo'),
('LT', 'Litro');

CREATE TABLE tarifas_iva (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(25) NOT NULL,
    nombre VARCHAR(77) NOT NULL,
    porcentaje DECIMAL(5, 3) NOT NULL,
    UNIQUE KEY uq_tarifas_iva_codigo (codigo)
) ENGINE=InnoDB;

INSERT INTO tarifas_iva (codigo, nombre, porcentaje) VALUES
('IVA19', 'Impuesto de IVA con porcentaje del 19%', 19),
('IVA5', 'Impuesto de IVA con porcentaje del 5%', 5),
('EXENTO', 'Exento del impuesto de IVA', 0),
('EXCLUIDO', 'Excluido del impuesto de IVA', 0);

CREATE TABLE productos (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    negocio_id INT NOT NULL,
    categoria_id INT NOT NULL,
    unidad_medida_id INT NOT NULL,
    tarifa_iva_id INT NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    descripcion VARCHAR(500) NULL,
    precio_venta DECIMAL(15, 2) NOT NULL,
    codigo_barras VARCHAR(50) NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en DATETIME DEFAULT CURRENT_TIMESTAMP,
    actualizado_en DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    -- Cada negocio es dueño de sus propios productos
    CONSTRAINT fk_productos_negocios
        FOREIGN KEY (negocio_id) REFERENCES negocios(id)
            ON DELETE RESTRICT
            ON UPDATE CASCADE,
    -- LLAVE COMPUESTA: el par (negocio_id, categoria_id) debe existir en categorías como (negocio_id, id)
    /* Esto hace independientes las categorías de los negocios, por ejemplo, la categoría "Lácteos" de un negocio es
    independiente de la de otro. */
    CONSTRAINT fk_productos_categorias -- nombre de la restricción, convención: fk_<tabla_hija>_<tabla_padre>
        FOREIGN KEY (negocio_id, categoria_id) REFERENCES categorias(negocio_id, id)
            ON DELETE RESTRICT -- Rechaza el DELETE si el negocio_categoría aún tiene negocio_categorias asociados
            ON UPDATE CASCADE, -- Si los ID del negocio_categoría cambia, los productos que apuntan a ellos actualizan automáticamente esa referencia en cascada
    CONSTRAINT fk_productos_unidades_medida
        FOREIGN KEY (unidad_medida_id) REFERENCES unidades_medida(id)
            ON DELETE RESTRICT
            ON UPDATE CASCADE,
    CONSTRAINT fk_productos_tarifas_iva
        FOREIGN KEY (tarifa_iva_id) REFERENCES tarifas_iva(id)
            ON DELETE RESTRICT
            ON UPDATE CASCADE,
    /* Con esto, cada negocio no puede repetir el mismo código de barras, pero los demás negocios si pueden tener el mismo
    código de barras que los de los demás. Por ejemplo, todos pueden tener el mismo código de barras de Coca-Cola, porque
    todos la venden. */
    UNIQUE KEY uq_productos_negocio_id_codigo_barras (negocio_id, codigo_barras),
    /* Blanco para que las tablas hijas puedan identificar los productos de cada negocio en específico, cada negocio_id queda
    vinculado con el ID de su producto. De la misma manera que se hizo en esta tabla con la llave compuesta y el par de
    negocio_id y categoria_id, para reconocer a qué categoría y a qué negocio pertenece este producto. */
    UNIQUE KEY uq_productos_negocio_id_producto_id (negocio_id, id)
) ENGINE=InnoDB;

-- Tabla global (catálogo del sistema), los tipos de documento los define la ley
CREATE TABLE tipos_documento (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(10) NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    UNIQUE KEY uq_tipos_documento_codigo (codigo),
    UNIQUE KEY uq_tipos_documento_nombre (nombre)
) ENGINE=InnoDB;

INSERT INTO tipos_documento (codigo, nombre) VALUES
('CC', 'Cédula de Ciudadanía'),
('TI', 'Tarjeta de Identidad'),
('CE', 'Cédula de Extranjería'),
('PA', 'Pasaporte'),
('RC', 'Registro Civil'),
('NIT', 'Número de Identificación Tributaria'),
('PEP', 'Permiso Especial de Permanencia'),
('PPT', 'Permiso por Protección Temporal'),
('NUIP', 'Número Único de Identificación Personal'),
('NA', 'No Aplica');

CREATE TABLE usuarios (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    tipo_documento_id INT NOT NULL,
    numero_documento VARCHAR(30) NOT NULL,
    nombre_completo VARCHAR(150) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    correo VARCHAR(255) NOT NULL,
    contrasena_hash VARCHAR(255) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en DATETIME DEFAULT CURRENT_TIMESTAMP,
    actualizado_en DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_usuarios_tipos_documento
        FOREIGN KEY (tipo_documento_id) REFERENCES tipos_documento(id)
            ON DELETE RESTRICT
            ON UPDATE CASCADE,
    -- Hacer que la combinación de tipo + número de documento sea única
    UNIQUE KEY uq_usuarios_tipo_documento_id_numero_documento (tipo_documento_id, numero_documento),
    UNIQUE KEY uq_usuarios_correo (correo) -- El correo registrado por el usuario debe ser único en el sistema
) ENGINE=InnoDB;

/* Un usuario puede tener muchos roles y muchos negocios, así que se procede a crear la tabla intermedia para la
relación N:N, la llave compuesta estará compuesta por 3 columnas. Esto permitirá que un usuario tenga muchos negocios, y
pueda tener distintos roles dentro de los mismos, por ejemplo, puede ser administrador en negocio A y empleado en negocio B,
o puede ser administrador en varios negocios a la vez. */
CREATE TABLE negocio_rol_usuario (
    negocio_id INT NOT NULL,
    rol_id INT NOT NULL,
    usuario_id INT NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    es_administrador_supremo BOOLEAN NOT NULL DEFAULT FALSE, -- "la última palabra dentro del software para este negocio", determina si es el administrador supremo
    -- Crear columna generada, se encarga de validar si es administrador supremo, en caso de que no lo sea, asigna null.
    /* en este caso, se crea la columna generada como INT, puede recibir valores NULL, si la columna es_administrador_supremo
    es TRUE, entonces la columna negocio_id_si_es_administrador_supremo pasa a tener el valor de negocio_id, en caso contrario,
    pasa a tener el valor NULL. */
    negocio_id_si_es_administrador_supremo INT AS (if(es_administrador_supremo, negocio_id, NULL)) STORED,
    PRIMARY KEY (negocio_id, rol_id, usuario_id),
    -- Crear la UNIQUE KEY que permita mantener UN solo administrador supremo en todo el negocio
    UNIQUE KEY uq_negocio_id_si_es_administrador_supremo (negocio_id_si_es_administrador_supremo),
    CONSTRAINT fk_negocio_rol_usuario_negocios
        FOREIGN KEY (negocio_id) REFERENCES negocios(id)
            ON DELETE RESTRICT
            ON UPDATE CASCADE,
    CONSTRAINT fk_negocio_rol_usuario_roles
        FOREIGN KEY (rol_id) REFERENCES roles(id)
            ON DELETE RESTRICT
            ON UPDATE CASCADE,
    CONSTRAINT fk_negocio_rol_usuario_usuarios
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
            ON DELETE RESTRICT
            ON UPDATE CASCADE
) ENGINE=InnoDB;

/*  Verificar que quien obtenga el cargo de administrador supremo, tenga el rol administrador, esto evita que por
un posible error, un cajero o un encargado de bodega terminen teniendo el rol administrador supremo. Esto es
posible con los TRIGGERS */
DELIMITER $$
    CREATE TRIGGER trg_nru_validar_admin_supremo_insert
    BEFORE INSERT ON negocio_rol_usuario -- Se ejecuta antes de que la fila entre (mediante INSERT únicamente) en la tabla
    FOR EACH ROW -- una vez por cada fila que se está insertando
    BEGIN
        DECLARE v_nombre_rol VARCHAR(50); -- definir variable local temporal, solo para el disparo del trigger
        IF NEW.es_administrador_supremo = TRUE THEN
            SELECT nombre INTO v_nombre_rol
            FROM roles
            WHERE id = NEW.rol_id;

                IF v_nombre_rol != 'Administrador' THEN
                    SIGNAL SQLSTATE '45000' -- Código genérico reservado para errores definidos por el usuario
                        SET MESSAGE_TEXT = 'Solo un usuario con rol "Administrador" puede ser Administrador "Supremo"';
                END IF;

        END IF;
    END$$

DELIMITER ;

DELIMITER $$
    CREATE TRIGGER trg_nru_validar_admin_supremo_update
    BEFORE UPDATE ON negocio_rol_usuario -- Se ejecuta antes de que la fila entre (mediante UPDATE únicamente) en la tabla
    FOR EACH ROW -- una vez por cada fila que se está actualizando
    BEGIN
        DECLARE v_nombre_rol VARCHAR(50); -- definir variable local temporal, solo para el disparo del trigger
        IF NEW.es_administrador_supremo = TRUE THEN
            SELECT nombre INTO v_nombre_rol
            FROM roles
            WHERE id = NEW.rol_id;

                IF v_nombre_rol != 'Administrador' THEN
                    SIGNAL SQLSTATE '45000' -- Código genérico reservado para errores definidos por el usuario
                        SET MESSAGE_TEXT = 'Solo un usuario con rol "Administrador" puede ser Administrador "Supremo"';
                END IF;

        END IF;
    END$$

DELIMITER ;

CREATE TABLE clientes (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    negocio_id INT NOT NULL,
    tipo_documento_id INT NOT NULL,
    numero_documento VARCHAR(30) NOT NULL,
    nombre_completo VARCHAR(150) NULL,
    telefono VARCHAR(20) NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en DATETIME DEFAULT CURRENT_TIMESTAMP,
    actualizado_en DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    /* Cada negocio se encarga de registrar sus propios clientes, es decir, que cada cliente es independiente en cada negocio */
    CONSTRAINT fk_clientes_negocios
        FOREIGN KEY (negocio_id) REFERENCES negocios(id)
            ON DELETE RESTRICT
            ON UPDATE CASCADE,
    CONSTRAINT fk_clientes_tipos_documento
        FOREIGN KEY (tipo_documento_id) REFERENCES tipos_documento(id)
            ON DELETE RESTRICT
            ON UPDATE CASCADE,
    -- Hacer que la combinación del negocio, tipo y número de documento sea única
    UNIQUE KEY uq_negocio_id_tipo_documento_id_numero_documento (negocio_id, tipo_documento_id, numero_documento),
    -- Hacer que el negocio y el cliente sean una única combinación dentro de la tabla (para que las tablas hijas puedan hacer referencia a esta llave única)
    UNIQUE KEY uq_negocio_id_cliente_id (negocio_id, id)
) ENGINE=InnoDB;

INSERT INTO clientes (negocio_id, tipo_documento_id, numero_documento, nombre_completo) VALUES
((SELECT id FROM negocios WHERE nit = '900111222-3'), (SELECT id FROM tipos_documento WHERE codigo = 'NA'), '222222222222', 'Consumidor Final'), -- en Colombia la DIAN pide exactamente doce números dos para el consumidor final de la factura electrónica.
((SELECT id FROM negocios WHERE nit = '800333444-5'), (SELECT id FROM tipos_documento WHERE codigo = 'NA'), '222222222222', 'Consumidor Final');

/* Esta tabla identifica el negocio que realizó la compra, y al usuario que la realizó junto al rol que tenía en el momento
de realizarla. También guarda al proveedor que vendió la mercancía. Se verifica que el usuario que realiza la compra realmente
pertenece al negocio mediante la llave foránea FOREIGN KEY (negocio_id, rol_id, usuario_id), esto impide que usuarios que sean
externos al negocio sean inmediatamente impedidos de realizar esta acción. */
CREATE TABLE compras (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    negocio_id INT NOT NULL,
    usuario_id INT NOT NULL,
    rol_id INT NOT NULL,
    proveedor_id INT NOT NULL,
    numero_factura_proveedor VARCHAR(50) NOT NULL,
    fecha_factura_proveedor DATE NOT NULL, -- fecha dada por el proveedor (fecha contable/legal)
    /* Si se intentan meter números negativos en las columnas de precios, se lanza una violación de restricción (Check
    constraint violation). */
    subtotal DECIMAL(15, 2) NOT NULL CHECK (subtotal >= 0),
    iva_total DECIMAL(15,2) NOT NULL CHECK (iva_total >= 0),
    fecha DATE NOT NULL, -- fecha en la que se recibió la mercancía (fecha recepción/inventario)
    creado_en DATETIME DEFAULT CURRENT_TIMESTAMP, -- fecha y hora exacta en la que el usuario guardó la compra en el sistema (fecha del sistema/auditoría)
    actualizado_en DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_compras_negocio_rol_usuario
        FOREIGN KEY (negocio_id, rol_id, usuario_id) REFERENCES negocio_rol_usuario(negocio_id, rol_id, usuario_id)
            ON DELETE RESTRICT
            ON UPDATE CASCADE,
    -- FK para comprobar que el proveedor pertenece al negocio específico
    CONSTRAINT fk_compras_proveedores
        FOREIGN KEY (negocio_id, proveedor_id) REFERENCES proveedores(negocio_id, id)
            ON DELETE RESTRICT
            ON UPDATE CASCADE,
    -- Asegurar que la combinación del ID del proveedor y número de factura no sea la misma
    UNIQUE KEY uq_proveedor_id_numero_factura_proveedor (proveedor_id, numero_factura_proveedor), -- convención: uq_<nombre_columna_1>_<nombre_columna_2>
    -- Crear UNIQUE KEY para que las tablas hijas puedan referenciar el id de la compra con el id del negocio específico
    UNIQUE KEY uq_negocio_id_compra_id (negocio_id, id)
) ENGINE=InnoDB;

CREATE TABLE lotes (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    negocio_id INT NOT NULL,
    producto_id INT NOT NULL,
    compra_id INT NOT NULL,
    costo_unitario DECIMAL(15, 2) NOT NULL CHECK (costo_unitario >= 0), -- El costo del lote
    cantidad_inicial DECIMAL(15, 2) NOT NULL CHECK (cantidad_inicial >= 0), -- La cantidad que llegó del lote (el valor inicial)
    cantidad_disponible DECIMAL(10, 3) NOT NULL CHECK (cantidad_disponible >= 0), -- La cantidad que va bajando a medida que se venden los productos del lote
    fecha_vencimiento DATE NULL,
    creado_en DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    actualizado_en DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    -- Verificar que el lote pertenezca a su negocio específico (dado que producto_id lleva a un negocio a través de productos)
    CONSTRAINT fk_lotes_productos
        FOREIGN KEY (negocio_id, producto_id) REFERENCES productos(negocio_id, id)
            ON DELETE RESTRICT
            ON UPDATE CASCADE,
    -- Verificar que el lote pertenezca a su negocio específico (dado que compra_id lleva a un negocio a través de compras)
    CONSTRAINT fk_lotes_compras
        FOREIGN KEY (negocio_id, compra_id) REFERENCES compras(negocio_id, id)
            ON DELETE RESTRICT
            ON UPDATE CASCADE,
    /* crear llave única del negocio con su respectivo lote, para que, de ser necesario, las tablas hijas puedan referenciarla
    en caso de necesitar que el lote sea específicamente de un negocio, lo cual es necesario en el sistema para evitar
    que se mezclen lotes entre negocios. */
    UNIQUE KEY uq_negocio_id_lote_id (negocio_id, id)
) ENGINE=InnoDB;

CREATE TABLE tipos_descuento (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE KEY uq_tipos_descuento_codigo (codigo),
    UNIQUE KEY uq_tipos_descuento_nombre (nombre)
) ENGINE=InnoDB;

INSERT INTO tipos_descuento (codigo, nombre) VALUES
('PORCENTAJE', 'Descuento por porcentaje'),
('MONTO_FIJO', 'Descuento por monto fijo');

CREATE TABLE promociones (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    negocio_id INT NOT NULL, -- Cada negocio tiene sus propias promociones
    rol_id INT NOT NULL, -- El rol que tenía el usuario cuando creó la promoción
    usuario_id INT NOT NULL, -- El usuario que creó la promoción
    lote_id INT NULL, -- para descuentos de un lote específico (por ejemplo, por vencimiento pronto)
    producto_id INT NULL, -- para promociones de un producto completo, sin importar el lote
    categoria_id INT NULL, -- para promociones amplias ("20% en toda la sección de lácteos")
    tipo_descuento_id INT NOT NULL,
    /* la columna valor se interpreta según el tipo de descuento que tenga, puede ser ya sea que tipo_descuento_id apunte
    a PORCENTAJE (valor = 20 significaría descontar 20% del precio) o apunte a MONTO_FIJO (valor = 500 significaría descontar
    500 pesos directamente del precio, sin importar cuál sea el precio) */
    valor DECIMAL(15, 3) NOT NULL CHECK (valor >= 0),
    fecha_inicio DATETIME NOT NULL,
    fecha_fin DATETIME NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    /* Hacer referencia a la llave primaria compuesta de la tabla negocio_rol_usuario. Esto identificará correctamente
    qué negocio creó la promoción, qué usuario la creó y con qué rol. */
    CONSTRAINT fk_promociones_negocio_rol_usuario
        FOREIGN KEY (negocio_id, rol_id, usuario_id) REFERENCES negocio_rol_usuario(negocio_id, rol_id, usuario_id)
            ON DELETE RESTRICT
            ON UPDATE CASCADE,
    -- Crear llave foránea para promociones por lote, verificando el lote pertenezca al negocio correspondiente
    CONSTRAINT fk_promociones_lotes
        FOREIGN KEY (negocio_id, lote_id) REFERENCES lotes(negocio_id, id)
            ON DELETE RESTRICT
            ON UPDATE CASCADE,
    -- Crear llave foránea para promociones por producto, verificando el producto pertenezca al negocio correspondiente
    CONSTRAINT fk_promociones_productos
        FOREIGN KEY (negocio_id, producto_id) REFERENCES productos(negocio_id, id)
            ON DELETE RESTRICT
            ON UPDATE CASCADE,
    -- Crear llave foránea para promociones por categoría, verificando la categoría pertenezca al negocio correspondiente
    CONSTRAINT fk_promociones_categorias
        FOREIGN KEY (negocio_id, categoria_id) REFERENCES categorias(negocio_id, id)
            ON DELETE RESTRICT
            ON UPDATE CASCADE,
    CONSTRAINT chk_promociones_alcance_unico CHECK (
        ((lote_id IS NOT NULL) AND (producto_id IS NULL AND categoria_id IS NULL)) -- promoción de un lote específico
        OR ((producto_id IS NOT NULL) AND (lote_id IS NULL AND categoria_id IS NULL)) -- promoción de un producto específico
        OR ((categoria_id IS NOT NULL) AND (producto_id IS NULL AND lote_id IS NULL)) -- promoción de una categoría específica
    ),
    CONSTRAINT fk_promociones_tipos_descuento
        FOREIGN KEY (tipo_descuento_id) REFERENCES tipos_descuento(id)
            ON DELETE RESTRICT
            ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE ventas (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    negocio_id INT NOT NULL,
    cliente_id INT NOT NULL,
    usuario_id INT NOT NULL,
    rol_id INT NOT NULL,
    -- Con esto, subtotal + iva_total = total, no es necesario crear una columna que almacene el total de la venta
    subtotal DECIMAL(15, 2) NOT NULL CHECK (subtotal >= 0),
    iva_total DECIMAL(15, 2) NOT NULL CHECK (iva_total >= 0),
    monto_pagado DECIMAL(15, 2) NOT NULL CHECK (monto_pagado >= 0),
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    -- Hacer referencia a la UNIQUE KEY creada en la tabla clientes para verificar que esta venta pertenezca al negocio y al cliente específicos
    CONSTRAINT fk_ventas_clientes_negocios
        FOREIGN KEY (negocio_id, cliente_id) REFERENCES clientes(negocio_id, id)
            ON DELETE RESTRICT
            ON UPDATE CASCADE,
    /* De la misma manera que se hizo en compras, se verifica en ventas que la venta haya sido realizada por un usuario
    que verdaderamente pertenezca al sistema y tenga un rol registrado dentro del mismo */
    CONSTRAINT fk_ventas_negocio_rol_usuario
        FOREIGN KEY (negocio_id, rol_id, usuario_id) REFERENCES negocio_rol_usuario(negocio_id, rol_id, usuario_id)
            ON DELETE RESTRICT
            ON UPDATE CASCADE,
    /* UNIQUE KEY que guarda el id del negocio junto al id de esta venta específica, mismo patrón que se ha aplicado en
    otras tablas (como en la tabla compras) */
    UNIQUE KEY uq_negocio_id_venta_id (negocio_id, id)
) ENGINE=InnoDB;

CREATE TABLE detalle_venta (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    negocio_id INT NOT NULL,
    venta_id INT NOT NULL,
    lote_id INT NOT NULL,
    cantidad DECIMAL(10, 3) NOT NULL CHECK (cantidad >= 0),
    costo_unitario DECIMAL(15, 2) NOT NULL CHECK (costo_unitario >= 0),
    precio_venta_unitario DECIMAL(15, 2) NOT NULL CHECK (precio_venta_unitario >= 0),
    porcentaje_iva_aplicado DECIMAL(5, 3) NOT NULL CHECK (porcentaje_iva_aplicado >= 0),
    /* Con el precio de venta unitario y con el porcentaje de iva aplicado, simplemente es calcular el subtotal de cada
    detalle de venta, "no hacer columna si se puede calcular, a menos que deba quedar congelada en el tiempo, en este
    caso, el monto del iva y el precio de venta unitario ya quedan congelados en el tiempo de por sí, así que no hay
    problema en calcular el total" */
    CONSTRAINT fk_detalle_venta_ventas
        FOREIGN KEY (negocio_id, venta_id) REFERENCES ventas(negocio_id, id)
            ON DELETE RESTRICT
            ON UPDATE CASCADE,
    -- FK compuesta para que en cada detalle_venta, el negocio y lote asociados son los correspondientes
    CONSTRAINT fk_detalle_venta_lotes
        FOREIGN KEY (negocio_id, lote_id) REFERENCES lotes(negocio_id, id)
            ON DELETE RESTRICT
            ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE facturas (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    negocio_id INT NOT NULL,
    venta_id INT NOT NULL,
    numero VARCHAR(20) NOT NULL,
    fecha_emision DATE NOT NULL,
    creado_en DATETIME DEFAULT CURRENT_TIMESTAMP,
    -- Se verifica que la venta pertenezca al negocio específico mediante la llave foránea compuesta creada previamente en la tabla ventas
    CONSTRAINT fk_facturas_ventas
        FOREIGN KEY (negocio_id, venta_id) REFERENCES ventas(negocio_id, id)
            ON DELETE RESTRICT
            ON UPDATE CASCADE,
    -- Crear la llave foránea para la relación 1:1 de facturas con ventas
    UNIQUE KEY uq_facturas_venta_id (venta_id), -- El número del id de venta que entre en esta columna no se puede volver a repetir jamás en ninguna otra fila de esta tabla
    -- Hacer que el número de la factura sea único e irrepetible DENTRO DE cada negocio
    UNIQUE KEY uq_facturas_negocio_id_numero (negocio_id, numero)
) ENGINE=InnoDB;

-- Tabla global, determina los tipos de movimiento de inventario posibles dentro de un negocio, si el cliente necesita uno extra, debe solicitarlo
CREATE TABLE tipos_movimiento (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(30) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    signo TINYINT(1) NOT NULL,
    requiere_motivo BOOLEAN NOT NULL,
    UNIQUE KEY uq_tipos_movimiento_codigo (codigo)
) ENGINE=InnoDB;

INSERT INTO tipos_movimiento (codigo, nombre, signo, requiere_motivo) VALUES
('ENTRADA_COMPRA', 'Entrada por compra', 1, FALSE),
('SALIDA_VENTA', 'Salida por venta', -1, FALSE),
('SALIDA_AVERIA', 'Salida por avería/daño', -1, TRUE),
('SALIDA_VENCIMIENTO', 'Baja por vencimiento', -1, FALSE),
('ENTRADA_DEVOLUCION_CLIENTE', 'Devolución del cliente', 1, TRUE),
('SALIDA_DEVOLUCION_PROVEEDOR', 'Devolución al proveedor', -1, TRUE),
('AJUSTE_POSITIVO', 'Ajuste positivo', 1, TRUE),
('AJUSTE_NEGATIVO', 'Ajuste negativo', -1, TRUE);


CREATE TABLE movimiento_inventario (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    tipo_movimiento_id INT NOT NULL,
    negocio_id INT NOT NULL,
    rol_id INT NOT NULL,
    usuario_id INT NOT NULL,
    lote_id INT NOT NULL,
    compra_id INT NULL,
    venta_id INT NULL,
    cliente_id INT NULL,
    cantidad DECIMAL(10, 3) NOT NULL,
    motivo VARCHAR(300) NULL,
    fecha DATETIME NOT NULL,
    CONSTRAINT fk_movimiento_inventario_tipos_movimiento
        FOREIGN KEY (tipo_movimiento_id) REFERENCES tipos_movimiento(id)
            ON DELETE RESTRICT
            ON UPDATE CASCADE,
    -- Crear llave foránea compuesta que verifica que el lote pertenezca a su respectivo negocio
    CONSTRAINT fk_movimiento_inventario_lotes
        FOREIGN KEY (negocio_id, lote_id) REFERENCES lotes(negocio_id, id)
            ON DELETE RESTRICT
            ON UPDATE CASCADE,
    -- Crear llave foránea compuesta que verifica que la compra pertenezca a su respectivo negocio
    CONSTRAINT fk_movimiento_inventario_compras
        FOREIGN KEY (negocio_id, compra_id) REFERENCES compras(negocio_id, id)
            ON DELETE RESTRICT
            ON UPDATE CASCADE,
    -- Crear llave foránea compuesta que verifica que la venta pertenezca a su respectivo negocio
    CONSTRAINT fk_movimiento_inventario_ventas
        FOREIGN KEY (negocio_id, venta_id) REFERENCES ventas(negocio_id, id)
            ON DELETE RESTRICT
            ON UPDATE CASCADE,
    -- Crear llave foránea compuesta que verifica que el cliente esté registrado en el respectivo negocio
    CONSTRAINT fk_movimiento_inventario_clientes
        FOREIGN KEY (negocio_id, cliente_id) REFERENCES clientes(negocio_id, id)
            ON DELETE RESTRICT
            ON UPDATE CASCADE,
    -- Crear llave foránea compuesta que verifica que el usuario pertenezca a su respectivo negocio y tenga un rol dentro del mismo
    CONSTRAINT fk_movimiento_inventario_negocio_rol_usuario
        FOREIGN KEY (negocio_id, rol_id, usuario_id) REFERENCES negocio_rol_usuario(negocio_id, rol_id, usuario_id)
            ON DELETE RESTRICT
            ON UPDATE CASCADE,
    -- Crear restricción CHECK que impida estados imposibles (como tener id de compra e id de venta a la vez en el mismo movimiento)
    -- Sirve para que MySQL nunca acepte una fila donde ambas estén llenas
    CONSTRAINT chk_origen_unico CHECK (
        (compra_id IS NOT NULL AND venta_id IS NULL) -- viene de compra
        OR (compra_id IS NULL AND venta_id IS NOT NULL) -- viene de venta
        OR (compra_id IS NULL AND venta_id IS NULL) -- otra causa (como ajuste/avería)
    )
) ENGINE=InnoDB;