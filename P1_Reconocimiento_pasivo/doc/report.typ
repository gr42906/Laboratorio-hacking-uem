#set page(paper: "a4", margin: 2.5cm)
#set text(font: "Linux Libertine", size: 11pt, lang: "es")

// --- CONFIGURACIÓN DE ESTILO ---
#set cite(style: "ieee") 
#show link: set text(fill: blue.darken(20%))

#show outline.entry: it => {
  link(it.element.location(), it)
}

#set heading(numbering: "1.1.")
#show heading: set text(fill: navy)
#set par(justify: true, leading: 0.65em)

// --- PORTADA ---
#align(center)[
  #v(3em)
  #text(size: 24pt, weight: "bold", fill: navy)[Auditoría de Reconocimiento Pasivo (OSINT)] \
  #v(1em)
  #text(size: 16pt, style: "italic")[Análisis de Superficie de Ataque: Repsol S.A.] \
  #v(2em)
  #text(size: 12pt)[*Asignatura:* Técnicas de Hacking] \
  #text(size: 12pt)[*Centro:* Escuela de Arquitectura, Ingeniería y Diseño - Universidad Europea] \
  #v(1em)
  #text(size: 12pt)[*Estudiante:* Gonzalo Revuelta] \
  #v(4em)
]

#outline(title: "Índice de Contenidos", indent: 2em, depth: 3)
#pagebreak()

= Investigación de Registros DNS (1.0 pt)

El Domain Name System (DNS) no es solo un traductor de nombres a IPs; para un auditor, es una base de datos pública que revela la arquitectura lógica de una organización. Según @petersen2020dns [Petersen & Stowe], el análisis de DNS permite identificar servicios críticos, proveedores de terceros y posibles vectores de entrada sin enviar un solo paquete a la red interna del objetivo.

== Análisis Técnico de Registros
A continuación, se detalla la función técnica y la relevancia en ciberseguridad de los registros solicitados:

- *A (Address) & AAAA:* El registro A apunta a una dirección IPv4, mientras que el AAAA apunta a una IPv6. Su análisis permite identificar si el servidor está alojado en premisa (On-Premise) o en un proveedor de Cloud.
- *MX (Mail Exchange):* Define la prioridad y el destino de los correos. Identificar registros MX de Microsoft o Google permite al atacante centrar sus esfuerzos en campañas de *Phishing* específicas para esas plataformas.
- *TXT (Text):* Es un registro multipropósito. En la actualidad, su uso más crítico es la implementación de **SPF (Sender Policy Framework)** y **DMARC**, los cuales enumeran las IPs autorizadas para enviar correo, revelando así otros servicios de marketing o CRM que la empresa utiliza.
- *CNAME (Canonical Name):* Crea alias para dominios. Es vital para detectar el uso de CDNs (Content Delivery Networks) como Cloudflare o Akamai, que actúan como escudos contra ataques DDoS.
- *NS (Name Server):* Indica quién tiene la autoridad sobre la zona. Si una empresa usa NS propios, suelen ser más vulnerables a ataques de denegación de servicio que si usan proveedores especializados como NS1 o Route53.
- *SOA (Start of Authority):* Proporciona detalles administrativos de la zona, incluyendo el número de serie (útil para detectar cambios recientes en la infraestructura) y correos de contacto técnico.
- *PTR (Pointer):* Facilita la resolución inversa. Se usa en auditorías para confirmar que una IP sospechosa pertenece realmente al rango de red de la empresa auditada.

== Metodología: Reconocimiento Pasivo vs. Activo
La distinción radica en la interacción directa con los activos del objetivo:
- *Pasivo:* Se consulta a terceros (DNS públicos, buscadores, bases de datos de Whois). No hay interacción con la infraestructura de Repsol. Herramientas: DNSDumpster, ViewDNS, Shodan.
- *Activo:* Se realizan peticiones directas a los Name Servers autoritativos del objetivo. Una técnica común es el *DNS Zone Transfer (AXFR)*, donde se solicita una copia completa de la zona DNS. Si está mal configurado, el servidor entrega todos los nombres e IPs internas, pero la petición queda registrada en sus auditorías de seguridad.

= Auditoría OSINT: Repsol S.A. (4.0 pts)

== Fase 1: Perfilado Organizacional y Modelo de Negocio
Repsol S.A. es una corporación global con presencia en toda la cadena de valor energética. El perfilado, según @glassman2012intelligence [Glassman & Kang], permite entender qué activos son más valiosos para la continuidad del negocio.

- **Perfil de Clientes:**
  - *B2C (Business to Consumer):* Millones de usuarios particulares que utilizan la app Waylet, estaciones de servicio y suministros de hogar (electricidad y gas). Aquí el activo crítico es la base de datos de usuarios y pasarelas de pago.
  - *B2B (Business to Business):* Suministro a aerolíneas (SAF - combustible sostenible), grandes constructoras, flotas de transporte logístico y el sector agrícola.
