#set page(paper: "a4", margin: 2.5cm)
#set text(font: "Linux Libertine", size: 11pt, lang: "es")

// Configuración de encabezados numerados e interactivos
#set heading(numbering: "1.1.")
#show outline.entry.where(level: 1): it => {
  v(12pt, weak: true)
  strong(it)
}

#align(center)[
  #v(2em)
  #text(size: 20pt, weight: "bold")[Práctica 1: Recogida de información pasiva] \
  #text(size: 14pt)[Técnicas de Hacking - Universidad Europea]
  #v(1em)
  *Estudiante:* Gonzalo Revuelta \
  *Objetivo:* Repsol S.A.
]

#v(2em)
#outline(title: "Índice", indent: 2em, depth: 3)
#pagebreak()

= Introducción
Como hemos visto en las sesiones de clase, el reconocimiento pasivo es la fase inicial y más crítica de cualquier auditoría. El objetivo es obtener la máxima inteligencia sin tocar directamente los servidores de la víctima, evitando así levantar sospechas en sus sistemas de detección (IDS/IPS). 

= Perfilado de la Empresa (Footprinting)
La investigación comenzó con una pregunta fundamental: ¿Quién es nuestro objetivo? Antes de lanzar herramientas técnicas, necesitaba comprender a Repsol S.A. a nivel de negocio. 

Al investigar en fuentes públicas, perfilé que no solo es una empresa energética del IBEX 35, sino una corporación en plena transición digital. Sus clientes abarcan desde usuarios particulares hasta aviación e industria, y sus proveedores tecnológicos clave incluyen a gigantes como Microsoft Azure y AWS. Esta información, puramente OSINT @glassman2012intelligence, es vital: me indica que su "superficie de ataque" no está en un solo edificio, sino distribuida en la nube. 

= Análisis de Infraestructura (DNS)
Una vez entendido el negocio, el siguiente paso lógico fue descubrir cómo se traducen sus nombres de dominio en máquinas reales. El sistema DNS es un pilar fundamental en ciberseguridad, ya que una mala configuración puede revelar toda la topología interna @petersen2020dns.

== Teoría y Mapeo Pasivo
Repasé los registros críticos: **A y AAAA** (IPs IPv4 e IPv6), **CNAME** (alias), **NS** (servidores de nombres), **SOA** (autoridad), **PTR** (inversa), **MX** (correo) y **TXT** (políticas de seguridad).

Para mantener la pasividad, utilicé *DNSDumpster*. Adicionalmente, quise corroborar los datos desde mi terminal usando `dig`. Para mantener el anonimato, ejecuté la consulta contra el servidor DNS de Google (`dig repsol.com MX @8.8.8.8`). Al consultar a un tercero, garantizo que mi IP no quede registrada en los logs de la compañía objetivo.

== Hallazgos DNS
El análisis reveló que Repsol ha delegado su infraestructura de correo a Microsoft (Office 365). Esto es un descubrimiento crítico para futuros vectores de *phishing*.

#figure(
  image("images/mx_repsol.png", width: 85%),
  caption: [Evidencia de registros MX apuntando a la infraestructura de Microsoft.],
)

= Inteligencia de Fuentes Abiertas (OSINT)
Sabiendo que su infraestructura técnica está externalizada, decidí buscar fallos de configuración humanos mediante OSINT avanzado.

== Relaciones y Superficie de Ataque
Generé un mapa topológico de sus subdominios. Esto me permitió visualizar la inmensa red de portales que Repsol tiene expuestos a Internet.

#figure(
  image("images/mapa_repsol.png", width: 80%),
  caption: [Grafo de relaciones de subdominios, ilustrando la dispersión de activos en la red.],
)

== Fugas de Información con Google Dorking
Utilicé operadores avanzados de búsqueda. Como señala @long2011google, esta técnica es completamente pasiva porque interrogamos a la caché de Google. Diseñé tres estrategias clave:

*1. Búsqueda de documentos confidenciales (`filetype:pdf`):*
El objetivo era encontrar manuales internos que expongan el lenguaje corporativo.
#figure(
  image("images/dork_pdf.png", width: 80%),
  caption: [Dork 1: Localización de archivos PDF de carácter sensible e interno.],
)

*2. Búsqueda de portales de acceso (`inurl:login`):*
El objetivo era localizar paneles de administración expuestos al público.
#figure(
  image("images/dork_login.png", width: 80%),
  caption: [Dork 2: Búsqueda de paneles de autenticación de empleados.],
)

*3. Búsqueda de directorios expuestos (`intitle:"index of"`):*
El objetivo era verificar si los servidores web tienen listados de directorios sin protección.
#figure(
  image("images/dork_index.png", width: 80%),
  caption: [Dork 3: Búsqueda de configuraciones deficientes en servidores web.],
)

= Conclusiones
La investigación demuestra que el reconocimiento pasivo es increíblemente poderoso. Siguiendo el hilo desde el modelo de negocio, pasando por la infraestructura (DNS), hasta llegar al error humano (OSINT y Dorking), he podido trazar un mapa completo de Repsol S.A. sin enviar un solo paquete malicioso a sus servidores.

#pagebreak()
#bibliography("bibliography.bib", title: "Bibliografía", style: "apa")