#set page(paper: "a4", margin: 2.5cm)
#set text(font: "Linux Libertine", size: 11pt, lang: "es")

// --- CONFIGURACIÓN PARA QUE LOS LINKS Y CITAS FUNCIONEN ---
#set cite(style: "ieee") // Estilo IEEE para que salgan [1], [2] con link
#show link: set text(fill: blue.darken(20%)) // Links en azul para que se vean

// Hacer que el índice sea clicable
#show outline.entry: it => {
  link(it.element.location(), it)
}

#set heading(numbering: "1.1.")
#show heading: set text(fill: navy)

#align(center)[
  #v(2em)
  #text(size: 20pt, weight: "bold")[Práctica 1: Recogida de información pasiva] \
  #text(size: 14pt)[Técnicas de Hacking - Universidad Europea] \
  #v(1em)
  *Estudiante:* Gonzalo Revuelta \
  *Objetivo:* Auditoría OSINT Repsol S.A.
]

#v(2em)
#outline(title: "Índice de Contenidos", indent: 2em, depth: 3)
#pagebreak()

= Investigación de Registros DNS (1.0 pt)
El análisis DNS es la piedra angular del reconocimiento. Según @petersen2020dns, entender estos registros permite mapear la superficie de ataque sin interactuar con el objetivo.

== Función de los registros
- **A / AAAA**: IPs del servidor.
- **MX**: Servidores de correo (clave para identificar Office 365).
- **TXT**: Seguridad y validación (SPF/DMARC).
- **CNAME / NS / SOA / PTR**: Alias, autoridad y resolución inversa.

== Reconocimiento Pasivo vs. Activo
La consulta es **pasiva** si usamos herramientas como *DNSDumpster* o servidores públicos como el `8.8.8.8` de Google. Se vuelve **activa** si intentamos una transferencia de zona (AXFR) directamente al servidor de Repsol, ya que nuestra IP quedaría registrada en sus auditorías de seguridad.

= Auditoría OSINT: Repsol S.A. (4.0 pts)

== Fase 1: Perfilado y Modelo de Negocio (2.1)
Repsol es una energética del IBEX 35. Mi investigación comenzó analizando su negocio: venden carburante y energía a millones de **clientes** y dependen de **proveedores** como Microsoft. Como indica @glassman2012intelligence, el perfilado es vital para saber qué buscar después.

== Fase 2: El hilo conductor (DNS a Infraestructura)
Al ver que Repsol es una empresa global, mi "historia" de investigación me llevó a mirar sus registros MX. Descubrí que usan Microsoft Outlook Protection. Esto me dio la pista: si el correo es Microsoft, probablemente sus portales de acceso también lo sean.

#figure(
  image("images/mx_repsol.png", width: 80%),
  caption: [Hallazgo de infraestructura de correo mediante DNS pasivo.],
)

== Fase 3: Mapeo de subdominios
Con el mapa de subdominios, visualicé la inmensa red de Repsol. Cada subdominio es una puerta potencial que investigué de forma pasiva.

#figure(
  image("images/mapa_repsol.png", width: 80%),
  caption: [Grafo de activos digitales expuestos de Repsol S.A.],
)

== Fase 4: Google Dorking - Buscando el error humano
Siguiendo la metodología de @long2011google, usé Google para buscar lo que el DNS no muestra:

1. **Dork de Documentos**: Busqué PDFs confidenciales.
#figure(image("images/dork_pdf.png", width: 70%), caption: [Dork 1: Documentación interna indexada.])

2. **Dork de Login**: Busqué portales de acceso Azure/Microsoft.
#figure(image("images/dork_login.png", width: 70%), caption: [Dork 2: Paneles de autenticación expuestos.])

3. **Dork de Directorios**: Busqué carpetas abiertas ("Index of").
#figure(image("images/dork_index.png", width: 70%), caption: [Dork 3: Servidores con listado de directorios activo.])

= Conclusiones
Esta investigación demuestra que el OSINT es una cadena lógica: el modelo de negocio me llevó al DNS, y este a los Dorks. Todo se hizo de forma pasiva, cumpliendo la ética de la práctica.

#pagebreak()
#bibliography("bibliography.bib", title: "Bibliografía", style: "apa")