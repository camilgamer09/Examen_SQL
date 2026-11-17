CREATE DATABASE libreria_tienda CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE libreria_tienda;


CREATE TABLE Autores (
    autor_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    fecha_nacimiento DATE,
    nacionalidad VARCHAR(100)
);


CREATE TABLE Categorias (
    categoria_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE
);


CREATE TABLE Editoriales (
    editorial_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE
);


CREATE TABLE Libros (
    libro_id INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(200) NOT NULL,
    isbn VARCHAR(20) NOT NULL UNIQUE,
    editorial_id INT NOT NULL,
    categoria_id INT NOT NULL,
    fecha_publicacion DATE,
    precio DECIMAL(10, 2) NOT NULL CHECK (precio >= 0),
    stock INT NOT NULL CHECK (stock >= 0),
    FOREIGN KEY (editorial_id) REFERENCES Editoriales(editorial_id) ON DELETE RESTRICT,
    FOREIGN KEY (categoria_id) REFERENCES Categorias(categoria_id) ON DELETE RESTRICT
);

CREATE TABLE Libros_Autores (
    libro_id INT NOT NULL,
    autor_id INT NOT NULL,
    PRIMARY KEY (libro_id, autor_id),
    FOREIGN KEY (libro_id) REFERENCES Libros(libro_id) ON DELETE CASCADE,
    FOREIGN KEY (autor_id) REFERENCES Autores(autor_id) ON DELETE CASCADE
);

/*clientes*/

CREATE TABLE Clientes (
    cliente_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(100) NOT NULL UNIQUE,
    telefono VARCHAR(20),
    direccion TEXT NOT NULL
);

/*pedidos*/

CREATE TABLE Pedidos (
    pedido_id INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT NOT NULL,
    fecha_compra DATETIME DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('pendiente', 'procesado', 'completado', 'cancelado') NOT NULL DEFAULT 'pendiente',
    FOREIGN KEY (cliente_id) REFERENCES Clientes(cliente_id) ON DELETE CASCADE
);


CREATE TABLE Detalle_Pedidos (
    detalle_id INT AUTO_INCREMENT PRIMARY KEY,
    pedido_id INT NOT NULL,
    libro_id INT NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad > 0),
    precio_unitario DECIMAL(10, 2) NOT NULL CHECK (precio_unitario >= 0),
    FOREIGN KEY (pedido_id) REFERENCES Pedidos(pedido_id) ON DELETE CASCADE,
    FOREIGN KEY (libro_id) REFERENCES Libros(libro_id) ON DELETE RESTRICT
);


CREATE TABLE Transacciones (
    transaccion_id INT AUTO_INCREMENT PRIMARY KEY,
    pedido_id INT NOT NULL UNIQUE, 
    metodo_pago ENUM('tarjeta_credito', 'paypal', 'transferencia', 'efectivo') NOT NULL,
    monto_total DECIMAL(10, 2) NOT NULL CHECK (monto_total >= 0),
    fecha_transaccion DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (pedido_id) REFERENCES Pedidos(pedido_id) ON DELETE CASCADE
);


CREATE INDEX idx_libros_titulo ON Libros(titulo);
CREATE INDEX idx_libros_isbn ON Libros(isbn);
CREATE INDEX idx_autores_nombre ON Autores(nombre);


DELIMITER //

CREATE PROCEDURE RegistrarCompra(
    IN p_cliente_id INT,
    IN p_libro_id INT,
    IN p_cantidad INT,
    IN p_metodo_pago VARCHAR(50),
    IN p_monto DECIMAL(10,2)
)
BEGIN
    DECLARE v_stock_actual INT;
    DECLARE v_pedido_id INT;


    START TRANSACTION;


    SELECT stock INTO v_stock_actual FROM Libros WHERE libro_id = p_libro_id FOR UPDATE;

    IF v_stock_actual >= p_cantidad THEN
   
        INSERT INTO Pedidos (cliente_id, estado) VALUES (p_cliente_id, 'procesado');
        SET v_pedido_id = LAST_INSERT_ID();

     
        INSERT INTO Detalle_Pedidos (pedido_id, libro_id, cantidad, precio_unitario)
        SELECT v_pedido_id, p_libro_id, p_cantidad, precio FROM Libros WHERE libro_id = p_libro_id;

   
        UPDATE Libros SET stock = stock - p_cantidad WHERE libro_id = p_libro_id;

      
        INSERT INTO Transacciones (pedido_id, metodo_pago, monto_total) 
        VALUES (v_pedido_id, p_metodo_pago, p_monto);

     
        COMMIT;
    ELSE
      
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock insuficiente para completar la compra.';
    END IF;
END //

DELIMITER ;