- **Perfil de Proveedores:** Repsol depende de una cadena de suministro masiva que incluye desde fabricantes de componentes industriales hasta gigantes tecnológicos como **Microsoft** (infraestructura cloud) y **SAP** (gestión de recursos corporativos).
- **Servicios Estratégicos:** Además del petróleo y gas, Repsol es ahora un operador eléctrico y de energías renovables (Solar/Eólica), lo que implica que su infraestructura crítica (OT) está cada vez más conectada a redes IT.

== Fase 2: Análisis de Infraestructura (DNSDumpster)
Utilicé la herramienta *DNSDumpster* introduciendo el dominio `repsol.com`. El objetivo fue obtener un "footprinting" inicial sin interactuar con sus servidores.

*Hallazgos Clave:*
Al observar los registros MX, identifiqué la cadena `repsol-com.mail.protection.outlook.com`. Técnicamente, esto nos indica que Repsol ha delegado su seguridad perimetral de correo a **Microsoft Office 365**. Desde el punto de vista de un auditor, esto significa que el portal de login de empleados probablemente sea un subdominio de Microsoft, lo que facilita la creación de páginas de *phishing* realistas.

#figure(
  image("images/mx_repsol.png", width: 80%),
  caption: [Captura de registros MX y mapeo visual de red en DNSDumpster.],
)

== Fase 3: Mapeo de Subdominios (crt.sh)
El uso de bases de datos de **Certificate Transparency (CT)** es una técnica de enumeración pasiva extremadamente potente. Consulté `crt.sh` con el término `%repsol.com` para encontrar todos los subdominios que han solicitado un certificado SSL/TLS.

*Análisis de 3 subdominios críticos identificados:*
1. **`vpn.repsol.com`**: Es la principal superficie de exposición para ataques de acceso inicial. Indica el uso de soluciones de acceso remoto para empleados.
2. **`proveedores.repsol.com`**: Un portal B2B. Los portales de terceros suelen ser menos robustos que el dominio principal, siendo un vector ideal para ataques de "Supply Chain".
3. **`solify.repsol.com`**: Servicio dedicado a soluciones solares. Revela la diversificación de activos web vinculados a nuevas líneas de negocio que podrían estar en infraestructuras separadas.

== Fase 4: Prueba OSINT adicional - Análisis de Metadatos
Siguiendo los apuntes de la asignatura sobre metadatos (diapositiva 42), realicé una búsqueda de documentos públicos para extraer información interna.
- *Proceso:* Utilicé Google para buscar archivos PDF de Repsol (`site:repsol.com filetype:pdf`).
- *Técnica:* Aunque en un entorno real usaría herramientas como **FOCA** o **Exiftool**, el análisis manual de los campos de "Propiedades" de estos archivos revela nombres de usuario de empleados, versiones de software (ej. Adobe Acrobat 2023) y rutas de carpetas locales del servidor (`C:\Users\j.perez\...`). Esta información es oro puro para un atacante, ya que permite conocer la estructura de nombres de usuario para ataques de fuerza bruta.

== Fase 5: Google Dorking - Análisis de Fugas
Para buscar información que no debería estar indexada, utilicé operadores avanzados de Google (@long2011google [Long et al.]):

1. **Búsqueda de Documentos Sensibles:**
   - Dork: `site:repsol.com filetype:pdf "estrictamente confidencial" OR "uso interno"`
   - *Justificación:* Busca manuales de procedimientos o normativas que exponen la jerarquía interna de la empresa.
#figure(image("images/dork_pdf.png", width: 70%), caption: [Resultados de documentos internos etiquetados como confidenciales.])

2. **Búsqueda de Directorios Expuestos:**
   - Dork: `site:repsol.com intitle:"index of"`
   - *Justificación:* Este dork busca servidores web mal configurados que listan sus archivos en lugar de mostrar una página web, lo cual puede exponer backups o configuraciones.
#figure(image("images/dork_index.png", width: 70%), caption: [Detección de servidores con listado de directorios activo.])

= Conclusiones
La auditoría pasiva realizada sobre Repsol S.A. demuestra que la superficie de ataque de una gran corporación es inmensa y difícil de ocultar. Mediante el análisis de DNS y subdominios, hemos identificado que su comunicación corporativa reside en la nube de Microsoft. El uso de técnicas de CT y Dorking ha revelado portales críticos y posibles fugas de información en metadatos de documentos públicos.
Es imperativo que las organizaciones realicen auditorías de "Footprinting" periódicas para minimizar su sombra digital y asegurar que sus activos más críticos, como las pasarelas VPN, no sean fácilmente descubiertos mediante técnicas OSINT tan sencillas pero efectivas como las aplicadas en esta práctica.

#pagebreak()
#bibliography("bibliography.bib", title: "Bibliografía", style: "apa")