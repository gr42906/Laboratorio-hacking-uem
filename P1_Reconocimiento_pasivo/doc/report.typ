#set page(paper: "a4", margin: 2.5cm)
#set text(font: "Linux Libertine", size: 11pt, lang: "es")

#align(center)[
  #v(2em)
  = Práctica 1: Recogida de información pasiva
  == Técnicas de Hacking - UEM
  #v(1em)
  *Estudiante:* Gonzalo Revuelta \
  *Objetivo:* Repsol S.A.
]

#v(2em)
#outline(title: "Índice", indent: 2em)
#pagebreak()

= Introducción
En esta fase de reconocimiento pasivo, se ha analizado la infraestructura de Repsol S.A. sin realizar interacciones directas con sus servidores, utilizando únicamente fuentes de información abiertas (OSINT).

= Fase de Reconocimiento Pasivo
== Análisis DNS (Registros MX)
Se han identificado los servidores de correo para comprender el flujo de comunicaciones externas.

#figure(
  image("images/mx_repsol.png", width: 80%),
  caption: [Servidores de correo de Repsol (Microsoft Office 365).],
)

== Footprinting (Mapa de Red)
El mapa visual muestra la amplitud de subdominios que componen la superficie de ataque.

#figure(
  image("images/mapa_repsol.png", width: 80%),
  caption: [Estructura de subdominios de Repsol S.A.],
)

== Google Dorking
Mediante búsquedas avanzadas, se han localizado documentos con etiquetas de confidencialidad.

#figure(
  image("images/dork_repsol.png", width: 80%),
  caption: [Localización de archivos PDF sensibles mediante dorks.],
)

#pagebreak()
#bibliography("bibliography.bib", title: "Bibliografía", style: "apa") 