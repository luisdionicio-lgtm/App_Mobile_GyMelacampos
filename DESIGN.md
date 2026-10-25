# G&M Campo

Interfaz operativa Flutter para Android e iOS. Conserva el logo rojo y azul, las fotografías del catálogo y las fuentes DM Sans y Playfair Display de la web. El móvil se adapta a colores semánticos de Material 3, con superficies marfil y carbón y acentos configurables Dorado, Azul o Verde.

## Navegación

Cuatro destinos estables: Inicio, Visitas, Materiales y Cuenta. NavigationBar en teléfono y NavigationRail en pantallas amplias. PageView admite gestos horizontales; las selecciones adyacentes usan 180 ms y curva cubic(.23,1,.32,1). Saltos distantes evitan recorrer pantallas intermedias. Los filtros y búsquedas se conservan al navegar.

## Interacción

La animación comunica selección y continuidad, sin desplazar los datos que se están leyendo. El selector de tema aplica la nueva paleta con una transición de 220 ms. Reducir animaciones evita el desplazamiento programático y respeta la opción de accesibilidad del sistema. Se mantienen controles nativos para menús, diálogos, formularios y navegación jerárquica.

Las acciones tienen áreas táctiles de al menos 48 dp. Las pantallas usan SafeArea y los formularios respetan el teclado. El bosquejo y la proforma adaptan superficie, texto y cotas al tema. El PDF conserva colores de impresión claros.

## Información y estados

El inicio usa fotografías reales de los recursos de G&M y conteos derivados de las visitas. No inventa importes ni trabajos. Demo siempre identificada. El estado de conexión está separado del estado de envío de una visita. Borradores, errores, catálogo vacío y favoritos vacíos tienen acciones o explicaciones concretas. La configuración de apariencia y los favoritos se almacenan en el dispositivo.
