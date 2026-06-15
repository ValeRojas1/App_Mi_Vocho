# Mejoras realizadas desde el 03 de junio de 2026

**Integrantes**

- Rojas Camayo Valentino
- Estrada Flores Axel
- Cruz Salazar Jorge

---

## Datos del documento

| Campo | Detalle |
| --- | --- |
| Proyecto | Mi Vocho |
| Periodo documentado | Desde el 03/Junio/2026 |
| Version base considerada | 1.2.0+3 |
| Tipo de documento | Informe de mejoras |

---

## Resumen ejecutivo

Desde el 03 de junio de 2026 se incorporaron mejoras enfocadas en convertir la aplicacion en una experiencia mas completa para clientes y administradores. Los cambios fortalecen el flujo de compra, la gestion de inventario, el seguimiento de pedidos, la ubicacion de la tienda, las promociones, los reportes, el perfil de usuario y la identidad visual de la app.

Las mejoras principales se agrupan en cinco frentes:

1. Experiencia de compra mas completa para el cliente.
2. Panel de administracion mas util para la dueña.
3. Mayor soporte de datos en Supabase.
4. Mejor presentacion visual e identidad de marca.
5. Funciones de apoyo como mapas, notificaciones y persistencia del carrito.

---

## Mejoras para clientes

### Catalogo de repuestos

- Se agrego un carrusel de ofertas y noticias en la pantalla principal del catalogo.
- Se incorporaron filtros por categoria para encontrar repuestos con mayor rapidez.
- Se mejoro la visualizacion de productos con imagenes, categoria, precio, stock y estado de disponibilidad.
- Se agrego una vista de detalle del repuesto con descripcion, disponibilidad e imagen ampliada.
- Se bloqueo la compra de productos agotados para evitar pedidos inconsistentes.
- Se agregaron mensajes claros cuando un repuesto se añade al carrito o cuando se alcanza el stock maximo disponible.

### Carrito de compras

- Se agrego persistencia local del carrito, permitiendo conservar productos aunque se cierre la aplicacion.
- Se incorporo sincronizacion del carrito con el stock y precio actual del servidor.
- Se ajustan automaticamente cantidades si el stock disponible cambia.
- Se eliminan del carrito productos que ya no estan activos o disponibles.
- Se agrego confirmacion antes de eliminar productos del carrito.
- Se muestra subtotal por producto y total general de compra.
- Se agrego actualizacion manual del carrito mediante gesto de refrescar.

### Pago y checkout

- Se rediseño el flujo de pago bajo una pantalla de "Pago Seguro".
- Se incorporaron metodos de pago: tarjeta, Yape, Plin y pago en tienda.
- Se agrego validacion de datos de tarjeta para el flujo demostrativo.
- Se agrego registro de numero de operacion o celular para pagos por Yape y Plin.
- Se agrego seleccion entre recojo en tienda y envio interprovincial.
- Se incorporo seleccion de agencia de envio para pedidos interprovinciales.
- Se agrego opcion para ingresar una agencia personalizada.
- Se registra el metodo de pago y la agencia de envio en el pedido.
- Se agrego pantalla de confirmacion de pago exitoso con mensajes diferenciados segun recojo o envio.

### Pedidos del cliente

- Se mejoro la pantalla de pedidos del cliente con tarjetas mas informativas.
- Se agregaron estados de pedido con etiquetas pensadas para el cliente.
- Se incorporo detalle de pedido con productos, cantidades, total, estado, metodo de entrega y datos relevantes.
- Se agrego acceso a la ruta de la tienda cuando el pedido sea para recojo.

### Perfil del cliente

- Se agrego pantalla "Mi cuenta".
- Se permite guardar nombre, telefono, region y direccion de entrega.
- Se muestra el correo asociado a la cuenta.
- Se agrego control para activar notificaciones sobre cambios en pedidos.
- Se agrego cierre de sesion desde el perfil.

### Ubicacion de la tienda

- Se agrego una nueva pestaña "Tienda" en la navegacion del cliente.
- Se muestra informacion de La Casa del Volkswagen, direccion y horario.
- Se agrego pantalla de mapa integrada con OpenStreetMap.
- Se calcula ruta en auto usando OSRM.
- Se muestra ubicacion actual del usuario cuando otorga permiso de GPS.
- Se agregaron accesos para abrir navegacion externa en Google Maps y Waze.
- Se documento que el mapa funciona sin necesidad de API Key de Google.

---

## Mejoras para administracion

### Panel principal

- Se mejoro el dashboard de la dueña con indicadores operativos.
- Se agregaron metricas de pedidos del dia.
- Se agrego contador de pedidos pendientes por confirmar.
- Se agrego contador de repuestos activos.
- Se agrego indicador de productos con stock bajo.
- Se agregaron mensajes de recomendacion para reabastecimiento cuando hay stock bajo.

### Gestion de pedidos

- Se agregaron filtros para ver todos los pedidos, pendientes y pedidos del dia.
- Se mejoro la tarjeta de pedido con informacion mas clara.
- Se agrego visualizacion de metodo de entrega y agencia de envio.
- Se mantiene la actualizacion de estado de pedidos desde el panel de administracion.
- Se incorporaron estados mas completos: pendiente, confirmado, listo, enviado y completado.

### Inventario de repuestos

