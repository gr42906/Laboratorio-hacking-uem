#set page(paper: "a4", margin: 2.5cm)
#set text(font: "Linux Libertine", size: 11pt, lang: "es")

// --- CONFIGURACIÓN DE ÍNDICE Y NUMERACIÓN (Requisito 0.5 pts) ---
#set heading(numbering: "1.1.")
#show outline.entry.where(level: 1): it => {
  v(12pt, weak: true)
  strong(it)
}

#align(center)[
  #v(2em)
  #text(size: 20pt, weight: "bold")[Práctica 1: Recogida de información pasiva] \
  #text(size: 14pt)[Técnicas de Hacking - Universidad Europea] \
  #v(1em)
  *Estudiante:* Gonzalo Revuelta \
  *Objetivo:* Auditoría OSINT Repsol S.A.
]

#v(2em)
#outline(title: "Índice", indent: 2em, depth: 3)
#pagebreak()

= Investigación de Registros DNS (1.0 pt)
Como base técnica antes de iniciar la auditoría, es fundamental entender el papel del DNS.

== Función de los registros
Para mapear la infraestructura de Repsol, primero debemos comprender qué información nos da cada registro:
- **A / AAAA**: Direcciones IP (v4 y v6) de sus servidores frontales.
- **MX**: Servidores de correo. Es el primer punto donde detectamos proveedores externos.
- **TXT**: Crucial para ver registros SPF/DMARC y validar la seguridad contra suplantación.
- **CNAME / NS / SOA / PTR**: Registros que definen alias, autoridad y resolución inversa de la infraestructura.

== Metodología: ¿Cuándo es Pasivo o Activo?
En esta práctica, mi enfoque ha sido **estrictamente pasivo**. He utilizado herramientas que consultan bases de datos preexistentes. Si hubiera lanzado un comando de transferencia de zona (AXFR) directamente contra los servidores NS de Repsol, la auditoría pasaría a ser **activa**, lo cual está prohibido en este escenario según el aviso legal.

= Auditoría OSINT: Repsol S.A. (4.0 pts)

== Fase 1: Perfilado y Modelo de Negocio (2.1)
Mi investigación comenzó analizando a qué se dedica Repsol. No podemos atacar lo que no entendemos. Descubrí que es una empresa multienergética que sirve a millones de **clientes** (particulares y aviación) y depende de **proveedores** críticos como Microsoft para su operativa diaria. 

Este primer paso me dio la clave: al ser una empresa tan grande y moderna, su superficie de ataque no estaría en servidores físicos propios, sino probablemente en la **nube**.

== Fase 2: El hilo conductor DNS - De la teoría a la práctica
Con la sospecha de que usaban la nube, utilicé *DNSDumpster* para confirmar mi teoría. Al analizar los registros **MX**, el resultado fue claro: todo el tráfico de correo pasa por `mail.protection.outlook.com`.



Esto me llevó a la siguiente conclusión: Repsol confía su identidad digital a Microsoft Azure. Por tanto, mi siguiente paso lógico fue buscar dónde se loguean sus empleados.

#figure(
  image("images/mx_repsol.png", width: 85%),
  caption: [Hallazgo clave: Los registros MX confirman la dependencia de servicios Office 365.],
)

== Fase 3: Mapeo de la superficie y subdominios
Siguiendo el rastro de la infraestructura, generé un mapa de subdominios. Al ver la inmensa cantidad de activos, comprendí que la empresa tiene portales específicos para cada tipo de cliente (industrial, particular, comercial). Esto aumenta exponencialmente las posibilidades de encontrar un descuido humano.

#figure(
  image("images/mapa_repsol.png", width: 80%),
  caption: [Grafo de infraestructura: La complejidad de la red de Repsol facilita la existencia de activos olvidados.],
)

== Fase 4: Google Dorking - Buscando el error humano (0.5 pts)
Tras mapear los servidores y ver que Repsol usa infraestructuras híbridas, decidí usar Google como un "escáner pasivo". Mi estrategia no fue lanzar dorks al azar, sino seguir un hilo de investigación:

*1. Fuga de documentación interna:* Primero, busqué si había documentos que no deberían estar indexados. Al usar `filetype:pdf "confidencial"`, el objetivo era encontrar manuales o normativas que revelen cómo se organizan internamente.
#figure(
  image("images/dork_pdf.png", width: 75%),
  caption: [Dork 1: Localización de archivos PDF con posibles fugas de información interna.],
)

*2. Exposición de portales de acceso:* Como el DNS me confirmó que usan Microsoft y Azure, el siguiente paso lógico fue buscar sus puntos de entrada. Usé `inurl:login` para mapear qué portales de empleados están expuestos directamente a Internet, lo cual es oro para un ataque de ingeniería social.
#figure(
  image("images/dork_login.png", width: 75%),
  caption: [Dork 2: Identificación de portales de autenticación y paneles de acceso.],
)

*3. Fallos de configuración en servidores:* Finalmente, quise comprobar si algún administrador olvidó cerrar el listado de directorios. El dork `intitle:"index of"` es la prueba definitiva de higiene digital. Encontrar un directorio abierto permitiría navegar por la estructura de archivos sin permiso.
#figure(
  image("images/dork_index.png", width: 75%),
  caption: [Dork 3: Verificación de servidores web con configuraciones de listado de archivos (Index of).],
)

= Conclusiones y Cumplimiento Ético
La "historia" de esta auditoría demuestra que el OSINT es una cadena: el modelo de negocio me llevó al DNS, el DNS me confirmó el uso de la nube de Microsoft, y eso me dirigió a buscar portales de acceso y documentos sensibles. Todo el proceso se ha realizado de forma **100% pasiva**, cumpliendo con el aviso legal de la práctica y sin interactuar con los sistemas de defensa de Repsol S.A.

#pagebreak()
#bibliography("bibliography.bib", title: "Bibliografía", style: "apa")