- Se mejoro la gestion de productos con soporte para imagenes.
- Se permite seleccionar imagen desde galeria o camara.
- Se permite quitar imagen de un producto.
- Se suben imagenes de productos a Supabase Storage.
- Se permite editar nombre, descripcion, precio, stock, categoria, imagen y estado activo.
- Se agrego actualizacion rapida de stock desde un dialogo.
- Se identifican visualmente los productos con stock bajo.
- Se muestra cuando un producto esta inactivo en el catalogo.
- Se agrego control de cambios sin guardar antes de salir del formulario.

### Ofertas y noticias

- Se agrego una pantalla de administracion para ofertas y noticias.
- Se permite editar titulo e imagen de promociones.
- Se soportan tres posiciones de promocion para mostrar en el carrusel del catalogo.
- Se integran las promociones con Supabase y Supabase Storage.
- Se agrego manejo visual cuando la migracion de promociones aun no esta aplicada.

### Reportes

- Se agrego una pantalla de reportes para administracion.
- Se muestran ingresos estimados del mes.
- Se muestran pedidos del mes.
- Se muestran pedidos pendientes.
- Se agrego ranking de repuestos mas vendidos.
- Se calcula cantidad vendida e ingreso generado por producto.

### Perfil de administracion

- Se agrego pantalla de perfil para la dueña.
- Se permite actualizar datos personales.
- Se agrego cierre de sesion desde el panel lateral.
- Se agrego un menu lateral con accesos a ofertas, perfil y salida.

---

## Mejoras de autenticacion

- Se mejoro la pantalla de inicio de sesion con modo de registro.
- Se agrego registro de usuarios con nombre completo.
- Se agrego confirmacion de contraseña.
- Se agregaron validaciones para correo, contraseña y nombre.
- Se agrego visualizacion para mostrar u ocultar contraseña.
- Se agrego manejo de mensajes claros para correo ya registrado, credenciales incorrectas y correo no verificado.
- Se agrego dialogo informativo cuando Supabase requiere confirmacion por correo.
- Se mantiene redireccion por rol hacia cliente o administracion.

---

## Mejoras de datos y backend

### Perfiles

- Se agrego soporte para direccion de entrega en perfiles.
- Se agrego modelo de perfil con nombre, telefono, region, direccion y rol.
- Se permite actualizar datos del perfil desde la app.
- Se mantiene compatibilidad con el correo legado de dueña como respaldo.

### Pedidos

- Se agrego soporte para metodo de pago.
- Se agrego soporte para agencia de envio.
- Se amplio el modelo de pedido para leer total, metodo de pago, agencia y tipo de recojo.
- Se mantiene creacion de pedidos con descuento de stock.
- Se agrego respaldo para crear pedidos aunque la funcion RPC de Supabase no este disponible.

### Tienda

- Se agrego tabla de configuracion de tienda.
- Se guarda nombre, direccion, ciudad, coordenadas, telefono y horario.
- Se agrego informacion de respaldo para La Casa del Volkswagen en Huancayo.
- Se agregaron politicas de lectura publica y escritura restringida a administracion.

### Promociones

- Se agrego tabla de promociones.
- Se agrego bucket publico para imagenes de promociones.
- Se configuraron politicas de lectura y escritura segun rol.
- Se agregaron tres espacios iniciales de promocion.

---

## Mejoras visuales y de marca

- Se actualizo la paleta visual con colores asociados a Volkswagen: azul corporativo, amarillo calido, crema vintage y rojo de acento.
- Se diferenciaron fondos visuales para cliente y administracion.
- Se mejoraron estilos de botones, tarjetas, campos de texto y barra de navegacion.
- Se agrego icono personalizado de la aplicacion.
- Se actualizaron iconos Android e iOS.
- Se agrego soporte de icono adaptativo para Android.
- Se agregaron assets para icono de app y promociones.
- Se incorporo una pantalla de carga tipo "elevator loading gate" para mejorar la percepcion visual durante esperas.

---

## Mejoras de plataforma y permisos

- Se agregaron permisos Android para internet, camara, ubicacion precisa, ubicacion aproximada y notificaciones.
- Se habilito soporte de camara opcional para seleccionar o tomar fotos de productos.
- Se agrego compatibilidad con notificaciones locales.
- Se habilito desugaring de Android para mejorar compatibilidad con librerias modernas.
- Se incorporaron dependencias para mapas, ubicacion, seleccion de imagenes, notificaciones, almacenamiento local y apertura de apps externas.

---

## Entregables documentados

| Area | Mejora principal |
| --- | --- |
| Cliente | Catalogo, carrito persistente, checkout, pedidos, perfil, notificaciones y mapa |
| Administracion | Dashboard, inventario, pedidos, promociones, reportes y perfil |
| Datos | Perfiles, tienda, promociones, metodo de pago y agencia de envio |
| Visual | Nueva identidad, iconos, assets y componentes mas pulidos |
| Plataforma | Permisos, mapas, GPS, camara, notificaciones y compatibilidad Android |

---

## Conclusion

Las mejoras realizadas desde el 03 de junio de 2026 amplian Mi Vocho desde una aplicacion basica de catalogo y pedidos hacia una solucion mas completa para venta de repuestos, gestion administrativa, seguimiento de pedidos, ubicacion de tienda, promociones y reportes. La app ahora ofrece una experiencia mas clara para el cliente y herramientas mas utiles para la administracion del negocio.
